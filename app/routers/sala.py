from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/sala", tags=["sala"])

COLUMNS = "id_sala, localizacao, capacidademaxima"


class SalaBase(BaseModel):
    localizacao: str
    capacidademaxima: int


class SalaCreate(SalaBase):
    id_sala: int


class Sala(SalaBase):
    id_sala: int


@router.post("", response_model=Sala, status_code=201)
def create_sala(payload: SalaCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO sala (id_sala, localizacao, capacidademaxima)
        VALUES (%(id_sala)s, %(localizacao)s, %(capacidademaxima)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Sala])
def list_sala(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM sala ORDER BY id_sala")
    return cursor.fetchall()


@router.get("/{id_sala}", response_model=Sala)
def get_sala(id_sala: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM sala WHERE id_sala = %s", (id_sala,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Sala não encontrada")
    return row


@router.put("/{id_sala}", response_model=Sala)
def update_sala(id_sala: int, payload: SalaBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE sala
        SET localizacao = %(localizacao)s, capacidademaxima = %(capacidademaxima)s
        WHERE id_sala = %(id_sala)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_sala": id_sala},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Sala não encontrada")
    return row


@router.delete("/{id_sala}", status_code=204)
def delete_sala(id_sala: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM sala WHERE id_sala = %s", (id_sala,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Sala não encontrada")
