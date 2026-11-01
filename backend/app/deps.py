from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .config import Settings
from .models import Role, User
from .ratelimit import RateLimiter
from .security import decode_access_token

_bearer = HTTPBearer(auto_error=False)


def get_settings_dep(request: Request) -> Settings:
    return request.app.state.settings


def get_db(request: Request) -> Iterator[Session]:
    yield from request.app.state.db.session()


def get_limiter(request: Request) -> RateLimiter:
    return request.app.state.limiter


SettingsDep = Annotated[Settings, Depends(get_settings_dep)]
DbDep = Annotated[Session, Depends(get_db)]
LimiterDep = Annotated[RateLimiter, Depends(get_limiter)]


def _unauthorized() -> HTTPException:
    return HTTPException(
        status.HTTP_401_UNAUTHORIZED,
        "Oturum geçersiz ya da süresi dolmuş.",
        headers={"WWW-Authenticate": "Bearer"},
    )


def optional_user(
    db: DbDep,
    settings: SettingsDep,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> User | None:
    if creds is None:
        return None
    payload = decode_access_token(settings, creds.credentials)
    if payload is None:
        raise _unauthorized()
    user = db.get(User, payload.get("sub"))
    if user is None:
        raise _unauthorized()
    return user


def current_user(user: Annotated[User | None, Depends(optional_user)]) -> User:
    if user is None:
        raise _unauthorized()
    return user


def admin_user(user: Annotated[User, Depends(current_user)]) -> User:
    if user.role != Role.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Bu işlem için yönetici yetkisi gerekir.")
    return user


OptionalUser = Annotated[User | None, Depends(optional_user)]
CurrentUser = Annotated[User, Depends(current_user)]
AdminUser = Annotated[User, Depends(admin_user)]
