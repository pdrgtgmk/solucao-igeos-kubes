#!/bin/bash
set -euo pipefail

# Configurações do arquivo de backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
BACKUP_FILE="${BACKUP_DIR}/igeos_db_${TIMESTAMP}.sql.gz"

echo "[$(date)] Iniciando backup do banco de dados igeos_db..."

# Executa o dump compactado via gzip com tratamento estrito de pipe
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "${BACKUP_FILE}"

echo "[$(date)] Backup concluído com sucesso: ${BACKUP_FILE}"

# Retenção: Remove backups com mais de 7 dias (Padrão GFS - Son)
echo "[$(date)] Limpando backups antigos com mais de 7 dias..."
find "${BACKUP_DIR}" -type f -name "*.sql.gz" -mtime +7 -exec rm -f {} \;

echo "[$(date)] Rotina de backup finalizada."