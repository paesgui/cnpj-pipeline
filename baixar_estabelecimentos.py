
import os
import re
import zipfile
import requests
import xml.etree.ElementTree as ET

from pathlib import Path
from urllib.parse import unquote, urljoin

# Configurações
TOKEN = "INFORME O TOKEN"
COMPETENCIA = "2026-10"

BASE_URL = "https://arquivos.receitafederal.gov.br"
URL_PASTA = f"{BASE_URL}/public.php/webdav/{COMPETENCIA}/"

PASTA_DATA = Path("data")
PASTA_ZIPS = PASTA_DATA / "estabelecimentos" / "zips"
PASTA_CSV = PASTA_DATA / "estabelecimentos" / "csv"

PASTA_ZIPS.mkdir(parents=True, exist_ok=True)
PASTA_CSV.mkdir(parents=True, exist_ok=True)

sessao = requests.Session()
sessao.auth = (TOKEN, "")


def listar_arquivos():
    print("Consultando arquivos na Receita Federal...")

    resposta = sessao.request(
        "PROPFIND",
        URL_PASTA,
        headers={"Depth": "1"},
        timeout=120
    )
    resposta.raise_for_status()

    raiz = ET.fromstring(resposta.content)
    arquivos = []

    for item in raiz.findall("{DAV:}response"):
        href = item.findtext("{DAV:}href", "")
        nome = unquote(href.rstrip("/").split("/")[-1])

        if re.fullmatch(r"Estabelecimentos\d+\.zip", nome, re.I):
            arquivos.append(nome)

    arquivos.sort(key=lambda nome: int(re.search(r"\d+", nome).group()))

    if not arquivos:
        raise RuntimeError("Nenhum arquivo de estabelecimentos encontrado.")

    print(f"{len(arquivos)} arquivos encontrados:")
    for nome in arquivos:
        print(" -", nome)

    return arquivos


def baixar_arquivo(nome):
    destino = PASTA_ZIPS / nome
    url = urljoin(URL_PASTA, nome)

    if destino.exists() and destino.stat().st_size > 0:
        print(f"\nArquivo já baixado: {nome}")
        return destino

    temporario = destino.with_suffix(".zip.part")

    print(f"\nBaixando: {nome}")

    with sessao.get(url, stream=True, timeout=(30, 300)) as resposta:
        resposta.raise_for_status()

        total = int(resposta.headers.get("content-length", 0))
        baixado = 0

        with open(temporario, "wb") as arquivo:
            for bloco in resposta.iter_content(chunk_size=8 * 1024 * 1024):
                if bloco:
                    arquivo.write(bloco)
                    baixado += len(bloco)

                    if total:
                        percentual = baixado * 100 / total
                        print(
                            f"\rProgresso: {percentual:.1f}%",
                            end="",
                            flush=True
                        )

    if total and temporario.stat().st_size != total:
        raise RuntimeError(f"Download incompleto: {nome}")

    os.replace(temporario, destino)
    print(f"\nDownload concluído: {nome}")

    return destino


def extrair_arquivo(caminho_zip):
    print(f"\nExtraindo: {caminho_zip.name}")

    with zipfile.ZipFile(caminho_zip, "r") as pacote:
        for membro in pacote.infolist():
            destino = (PASTA_CSV / membro.filename).resolve()

            if not destino.is_relative_to(PASTA_CSV.resolve()):
                raise RuntimeError("Arquivo ZIP contém caminho inválido.")

        pacote.extractall(PASTA_CSV)

    print("Extração concluída.")


def main():
    arquivos = listar_arquivos()

    for nome in arquivos:
        caminho_zip = baixar_arquivo(nome)
        extrair_arquivo(caminho_zip)

    print("\nPROCESSAMENTO CONCLUÍDO!")
    print("ZIPs:", PASTA_ZIPS.resolve())
    print("CSVs:", PASTA_CSV.resolve())


if __name__ == "__main__":
    main()
