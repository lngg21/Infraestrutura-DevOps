# 🚀 Infraestrutura DevOps de Alta Performance

Este projeto implementa a infraestrutura completa de automação, provisionamento, orquestração e observabilidade para a sustentação de dois microsserviços: **Contracts API** e **Flash Sales API**.

A solução foi desenvolvida seguindo rigorosamente os padrões modernos de Engenharia DevOps discutidos em aula, contemplando:
- **Containerização:** Docker e Dockerfiles Multi-stage com execução não-root.
- **Infraestrutura como Código (IaC):** Terraform com emulação AWS via LocalStack (Bucket S3 e Fila SQS).
- **Orquestração de Containers:** Kubernetes (Deployments, Services, ConfigMaps, Secrets e Ingress).
- **Observabilidade:** Monitoramento e coleta de métricas em tempo real com Prometheus e Grafana.
- **Automação Contínua (CI/CD):** Pipeline GitHub Actions com validação de código, build de imagens, validação de Terraform e manifestos K8s.

---

## 📐 1. Arquitetura da Solução & Justificativas Técnicas

A arquitetura foi desenhada para garantir **Escalabilidade**, **Segurança**, **Confiabilidade** e **Reprodutibilidade**, conforme requerido na proposta da atividade:

```text
                                 ┌─────────────────────────────────────────┐
                                 │       GitHub Actions CI/CD Pipeline     │
                                 │ (Lint, Test, Docker Build, IaC & K8s)   │
                                 └────────────────────┬────────────────────┘
                                                      │ Deploy / Provisionamento
                                                      ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                                NUVEM LOCAL & INFRAESTRUTURA                                     │
 │                                                                                                 │
 │   ┌──────────────────────┐          ┌───────────────────────────────────────────────────────┐   │
 │   │   Terraform (IaC)    │ ───────► │               LocalStack (AWS Community)              │   │
 │   │  (main.tf / S3 / SQS)│          │  • S3: devops-activity-artifacts-dev (Relatórios)     │   │
 │   └──────────────────────┘          │  • SQS: flash-sales-orders-queue (Mensageria Pedidos) │   │
 │                                     └───────────────────────────────────────────────────────┘   │
 └─────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                      │
                                                      ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                                   CLUSTER KUBERNETES / DOCKER                                   │
 │                                                                                                 │
 │                           Ingress Controller (devops.local / Ingress)                           │
 │                           ├── /contracts   ──► Contracts API Service (Porta 3001)               │
 │                           └── /flash-sales ──► Flash Sales API Service (Porta 3002)             │
 │                                                                                                 │
 │   ┌──────────────────────────────┐                ┌──────────────────────────────┐              │
 │   │        Contracts API         │                │       Flash Sales API        │              │
 │   │      (Porta 3001 - 2 Pods)   │                │     (Porta 3002 - 2 Pods)    │              │
 │   └──────────────┬───────────────┘                └──────────────┬───────────────┘              │
 │                  │                                               │                              │
 │                  ▼                                               ▼                              │
 │   ┌──────────────────────────────────────────────────────────────────────────────┐              │
 │   │                        Camada de Armazenamento & Cache                       │              │
 │   │   • PostgreSQL (5432): bancos 'contracts_db' e 'flash_sales' (init-db.sql)   │              │
 │   │   • Redis (6379): cache de alta velocidade e controle de ingressos           │              │
 │   └──────────────────────────────────────────────────────────────────────────────┘              │
 └─────────────────────────────────────────────────────────────────────────────────────────────────┘
                                    │                             │
                                    ▼                             ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                               STACK DE OBSERVABILIDADE & MÉTRICAS                               │
 │                                                                                                 │
 │   ┌───────────────────────────┐                         ┌───────────────────────────┐           │
 │   │        Prometheus         │ ◄────────────────────── │          Grafana          │           │
 │   │   (Scrape em /metrics)    │   Dashboards e Painéis  │ (Porta 3000, admin/admin) │           │
 │   └───────────────────────────┘                         └───────────────────────────┘           │
 └─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Justificativas das Escolhas Arquiteturais

| Pilar | Abordagem Implementada | Justificativa DevOps |
| :--- | :--- | :--- |
| **Escalabilidade** | • Microsserviços independentes e stateless<br>• Réplicas gerenciadas no Kubernetes<br>• Cache em memória com Redis<br>• Fila assíncrona SQS via LocalStack | Permite que o tráfego crítico da `Flash Sales API` (vendas relâmpago e picos de acessos) escale horizontalmente de forma isolada, sem impactar a `Contracts API`. O Redis alivia o banco de dados evitando concorrência excessiva de leitura/escrita. |
| **Segurança** | • Docker Multi-stage Builds (`node:20-alpine`)<br>• Execução não-root (`USER appuser`)<br>• K8s Secrets e ConfigMaps desacoplados<br>• Ambiente isolado com LocalStack | Reduz a superfície de ataque minimizando dependências no container final. A execução em modo não-root previne escalonamento de privilégios. Credenciais sensíveis nunca ficam hardcoded no código nem em imagens. |
| **Confiabilidade & Resiliência** | • *Self-Healing* do Kubernetes (reinício automático de pods)<br>• Scripts de inicialização idempotentes (`init-db.sql`)<br>• Healthchecks no Compose e Probes no K8s | O cluster garante que instâncias que apresentem travamentos (como estouro de memória no event loop) sejam substituídas automaticamente com zero indisponibilidade ao usuário final. |
| **Observabilidade** | • Coleta com Prometheus (5s interval)<br>• Painéis em Grafana (`localhost:3000`)<br>• Instrumentação nativa com `prom-client` | Visibilidade total em tempo real de latência HTTP, contagem de requisições e gargalos de CPU/memória no endpoint de estresse. Facilita redução do MTTR (*Mean Time To Resolution*). |
| **Automação Contínua (CI/CD)** | • Pipeline declarativa no GitHub Actions<br>• Testes unitários com Jest<br>• Validação de Terraform e K8s (dry-run) | Evita regressões antes de qualquer merge, assegurando conformidade de código e infraestrutura antes de atingir produção. |

---

## 🛠️ 2. Estrutura do Repositório

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml             # Pipeline de CI/CD (Test, Docker, Terraform & K8s)
├── Contratos/                    # Microsserviço Contracts API
│   ├── src/
│   │   ├── config/               # Conexões TypeORM (Postgres) e Redis
│   │   ├── controllers/          # ContractController (POST /contracts)
│   │   ├── entities/             # Entidade Contract
│   │   ├── middlewares/          # Métricas (prom-client) e Error Handler
│   │   ├── routes/               # Definição de rotas (/contracts, /metrics)
│   │   ├── services/             # Regra de negócio e persistência
│   │   ├── app.ts                # Inicialização do Express
│   │   └── server.ts             # Bootstrap na porta 3001
│   ├── tests/                    # Testes automatizados (Jest/ts-jest)
│   ├── Dockerfile                # Build Multi-stage otimizado
│   └── package.json
├── Flash Sales/                  # Microsserviço Flash Sales API
│   ├── src/
│   │   ├── config/               # Conexões TypeORM (Postgres) e Redis
│   │   ├── controllers/          # CheckoutController e ExportController
│   │   ├── entities/             # Entidade Order
│   │   ├── middlewares/          # Métricas (prom-client) e Error Handler
│   │   ├── routes/               # Rotas (/checkout, /tickets/export, /metrics)
│   │   ├── services/             # Checkout e geração de relatórios massivos
│   │   ├── app.ts                # Inicialização do Express
│   │   └── server.ts             # Bootstrap na porta 3002
│   ├── tests/                    # Testes automatizados (Jest/ts-jest)
│   ├── Dockerfile                # Build Multi-stage otimizado
│   └── package.json
├── terraform/                    # Infraestrutura como Código (IaC)
│   ├── main.tf                   # Recursos AWS no LocalStack (S3 Bucket e SQS Queue)
│   ├── variables.tf              # Variáveis de ambiente e endpoints
│   ├── providers.tf              # Provider AWS configurado para LocalStack
│   └── outputs.tf                # Outputs com S3 bucket name e SQS URL
├── k8s/                          # Manifestos de Orquestração Kubernetes
│   ├── 01-configmap-secrets.yaml # ConfigMap e Secret das credenciais e banco
│   ├── 02-postgres.yaml          # Deployment e Service do PostgreSQL 16
│   ├── 03-redis.yaml             # Deployment e Service do Redis 7
│   ├── 04-contracts-api.yaml     # Deployment (2 réplicas) e Service NodePort
│   ├── 05-flash-sales-api.yaml   # Deployment (2 réplicas) e Service NodePort
│   └── 06-ingress.yaml           # Regras de Ingress NGINX para devops.local
├── monitoring/                   # Observabilidade
│   └── prometheus/
│       └── prometheus.yml        # Configuração de scraping das APIs (/metrics)
├── docker-compose.yml            # Ambiente completo para desenvolvimento local
├── init-db.sql                   # Criação inicial dos bancos 'contracts_db' e 'flash_sales'
├── Proposta de Atividade DevOps.pdf
└── README.md                     # Documentação oficial do projeto
```

