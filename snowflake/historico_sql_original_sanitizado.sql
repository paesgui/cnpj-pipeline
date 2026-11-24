-- ============================================================================
-- 01 - RELACIONAMENTO DE ESTATISTICAS E AUDITORIA
-- ============================================================================

-- OBJETIVO: Relaciona dados de tabelas diferentes usando a chave indicada no ON.
SELECT
    N.CODIGO_NATUREZA,
    N.DESCRICAO_NATUREZA,
    E.CODIGO_PORTE,
    E.TOTAL_EMPRESAS,
    E.CAPITAL_MEDIANO,
    A.CAPITAL_MEDIO
FROM CNPJ_DB.PUBLIC.FCT_ESTATISTICAS_CAPITAL_SOCIAL E
INNER JOIN CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL A
    ON E.CODIGO_NATUREZA = A.CODIGO_NATUREZA
    AND E.CODIGO_PORTE = A.CODIGO_PORTE
ORDER BY E.TOTAL_EMPRESAS DESC
LIMIT 20;


CREATE DATABASE IF NOT EXISTS CNPJ_DB;

-- ============================================================================
-- 02 - INFRAESTRUTURA SNOWFLAKE E ACESSO AO S3
-- ============================================================================

-- OBJETIVO: Cria o warehouse usado para executar as consultas no Snowflake.
CREATE WAREHOUSE IF NOT EXISTS CNPJ_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;


-- OBJETIVO: Configura a integracao segura entre Snowflake e o bucket AWS S3.
CREATE STORAGE INTEGRATION CNPJ_S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'ARN_DA_ROLE_AWS'
  STORAGE_ALLOWED_LOCATIONS = (
    's3://NOME_DO_BUCKET/'
  );

-- OBJETIVO: Inspeciona as propriedades da integracao com o S3.
  DESC INTEGRATION CNPJ_S3_INTEGRATION;

-- OBJETIVO: Cria um stage para o Snowflake acessar os arquivos armazenados no S3.
  CREATE STAGE CNPJ_S3_STAGE
  URL = 's3://NOME_DO_BUCKET/landing/raw/'
  STORAGE_INTEGRATION = CNPJ_S3_INTEGRATION;

-- OBJETIVO: Lista os arquivos disponiveis no stage/caminho informado.
  LIST @CNPJ_S3_STAGE;

-- OBJETIVO: Define como o Snowflake deve interpretar os arquivos CSV (separador, codificacao e aspas).
  CREATE OR REPLACE FILE FORMAT CNPJ_CSV_FORMAT
TYPE = CSV
FIELD_DELIMITER = ';'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
ENCODING = 'ISO-8859-1'
SKIP_HEADER = 0;

-- ============================================================================
-- 03 - CARGA E VALIDACAO INICIAL DE EMPRESAS
-- ============================================================================

-- OBJETIVO: Cria ou recria a tabela de destino para armazenar os dados carregados.
CREATE OR REPLACE TABLE EMPRESAS_BRONZE (
    CNPJ_BASICO VARCHAR,
    RAZAO_SOCIAL VARCHAR,
    NATUREZA_JURIDICA VARCHAR,
    QUALIFICACAO_RESPONSAVEL VARCHAR,
    CAPITAL_SOCIAL VARCHAR,
    PORTE_EMPRESA VARCHAR,
    ENTE_FEDERATIVO_RESPONSAVEL VARCHAR
);

