from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
import jwt
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from app.core.config import settings


def verify_google_id_token(token: str) -> Dict[str, Any]:
    """Verifies a Google ID token against Google's servers.
    
    Returns the verified token payload containing:
    - sub: Google's unique user identifier
    - email: User's email address
    - email_verified: Whether the email is verified
    - name: User's display name
    - picture: URL to user's profile picture
    
    Raises ValueError if the token is invalid, expired, or from wrong audience.
    """
    try:
        payload = id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID,
        )
        
        # Verify the issuer
        if payload.get("iss") not in ("accounts.google.com", "https://accounts.google.com"):
            raise ValueError("Invalid token issuer")
        
        # Ensure email is verified
        if not payload.get("email_verified", False):
            raise ValueError("Google email is not verified")
        
        return payload
    except Exception as e:
        raise ValueError(f"Invalid Google ID token: {str(e)}")


def create_access_token(subject: str, expires_delta: Optional[timedelta] = None, extra_claims: Optional[Dict[str, Any]] = None) -> str:
    """Generates a short-lived JWT Access Token."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "type": "access",
        "iat": datetime.now(timezone.utc),
    }
    if extra_claims:
        to_encode.update(extra_claims)
        
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.ALGORITHM)
    return encoded_jwt

def create_refresh_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    """Generates a long-lived JWT Refresh Token."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "type": "refresh",
        "iat": datetime.now(timezone.utc),
    }
    encoded_jwt = jwt.encode(to_encode, settings.REFRESH_TOKEN_SECRET, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_token(token: str, secret: str) -> Dict[str, Any]:
    """Decodes and validates a JWT token."""
    try:
        payload = jwt.decode(token, secret, algorithms=[settings.ALGORITHM])
        return payload
    except jwt.PyJWTError as e:
        raise ValueError(f"Invalid token: {str(e)}")
