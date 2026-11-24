
SELECT
    CNPJ_BASICO,
    CNPJ_ORDEM,
    CNPJ_DV,
    COUNT(*) AS TOTAL
FROM {{ ref('stg_estabelecimentos') }}
GROUP BY
    CNPJ_BASICO,
    CNPJ_ORDEM,
    CNPJ_DV
HAVING COUNT(*) > 1
