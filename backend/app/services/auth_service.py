import uuid
from datetime import datetime, timezone
from typing import Tuple, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status

from app.models.user import User
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.core.config import settings

class AuthService:
    @staticmethod
    async def register_user(db: AsyncSession, email: str, password: str, name: Optional[str] = None, phone: Optional[str] = None) -> User:
        """Registers a new user account with hashed password."""
        email_clean = email.strip().lower()
        stmt = select(User).where(User.email == email_clean)
        res = await db.execute(stmt)
        if res.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists."
            )
            
        user_id = f"user_{int(datetime.now().timestamp() * 1000)}"
        user = User(
            id=user_id,
            email=email_clean,
            phone=phone,
            password_hash=get_password_hash(password),
            first_name=name or "User",
            display_name=name or "User",
            plan="free",
            account_status="ACTIVE",
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def authenticate_user(db: AsyncSession, email: str, password: str) -> User:
        """Authenticates user credentials."""
        email_clean = email.strip().lower()
        stmt = select(User).where(User.email == email_clean, User.deleted_at.is_(None))
        res = await db.execute(stmt)
        user = res.scalar_one_or_none()
        
        if not user or not user.password_hash or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials."
            )
        if user.account_status == "DELETED":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account has been deleted."
            )
        return user

    @staticmethod
    def generate_tokens(user: User) -> Tuple[str, str]:
        """Generates access and refresh tokens for user."""
        access_token = create_access_token(subject=user.id, extra_claims={"email": user.email, "plan": user.plan})
        refresh_token = create_refresh_token(subject=user.id)
        return access_token, refresh_token

    @staticmethod
    async def refresh_tokens(db: AsyncSession, refresh_token: str) -> Tuple[str, str, User]:
        """Rotates refresh token and issues a new access token pair."""
        try:
            payload = decode_token(refresh_token, settings.REFRESH_TOKEN_SECRET)
            if payload.get("type") != "refresh":
                raise ValueError("Not a refresh token")
            user_id = payload.get("sub")
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token."
            )
            
        stmt = select(User).where(User.id == user_id, User.deleted_at.is_(None))
        res = await db.execute(stmt)
        user = res.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found.")
            
        new_access_token, new_refresh_token = AuthService.generate_tokens(user)
        return new_access_token, new_refresh_token, user

    @staticmethod
    async def delete_account(db: AsyncSession, user_id: str):
        """Soft-deletes user account and invalidates active status."""
        stmt = select(User).where(User.id == user_id)
        res = await db.execute(stmt)
        user = res.scalar_one_or_none()
        if user:
            user.account_status = "DELETED"
            user.deleted_at = datetime.now(timezone.utc)
            await db.commit()
