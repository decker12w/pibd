--
-- =============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS ACADÊMICO
--
-- =============================================================================

--
-- =============================================================================
-- e) CRIAÇÃO DO BANCO DE DADOS E IMPLEMENTAÇÃO DE RESTRIÇÕES
-- (PRIMARY KEY, FOREIGN KEY, NOT NULL, UNIQUE, CHECK, etc.)
--
-- =============================================================================

--
-- =============================================================================
-- TABELA: endereco
--
-- Armazena os endereços cadastrados no sistema. É criada antes de 'pessoa'
-- porque a tabela pessoa possui uma chave estrangeira para id_endereco.
-- A constraint de estado valida que apenas siglas em letras maiúsculas
-- (ex: SP, RJ) sejam aceitas.
--
-- =============================================================================
CREATE TABLE endereco (
id_endereco INT NOT NULL,

cidade VARCHAR(100) NOT NULL,
estado CHAR(2) NOT NULL,
rua VARCHAR(100) NOT NULL,
bairro VARCHAR(100) NOT NULL,
numero INT NOT NULL,
-- Garante que o estado seja exatamente 2 letras maiúsculas (ex: SP, MG)
CONSTRAINT chk_endereco_estado CHECK (estado ~ '^[A-Z]{2}$'),
CONSTRAINT pk_endereco PRIMARY KEY (id_endereco)
);

