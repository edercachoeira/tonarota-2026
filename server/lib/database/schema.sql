-- Banco de Dados do Ecossistema Tô Na Rota
-- Mapeamento DDL PostgreSQL 15+ em conformidade com o ERD do PRD.
-- Foco em integridade referencial, índices de pesquisa e segurança física.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. BALNEARIO
CREATE TABLE balneario (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(100) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    descricao TEXT,
    imagem_capa_url VARCHAR(255),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. CATEGORIA
CREATE TABLE categoria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(100) NOT NULL,
    icone VARCHAR(50) NOT NULL DEFAULT '',
    descricao TEXT,
    ordem INT NOT NULL DEFAULT 0,
    parent_id UUID REFERENCES categoria(id) ON DELETE SET NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. USUARIO
CREATE TABLE usuario (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('turista', 'estabelecimento', 'gestor')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. ESTABELECIMENTO
CREATE TABLE estabelecimento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    balneario_id UUID NOT NULL REFERENCES balneario(id) ON DELETE CASCADE,
    categoria_id UUID NOT NULL REFERENCES categoria(id) ON DELETE RESTRICT,
    nome_fantasia VARCHAR(150) NOT NULL,
    documento VARCHAR(20) NOT NULL,
    endereco VARCHAR(255) NOT NULL DEFAULT '',
    telefone VARCHAR(20) NOT NULL DEFAULT '',
    whatsapp VARCHAR(20) NOT NULL DEFAULT '',
    instagram VARCHAR(50) NOT NULL DEFAULT '',
    descricao TEXT,
    logomarca_url VARCHAR(255) NOT NULL DEFAULT '',
    plano VARCHAR(10) NOT NULL DEFAULT 'gratuito' CHECK (plano IN ('gratuito', 'premium')),
    status VARCHAR(15) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'ativo', 'suspenso')),
    horarios JSONB NOT NULL DEFAULT '{}'::jsonb,
    nota_media NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    total_avaliacoes INT NOT NULL DEFAULT 0,
    total_visualizacoes INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. PRODUTO
CREATE TABLE produto (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estabelecimento_id UUID NOT NULL REFERENCES estabelecimento(id) ON DELETE CASCADE,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    foto_url VARCHAR(255) NOT NULL DEFAULT '',
    ordem INT NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 6. CAMERA
CREATE TABLE camera (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    balneario_id UUID NOT NULL REFERENCES balneario(id) ON DELETE CASCADE,
    nome VARCHAR(100) NOT NULL,
    url_stream VARCHAR(255) NOT NULL,
    protocolo VARCHAR(10) NOT NULL DEFAULT 'HLS' CHECK (protocolo IN ('HLS', 'RTSP')),
    online BOOLEAN NOT NULL DEFAULT TRUE
);

-- 7. EVENTO
CREATE TABLE evento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    balneario_id UUID NOT NULL REFERENCES balneario(id) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    data_hora TIMESTAMP WITH TIME ZONE NOT NULL,
    local VARCHAR(150) NOT NULL,
    descricao TEXT,
    imagem_url VARCHAR(255) NOT NULL DEFAULT '',
    link_externo VARCHAR(255) NOT NULL DEFAULT ''
);

-- 8. AVALIACAO
CREATE TABLE avaliacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estabelecimento_id UUID NOT NULL REFERENCES estabelecimento(id) ON DELETE CASCADE,
    nota INT NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario TEXT,
    status VARCHAR(15) NOT NULL DEFAULT 'aprovada' CHECK (status IN ('aprovada', 'oculta')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9. BANNER
CREATE TABLE banner (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    imagem_url VARCHAR(255) NOT NULL,
    link_destino VARCHAR(255) NOT NULL DEFAULT '',
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    posicao VARCHAR(15) NOT NULL DEFAULT 'home' CHECK (posicao IN ('home', 'diretorio')),
    status VARCHAR(15) NOT NULL DEFAULT 'agendado' CHECK (status IN ('ativo', 'agendado', 'expirado'))
);

-- 10. EMERGENCIA
CREATE TABLE emergencia (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    balneario_id UUID NOT NULL REFERENCES balneario(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20) NOT NULL
);

-- 11. NOTIFICACAO
CREATE TABLE notificacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(150) NOT NULL,
    corpo TEXT NOT NULL,
    imagem_url VARCHAR(255) NOT NULL DEFAULT '',
    balneario_id UUID REFERENCES balneario(id) ON DELETE CASCADE,
    enviada_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. BANNER_BALNEARIO (Relacionamento N-N)
CREATE TABLE banner_balneario (
    banner_id UUID NOT NULL REFERENCES banner(id) ON DELETE CASCADE,
    balneario_id UUID NOT NULL REFERENCES balneario(id) ON DELETE CASCADE,
    PRIMARY KEY (banner_id, balneario_id)
);

-- Índices adicionais para otimização de consultas (Foreign Keys e filtros frequentes)
CREATE INDEX idx_estabelecimento_balneario ON estabelecimento(balneario_id);
CREATE INDEX idx_estabelecimento_categoria ON estabelecimento(categoria_id);
CREATE INDEX idx_produto_estabelecimento ON produto(estabelecimento_id);
CREATE INDEX idx_camera_balneario ON camera(balneario_id);
CREATE INDEX idx_evento_balneario ON evento(balneario_id);
CREATE INDEX idx_avaliacao_estabelecimento ON avaliacao(estabelecimento_id);
CREATE INDEX idx_emergencia_balneario ON emergencia(balneario_id);
