import requests
import boto3
from pathlib import Path

URL = (
    "https://arquivos.receitafederal.gov.br/"
    "public.php/dav/files/YggdBLfdninEJX9/"
    "2026-10/Empresas0.zip"
)

BUCKET = "cnpj-data-lake"
S3_KEY = "landing/raw/2026-10/Empresas0.zip"

def executar():
    pasta = Path("data")
    pasta.mkdir(exist_ok=True)
    arquivo = pasta / "Empresas0.zip"

    print("Baixando arquivo...")

    with requests.get(URL, stream=True, timeout=120) as resposta:
        resposta.raise_for_status()

        with open(arquivo, "wb") as destino:
            for bloco in resposta.iter_content(chunk_size=1024 * 1024):
                if bloco:
                    destino.write(bloco)

    print("Download concluído.")
    print("Enviando para o S3...")

    s3 = boto3.client("s3", region_name="us-east-1")
    s3.upload_file(str(arquivo), BUCKET, S3_KEY)

    print(f"Upload concluído: s3://{BUCKET}/{S3_KEY}")

if __name__ == "__main__":
    executar()