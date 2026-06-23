import psycopg2
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


def register_exception_handlers(app: FastAPI) -> None:
    async def handle_db_error(request: Request, exc: psycopg2.Error) -> JSONResponse:
        return JSONResponse(status_code=400, content={"detail": str(exc).strip()})

    app.add_exception_handler(psycopg2.Error, handle_db_error)
