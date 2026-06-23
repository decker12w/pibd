from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/requisito", tags=["requisito"])

COLUMNS = "id_disciplina, id_requisito"


class Requisito(BaseModel):
    id_disciplina: int
    id_requisito: int


@router.post("", response_model=Requisito, status_code=201)
def create_requisito(payload: Requisito, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO requisito (id_disciplina, id_requisito)
        VALUES (%(id_disciplina)s, %(id_requisito)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Requisito])
def list_requisito(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM requisito ORDER BY id_disciplina, id_requisito")
    return cursor.fetchall()


@router.get("/{id_disciplina}/{id_requisito}", response_model=Requisito)
def get_requisito(id_disciplina: int, id_requisito: int, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"SELECT {COLUMNS} FROM requisito WHERE id_disciplina = %s AND id_requisito = %s",
        (id_disciplina, id_requisito),
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Requisito não encontrado")
    return row


@router.delete("/{id_disciplina}/{id_requisito}", status_code=204)
def delete_requisito(id_disciplina: int, id_requisito: int, cursor=Depends(get_db_cursor)):
    cursor.execute(
        "DELETE FROM requisito WHERE id_disciplina = %s AND id_requisito = %s",
        (id_disciplina, id_requisito),
    )
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Requisito não encontrado")
