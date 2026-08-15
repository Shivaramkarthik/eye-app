import os
from datetime import datetime, timezone
from fastapi import FastAPI, Request, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.middleware import (
    RequestIDMiddleware,
    RequestSizeLimiterMiddleware,
    StructuredLoggingMiddleware,
)
from app.core.rate_limiter import limiter

# Routers
from app.api.v1.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.profiles import router as profiles_router
from app.api.v1.prescriptions import router as prescriptions_router
from app.api.v1.medications import router as medications_router
from app.api.v1.scores import router as scores_router
from app.api.v1.reports import router as reports_router
from app.api.v1.sync import router as sync_router
from app.api.v1.subscriptions import router as subscriptions_router
from app.api.v1.webhooks import router as webhooks_router
from app.api.v1.ai import router as ai_router
from app.api.v1.analytics import router as analytics_router
from app.api.v1.websocket import router as websocket_router
from app.api.v1.config import router as config_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Attach slowapi rate limiter state
app.state.limiter = limiter

# Middleware Pipeline (executed in reverse registration order)
# 1. CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID"],
)
# 2. Structured Access Logging
app.add_middleware(StructuredLoggingMiddleware)
# 3. Payload Size Limiting (15MB cap)
app.add_middleware(RequestSizeLimiterMiddleware)
# 4. Request ID Generation & Propagation
app.add_middleware(RequestIDMiddleware)


# --- RFC 7807 Standard Error Handlers ---

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Formats HTTPException into standard structured error response."""
    request_id = getattr(request.state, "request_id", "unknown")
    return JSONResponse(
        status_code=exc.status_code,
        headers={"X-Request-ID": request_id, **(exc.headers or {})},
        content={
            "detail": exc.detail,
            "error": {
                "code": _status_to_code(exc.status_code),
                "message": exc.detail,
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Formats validation errors without leaking internal schema internals."""
    request_id = getattr(request.state, "request_id", "unknown")
    errors = []
    for err in exc.errors():
        field = " -> ".join(str(loc) for loc in err.get("loc", []))
        errors.append(f"{field}: {err.get('msg')}")

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        headers={"X-Request-ID": request_id},
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid request parameters.",
                "details": errors,
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        },
    )


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """Handles 429 Too Many Requests with retry-after header."""
    request_id = getattr(request.state, "request_id", "unknown")
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        headers={"X-Request-ID": request_id, "Retry-After": "60"},
        content={
            "error": {
                "code": "RATE_LIMIT_EXCEEDED",
                "message": "Too many requests. Please slow down.",
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        },
    )


@app.exception_handler(Exception)
async def custom_global_exception_handler(request: Request, exc: Exception):
    """Catches unhandled exceptions. Never leaks stack traces or SQL details."""
    request_id = getattr(request.state, "request_id", "unknown")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        headers={"X-Request-ID": request_id},
        content={
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected internal server error occurred. Our team has been notified.",
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        },
    )


def _status_to_code(status_code: int) -> str:
    codes = {
        400: "BAD_REQUEST",
        401: "UNAUTHORIZED",
        402: "PAYMENT_REQUIRED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        409: "CONFLICT",
        413: "PAYLOAD_TOO_LARGE",
        422: "UNPROCESSABLE_ENTITY",
        429: "RATE_LIMIT_EXCEEDED",
        500: "INTERNAL_SERVER_ERROR",
        502: "BAD_GATEWAY",
        503: "SERVICE_UNAVAILABLE",
    }
    return codes.get(status_code, "ERROR")


# Include Routers
app.include_router(health_router, tags=["Health"])
app.include_router(config_router, prefix=f"{settings.API_V1_STR}/config", tags=["Configuration & Flags"])
app.include_router(auth_router, prefix=f"{settings.API_V1_STR}/auth", tags=["Auth"])
app.include_router(users_router, prefix=f"{settings.API_V1_STR}/users", tags=["Users"])
app.include_router(profiles_router, prefix=f"{settings.API_V1_STR}/profiles", tags=["Profiles"])
app.include_router(prescriptions_router, prefix=f"{settings.API_V1_STR}", tags=["Prescriptions"])
app.include_router(medications_router, prefix=f"{settings.API_V1_STR}", tags=["Medications"])
app.include_router(scores_router, prefix=f"{settings.API_V1_STR}", tags=["Scores"])
app.include_router(reports_router, prefix=f"{settings.API_V1_STR}", tags=["Reports"])
app.include_router(sync_router, prefix=f"{settings.API_V1_STR}/sync", tags=["Sync"])
app.include_router(subscriptions_router, prefix=f"{settings.API_V1_STR}/subscriptions", tags=["Subscriptions"])
app.include_router(webhooks_router, prefix=f"{settings.API_V1_STR}/webhooks", tags=["Webhooks"])
app.include_router(ai_router, prefix=f"{settings.API_V1_STR}/ai", tags=["AI & OCR"])
app.include_router(analytics_router, prefix=f"{settings.API_V1_STR}/analytics", tags=["Analytics"])
app.include_router(websocket_router, prefix=f"{settings.API_V1_STR}", tags=["Realtime WebSocket"])


@app.get("/")
async def root():
    return {"message": "Welcome to Specz.co V2 API", "docs": "/docs", "version": "2.0.0"}
