from collections.abc import Iterator

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import StaticPool


class Base(DeclarativeBase):
    pass


def make_engine(url: str) -> Engine:
    if url.startswith("sqlite"):
        kwargs: dict = {"connect_args": {"check_same_thread": False}}
        if url in ("sqlite://", "sqlite:///:memory:"):
            # Testlerde tüm bağlantılar aynı bellek içi veritabanını görsün.
            kwargs["poolclass"] = StaticPool
        engine = create_engine(url, **kwargs)

        @event.listens_for(engine, "connect")
        def _fk_on(dbapi_conn, _):  # SQLite'ta yabancı anahtarlar varsayılan kapalı
            dbapi_conn.execute("PRAGMA foreign_keys=ON")

        return engine
    # Render vb. "postgres://" verir; SQLAlchemy "postgresql+psycopg://" ister.
    if url.startswith("postgres://"):
        url = "postgresql+psycopg://" + url.removeprefix("postgres://")
    elif url.startswith("postgresql://"):
        url = "postgresql+psycopg://" + url.removeprefix("postgresql://")
    return create_engine(url, pool_pre_ping=True)


class Database:
    def __init__(self, url: str):
        self.engine = make_engine(url)
        self.sessions = sessionmaker(self.engine, expire_on_commit=False)

    def create_all(self) -> None:
        from . import models  # noqa: F401  (tabloları kaydetmek için)

        Base.metadata.create_all(self.engine)

    def session(self) -> Iterator[Session]:
        with self.sessions() as s:
            yield s
