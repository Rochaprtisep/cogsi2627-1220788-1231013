# CA5 — CI/CD Pipelines

## 1. Introdução e Ambiente
- Contexto do trabalho e ferramentas utilizadas (Jenkins, Vagrant, VirtualBox, Ansible, Docker, Java).

## 2. Arquitetura da Solução
- Diagrama e tabela de nós, endereços IP, controller Windows e agentes Linux (`ctrl` / `ctrl2`).
- Justificação das opções de arquitetura (Ansible em Linux, Jenkins no Windows, 1 vCPU por VM para compatibilidade com Hyper-V).

## 3. Parte 1 — Pipeline Gradle com Deploy Blue/Green em VMs
- Versionamento configurável com `-PappVersion`.
- Infraestrutura Vagrant (VMs `ctrl`, `blue`, `green`) e gestão de chaves SSH.
- Provisionamento e automação Ansible (roles `common`, `bookstore_runtime`, `bookstore_artifact`, playbook `site.yml`).
- Configuração do Jenkins (agente SSH, credenciais sem segredos no repositório).
- Pipeline `Jenkinsfile` stage a stage (Checkout, Assemble, Test com JUnit, Archive de estáveis, Deploy condicional).
- Mecanismo de Rollback idempotente (`rollback.yml` e `Jenkinsfile.rollback`).
- Demonstração e evidências (outputs, screenshots e verificação de saúde).

## 4. Parte 2 — Multibranch, Docker Hub e Deploy em Produção
- Pipeline Multibranch e configuração do Webhook.
- Construção da imagem Docker (app + H2 no mesmo contentor, utilizador non-root).
- Testes unitários e de integração em paralelo (execução distribuída no controller e agente).
- Publicação no Docker Hub com tags imutáveis.
- Deploy automatizado em produção na VM `prod` (apenas para o branch `main`).
- Notificações e verificações de saúde.

## 5. Alternativa CI/CD — GitHub Actions
- Análise comparativa entre Jenkins, GitHub Actions e GitLab CI.
- Desenho da solução para os mesmos requisitos.
- Implementação e reflexão sobre diferenças e limitações.

## 6. Autoavaliação
| Membro da Equipa | Número de Estudante | Contribuição (%) |
|---|---|---|
| Tiago Fontes | 1231013 | 50% |
| Pedro Rocha | 1220788 | 50% |