---

## 📋 3. Pré-requisitos do Sistema

Para reproduzir este ambiente, certifique-se de possuir instalado:
* **Docker** (v24+) e **Docker Compose** (v2+)
* **Node.js** (v20+) e **npm**
* **Terraform** (v1.5+)
* **kubectl** e um cluster Kubernetes local (Docker Desktop K8s, Minikube ou Kind)

---

## ⚡ 4. Guia de Execução Passo a Passo

### Opção A: Execução Integrada com Docker Compose (Recomendado para Desenvolvimento)

O `docker-compose.yml` sobe todos os serviços necessários em um único comando: LocalStack, PostgreSQL, Redis, as duas APIs, Prometheus e Grafana.

#### 1. Iniciar os Containers
```bash
docker-compose up --build -d
```

#### 2. Verificar o Status dos Serviços
```bash
docker-compose ps
```
Todos os serviços devem constar com o status `healthy` ou `running`.

#### 3. Provisionar os Recursos AWS no LocalStack com Terraform
Com o container do LocalStack em execução na porta `4566`, navegue para a pasta `terraform/` e aplique o plano:

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
cd ..
```

**Recursos criados no LocalStack:**
* **S3 Bucket:** `devops-activity-artifacts-dev` (armazenamento de artefatos e relatórios).
* **SQS Queue:** `flash-sales-orders-queue` (fila assíncrona de pedidos).

---

### Opção B: Implantação no Kubernetes (K8s)

Para implantar no ambiente orquestrado com Kubernetes (Docker Desktop Kubernetes, Minikube ou Kind):

#### 1. Construir as Imagens Docker Localmente
Os manifestos do Kubernetes utilizam as imagens locais `contracts-api:latest` e `flash-sales-api:latest`. Construa-as com:

```bash
# Construir Contracts API
docker build -t contracts-api:latest ./Contratos

