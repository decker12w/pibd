from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/aluno", tags=["aluno"])

COLUMNS = "cpf, ra, id_curso"


class AlunoBase(BaseModel):
    ra: str
    id_curso: int


class AlunoCreate(AlunoBase):
    cpf: str


class Aluno(AlunoBase):
    cpf: str


class TurmaAluno(BaseModel):
    id_inscricao: int
    id_turma: int
    id_disciplina: int
    ano: int
    semestre: int
    status: str
    frequencia: int


class AvaliacaoAluno(BaseModel):
    id_avaliacao: int
    nota: Decimal
    tipo: str
    datalancamento: date


def _check_aluno_by_ra_or_404(ra: str, cursor) -> None:
    cursor.execute("SELECT 1 FROM aluno WHERE ra = %s", (ra,))
    if cursor.fetchone() is None:
        raise HTTPException(status_code=404, detail="Aluno não encontrado")


@router.post("", response_model=Aluno, status_code=201)
def create_aluno(payload: AlunoCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO aluno (cpf, ra, id_curso)
        VALUES (%(cpf)s, %(ra)s, %(id_curso)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Aluno])
def list_aluno(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM aluno ORDER BY cpf")
    return cursor.fetchall()


@router.get("/{cpf}", response_model=Aluno)
def get_aluno(cpf: str, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM aluno WHERE cpf = %s", (cpf,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Aluno não encontrado")
    return row


@router.put("/{cpf}", response_model=Aluno)
def update_aluno(cpf: str, payload: AlunoBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE aluno
        SET ra = %(ra)s, id_curso = %(id_curso)s
        WHERE cpf = %(cpf)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "cpf": cpf},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Aluno não encontrado")
    return row


@router.delete("/{cpf}", status_code=204)
def delete_aluno(cpf: str, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM aluno WHERE cpf = %s", (cpf,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Aluno não encontrado")


@router.get("/ra/{ra}/turmas", response_model=list[TurmaAluno])
def list_turmas_aluno(ra: str, cursor=Depends(get_db_cursor)):
    _check_aluno_by_ra_or_404(ra, cursor)

    cursor.execute(
        """
        SELECT i.id_inscricao, t.id_turma, t.id_disciplina, t.ano, t.semestre,
               i.status, i.frequencia
        FROM inscricao i
        JOIN turma t ON t.id_turma = i.id_turma
        WHERE i.ra = %s
        ORDER BY t.ano DESC, t.semestre DESC, t.id_turma
        """,
        (ra,),
    )
    return cursor.fetchall()


@router.get("/ra/{ra}/turmas/{id_turma}/avaliacoes", response_model=list[AvaliacaoAluno])
def list_avaliacoes_aluno_turma(ra: str, id_turma: int, cursor=Depends(get_db_cursor)):
    _check_aluno_by_ra_or_404(ra, cursor)

    cursor.execute("SELECT id_inscricao FROM inscricao WHERE ra = %s AND id_turma = %s", (ra, id_turma))
    inscricao = cursor.fetchone()
    if inscricao is None:
        raise HTTPException(status_code=404, detail="Aluno não está inscrito nessa turma")

    cursor.execute(
        """
        SELECT id_avaliacao, nota, tipo, datalancamento
        FROM avaliacao
        WHERE id_inscricao = %s
        ORDER BY datalancamento
        """,
        (inscricao["id_inscricao"],),
    )
    return cursor.fetchall()
