# DevSecOps Lab Project

## Visão Geral do Projeto

Este projeto serve como um laboratório prático para demonstrar a implementação de práticas de DevSecOps em um pipeline de Integração Contínua/Entrega Contínua (CI/CD). O objetivo principal é integrar ferramentas de segurança (SAST, SCA, DAST) diretamente no fluxo de desenvolvimento, garantindo que vulnerabilidades sejam identificadas e corrigidas o mais cedo possível no ciclo de vida do software.

A aplicação é um simples servidor web Python construído com Flask, projetado para ser vulnerável a certas falhas de segurança que são então detectadas e remediadas através do pipeline DevSecOps.

## Tecnologias Utilizadas

*   **Python:** Linguagem de programação principal.
*   **Flask:** Microframework web para Python.
*   **Waitress:** Servidor WSGI de produção para Python.
*   **GitHub Actions:** Plataforma de CI/CD para automação do pipeline.
*   **Bandit:** Ferramenta de Análise Estática de Segurança de Aplicações (SAST) para Python.
*   **Trivy:** Ferramenta de Análise de Composição de Software (SCA) para detecção de vulnerabilidades em dependências.
*   **OWASP ZAP (Zed Attack Proxy):** Ferramenta de Análise Dinâmica de Segurança de Aplicações (DAST) para encontrar vulnerabilidades em aplicações web em execução.

## Pipeline DevSecOps (GitHub Actions)

O pipeline de CI/CD é orquestrado pelo GitHub Actions e consiste nas seguintes etapas:

1.  **SAST (Static Application Security Testing) com Bandit:**
    *   **Propósito:** Analisa o código-fonte Python em busca de padrões de código inseguros e vulnerabilidades conhecidas antes da execução.
    *   **Execução:** O Bandit é executado em todos os arquivos Python do projeto.
    *   **Resultado:** Gera um relatório JSON e falha o build se encontrar vulnerabilidades.

2.  **SCA (Software Composition Analysis) com Trivy:**
    *   **Propósito:** Identifica vulnerabilidades em bibliotecas e dependências de terceiros utilizadas pelo projeto.
    *   **Execução:** O Trivy escaneia o sistema de arquivos do projeto para detectar dependências e suas vulnerabilidades.
    *   **Resultado:** Gera um relatório SARIF e falha o build se encontrar vulnerabilidades críticas ou de alta severidade.

3.  **DAST (Dynamic Application Security Testing) com OWASP ZAP:**
    *   **Propósito:** Testa a aplicação em execução para identificar vulnerabilidades que só aparecem em tempo de execução (ex: injeção, XSS, configurações de segurança de cabeçalhos).
    *   **Execução:** A aplicação Flask é iniciada usando o servidor de produção Waitress, e o ZAP executa um scan de linha de base contra ela.
    *   **Resultado:** Gera um relatório HTML e JSON com os alertas encontrados.

## Desafios e Soluções Implementadas

Durante o desenvolvimento e aprimoramento deste laboratório, enfrentamos e resolvemos vários desafios de segurança, demonstrando a natureza iterativa do DevSecOps:

1.  **Vulnerabilidade de Dependência (SCA):**
    *   **Desafio:** O Trivy identificou uma vulnerabilidade crítica (CVE-2024-49768) na versão `2.1.2` do `waitress`.
    *   **Solução:** Atualizamos a dependência `waitress` para a versão `3.0.1` no `requirements.txt`, mitigando a vulnerabilidade.

2.  **Configuração Incorreta do Servidor DAST:**
    *   **Desafio:** Inicialmente, o pipeline DAST estava executando a aplicação com o servidor de desenvolvimento padrão do Flask (Werkzeug) em vez do servidor de produção (Waitress). Isso resultava em falsos positivos nos relatórios do ZAP, pois os cabeçalhos de segurança configurados para o Waitress não estavam sendo aplicados.
    *   **Solução:** Modificamos o workflow do GitHub Actions (`.github/workflows/main.yml`) para iniciar a aplicação explicitamente com `waitress-serve`, garantindo que o ambiente de teste DAST espelhasse o ambiente de produção e que os cabeçalhos de segurança fossem corretamente aplicados.

3.  **Aprimoramento da Política de Segurança de Conteúdo (CSP):**
    *   **Desafio:** Após a correção do servidor DAST, o ZAP revelou que a Política de Segurança de Conteúdo (CSP) estava incompleta, faltando a diretiva `form-action`. Isso representava um risco de segurança, pois formulários poderiam enviar dados para origens não autorizadas.
    *   **Solução:** Adicionamos `form-action 'self'` à diretiva `Content-Security-Policy` no `app.py`, restringindo explicitamente o envio de formulários para a própria origem da aplicação.

4.  **Alertas Informativos do ZAP:**
    *   **Desafio:** O ZAP continuou a reportar um alerta "Non-Storable Content" mesmo após todas as correções.
    *   **Solução:** Este alerta foi identificado como informativo e esperado, pois a aplicação foi configurada para desabilitar o cache (`Cache-Control: no-store`) por motivos de segurança, evitando o armazenamento de conteúdo sensível em caches intermediários.

## Como Executar o Projeto Localmente

Para configurar e executar este projeto em sua máquina local:

1.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/PedroMPaiva/devsecops-lab.git
    cd devsecops-lab
    ```

2.  **Crie e Ative um Ambiente Virtual:**
    ```bash
    python -m venv .venv
    # No Windows:
    .venv\Scripts\activate
    # No macOS/Linux:
    source .venv/bin/activate
    ```

3.  **Instale as Dependências:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Execute a Aplicação com Waitress:**
    ```bash
    waitress-serve --host=127.0.0.1 --port=5000 app:app
    ```
    A aplicação estará acessível em `http://127.0.0.1:5000/`.

## Como o Pipeline de CI/CD Funciona

O pipeline é executado automaticamente no GitHub Actions:

*   **Em cada `push` para a branch `main`:** Todos os estágios (SAST, SCA, DAST) são executados.
*   **Em cada `pull_request` para a branch `main`:** Todos os estágios são executados para validar as mudanças antes da fusão.

Você pode acompanhar o status das execuções do pipeline na aba "Actions" do repositório GitHub.

---
