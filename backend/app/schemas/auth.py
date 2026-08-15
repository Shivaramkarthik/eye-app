from typing import Optional
from pydantic import BaseModel, Field


class GoogleAuthRequest(BaseModel):
    """Request body for Google Sign-In authentication."""
    google_id_token: str = Field(..., description="Google ID token obtained from Google Sign-In SDK")


class TokenResponse(BaseModel):
    """JWT token pair returned after successful authentication."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
    email: str
    name: Optional[str] = None
    avatar_url: Optional[str] = None
    plan: str = "free"


class RefreshTokenRequest(BaseModel):
    """Request body for refreshing an expired access token."""
    refresh_token: str
