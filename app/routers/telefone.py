from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/telefone", tags=["telefone"])

COLUMNS = "cpf, numero"


class Telefone(BaseModel):
    cpf: str
    numero: str


@router.post("", response_model=Telefone, status_code=201, summary="Cadastra um telefone para uma pessoa")
def create_telefone(payload: Telefone, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO telefone (cpf, numero)
        VALUES (%(cpf)s, %(numero)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Telefone], summary="Lista todos os telefones")
def list_telefone(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM telefone ORDER BY cpf, numero")
    return cursor.fetchall()


@router.get("/{cpf}/{numero}", response_model=Telefone, summary="Busca um telefone pelo CPF e número")
def get_telefone(cpf: str, numero: str, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM telefone WHERE cpf = %s AND numero = %s", (cpf, numero))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Telefone não encontrado")
    return row


@router.delete("/{cpf}/{numero}", status_code=204, summary="Remove um telefone")
def delete_telefone(cpf: str, numero: str, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM telefone WHERE cpf = %s AND numero = %s", (cpf, numero))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Telefone não encontrado")