-- OBJETIVO: Carrega os dados do stage do S3 para a tabela Snowflake.
COPY INTO EMPRESAS_BRONZE
FROM @CNPJ_S3_STAGE/2026-10/Empresas0.zip
FILE_FORMAT = (FORMAT_NAME = CNPJ_CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- OBJETIVO: Lista os arquivos disponiveis no stage/caminho informado.
LIST @CNPJ_S3_STAGE/2026-10/;

-- OBJETIVO: Carrega os dados do stage do S3 para a tabela Snowflake.
COPY INTO EMPRESAS_BRONZE
FROM @CNPJ_S3_STAGE/2026-10/Empresas0.csv
FILE_FORMAT = (FORMAT_NAME = CNPJ_CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- OBJETIVO: Consulta ou valida a tabela Bronze de empresas.
SELECT COUNT(*) AS TOTAL_REGISTROS
FROM EMPRESAS_BRONZE;

-- OBJETIVO: Consulta ou valida a tabela Bronze de empresas.
SELECT *
FROM EMPRESAS_BRONZE
LIMIT 10;

-- OBJETIVO: Executa uma consulta exploratoria ou analitica; confira as colunas, filtros e agrupamentos para identificar o recorte.
SELECT COUNT(*) AS TOTAL_REGISTROS
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS;

-- OBJETIVO: Executa uma consulta exploratoria ou analitica; confira as colunas, filtros e agrupamentos para identificar o recorte.
SELECT *
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS
LIMIT 10;

-- OBJETIVO: Consulta empresas e indicadores de capital agrupados por porte.
SELECT
    PORTE_EMPRESA,
    COUNT(*) AS TOTAL_EMPRESAS,
    ROUND(AVG(CAPITAL_SOCIAL), 2) AS CAPITAL_SOCIAL_MEDIO,
    ROUND(SUM(CAPITAL_SOCIAL), 2) AS CAPITAL_SOCIAL_TOTAL
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS
GROUP BY PORTE_EMPRESA
ORDER BY TOTAL_EMPRESAS DESC

SELECT *
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_PORTE
ORDER BY TOTAL_EMPRESAS DESC;


-- ============================================================================
-- 04 - CONSULTAS INICIAIS SOBRE EMPRESAS E PORTE
-- ============================================================================

-- OBJETIVO: Consulta empresas e indicadores de capital agrupados por porte.
SELECT SUM(TOTAL_EMPRESAS) AS TOTAL
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_PORTE;


-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 15;


-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT
    NATUREZA_JURIDICA,
    TOTAL_EMPRESAS,
    CAPITAL_SOCIAL_MEDIO,
    CAPITAL_SOCIAL_TOTAL
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 5;



-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT
    NATUREZA_JURIDICA,
    DESCRICAO_NATUREZA,
    TOTAL_EMPRESAS,
    CAPITAL_SOCIAL_MEDIO,
    CAPITAL_SOCIAL_TOTAL
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 15;


-- ============================================================================
-- 05 - CARGA E VALIDACAO DE NATUREZAS JURIDICAS
-- ============================================================================

-- OBJETIVO: Cria ou recria a tabela de destino para armazenar os dados carregados.
CREATE OR REPLACE TABLE CNPJ_DB.PUBLIC.NATUREZAS (
    CODIGO_NATUREZA VARCHAR(4),
    DESCRICAO_NATUREZA VARCHAR(200)
);


-- OBJETIVO: Carrega os dados do stage do S3 para a tabela Snowflake.
COPY INTO CNPJ_DB.PUBLIC.NATUREZAS
FROM @CNPJ_DB.PUBLIC.CNPJ_S3_STAGE/bronze/2026-10/naturezas.csv
FILE_FORMAT = (FORMAT_NAME = CNPJ_DB.PUBLIC.CNPJ_CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- OBJETIVO: Valida ou consulta o cadastro de codigos e descricoes de naturezas juridicas.
SELECT
    COUNT(*) AS TOTAL_NATUREZAS
FROM CNPJ_DB.PUBLIC.NATUREZAS;

-- OBJETIVO: Valida ou consulta o cadastro de codigos e descricoes de naturezas juridicas.
SELECT *
FROM CNPJ_DB.PUBLIC.NATUREZAS
ORDER BY CODIGO_NATUREZA;

-- OBJETIVO: Lista os arquivos disponiveis no stage/caminho informado.
LIST @CNPJ_DB.PUBLIC.CNPJ_S3_STAGE/bronze/2026-10/;

-- OBJETIVO: Consulta a configuracao do stage e seu caminho no S3.
DESC STAGE CNPJ_DB.PUBLIC.CNPJ_S3_STAGE;

-- OBJETIVO: Recupera o resultado do comando anterior para consultar propriedades do stage.
SELECT "property", "property_value"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "property" IN ('URL', 'STORAGE_INTEGRATION');


-- OBJETIVO: Consulta a configuracao do stage e seu caminho no S3.
DESC STAGE CNPJ_DB.PUBLIC.CNPJ_S3_STAGE;


-- OBJETIVO: Inspeciona as propriedades da integracao com o S3.
DESC INTEGRATION CNPJ_S3_INTEGRATION;


-- OBJETIVO: Cria um stage para o Snowflake acessar os arquivos armazenados no S3.
CREATE STAGE IF NOT EXISTS CNPJ_DB.PUBLIC.CNPJ_BRONZE_STAGE
URL = 's3://NOME_DO_BUCKET/bronze/'
STORAGE_INTEGRATION = CNPJ_S3_INTEGRATION
FILE_FORMAT = CNPJ_CSV_FORMAT;

-- OBJETIVO: Lista os arquivos disponiveis no stage/caminho informado.
LIST @CNPJ_DB.PUBLIC.CNPJ_BRONZE_STAGE/2026-10/;


-- OBJETIVO: Carrega os dados do stage do S3 para a tabela Snowflake.
COPY INTO CNPJ_DB.PUBLIC.NATUREZAS
FROM @CNPJ_DB.PUBLIC.CNPJ_BRONZE_STAGE/2026-10/naturezas.csv
FILE_FORMAT = (FORMAT_NAME = CNPJ_DB.PUBLIC.CNPJ_CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- OBJETIVO: Valida ou consulta o cadastro de codigos e descricoes de naturezas juridicas.
SELECT COUNT(*) FROM CNPJ_DB.PUBLIC.NATUREZAS;


-- OBJETIVO: Valida ou consulta o cadastro de codigos e descricoes de naturezas juridicas.
SELECT
    COUNT(*) AS TOTAL_REGISTROS,
    COUNT(DISTINCT CODIGO_NATUREZA) AS CODIGOS_DISTINTOS
FROM CNPJ_DB.PUBLIC.NATUREZAS;


-- OBJETIVO: Valida ou consulta o cadastro de codigos e descricoes de naturezas juridicas.
SELECT
    CODIGO_NATUREZA,
    COUNT(*) AS QUANTIDADE
FROM CNPJ_DB.PUBLIC.NATUREZAS
GROUP BY CODIGO_NATUREZA
HAVING COUNT(*) > 1;


-- OBJETIVO: Relaciona dados de tabelas diferentes usando a chave indicada no ON.
SELECT
    E.NATUREZA_JURIDICA,
    COUNT(*) AS TOTAL_EMPRESAS
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS E
LEFT JOIN CNPJ_DB.PUBLIC.NATUREZAS N
    ON TRIM(E.NATUREZA_JURIDICA) = TRIM(N.CODIGO_NATUREZA)
WHERE N.CODIGO_NATUREZA IS NULL
GROUP BY E.NATUREZA_JURIDICA
ORDER BY TOTAL_EMPRESAS DESC;


-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 15;


-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT SUM(TOTAL_EMPRESAS)
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA;

-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT
    DESCRICAO_NATUREZA,
    PORTE_EMPRESA,
    TOTAL_EMPRESAS,
    CAPITAL_SOCIAL_MEDIO,
    CAPITAL_SOCIAL_TOTAL
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 20;

-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT SUM(TOTAL_EMPRESAS)
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE;

-- ============================================================================
-- 06 - CADASTRO DE PORTES E ANALISE DE CONCENTRACAO
-- ============================================================================

-- OBJETIVO: Cria ou recria a tabela de destino para armazenar os dados carregados.
CREATE OR REPLACE TABLE CNPJ_DB.PUBLIC.PORTES_EMPRESA (
    CODIGO_PORTE VARCHAR(2),
    DESCRICAO_PORTE VARCHAR(100)
);


-- OBJETIVO: Insere manualmente o de-para entre codigos de porte e suas descricoes.
INSERT INTO CNPJ_DB.PUBLIC.PORTES_EMPRESA
    (CODIGO_PORTE, DESCRICAO_PORTE)
VALUES
    ('00', 'Não informado'),
    ('01', 'Microempresa (ME)'),
    ('03', 'Empresa de Pequeno Porte (EPP)'),
    ('05', 'Demais empresas');

-- OBJETIVO: Consulta o de-para dos codigos de porte e suas descricoes.
    SELECT *
FROM CNPJ_DB.PUBLIC.PORTES_EMPRESA
ORDER BY CODIGO_PORTE;

-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT
    TRIM(CODIGO_PORTE) AS CODIGO_PORTE,
    TRIM(DESCRICAO_PORTE) AS DESCRICAO_PORTE
FROM CNPJ_DB.PUBLIC.PORTES_EMPRESA


SELECT
    CODIGO_PORTE,
    DESCRICAO_PORTE,
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE
GROUP BY CODIGO_PORTE, DESCRICAO_PORTE
ORDER BY CODIGO_PORTE;

-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE;

-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT
    CODIGO_PORTE,
    DESCRICAO_PORTE,
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE
GROUP BY CODIGO_PORTE, DESCRICAO_PORTE
ORDER BY CODIGO_PORTE;


-- OBJETIVO: Mede a concentracao de empresas por natureza juridica e participacao acumulada.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_CONCENTRACAO_NATUREZA
ORDER BY RANKING
LIMIT 20;

-- OBJETIVO: Mede a concentracao de empresas por natureza juridica e participacao acumulada.
SELECT
    DESCRICAO_NATUREZA,
    TOTAL_EMPRESAS,
    PARTICIPACAO_PERCENTUAL,
    RANKING,
    PARTICIPACAO_ACUMULADA
FROM CNPJ_DB.PUBLIC.FCT_CONCENTRACAO_NATUREZA
WHERE RANKING <= 10
ORDER BY RANKING;



-- ============================================================================
-- 07 - ANALISE DE CAPITAL SOCIAL ZERADO E DISTRIBUICAO
-- ============================================================================

-- OBJETIVO: Investiga empresas com capital social zerado ou nao informado.
SELECT
    DESCRICAO_NATUREZA,
    DESCRICAO_PORTE,
    TOTAL_EMPRESAS,
    EMPRESAS_CAPITAL_ZERADO,
    EMPRESAS_CAPITAL_NAO_INFORMADO,
    PERCENTUAL_CAPITAL_ZERADO
FROM CNPJ_DB.PUBLIC.FCT_CAPITAL_SOCIAL_ZERADO
ORDER BY EMPRESAS_CAPITAL_ZERADO DESC
LIMIT 20;


-- OBJETIVO: Investiga empresas com capital social zerado ou nao informado.
SELECT
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,
    SUM(EMPRESAS_CAPITAL_ZERADO) AS CAPITAL_ZERADO,
    SUM(EMPRESAS_CAPITAL_NAO_INFORMADO) AS CAPITAL_NAO_INFORMADO,
    ROUND(
        SUM(EMPRESAS_CAPITAL_ZERADO) * 100.0
        / SUM(TOTAL_EMPRESAS),
        2
    ) AS PERCENTUAL_CAPITAL_ZERADO
FROM CNPJ_DB.PUBLIC.FCT_CAPITAL_SOCIAL_ZERADO;

-- OBJETIVO: Investiga empresas com capital social zerado ou nao informado.
SELECT
    DESCRICAO_NATUREZA,
    DESCRICAO_PORTE,
    TOTAL_EMPRESAS,
    EMPRESAS_CAPITAL_ZERADO,
    PERCENTUAL_CAPITAL_ZERADO
FROM CNPJ_DB.PUBLIC.FCT_CAPITAL_SOCIAL_ZERADO
WHERE EMPRESAS_CAPITAL_ZERADO > 0
ORDER BY EMPRESAS_CAPITAL_ZERADO DESC
LIMIT 20;


-- OBJETIVO: Investiga empresas com capital social zerado ou nao informado.
SELECT
    DESCRICAO_NATUREZA,
    DESCRICAO_PORTE,
    TOTAL_EMPRESAS,
    EMPRESAS_CAPITAL_ZERADO,
    PERCENTUAL_CAPITAL_ZERADO
FROM CNPJ_DB.PUBLIC.FCT_CAPITAL_SOCIAL_ZERADO
WHERE EMPRESAS_CAPITAL_ZERADO > 0
ORDER BY EMPRESAS_CAPITAL_ZERADO DESC
LIMIT 20;


-- OBJETIVO: Analisa a distribuicao das empresas por faixas de capital social.
SELECT
    FAIXA_CAPITAL,
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,
    ROUND(
        SUM(TOTAL_EMPRESAS) * 100.0 /
        SUM(SUM(TOTAL_EMPRESAS)) OVER (),
        2
    ) AS PARTICIPACAO_PERCENTUAL,
    SUM(CAPITAL_TOTAL) AS CAPITAL_TOTAL
FROM CNPJ_DB.PUBLIC.FCT_DISTRIBUICAO_CAPITAL_SOCIAL
GROUP BY ORDEM_FAIXA, FAIXA_CAPITAL
ORDER BY ORDEM_FAIXA;


-- OBJETIVO: Analisa a distribuicao das empresas por faixas de capital social.
SELECT
    FAIXA_CAPITAL,
    PORTE_EMPRESA,
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,
    ROUND(
        SUM(TOTAL_EMPRESAS) * 100.0 /
        SUM(SUM(TOTAL_EMPRESAS)) OVER (
            PARTITION BY PORTE_EMPRESA
        ),
        2
    ) AS PARTICIPACAO_PERCENTUAL
FROM CNPJ_DB.PUBLIC.FCT_DISTRIBUICAO_CAPITAL_SOCIAL
GROUP BY
    ORDEM_FAIXA,
    FAIXA_CAPITAL,
    PORTE_EMPRESA
ORDER BY ORDEM_FAIXA, PORTE_EMPRESA;


-- ============================================================================
-- 08 - INVESTIGACAO DE CAPITAIS E VALORES EXTREMOS
-- ============================================================================

-- OBJETIVO: Consulta ou analisa os dados tratados das empresas, incluindo capital social.
SELECT
    CNPJ_BASICO,
    RAZAO_SOCIAL,
    NATUREZA_JURIDICA,
    PORTE_EMPRESA,
    CAPITAL_SOCIAL
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS
ORDER BY CAPITAL_SOCIAL DESC
LIMIT 20;


-- OBJETIVO: Investiga a quantidade e o impacto financeiro do valor extremo observado de R$ 999.999.999.999.
SELECT
    COUNT(*) AS TOTAL_EMPRESAS,
    SUM(CAPITAL_SOCIAL) AS CAPITAL_TOTAL,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM CNPJ_DB.PUBLIC.STG_EMPRESAS),
        4
    ) AS PARTICIPACAO_BASE
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS
WHERE CAPITAL_SOCIAL = 999999999999.00;

-- OBJETIVO: Consulta ou analisa os dados tratados das empresas, incluindo capital social.
SELECT
    CAPITAL_SOCIAL,
    COUNT(*) AS TOTAL_EMPRESAS
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS
WHERE CAPITAL_SOCIAL >= 100000000
GROUP BY CAPITAL_SOCIAL
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 20;


-- OBJETIVO: Relaciona dados de tabelas diferentes usando a chave indicada no ON.
SELECT
    N.DESCRICAO_NATUREZA,
    COUNT(*) AS TOTAL_EMPRESAS,
    SUM(E.CAPITAL_SOCIAL) AS CAPITAL_TOTAL
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS E
INNER JOIN CNPJ_DB.PUBLIC.STG_NATUREZAS N
    ON E.NATUREZA_JURIDICA = N.CODIGO_NATUREZA
WHERE E.CAPITAL_SOCIAL = 999999999999.00
GROUP BY N.DESCRICAO_NATUREZA
ORDER BY TOTAL_EMPRESAS DESC;


-- OBJETIVO: Audita capitais elevados, negativos, nulos e valores extremos por grupo.
SELECT
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,
    SUM(EMPRESAS_VALOR_LIMITE_OBSERVADO) AS VALORES_EXTREMOS,
    SUM(EMPRESAS_CAPITAL_ELEVADO) AS CAPITAIS_ELEVADOS,
    SUM(EMPRESAS_CAPITAL_NEGATIVO) AS CAPITAIS_NEGATIVOS,
    SUM(EMPRESAS_CAPITAL_NULO) AS CAPITAIS_NULOS
FROM CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL;

-- OBJETIVO: Audita capitais elevados, negativos, nulos e valores extremos por grupo.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL
WHERE EMPRESAS_VALOR_LIMITE_OBSERVADO > 0
ORDER BY EMPRESAS_VALOR_LIMITE_OBSERVADO DESC;

-- OBJETIVO: Audita capitais elevados, negativos, nulos e valores extremos por grupo.
SELECT
    CODIGO_PORTE,
    SUM(EMPRESAS_CAPITAL_ELEVADO) AS TOTAL_CAPITAIS_ELEVADOS
FROM CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL
GROUP BY CODIGO_PORTE
ORDER BY TOTAL_CAPITAIS_ELEVADOS DESC;

-- ============================================================================
-- 09 - ESTATISTICAS, MEDIANA E DISPERSAO DO CAPITAL
-- ============================================================================

-- OBJETIVO: Consulta estatisticas de capital social, incluindo mediana, por natureza juridica e porte.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_ESTATISTICAS_CAPITAL_SOCIAL
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 20;

-- OBJETIVO: Relaciona dados de tabelas diferentes usando a chave indicada no ON.
SELECT
    E.CODIGO_NATUREZA,
    E.DESCRICAO_NATUREZA,
    E.CODIGO_PORTE,
    E.TOTAL_EMPRESAS,
    E.CAPITAL_MEDIANO,
    A.CAPITAL_MEDIO,
    ROUND(
        A.CAPITAL_MEDIO - E.CAPITAL_MEDIANO,
        2
    ) AS DIFERENCA_MEDIA_MEDIANA
FROM CNPJ_DB.PUBLIC.FCT_ESTATISTICAS_CAPITAL_SOCIAL E
INNER JOIN CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL A
    ON E.CODIGO_NATUREZA = A.CODIGO_NATUREZA
    AND E.CODIGO_PORTE = A.CODIGO_PORTE
ORDER BY E.TOTAL_EMPRESAS DESC
LIMIT 20;

-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_MEDIANO,
    CAPITAL_P25,
    CAPITAL_P75,
    AMPLITUDE_INTERQUARTIL,
    RAZAO_MEDIA_MEDIANA
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
ORDER BY AMPLITUDE_INTERQUARTIL DESC
LIMIT 20;

-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_MEDIANO,
    CAPITAL_MEDIO,
    RAZAO_MEDIA_MEDIANA
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
WHERE RAZAO_MEDIA_MEDIANA IS NOT NULL
ORDER BY RAZAO_MEDIA_MEDIANA DESC
LIMIT 20;

-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_MEDIANO,
    CAPITAL_P25,
    CAPITAL_P75,
    AMPLITUDE_INTERQUARTIL,
    RAZAO_MEDIA_MEDIANA
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
ORDER BY AMPLITUDE_INTERQUARTIL DESC
LIMIT 20;

-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_MEDIANO,
    CAPITAL_MEDIO,
    RAZAO_MEDIA_MEDIANA
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
WHERE RAZAO_MEDIA_MEDIANA IS NOT NULL
ORDER BY RAZAO_MEDIA_MEDIANA DESC
LIMIT 20;

-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_MEDIANO,
    CAPITAL_MEDIO,
    RAZAO_MEDIA_MEDIANA,
    AMPLITUDE_INTERQUARTIL
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
WHERE TOTAL_EMPRESAS >= 1000
  AND RAZAO_MEDIA_MEDIANA IS NOT NULL
ORDER BY RAZAO_MEDIA_MEDIANA DESC
LIMIT 20;


-- ============================================================================
-- 10 - COMPARACAO DE MEDIAS E IMPACTO DOS EXTREMOS
-- ============================================================================

-- OBJETIVO: Monta uma base/etapas intermediarias (CTEs) e executa uma analise sobre os dados.
WITH BASE AS (
    SELECT
        N.CODIGO_NATUREZA,
        N.DESCRICAO_NATUREZA,
        E.PORTE_EMPRESA AS CODIGO_PORTE,
        E.CAPITAL_SOCIAL
    FROM CNPJ_DB.PUBLIC.STG_EMPRESAS E
    INNER JOIN CNPJ_DB.PUBLIC.STG_NATUREZAS N
        ON E.NATUREZA_JURIDICA = N.CODIGO_NATUREZA
)
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,

    COUNT(*) AS TOTAL_EMPRESAS,

    ROUND(AVG(CAPITAL_SOCIAL), 2) AS MEDIA_ORIGINAL,

    ROUND(
        AVG(IFF(
            CAPITAL_SOCIAL < 100000000,
            CAPITAL_SOCIAL,
            NULL
        )), 2
    ) AS MEDIA_SEM_CAPITAIS_ACIMA_100M,

    ROUND(
        AVG(IFF(
            CAPITAL_SOCIAL <> 999999999999.00,
            CAPITAL_SOCIAL,
            NULL
        )), 2
    ) AS MEDIA_SEM_VALOR_EXTREMO,

    COUNT_IF(CAPITAL_SOCIAL >= 100000000)
        AS TOTAL_CAPITAIS_ACIMA_100M,

    COUNT_IF(CAPITAL_SOCIAL = 999999999999.00)
        AS TOTAL_VALORES_EXTREMOS

FROM BASE
GROUP BY
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE
HAVING COUNT(*) >= 1000
ORDER BY MEDIA_ORIGINAL DESC
LIMIT 20;


-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT
    DESCRICAO_NATUREZA,
    TOTAL_EMPRESAS,
    ROUND(
        TOTAL_EMPRESAS * 100.0
        / SUM(TOTAL_EMPRESAS) OVER (),
        2
    ) AS PARTICIPACAO_PERCENTUAL
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA
ORDER BY TOTAL_EMPRESAS DESC
LIMIT 20;

-- ============================================================================
-- 11 - PARTICIPACAO POR PORTE, NATUREZA E CAPITAL
-- ============================================================================

-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT
    CASE
        WHEN CODIGO_PORTE = '01' THEN 'Microempresa (ME)'
        WHEN CODIGO_PORTE = '03' THEN 'Empresa de Pequeno Porte (EPP)'
        WHEN CODIGO_PORTE = '05' THEN 'Demais empresas'
        ELSE 'Não informado'
    END AS DESCRICAO_PORTE,

    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,

    ROUND(
        SUM(TOTAL_EMPRESAS) * 100.0
        / SUM(SUM(TOTAL_EMPRESAS)) OVER (),
        2
    ) AS PARTICIPACAO_PERCENTUAL

FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE

GROUP BY CODIGO_PORTE
ORDER BY TOTAL_EMPRESAS DESC;


-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT
    CODIGO_PORTE,
    DESCRICAO_NATUREZA,
    TOTAL_EMPRESAS,

    ROUND(
        TOTAL_EMPRESAS * 100.0
        / SUM(TOTAL_EMPRESAS) OVER (
            PARTITION BY CODIGO_PORTE
        ),
        2
    ) AS PARTICIPACAO_NO_PORTE,

    ROW_NUMBER() OVER (
        PARTITION BY CODIGO_PORTE
        ORDER BY TOTAL_EMPRESAS DESC
    ) AS RANKING

FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE

QUALIFY RANKING <= 10

ORDER BY CODIGO_PORTE, RANKING;


-- OBJETIVO: Analisa a distribuicao das empresas por faixas de capital social.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_DISTRIBUICAO_CAPITAL_SOCIAL
LIMIT 20;


-- OBJETIVO: Analisa a distribuicao das empresas por faixas de capital social.
SELECT
    CASE
        WHEN PORTE_EMPRESA = '01' THEN 'Microempresa (ME)'
        WHEN PORTE_EMPRESA = '03' THEN 'Empresa de Pequeno Porte (EPP)'
        WHEN PORTE_EMPRESA = '05' THEN 'Demais empresas'
        ELSE 'Não informado'
    END AS DESCRICAO_PORTE,

    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,

    SUM(
        IFF(ORDEM_FAIXA IN (6, 7), TOTAL_EMPRESAS, 0)
    ) AS EMPRESAS_ACIMA_100MIL,

    ROUND(
        100.0 * SUM(
            IFF(ORDEM_FAIXA IN (6, 7), TOTAL_EMPRESAS, 0)
        ) / SUM(TOTAL_EMPRESAS),
        2
    ) AS PERCENTUAL_ACIMA_100MIL,

    SUM(
        IFF(ORDEM_FAIXA = 7, TOTAL_EMPRESAS, 0)
    ) AS EMPRESAS_ACIMA_1MILHAO

FROM CNPJ_DB.PUBLIC.FCT_DISTRIBUICAO_CAPITAL_SOCIAL

GROUP BY PORTE_EMPRESA
ORDER BY PORTE_EMPRESA;


-- OBJETIVO: Cruza natureza juridica e porte para comparar quantidades, participacoes e rankings.
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_SOCIAL_TOTAL,

    ROUND(
        CAPITAL_SOCIAL_TOTAL * 100.0
        / SUM(CAPITAL_SOCIAL_TOTAL) OVER (),
        4
    ) AS PARTICIPACAO_CAPITAL_TOTAL

FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA_PORTE

ORDER BY CAPITAL_SOCIAL_TOTAL DESC
LIMIT 20;



-- ============================================================================
-- 12 - ANALISE DE CAPITAL COM E SEM VALORES ELEVADOS
-- ============================================================================

-- OBJETIVO: Monta uma base/etapas intermediarias (CTEs) e executa uma analise sobre os dados.
WITH BASE AS (
    SELECT
        N.CODIGO_NATUREZA,
        N.DESCRICAO_NATUREZA,
        E.PORTE_EMPRESA AS CODIGO_PORTE,
        E.CAPITAL_SOCIAL
    FROM CNPJ_DB.PUBLIC.STG_EMPRESAS E
    INNER JOIN CNPJ_DB.PUBLIC.STG_NATUREZAS N
        ON E.NATUREZA_JURIDICA = N.CODIGO_NATUREZA
),

AGREGADO AS (
    SELECT
        CODIGO_NATUREZA,
        DESCRICAO_NATUREZA,
        CODIGO_PORTE,

        COUNT(*) AS TOTAL_EMPRESAS,

        SUM(CAPITAL_SOCIAL) AS CAPITAL_ORIGINAL,

        SUM(
            IFF(CAPITAL_SOCIAL < 100000000,
                CAPITAL_SOCIAL, 0)
        ) AS CAPITAL_SEM_ACIMA_100M,

        COUNT_IF(CAPITAL_SOCIAL >= 100000000)
            AS TOTAL_ACIMA_100M

    FROM BASE
    GROUP BY
        CODIGO_NATUREZA,
        DESCRICAO_NATUREZA,
        CODIGO_PORTE
)

SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_ORIGINAL,

    ROUND(
        100.0 * CAPITAL_ORIGINAL
        / SUM(CAPITAL_ORIGINAL) OVER (),
        4
    ) AS PARTICIPACAO_ORIGINAL,

    CAPITAL_SEM_ACIMA_100M,

    ROUND(
        100.0 * CAPITAL_SEM_ACIMA_100M
        / NULLIF(SUM(CAPITAL_SEM_ACIMA_100M) OVER (), 0),
        4
    ) AS PARTICIPACAO_SEM_ACIMA_100M,

    TOTAL_ACIMA_100M

FROM AGREGADO
ORDER BY CAPITAL_SEM_ACIMA_100M DESC
LIMIT 20;


-- OBJETIVO: Investiga empresas com capital social zerado ou nao informado.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_CAPITAL_SOCIAL_ZERADO
LIMIT 10;



-- OBJETIVO: Investiga empresas com capital social zerado ou nao informado.
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    DESCRICAO_PORTE,
    TOTAL_EMPRESAS,
    EMPRESAS_CAPITAL_ZERADO,
    PERCENTUAL_CAPITAL_ZERADO
FROM CNPJ_DB.PUBLIC.FCT_CAPITAL_SOCIAL_ZERADO
WHERE TOTAL_EMPRESAS >= 1000
ORDER BY PERCENTUAL_CAPITAL_ZERADO DESC
LIMIT 20;


-- OBJETIVO: Consulta o total de empresas e os indicadores de capital por natureza juridica.
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    TOTAL_EMPRESAS,
    CAPITAL_SOCIAL_MEDIO,
    CAPITAL_SOCIAL_TOTAL
FROM CNPJ_DB.PUBLIC.FCT_EMPRESAS_POR_NATUREZA
WHERE TOTAL_EMPRESAS >= 1000
ORDER BY CAPITAL_SOCIAL_MEDIO DESC
LIMIT 20;


-- OBJETIVO: Consulta estatisticas de capital social, incluindo mediana, por natureza juridica e porte.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_ESTATISTICAS_CAPITAL_SOCIAL
LIMIT 10;


-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
LIMIT 10;


-- OBJETIVO: Analisa a dispersao do capital social por natureza juridica e porte (mediana, quartis e razoes).
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    TOTAL_EMPRESAS,
    CAPITAL_MEDIANO,
    CAPITAL_MEDIO,
    CAPITAL_P25,
    CAPITAL_P75,
    CAPITAL_P90,
    AMPLITUDE_INTERQUARTIL,
    RAZAO_P90_MEDIANA,
    RAZAO_MEDIA_MEDIANA
FROM CNPJ_DB.PUBLIC.FCT_DISPERSAO_CAPITAL_SOCIAL
WHERE TOTAL_EMPRESAS >= 1000
  AND CAPITAL_MEDIANO > 0
ORDER BY AMPLITUDE_INTERQUARTIL DESC
LIMIT 20;


-- OBJETIVO: Audita capitais elevados, negativos, nulos e valores extremos por grupo.
SELECT *
FROM CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL
LIMIT 10;

-- OBJETIVO: Audita capitais elevados, negativos, nulos e valores extremos por grupo.
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,
    SUM(EMPRESAS_CAPITAL_ELEVADO) AS TOTAL_CAPITAL_ACIMA_100M,
    ROUND(
        100.0 * SUM(EMPRESAS_CAPITAL_ELEVADO)
        / NULLIF(SUM(TOTAL_EMPRESAS), 0),
        4
    ) AS PERCENTUAL_CAPITAL_ACIMA_100M
FROM CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL
GROUP BY
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA
ORDER BY TOTAL_CAPITAL_ACIMA_100M DESC
LIMIT 20;

-- OBJETIVO: Audita capitais elevados, negativos, nulos e valores extremos por grupo.
SELECT
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE,
    SUM(TOTAL_EMPRESAS) AS TOTAL_EMPRESAS,
    SUM(EMPRESAS_VALOR_LIMITE_OBSERVADO) AS TOTAL_VALORES_EXTREMOS
FROM CNPJ_DB.PUBLIC.FCT_AUDITORIA_CAPITAL_SOCIAL
WHERE EMPRESAS_VALOR_LIMITE_OBSERVADO > 0
GROUP BY
    CODIGO_NATUREZA,
    DESCRICAO_NATUREZA,
    CODIGO_PORTE
ORDER BY TOTAL_VALORES_EXTREMOS DESC;


-- OBJETIVO: Investiga a quantidade e o impacto financeiro do valor extremo observado de R$ 999.999.999.999.
SELECT
    COUNT(*) AS TOTAL_EMPRESAS,
    SUM(CAPITAL_SOCIAL) AS CAPITAL_TOTAL,

    COUNT_IF(CAPITAL_SOCIAL = 999999999999.00)
        AS TOTAL_VALORES_EXTREMOS,

    SUM(
        IFF(CAPITAL_SOCIAL = 999999999999.00,
            CAPITAL_SOCIAL, 0)
    ) AS CAPITAL_DOS_VALORES_EXTREMOS,

    SUM(
        IFF(CAPITAL_SOCIAL <> 999999999999.00,
            CAPITAL_SOCIAL, 0)
    ) AS CAPITAL_SEM_VALORES_EXTREMOS,

    ROUND(
        100.0 * SUM(
            IFF(CAPITAL_SOCIAL = 999999999999.00,
                CAPITAL_SOCIAL, 0)
        ) / NULLIF(SUM(CAPITAL_SOCIAL), 0),
        4
    ) AS PERCENTUAL_CAPITAL_EXTREMO

FROM CNPJ_DB.PUBLIC.STG_EMPRESAS;



-- ============================================================================
-- 13 - COMPARACAO GERAL COM E SEM VALORES EXTREMOS
-- ============================================================================

-- OBJETIVO: Monta uma base/etapas intermediarias (CTEs) e executa uma analise sobre os dados.
WITH BASE AS (
    SELECT CAPITAL_SOCIAL
    FROM CNPJ_DB.PUBLIC.STG_EMPRESAS
),
RESULTADO AS (
    SELECT
        COUNT(*) AS TOTAL_EMPRESAS,
        AVG(CAPITAL_SOCIAL) AS MEDIA_ORIGINAL,
        MEDIAN(CAPITAL_SOCIAL) AS MEDIANA_ORIGINAL,
        SUM(CAPITAL_SOCIAL) AS CAPITAL_TOTAL_ORIGINAL,

        AVG(IFF(
            CAPITAL_SOCIAL <> 999999999999.00,
            CAPITAL_SOCIAL,
            NULL
        )) AS MEDIA_SEM_EXTREMOS,

        MEDIAN(IFF(
            CAPITAL_SOCIAL <> 999999999999.00,
            CAPITAL_SOCIAL,
            NULL
        )) AS MEDIANA_SEM_EXTREMOS,

        SUM(IFF(
            CAPITAL_SOCIAL <> 999999999999.00,
            CAPITAL_SOCIAL,
            0
        )) AS CAPITAL_TOTAL_SEM_EXTREMOS,

        COUNT_IF(CAPITAL_SOCIAL = 999999999999.00)
            AS TOTAL_EXTREMOS
    FROM BASE
)
SELECT *
FROM RESULTADO;


-- ============================================================================
-- 14 - PREPARACAO E INSPECAO DOS ARQUIVOS DE ESTABELECIMENTOS
-- ============================================================================

-- OBJETIVO: Lista as tabelas existentes no schema.
SHOW TABLES IN SCHEMA CNPJ_DB.PUBLIC;

-- OBJETIVO: Consulta a configuracao do stage e seu caminho no S3.
DESC STAGE CNPJ_S3_STAGE;

-- OBJETIVO: Lista os arquivos disponiveis no stage/caminho informado.
LIST @CNPJ_S3_STAGE/2026-10/estabelecimentos/;

-- OBJETIVO: Define como o Snowflake deve interpretar os arquivos CSV (separador, codificacao e aspas).
CREATE OR REPLACE FILE FORMAT CNPJ_DB.PUBLIC.CNPJ_ESTABELECIMENTOS_FF
    TYPE = CSV
    FIELD_DELIMITER = ';'
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 0
    ENCODING = 'ISO88591'
    FIELD_OPTIONALLY_ENCLOSED_BY = NONE
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    COMPRESSION = NONE;


-- OBJETIVO: Executa uma consulta exploratoria ou analitica; confira as colunas, filtros e agrupamentos para identificar o recorte.
    SELECT
    t.$1  AS CNPJ_BASICO,
    t.$2  AS CNPJ_ORDEM,
    t.$3  AS CNPJ_DV,
    t.$4  AS IDENTIFICADOR_MATRIZ_FILIAL,
    t.$5  AS NOME_FANTASIA,
    t.$6  AS SITUACAO_CADASTRAL,
    t.$20 AS UF,
    t.$21 AS CODIGO_MUNICIPIO
FROM @CNPJ_S3_STAGE/2026-10/estabelecimentos/
    (FILE_FORMAT => 'CNPJ_DB.PUBLIC.CNPJ_ESTABELECIMENTOS_FF')
    t
LIMIT 10;


-- ============================================================================
-- 15 - CRIACAO DA BRONZE E DIAGNOSTICO DA CARGA DE ESTABELECIMENTOS
-- ============================================================================

-- OBJETIVO: Cria ou recria a tabela de destino para armazenar os dados carregados.
CREATE OR REPLACE TABLE CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE (
    CNPJ_BASICO VARCHAR(8),
    CNPJ_ORDEM VARCHAR(4),
    CNPJ_DV VARCHAR(2),
    IDENTIFICADOR_MATRIZ_FILIAL VARCHAR(1),
    NOME_FANTASIA VARCHAR(255),
    SITUACAO_CADASTRAL VARCHAR(2),
    DATA_SITUACAO_CADASTRAL VARCHAR(8),
    MOTIVO_SITUACAO_CADASTRAL VARCHAR(2),
    NOME_CIDADE_EXTERIOR VARCHAR(255),
    PAIS VARCHAR(3),
    DATA_INICIO_ATIVIDADE VARCHAR(8),
    CNAE_FISCAL_PRINCIPAL VARCHAR(7),
    CNAE_FISCAL_SECUNDARIA VARCHAR(2000),
    TIPO_LOGRADOURO VARCHAR(50),
    LOGRADOURO VARCHAR(255),
    NUMERO VARCHAR(20),
    COMPLEMENTO VARCHAR(255),
    BAIRRO VARCHAR(255),
    CEP VARCHAR(8),
    UF VARCHAR(2),
    CODIGO_MUNICIPIO VARCHAR(4),
    DDD1 VARCHAR(4),
    TELEFONE1 VARCHAR(20),
    DDD2 VARCHAR(4),
    TELEFONE2 VARCHAR(20),
    DDD_FAX VARCHAR(4),
    FAX VARCHAR(20),
    CORREIO_ELETRONICO VARCHAR(255),
    SITUACAO_ESPECIAL VARCHAR(255),
    DATA_SITUACAO_ESPECIAL VARCHAR(8)
);


-- OBJETIVO: Define como o Snowflake deve interpretar os arquivos CSV (separador, codificacao e aspas).
CREATE OR REPLACE FILE FORMAT CNPJ_DB.PUBLIC.CNPJ_ESTABELECIMENTOS_FF
    TYPE = CSV
    FIELD_DELIMITER = ';'
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 0
    ENCODING = 'ISO88591'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    COMPRESSION = NONE;

-- OBJETIVO: Executa uma consulta exploratoria ou analitica; confira as colunas, filtros e agrupamentos para identificar o recorte.
    SELECT
    $1 AS CNPJ_BASICO,
    $13 AS CNAE_SECUNDARIA,
    $17 AS COMPLEMENTO,
    $20 AS UF
FROM @CNPJ_S3_STAGE/2026-10/estabelecimentos/
    (FILE_FORMAT => 'CNPJ_DB.PUBLIC.CNPJ_ESTABELECIMENTOS_FF')
    t
WHERE METADATA$FILENAME LIKE '%Y4.D61010.ESTABELE'
  AND $1 = '63993112';


-- OBJETIVO: Consulta o historico de carga para verificar arquivos, status e erros.
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


-- ============================================================================
-- 16 - CARGA, VALIDACAO E RANKING DE EMPRESAS POR UF
-- ============================================================================

-- OBJETIVO: Consulta, valida ou analisa os dados brutos de estabelecimentos.
SELECT
    COUNT(*) AS TOTAL_REGISTROS
FROM CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE;

-- OBJETIVO: Carrega os dados do stage do S3 para a tabela Snowflake.
COPY INTO CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE
FROM @CNPJ_S3_STAGE/2026-10/estabelecimentos/
FILE_FORMAT = (
    FORMAT_NAME = 'CNPJ_DB.PUBLIC.CNPJ_ESTABELECIMENTOS_FF'
)
ON_ERROR = 'ABORT_STATEMENT';


-- OBJETIVO: Valida o total de estabelecimentos, UFs preenchidas e quantidade de UFs distintas.
SELECT
    COUNT(*) AS TOTAL_ESTABELECIMENTOS,
    COUNT_IF(UF IS NULL OR TRIM(UF) = '') AS UF_NAO_PREENCHIDA,
    COUNT(DISTINCT UF) AS TOTAL_UFS
FROM CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE;

-- OBJETIVO: Conta o total de estabelecimentos carregados e verifica campos de UF vazios.
SELECT
    UF,
    COUNT(*) AS TOTAL_ESTABELECIMENTOS
FROM CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE
GROUP BY UF
ORDER BY TOTAL_ESTABELECIMENTOS DESC;


-- OBJETIVO: Conta empresas por UF considerando somente matrizes e identifica as ativas pela situacao cadastral 02.
SELECT
    UF,
    COUNT(DISTINCT CNPJ_BASICO) AS TOTAL_EMPRESAS,
    COUNT(DISTINCT CASE
        WHEN SITUACAO_CADASTRAL = '02'
        THEN CNPJ_BASICO
    END) AS EMPRESAS_ATIVAS
FROM CNPJ_DB.PUBLIC.ESTABELECIMENTOS_BRONZE
WHERE IDENTIFICADOR_MATRIZ_FILIAL = '1'
  AND UF <> 'EX'
GROUP BY UF
ORDER BY EMPRESAS_ATIVAS DESC;


SELECT
    E.PORTE_EMPRESA,
    COUNT(*) AS TOTAL_EMPRESAS
FROM CNPJ_DB.PUBLIC.STG_EMPRESAS E
LEFT JOIN CNPJ_DB.PUBLIC.STG_PORTES_EMPRESA P
    ON E.PORTE_EMPRESA = P.CODIGO_PORTE
WHERE P.CODIGO_PORTE IS NULL
GROUP BY E.PORTE_EMPRESA
ORDER BY TOTAL_EMPRESAS DESC;
