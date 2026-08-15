from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.core.rate_limiter import limiter
from app.schemas.auth import (
    GoogleAuthRequest,
    TokenResponse,
    RefreshTokenRequest,
)
from app.schemas.user import UserOut
from app.services.auth_service import AuthService
from app.services.analytics_service import AnalyticsService

router = APIRouter()


@router.post("/google", response_model=TokenResponse)
@limiter.limit("5/minute")
async def google_auth(req: GoogleAuthRequest, request: Request, db: AsyncSession = Depends(get_db)):
    """Authenticates via Google Sign-In and returns JWT token pair.
    
    1. Receives Google ID token from Flutter client.
    2. Validates it against Google's servers (NOT just decoding).
    3. Finds or creates the Specz user.
    4. Returns Specz access + refresh tokens.
    """
    user = await AuthService.authenticate_with_google(db, google_id_token=req.google_id_token)
    access_token, refresh_token = AuthService.generate_tokens(user)
    
    await AnalyticsService.log_audit(
        db, action="google_login", user_id=user.id,
        ip_address=request.client.host if request.client else None
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=1800,
        user_id=user.id,
        email=user.email,
        name=user.display_name,
        avatar_url=user.avatar_url,
        plan=user.plan,
    )


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("10/minute")
async def refresh_token(req: RefreshTokenRequest, request: Request, db: AsyncSession = Depends(get_db)):
    """Rotates refresh token and returns a new token pair."""
    access_token, refresh_token, user = await AuthService.refresh_tokens(db, req.refresh_token)
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=1800,
        user_id=user.id,
        email=user.email,
        name=user.display_name,
        avatar_url=user.avatar_url,
        plan=user.plan,
    )


@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Logs out user session."""
    await AnalyticsService.log_audit(db, action="logout", user_id=current_user.id)
    return {"message": "Successfully logged out."}


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    """Returns currently authenticated user profile."""
    return current_user


@router.delete("/account")
async def delete_account(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Deletes active user account and soft-deletes profile state."""
    await AuthService.delete_account(db, current_user.id)
    await AnalyticsService.log_audit(db, action="account_deletion", user_id=current_user.id)
    return {"message": "Account has been successfully deleted."}
