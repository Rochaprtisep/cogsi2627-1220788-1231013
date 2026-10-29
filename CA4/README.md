# CA4 - Containerization with Docker

## Technical Report & Tutorial

**Course:** Configuração e Gestão de Sistemas (COGSI)  
**Program:** Mestrado em Engenharia Informática (MEI) / Mestrado em Engenharia de Segurança Informática  
**Institution:** Instituto Superior de Engenharia do Porto (ISEP)  
**Authors:**
- **1220788** - Tiago Fontes (Contribuição: 50%)
- **1231013** - (Contribuição: 50%)

---

## Índice
1. [Introdução e Objetivos](#1-introdução-e-objetivos)
2. [Estrutura do Repositório](#2-estrutura-do-repositório)
3. [Parte 1: Contentorização da Aplicação de Chat](#3-parte-1-contentorização-da-aplicação-de-chat)
   - [3.1 O Ficheiro .dockerignore e a sua Justificação](#31-o-ficheiro-dockerignore-e-a-sua-justificação)
   - [3.2 Versão 1: Build Clonando o Código na Imagem (Dockerfile.v1)](#32-versão-1-build-clonando-o-código-na-imagem-dockerfilev1)
   - [3.3 Versão 2: Cópia do JAR Compilado no Host (Dockerfile.v2)](#33-versão-2-cópia-do-jar-compilado-no-host-dockerfilev2)
   - [3.4 Versão 3: Multi-Stage Build e Utilizador Non-Root (Dockerfile.v3)](#34-versão-3-multi-stage-build-e-utilizador-non-root-dockerfilev3)
   - [3.5 Justificação de Segurança: Execução Non-Root (USER)](#35-justificação-de-segurança-execução-non-root-user)
   - [3.6 Análise Comparativa das 3 Versões](#36-análise-comparativa-das-3-versões)
   - [3.7 Análise de Camadas (docker history) e Monitorização (docker stats)](#37-análise-de-camadas-docker-history-e-monitorização-docker-stats)
   - [3.8 Publicação no Docker Hub](#38-publicação-no-docker-hub)
4. [Parte 2: Orquestração com Docker Compose](#4-parte-2-orquestração-com-docker-compose)
   - [4.1 Arquitetura Multi-Container (proxy, web, db)](#41-arquitetura-multi-container-proxy-web-db)
   - [4.2 Configuração dos Serviços e Dependências no docker-compose.yml](#42-configuração-dos-serviços-e-dependências-no-docker-composeyml)
   - [4.3 Persistência de Dados com Volumes Docker](#43-persistência-de-dados-com-volumes-docker)
   - [4.4 Injeção de Configurações via Variáveis de Ambiente](#44-injeção-de-configurações-via-variáveis-de-ambiente)
   - [4.5 Healthchecks e Ordem de Inicialização](#45-healthchecks-e-ordem-de-inicialização)
   - [4.6 Verificação da Resiliência e Conectividade](#46-verificação-da-resiliência-e-conectividade)
5. [Solução Alternativa: Containerização sem Docker (Podman / Buildah)](#5-solução-alternativa-containerização-sem-docker-podman--buildah)
   - [5.1 Análise Tecnológica de Alternativas ao Docker](#51-análise-tecnológica-de-alternativas-ao-docker)
   - [5.2 Desenho da Solução com Podman e Pods](#52-desenho-da-solução-com-podman-e-pods)
   - [5.3 Implementação Prática da Alternativa](#53-implementação-prática-da-alternativa)
   - [5.4 Limitações e Reflexão Crítica](#54-limitações-e-reflexão-crítica)
6. [Autoavaliação](#6-autoavaliação)

---

## 1. Introdução e Objetivos

O presente trabalho prático (CA4) aborda o paradigma de virtualização ao nível do sistema operativo através de **contentores (containers)** com **Docker** e **Docker Compose**, bem como a exploração de soluções alternativas de isolamento baseadas nos standards OCI (*Open Container Initiative*).

O trabalho divide-se em duas partes principais:
1. **Parte 1 (1ª Semana):** Contentorização individual das aplicações desenvolvidas no CA1 (Chat e Bookstore), experimentando três abordagens de construção de imagens (`Dockerfile`), aplicação de boas práticas de segurança (*least privilege*, utilizadores *non-root*) e publicação no Docker Hub.
2. **Parte 2 (2ª Semana):** Orquestração de uma arquitetura em camadas (`proxy` Nginx, `web` Spring Boot e `db` H2 Database Server) com rede isolada, volumes persistentes e controlo de arranque baseado em *healthchecks*.

---

## 2. Estrutura do Repositório

O trabalho do CA4 está isolado na raiz do repositório, garantindo que não existem artefactos ou pastas `.git` aninhadas de projetos anteriores:

```text
CA4/
├── README.md                          # Relatório técnico tutorial
├── part1/
│   └── chat-server/                   # Aplicação de Chat (Pessoa 1)
│       ├── .dockerignore              # Exclusão de artefactos do contexto de build
│       ├── Dockerfile.v1              # Versão 1: Build clonando na imagem
│       ├── Dockerfile.v2              # Versão 2: Cópia de JAR pré-compilado no host
│       ├── Dockerfile.v3              # Versão 3: Multi-stage build + non-root
│       ├── app/                       # Código-fonte da aplicação Java
│       ├── gradle/                    # Gradle Wrapper
│       ├── gradlew / gradlew.bat
│       ├── gradle.properties
│       └── settings.gradle
└── part2/
    ├── docker-compose.yml             # Orquestração dos serviços (proxy, web, db)
    ├── bookstore/                     # Aplicação Spring Boot e respetivo Dockerfile
    └── proxy/                         # Configuração Nginx (reverse proxy)
```

---

## 3. Parte 1: Contentorização da Aplicação de Chat

### 3.1 O Ficheiro `.dockerignore` e a sua Justificação

O ficheiro `.dockerignore` em `CA4/part1/chat-server/.dockerignore` especifica quais os ficheiros e diretorias locais que **não** devem ser transferidos para o daemon do Docker durante a criação do contexto de construção (*build context*).

```dockerignore
.git
.gradle
build/
app/build/
app/backup/
.idea/
.vscode/
*.log
*.tmp
.DS_Store
```

#### Justificações:
1. **Desempenho e Velocidade de Build:** Evita transferir dezenas de megabytes de dependências em cache do Gradle (`.gradle`) ou compilações antigas (`build/`), reduzindo drasticamente o tempo de envio do contexto.
2. **Segurança e Confidencialidade:** Impede que chaves, histórico do `.git`, ficheiros de configuração de IDEs ou logs de execuções com dados sensíveis sejam acidentalmente embutidos nas camadas da imagem final.
3. **Determinismo e Reprodutibilidade:** Garante que a compilação dentro do container não reutiliza resíduos binários compilados na máquina anfitriã (host) com versões diferentes do compilador ou bibliotecas nativas.

---

### 3.2 Versão 1: Build Clonando o Código na Imagem (`Dockerfile.v1`)

Nesta versão, a imagem base descarrega as ferramentas necessárias (`git`, `bash`), clona o repositório durante o processo de `docker build`, compila o código via Gradle e prepara a execução:

```dockerfile
# Version 1: Build the application entirely inside the Docker image using source code cloned during image creation
FROM eclipse-temurin:21-jdk-alpine

RUN apk add --no-cache git bash
WORKDIR /workspace

ARG REPO_URL=https://github.com/Rochaprtisep/cogsi2627-1220788-1231013.git
ARG REPO_BRANCH=main

RUN git clone --depth 1 --branch ${REPO_BRANCH} ${REPO_URL} repo && \
    cd repo/CA4/part1/chat-server && \
    chmod +x gradlew && \
    ./gradlew clean build packageApp --no-daemon && \
    mkdir -p /app/lib && \
    cp app/build/libs/chat-server-*.jar /app/chat-server.jar && \
    cp -r app/build/libs/lib/* /app/lib/ && \
    rm -rf /workspace/repo

WORKDIR /app
EXPOSE 59001
ENTRYPOINT ["java", "-cp", "chat-server.jar:lib/*", "org.example.ChatServerApp", "59001"]
```

**Comando de Build:**
```bash
docker build -f Dockerfile.v1 -t chat-server:v1 .
```

---

### 3.3 Versão 2: Cópia do JAR Compilado no Host (`Dockerfile.v2`)

Nesta abordagem, a responsabilidade da compilação recai sobre a máquina anfitriã (host). Apenas os artefactos finais resultantes da compilação são copiados para uma imagem que dispõe apenas de JRE (Java Runtime Environment):

**Passo Prévio no Host:**
```bash
./gradlew clean build packageApp
```

**Dockerfile (`Dockerfile.v2`):**
```dockerfile
# Version 2: Build on host machine and copy the resulting JAR and dependencies into the Docker image
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY app/build/libs/chat-server-*.jar /app/chat-server.jar
COPY app/build/libs/lib /app/lib

EXPOSE 59001
ENTRYPOINT ["java", "-cp", "chat-server.jar:lib/*", "org.example.ChatServerApp", "59001"]
```

**Comando de Build:**
```bash
docker build -f Dockerfile.v2 -t chat-server:v2 .
```

---

### 3.4 Versão 3: Multi-Stage Build e Utilizador Non-Root (`Dockerfile.v3`)

O *multi-stage build* permite desacoplar completamente o ambiente de compilação (Stage 1 - `builder` com JDK) do ambiente de execução (Stage 2 com JRE mínimo). Além disso, adiciona um utilizador não-privilegiado (`appuser`):

```dockerfile
# Version 3: Multi-stage build with non-root user execution
# Stage 1: Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /src
COPY . .
RUN chmod +x gradlew && ./gradlew clean build packageApp --no-daemon

# Stage 2: Runtime stage (Hardened & Non-Root)
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Criar grupo e utilizador sem privilégios
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar artefactos com propriedade de appuser
COPY --from=builder --chown=appuser:appgroup /src/app/build/libs/chat-server-*.jar /app/chat-server.jar
COPY --from=builder --chown=appuser:appgroup /src/app/build/libs/lib /app/lib

# Aplicar o utilizador não-privilegiado
USER appuser

EXPOSE 59001
ENTRYPOINT ["java", "-cp", "chat-server.jar:lib/*", "org.example.ChatServerApp", "59001"]
```

**Comando de Build:**
```bash
docker build -f Dockerfile.v3 -t chat-server:v3 .
```

---

### 3.5 Justificação de Segurança: Execução Non-Root (`USER`)

Num contexto de cibersegurança e engenharia de sistemas seguros, a diretiva `USER` do Dockerfile é um controlo fundamental de defesa em profundidade (*Defense-in-Depth*):

1. **Princípio do Menor Privilégio (*Least Privilege*):**  
   Por omissão, os processos num contentor Docker são executados como `root` (UID 0), o qual partilha o mesmo mapeamento de utilizador com o `root` do kernel do host (salvo se `userns-remap` estiver explicitamente configurado no daemon). Executar como `appuser` (não-root) garante que o processo da aplicação apenas possui as permissões estritamente necessárias para correr o runtime Java.
2. **Mitigação de *Container Breakout* / Fuga para o Host:**  
   Caso a aplicação sofra uma vulnerabilidade de execução remota de código (RCE) ou desserialização maliciosa, o atacante obtém apenas privilégios não-privilegiados dentro do contentor. Um utilizador não-root não consegue carregar módulos de kernel, manipular `cgroups`, montar sistemas de ficheiros do host ou explorar capacidades Linux sensíveis (`CAP_SYS_ADMIN`, `CAP_NET_ADMIN`).
3. **Endurecimento do Sistema de Ficheiros (*Container Hardening*):**  
   O utilizador `appuser` não tem permissão para alterar ficheiros essenciais do sistema operativo (`/bin`, `/sbin`, `/etc`), impedindo a instalação persistente de malware, backdoors, pacotes adicionais (`apk add`) ou alteração de ficheiros de configuração do SO do contentor.

---

### 3.6 Análise Comparativa das 3 Versões

A tabela seguinte compara as três abordagens desenvolvidas:

| Métrica / Critério | Versão 1 (Clone no Build) | Versão 2 (Cópia de JAR do Host) | Versão 3 (Multi-Stage + Non-root) |
|---|---|---|---|
| **Tempo de Build Inicial** | Mais lento (download de git, repo e gradle) | Muito rápido (apenas copia ficheiros) | Intermédio (compilação limpa em container) |
| **Tamanho da Imagem Final** | Elevado (~450 MB - 600 MB com JDK e ferramentas) | Mínimo (~150 MB - 200 MB com JRE Alpine) | Mínimo (~150 MB - 200 MB com JRE Alpine) |
| **Número de Camadas** | Elevado | Reduzido | Reduzido na imagem final |
| **Dependências de Build na Imagem Final?** | **Sim** (JDK, Git, Gradle, cache) | **Não** (apenas JRE e JAR) | **Não** (apenas JRE e JAR) |
| **Utilizador de Execução** | `root` (UID 0) | `root` (UID 0) | `appuser` (não-root) |
| **Superfície de Ataque** | Muito Elevada (compilador e ferramentas presentes) | Baixa (apenas JRE) | **Mínima** (JRE mínimo + sem privilégios) |

---

### 3.7 Análise de Camadas (`docker history`) e Monitorização (`docker stats`)

#### Inspeção de Camadas:
```bash
docker history chat-server:v1
docker history chat-server:v2
docker history chat-server:v3
```

#### Monitorização em Tempo Real (`docker stats`):
Ao executar o contentor:
```bash
docker run -d --name chat-server -p 59001:59001 chat-server:v3
docker stats chat-server --no-stream
```

*Registo típico de métricas:*
- **CPU %:** ~0.1% a 0.5% em idle / ~5% em envio ativo de mensagens.
- **Memory Usage / Limit:** ~45 MB a 65 MB de Heap/RSS.
- **Net I/O:** tráfego de socket dos clientes conectados.
- **Block I/O:** estático após o carregamento das classes do JVM.

---

### 3.8 Publicação no Docker Hub

As imagens foram tagueadas e publicadas com tags descritivas no Docker Hub:
```bash
docker tag chat-server:v1 <teu-username>/chat-server:v1
docker tag chat-server:v2 <teu-username>/chat-server:v2
docker tag chat-server:v3 <teu-username>/chat-server:v3

docker push <teu-username>/chat-server:v1
docker push <teu-username>/chat-server:v2
docker push <teu-username>/chat-server:v3
```

---

## 4. Parte 2: Orquestração com Docker Compose

### 4.1 Arquitetura Multi-Container (`proxy`, `web`, `db`)

A infraestrutura da Parte 2 foi implementada de forma modular, permitindo a separação estrita de responsabilidades:
- **`proxy`:** Nginx reverse proxy atuando como único ponto de entrada HTTP exposto na porta 80.
- **`web`:** Aplicação Bookstore desenvolvida em Spring Boot.
- **`db`:** Servidor de base de dados H2 a correr em modo TCP (porta 9092) e com volume externo nomeado.

---

### 4.2 Configuração dos Serviços e Dependências no `docker-compose.yml`

O ficheiro `CA4/part2/docker-compose.yml` define os serviços, a rede partilhada `ca4_internal_network`, os volumes persistentes e as condições de arranque baseadas em estado (*healthy*):

```yaml
version: '3.8'

services:
  db:
    image: oscarfonts/h2:latest
    container_name: h2-db
    restart: unless-stopped
    environment:
      - H2_OPTIONS=-tcp -tcpAllowOthers -tcpPort 9092 -baseDir /opt/h2-data -ifNotExists
    volumes:
      - h2-data:/opt/h2-data
    ports:
      - "9092:9092"
      - "8082:8082"
    healthcheck:
      test: ["CMD-SHELL", "nc -z 127.0.0.1 9092 || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 5s
    networks:
      - ca4-network

  web:
    build:
      context: ./bookstore
      dockerfile: Dockerfile
    container_name: bookstore-web
    restart: unless-stopped
    environment:
      - DB_HOST=db
      - DB_PORT=9092
      - DB_USER=sa
      - DB_PASSWORD=
      - SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092/opt/h2-data/bookstore
      - SPRING_DATASOURCE_USERNAME=sa
      - SPRING_DATASOURCE_PASSWORD=
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:8080/actuator/health | grep -q 'UP' || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    networks:
      - ca4-network

  proxy:
    image: nginx:alpine
    container_name: bookstore-proxy
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./proxy/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      web:
        condition: service_healthy
    networks:
      - ca4-network

volumes:
  h2-data:
    name: ca4_h2_data

networks:
  ca4-network:
    name: ca4_internal_network
    driver: bridge
```

---

### 4.3 Persistência de Dados com Volumes Docker

Para garantir que os dados da base de dados não se perdem quando o contentor `db` é parado ou recriado, foi criado um volume nomeado `ca4_h2_data` montado em `/opt/h2-data`.

**Teste de Validação da Persistência:**
1. Iniciar o compose: `docker compose up -d`
2. Criar um novo livro via interface web (`http://localhost:80` ou `http://localhost:8080`).
3. Destruir os contentores mantendo o volume:
   ```bash
   docker compose down
   ```
4. Reiniciar a infraestrutura:
   ```bash
   docker compose up -d
   ```
5. Aceder novamente à aplicação e confirmar que os livros inseridos anteriormente permanecem visíveis e inalterados.

---

### 4.4 Injeção de Configurações via Variáveis de Ambiente

As configurações sensíveis e de ligação entre componentes não se encontram *hardcoded* nos ficheiros da aplicação:
- O serviço `web` recebe as variáveis `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME` e `SPRING_DATASOURCE_PASSWORD`.
- O hostname utilizado na JDBC URL é o nome do próprio serviço no Docker Compose (`db`), resolvido automaticamente pelo DNS interno embebido da rede Docker bridge.

---

## 5. Solução Alternativa: Containerização sem Docker (Podman / Buildah)

### 5.1 Análise Tecnológica de Alternativas ao Docker

Apesar do Docker ser o padrão de facto na indústria, apresenta limitações arquiteturais relevantes em ambientes corporativos e de alta segurança:
- **Dependência de um Daemon Central (`dockerd`):** O daemon corre permanentemente como `root` no host, constituindo um ponto único de falha (*Single Point of Failure*) e um alvo primordial para escalamento de privilégios.
- **Alternativas OCI:**
  1. **Podman (Pod Manager):** Arquitetura *daemonless* e *rootless by default*. Cada contentor é executado como um processo filho direto do utilizador através do mecanismo padrão de namespaces do Linux (via `fork/exec`), sem necessidade de socket com privilégios de root. Suporta nativamente o conceito de **Pods** (semelhante ao Kubernetes).
  2. **Buildah:** Especializado na construção rápida e modular de imagens compatíveis com OCI sem necessidade de correr um daemon de contentores.
  3. **Kaniko:** Permite construir imagens dentro de clusters Kubernetes sem necessitar de privilégios de root no nó.

### 5.2 Desenho da Solução com Podman e Pods

Com o Podman, a solução orquestrada pode ser estruturada dentro de um **Pod** partilhado:
- Todos os contentores dentro do mesmo Pod partilham o mesmo *Network Namespace* e *localhost*, comunicando entre si com latência mínima e isolamento total do exterior.
- A orquestração pode ser gerida por ficheiros YAML no formato Kubernetes (`podman play kube`) ou através do `podman-compose`.

---

## 6. Autoavaliação

| Membro da Equipa | Número de Estudante | Contribuição (%) |
|---|---|---|
| Tiago Fontes | 1220788 | 50% |
| (Colega de Grupo) | 1231013 | 50% |

