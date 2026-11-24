
import boto3
from pathlib import Path
from botocore.exceptions import ClientError
from boto3.s3.transfer import TransferConfig

BUCKET = "cnpj-data-lake"
PASTA = Path("data/estabelecimentos/csv")
PREFIXO = "landing/raw/2026-10/estabelecimentos/"

CONFIG = TransferConfig(
    multipart_threshold=64 * 1024 * 1024,
    multipart_chunksize=64 * 1024 * 1024,
    max_concurrency=3,
    use_threads=True
)

def executar():
    arquivos = sorted(
        PASTA.glob("K3241.K03200Y*.D61010.ESTABELE")
    )

    if len(arquivos) != 10:
        raise RuntimeError(
            f"Esperados 10 arquivos, encontrados {len(arquivos)}"
        )

    s3 = boto3.client("s3", region_name="us-east-1")

    for arquivo in arquivos:
        chave = PREFIXO + arquivo.name
        tamanho = arquivo.stat().st_size

        print(f"\nArquivo: {arquivo.name}")
        print(f"Tamanho: {tamanho:,} bytes")

        try:
            remoto = s3.head_object(Bucket=BUCKET, Key=chave)

            if remoto["ContentLength"] == tamanho:
                print("Já existe no S3 com o mesmo tamanho. Pulando.")
                continue

        except ClientError as erro:
            codigo = erro.response["Error"]["Code"]
            if codigo not in ("404", "NoSuchKey", "NotFound"):
                raise

        print("Enviando para o S3...")

        s3.upload_file(
            str(arquivo),
            BUCKET,
            chave,
            Config=CONFIG,
            ExtraArgs={"ContentType": "text/csv"}
        )

        print(f"Upload concluído: s3://{BUCKET}/{chave}")

    print("\nProcesso finalizado!")

if __name__ == "__main__":
    executar()
