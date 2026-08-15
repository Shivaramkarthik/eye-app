from datetime import datetime, timezone
from typing import Tuple, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status

from app.models.user import User
from app.core.security import (
    verify_google_id_token,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.core.config import settings


class AuthService:
    @staticmethod
    async def authenticate_with_google(db: AsyncSession, google_id_token: str) -> User:
        """Authenticates a user via Google Sign-In.
        
        1. Validates the Google ID token with Google's servers.
        2. Extracts verified identity (sub, email, name, picture).
        3. Finds existing user by google_sub (primary lookup).
        4. Falls back to email lookup for legacy account linking.
        5. Creates a new user if no match found.
        
        Returns the authenticated User.
        """
        # Step 1: Verify the Google ID token — this is REAL validation against Google
        try:
            google_payload = verify_google_id_token(google_id_token)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid Google credentials: {str(e)}"
            )
        
        google_sub = google_payload.get("sub")
        email = google_payload.get("email", "").strip().lower()
        display_name = google_payload.get("name", "User")
        avatar_url = google_payload.get("picture")
        
        if not google_sub or not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google token missing required identity fields."
            )
        
        # Step 2: Look up user by Google subject ID (primary identity key)
        stmt = select(User).where(User.google_sub == google_sub, User.deleted_at.is_(None))
        res = await db.execute(stmt)
        user = res.scalar_one_or_none()
        
        if user:
            # Existing Google user — update profile info from Google
            user.display_name = display_name
            user.avatar_url = avatar_url
            user.email = email
            user.updated_at = datetime.now(timezone.utc)
            await db.commit()
            await db.refresh(user)
            return user
        
        # Step 3: Fall back to email lookup (legacy account linking)
        stmt = select(User).where(User.email == email, User.deleted_at.is_(None))
        res = await db.execute(stmt)
        user = res.scalar_one_or_none()
        
        if user:
            # Link Google identity to existing account
            user.google_sub = google_sub
            user.display_name = display_name
            user.avatar_url = avatar_url
            user.updated_at = datetime.now(timezone.utc)
            await db.commit()
            await db.refresh(user)
            return user
        
        # Step 4: Create new user
        user_id = f"user_{int(datetime.now().timestamp() * 1000)}"
        user = User(
            id=user_id,
            google_sub=google_sub,
            email=email,
            first_name=display_name.split()[0] if display_name else "User",
            display_name=display_name,
            avatar_url=avatar_url,
            plan="free",
            account_status="ACTIVE",
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
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
