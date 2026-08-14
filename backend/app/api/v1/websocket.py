import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from app.core.config import settings
from app.core.security import decode_token
from app.services.websocket_service import manager

logger = logging.getLogger("specz_websocket")
router = APIRouter()

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    
    # 1. Check for token in query parameters
    token = websocket.query_params.get("token")
    authenticated_user_id = None

    if token:
        try:
            payload = decode_token(token, settings.JWT_SECRET)
            if payload.get("type") == "access":
                authenticated_user_id = payload.get("sub")
        except Exception as e:
            logger.warning(f"WebSocket auth failed via query param: {e}")

    # 2. If no query token, wait for authentication frame from client
    if not authenticated_user_id:
        try:
            auth_frame_raw = await websocket.receive_text()
            auth_data = json.loads(auth_frame_raw)
            if auth_data.get("action") == "authenticate":
                client_token = auth_data.get("token")
                if client_token:
                    payload = decode_token(client_token, settings.JWT_SECRET)
                    if payload.get("type") == "access":
                        authenticated_user_id = payload.get("sub")
        except Exception as e:
            logger.warning(f"WebSocket auth frame failed: {e}")

    # 3. IDOR Security Enforcement: Verify authenticated identity matches requested user_id
    if not authenticated_user_id or authenticated_user_id != user_id:
        logger.warning(f"WebSocket IDOR Violation attempt: Token user '{authenticated_user_id}' requested channel for '{user_id}'")
        await websocket.send_json({
            "event": "error",
            "code": "ACCESS_DENIED",
            "message": "Forbidden: Token identity does not match requested channel."
        })
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # Add verified connection to manager
    await manager.connect(user_id, websocket)
    await websocket.send_json({"event": "authenticated", "status": "ok", "user_id": user_id})

    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                action = payload.get("action")
                if action == "recover_events":
                    await manager.send_personal_message(
                        {"event": "events_recovered", "status": "ok", "user_id": user_id},
                        websocket
                    )
            except Exception:
                pass
    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
