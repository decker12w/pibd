# PIBD API

API em FastAPI para o banco acadêmico do projeto PIBD. Acesso ao PostgreSQL é feito **sem ORM**, diretamente via `psycopg2`, seguindo o schema definido em [banco.sql](banco.sql).

## Stack

- **FastAPI** — framework web
- **psycopg2** — driver PostgreSQL (raw SQL, sem ORM)
- **uv** — gerenciador de pacotes e ambiente Python
- **PostgreSQL 15** — via Docker Compose

## Estrutura

```
app/
  core/
    config.py        # settings (lidas de variáveis de ambiente)
    exceptions.py     # handler global que converte erros do psycopg2 em HTTP 400
  db/
    connection.py     # pool de conexões psycopg2 + dependency do cursor
  routers/             # um arquivo por tabela do banco.sql, com CRUD completo
  main.py              # cria o app, registra routers e o lifespan do pool
banco.sql              # schema, seeds, functions, procedures e triggers
docker-compose.yml      # serviço Postgres
Makefile                # comandos de atalho
```

## Pré-requisitos

- [uv](https://docs.astral.sh/uv/)
- Docker e Docker Compose

## Configuração

1. Copie o arquivo de ambiente:
   ```bash
   cp .env.example .env
   ```
   As variáveis já vêm alinhadas com o `docker-compose.yml` (usuário `admin`, banco `banco_pibd`, porta `5432`).

2. Instale as dependências:
   ```bash
   make install
   ```

## Banco de dados

```bash
make db-up      # sobe o Postgres
make db-reset   # recria o volume do zero e roda o banco.sql automaticamente
make db-logs    # acompanha os logs do container
make psql       # abre um psql dentro do container, já no banco banco_pibd
```

O `banco.sql` é montado em `/docker-entrypoint-initdb.d/`, então só é executado automaticamente quando o volume está **vazio** (primeira inicialização). Se o volume já existir com dados antigos, use `make db-reset` para recriá-lo.

> O `banco.sql` contém, propositalmente, alguns `INSERT`s de teste que devem falhar (para validar triggers). Isso é esperado e não impede a criação das tabelas — todo o schema, seeds, functions, procedures e triggers já foram aplicados antes desses testes.

## Rodando a API

```bash
make run   # só a API (uvicorn --reload)
make up    # sobe o Postgres e a API juntos
```

A API sobe em `http://localhost:8000`. Documentação interativa:

- Swagger: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Endpoints

CRUD completo (criar, listar, buscar, atualizar, remover) para as 17 tabelas do schema: `endereco`, `pessoa`, `telefone`, `centro`, `departamento`, `curso`, `disciplina`, `requisito`, `departamento_disciplina`, `professor`, `aluno`, `sala`, `turma`, `turma_sala`, `professor_turma`, `inscricao`, `avaliacao`.

Rotas adicionais que chamam functions/procedures já existentes no banco:

| Rota | Descrição |
|---|---|
| `GET /inscricao/{id_inscricao}/aprovado` | Chama a function `aluno_aprovado` e retorna se o aluno foi aprovado |
| `POST /turma/{id_turma}/encerrar` | Chama a procedure `encerrar_turma`, aprovando/reprovando as inscrições ativas |
| `GET /turma/{id_turma}/alunos` | Lista os alunos matriculados na turma com status e frequência |
| `GET /aluno/ra/{ra}/turmas` | Lista todas as turmas de um aluno (por RA) |
| `GET /aluno/ra/{ra}/turmas/{id_turma}/avaliacoes` | Lista as notas de um aluno em uma turma específica |
| `GET /health`, `GET /health/db` | Health check da API e da conexão com o banco |

Erros de integridade do banco (FK, UNIQUE, CHECK, `RAISE EXCEPTION` de procedures/triggers) são convertidos automaticamente em respostas HTTP 400 com a mensagem original do PostgreSQL.