# Construir Flash Sales API
docker build -t flash-sales-api:latest ./"Flash Sales"
```

> **Nota para Minikube:** Se estiver utilizando o Minikube em vez do Docker Desktop K8s, carregue as imagens para a máquina virtual:
> ```bash
> minikube image load contracts-api:latest
> minikube image load flash-sales-api:latest
> ```

#### 2. Aplicar os Manifestos em Ordem
Aplique os manifestos do diretório `k8s/`:

```bash
kubectl apply -f k8s/
```

#### 3. Validar Pods e Serviços
Aguarde a inicialização de todos os pods:

```bash
kubectl get pods
```
Saída esperada:
```text
NAME                                          READY   STATUS    RESTARTS   AGE
contracts-api-deployment-xxx-xxx              1/1     Running   0          30s
contracts-api-deployment-xxx-yyy              1/1     Running   0          30s
flash-sales-api-deployment-xxx-zzz            1/1     Running   0          30s
flash-sales-api-deployment-xxx-www            1/1     Running   0          30s
postgres-deployment-xxx-xxx                   1/1     Running   0          30s
redis-deployment-xxx-xxx                      1/1     Running   0          30s
```

Verifique os Services expostos:
```bash
kubectl get svc
```

---

## 🌐 5. Mapeamento de Portas e Endpoints

| Componente | Porta / URL Local | Descrição |
| :--- | :--- | :--- |
| **Contracts API** | `http://localhost:3001` | Microsserviço de contratos (NodePort K8s: `30001`) |
| **Flash Sales API** | `http://localhost:3002` | Microsserviço de vendas relâmpago (NodePort K8s: `30002`) |
| **PostgreSQL** | `localhost:5432` | Bancos `contracts_db` e `flash_sales` |
| **Redis** | `localhost:6379` | Cache em memória e estoque |
| **LocalStack** | `http://localhost:4566` | Emulador AWS (S3, SQS) |
| **Prometheus** | `http://localhost:9090` | Servidor de scraping e consulta de métricas |
| **Grafana** | `http://localhost:3000` | Interface de dashboards (User: `admin` \| Senha: `admin`) |

