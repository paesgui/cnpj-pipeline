# Pipeline de Dados CNPJ — Engenharia de Dados

Pipeline de Engenharia de Dados desenvolvido para processar, transformar e analisar os dados públicos de empresas e estabelecimentos disponibilizados pela Receita Federal do Brasil.

O projeto utiliza Python, Amazon S3, Snowflake e dbt para construir um fluxo de dados organizado em camadas, com transformações SQL e testes de qualidade.

## Objetivo

Construir um pipeline de dados capaz de processar a base pública do CNPJ e disponibilizar informações estruturadas para análises sobre:

- Distribuição de empresas por natureza jurídica e porte.
- Distribuição de estabelecimentos por unidade federativa.
- Capital social das empresas.
- Empresas com capital social zerado.
- Concentração e dispersão do capital social.
- Auditoria e identificação de valores extremos.

## Tecnologias utilizadas

- Python — extração, processamento e ingestão de dados.
- Amazon S3 — armazenamento e disponibilização dos arquivos.
- Snowflake — armazenamento e processamento analítico.
- dbt Core — transformação, organização e testes dos dados.
- SQL — construção dos modelos analíticos.
- Git e GitHub — versionamento do projeto.

## Arquitetura

O projeto segue uma arquitetura de dados em camadas:

```text
Receita Federal do Brasil
          |
          v
       Python
  Extração e processamento
          |
          v
      Amazon S3
          |
          v
       Snowflake
          |
          v
    BRONZE - Dados brutos
          |
          v
    STAGING - dbt
  Limpeza e padronização
          |
          v
      MARTS - dbt
   Modelos analíticos
          |
          v
     Consultas SQL
```

## Organização do projeto

```text
cnpj_pipeline/
│
├── data/
│   └── Arquivos de origem e dados processados
│
├── models/
│   ├── staging/
│   │   ├── stg_cnpj.sql
│   │   ├── stg_empresas.sql
│   │   ├── stg_estabelecimentos.sql
│   │   ├── stg_naturezas.sql
│   │   ├── stg_portes_empresa.sql
│   │   └── schema.yml
│   │
│   └── marts/
│       ├── fct_auditoria_capital_social.sql
│       ├── fct_capital_social_zerado.sql
│       ├── fct_concentracao_natureza.sql
│       ├── fct_dispersao_capital_social.sql
│       ├── fct_distribuicao_capital_social.sql
│       ├── fct_empresas_por_natureza.sql
│       ├── fct_empresas_por_natureza_porte.sql
│       ├── fct_empresas_por_porte.sql
│       ├── fct_estabelecimentos_por_uf.sql
│       └── fct_estatisticas_capital_social.sql
│
├── scripts/
│   ├── extract_empresas.py
│   ├── ingest_cnpj.py
│   ├── processar_estabelecimentos.py
│   ├── process_bronze.py
│   └── upload_estabelecimentos_s3.py
│
├── tests/
│   └── unique_chave_estabelecimento.sql
│
├── baixar_estabelecimentos.py
├── dbt_project.yml
├── .gitignore
└── README.md
```

## Camadas de dados

### Bronze

Armazenamento dos dados originais no Snowflake, preservando os registros de origem.

Principais tabelas:
- EMPRESAS_BRONZE
- ESTABELECIMENTOS_BRONZE

Também são utilizadas tabelas de referência para natureza jurídica e porte empresarial.

### Staging

Camada responsável pela limpeza e padronização dos dados.

Transformações realizadas:
- Padronização de textos.
- Tratamento de valores vazios.
- Conversão de datas.
- Conversão de capital social para formato numérico.
- Organização dos campos cadastrais.

### Marts

Camada analítica composta por 10 modelos SQL materializados como tabelas no Snowflake.

Os modelos permitem investigar características empresariais, distribuição geográfica, natureza jurídica, porte e capital social.

## Qualidade dos dados

O projeto utiliza testes nativos do dbt e um teste SQL personalizado.

Validações implementadas:
- Campos obrigatórios.
- Unicidade de identificadores.
- Integridade referencial entre empresas, naturezas e portes.
- Valores permitidos para identificação de matriz e filial.
- Unicidade da chave composta dos estabelecimentos.

## Resultado da execução

Última execução validada:

```text
dbt build

PASS = 31
WARN = 0
ERROR = 0
SKIP = 0
TOTAL = 31
```

Foram executados com sucesso:
- 5 modelos de Staging.
- 10 modelos de Marts.
- 16 testes de qualidade.

## Como executar

### 1. Configurar o ambiente

Criar e instalar o ambiente Python e as dependências necessárias para o projeto.

### 2. Configurar o Snowflake

Configurar o perfil dbt em:

`~/.dbt/profiles.yml`

O perfil utilizado pelo projeto é `cnpj_pipeline`.

A senha deve ser fornecida por variável de ambiente, sem armazená-la no repositório.

### 3. Executar o dbt

```powershell
.\.venv\Scripts\dbt.exe debug
```

```powershell
.\.venv\Scripts\dbt.exe build
```

### 4. Gerar a documentação

```powershell
.\.venv\Scripts\dbt.exe docs generate
```

## Considerações finais

Este projeto demonstra a construção de um pipeline de Engenharia de Dados utilizando ferramentas de armazenamento em nuvem, processamento de dados, modelagem analítica e validação de qualidade.

O objetivo é transformar dados públicos brutos em informações estruturadas e confiáveis para análises empresariais.