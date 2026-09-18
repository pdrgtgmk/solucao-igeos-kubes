# Solução do Desafio DevOps / Plataforma

Aplicação em microsserviços para ingestão, processamento e exibição de mensagens assíncronas utilizando **FastAPI**, **Apache Kafka**, **PostgreSQL** e **Nginx** orquestrados via **Docker Compose**.

---

##  Como Executar

### Pré-requisitos
* Docker instalado
* Docker Compose v2+

### Subindo o ambiente completo
Na raiz do repositório, execute:

`docker compose up -d --build`
Aguarde alguns segundos até que os serviços de infraestrutura (postgres, zookeeper e kafka) completem a inicialização e fiquem em estado de saúde (healthy).

 Endpoints Mapeados (Nginx - Porta 80)
Interface do Produtor: http://localhost/producer/

Interface do Consumidor: http://localhost/consumer/

API Produtora (Healthcheck): http://localhost/api/producer/health/live

API Consumidora (Healthcheck): http://localhost/api/consumer/health/ready

Tecnologias Utilizadas:
Proxy / Entrada: Nginx (Reverse Proxy)

Back-end: Python 3.12, FastAPI, Uvicorn, uv (Package Manager)

Front-end: React (interfaces web servidas via Nginx)

Mensageria: Apache Kafka + Zookeeper (Confluent 7.5.0)

Banco de Dados: PostgreSQL 15 Alpine

 Documentação da Solução e Arquitetura

Consulte o arquivo de documentação técnica em SOLUTION.md.
