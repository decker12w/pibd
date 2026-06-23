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


tags_metadata = [
    {"name": "endereco", "description": "Endereços cadastrados no sistema."},
    {"name": "pessoa", "description": "Entidade base (CPF) da qual professor e aluno derivam."},
    {"name": "telefone", "description": "Telefones de uma pessoa (atributo multivalorado)."},
    {"name": "centro", "description": "Centros acadêmicos (unidades de nível mais alto)."},
    {"name": "departamento", "description": "Departamentos vinculados a um centro."},
    {"name": "curso", "description": "Cursos oferecidos pela instituição."},
    {"name": "disciplina", "description": "Disciplinas do currículo acadêmico."},
    {"name": "requisito", "description": "Pré-requisitos entre disciplinas."},
    {"name": "departamento_disciplina", "description": "Vínculo N:N entre departamento e disciplina."},
    {"name": "professor", "description": "Professores (especialização de pessoa)."},
    {"name": "aluno", "description": "Alunos (especialização de pessoa) e suas turmas/avaliações."},
    {"name": "sala", "description": "Salas físicas onde as aulas são ministradas."},
    {"name": "turma", "description": "Ofertas de disciplina em um período letivo, incluindo encerramento e listagem de alunos."},
    {"name": "turma_sala", "description": "Agendamento de turma em sala (dia/horário)."},
    {"name": "professor_turma", "description": "Vínculo N:N entre professor e turma (co-docência)."},
    {"name": "inscricao", "description": "Matrícula de um aluno em uma turma, incluindo verificação de aprovação."},
    {"name": "avaliacao", "description": "Notas lançadas para cada inscrição."},
]

app = FastAPI(
    title="PIBD API",
    description=(
        "API do banco acadêmico do projeto PIBD. Acesso ao Postgres é feito "
        "diretamente via psycopg2 (sem ORM), seguindo o schema definido em banco.sql. "
        "Além do CRUD de cada tabela, expõe rotas que chamam as functions/procedures "
        "já criadas no banco (aluno_aprovado, encerrar_turma)."
    ),
    version="0.1.0",
    openapi_tags=tags_metadata,
    lifespan=lifespan,
)

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


@app.get("/health", tags=["health"], summary="Verifica se a API está no ar")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/db", tags=["health"], summary="Verifica a conexão com o banco de dados")
def health_db(cursor=Depends(get_db_cursor)) -> dict[str, str]:
    cursor.execute("SELECT 1")
    cursor.fetchone()
    return {"status": "ok"}
