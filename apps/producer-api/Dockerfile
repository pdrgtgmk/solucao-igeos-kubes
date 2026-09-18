FROM python:3.12-slim

WORKDIR /app

# Desabilita geração de bytecode .pyc e força logs em tempo real
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instala dependências de build essenciais e atualiza o pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copia o pyproject.toml e arquivos de configuração primeiro
COPY pyproject.toml README.md* ./

# Instala as dependências especificadas no pyproject.toml
RUN pip install --no-cache-dir .

# Copia todo o restante do código da aplicação
COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]