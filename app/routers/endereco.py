from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/endereco", tags=["endereco"])

COLUMNS = "id_endereco, cidade, estado, rua, bairro, numero"


class EnderecoBase(BaseModel):
    cidade: str
    estado: str
    rua: str
    bairro: str
    numero: int


class EnderecoCreate(EnderecoBase):
    id_endereco: int


class Endereco(EnderecoBase):
    id_endereco: int


@router.post("", response_model=Endereco, status_code=201)
def create_endereco(payload: EnderecoCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO endereco (id_endereco, cidade, estado, rua, bairro, numero)
        VALUES (%(id_endereco)s, %(cidade)s, %(estado)s, %(rua)s, %(bairro)s, %(numero)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Endereco])
def list_endereco(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM endereco ORDER BY id_endereco")
    return cursor.fetchall()


@router.get("/{id_endereco}", response_model=Endereco)
def get_endereco(id_endereco: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM endereco WHERE id_endereco = %s", (id_endereco,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Endereco não encontrado")
    return row


@router.put("/{id_endereco}", response_model=Endereco)
def update_endereco(id_endereco: int, payload: EnderecoBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE endereco
        SET cidade = %(cidade)s, estado = %(estado)s, rua = %(rua)s,
            bairro = %(bairro)s, numero = %(numero)s
        WHERE id_endereco = %(id_endereco)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_endereco": id_endereco},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Endereco não encontrado")
    return row


@router.delete("/{id_endereco}", status_code=204)
def delete_endereco(id_endereco: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM endereco WHERE id_endereco = %s", (id_endereco,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Endereco não encontrado")
