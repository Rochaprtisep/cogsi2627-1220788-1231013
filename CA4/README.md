# CA4 - Containerization

## Relatório Técnico - Parte 1

**Unidade Curricular:** Configuração e Gestão de Sistemas (COGSI)  
**Mestrado:** Engenharia Informática / Engenharia de Segurança Informática  
**Instituto Superior de Engenharia do Porto (ISEP)**  

**Autores:**
- **1231013** - Tiago Fontes (50%)
- **1220788** - (50%)

---

## 1. Introdução

Este relatório documenta a realização da **Parte 1** do CA4, focada na contentorização da aplicação de Chat desenvolvida no CA1 utilizando **Docker**.

O objetivo principal desta fase foi empacotar e executar o servidor de chat em contentores Docker através de três abordagens distintas de construção (`Dockerfile`), aplicar boas práticas de segurança através da execução sob um utilizador *non-root*, recolher métricas comparativas (tempo de build, tamanho e camadas) e publicar as imagens resultantes no Docker Hub.

---

## 2. Estrutura dos Ficheiros

Os ficheiros desenvolvidos para a Parte 1 encontram-se estruturados na pasta `CA4/part1/chat-server/`:

```text
CA4/
├── README.md
├── .gitattributes
├── part1/
│   └── chat-server/
│       ├── .dockerignore
│       ├── .gitignore
│       ├── Dockerfile.v1       # Versão 1: build clonando o repositório na imagem
│       ├── Dockerfile.v2       # Versão 2: cópia do JAR compilado no host
│       ├── Dockerfile.v3       # Versão 3: multi-stage build com utilizador non-root
│       ├── app/
│       ├── gradle/
│       ├── gradlew
│       ├── gradlew.bat
│       ├── gradle.properties
│       └── settings.gradle
└── part2/
    ├── .gitkeep
    └── docker-compose.yml      # Base para a orquestração da Parte 2
```

---

## 3. O Ficheiro `.dockerignore`

O ficheiro `.dockerignore` foi colocado na raiz de `CA4/part1/chat-server/` para filtrar os ficheiros enviados para o Docker Daemon durante a criação do contexto de construção:

```dockerignore
.git
.gradle
.idea
.vscode
*.log
*.tmp
.DS_Store
```

### Justificação:
1. **Redução do Contexto de Build:** Evita a transferência desnecessária de caches locais pesadas (`.gradle/`), acelerando o envio do contexto para o daemon.
2. **Segurança e Higiene:** Impede que metadados locais, histórico de commits (`.git`) ou ficheiros de configuração de IDEs sejam expostos nas camadas da imagem.
3. **Determinismo:** Garante que a compilação no container não reutiliza resíduos binários de compilações anteriores do host.

---

## 4. Implementação das 3 Versões de Dockerfile

### Versão 1: Build Clonando o Código na Imagem (`Dockerfile.v1`)
Esta versão descarrega as ferramentas necessárias (`git`, `bash`), clona o código do repositório diretamente dentro da imagem e compila a aplicação com o Gradle Wrapper:

```dockerfile
FROM eclipse-temurin:21-jdk-alpine

RUN apk add --no-cache git bash

WORKDIR /workspace

ARG REPO_URL=https://github.com/Rochaprtisep/cogsi2627-1220788-1231013.git
ARG REPO_BRANCH=main

RUN git clone --depth 1 --branch ${REPO_BRANCH} ${REPO_URL} repo && \
    if [ -d "repo/CA4/part1/chat-server" ]; then \
        cd repo/CA4/part1/chat-server; \
    else \
        cd repo/CA1/part1; \
    fi && \
    sed -i 's/\r$//' gradlew && \
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

**Comando de build:**
```bash
docker build -f Dockerfile.v1 -t chat-server:v1 .
```

---

### Versão 2: Cópia do JAR Compilado no Host (`Dockerfile.v2`)
Nesta versão, a compilação é realizada previamente no host (`./gradlew clean build packageApp`). O Dockerfile apenas copia o artefacto JAR e a pasta de dependências `lib/` para uma imagem JRE Alpine mínima:

```dockerfile
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY app/build/libs/chat-server-*.jar /app/chat-server.jar
COPY app/build/libs/lib /app/lib

EXPOSE 59001
ENTRYPOINT ["java", "-cp", "chat-server.jar:lib/*", "org.example.ChatServerApp", "59001"]
```

**Comando de build:**
```bash
docker build -f Dockerfile.v2 -t chat-server:v2 .
```

---

### Versão 3: Multi-Stage Build e Utilizador Non-Root (`Dockerfile.v3`)
Utiliza um primeiro estágio (`builder`) com JDK 21 para compilar o código fonte e um segundo estágio leve com JRE 21 Alpine para a execução, correndo a aplicação sob um utilizador dedicado sem privilégios (`appuser`):

```dockerfile
# Estagio 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /src
COPY . .

RUN apk add --no-cache bash && \
    sed -i 's/\r$//' gradlew && \
    chmod +x gradlew && \
    ./gradlew clean build packageApp --no-daemon

