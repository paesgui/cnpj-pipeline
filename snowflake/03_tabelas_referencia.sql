-- ============================================================================
-- 03 - TABELAS DE REFERENCIA
-- ============================================================================

CREATE TABLE IF NOT EXISTS CNPJ_DB.PUBLIC.NATUREZAS (
    CODIGO_NATUREZA VARCHAR(4),
    DESCRICAO_NATUREZA VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS CNPJ_DB.PUBLIC.PORTES_EMPRESA (
    CODIGO_PORTE VARCHAR(2),
    DESCRICAO_PORTE VARCHAR(100)
);

-- MERGE evita inserir novamente os codigos ja cadastrados.
MERGE INTO CNPJ_DB.PUBLIC.PORTES_EMPRESA AS destino
USING (
    SELECT column1 AS CODIGO_PORTE, column2 AS DESCRICAO_PORTE
    FROM VALUES
        ('00', 'Não informado'),
        ('01', 'Microempresa (ME)'),
        ('03', 'Empresa de Pequeno Porte (EPP)'),
        ('05', 'Demais empresas')
) AS origem
ON destino.CODIGO_PORTE = origem.CODIGO_PORTE
WHEN NOT MATCHED THEN
    INSERT (CODIGO_PORTE, DESCRICAO_PORTE)
    VALUES (origem.CODIGO_PORTE, origem.DESCRICAO_PORTE);
