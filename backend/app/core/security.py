from typing import Optional
from fastapi import Depends, HTTPException, Header, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from app.core.config import settings

security = HTTPBearer(auto_error=False)


class AuthenticatedResident:
    def __init__(self, user_id: str, email: Optional[str] = None, phone: Optional[str] = None, role: Optional[str] = None):
        self.user_id = user_id
        self.email = email
        self.phone = phone
        self.role = role


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    x_resident_id: Optional[str] = Header(None, alias="X-Resident-ID")
) -> AuthenticatedResident:
    """
    Validates Supabase JWT Bearer token or accepts dev-mode / header credentials.
    Extracts the resident's user_id and phone for profile linking.
    """
    # 1. Dev token or X-Resident-ID header shortcut (for local dev, offline field testing, and prototyping)
    if x_resident_id:
        return AuthenticatedResident(
            user_id=x_resident_id,
            phone="+919876543210",
            role="authenticated"
        )

    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    # Test / Dev token fast-path
    if token.startswith("dev-") or token.startswith("test-") or token == "mock-token":
        user_id = token.split("-", 1)[1] if "-" in token and len(token) > 10 else "00000000-0000-0000-0000-000000000001"
        return AuthenticatedResident(
            user_id=user_id,
            phone="+919876543210",
            role="authenticated"
        )

    try:
        # Decode and verify Supabase JWT
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated"
        )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing subject identifier",
            )
        return AuthenticatedResident(
            user_id=user_id,
            email=payload.get("email"),
            phone=payload.get("phone") or payload.get("phone_number"),
            role=payload.get("role")
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token has expired",
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
        )
