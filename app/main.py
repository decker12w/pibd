from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI

from app.core.exceptions import register_exception_handlers
from app.db.connection import close_pool, get_db_cursor, init_pool
from app.routers import (
    aluno,
    avaliacao,
    centro,
    curso,
    departamento,
    departamento_disciplina,
    disciplina,
    endereco,
    inscricao,
    pessoa,
    professor,
    professor_turma,
    requisito,
    sala,
    telefone,
    turma,
    turma_sala,
)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    init_pool()
    yield
    close_pool()


app = FastAPI(title="PIBD API", lifespan=lifespan)

register_exception_handlers(app)

for entity_router in (
    endereco.router,
    pessoa.router,
    telefone.router,
    centro.router,
    departamento.router,
    curso.router,
    disciplina.router,
    requisito.router,
    departamento_disciplina.router,
    professor.router,
    aluno.router,
    sala.router,
    turma.router,
    turma_sala.router,
    professor_turma.router,
    inscricao.router,
    avaliacao.router,
):
    app.include_router(entity_router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/db")
def health_db(cursor=Depends(get_db_cursor)) -> dict[str, str]:
    cursor.execute("SELECT 1")
    cursor.fetchone()
    return {"status": "ok"}
