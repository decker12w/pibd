from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/professor-turma", tags=["professor_turma"])

COLUMNS = "id_professor, id_turma"


class ProfessorTurma(BaseModel):
    id_professor: int
    id_turma: int


@router.post("", response_model=ProfessorTurma, status_code=201, summary="Vincula um professor a uma turma")
def create_professor_turma(payload: ProfessorTurma, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO professor_turma (id_professor, id_turma)
        VALUES (%(id_professor)s, %(id_turma)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[ProfessorTurma], summary="Lista todos os vínculos professor/turma")
def list_professor_turma(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM professor_turma ORDER BY id_professor, id_turma")
    return cursor.fetchall()


@router.get("/{id_professor}/{id_turma}", response_model=ProfessorTurma, summary="Busca um vínculo específico")
def get_professor_turma(id_professor: int, id_turma: int, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"SELECT {COLUMNS} FROM professor_turma WHERE id_professor = %s AND id_turma = %s",
        (id_professor, id_turma),
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Vínculo professor/turma não encontrado")
    return row


@router.delete("/{id_professor}/{id_turma}", status_code=204, summary="Remove um vínculo professor/turma")
def delete_professor_turma(id_professor: int, id_turma: int, cursor=Depends(get_db_cursor)):
    cursor.execute(
        "DELETE FROM professor_turma WHERE id_professor = %s AND id_turma = %s",
        (id_professor, id_turma),
    )
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Vínculo professor/turma não encontrado")
