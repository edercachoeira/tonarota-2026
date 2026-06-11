-- Tabela de Logs de Auditoria para Tô Na Rota
CREATE TABLE IF NOT EXISTS log_auditoria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    usuario_nome VARCHAR(100) NOT NULL,
    acao VARCHAR(100) NOT NULL,
    detalhes TEXT,
    ip VARCHAR(45) NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para buscas rápidas e relatórios filtrados por período e tipo de ação
CREATE INDEX IF NOT EXISTS idx_log_auditoria_usuario ON log_auditoria(usuario_id);
CREATE INDEX IF NOT EXISTS idx_log_auditoria_acao ON log_auditoria(acao);
CREATE INDEX IF NOT EXISTS idx_log_auditoria_periodo ON log_auditoria(created_at);
