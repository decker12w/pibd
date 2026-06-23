from datetime import time

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.db.connection import get_db_cursor

router = APIRouter(prefix="/turma-sala", tags=["turma_sala"])

COLUMNS = "id_turma, id_sala, horarioinicio, horariofim, diasemana"


class TurmaSala(BaseModel):
    id_turma: int
    id_sala: int
    horarioinicio: time
    horariofim: time
    diasemana: str


class TurmaSalaUpdate(BaseModel):
    horariofim: time


@router.post("", response_model=TurmaSala, status_code=201)
def create_turma_sala(payload: TurmaSala, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        INSERT INTO turma_sala (id_turma, id_sala, horarioinicio, horariofim, diasemana)
        VALUES (%(id_turma)s, %(id_sala)s, %(horarioinicio)s, %(horariofim)s, %(diasemana)s)
        RETURNING {COLUMNS}
        """,
        payload.model_dump(),
    )
    return cursor.fetchone()


@router.get("", response_model=list[TurmaSala])
def list_turma_sala(cursor=Depends(get_db_cursor)):
    cursor.execute(f"SELECT {COLUMNS} FROM turma_sala ORDER BY id_turma, id_sala, horarioinicio")
    return cursor.fetchall()


@router.get("/{id_turma}/{id_sala}/{horarioinicio}/{diasemana}", response_model=TurmaSala)
def get_turma_sala(id_turma: int, id_sala: int, horarioinicio: time, diasemana: str, cursor=Depends(get_db_cursor)):
    cursor.execute(
        f"""
        SELECT {COLUMNS} FROM turma_sala
        WHERE id_turma = %s AND id_sala = %s AND horarioinicio = %s AND diasemana = %s
        """,
        (id_turma, id_sala, horarioinicio, diasemana),
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Agendamento de sala não encontrado")
    return row


@router.put("/{id_turma}/{id_sala}/{horarioinicio}/{diasemana}", response_model=TurmaSala)
def update_turma_sala(
    id_turma: int,
    id_sala: int,
    horarioinicio: time,
    diasemana: str,
    payload: TurmaSalaUpdate,
    cursor=Depends(get_db_cursor),
):
    cursor.execute(
        f"""
        UPDATE turma_sala
        SET horariofim = %(horariofim)s
        WHERE id_turma = %(id_turma)s AND id_sala = %(id_sala)s
            AND horarioinicio = %(horarioinicio)s AND diasemana = %(diasemana)s
        RETURNING {COLUMNS}
        """,
        {
            **payload.model_dump(),
            "id_turma": id_turma,
            "id_sala": id_sala,
            "horarioinicio": horarioinicio,
            "diasemana": diasemana,
        },
    )
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Agendamento de sala não encontrado")
    return row


@router.delete("/{id_turma}/{id_sala}/{horarioinicio}/{diasemana}", status_code=204)
def delete_turma_sala(id_turma: int, id_sala: int, horarioinicio: time, diasemana: str, cursor=Depends(get_db_cursor)):
    cursor.execute(
        """
        DELETE FROM turma_sala
        WHERE id_turma = %s AND id_sala = %s AND horarioinicio = %s AND diasemana = %s
        """,
        (id_turma, id_sala, horarioinicio, diasemana),
    )
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Agendamento de sala não encontrado")
