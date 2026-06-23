from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/curso", tags=["curso"])

COLUMNS = "id_curso, id_centro, titulo, grau, duracaominima, duracaomaxima, modalidade, cargahoraria"


class CursoBase(BaseModel):
    id_centro: int
    titulo: str
    grau: str
    duracaominima: int
    duracaomaxima: int
    modalidade: str
    cargahoraria: int


class CursoCreate(CursoBase):
    id_curso: int


class Curso(CursoBase):
    id_curso: int


@router.post("", response_model=Curso, status_code=201, summary="Cria um curso")
def create_curso(payload: CursoCreate, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO curso (id_curso, id_centro, titulo, grau, duracaominima, duracaomaxima, modalidade, cargahoraria)
        VALUES (%(id_curso)s, %(id_centro)s, %(titulo)s, %(grau)s, %(duracaominima)s, %(duracaomaxima)s, %(modalidade)s, %(cargahoraria)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[Curso], summary="Lista todos os cursos")
def list_curso(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM curso ORDER BY id_curso")
    return cursor.fetchall()


@router.get("/{id_curso}", response_model=Curso, summary="Busca um curso pelo ID")
def get_curso(id_curso: int, cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM curso WHERE id_curso = %s", (id_curso,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Curso não encontrado")
    return row


@router.put("/{id_curso}", response_model=Curso, summary="Atualiza um curso")
def update_curso(id_curso: int, payload: CursoBase, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        UPDATE curso
        SET id_centro = %(id_centro)s, titulo = %(titulo)s, grau = %(grau)s,
            duracaominima = %(duracaominima)s, duracaomaxima = %(duracaomaxima)s,
            modalidade = %(modalidade)s, cargahoraria = %(cargahoraria)s
        WHERE id_curso = %(id_curso)s
        RETURNING {COLUMNS}
        """,
        {**payload.model_dump(), "id_curso": id_curso},
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Curso não encontrado")
    return row


@router.delete("/{id_curso}", status_code=204, summary="Remove um curso")
def delete_curso(id_curso: int, cursor=Depends(get_db_cursor)):
    cursor.execute("DELETE FROM curso WHERE id_curso = %s", (id_curso,))
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Curso não encontrado")
