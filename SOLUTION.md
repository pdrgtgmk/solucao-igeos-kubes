# Solução do Desafio DevOps / Plataforma

Este documento detalha a arquitetura, as decisões técnicas, os problemas encontrados durante a conteinerização e as estratégias adotadas para garantir a resiliência e a persistência do ambiente.

---

## 1. Visão Geral da Arquitetura

O ambiente foi estruturado utilizando Docker Compose para orquestrar 8 serviços em uma rede em ponte privada e isolada (igeos-network):

* Proxy / Roteamento (nginx): Atua como reverse proxy na porta 80, distribuindo chamadas para as interfaces e roteando endpoints sob /api/.
* Interfaces Gráficas (producer-web e consumer-web): SPAs React servidas via Nginx.
* APIs de Back-end (producer-api e consumer-api): Serviços FastAPI em Python 3.12 gerenciados via uv.
* Mensageria (kafka + zookeeper): Cluster Confluent 7.5.0 para ingestão de eventos assíncronos.
* Persistência Relacional (postgres): Banco PostgreSQL 15 Alpine para histórico de dados.

---

## 2. Desafios Enfrentados e Soluções Adotadas

### 2.1. Incompatibilidade com Versão Antiga do Python nos Containers Base
* Problema: O código-fonte das aplicações e as dependências travadas nas lockfiles exigiam recursos e sintaxes modernas do ecossistema Python (gerenciadas via uv), enquanto a versão do Python definida originalmente na imagem base de construção/runtime se encontrava defasada. Isso gerava falhas de compilação de bibliotecas (C-extensions) e incompatibilidade na resolução das dependências.
* Solução: Padronizou-se a imagem base de todos os microserviços Python para python:3.12-slim. Adicionou-se o suporte oficial ao gerenciador uv nos Dockerfiles. O comando de instalação foi ajustado para uv pip install --system --frozen -r pyproject.toml, garantindo uma instalação leve, reproduzível e alinhada ao uv.lock original.

---

### 2.2. Falha de Conexão Contínua com o Kafka no producer-api
* Problema: Ao subir o container da producer-api, a aplicação entrava em loop de reinicialização (crash loop) disparando o erro RuntimeError: Kafka indisponível após 5 tentativas. O log indicava tentativas de conexão em localhost:9092, ignorando as variáveis comuns de ambiente como KAFKA_HOST.
* Causa Raiz & Análise de Contrato: Ao inspecionar a classe Settings (Pydantic Settings v2) no código-fonte da API, identificou-se que o atributo esperava estritamente o alias validation_alias="KAFKA_BROKERS". Como essa variável não estava mapeada no Compose, a aplicação usava o valor padrão ["localhost:9092"], inviável dentro da rede do Docker.
* Solução: Em conformidade com as diretrizes do desafio (adequar a infraestrutura ao contrato de código), injetou-se explicitamente a variável KAFKA_BROKERS: "kafka:9092" no docker-compose.yml, permitindo a resolução imediata do hostname do serviço via DNS interno do Docker.

---

### 2.3. Tabela Inexistente no Consumidor (UndefinedTableError)
* Problema: A consumer-api falhava durante a inicialização porque consultava as mensagens no PostgreSQL antes que as tabelas tivessem sido criadas.
* Solução: O script idempotente prepare.py (fornecido no repositório) foi encadeado diretamente no comando de execução do Dockerfile da consumer-api `CMD ["sh", "-c", "python prepare.py && uvicorn main:app --host 0.0.0.0 --port 8000"]`

Dessa forma, a aplicação aplica o schema.sql antes do Uvicorn subir, garantindo resiliência na criação do schema sem apagar dados pré-existentes.

---

### 2.4. Erro de Conflito de ID do Cluster Kafka (InconsistentClusterIdException)
* Problema: Ao executar docker compose down e subir novamente o ambiente mantendo volumes, o Kafka falhava na inicialização acusando divergência entre o Cluster ID da memória e o gravado no arquivo meta.properties do volume kafka_data.
* Solução: O Zookeeper gerava um novo ID dinâmico a cada reinício por falta de persistência de seu próprio estado. A solução definitiva consistiu em adicionar volumes persistentes para o Zookeeper (zookeeper_data e zookeeper_log) e mapear os volumes explicitamente no docker-compose.yml, permitindo que o estado do Zookeeper e do Kafka fiquem em sincronia perpétua sem requerer a flag -v no down.

---

### 2.5. Estratégia de Disaster Recovery e Backup Automatizado
* **Decisão Arquitetural:** Implementou-se um sidecar container (`postgres-backup`) focado no backup diário do PostgreSQL.
* **Embasamento Teórico:** A política de retenção de 7 dias baseia-se na camada *Son* do modelo clássico **Grandfather-Father-Son (GFS)** e no framework **SRE (Site Reliability Engineering)**, garantindo um RPO de 24 horas e uma janela de detecção contra corrupção lógica de dados.
* **Resiliência nos Scripts:** Uso de `#!/bin/bash` com as flags `set -euo pipefail` para garantir interrompimento imediato no caso de falhas em pipes de compressão (`pg_dump | gzip`), evitando backups vazios.

---

## 3. Guia de Execução e Endpoints

### 3.1. Subindo o Ambiente
Execute na raiz do repositório: `docker compose up -d --build

### 3.2. Endpoints Mapeados (Via Nginx na porta 80)
* Interface do Produtor: http://localhost/producer/
* Interface do Consumidor: http://localhost/consumer/
* API Produtora (Healthcheck): http://localhost/api/producer/health/live
* API Consumidora (Healthcheck): http://localhost/api/consumer/health/ready

---

## 4. Validação de Resiliência e Persistência

### Teste 1: Consumo Retroativo (Kafka Unbound)
1. Interrompa o container consumidor: docker compose stop consumer-api
2. Envie novas mensagens acessando a interface do produtor (/producer/).
3. Reative o consumidor: docker compose start consumer-api
4. Acesse /consumer/. As mensagens acumuladas no broker serão processadas em lote, evidenciadas pelo carimbo de data/hora no campo processed_at.

### Teste 2: Persistência de Dados no PostgreSQL
1. Encerrar todos os containers SEM remoção de volumes: docker compose down
2. Encerrar todos os containers COM remoção de volumes: docker compose down -v
3. Subir novamente: docker compose up -d
4. Consultar as mensagens salvas via banco:`docker compose exec postgres psql -U igeos_user -d igeos_db -c "SELECT * FROM messages;"`