---

## 🧪 6. Testes Práticos e Validação das APIs

Execute os testes práticos abaixo para validar todas as rotas de negócio, persistência no PostgreSQL/Redis e monitoramento:

### 1. Criar um Contrato (`Contracts API`)
```bash
curl -X POST http://localhost:3001/contracts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Contrato de Prestacao de Servicos Cloud",
    "userId": "user-001",
    "description": "Contrato corporativo de infraestrutura",
    "value": 15000.50
  }'
```
* **Resposta esperada:** Status `201 Created` com o ID gerado e registro persistido no PostgreSQL e cache Redis.

---

### 2. Realizar Compra em Venda Relâmpago (`Flash Sales API`)
```bash
curl -X POST http://localhost:3002/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "show-rock-2026",
    "userId": "client-789",
    "quantity": 2
  }'
```
* **Resposta esperada:** Status `201 Created` confirmando a reserva e persistência do pedido.

---

### 3. Simulação de Teste de Carga e Gargalo de CPU/Memória
A rota `/tickets/export` gera um relatório massivo intencional para estressar o Event Loop do Node.js e permitir observar a variação de consumo nos gráficos do Prometheus/Grafana:

```bash
curl -X POST http://localhost:3002/tickets/export \
  -H "Content-Type: application/json" \
  -d '{"records": 50000}'
```
* **Resposta esperada:** Retorno com tamanho do relatório em bytes gerado.

---

### 4. Consultar Métricas do Prometheus
Ambas as APIs expõem métricas no padrão Prometheus:

```bash
# Métricas da Contracts API
curl http://localhost:3001/metrics

# Métricas da Flash Sales API
curl http://localhost:3002/metrics
```

No painel do Prometheus (`http://localhost:9090`), execute as seguintes consultas PromQL:
* `http_requests_total`: Total de requisições por rota e status code.
* `process_cpu_user_seconds_total`: Consumo de tempo de CPU da aplicação.
* `nodejs_eventloop_lag_seconds`: Latência do event loop do Node.js durante o teste de carga.

---

### 5. Validar Recursos Criados no LocalStack (S3 e SQS)
Utilizando a AWS CLI direcionada ao LocalStack:

```bash
# Listar Buckets S3
aws --endpoint-url=http://localhost:4566 s3 ls

# Listar Filas SQS
aws --endpoint-url=http://localhost:4566 sqs list-queues
```

---

### 6. Execução dos Testes Unitários Automatizados
Cada microsserviço possui suíte de testes com **Jest**:

```bash
# Testes da Contracts API
cd Contratos
npx jest
cd ..

# Testes da Flash Sales API
cd "Flash Sales"
npx jest
cd ..
```

---

## 🔄 7. Pipeline de CI/CD (GitHub Actions)

A automação contínua está definida em `.github/workflows/ci-cd.yml` e dispara automaticamente a cada `push` ou `pull_request` nas branches `main` e `develop`:

1. **Job `build-and-test`**:
   - Checkout do código-fonte.
   - Setup do Node.js v20.
   - Instalação limpa de dependências (`npm ci`).
   - Compilação estática TypeScript (`npm run build`).
2. **Job `docker-build`**:
   - Setup do Docker Buildx.
   - Build multi-stage das imagens `contracts-api:latest` e `flash-sales-api:latest`.
3. **Job `terraform-validate`**:
   - Setup do Terraform CLI (v1.6.0).
   - Validação sintática e de configuração (`terraform init -backend=false && terraform validate`).
4. **Job `k8s-validate`**:
   - Validação estática dos manifestos Kubernetes via `kubectl apply --dry-run=client -f k8s/`.

---

## 👥 Autores & Informações Acadêmicas
- **Atividade:** Criação de Infraestrutura DevOps
- **Tecnologias:** Docker, Kubernetes, Terraform, LocalStack, Prometheus, Grafana, Node.js, TypeScript, PostgreSQL, Redis, GitHub Actions.
