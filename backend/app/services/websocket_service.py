import json
import logging
from typing import Dict, List, Set, Optional
from fastapi import WebSocket

logger = logging.getLogger("specz_websocket")

class ConnectionManager:
    def __init__(self):
        # Maps user_id -> Set[WebSocket]
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)
        logger.info(f"WebSocket connected for user {user_id}")

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"WebSocket disconnected for user {user_id}")

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_text(json.dumps(message))

    async def broadcast_to_user(self, user_id: str, event_type: str, payload: dict, event_id: Optional[str] = None):
        if user_id in self.active_connections:
            message = {
                "event": event_type,
                "event_id": event_id or f"evt_{user_id}",
                "payload": payload
            }
            raw_msg = json.dumps(message)
            for connection in list(self.active_connections[user_id]):
                try:
                    await connection.send_text(raw_msg)
                except Exception as e:
                    logger.error(f"Failed to send WS message: {e}")
                    self.disconnect(user_id, connection)

manager = ConnectionManager()
