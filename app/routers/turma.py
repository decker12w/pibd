from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/turma", tags=["turma"])

COLUMNS = "id_turma, id_disciplina, capacidademaxima, ano, semestre"


class TurmaBase(BaseModel):
    id_disciplina: int
    capacidademaxima: int
    ano: int
    semestre: int


class TurmaCreate(TurmaBase):
    id_turma: int


class Turma(TurmaBase):
    id_turma: int


class AlunoTurma(BaseModel):
    ra: str
    nome: str
    status: str
    frequencia: int
    datainscricao: date


class EncerrarTurmaResponse(BaseModel):
    id_turma: int
    mensagens: list[str]


@router.post("", response_model=Turma, status_code=201, summary="Cria uma turma")
def create_turma(payload: TurmaCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO turma (id_turma, id_disciplina, capacidademaxima, ano, semestre)
        VALUES (%(id_turma)s, %(id_disciplina)s, %(capacidademaxima)s, %(ano)s, %(semestre)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Turma], summary="Lista todas as turmas")
def list_turma(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM turma ORDER BY id_turma")
    return cursor.fetchall()


@router.get("/{id_turma}", response_model=Turma, summary="Busca uma turma pelo ID")
def get_turma(id_turma: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM turma WHERE id_turma = %s", (id_turma,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Turma não encontrada")
    return row


@router.put("/{id_turma}", response_model=Turma, summary="Atualiza uma turma")
def update_turma(id_turma: int, payload: TurmaBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE turma
        SET id_disciplina = %(id_disciplina)s, capacidademaxima = %(capacidademaxima)s,
            ano = %(ano)s, semestre = %(semestre)s
        WHERE id_turma = %(id_turma)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_turma": id_turma},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Turma não encontrada")
    return row


@router.delete("/{id_turma}", status_code=204, summary="Remove uma turma")
def delete_turma(id_turma: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM turma WHERE id_turma = %s", (id_turma,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Turma não encontrada")


@router.get(
    "/{id_turma}/alunos",
    response_model=list[AlunoTurma],
    summary="Lista os alunos de uma turma e seus status",
    description="Retorna RA, nome, status e frequência de cada aluno inscrito na turma, via join inscricao/aluno/pessoa.",
)
def list_alunos_turma(id_turma: int, cursor=Depends(get_db_cursor)):
    cursor.execute("SELECT 1 FROM turma WHERE id_turma = %s", (id_turma,))
    if cursor.fetchone() is None:
        raise HTTPException(status_code=404, detail="Turma não encontrada")

    cursor.execute(
        """
        SELECT a.ra, p.nome, i.status, i.frequencia, i.datainscricao
        FROM inscricao i
        JOIN aluno a ON a.ra = i.ra
        JOIN pessoa p ON p.cpf = a.cpf
        WHERE i.id_turma = %s
        ORDER BY p.nome
        """,
        (id_turma,),
    )
    return cursor.fetchall()


@router.post(
    "/{id_turma}/encerrar",
    response_model=EncerrarTurmaResponse,
    summary="Encerra uma turma",
    description=(
        "Chama a procedure `encerrar_turma` já existente no banco: aprova (status -> 'Concluída') ou reprova "
        "(status -> 'Reprovada') todas as inscrições 'Ativas' da turma, com base na function aluno_aprovado. "
        "As mensagens RAISE NOTICE emitidas pela procedure (quem foi aprovado/reprovado) são retornadas em "
        "`mensagens`."
    ),
)
def encerrar_turma(id_turma: int, cursor=Depends(get_db_cursor)):
    conn = cursor.connection
    conn.notices.clear()
    cursor.execute("CALL encerrar_turma(%s)", (id_turma,))
    return {"id_turma": id_turma, "mensagens": [n.strip() for n in conn.notices]}
