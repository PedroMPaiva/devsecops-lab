# Laboratório Prático: Pipeline DevSecOps "Zero to Hero" em AWS

Este projeto documenta a criação de um pipeline CI/CD seguro na AWS, utilizando GitHub Actions. O objetivo é demonstrar um fluxo de trabalho DevSecOps completo, desde a análise estática do código até o deploy de uma aplicação em um cluster Kubernetes (EKS), com múltiplos gates de segurança.

## Objetivo

Construir um pipeline CI/CD que automatiza o deploy de uma aplicação web em container, garantindo que práticas de segurança sejam aplicadas em cada etapa do processo (Shift Left).

**Tecnologias e Ferramentas:**
- **Cloud:** AWS
- **CI/CD:** GitHub Actions
- **Infraestrutura como Código (IaC):** Terraform
- **Containers:** Docker, Amazon ECR
- **Orquestração:** Kubernetes (Amazon EKS)
- **Ferramentas de Segurança:**
  - **SAST (Static Application Security Testing):** GitHub CodeQL
  - **Análise de IaC:** tfsec
  - **SCA (Software Composition Analysis) / Análise de Imagem:** Trivy
  - **Monitoramento de Ameaças:** AWS GuardDuty

---

## Fases do Laboratório

### Fase 1: Setup e Fundações (IAM) - Concluída

A base de qualquer ambiente seguro na nuvem é uma configuração de identidade e acesso (IAM) robusta e com privilégios mínimos.

- **Ações:**
  - [x] 1.  Criação de um usuário IAM para acesso via AWS CLI.
  - [x] 2.  Configuração de um Provedor de Identidade OIDC (OpenID Connect) no IAM para permitir que o GitHub Actions se autentique na AWS de forma segura, sem a necessidade de armazenar credenciais de longa duração como segredos no GitHub.
  - [x] 3.  Criação de uma Role IAM específica para o GitHub Actions, com as permissões necessárias para executar as tarefas do pipeline.

### Fase 2: Infraestrutura Segura como Código (Terraform + `tfsec`)

Provisionamento da infraestrutura base (VPC e EKS) de forma automatizada e segura.

- **Ações:**
  1.  Desenvolvimento de código Terraform para criar:
      - Uma VPC com sub-redes públicas e privadas.
      - Um cluster Amazon EKS.
  2.  Integração da ferramenta `tfsec` no ambiente de desenvolvimento local para escanear o código Terraform em busca de configurações inseguras antes de qualquer deploy.

### Fase 3: Containerização e Registro Seguro (Docker + ECR + Trivy)

Empacotamento da aplicação em um container Docker e verificação de suas dependências.

- **Ações:**
  1.  Criação de um `Dockerfile` para a aplicação web (Python/Flask).
  2.  Criação de um repositório privado no Amazon ECR (Elastic Container Registry).
  3.  Utilização da ferramenta `Trivy` para escanear a imagem Docker em busca de vulnerabilidades conhecidas (CVEs) em pacotes do SO e dependências da aplicação.

### Fase 4: O Pipeline CI/CD (GitHub Actions)

O coração do projeto, onde todas as fases anteriores são orquestradas.

- **Workflow (`.github/workflows/main.yml`):**
  - **Gatilho:** O pipeline é acionado a cada `push` na branch `main`.
  - **Job 1: `security_checks`**
    - **Gate 1 (IaC):** Roda o `tfsec` para validar a segurança do código Terraform.
    - **Gate 2 (SAST):** Roda o `CodeQL` para analisar o código-fonte da aplicação.
    - **Gate 3 (SCA):** Faz o build da imagem Docker e a escaneia com `Trivy`.
    - *O pipeline só prossegue se todos os gates de segurança passarem.*
  - **Job 2: `deploy`**
    - Autentica na AWS usando a Role OIDC.
    - Envia a imagem aprovada para o Amazon ECR.
    - Executa o `terraform apply` para provisionar a infraestrutura.
    - Usa `kubectl` para fazer o deploy da aplicação no cluster EKS.

### Fase 5: Monitoramento e Resposta (GuardDuty)

A segurança não termina após o deploy. É crucial monitorar o ambiente em tempo de execução.

- **Ações:**
  1.  Ativação do AWS GuardDuty para monitorar a conta AWS em busca de atividades maliciosas, anômalas ou não autorizadas.

---

## Como Executar

1.  Clone este repositório.
2.  Configure suas credenciais da AWS localmente (`aws configure`).
3.  Configure os segredos necessários no seu repositório do GitHub, se não estiver usando OIDC.
4.  Execute o `terraform init` e `terraform plan` no diretório `/infra` para validar a configuração.
5.  Faça um `push` para a branch `main` para acionar o workflow do GitHub Actions.