# Estagio 2: Runtime
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Criar grupo e utilizador sem privilegios
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar apenas os artefactos gerados e atribuir permissao ao appuser
COPY --from=builder --chown=appuser:appgroup /src/app/build/libs/chat-server-*.jar /app/chat-server.jar
COPY --from=builder --chown=appuser:appgroup /src/app/build/libs/lib /app/lib

USER appuser

EXPOSE 59001
ENTRYPOINT ["java", "-cp", "chat-server.jar:lib/*", "org.example.ChatServerApp", "59001"]
```

**Comando de build:**
```bash
docker build -f Dockerfile.v3 -t chat-server:v3 .
```

---

## 5. Justificação de Segurança: Execução Non-Root (`USER`)

A execução de contentores como `root` (UID 0) constitui um risco de segurança porque o UID 0 no contentor mapeia diretamente para o UID 0 no kernel do anfitrião (salvo se `userns-remap` estiver ativo).

A utilização da instrução `USER appuser` no `Dockerfile.v3` melhora a postura de segurança pelos seguintes motivos:

1. **Princípio do Menor Privilégio (*Least Privilege*):** A aplicação de chat necessita apenas de permissão para ler o JAR, abrir o socket na porta `59001` (porta não-privilegiada > 1024) e escrever logs. Não necessita de privilégios de administração do sistema.
2. **Mitigação de *Container Breakout*:** Em caso de vulnerabilidade de execução remota de código (RCE) na aplicação ou numa dependência (ex.: Log4j), o atacante obtém apenas os privilégios do utilizador `appuser`. Isto impede o acesso direto a ficheiros de configuração protegidos, montagem de dispositivos ou manipulação do kernel do host.
3. **Hardening do Sistema de Ficheiros:** O utilizador `appuser` não tem permissão para instalar novos pacotes via `apk` nem para modificar os binários do sistema operativo dentro do contentor.

**Comprovação do utilizador em execução:**
```bash
docker exec chat-srv id
# Output: uid=100(appuser) gid=101(appgroup) groups=101(appgroup)
```

---

## 6. Comparação das 3 Versões

Medições reais obtidas no ambiente de desenvolvimento:

| Métrica / Critério | Versão 1 (Clone na Imagem) | Versão 2 (Cópia de JAR do Host) | Versão 3 (Multi-Stage + Non-root) |
|---|---|---|---|
| **Tempo de Build Inicial** | ~28 s | ~1.5 s | ~22 s |
| **Tamanho da Imagem Final** | **881 MB** | **290 MB** | **290 MB** |
| **Tamanho Comprimido** | ~334 MB | ~76.2 MB | ~76.2 MB |
| **Número de Camadas** | 16 | 10 | 12 |
| **Dependências de Build na Imagem Final?** | **Sim** (JDK, Git, Gradle, cache) | **Não** (apenas JRE) | **Não** (apenas JRE) |
| **Utilizador de Execução** | `root` (UID 0) | `root` (UID 0) | `appuser` (UID 100) |
| **Superfície de Ataque** | Muito Elevada | Baixa | **Mínima** |

---

## 7. Análise de Camadas e Monitorização de Recursos

### Inspeção de Camadas (`docker history`)
O comando `docker history` demonstra claramente o impacto das escolhas de build:
- Na **Versão 1**, a instalação do Git/Bash e a camada de compilação adicionam cerca de 178 MB à imagem, para além dos 307 MB da base JDK.
- Na **Versão 3**, o estágio final descarta totalmente o compilador e as dependências temporárias do Gradle, mantendo apenas a base JRE (165 MB) e os binários da app (~2.4 MB).

### Monitorização em Tempo Real (`docker stats`)
Com o contentor `chat-srv` em execução contínua:

```text
CONTAINER ID   NAME       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O         BLOCK I/O     PIDS
d7c6efa02cfd   chat-srv   0.12%     51.21MiB / 15.34GiB   0.33%     1.17kB / 126B   75.2MB / 0B   20
```

---

## 8. Verificação da Conectividade

O servidor foi iniciado com mapeamento de porta para o host:
```bash
docker run -d --name chat-srv -p 59001:59001 chat-server:v3
```

A verificação de conectividade a partir do anfitrião confirmou a disponibilidade do serviço:
```powershell
PS> Test-NetConnection -ComputerName localhost -Port 59001

ComputerName     : localhost
RemoteAddress    : ::1
RemotePort       : 59001
TcpTestSucceeded : True
```

---

## 9. Publicação no Docker Hub

As imagens foram tagueadas e publicadas no Docker Hub sob a conta `fontezz`:

- `fontezz/chat-server:v1`
- `fontezz/chat-server:v2`
- `fontezz/chat-server:v3`

Comandos utilizados:
```bash
docker tag chat-server:v1 fontezz/chat-server:v1
docker tag chat-server:v2 fontezz/chat-server:v2
docker tag chat-server:v3 fontezz/chat-server:v3

docker push fontezz/chat-server:v1
docker push fontezz/chat-server:v2
docker push fontezz/chat-server:v3
```

---

## 10. Autoavaliação

| Membro da Equipa | Número de Estudante | Contribuição (%) |
|---|---|---|
| Tiago Fontes | 1231013 | 50% |
| (Colega de Grupo) | 1220788 | 50% |
