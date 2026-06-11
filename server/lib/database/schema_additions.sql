-- Adições ao Schema do Banco de Dados para Tô Na Rota
-- Criação de tabelas de tokens temporários seguros

CREATE TABLE IF NOT EXISTS token_confirmacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expira_em TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS token_recuperacao (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expira_em TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_token_confirmacao_val ON token_confirmacao(token);
CREATE INDEX IF NOT EXISTS idx_token_recuperacao_val ON token_recuperacao(token);
