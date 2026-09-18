FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Instala a ferramenta uv
RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock ./

# Instala as dependências exatas do uv.lock no Python global do container
RUN uv pip install --system --no-cache --frozen -r pyproject.toml || uv pip install --system --no-cache .

COPY . .

EXPOSE 8000

# Executa o prepare.py para criar a tabela no banco e sobe o servidor Uvicorn
CMD ["sh", "-c", "python prepare.py && uvicorn main:app --host 0.0.0.0 --port 8000"]