from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/departamento", tags=["departamento"])

COLUMNS = "id_departamento, id_centro, localizacao, nome"


class DepartamentoBase(BaseModel):
    id_centro: int
    localizacao: str
    nome: str


class DepartamentoCreate(DepartamentoBase):
    id_departamento: int


class Departamento(DepartamentoBase):
    id_departamento: int


@router.post("", response_model=Departamento, status_code=201, summary="Cria um departamento")
def create_departamento(payload: DepartamentoCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO departamento (id_departamento, id_centro, localizacao, nome)
        VALUES (%(id_departamento)s, %(id_centro)s, %(localizacao)s, %(nome)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Departamento], summary="Lista todos os departamentos")
def list_departamento(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM departamento ORDER BY id_departamento")
    return cursor.fetchall()


@router.get("/{id_departamento}", response_model=Departamento, summary="Busca um departamento pelo ID")
def get_departamento(id_departamento: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM departamento WHERE id_departamento = %s", (id_departamento,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Departamento não encontrado")
    return row


@router.put("/{id_departamento}", response_model=Departamento, summary="Atualiza um departamento")
def update_departamento(id_departamento: int, payload: DepartamentoBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE departamento
        SET id_centro = %(id_centro)s, localizacao = %(localizacao)s, nome = %(nome)s
        WHERE id_departamento = %(id_departamento)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_departamento": id_departamento},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Departamento não encontrado")
    return row


@router.delete("/{id_departamento}", status_code=204, summary="Remove um departamento")
def delete_departamento(id_departamento: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM departamento WHERE id_departamento = %s", (id_departamento,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Departamento não encontrado")
