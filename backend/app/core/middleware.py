import time
import uuid
import logging
from typing import Callable
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, JSONResponse
from starlette import status

logger = logging.getLogger("specz_access")

MAX_PAYLOAD_BYTES = 15 * 1024 * 1024  # 15 MB limit for OCR/image uploads


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Assigns or propagates a unique X-Request-ID header for distributed tracing."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = request.headers.get("X-Request-ID") or f"req_{uuid.uuid4().hex[:16]}"
        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


class RequestSizeLimiterMiddleware(BaseHTTPMiddleware):
    """Rejects incoming payloads larger than 15MB before processing."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        content_length = request.headers.get("content-length")
        if content_length:
            try:
                length = int(content_length)
                if length > MAX_PAYLOAD_BYTES:
                    request_id = getattr(request.state, "request_id", "unknown")
                    return JSONResponse(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        headers={"X-Request-ID": request_id},
                        content={
                            "error": {
                                "code": "PAYLOAD_TOO_LARGE",
                                "message": f"Request entity exceeds the maximum allowed size of {MAX_PAYLOAD_BYTES // (1024 * 1024)}MB.",
                                "request_id": request_id,
                            }
                        },
                    )
            except ValueError:
                pass

        return await call_next(request)


class StructuredLoggingMiddleware(BaseHTTPMiddleware):
    """Logs non-sensitive request metrics (method, path, status, latency, request_id).
    
    NEVER logs request bodies, auth headers, passwords, or medical records.
    """

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        start_time = time.perf_counter()
        request_id = getattr(request.state, "request_id", "unknown")
        client_ip = request.client.host if request.client else "unknown"

        # Suppress verbose health probe logs
        is_health = request.url.path.startswith("/health")

        try:
            response = await call_next(request)
            duration_ms = round((time.perf_counter() - start_time) * 1000, 2)

            if not is_health:
                logger.info(
                    f"[{request_id}] {request.method} {request.url.path} "
                    f"-> {response.status_code} ({duration_ms}ms) | IP: {client_ip}"
                )
            return response
        except Exception as exc:
            duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
            logger.error(
                f"[{request_id}] {request.method} {request.url.path} "
                f"FAILED after {duration_ms}ms | IP: {client_ip} | Error: {type(exc).__name__}"
            )
            raise exc
