from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/departamento-disciplina", tags=["departamento_disciplina"])

COLUMNS = "id_disciplina, id_departamento, tipo"


class DepartamentoDisciplina(BaseModel):
    id_disciplina: int
    id_departamento: int
    tipo: str


class DepartamentoDisciplinaUpdate(BaseModel):
    tipo: str


@router.post("", response_model=DepartamentoDisciplina, status_code=201)
def create_departamento_disciplina(payload: DepartamentoDisciplina, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO departamento_disciplina (id_disciplina, id_departamento, tipo)
        VALUES (%(id_disciplina)s, %(id_departamento)s, %(tipo)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[DepartamentoDisciplina])
def list_departamento_disciplina(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM departamento_disciplina ORDER BY id_disciplina, id_departamento")
    return cursor.fetchall()


@router.get("/{id_disciplina}/{id_departamento}", response_model=DepartamentoDisciplina)
def get_departamento_disciplina(id_disciplina: int, id_departamento: int, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"SELECT {COLUMNS} FROM departamento_disciplina WHERE id_disciplina = %s AND id_departamento = %s",
        (id_disciplina, id_departamento),
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Vínculo departamento/disciplina não encontrado")
    return row


@router.put("/{id_disciplina}/{id_departamento}", response_model=DepartamentoDisciplina)
def update_departamento_disciplina(
    id_disciplina: int, id_departamento: int, payload: DepartamentoDisciplinaUpdate, cursor=Depends(get_db_cursor)
):
    cursor.execute(
        f"""
        UPDATE departamento_disciplina
        SET tipo = %(tipo)s
        WHERE id_disciplina = %(id_disciplina)s AND id_departamento = %(id_departamento)s
        RETURNING {COLUMNS}
        """,
        {"tipo": payload.tipo, "id_disciplina": id_disciplina, "id_departamento": id_departamento},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Vínculo departamento/disciplina não encontrado")
    return row


@router.delete("/{id_disciplina}/{id_departamento}", status_code=204)
def delete_departamento_disciplina(id_disciplina: int, id_departamento: int, cursor=Depends(get_db_cursor)):
    cursor.execute(
        "DELETE FROM departamento_disciplina WHERE id_disciplina = %s AND id_departamento = %s",
        (id_disciplina, id_departamento),
    )
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Vínculo departamento/disciplina não encontrado")
