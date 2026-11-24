# RELATÓRIO TÉCNICO — PROJETO PIPELINE DE DADOS CNPJ

**Projeto:** Pipeline de Dados CNPJ  
**Tecnologias:** Python, AWS S3, Snowflake, SQL, dbt e Git/GitHub  
**Fonte de dados:** Cadastro Nacional da Pessoa Jurídica — Receita Federal

---

## 1. Apresentação do projeto

O projeto tem como objetivo construir um pipeline de engenharia de dados para processar, organizar e analisar informações públicas do Cadastro Nacional da Pessoa Jurídica (CNPJ).

A solução utiliza serviços de armazenamento em nuvem, processamento e transformação de dados, permitindo transformar arquivos brutos em informações estruturadas para análises empresariais.

O trabalho foi desenvolvido em etapas, desde a ingestão dos arquivos até a criação de modelos analíticos utilizando SQL e dbt.

## 2. Arquitetura desenvolvida

O fluxo de dados foi estruturado da seguinte maneira:

1. **Origem:** arquivos públicos disponibilizados pela Receita Federal.
2. **Armazenamento:** AWS S3, utilizado como Data Lake.
3. **Ingestão:** Snowflake acessa os arquivos armazenados no S3.
4. **Bronze:** armazenamento inicial dos dados recebidos.
5. **Staging:** modelos dbt responsáveis pela padronização e preparação dos dados.
6. **Marts:** modelos analíticos utilizados para responder às perguntas de negócio.

## 3. Análises desenvolvidas

Foram construídos dez modelos analíticos principais, organizados por finalidade.

### 3.1 Perfil empresarial

**Modelo: `fct_empresas_por_natureza`**

Perguntas respondidas:
- Quantas empresas existem por natureza jurídica?
- Quais naturezas jurídicas concentram mais empresas?
- Qual é o capital social médio e total por natureza jurídica?

**Modelo: `fct_empresas_por_porte`**

Perguntas respondidas:
- Quantas empresas existem por porte?
- Qual é a distribuição das empresas entre ME, EPP e demais empresas?
- Qual é o capital social médio e total por porte?

**Modelo: `fct_empresas_por_natureza_porte`**

Perguntas respondidas:
- Como as empresas se distribuem considerando natureza jurídica e porte?
- Quais combinações concentram mais empresas?
- Como o capital social se distribui entre esses grupos?

### 3.2 Distribuição geográfica

**Modelo: `fct_estabelecimentos_por_uf`**

Perguntas respondidas:
- Quantos estabelecimentos existem por unidade da Federação?
- Quais estados concentram mais estabelecimentos?
- Como ocorre a distribuição geográfica dos estabelecimentos?

### 3.3 Análise de capital social

**Modelo: `fct_estatisticas_capital_social`**

Perguntas respondidas:
- Qual é o capital social médio e mediano?
- Como os indicadores variam por natureza jurídica e porte?
- Qual é a diferença entre média e mediana?

**Modelo: `fct_distribuicao_capital_social`**

Perguntas respondidas:
- Quantas empresas existem em cada faixa de capital social?
- Qual é a participação percentual de cada faixa?
- Como a distribuição varia conforme o porte empresarial?

**Modelo: `fct_dispersao_capital_social`**

Perguntas respondidas:
- Como os valores de capital social estão dispersos?
- Quais grupos apresentam maior amplitude interquartil?
- Qual é a diferença entre média e mediana em cada grupo?
- Como se comportam os quartis e o percentil 90?

**Modelo: `fct_capital_social_zerado`**

Perguntas respondidas:
- Quantas empresas possuem capital social zerado?
- Quantas possuem capital social não informado?
- Qual é o percentual de capital zerado?
- Como esses casos se distribuem por natureza jurídica e porte?

### 3.4 Concentração e qualidade dos dados

**Modelo: `fct_concentracao_natureza`**

Perguntas respondidas:
- Quais naturezas jurídicas concentram mais empresas?
- Qual é a participação percentual de cada natureza?
- Qual é a participação acumulada das principais naturezas?

**Modelo: `fct_auditoria_capital_social`**

Perguntas respondidas:
- Existem valores de capital social elevados?
- Existem valores negativos ou nulos?
- Quantas empresas apresentam o valor extremo observado de R$ 999.999.999.999?
- Como os valores extremos se distribuem por natureza jurídica e porte?

## 4. Investigações complementares

Além dos modelos analíticos, foram realizadas consultas exploratórias para aprofundar a análise do capital social.

Uma investigação importante foi a identificação do valor de R$ 999.999.999.999, que apareceu na base e motivou uma análise específica.

Foram realizadas comparações entre:
- Média original do capital social.
- Média sem valores acima de R$ 100 milhões.
- Média sem o valor extremo observado.
- Mediana original e mediana sem valores extremos.
- Participação dos valores extremos no capital social total.

Essas investigações ajudam a compreender como valores muito elevados podem influenciar indicadores estatísticos.

**Observação:** a identificação de um valor extremo não significa automaticamente que o registro esteja incorreto. É necessário investigar sua origem e contexto.

## 5. Qualidade e validação dos dados

O projeto também utiliza testes de qualidade no dbt para verificar a integridade dos dados transformados.

Entre as verificações desenvolvidas estão:
- Campos obrigatórios não nulos.
- Unicidade de identificadores.
- Integridade referencial entre modelos.
- Validação de valores aceitos.
- Verificação de duplicidade da chave composta de estabelecimento.

A chave utilizada para identificar um estabelecimento é composta por:

`CNPJ_BASICO + CNPJ_ORDEM + CNPJ_DV`

Os testes permitem identificar problemas antes que os dados sejam utilizados nas análises.

## 6. Resultados alcançados

O projeto já possui uma estrutura funcional de ingestão, armazenamento e transformação de dados.

Entre as entregas realizadas estão:

- Infraestrutura de acesso entre Snowflake e AWS S3.
- Tabelas Bronze para empresas e estabelecimentos.
- Tabelas de referência para natureza jurídica e porte.
- Modelos de staging desenvolvidos com dbt.
- Dez modelos analíticos principais.
- Testes automatizados de qualidade.
- Scripts SQL organizados e versionados no GitHub.

O processo de construção dos modelos também permitiu investigar características da base, especialmente a distribuição empresarial e o comportamento estatístico do capital social.

## 7. Próxima evolução: modelo dimensional

A próxima etapa prevista é complementar os modelos analíticos atuais com uma estrutura dimensional.

A proposta é organizar os dados em:

**Dimensões:**
- `dim_empresa`
- `dim_natureza_juridica`
- `dim_porte`

**Tabela fato:**
- `fct_estabelecimentos`

Essa estrutura permitirá realizar análises mais flexíveis, cruzando informações de empresas, natureza jurídica, porte e estabelecimentos.

Os dez modelos analíticos atuais serão preservados. O modelo dimensional será desenvolvido paralelamente, sem substituir as análises existentes.

## 8. Considerações finais

O projeto CNPJ demonstra a aplicação prática de conceitos de engenharia de dados em um conjunto de dados público e de grande volume.

A solução percorre diferentes etapas de um pipeline moderno: ingestão, armazenamento, transformação, modelagem, validação e disponibilização de dados analíticos.

As análises desenvolvidas permitem investigar o perfil das empresas brasileiras, sua distribuição por natureza jurídica e porte, sua presença geográfica e o comportamento do capital social.

Como evolução, a implementação do modelo dimensional ampliará a capacidade analítica do projeto e fortalecerá sua estrutura como solução de engenharia de dados para portfólio profissional.

---
