# Projeto de Infraestrutura DevOps - APIs Contratos & Flash Sales

Este repositório contém a infraestrutura containerizada, automação e documentação para os microsserviços **Contracts API** e **Flash Sales API**, desenvolvidos em Node.js com TypeScript, PostgreSQL e Redis.

---

## 📐 Justificativa de Arquitetura

A arquitetura de infraestrutura foi projetada seguindo as melhores práticas de **DevOps**, com foco nos seguintes pilares:

### 1. Escalabilidade e Isolamento
* **Containers (Docker & Docker Compose):** As aplicações, banco de dados (PostgreSQL) e cache (Redis) são executados de forma isolada em containers independentes. Isso garante paridade entre ambientes de desenvolvimento e produção.
* **Desacoplamento de Serviços:** A `Contracts API` e a `Flash Sales API` rodam como microsserviços independentes, permitindo escalabilidade horizontal individualizada (por exemplo, escalar mais instâncias da `Flash Sales` durante picos de vendas).

### 2. Alta Performance e Resiliência
* **Camada de Caching (Redis):** Utilizado para otimização de consultas e controle concorrente (scripts Lua na `Flash Sales API` para evitar *race conditions* no estoque de ingressos).
* **Persistência de Dados (PostgreSQL):** Banco de dados relacional robusto com volumes persistentes mapeados via Docker.

### 3. Observabilidade e Métricas
* **Prometheus Metrics:** As APIs possuem suporte nativo à exportação de métricas via `prom-client` na rota `/metrics`, permitindo monitoramento de latência, taxa de erros e throughput em tempo real.

---

## 🛠️ Estrutura do Repositório

```text
.
├── Contratos/             # Código fonte da Contracts API
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── Flash Sales/           # Código fonte da Flash Sales API
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── .github/
│   └── workflows/
│       └── ci-cd.yml      # Pipeline de Integração e Entrega Contínua (CI/CD)
├── docker-compose.yml     # Orquestração local de serviços
├── init-db.sql            # Script de inicialização dos bancos PostgreSQL
└── README.md              # Documentação oficial da infraestrutura
```

---

## 🚀 Passo a Passo de Provisionamento e Execução

### Pré-requisitos
* [Docker](https://www.docker.com/) instalado e em execução.
* [Docker Compose](https://docs.docker.com/compose/) v2+.
* [Git](https://git-scm.com/).

### 1. Clonar o Repositório
```bash
git clone <URL_DO_REPOSITORIO>
cd Atividade
```

### 2. Provisionar o Ambiente com Docker Compose
Para compilar as imagens e subir todos os containers (PostgreSQL, Redis, Contracts API e Flash Sales API), execute:

```bash
docker-compose up --build -d
```

### 3. Verificar o Status dos Containers
```bash
docker-compose ps
```

---

## 🧪 Como Testar as APIs

Após subir a infraestrutura, os serviços estarão acessíveis nas seguintes portas:

| Serviço | URL Base | Rota de Health / Métricas |
| :--- | :--- | :--- |
| **Contracts API** | `http://localhost:3001` | `http://localhost:3001/metrics` |
| **Flash Sales API** | `http://localhost:3002` | `http://localhost:3002/metrics` |
| **PostgreSQL** | `localhost:5432` | — |
| **Redis** | `localhost:6379` | — |

---

### Exemplo 1: Testando a `Contracts API` (Porta 3001)

#### Criar um novo contrato (`POST /contracts`):
```bash
curl -X POST http://localhost:3001/contracts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Contrato de Prestação de Serviços",
    "userId": "user-123",
    "description": "Desenvolvimento de Infraestrutura DevOps",
    "value": 15000
  }'
```

---

### Exemplo 2: Testando a `Flash Sales API` (Porta 3002)

#### Realizar Checkout de Ingresso (`POST /checkout`):
```bash
curl -X POST http://localhost:3002/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "event-456",
    "userId": "user-789",
    "quantity": 2
  }'
```

#### Simular Teste de Carga / Relatório Massivo (`POST /export`):
```bash
curl -X POST http://localhost:3002/export \
  -H "Content-Type: application/json" \
  -d '{
    "recordsCount": 50000
  }'
```

---

## 🔄 Pipeline de CI/CD (GitHub Actions)

O arquivo `.github/workflows/ci-cd.yml` realiza automaticamente a validação da aplicação em cada `push` ou `pull_request` na branch `main`:
1. Build das imagens Docker para verificar erros de compilação/dependências.
2. Testes de inicialização dos microsserviços.
