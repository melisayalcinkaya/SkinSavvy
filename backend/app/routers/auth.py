from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Request, Response, status
from sqlalchemy import select

from ..deps import DbDep, LimiterDep, SettingsDep
from ..models import RefreshToken, User
from ..ratelimit import client_ip
from ..schemas import LoginIn, RefreshIn, RegisterIn, TokensOut
from ..security import hash_password, password_problem, token_digest, verify_password
from ..services import as_utc, issue_tokens, revoke_family

router = APIRouter(prefix="/auth", tags=["Hesap"])

_BAD_LOGIN = "E-posta ya da şifre hatalı."


def _ip(request: Request, settings) -> str:
    return client_ip(request) if settings.trust_forwarded_for else (request.client.host if request.client else "?")


@router.post("/register", response_model=TokensOut, status_code=status.HTTP_201_CREATED)
def register(body: RegisterIn, request: Request, db: DbDep, settings: SettingsDep, limiter: LimiterDep):
    limiter.hit(f"register:{_ip(request, settings)}", limit=5, window_seconds=3600)
    email = body.email.lower()
    if problem := password_problem(body.password, email, body.name):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, problem)
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(status.HTTP_409_CONFLICT, "Bu e-posta ile bir hesap zaten var.")
    user = User(email=email, name=body.name, password_hash=hash_password(body.password))
    db.add(user)
    db.commit()
    return issue_tokens(db, settings, user)


@router.post("/login", response_model=TokensOut)
def login(body: LoginIn, request: Request, db: DbDep, settings: SettingsDep, limiter: LimiterDep):
    email = body.email.lower()
    # Hem IP hem hesap başına sınır: tek hesaba dağıtık deneme de yavaşlar.
    limiter.hit(f"login-ip:{_ip(request, settings)}", limit=20, window_seconds=300)
    limiter.hit(f"login-acct:{email}", limit=8, window_seconds=300)
    user = db.scalar(select(User).where(User.email == email))
    # Bilinmeyen e-posta ve yanlış şifre aynı mesajı ve benzer süreyi alır.
    if not verify_password(body.password, user.password_hash if user else None) or user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, _BAD_LOGIN)
    return issue_tokens(db, settings, user)


@router.post("/refresh", response_model=TokensOut)
def refresh(body: RefreshIn, db: DbDep, settings: SettingsDep):
    token = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == token_digest(body.refresh_token)))
    if token is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Oturum geçersiz.")
    if token.revoked_at is not None:
        # İptal edilmiş token tekrar geldi: çalınmış olabilir, bütün oturum ailesini kapat.
        revoke_family(db, token.family)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Oturum geçersiz.")
    if as_utc(token.expires_at) <= datetime.now(UTC):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Oturumun süresi doldu.")
    user = db.get(User, token.user_id)
    token.revoked_at = datetime.now(UTC)
    db.commit()
    return issue_tokens(db, settings, user, family=token.family)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(body: RefreshIn, db: DbDep) -> Response:
    token = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == token_digest(body.refresh_token)))
    if token is not None:
        revoke_family(db, token.family)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
