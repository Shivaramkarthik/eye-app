from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
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

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global Production Error Handler (Does not leak internal stack traces or SQL details)
@app.exception_handler(Exception)
async def custom_global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected internal server error occurred. Please try again later."
            }
        }
    )

# Include Routers
app.include_router(health_router, tags=["Health"])
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