--
-- =============================================================================
-- TABELA: pessoa
--
-- Entidade base do modelo de herança por referência: tanto professores
-- quanto alunos estendem 'pessoa' via CPF. O CPF é a chave primária natural,
-- pois identifica univocamente qualquer indivíduo.
-- O e-mail educacional tem restrição de unicidade porque cada usuário deve
-- ter um endereço exclusivo no domínio institucional.
--
-- =============================================================================
CREATE TABLE pessoa (
cpf VARCHAR(11) NOT NULL,
nome VARCHAR(150) NOT NULL,
dataNascimento DATE NOT NULL,
rua_numero VARCHAR(200) NOT NULL,
id_endereco INT NOT NULL,
emailEducacional VARCHAR(200) NOT NULL,
-- Garante que o CPF contenha exatamente 11 dígitos numéricos
CONSTRAINT chk_pessoa_cpf CHECK (cpf ~ '^[0-9]{11}$'),
-- Validação básica de formato de e-mail
CONSTRAINT chk_pessoa_email CHECK (emailEducacional LIKE '%@%.%'),
-- Cada pessoa deve ter um e-mail institucional único
CONSTRAINT uq_pessoa_email UNIQUE (emailEducacional),
CONSTRAINT pk_pessoa PRIMARY KEY (cpf),
-- ON UPDATE CASCADE: propaga alterações no id_endereco automaticamente
-- ON DELETE RESTRICT: impede exclusão de um endereço que ainda está em uso
CONSTRAINT fk_pessoa_endereco
FOREIGN KEY (id_endereco)
REFERENCES endereco (id_endereco)

ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: telefone
--
-- Representa o atributo multivalorado 'telefone' de pessoa: uma mesma
-- pessoa pode ter vários números, mas o mesmo número não pode ser
-- registrado duas vezes para a mesma pessoa.
-- A chave primária composta (cpf, numero) garante essa unicidade.
-- ON DELETE CASCADE remove os telefones automaticamente quando a pessoa
-- é excluída, mantendo a integridade referencial sem registros órfãos.
--
-- =============================================================================
CREATE TABLE telefone (
cpf VARCHAR(11) NOT NULL,
numero VARCHAR(20) NOT NULL,
-- Aceita apenas dígitos, sem traços ou parênteses
CONSTRAINT chk_telefone_numero CHECK (numero ~ '^[0-9]+$'),
CONSTRAINT pk_telefone PRIMARY KEY (cpf, numero),
-- Remove os telefones ao excluir a pessoa correspondente
CONSTRAINT fk_telefone_pessoa
FOREIGN KEY (cpf)
REFERENCES pessoa (cpf)
ON UPDATE CASCADE
ON DELETE CASCADE
);

--
-- =============================================================================
-- TABELA: centro
--
-- Representa as unidades acadêmicas de nível mais alto da instituição
-- (ex: CCET). O nome do centro deve ser único para evitar duplicatas
-- cadastrais.
--
-- =============================================================================
CREATE TABLE centro (
id_centro INT NOT NULL,
nome VARCHAR(150) NOT NULL,

CONSTRAINT uq_centro_nome UNIQUE (nome),
CONSTRAINT pk_centro PRIMARY KEY (id_centro)
);

--
-- =============================================================================
-- TABELA: departamento
--
-- Cada departamento pertence a um centro. A localização descreve a
-- posição física (bloco e sala) do departamento no campus.
-- ON DELETE RESTRICT impede a exclusão de um centro que ainda possua
-- departamentos vinculados.
--
-- =============================================================================
CREATE TABLE departamento (
id_departamento INT NOT NULL,
id_centro INT NOT NULL,
localizacao VARCHAR(200) NOT NULL,
nome VARCHAR(150) NOT NULL,
CONSTRAINT uq_departamento_nome UNIQUE (nome),
CONSTRAINT pk_departamento PRIMARY KEY (id_departamento),
CONSTRAINT fk_departamento_centro
FOREIGN KEY (id_centro)
REFERENCES centro (id_centro)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: curso
--
-- Representa os cursos oferecidos pela instituição. A constraint de duração
-- garante que a duração máxima nunca seja menor que a mínima, e a constraint
-- de carga horária impede valores negativos ou zerados.
--
-- =============================================================================
CREATE TABLE curso (
id_curso INT NOT NULL,
id_centro INT NOT NULL,
titulo VARCHAR(200) NOT NULL,
grau VARCHAR(50) NOT NULL,

duracaoMinima INT NOT NULL,
duracaoMaxima INT NOT NULL,
modalidade VARCHAR(50) NOT NULL,
cargaHoraria INT NOT NULL,
-- Garante consistência entre a duração mínima e máxima do curso
CONSTRAINT chk_curso_duracao CHECK (duracaoMaxima >= duracaoMinima),
CONSTRAINT chk_curso_cargaHoraria CHECK (cargaHoraria > 0),
CONSTRAINT pk_curso PRIMARY KEY (id_curso),
CONSTRAINT fk_curso_centro
FOREIGN KEY (id_centro)
REFERENCES centro (id_centro)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: disciplina
--
-- Representa as disciplinas do currículo acadêmico, independentemente de
-- em qual turma ou período são ofertadas. Créditos e carga horária devem
-- ser sempre positivos.
--
-- =============================================================================
CREATE TABLE disciplina (
id_disciplina INT NOT NULL,
titulo VARCHAR(200) NOT NULL,
ementa TEXT NOT NULL,
cargaHoraria INT NOT NULL,
creditos INT NOT NULL,
CONSTRAINT chk_disciplina_cargaHoraria CHECK (cargaHoraria > 0),
CONSTRAINT chk_disciplina_creditos CHECK (creditos > 0),
CONSTRAINT pk_disciplina PRIMARY KEY (id_disciplina)
);

--
-- =============================================================================
-- TABELA: requisito
--
-- Modela o auto-relacionamento de pré-requisitos entre disciplinas.
-- A constraint chk_requisito_self impede que uma disciplina seja

-- registrada como pré-requisito de si mesma.
-- A chave primária composta (id_disciplina, id_requisito) garante que
-- o mesmo par não seja cadastrado duas vezes.
-- Ambas as FKs apontam para 'disciplina' com ON DELETE CASCADE, de forma
-- que ao remover uma disciplina todos os seus vínculos de pré-requisito
-- são removidos automaticamente.
--
-- =============================================================================
CREATE TABLE requisito (
id_disciplina INT NOT NULL,
id_requisito INT NOT NULL,
-- Impede que uma disciplina seja pré-requisito de si mesma
CONSTRAINT chk_requisito_self CHECK (id_disciplina <> id_requisito),
CONSTRAINT pk_requisito PRIMARY KEY (id_disciplina, id_requisito),
CONSTRAINT fk_requisito_disciplina
FOREIGN KEY (id_disciplina)
REFERENCES disciplina (id_disciplina)
ON UPDATE CASCADE
ON DELETE CASCADE,
CONSTRAINT fk_requisito_requisito
FOREIGN KEY (id_requisito)
REFERENCES disciplina (id_disciplina)
ON UPDATE CASCADE
ON DELETE CASCADE
);

--
-- =============================================================================
-- TABELA: departamento_disciplina
--
-- Relacionamento N:N entre departamento e disciplina. O atributo 'tipo'
-- indica a natureza da disciplina (ex: 'presencial', 'remoto')
--
-- ==============================================================================
CREATE TABLE departamento_disciplina (
id_disciplina INT NOT NULL,
id_departamento INT NOT NULL,
tipo VARCHAR(50) NOT NULL,
CONSTRAINT pk_departamento_disciplina PRIMARY KEY (id_disciplina,
id_departamento),
CONSTRAINT fk_depdis_disciplina

FOREIGN KEY (id_disciplina)
REFERENCES disciplina (id_disciplina)
ON UPDATE CASCADE
ON DELETE CASCADE,
CONSTRAINT fk_depdis_departamento
FOREIGN KEY (id_departamento)
REFERENCES departamento (id_departamento)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: professor
--
-- Especialização de 'pessoa' pelo padrão de herança por referência:
-- o CPF é ao mesmo tempo PK e FK para 'pessoa', garantindo que todo
-- professor tenha um registro correspondente na entidade base.
-- O campo id_professor representa a matrícula funcional institucional,
-- que é distinta do CPF e também deve ser única.
--
-- =============================================================================
CREATE TABLE professor (
cpf VARCHAR(11) NOT NULL,
id_professor INT NOT NULL,
id_departamento INT NOT NULL,
titulo VARCHAR(100) NOT NULL,
-- Garante unicidade da matrícula funcional do professor
CONSTRAINT uq_professor_id UNIQUE (id_professor),
CONSTRAINT pk_professor PRIMARY KEY (cpf),
CONSTRAINT fk_professor_pessoa
FOREIGN KEY (cpf)
REFERENCES pessoa (cpf)
ON UPDATE CASCADE
ON DELETE RESTRICT,
CONSTRAINT fk_professor_departamento
FOREIGN KEY (id_departamento)
REFERENCES departamento (id_departamento)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: aluno
--
-- Especialização de 'pessoa', seguindo o mesmo padrão de herança do professor.
-- O RA (Registro Acadêmico) é o identificador público do aluno no sistema,
-- deve ser único e é utilizado como FK em inscrições.
--
-- =============================================================================
CREATE TABLE aluno (
cpf VARCHAR(11) NOT NULL,
ra VARCHAR(20) NOT NULL,
id_curso INT NOT NULL,
-- O RA é o identificador público do aluno, deve ser único
CONSTRAINT uq_aluno_ra UNIQUE (ra),
CONSTRAINT pk_aluno PRIMARY KEY (cpf),
CONSTRAINT fk_aluno_curso
FOREIGN KEY (id_curso)
REFERENCES curso (id_curso),
CONSTRAINT fk_aluno_pessoa
FOREIGN KEY (cpf)
REFERENCES pessoa (cpf)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: sala
--
-- Representa os espaços físicos onde as aulas são ministradas. A capacidade
-- máxima deve ser maior que zero para garantir que a sala seja utilizável.
--
-- =============================================================================
CREATE TABLE sala (
id_sala INT NOT NULL,
localizacao VARCHAR(200) NOT NULL,
capacidadeMaxima INT NOT NULL,
CONSTRAINT chk_sala_capacidade CHECK (capacidadeMaxima > 0),
CONSTRAINT pk_sala PRIMARY KEY (id_sala)
);

--
-- =============================================================================

-- TABELA: turma
--
-- Representa a oferta de uma disciplina em um período letivo específico
-- (ano e semestre). O semestre é restrito a 1 ou 2.
--
-- =============================================================================
CREATE TABLE turma (
id_turma INT NOT NULL,
id_disciplina INT NOT NULL,
capacidadeMaxima INT NOT NULL,
ano INT NOT NULL,
semestre INT NOT NULL,
CONSTRAINT chk_turma_capacidade CHECK (capacidadeMaxima > 0),
-- Semestre aceita apenas os valores 1 e 2
CONSTRAINT chk_turma_semestre CHECK (semestre IN (1, 2)),
CONSTRAINT pk_turma PRIMARY KEY (id_turma),
CONSTRAINT fk_turma_disciplina
FOREIGN KEY (id_disciplina)
REFERENCES disciplina (id_disciplina)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: turma_sala
--
-- Associa uma turma a uma sala com dia da semana e horário. A chave primária
-- composta (id_turma, id_sala, horarioInicio, diaSemana, ano, semestre)
-- impede o agendamento duplicado exato da mesma sala no mesmo horário e dia
-- dentro do mesmo período letivo.
-- A constraint de horário garante que o fim sempre seja posterior ao início.
--
-- =============================================================================
CREATE TABLE turma_sala (
id_turma INT NOT NULL,
id_sala INT NOT NULL,
horarioInicio TIME NOT NULL,
horarioFim TIME NOT NULL,
diaSemana VARCHAR(15) NOT NULL,
-- Garante que o horário de fim seja sempre posterior ao de início
CONSTRAINT chk_turmasala_horario CHECK (horarioFim > horarioInicio),

-- Restringe os dias da semana a valores válidos no contexto acadêmico
CONSTRAINT chk_turmasala_dia CHECK (
diaSemana IN ('Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta',
'Sábado')
),
CONSTRAINT pk_turma_sala PRIMARY KEY (id_turma, id_sala, horarioInicio,
diaSemana),
CONSTRAINT fk_turmasala_turma
FOREIGN KEY (id_turma)
REFERENCES turma (id_turma)
ON UPDATE CASCADE
ON DELETE CASCADE,
CONSTRAINT fk_turmasala_sala
FOREIGN KEY (id_sala)
REFERENCES sala (id_sala)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: professor_turma
--
-- Relacionamento N:N entre professor e turma, possibilitando co-docência.
-- A FK referencia id_professor (matrícula funcional), e não o CPF, porque
-- é o identificador usado operacionalmente para associar professores a turmas.
--
-- =============================================================================
CREATE TABLE professor_turma (
id_professor INT NOT NULL,
id_turma INT NOT NULL,
CONSTRAINT pk_professor_turma PRIMARY KEY (id_professor, id_turma),
CONSTRAINT fk_profturma_professor
FOREIGN KEY (id_professor)
REFERENCES professor (id_professor)
ON UPDATE CASCADE
ON DELETE RESTRICT,
CONSTRAINT fk_profturma_turma

FOREIGN KEY (id_turma)
REFERENCES turma (id_turma)
ON UPDATE CASCADE
ON DELETE CASCADE
);

--
-- =============================================================================
-- TABELA: inscricao
--
-- Registra a matrícula de um aluno em uma turma. A constraint UNIQUE
-- (ra, id_turma) impede que o mesmo aluno se inscreva duas vezes na
-- mesma turma. O status controla o ciclo de vida da matrícula e é
-- restrito a valores predefinidos para garantir consistência nos relatórios.
-- A frequencia armazena o percentual de presença do aluno na turma
-- (inteiro de 0 a 100) e é usada como critério de aprovação.
--
-- =============================================================================
CREATE TABLE inscricao (
id_inscricao INT NOT NULL,
id_turma INT NOT NULL,
ra VARCHAR(20) NOT NULL,
status VARCHAR(30) NOT NULL,
dataInscricao DATE NOT NULL,
frequencia INT NOT NULL DEFAULT 100,
-- Valores permitidos para o status da inscrição, representando
-- todos os estados possíveis do ciclo de vida de uma matrícula
CONSTRAINT chk_inscricao_status CHECK (
status IN ('Ativa', 'Cancelada', 'Trancada', 'Concluída', 'Reprovada')
),
-- A frequência deve ser um percentual válido entre 0 e 100
CONSTRAINT chk_inscricao_frequencia CHECK (frequencia >= 0 AND frequencia
<= 100),
-- Impede dupla matrícula do mesmo aluno na mesma turma
CONSTRAINT uq_inscricao_aluno_turma UNIQUE (ra, id_turma),
CONSTRAINT pk_inscricao PRIMARY KEY (id_inscricao),
CONSTRAINT fk_inscricao_turma
FOREIGN KEY (id_turma)
REFERENCES turma (id_turma)
ON UPDATE CASCADE
ON DELETE RESTRICT,

CONSTRAINT fk_inscricao_aluno
FOREIGN KEY (ra)
REFERENCES aluno (ra)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

--
-- =============================================================================
-- TABELA: avaliacao
--
-- Registra as notas lançadas para cada inscrição. NUMERIC(4,2) garante
-- precisão de até duas casas decimais com valores entre 0.00 e 10.00.
-- ON DELETE CASCADE remove as avaliações quando a inscrição correspondente
-- é excluída, evitando registros de notas sem vínculo.
--
-- =============================================================================
CREATE TABLE avaliacao (
id_avaliacao INT NOT NULL,
id_inscricao INT NOT NULL,
nota NUMERIC(4,2) NOT NULL,
tipo VARCHAR(50) NOT NULL,
dataLancamento DATE NOT NULL,
-- A nota deve estar no intervalo válido de 0 a 10
CONSTRAINT chk_avaliacao_nota CHECK (nota >= 0 AND nota <= 10),
CONSTRAINT pk_avaliacao PRIMARY KEY (id_avaliacao),
CONSTRAINT fk_avaliacao_inscricao
FOREIGN KEY (id_inscricao)
REFERENCES inscricao (id_inscricao)
ON UPDATE CASCADE
ON DELETE CASCADE
);

--
-- =============================================================================
-- f) CRIAÇÃO DE ÍNDICES (mínimo de 5 índices)
--
-- Índices aceleram consultas frequentes. PRIMARY KEYs e UNIQUE já criam
-- índices automaticamente; os abaixo são índices adicionais para otimizar
-- operações de leitura em colunas usadas recorrentemente em JOINs, WHERE
-- e ORDER BY.
--
-- =============================================================================

-- Índice 1: Busca de pessoas por nome
-- Buscas por nome parcial (LIKE 'João%') são comuns em sistemas acadêmicos.
-- O índice evita varredura completa da tabela pessoa.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_pessoa_nome
ON pessoa USING gin (nome gin_trgm_ops);


-- Índice 2: Busca de inscrições por status
-- Relatórios filtram frequentemente por status
-- (ex: todas as inscrições 'Ativas' de um semestre).
CREATE INDEX idx_inscricao_status
ON inscricao (status);

-- Índice 3: Busca de turmas por ano e semestre
-- A combinação (ano, semestre) é o filtro mais comum ao listar turmas
-- de um período letivo específico.
CREATE INDEX idx_turma_ano_semestre
ON turma (ano, semestre);

-- Índice 4: Busca de inscrições por RA do aluno
-- Consultar todas as turmas de um aluno pelo RA é uma operação frequente
-- (histórico escolar, portal do aluno).
CREATE INDEX idx_inscricao_ra
ON inscricao (ra);

-- Índice 5: Busca de professores por departamento
-- Listar todos os professores de um departamento é comum em relatórios
-- administrativos e páginas de departamento.
CREATE INDEX idx_professor_departamento
ON professor (id_departamento);

-- Índice 6: Busca de avaliações por inscrição
-- Ao exibir o boletim de um aluno, todas as avaliações de uma inscrição
-- são consultadas juntas; o índice acelera esse JOIN.
CREATE INDEX idx_avaliacao_inscricao
ON avaliacao (id_inscricao);

-- Índice 7: Busca de turmas por disciplina
-- Encontrar todas as ofertas de uma disciplina
-- (ex: quantas turmas de Cálculo I existem este semestre).
CREATE INDEX idx_turma_disciplina

ON turma (id_disciplina);

--
-- =============================================================================
-- g) INSERÇÃO DE DADOS DE TESTE (10-20 registros por tabela)
--
-- A ordem de inserção respeita as dependências de FK:
-- tabelas referenciadas são populadas antes das que as referenciam.
--
-- =============================================================================

--
-----------------------------------------------------------------------------
-- endereco (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO endereco (id_endereco, cidade, estado, rua, bairro, numero) VALUES
(1, 'São Carlos', 'SP', 'Rua XV de Novembro', 'Centro',
100),
(2, 'São Paulo', 'SP', 'Av. Paulista', 'Bela Vista',
1000),
(3, 'Campinas', 'SP', 'Rua Barreto Leme', 'Centro',
50),
(4, 'Rio de Janeiro', 'RJ', 'Rua da Carioca', 'Centro',
200),
(5, 'Belo Horizonte', 'MG', 'Av. Afonso Pena', 'Centro',
300),
(6, 'Porto Alegre', 'RS', 'Rua dos Andradas', 'Centro',
150),
(7, 'Curitiba', 'PR', 'Rua das Flores', 'Centro',
80),
(8, 'Fortaleza', 'CE', 'Av. Beira Mar', 'Meireles',
400),
(9, 'Manaus', 'AM', 'Av. Eduardo Ribeiro', 'Centro',
500),
(10, 'Brasília', 'DF', 'SQN 204', 'Asa Norte',
10);

--
-----------------------------------------------------------------------------
-- centro (5 registros)
--
-----------------------------------------------------------------------------
INSERT INTO centro (id_centro, nome) VALUES
(1, 'Centro de Ciências Exatas e Tecnologia'),

(2, 'Centro de Ciências Humanas'),
(3, 'Centro de Ciências Biológicas e da Saúde'),
(4, 'Centro de Educação e Ciências Humanas'),
(5, 'Centro de Ciências Agrárias');

--
-----------------------------------------------------------------------------
-- departamento (10 registros)
-- A localização agora é uma string de endereço (logradouro, número e bairro).
--
-----------------------------------------------------------------------------
INSERT INTO departamento (id_departamento, id_centro, localizacao, nome) VALUES
(1, 1, 'Rua Marechal Deodoro, 1100 - Centro', 'Departamento de
Computação'),
(2, 1, 'Av. Trabalhador São-carlense, 400 - Centro', 'Departamento de
Matemática'),
(3, 1, 'Rua Episcopal, 1575 - Centro', 'Departamento de
Física'),
(4, 1, 'Av. São Carlos, 2300 - Centro', 'Departamento de
Química'),
(5, 2, 'Rua Sete de Setembro, 850 - Centro', 'Departamento de
Letras'),
(6, 2, 'Av. Comendador Alfredo Maffei, 920 - Vila Prado', 'Departamento de
História'),
(7, 3, 'Rua Padre Teixeira, 640 - Jardim Lutfalla', 'Departamento de
Medicina'),
(8, 3, 'Av. Dr. Carlos Botelho, 1750 - Centro', 'Departamento de
Enfermagem'),
(9, 4, 'Rua Larga, 230 - Vila Nery', 'Departamento de
Pedagogia'),
(10, 5, 'Av. Getúlio Vargas, 1280 - Vila Nery', 'Departamento de
Agronomia');

--
-----------------------------------------------------------------------------
-- curso (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO curso (id_curso, id_centro, titulo, grau, duracaoMinima,
duracaoMaxima, modalidade, cargaHoraria) VALUES
(1, 1, 'Ciência da Computação', 'Bacharelado', 8, 12, 'Presencial',
3200),
(2, 1, 'Engenharia de Software', 'Bacharelado', 8, 12, 'Presencial',
3600),
(3, 1, 'Matemática', 'Licenciatura', 8, 12, 'Presencial',
2800),

(4, 1, 'Física', 'Bacharelado', 8, 12, 'Presencial',
3000),
(5, 2, 'Letras - Português', 'Licenciatura', 8, 12, 'Presencial',
2800),
(6, 2, 'História', 'Licenciatura', 8, 12, 'Presencial',
2800),
(7, 3, 'Medicina', 'Bacharelado', 12, 14, 'Presencial',
7200),
(8, 3, 'Enfermagem', 'Bacharelado', 10, 12, 'Presencial',
4000),
(9, 4, 'Pedagogia', 'Licenciatura', 8, 10, 'Híbrido',
3200),
(10, 1, 'Sistemas de Informação', 'Bacharelado', 8, 12, 'EAD',
3000);

--
-----------------------------------------------------------------------------
-- pessoa (15 registros)
-- Inclui pessoas que serão professores e alunos
--
-----------------------------------------------------------------------------
INSERT INTO pessoa (cpf, nome, dataNascimento, rua_numero, id_endereco,
emailEducacional) VALUES
('12345678901', 'Ana Paula Ferreira', '1985-03-15', 'Rua XV de Novembro,
100', 1, 'ana.ferreira@ufscar.br'),
('23456789012', 'Carlos Eduardo Lima', '1979-07-22', 'Av. Paulista, 1000',
2, 'carlos.lima@ufscar.br'),
('34567890123', 'Beatriz Santos Oliveira', '1990-11-05', 'Rua Barreto Leme,
50', 3, 'beatriz.oliveira@ufscar.br'),
('45678901234', 'Diego Marques Costa', '1988-04-30', 'Rua da Carioca, 200',
4, 'diego.costa@ufscar.br'),
('56789012345', 'Fernanda Rocha Nunes', '1995-08-12', 'Av. Afonso Pena,
300', 5, 'fernanda.nunes@estudante.ufscar.br'),
('67890123456', 'Gabriel Souza Mendes', '1998-02-28', 'Rua dos Andradas,
150', 6, 'gabriel.mendes@estudante.ufscar.br'),
('78901234567', 'Helena Carvalho Dias', '1997-06-17', 'Rua das Flores, 80',
7, 'helena.dias@estudante.ufscar.br'),
('89012345678', 'Igor Almeida Batista', '1999-09-03', 'Av. Beira Mar, 400',
8, 'igor.batista@estudante.ufscar.br'),
('90123456789', 'Juliana Pinto Araújo', '1996-12-25', 'Av. Eduardo Ribeiro,
500', 9, 'juliana.araujo@estudante.ufscar.br'),
('01234567890', 'Lucas Vieira Teixeira', '2000-01-10', 'SQN 204, 10',
10, 'lucas.teixeira@estudante.ufscar.br'),
('11122233344', 'Marcos Antônio Silva', '1982-05-20', 'Rua XV de Novembro,
200', 1, 'marcos.silva@ufscar.br'),
('22233344455', 'Natália Gomes Ribeiro', '1993-10-14', 'Av. Paulista, 2000',
2, 'natalia.ribeiro@estudante.ufscar.br'),

('33344455566', 'Otávio Nascimento Cruz', '1994-03-08', 'Rua Barreto Leme,
100', 3, 'otavio.cruz@estudante.ufscar.br'),
('44455566677', 'Patrícia Lopes Freitas', '1991-07-19', 'Rua da Carioca, 300',
4, 'patricia.freitas@ufscar.br'),
('55566677788', 'Rafael Moreira Campos', '1987-09-27', 'Av. Afonso Pena,
500', 5, 'rafael.campos@ufscar.br');

--
-----------------------------------------------------------------------------
-- telefone (15 registros)
--
-----------------------------------------------------------------------------
INSERT INTO telefone (cpf, numero) VALUES
('12345678901', '16999110001'),
('23456789012', '11999220002'),
('34567890123', '19999330003'),
('45678901234', '21999440004'),
('56789012345', '31999550005'),
('67890123456', '51999660006'),
('78901234567', '41999770007'),
('89012345678', '85999880008'),
('90123456789', '92999990009'),
('01234567890', '61999100010'),
('11122233344', '16999111111'),
('22233344455', '11999222222'),
('33344455566', '19999333333'),
('44455566677', '21999444444'),
('55566677788', '31999555555');

--
-----------------------------------------------------------------------------
-- professor (5 registros)
--
-----------------------------------------------------------------------------
INSERT INTO professor (cpf, id_professor, id_departamento, titulo) VALUES
('12345678901', 101, 1, 'Titular'),
('23456789012', 102, 2, 'Titular'),
('34567890123', 103, 1, 'Adjunto'),
('44455566677', 104, 3, 'Associado'),
('55566677788', 105, 5, 'Titular');

--
-----------------------------------------------------------------------------
-- aluno (10 registros)

--
-----------------------------------------------------------------------------
INSERT INTO aluno (cpf, ra, id_curso) VALUES
('56789012345', '758001', 1),
('67890123456', '758002', 2),
('78901234567', '758003', 1),
('89012345678', '758004', 10),
('90123456789', '758005', 1),
('01234567890', '758006', 3),
('11122233344', '758007', 2),
('22233344455', '758008', 5),
('33344455566', '758009', 6),
('45678901234', '758010', 4);

--
-----------------------------------------------------------------------------
-- disciplina (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO disciplina (id_disciplina, titulo, ementa, cargaHoraria, creditos)
VALUES
(1, 'Introdução à Programação', 'Lógica de programação, algoritmos e
estruturas básicas em Python.', 60, 4),
(2, 'Cálculo I', 'Limites, derivadas e integrais de
funções de uma variável.', 90, 6),
(3, 'Estruturas de Dados', 'Listas, pilhas, filas, árvores e
grafos.', 60, 4),
(4, 'Banco de Dados', 'Modelo relacional, SQL, normalização e
transações.', 60, 4),
(5, 'Álgebra Linear', 'Vetores, matrizes, sistemas lineares e
transformações lineares.', 60, 4),
(6, 'Programação Orientada a Objetos','Classes, herança, polimorfismo e
padrões de projeto.', 60, 4),
(7, 'Redes de Computadores', 'Modelo OSI, TCP/IP, protocolos e
segurança de redes.', 60, 4),
(8, 'Engenharia de Software', 'Processos de desenvolvimento, UML,
testes e gerência de projetos.', 60, 4),
(9, 'Sistemas Operacionais', 'Processos, threads, memória, sistemas de
arquivos e escalonamento.', 60, 4),
(10, 'Inteligência Artificial', 'Busca, aprendizado de máquina, redes
neurais e PLN.', 60, 4);

--
-----------------------------------------------------------------------------
-- requisito (8 registros)
-- Estrutura de pré-requisitos entre disciplinas

--
-----------------------------------------------------------------------------
INSERT INTO requisito (id_disciplina, id_requisito) VALUES
(3, 1), -- Estruturas de Dados requer Introdução à Programação
(4, 1), -- Banco de Dados requer Introdução à Programação
(5, 2), -- Álgebra Linear requer Cálculo I
(6, 1), -- POO requer Introdução à Programação
(7, 3), -- Redes requer Estruturas de Dados
(8, 6), -- Eng. de Software requer POO
(9, 3), -- Sistemas Operacionais requer Estruturas de Dados
(10, 6); -- IA requer POO

--
-----------------------------------------------------------------------------
-- departamento_disciplina (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO departamento_disciplina (id_disciplina, id_departamento, tipo)
VALUES
(1, 1, 'presencial'),
(2, 2, 'presencial'),
(3, 1, 'presencial'),
(4, 1, 'presencial'),
(5, 2, 'presencial'),
(6, 1, 'presencial'),
(7, 1, 'presencial'),
(8, 1, 'EAD'),
(9, 1, 'EAD'),
(10, 1, 'EAD');

--
-----------------------------------------------------------------------------
-- sala (10 registros)
-- O bloco da localização passou a usar a nomenclatura AT1, AT2, etc.
--
-----------------------------------------------------------------------------
INSERT INTO sala (id_sala, localizacao, capacidadeMaxima) VALUES
(1, 'AT1 - Sala 101', 40),
(2, 'AT1 - Sala 102', 40),
(3, 'AT2 - Sala 201', 50),
(4, 'AT2 - Sala 202', 50),
(5, 'AT3 - Lab 301', 30),
(6, 'AT3 - Lab 302', 30),
(7, 'AT4 - Sala 401', 60),
(8, 'AT4 - Sala 402', 60),
(9, 'Auditório Central', 150),

(10, 'AT5 - Sala 501', 35);

--
-----------------------------------------------------------------------------
-- turma (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO turma (id_turma, id_disciplina, capacidadeMaxima, ano, semestre)
VALUES
(1, 1, 35, 2025, 1),
(2, 2, 40, 2025, 1),
(3, 3, 30, 2025, 1),
(4, 4, 30, 2025, 1),
(5, 5, 40, 2025, 1),
(6, 6, 35, 2025, 2),
(7, 7, 35, 2025, 2),
(8, 8, 30, 2025, 2),
(9, 9, 30, 2025, 2),
(10, 10, 25, 2025, 2);

--
-----------------------------------------------------------------------------
-- turma_sala (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO turma_sala (id_turma, id_sala, horarioInicio, horarioFim,
diaSemana) VALUES
(1, 1, '08:00', '10:00', 'Segunda'),
(1, 1, '08:00', '10:00', 'Quarta'),
(2, 3, '10:00', '12:00', 'Terça'),
(2, 3, '10:00', '12:00', 'Quinta'),
(3, 5, '14:00', '16:00', 'Segunda'),
(4, 6, '16:00', '18:00', 'Terça'),
(5, 7, '08:00', '10:00', 'Quarta'),
(6, 2, '08:00', '10:00', 'Segunda'),
(7, 4, '10:00', '12:00', 'Terça'),
(8, 8, '14:00', '16:00', 'Quarta');

--
-----------------------------------------------------------------------------
-- professor_turma (10 registros)
--
-----------------------------------------------------------------------------
INSERT INTO professor_turma (id_professor, id_turma) VALUES
(101, 1),

(101, 3),
(102, 2),
(102, 5),
(103, 4),
(103, 6),
(104, 7),
(104, 8),
(105, 9),
(105, 10);

--
-----------------------------------------------------------------------------
-- inscricao (15 registros)
-- A coluna frequencia (0-100) representa o percentual de presença do aluno.
--
-----------------------------------------------------------------------------
INSERT INTO inscricao (id_inscricao, id_turma, ra, status, dataInscricao,
frequencia) VALUES
(1, 1, '758001', 'Ativa', '2025-02-01', 90),
(2, 2, '758001', 'Ativa', '2025-02-01', 85),
(3, 3, '758002', 'Ativa', '2025-02-01', 80),
(4, 4, '758002', 'Ativa', '2025-02-01', 95),
(5, 1, '758003', 'Ativa', '2025-02-02', 70),
(6, 2, '758003', 'Concluída', '2025-02-02', 100),
(7, 5, '758004', 'Ativa', '2025-02-02', 88),
(8, 3, '758004', 'Cancelada', '2025-02-03', 50),
(9, 1, '758005', 'Ativa', '2025-02-03', 78),
(10, 4, '758005', 'Ativa', '2025-02-03', 92),
(11, 6, '758006', 'Ativa', '2025-08-01', 85),
(12, 7, '758006', 'Ativa', '2025-08-01', 60),
(13, 8, '758007', 'Ativa', '2025-08-01', 95),
(14, 9, '758008', 'Trancada', '2025-08-02', 40),
(15, 10, '758009', 'Ativa', '2025-08-02', 82);

--
-----------------------------------------------------------------------------
-- avaliacao (15 registros)
--
-----------------------------------------------------------------------------
INSERT INTO avaliacao (id_avaliacao, id_inscricao, nota, tipo, dataLancamento)
VALUES
(1, 1, 8.50, 'Prova 1', '2025-04-10'),
(2, 1, 7.00, 'Trabalho 1', '2025-05-15'),
(3, 2, 9.00, 'Prova 2', '2025-04-11'),
(4, 3, 6.50, 'Prova 3', '2025-04-12'),
(5, 3, 8.00, 'Seminário 1', '2025-05-20'),

(6, 4, 7.50, 'Prova 3', '2025-04-13'),
(7, 5, 5.00, 'Prova 1', '2025-04-10'),
(8, 5, 6.00, 'Trabalho 2', '2025-05-15'),
(9, 6, 9.50, 'Prova 3', '2025-04-11'),
(10, 7, 8.00, 'Prova 2', '2025-04-14'),
(11, 9, 7.00, 'Prova 1', '2025-04-10'),
(12, 10, 8.50, 'Prova 2', '2025-04-13'),
(13, 11, 6.00, 'Prova 1', '2025-10-10'),
(14, 12, 7.50, 'Trabalho 3', '2025-10-15'),
(15, 13, 9.00, 'Prova 2', '2025-10-11');

--
-- =============================================================================
-- h) PROCEDURES, FUNCTIONS E TRIGGERS (mínimo 3 de cada tipo)
--
-- Estrutura desta seção:
-- 1. FUNCTIONS (3)
-- 2. PROCEDURES (3)
-- 3. TRIGGERS (3) — cada trigger exige uma trigger function + o comando
-- CREATE TRIGGER
--
-- =============================================================================

--
-- =============================================================================
-- h.1) FUNCTIONS
--
-- Funções retornam um valor e podem ser usadas diretamente em consultas
-- SELECT.
-- Utilizamos PL/pgSQL como linguagem procedural padrão.
--
-- =============================================================================

--
-----------------------------------------------------------------------------
-- FUNCTION 1: calcular_media_aluno
--
-- Calcula a média aritmética de todas as notas de um aluno em uma
-- inscrição específica.
--
-- Parâmetros:
-- p_id_inscricao: identificador da inscrição
--
-- Retorno: NUMERIC(4,2) — média das notas, ou NULL se não houver avaliações.
--

-- Justificativa: centralizar o cálculo de média evita repetição de lógica
-- em queries e garante consistência nos relatórios de boletim.
-- AVG retorna NULL automaticamente quando não há linhas, o que é repassado
-- ao chamador para indicar ausência de avaliações lançadas.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calcular_media_aluno(p_id_inscricao INT)
RETURNS NUMERIC(4,2)
LANGUAGE plpgsql
AS $$
DECLARE
v_media NUMERIC(4,2);
BEGIN
SELECT AVG(nota)
INTO v_media
FROM avaliacao
WHERE id_inscricao = p_id_inscricao;
-- AVG retorna NULL se não houver linhas; repassamos NULL ao chamador
RETURN v_media;
END;
$$;
-- Exemplo de uso:
-- SELECT calcular_media_aluno(1);

--
-----------------------------------------------------------------------------
-- FUNCTION 2: contar_alunos_ativos_turma
--
-- Retorna o número de alunos com inscrição 'Ativa' em uma turma.
--
-- Parâmetros:
-- p_id_turma: identificador da turma
--
-- Retorno: INT — total de alunos ativos.
--
-- Justificativa: usada para verificar disponibilidade de vagas antes de
-- permitir novas matrículas. É chamada tanto pela procedure matricular_aluno
-- quanto pelo trigger de capacidade, centralizando essa contagem em um
-- único ponto reutilizável.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION contar_alunos_ativos_turma(p_id_turma INT)
RETURNS INT
LANGUAGE plpgsql
AS $$

DECLARE
v_total INT;
BEGIN
SELECT COUNT(*)
INTO v_total
FROM inscricao
WHERE id_turma = p_id_turma
AND status = 'Ativa';
RETURN v_total;
END;
$$;
-- Exemplo de uso:
-- SELECT contar_alunos_ativos_turma(1);

--
-----------------------------------------------------------------------------
-- FUNCTION 3: aluno_aprovado
--
-- Verifica se um aluno foi aprovado em uma inscrição com base na média e na
-- frequência.
-- Critério: média >= 6.0, frequência >= 75 e status diferente de
-- 'Cancelada' ou 'Trancada'.
--
-- Parâmetros:
-- p_id_inscricao: identificador da inscrição
--
-- Retorno: BOOLEAN — TRUE se aprovado, FALSE caso contrário.
--
-- Justificativa: encapsula a regra de negócio de aprovação em um único
-- lugar, facilitando reutilização em relatórios, na procedure encerrar_turma
-- e em validações futuras sem duplicação de lógica.
-- Inscrições canceladas ou trancadas retornam FALSE imediatamente, sem
-- consultar as notas, pois não passam pelo processo de avaliação normal.
-- Alunos com frequência abaixo de 75 são reprovados independentemente da nota.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION aluno_aprovado(p_id_inscricao INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
v_media NUMERIC(4,2);
v_status VARCHAR(30);
v_frequencia INT;
BEGIN

-- Busca o status e a frequência atual da inscrição
SELECT status, frequencia
INTO v_status, v_frequencia
FROM inscricao
WHERE id_inscricao = p_id_inscricao;
-- Inscrições canceladas ou trancadas não são avaliadas
IF v_status IN ('Cancelada', 'Trancada') THEN
RETURN FALSE;
END IF;
-- Frequência insuficiente reprova o aluno independentemente da nota
IF v_frequencia < 75 THEN
RETURN FALSE;
END IF;
-- Reutiliza a function de média já definida
v_media := calcular_media_aluno(p_id_inscricao);
-- Sem avaliações lançadas ainda: não aprovado
IF v_media IS NULL THEN
RETURN FALSE;
END IF;
RETURN v_media >= 6.0;
END;
$$;
-- Exemplo de uso:
-- SELECT aluno_aprovado(1);

--
-- =============================================================================
-- h.2) PROCEDURES
--
-- Procedures executam ações (INSERT/UPDATE/DELETE) sem retornar valor.
-- São chamadas com o comando CALL.
--
-- =============================================================================

--
-----------------------------------------------------------------------------
-- PROCEDURE 1: matricular_aluno
--
-- Realiza a matrícula de um aluno em uma turma, verificando:
-- 1. Se o aluno existe.

-- 2. Se a turma existe.
-- 3. Se o aluno já está inscrito na turma.
-- 4. Se há vagas disponíveis (capacidadeMaxima da turma).
--
-- Parâmetros:
-- p_id_inscricao: ID da nova inscrição (gerado externamente)
-- p_ra : Registro Acadêmico do aluno
-- p_id_turma : ID da turma desejada
--
-- Justificativa: centraliza toda a regra de matrícula em um único ponto,
-- evitando inscrições duplicadas ou acima da capacidade independentemente
-- de qual caminho de inserção for utilizado. A procedure reutiliza a
-- function contar_alunos_ativos_turma para verificar vagas.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE matricular_aluno(
p_id_inscricao INT,
p_ra VARCHAR(20),
p_id_turma INT
)
LANGUAGE plpgsql
AS $$
DECLARE
v_capacidade INT;
v_ativos INT;
v_ja_inscrito INT;
v_aluno_existe INT;
v_turma_existe INT;
BEGIN
-- Verifica existência do aluno
SELECT COUNT(*) INTO v_aluno_existe FROM aluno WHERE ra = p_ra;
IF v_aluno_existe = 0 THEN
RAISE EXCEPTION 'Aluno com RA % não encontrado.', p_ra;
END IF;
-- Verifica existência da turma
SELECT COUNT(*) INTO v_turma_existe FROM turma WHERE id_turma = p_id_turma;
IF v_turma_existe = 0 THEN
RAISE EXCEPTION 'Turma % não encontrada.', p_id_turma;
END IF;
-- Verifica se o aluno já está inscrito nesta turma
SELECT COUNT(*) INTO v_ja_inscrito
FROM inscricao
WHERE ra = p_ra AND id_turma = p_id_turma;
IF v_ja_inscrito > 0 THEN

RAISE EXCEPTION 'Aluno % já possui inscrição na turma %.', p_ra,
p_id_turma;
END IF;
-- Verifica disponibilidade de vagas reutilizando a function existente
SELECT capacidadeMaxima INTO v_capacidade FROM turma WHERE id_turma =
p_id_turma;
v_ativos := contar_alunos_ativos_turma(p_id_turma);
IF v_ativos >= v_capacidade THEN
RAISE EXCEPTION 'Turma % sem vagas disponíveis (capacidade: %, ativos:
%).',
p_id_turma, v_capacidade, v_ativos;
END IF;
-- Insere a inscrição com status inicial 'Ativa' e data atual
INSERT INTO inscricao (id_inscricao, id_turma, ra, status, dataInscricao)
VALUES (p_id_inscricao, p_id_turma, p_ra, 'Ativa', CURRENT_DATE);
RAISE NOTICE 'Aluno % matriculado com sucesso na turma %.', p_ra,
p_id_turma;
END;
$$;
-- Exemplo de uso:
-- CALL matricular_aluno(16, '758010', 5);

--
-----------------------------------------------------------------------------
-- PROCEDURE 2: lancar_nota
--
-- Lança ou atualiza uma nota para uma inscrição.
-- Regras:
-- 1. A inscrição deve existir e estar 'Ativa' ou 'Concluída'.
-- 2. A nota deve estar entre 0 e 10.
-- 3. Se já existir avaliação do mesmo tipo, atualiza; senão, insere.
--
-- Parâmetros:
-- p_id_avaliacao: ID da avaliação (usado apenas na inserção)
-- p_id_inscricao: ID da inscrição alvo
-- p_nota : nota a ser lançada
-- p_tipo : tipo da avaliação (ex: 'Prova', 'Trabalho')
--
-- Justificativa: garante que notas inválidas nunca sejam persistidas e
-- evita duplicatas acidentais do mesmo tipo de avaliação por inscrição.
-- A lógica de upsert (atualizar se existe, inserir se não existe) facilita
-- correções de notas sem exigir que o chamador saiba o id_avaliacao original.

--
-----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE lancar_nota(
p_id_avaliacao INT,
p_id_inscricao INT,
p_nota NUMERIC(4,2),
p_tipo VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
v_status VARCHAR(30);
v_avaliacao_id INT;
BEGIN
-- Valida o intervalo da nota antes de qualquer consulta
IF p_nota < 0 OR p_nota > 10 THEN
RAISE EXCEPTION 'Nota inválida: %. Deve estar entre 0 e 10.', p_nota;
END IF;
-- Verifica se a inscrição existe e obtém o status
SELECT status INTO v_status
FROM inscricao
WHERE id_inscricao = p_id_inscricao;
IF NOT FOUND THEN
RAISE EXCEPTION 'Inscrição % não encontrada.', p_id_inscricao;
END IF;
-- Somente inscrições Ativas ou Concluídas aceitam lançamento de nota
IF v_status NOT IN ('Ativa', 'Concluída') THEN
RAISE EXCEPTION 'Não é possível lançar nota para inscrição com status
"%".', v_status;
END IF;
-- Verifica se já existe avaliação desse tipo para essa inscrição (lógica
-- de upsert)
SELECT id_avaliacao INTO v_avaliacao_id
FROM avaliacao
WHERE id_inscricao = p_id_inscricao AND tipo = p_tipo;
IF FOUND THEN
-- Atualiza a nota existente e registra a data atual do lançamento
UPDATE avaliacao
SET nota = p_nota, dataLancamento = CURRENT_DATE
WHERE id_avaliacao = v_avaliacao_id;
RAISE NOTICE 'Nota atualizada para inscrição %, tipo "%": %.',
p_id_inscricao, p_tipo, p_nota;

ELSE
-- Insere nova avaliação quando não existe registro do mesmo tipo
INSERT INTO avaliacao (id_avaliacao, id_inscricao, nota, tipo,
dataLancamento)
VALUES (p_id_avaliacao, p_id_inscricao, p_nota, p_tipo, CURRENT_DATE);
RAISE NOTICE 'Nota lançada para inscrição %, tipo "%": %.',
p_id_inscricao, p_tipo, p_nota;
END IF;
END;
$$;
-- Exemplo de uso:
-- CALL lancar_nota(20, 1, 9.0, 'Prova Final');

--
-----------------------------------------------------------------------------
-- PROCEDURE 3: encerrar_turma
--
-- Encerra uma turma ao final do período letivo:
-- 1. Aprova (status → 'Concluída') alunos com média >= 6.0 e frequência >=
-- 75.
-- 2. Reprova (status → 'Reprovada') alunos com média < 6.0 ou frequência <
-- 75.
-- 3. Mantém 'Cancelada' e 'Trancada' sem alteração.
--
-- Parâmetros:
-- p_id_turma: ID da turma a ser encerrada
--
-- Justificativa: automatiza o fechamento de período, eliminando
-- atualizações manuais linha a linha e garantindo consistência no
-- resultado final de todos os alunos. Reutiliza a function aluno_aprovado
-- para aplicar a regra de aprovação de forma centralizada.
-- Apenas inscrições com status 'Ativa' são processadas; as demais já
-- possuem um desfecho definitivo e não devem ser alteradas.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE encerrar_turma(p_id_turma INT)
LANGUAGE plpgsql
AS $$
DECLARE
v_inscricao RECORD;
v_aprovado BOOLEAN;
v_turma_existe INT;
BEGIN
-- Verifica se a turma existe antes de processar
SELECT COUNT(*) INTO v_turma_existe FROM turma WHERE id_turma = p_id_turma;

IF v_turma_existe = 0 THEN
RAISE EXCEPTION 'Turma % não encontrada.', p_id_turma;
END IF;
-- Percorre todas as inscrições ativas da turma para processar o resultado
FOR v_inscricao IN
SELECT id_inscricao, ra
FROM inscricao
WHERE id_turma = p_id_turma
AND status = 'Ativa'
LOOP
-- Delega a avaliação de aprovação para a function correspondente
v_aprovado := aluno_aprovado(v_inscricao.id_inscricao);
IF v_aprovado THEN
UPDATE inscricao
SET status = 'Concluída'
WHERE id_inscricao = v_inscricao.id_inscricao;
RAISE NOTICE 'Aluno % APROVADO na turma %.', v_inscricao.ra,
p_id_turma;
ELSE
UPDATE inscricao
SET status = 'Reprovada'
WHERE id_inscricao = v_inscricao.id_inscricao;
RAISE NOTICE 'Aluno % REPROVADO na turma %.', v_inscricao.ra,
p_id_turma;
END IF;
END LOOP;
RAISE NOTICE 'Turma % encerrada com sucesso.', p_id_turma;
END;
$$;
-- Exemplo de uso:
-- CALL encerrar_turma(1);

--
-- =============================================================================
-- h.3) TRIGGERS
--
-- Triggers exigem dois objetos:
-- a) Uma trigger function (retorna TRIGGER) com a lógica de negócio.
-- b) O comando CREATE TRIGGER que associa a função à tabela e ao evento.
--
-- =============================================================================

--
-----------------------------------------------------------------------------
-- TRIGGER 1: verificar_capacidade_inscricao
--
-- Evento : BEFORE INSERT em inscricao
-- Ação : impede a inserção se a turma já atingiu capacidadeMaxima.
--
-- Justificativa: mesmo com a procedure matricular_aluno realizando essa
-- verificação, o trigger atua como segunda linha de defesa — garante
-- a regra no nível do banco independentemente do caminho de inserção,
-- protegendo contra inserções diretas que contornem a procedure.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_verificar_capacidade_inscricao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_capacidade INT;
v_ativos INT;
BEGIN
SELECT capacidadeMaxima INTO v_capacidade
FROM turma
WHERE id_turma = NEW.id_turma;
-- Reutiliza a function de contagem de ativos
v_ativos := contar_alunos_ativos_turma(NEW.id_turma);
IF v_ativos >= v_capacidade THEN
RAISE EXCEPTION
'Turma % atingiu a capacidade máxima (%). Inscrição bloqueada.',
NEW.id_turma, v_capacidade;
END IF;
-- Retorna NEW para permitir que a inserção prossiga
RETURN NEW;
END;
$$;
CREATE TRIGGER tg_verificar_capacidade_inscricao
BEFORE INSERT ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_capacidade_inscricao();

--
-----------------------------------------------------------------------------
-- TRIGGER 2: impedir_rematricula_disciplina_concluida
--
-- Evento : BEFORE INSERT em inscricao
-- Ação : impede a inscrição de um aluno em uma turma cuja disciplina ele
-- já concluiu anteriormente (em qualquer outra turma).
--
-- Justificativa: um aluno aprovado em uma disciplina não deve ocupar vaga
-- cursando-a de novo. Como a aprovação é registrada no status 'Concluída'
-- da inscrição, o trigger descobre a disciplina da turma de destino e
-- verifica se já existe uma inscrição 'Concluída' do mesmo aluno em qualquer
-- turma daquela disciplina. NEW contém os dados da inscrição que está sendo
-- inserida; a checagem ocorre BEFORE INSERT para abortar antes de gravar.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_impedir_rematricula_disciplina_concluida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_id_disciplina INT;
v_ja_concluiu INT;
BEGIN
-- Descobre a disciplina da turma na qual o aluno está se inscrevendo
SELECT id_disciplina INTO v_id_disciplina
FROM turma
WHERE id_turma = NEW.id_turma;
-- Conta inscrições 'Concluída' do aluno em qualquer turma dessa disciplina
SELECT COUNT(*) INTO v_ja_concluiu
FROM inscricao i
JOIN turma t ON t.id_turma = i.id_turma
WHERE i.ra = NEW.ra
AND t.id_disciplina = v_id_disciplina
AND i.status = 'Concluída';
IF v_ja_concluiu > 0 THEN
RAISE EXCEPTION 'Aluno % já concluiu a disciplina % e não pode se
matricular novamente.', NEW.ra, v_id_disciplina;
END IF;
RETURN NEW; -- libera a inserção quando o aluno ainda não concluiu
END;
$$;
DROP TRIGGER IF EXISTS tg_impedir_rematricula_disciplina_concluida ON
inscricao;
CREATE TRIGGER tg_impedir_rematricula_disciplina_concluida
BEFORE INSERT ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_impedir_rematricula_disciplina_concluida();

--
-----------------------------------------------------------------------------
-- TRIGGER 3: validar_status_avaliacao
--
-- Evento : BEFORE INSERT em avaliacao
-- Ação : impede o lançamento de nota quando a inscrição alvo não está
-- com status 'Ativa' ou 'Concluída'.
--
-- Justificativa: inscrições 'Cancelada', 'Trancada' ou 'Reprovada' não passam
-- pelo processo regular de avaliação, então não devem receber notas. O trigger
-- atua como segunda linha de defesa no nível do banco, garantindo a regra
-- independentemente de a inserção vir pela procedure lancar_nota ou por um
-- INSERT direto. NEW.id_inscricao identifica a inscrição cujo status é
-- consultado antes de permitir a gravação da nota.
--
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validar_status_avaliacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_status VARCHAR(30);
BEGIN
SELECT status INTO v_status
FROM inscricao
WHERE id_inscricao = NEW.id_inscricao;
IF v_status NOT IN ('Ativa', 'Concluída') THEN
RAISE EXCEPTION 'Não é possível lançar nota: a inscrição % está com
status "%".', NEW.id_inscricao, v_status;
END IF;
RETURN NEW; -- libera a inserção para inscrições Ativa/Concluída
END;
$$;
DROP TRIGGER IF EXISTS tg_validar_status_avaliacao ON avaliacao;
CREATE TRIGGER tg_validar_status_avaliacao
BEFORE INSERT ON avaliacao
FOR EACH ROW
EXECUTE FUNCTION fn_validar_status_avaliacao();

--
-- =============================================================================
-- EXEMPLOS DE TESTE

--
-- =============================================================================
-- Testar FUNCTION 1: média de notas da inscrição 1
-- SELECT calcular_media_aluno(1);
-- Testar FUNCTION 2: alunos ativos na turma 1
-- SELECT contar_alunos_ativos_turma(1);
-- Testar FUNCTION 3: aprovação da inscrição 1
-- SELECT aluno_aprovado(1);
-- Testar PROCEDURE 1: nova matrícula
-- CALL matricular_aluno(16, '758010', 5);
-- Testar PROCEDURE 2: lançar nota
-- CALL lancar_nota(20, 15, 8.5, 'Prova Final');
-- Testar PROCEDURE 3: encerrar turma
-- CALL encerrar_turma(1);
-- Testar TRIGGER 1: tentativa de exceder capacidade (deve falhar se turma
-- cheia)
-- INSERT INTO inscricao VALUES (99, 1, '758010', 'Ativa', CURRENT_DATE);
-- Testar TRIGGER 2:
-- Cria uma nova turma de Cálculo I (disciplina 2)
INSERT INTO turma VALUES (11, 2, 40, 2025, 2);
-- (a) deve FALHAR: o aluno 758003 tem inscrição 'Concluída' na disciplina 2
INSERT INTO inscricao (id_inscricao, id_turma, ra, status, dataInscricao,
frequencia)
VALUES (16, 11, '758003', 'Ativa', CURRENT_DATE, 100);
-- (b) deve FUNCIONAR: 758003 ainda não concluiu a disciplina 5 (turma 5)
INSERT INTO inscricao (id_inscricao, id_turma, ra, status, dataInscricao,
frequencia)
VALUES (17, 5, '758003', 'Ativa', CURRENT_DATE, 100);
SELECT id_inscricao, id_turma, ra,
-- Testar TRIGGER 3: tentativa de deletar inscrição ativa (deve falhar)
-- Inscrição 50 = 'Ativa' | Inscrição 51 = 'Cancelada' (aluno 758010, livre nas
-- turmas 9 e 10)
INSERT INTO inscricao (id_inscricao, id_turma, ra, status, dataInscricao,
frequencia)
VALUES (50, 10, '758010', 'Ativa', CURRENT_DATE, 100)
ON CONFLICT (id_inscricao) DO NOTHING;
INSERT INTO inscricao (id_inscricao, id_turma, ra, status, dataInscricao,
frequencia)
VALUES (51, 9, '758010', 'Cancelada', CURRENT_DATE, 100)

ON CONFLICT (id_inscricao) DO NOTHING;
-- (a) deve FALHAR pelo trigger: inscrição 51 está 'Cancelada'
INSERT INTO avaliacao (id_avaliacao, id_inscricao, nota, tipo, dataLancamento)
VALUES (60, 51, 7.0, 'Prova 1', CURRENT_DATE);
-- (b) deve FUNCIONAR: inscrição 50 está 'Ativa'
INSERT INTO avaliacao (id_avaliacao, id_inscricao, nota, tipo, dataLancamento)
VALUES (61, 50, 7.0, 'Prova Extra', CURRENT_DATE);
SELECT id_avaliacao, id_inscricao, nota, tipo FROM avaliacao WHERE id_avaliacao
IN (60, 61);

-- =============================================================================
-- CONSULTAS SQL E TRIGGERS  - Entrega Final
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CONSULTA 1: Boletim completo de um aluno
--
-- Entidades: pessoa, aluno, inscricao, turma, disciplina, avaliacao
-- Relacionamentos:
--   aluno →(fk_aluno_pessoa)→ pessoa
--   inscricao →(fk_inscricao_aluno)→ aluno
--   inscricao →(fk_inscricao_turma)→ turma
--   turma →(fk_turma_disciplina)→ disciplina
--   avaliacao →(fk_avaliacao_inscricao)→ inscricao
--
-- Mostra, para cada disciplina cursada pelo aluno, o ano/semestre,
-- o status da inscrição, a frequência e a média das notas.
-- Filtramos por RA, mas a query funciona para qualquer aluno.
-- -----------------------------------------------------------------------------

SELECT
    p.nome AS aluno,
    a.ra,
    d.titulo AS disciplina,
    t.ano,
    t.semestre,
    i.status,
    i.frequencia AS frequencia_pct,
    ROUND(AVG(av.nota), 2) AS media_notas
FROM pessoa p
JOIN aluno a ON a.cpf = p.cpf
JOIN inscricao i ON i.ra = a.ra
JOIN turma t ON t.id_turma = i.id_turma
JOIN disciplina d ON d.id_disciplina = t.id_disciplina
LEFT JOIN avaliacao av ON av.id_inscricao = i.id_inscricao
GROUP BY
    p.nome, a.ra, d.titulo,
    t.ano, t.semestre,
    i.status, i.frequencia
ORDER BY
    p.nome, t.ano DESC, t.semestre DESC, d.titulo;


-- -----------------------------------------------------------------------------
-- CONSULTA 2: Carga de trabalho dos professores por departamento
--
-- Entidades: pessoa, professor, departamento, professor_turma, turma, disciplina
-- Relacionamentos:
--   professor →(fk_professor_pessoa)→ pessoa
--   professor →(fk_professor_departamento)→ departamento
--   professor_turma →(fk_profturma_professor)→ professor
--   professor_turma →(fk_profturma_turma)→ turma
--   turma →(fk_turma_disciplina)→ disciplina
--
-- Mostra quantas turmas e disciplinas distintas cada professor ministra,
-- agrupado por departamento. Útil para relatórios de gestão acadêmica.
-- -----------------------------------------------------------------------------

SELECT
    dep.nome AS departamento,
    p.nome AS professor,
    prof.titulo AS titulacao,
    COUNT(DISTINCT pt.id_turma) AS total_turmas,
    COUNT(DISTINCT t.id_disciplina) AS disciplinas_distintas,
    STRING_AGG(DISTINCT d.titulo, ', ' ORDER BY d.titulo) AS lista_disciplinas
FROM pessoa p
JOIN professor prof  ON prof.cpf = p.cpf
JOIN departamento dep ON dep.id_departamento = prof.id_departamento
JOIN professor_turma pt ON pt.id_professor  = prof.id_professor
JOIN turma t ON t.id_turma = pt.id_turma
JOIN disciplina d ON d.id_disciplina = t.id_disciplina
GROUP BY
    dep.nome, p.nome, prof.titulo
ORDER BY
    dep.nome, total_turmas DESC;


-- -----------------------------------------------------------------------------
-- CONSULTA 3: Turmas com ocupação acima de 50% da capacidade
--
-- Entidades: disciplina, turma, inscricao, sala, turma_sala
-- Relacionamentos:
--   turma →(fk_turma_disciplina)→ disciplina
--   inscricao →(fk_inscricao_turma)→ turma
--   turma_sala →(fk_turmasala_turma)→ turma
--   turma_sala →(fk_turmasala_sala)→ sala
--
-- Calcula a taxa de ocupação (alunos ativos / capacidade da turma) e
-- lista apenas as turmas com mais de 50 % de ocupação, informando a
-- sala principal e o horário. Ajuda na gestão de espaço físico.
-- -----------------------------------------------------------------------------

SELECT
    d.titulo AS disciplina,
    t.id_turma,
    t.ano,
    t.semestre,
    t.capacidadeMaxima AS capacidade,
    COUNT(i.id_inscricao) FILTER (WHERE i.status = 'Ativa') AS alunos_ativos,
    ROUND(COUNT(i.id_inscricao) FILTER (WHERE i.status = 'Ativa')* 100.0 / t.capacidadeMaxima, 1) AS ocupacao_pct,
    s.localizacao AS sala_principal,
    ts.diaSemana AS dia,
    ts.horarioInicio AS inicio
FROM turma t
JOIN disciplina d ON d.id_disciplina = t.id_disciplina
LEFT JOIN inscricao i ON i.id_turma = t.id_turma
LEFT JOIN turma_sala ts ON ts.id_turma = t.id_turma
LEFT JOIN sala s ON s.id_sala = ts.id_sala
GROUP BY
    d.titulo, t.id_turma, t.ano, t.semestre,
    t.capacidadeMaxima, s.localizacao,
    ts.diaSemana, ts.horarioInicio
HAVING
    COUNT(i.id_inscricao) FILTER (WHERE i.status = 'Ativa') > t.capacidadeMaxima * 0.5
ORDER BY
    ocupacao_pct DESC;


-- -----------------------------------------------------------------------------
-- CONSULTA 4: Alunos em risco de reprovação (frequência < 75 ou média < 6)
--
-- Entidades: pessoa, aluno, inscricao, turma, disciplina, avaliacao
-- Relacionamentos:
--   aluno →(fk_aluno_pessoa)→ pessoa
--   inscricao →(fk_inscricao_aluno)→ aluno
--   inscricao →(fk_inscricao_turma)→ turma
--   turma →(fk_turma_disciplina)→ disciplina
--   avaliacao →(fk_avaliacao_inscricao)→ inscricao
--
-- Lista somente inscrições 'Ativas' onde o aluno já está em risco,
-- indicando qual critério está sendo violado. Útil para ações preventivas
-- da coordenação acadêmica.
-- -----------------------------------------------------------------------------

SELECT
    p.nome AS aluno,
    a.ra,
    d.titulo AS disciplina,
    t.ano,
    t.semestre,
    i.frequencia AS frequencia_pct,
    ROUND(AVG(av.nota), 2) AS media_atual,
    CASE
        WHEN i.frequencia < 75
             AND ROUND(AVG(av.nota), 2) < 6.0 THEN 'Frequência e Nota'
        WHEN i.frequencia < 75 THEN 'Frequência'
        WHEN ROUND(AVG(av.nota), 2) < 6.0 THEN 'Nota'
    END AS risco_por
FROM pessoa p
JOIN aluno a ON a.cpf = p.cpf
JOIN inscricao i ON i.ra = a.ra
JOIN turma t ON t.id_turma = i.id_turma
JOIN disciplina d ON d.id_disciplina = t.id_disciplina
LEFT JOIN avaliacao av ON av.id_inscricao = i.id_inscricao
WHERE
    i.status = 'Ativa'
GROUP BY
    p.nome, a.ra, d.titulo,
    t.ano, t.semestre, i.frequencia
HAVING
    i.frequencia < 75 OR ROUND(AVG(av.nota), 2) < 6.0
ORDER BY
    risco_por, p.nome;


-- =============================================================================
-- TRIGGERS ADICIONAIS (4 novos)
-- Os 3 já existentes são:
--   tg_verificar_capacidade_inscricao
--   tg_impedir_rematricula_disciplina_concluida
--   tg_validar_status_avaliacao
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TRIGGER 4: Registrar data de atualização de status da inscrição
--
-- Evento : BEFORE UPDATE em inscricao (quando status muda)
-- Tabela : log_status_inscricao (criada abaixo)
-- Ação   : insere uma linha de auditoria com o status anterior e o novo,
--          o RA do aluno, o id_turma e o momento da mudança.
--
-- Justificativa: rastrear a evolução do ciclo de vida de cada matrícula
-- é essencial para auditorias, emissão de declarações e resolução de
-- disputas acadêmicas. Sem esse log, o histórico de transições de status
-- fica perdido (o banco só guarda o valor atual).
-- -----------------------------------------------------------------------------

-- Tabela de log necessária para o trigger 4
CREATE TABLE IF NOT EXISTS log_status_inscricao (
    id_log SERIAL PRIMARY KEY,
    id_inscricao INT NOT NULL,
    ra VARCHAR(20) NOT NULL,
    id_turma INT NOT NULL,
    status_anterior VARCHAR(30) NOT NULL,
    status_novo VARCHAR(30) NOT NULL,
    alterado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION fn_log_mudanca_status_inscricao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Só registra quando o status realmente mudou
    IF NEW.status <> OLD.status THEN
        INSERT INTO log_status_inscricao
            (id_inscricao, ra, id_turma, status_anterior, status_novo)
        VALUES
            (OLD.id_inscricao, OLD.ra, OLD.id_turma, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tg_log_mudanca_status_inscricao ON inscricao;
CREATE TRIGGER tg_log_mudanca_status_inscricao
BEFORE UPDATE OF status ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_log_mudanca_status_inscricao();

-- Exemplo de teste:
-- UPDATE inscricao SET status = 'Concluída' WHERE id_inscricao = 1;
-- SELECT * FROM log_status_inscricao;


-- -----------------------------------------------------------------------------
-- TRIGGER 5: Impedir exclusão de professor vinculado a turmas ativas
--
-- Evento : BEFORE DELETE em professor
-- Ação   : aborta a exclusão se o professor ainda tiver vínculos na tabela
--          professor_turma referentes a turmas do período corrente
--          (ano = EXTRACT(YEAR FROM CURRENT_DATE)).
--
-- Justificativa: a FK fk_profturma_professor já usa ON DELETE RESTRICT, o
-- que impede a exclusão enquanto houver qualquer linha em professor_turma.
-- Este trigger vai além: emite uma mensagem de erro explicativa, listando
-- quantas turmas ativas o professor possui, facilitando a ação corretiva
-- pelo usuário. Turmas de períodos anteriores não bloqueiam a exclusão,
-- pois o vínculo histórico pode ser mantido na tabela professor_turma
-- mesmo sem o professor ativo no sistema.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_impedir_exclusao_professor_ativo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_turmas_ativas INT;
    v_ano_atual     INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
BEGIN
    SELECT COUNT(*)
    INTO v_turmas_ativas
    FROM professor_turma pt
    JOIN turma t ON t.id_turma = pt.id_turma
    WHERE pt.id_professor = OLD.id_professor
      AND t.ano = v_ano_atual;

    IF v_turmas_ativas > 0 THEN
        RAISE EXCEPTION
            'Não é possível excluir o professor % (id: %): ele possui % turma(s) ativa(s) no ano corrente (%).',
            (SELECT nome FROM pessoa WHERE cpf = OLD.cpf),
            OLD.id_professor,
            v_turmas_ativas,
            v_ano_atual;
    END IF;

    RETURN OLD; -- libera a exclusão quando não há turmas no ano corrente
END;
$$;

DROP TRIGGER IF EXISTS tg_impedir_exclusao_professor_ativo ON professor;
CREATE TRIGGER tg_impedir_exclusao_professor_ativo
BEFORE DELETE ON professor
FOR EACH ROW
EXECUTE FUNCTION fn_impedir_exclusao_professor_ativo();

-- Exemplo de teste (deve falhar — professor 101 ministra turmas em 2025):
-- DELETE FROM professor WHERE id_professor = 101;


-- -----------------------------------------------------------------------------
-- TRIGGER 6: Impedir conflito de horário na mesma sala
--
-- Evento : BEFORE INSERT em turma_sala
-- Ação   : verifica se já existe outra turma alocada na mesma sala,
--          no mesmo dia da semana e com sobreposição de horário.
--          Se sim, aborta a inserção com mensagem detalhada.
--
-- Justificativa: o modelo atual não impede que duas turmas sejam alocadas
-- na mesma sala simultaneamente — a PK (id_turma, id_sala, horarioInicio,
-- diaSemana) impede duplicatas exatas, mas não sobreposições parciais de
-- horário (ex.: uma turma das 08:00–10:00 e outra das 09:00–11:00 na
-- mesma sala passariam pela PK). Este trigger fecha essa lacuna verificando
-- a interseção dos intervalos de horário.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_verificar_conflito_sala()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_conflito_turma INT;
BEGIN
    SELECT ts.id_turma
    INTO v_conflito_turma
    FROM turma_sala ts
    WHERE ts.id_sala      = NEW.id_sala
      AND ts.diaSemana    = NEW.diaSemana
      AND ts.id_turma    <> NEW.id_turma   -- ignora a própria turma em updates
      -- Sobreposição: o intervalo existente começa antes do fim do novo
      --               E termina depois do início do novo
      AND ts.horarioInicio < NEW.horarioFim
      AND ts.horarioFim   > NEW.horarioInicio
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION
            'Conflito de horário: sala % já está ocupada na % por outra turma (id_turma=%) no intervalo solicitado (%–%).',
            NEW.id_sala,
            NEW.diaSemana,
            v_conflito_turma,
            NEW.horarioInicio,
            NEW.horarioFim;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tg_verificar_conflito_sala ON turma_sala;
CREATE TRIGGER tg_verificar_conflito_sala
BEFORE INSERT ON turma_sala
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_conflito_sala();

-- Exemplo de teste (deve falhar — sala 1 já ocupada na Segunda das 08:00–10:00):
-- INSERT INTO turma_sala VALUES (3, 1, '09:00', '11:00', 'Segunda');
-- Exemplo de teste (deve funcionar — sala diferente):
-- INSERT INTO turma_sala VALUES (3, 2, '09:00', '11:00', 'Segunda');


-- -----------------------------------------------------------------------------
-- TRIGGER 7: Atualizar automaticamente o status da inscrição para 'Reprovada'
--            quando a frequência cair abaixo de 75
--
-- Evento : BEFORE UPDATE em inscricao (quando frequencia muda)
-- Ação   : se a inscrição está 'Ativa' e a nova frequência for < 75,
--          altera o status para 'Reprovada' automaticamente, impedindo
--          que o aluno continue constando como ativo mesmo já reprovado
--          por falta.
--
-- Justificativa: a regra de aprovação exige frequência mínima de 75 %.
-- Sem este trigger, um professor precisaria encerrar manualmente cada
-- inscrição após o lançamento da frequência final, abrindo espaço para
-- inconsistências (aluno com frequência 30 % e status 'Ativo'). O trigger
-- automatiza a transição, garantindo consistência imediata e ativando
-- também o trigger 4 (log de status) em cascata, pois este retorna NEW
-- com status alterado.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_reprovar_por_falta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Aplica somente a inscrições Ativas cuja frequência caiu abaixo do mínimo
    IF NEW.status = 'Ativa' AND NEW.frequencia < 75 THEN
        NEW.status := 'Reprovada';
        RAISE NOTICE
            'Inscrição % (RA %, turma %): status alterado automaticamente para "Reprovada" por frequência insuficiente (%).',
            NEW.id_inscricao, NEW.ra, NEW.id_turma, NEW.frequencia;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tg_reprovar_por_falta ON inscricao;
CREATE TRIGGER tg_reprovar_por_falta
BEFORE UPDATE OF frequencia ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_reprovar_por_falta();

-- Exemplo de teste (deve mudar status para 'Reprovada' automaticamente):
-- UPDATE inscricao SET frequencia = 60 WHERE id_inscricao = 9;
-- SELECT id_inscricao, status, frequencia FROM inscricao WHERE id_inscricao = 9;
-- O log_status_inscricao também registrará a mudança (via trigger 4).