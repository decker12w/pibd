from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/pessoa", tags=["pessoa"])

COLUMNS = "cpf, nome, datanascimento, rua_numero, id_endereco, emaileducacional"


class PessoaBase(BaseModel):
    nome: str
    datanascimento: date
    rua_numero: str
    id_endereco: int
    emaileducacional: str


class PessoaCreate(PessoaBase):
    cpf: str


class Pessoa(PessoaBase):
    cpf: str


@router.post("", response_model=Pessoa, status_code=201)
def create_pessoa(payload: PessoaCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO pessoa (cpf, nome, datanascimento, rua_numero, id_endereco, emaileducacional)
        VALUES (%(cpf)s, %(nome)s, %(datanascimento)s, %(rua_numero)s, %(id_endereco)s, %(emaileducacional)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Pessoa])
def list_pessoa(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM pessoa ORDER BY cpf")
    return cursor.fetchall()


@router.get("/{cpf}", response_model=Pessoa)
def get_pessoa(cpf: str, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM pessoa WHERE cpf = %s", (cpf,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Pessoa não encontrada")
    return row


@router.put("/{cpf}", response_model=Pessoa)
def update_pessoa(cpf: str, payload: PessoaBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE pessoa
        SET nome = %(nome)s, datanascimento = %(datanascimento)s, rua_numero = %(rua_numero)s,
            id_endereco = %(id_endereco)s, emaileducacional = %(emaileducacional)s
        WHERE cpf = %(cpf)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "cpf": cpf},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Pessoa não encontrada")
    return row


@router.delete("/{cpf}", status_code=204)
def delete_pessoa(cpf: str, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM pessoa WHERE cpf = %s", (cpf,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Pessoa não encontrada")
