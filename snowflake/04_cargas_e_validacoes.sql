-- ============================================================================
-- 04 - CARGAS E VALIDACOES
-- ============================================================================
-- IMPORTANTE:
-- Os caminhos abaixo refletem os exemplos registrados durante o projeto.
-- Confira se os arquivos ainda existem no S3 e se ja foram carregados.
-- COPY INTO pode inserir dados novamente conforme as opcoes de carga.

-- Inspecionar arquivos:
-- LIST @CNPJ_DB.PUBLIC.CNPJ_S3_STAGE/2026-10/;
-- LIST @CNPJ_DB.PUBLIC.CNPJ_S3_STAGE/2026-10/estabelecimentos/;
-- LIST @CNPJ_DB.PUBLIC.CNPJ_BRONZE_STAGE/2026-10/;

-- Exemplo de carga da tabela de empresas:
-- COPY INTO CNPJ_DB.PUBLIC.EMPRESAS_BRONZE
-- FROM @CNPJ_DB.PUBLIC.CNPJ_S3_STAGE/2026-10/Empresas0.csv
-- FILE_FORMAT = (FORMAT_NAME = CNPJ_DB.PUBLIC.CNPJ_CSV_FORMAT)
-- ON_ERROR = 'ABORT_STATEMENT';

-- Exemplo de carga da tabela de naturezas:
-- COPY INTO CNPJ_DB.PUBLIC.NATUREZAS
-- FROM @CNPJ_DB.PUBLIC.CNPJ_BRONZE_STAGE/2026-10/naturezas.csv
-- FILE_FORMAT = (FORMAT_NAME = CNPJ_DB.PUBLIC.CNPJ_CSV_FORMAT)
-- ON_ERROR = 'ABORT_STATEMENT';

-- Exemplo de carga de estabelecimentos:
-- COPY INTO CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE
-- FROM @CNPJ_DB.PUBLIC.CNPJ_S3_STAGE/2026-10/estabelecimentos/
-- FILE_FORMAT = (FORMAT_NAME = 'CNPJ_DB.PUBLIC.CNPJ_ESTABELECIMENTOS_FF')
-- ON_ERROR = 'ABORT_STATEMENT';

-- Validacoes apos a carga:
SELECT COUNT(*) AS TOTAL_EMPRESAS_BRONZE
FROM CNPJ_DB.PUBLIC.EMPRESAS_BRONZE;

SELECT COUNT(*) AS TOTAL_ESTABELECIMENTOS_BRONZE
FROM CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE;

SELECT
    COUNT(*) AS TOTAL_ESTABELECIMENTOS,
    COUNT_IF(UF IS NULL OR TRIM(UF) = '') AS UF_NAO_PREENCHIDA,
    COUNT(DISTINCT UF) AS TOTAL_UFS
FROM CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE;

-- Historico recente de carga de estabelecimentos:
SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    ROW_PARSED,
    FIRST_ERROR_MESSAGE,
    LAST_LOAD_TIME
FROM TABLE(
    CNPJ_DB.INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'ESTABELECIMENTOS_BRONZE',
        START_TIME => DATEADD('day', -2, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;
