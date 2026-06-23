.PHONY: help install db-up db-down db-reset db-logs psql run up

help:
	@echo "make install   - instala as dependencias com uv"
	@echo "make db-up     - sobe o Postgres (docker compose)"
	@echo "make db-down   - para o Postgres"
	@echo "make db-reset  - recria o volume do Postgres do zero (roda banco.sql)"
	@echo "make db-logs   - acompanha os logs do Postgres"
	@echo "make psql      - abre um psql dentro do container"
	@echo "make run       - roda a API (uvicorn --reload)"
	@echo "make up        - sobe o Postgres e roda a API"

install:
	uv sync

db-up:
	docker compose up -d

db-down:
	docker compose down

db-reset:
	docker compose down -v
	docker compose up -d

db-logs:
	docker compose logs -f db

psql:
	docker compose exec db psql -U admin -d banco_pibd

run:
	uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

up: db-up run
