from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/disciplina", tags=["disciplina"])

COLUMNS = "id_disciplina, titulo, ementa, cargahoraria, creditos"


class DisciplinaBase(BaseModel):
    titulo: str
    ementa: str
    cargahoraria: int
    creditos: int


class DisciplinaCreate(DisciplinaBase):
    id_disciplina: int


class Disciplina(DisciplinaBase):
    id_disciplina: int


@router.post("", response_model=Disciplina, status_code=201)
def create_disciplina(payload: DisciplinaCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO disciplina (id_disciplina, titulo, ementa, cargahoraria, creditos)
        VALUES (%(id_disciplina)s, %(titulo)s, %(ementa)s, %(cargahoraria)s, %(creditos)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Disciplina])
def list_disciplina(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM disciplina ORDER BY id_disciplina")
    return cursor.fetchall()


@router.get("/{id_disciplina}", response_model=Disciplina)
def get_disciplina(id_disciplina: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM disciplina WHERE id_disciplina = %s", (id_disciplina,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Disciplina não encontrada")
    return row


@router.put("/{id_disciplina}", response_model=Disciplina)
def update_disciplina(id_disciplina: int, payload: DisciplinaBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE disciplina
        SET titulo = %(titulo)s, ementa = %(ementa)s, cargahoraria = %(cargahoraria)s, creditos = %(creditos)s
        WHERE id_disciplina = %(id_disciplina)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_disciplina": id_disciplina},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Disciplina não encontrada")
    return row


@router.delete("/{id_disciplina}", status_code=204)
def delete_disciplina(id_disciplina: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM disciplina WHERE id_disciplina = %s", (id_disciplina,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Disciplina não encontrada")
