from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.config import settings
from app.core.security import decode_token
from app.database.session import get_db
from app.models.user import User

security_bearer = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_bearer),
    db: AsyncSession = Depends(get_db)
) -> User:
    """FastAPI dependency extracting and verifying the authenticated user from JWT Bearer token."""
    token = credentials.credentials
    try:
        payload = decode_token(token, settings.JWT_SECRET)
        if payload.get("type") != "access":
            raise ValueError("Token is not an access token")
        user_id: str = payload.get("sub")
        if not user_id:
            raise ValueError("Sub missing from payload")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    stmt = select(User).where(User.id == user_id, User.deleted_at.is_(None))
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or account deactivated."
        )
    if user.account_status == "DELETED":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account has been deleted."
        )
    return user
