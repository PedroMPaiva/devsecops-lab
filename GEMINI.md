# Laboratório DevSecOps na Prática

Este documento registra o progresso do laboratório DevSecOps, construído com a assistência do Gemini CLI.

## Status Atual:

### Fase 1: Configuração do Ambiente de Pentest (Concluída)
-   **Máquina Atacante:** Kali Linux VM configurada.
-   **Máquina Servidor/Alvo:** Debian 12 VM configurada com Docker.
-   **Aplicações Alvo:** DVWA (acessível em http://<IP_DEBIAN>:4001) e OWASP Juice Shop (acessível em http://<IP_DEBIAN>:3000) rodando em contêineres Docker na VM Debian.
-   **Conectividade:** Acesso confirmado do Kali Linux às aplicações na VM Debian.

### Fase 2: Criação de uma Aplicação Simples (Concluída)
-   **Tecnologia:** Aplicação web simples em Python com Flask.
-   **Local:** Desenvolvida no PC Windows do usuário.
-   **Execução Local:** Aplicação rodando com sucesso em http://localhost:5000.
-   **Controle de Versão:** Código inicial (`app.py`, `requirements.txt`, `.gitignore`) versionado com Git e enviado para o repositório GitHub: `https://github.com/PedroMPaiva/devsecops-lab`.

## Próximos Passos:

### Fase 3: Construção do Pipeline CI/CD com Segurança (Iniciando)
-   **Objetivo:** Configurar GitHub Actions para automatizar verificações de segurança.
-   **Próxima Ação:** Criar o arquivo de workflow `.github/workflows/main.yml` no repositório.
    -   Integrar Análise Estática de Código (SAST) com Bandit.
    -   Integrar Análise de Dependências (SCA) com Trivy.
    -   Integrar Análise Dinâmica de Aplicações (DAST) com OWASP ZAP.

---
*Última atualização: 21 de julho de 2025*
