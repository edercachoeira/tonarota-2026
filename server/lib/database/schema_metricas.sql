-- Tabela de métricas diárias
CREATE TABLE IF NOT EXISTS estabelecimento_metrica (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estabelecimento_id UUID NOT NULL REFERENCES estabelecimento(id) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('visualizacao', 'whatsapp', 'instagram')),
    data DATE NOT NULL DEFAULT CURRENT_DATE,
    quantidade INT NOT NULL DEFAULT 1,
    UNIQUE (estabelecimento_id, tipo, data)
);

CREATE INDEX IF NOT EXISTS idx_metrica_estabelecimento_data ON estabelecimento_metrica(estabelecimento_id, data);

-- Trigger para atualizar nota média e quantidade de avaliações em tempo real
CREATE OR REPLACE FUNCTION atualizar_rating_estabelecimento()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE estabelecimento
    SET 
        nota_media = COALESCE((SELECT AVG(nota)::NUMERIC(3,2) FROM avaliacao WHERE estabelecimento_id = NEW.estabelecimento_id AND status = 'aprovada'), 0.0),
        total_avaliacoes = (SELECT COUNT(*) FROM avaliacao WHERE estabelecimento_id = NEW.estabelecimento_id AND status = 'aprovada')
    WHERE id = NEW.estabelecimento_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_atualizar_rating
AFTER INSERT OR UPDATE OR DELETE ON avaliacao
FOR EACH ROW
EXECUTE FUNCTION atualizar_rating_estabelecimento();
