from typing import Optional
from pydantic import BaseModel, EmailStr, Field

class RegisterRequest(BaseModel):
    email: str = Field(..., description="User email or phone identifier")
    password: str = Field(..., min_length=6, description="User password")
    name: Optional[str] = Field(None, description="Full display name")
    phone: Optional[str] = Field(None, description="Phone number")

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
    email: str
    name: Optional[str] = None
    plan: str = "free"

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class PasswordResetRequest(BaseModel):
    email: str

class PasswordResetConfirmRequest(BaseModel):
    token: str
    new_password: str = Field(..., min_length=6)

class AccountDeleteRequest(BaseModel):
    password: str
