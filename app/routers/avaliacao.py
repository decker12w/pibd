from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/avaliacao", tags=["avaliacao"])

COLUMNS = "id_avaliacao, id_inscricao, nota, tipo, datalancamento"


class AvaliacaoBase(BaseModel):
    id_inscricao: int
    nota: Decimal
    tipo: str
    datalancamento: date


class AvaliacaoCreate(AvaliacaoBase):
    id_avaliacao: int


class Avaliacao(AvaliacaoBase):
    id_avaliacao: int


@router.post("", response_model=Avaliacao, status_code=201, summary="Lança uma avaliação (nota)")
def create_avaliacao(payload: AvaliacaoCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO avaliacao (id_avaliacao, id_inscricao, nota, tipo, datalancamento)
        VALUES (%(id_avaliacao)s, %(id_inscricao)s, %(nota)s, %(tipo)s, %(datalancamento)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Avaliacao], summary="Lista todas as avaliações")
def list_avaliacao(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM avaliacao ORDER BY id_avaliacao")
    return cursor.fetchall()


@router.get("/{id_avaliacao}", response_model=Avaliacao, summary="Busca uma avaliação pelo ID")
def get_avaliacao(id_avaliacao: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM avaliacao WHERE id_avaliacao = %s", (id_avaliacao,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Avaliação não encontrada")
    return row


@router.put("/{id_avaliacao}", response_model=Avaliacao, summary="Atualiza uma avaliação")
def update_avaliacao(id_avaliacao: int, payload: AvaliacaoBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE avaliacao
        SET id_inscricao = %(id_inscricao)s, nota = %(nota)s, tipo = %(tipo)s, datalancamento = %(datalancamento)s
        WHERE id_avaliacao = %(id_avaliacao)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_avaliacao": id_avaliacao},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Avaliação não encontrada")
    return row


@router.delete("/{id_avaliacao}", status_code=204, summary="Remove uma avaliação")
def delete_avaliacao(id_avaliacao: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM avaliacao WHERE id_avaliacao = %s", (id_avaliacao,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Avaliação não encontrada")
