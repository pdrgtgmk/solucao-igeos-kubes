#!/bin/bash
set -euo pipefail

BACKUP_FILE="${1:-}"

if [[ -z "${BACKUP_FILE}" ]]; then
  echo "Erro: Caminho do arquivo de backup não informado."
  echo "Uso: $0 /backups/nome_do_arquivo.sql.gz"
  exit 1
fi

if [[ ! -f "${BACKUP_FILE}" ]]; then
  echo "Erro: O arquivo de backup '${BACKUP_FILE}' não foi encontrado."
  exit 1
fi

echo "[$(date)] Dropando e recriando as tabelas para uma restauração limpa..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "DROP TABLE IF EXISTS messages CASCADE;"

echo "[$(date)] Restaurando o banco de dados a partir de: ${BACKUP_FILE}..."
gunzip -c "${BACKUP_FILE}" | PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"

echo "[$(date)] Restauração concluída com sucesso!"