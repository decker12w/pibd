from collections.abc import Generator
from contextlib import contextmanager

from psycopg2.extensions import connection as PgConnection
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool

from app.core.config import settings

_pool: SimpleConnectionPool | None = None


def init_pool() -> None:
    global _pool
    _pool = SimpleConnectionPool(
        minconn=settings.db_pool_min_size,
        maxconn=settings.db_pool_max_size,
        dbname=settings.postgres_db,
        user=settings.postgres_user,
        password=settings.postgres_password,
        host=settings.postgres_host,
        port=settings.postgres_port,
    )


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.closeall()
        _pool = None


@contextmanager
def get_connection() -> Generator[PgConnection, None, None]:
    if _pool is None:
        raise RuntimeError("Connection pool was not initialized. Call init_pool() first.")
    conn = _pool.getconn()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        _pool.putconn(conn)


def get_db_cursor():
    with get_connection() as conn:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cur
        finally:
            cur.close()
