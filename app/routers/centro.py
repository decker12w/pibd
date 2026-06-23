from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/centro", tags=["centro"])

COLUMNS = "id_centro, nome"


class CentroBase(BaseModel):
    nome: str


class CentroCreate(CentroBase):
    id_centro: int


class Centro(CentroBase):
    id_centro: int


@router.post("", response_model=Centro, status_code=201, summary="Cria um centro acadêmico")
def create_centro(payload: CentroCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO centro (id_centro, nome)
        VALUES (%(id_centro)s, %(nome)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Centro], summary="Lista todos os centros acadêmicos")
def list_centro(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM centro ORDER BY id_centro")
    return cursor.fetchall()


@router.get("/{id_centro}", response_model=Centro, summary="Busca um centro acadêmico pelo ID")
def get_centro(id_centro: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM centro WHERE id_centro = %s", (id_centro,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Centro não encontrado")
    return row


@router.put("/{id_centro}", response_model=Centro, summary="Atualiza um centro acadêmico")
def update_centro(id_centro: int, payload: CentroBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE centro
        SET nome = %(nome)s
        WHERE id_centro = %(id_centro)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_centro": id_centro},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Centro não encontrado")
    return row


@router.delete("/{id_centro}", status_code=204, summary="Remove um centro acadêmico")
def delete_centro(id_centro: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM centro WHERE id_centro = %s", (id_centro,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Centro não encontrado")
