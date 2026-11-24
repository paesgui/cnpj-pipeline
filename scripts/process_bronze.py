import zipfile
import pandas as pd

ARQUIVO = "data/Empresas0.zip"

COLUNAS = [
    "cnpj_basico",
    "razao_social",
    "natureza_juridica",
    "qualificacao_responsavel",
    "capital_social",
    "porte_empresa",
    "ente_federativo_responsavel"
]

with zipfile.ZipFile(ARQUIVO) as z:
    nome = z.namelist()[0]

    with z.open(nome) as arquivo:
        df = pd.read_csv(
            arquivo,
            sep=";",
            header=None,
            names=COLUNAS,
            dtype=str,
            encoding="latin1"
        )

df.to_csv(
    "data/empresas_bronze.csv",
    index=False,
    encoding="utf-8"
)

print("Processamento concluído!")
print("Linhas:", len(df))
print(df.head())