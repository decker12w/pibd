from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/professor", tags=["professor"])

COLUMNS = "cpf, id_professor, id_departamento, titulo"


class ProfessorBase(BaseModel):
    id_professor: int
    id_departamento: int
    titulo: str


class ProfessorCreate(ProfessorBase):
    cpf: str


class Professor(ProfessorBase):
    cpf: str


@router.post("", response_model=Professor, status_code=201)
def create_professor(payload: ProfessorCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO professor (cpf, id_professor, id_departamento, titulo)
        VALUES (%(cpf)s, %(id_professor)s, %(id_departamento)s, %(titulo)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Professor])
def list_professor(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM professor ORDER BY cpf")
    return cursor.fetchall()


@router.get("/{cpf}", response_model=Professor)
def get_professor(cpf: str, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM professor WHERE cpf = %s", (cpf,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Professor não encontrado")
    return row


@router.put("/{cpf}", response_model=Professor)
def update_professor(cpf: str, payload: ProfessorBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE professor
        SET id_professor = %(id_professor)s, id_departamento = %(id_departamento)s, titulo = %(titulo)s
        WHERE cpf = %(cpf)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "cpf": cpf},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Professor não encontrado")
    return row


@router.delete("/{cpf}", status_code=204)
def delete_professor(cpf: str, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM professor WHERE cpf = %s", (cpf,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Professor não encontrado")
