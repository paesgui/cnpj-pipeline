import zipfile

ZIP = "data/Empresas0.zip"
DESTINO = "data/Empresas0.csv"

print("Extraindo arquivo...", flush=True)

with zipfile.ZipFile(ZIP) as z:
    nome = z.namelist()[0]
    with z.open(nome) as origem, open(DESTINO, "wb") as destino:
        destino.write(origem.read())

print("Extração concluída!", flush=True)