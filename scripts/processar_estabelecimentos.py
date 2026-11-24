
import csv
from pathlib import Path
import pandas as pd

PASTA = Path("data/estabelecimentos/csv")
SAIDA = Path("data/estabelecimentos/estabelecimentos_bronze.csv")

COLUNAS = [
    "cnpj_basico",
    "cnpj_ordem",
    "cnpj_dv",
    "identificador_matriz_filial",
    "nome_fantasia",
    "situacao_cadastral",
    "data_situacao_cadastral",
    "motivo_situacao_cadastral",
    "nome_cidade_exterior",
    "pais",
    "data_inicio_atividade",
    "cnae_fiscal_principal",
    "cnae_fiscal_secundaria",
    "tipo_logradouro",
    "logradouro",
    "numero",
    "complemento",
    "bairro",
    "cep",
    "uf",
    "codigo_municipio",
    "ddd1",
    "telefone1",
    "ddd2",
    "telefone2",
    "ddd_fax",
    "fax",
    "correio_eletronico",
    "situacao_especial",
    "data_situacao_especial"
]

arquivos = sorted(PASTA.iterdir())

SAIDA.parent.mkdir(parents=True, exist_ok=True)

total = 0

with open(SAIDA, "w", encoding="utf-8", newline="") as destino:
    escritor = csv.writer(destino, delimiter=";")
    escritor.writerow(COLUNAS)

    for arquivo in arquivos:
        if not arquivo.is_file():
            continue

        print(f"Processando: {arquivo.name}")

        with open(
            arquivo, "r", encoding="latin-1", newline=""
        ) as origem:
            leitor = csv.reader(origem, delimiter=";")

            for linha in leitor:
                if len(linha) != 30:
                    raise ValueError(
                        f"Linha inválida em {arquivo.name}: {len(linha)} colunas"
                    )

                escritor.writerow(linha)
                total += 1

        print(f"Registros acumulados: {total:,}")

print("\nPROCESSAMENTO CONCLUÍDO")
print(f"Total de registros: {total:,}")
print(f"Arquivo: {SAIDA}")
