from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/inscricao", tags=["inscricao"])

COLUMNS = "id_inscricao, id_turma, ra, status, datainscricao, frequencia"


class InscricaoBase(BaseModel):
    id_turma: int
    ra: str
    status: str
    datainscricao: date
    frequencia: int = 100


class InscricaoCreate(InscricaoBase):
    id_inscricao: int


class Inscricao(InscricaoBase):
    id_inscricao: int


class AprovadoResponse(BaseModel):
    id_inscricao: int
    aprovado: bool


@router.post("", response_model=Inscricao, status_code=201)
def create_inscricao(payload: InscricaoCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO inscricao (id_inscricao, id_turma, ra, status, datainscricao, frequencia)
        VALUES (%(id_inscricao)s, %(id_turma)s, %(ra)s, %(status)s, %(datainscricao)s, %(frequencia)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Inscricao])
def list_inscricao(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM inscricao ORDER BY id_inscricao")
    return cursor.fetchall()


@router.get("/{id_inscricao}", response_model=Inscricao)
def get_inscricao(id_inscricao: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM inscricao WHERE id_inscricao = %s", (id_inscricao,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Inscrição não encontrada")
    return row


@router.put("/{id_inscricao}", response_model=Inscricao)
def update_inscricao(id_inscricao: int, payload: InscricaoBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE inscricao
        SET id_turma = %(id_turma)s, ra = %(ra)s, status = %(status)s,
            datainscricao = %(datainscricao)s, frequencia = %(frequencia)s
        WHERE id_inscricao = %(id_inscricao)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_inscricao": id_inscricao},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Inscrição não encontrada")
    return row


@router.delete("/{id_inscricao}", status_code=204)
def delete_inscricao(id_inscricao: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM inscricao WHERE id_inscricao = %s", (id_inscricao,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Inscrição não encontrada")


@router.get("/{id_inscricao}/aprovado", response_model=AprovadoResponse)
def verificar_aprovacao(id_inscricao: int, cursor=Depends(get_db_cursor)):
    cursor.execute("SELECT 1 FROM inscricao WHERE id_inscricao = %s", (id_inscricao,))
    if cursor.fetchone() is None:
        raise HTTPException(status_code=404, detail="Inscrição não encontrada")

    cursor.execute("SELECT aluno_aprovado(%s) AS aprovado", (id_inscricao,))
    row = cursor.fetchone()
    return {"id_inscricao": id_inscricao, "aprovado": row["aprovado"]}
