# CA5 — CI/CD Pipelines

## Relatório Técnico — Partes 1 e 2

**Unidade Curricular:** Configuração e Gestão de Sistemas (COGSI)  
**Mestrado:** Engenharia Informática / Engenharia de Segurança Informática  
**Instituto Superior de Engenharia do Porto (ISEP)**  

**Autores:**
- **1231013** — Tiago Fontes (50%)
- **1220788** — Pedro Rocha (50%)

---

## 1. Introdução e Ambiente

Este relatório documenta a conceção, implementação e validação do **Assignment 5 (CA5)**, dedicado à automação do ciclo de vida de software através de **Pipelines de Integração Contínua e Entrega Contínua (CI/CD)**.

O objetivo da **Parte 1** consiste em automatizar a construção, teste unitário, arquivo com integridade criptográfica e deployment contínuo da aplicação **Bookstore** (baseada em Spring Boot e Gradle, desenvolvida no CA1) através de uma pipeline declarativa em **Jenkins**, aplicando uma estratégia de deployment **Blue/Green** automatizada com **Ansible** sobre máquinas virtuais geridas por **Vagrant**, complementada com um mecanismo idempotente de **Rollback**.

### Ferramentas e Versões Utilizadas

| Ferramenta / Componente | Versão / Especificação | Finalidade no Projeto |
|---|---|---|
| **Host OS** | Windows 11 Pro 64-bit | Execução do Hypervisor e Jenkins Controller |
| **Hypervisor** | Oracle VM VirtualBox 7.1.x | Execução das máquinas virtuais do cluster |
| **IaC / Virtualização** | Vagrant 2.4.x (`bento/ubuntu-22.04`) | Provisionamento automatizado e isolado das VMs |
| **Gestão de Configuração** | Ansible Core 2.14+ (no nó `ctrl`) | Automação de runtime, deploy e rollback |
| **CI/CD Server** | Jenkins 2.580.2 | Orquestração da pipeline declarativa |
| **Java Runtimes** | OpenJDK 21 (Jenkins) / OpenJDK 17 (App) | Execução do Jenkins Controller e do Bookstore |
| **Build Tool** | Gradle 9.4 (via Gradle Wrapper) | Compilação, teste e empacotamento da app |
| **Controlo de Versões** | Git 2.47+ / GitHub | Controlo de versões, branches e webhooks |

---

## 2. Arquitetura da Solução

### Topologia de Nós e Endereçamento

Para garantir a separação de responsabilidades e permitir a estratégia de deployment Blue/Green, foram configurados 4 intervenientes principais:

| Nó | IP / Interface | Sistema Operativo | Papel e Responsabilidades |
|---|---|---|---|
| **Host (Jenkins Controller)** | `localhost:9090` | Windows 11 | Gestor da orquestração Jenkins, interface web, gestão de credenciais e histórico de builds. |
| **ctrl (Agente Jenkins + Ansible)** | `192.168.56.20` | Ubuntu 22.04 LTS | Agente Linux de build (SSH), nó de controlo Ansible, compilação Gradle e execução de testes. |
| **blue (Ambiente Atual / Produção)** | `192.168.56.21` | Ubuntu 22.04 LTS | Aloja a versão base em produção (`v1.0.0`) com base de dados H2 embedded e serviço systemd. |
| **green (Ambiente Candidato / Staging)** | `192.168.56.22` | Ubuntu 22.04 LTS | Ambiente alvo de novas releases estáveis (`v1.0.X`) e de procedimentos de rollback. |

### Justificação das Decisões de Arquitetura

1. **Jenkins Controller nativo em Windows na porta 9090:**
   - Evita colisão direta com a porta padrão `8080` utilizada pelos serviços Spring Boot do Bookstore.
   - Permite tirar partido do JDK 21 instalado no host sem necessidade de emuladores ou WSL2 com restrições de rede.
2. **VM `ctrl` como Agente Jenkins Linux via SSH:**
   - O Ansible não corre nativamente em sistemas operativos Windows (requer chamadas POSIX e controlo estrito de permissões `0600` em ficheiros de chaves privadas SSH).
   - Ao registar a VM `ctrl` como agente SSH do Jenkins (`agent { label 'ca5-p1' }`), todas as tarefas pesadas de compilação, testes e execução de playbooks correm diretamente em ambiente Linux nativo, garantindo isolamento total em relação ao host Windows.
3. **Pares de Chaves SSH Ed25519 Geradas por VM:**
   - No arranque do Vagrant, são geradas chaves assimétricas dedicadas por cada máquina (`keys/ctrl`, `keys/blue`, `keys/green`). O nó `ctrl` recebe apenas a chave pública autorizada e a chave privada necessária para contactar `blue` e `green`.
4. **Dimensionamento de Recursos:**
   - Foi atribuída **1 vCPU e 1024 MB de RAM** por VM (com 2048 MB no `ctrl` para suporte ao Gradle e ao agente Jenkins), garantindo estabilidade no hypervisor e compatibilidade total com o hardware host.

---

## 3. Parte 1 — Pipeline Gradle com Deploy Blue/Green em VMs

### 3.1. Rastreabilidade e Versionamento Dinâmico

Para assegurar a rastreabilidade entre cada commit/build no Jenkins e o artefacto gerado, o ficheiro `CA1/part2/app/build.gradle` foi modificado para suportar a injeção da versão por propriedade do Gradle:

```groovy
version = findProperty('appVersion') ?: '1.0.0'
```

* **Comportamento por omissão:** Em builds locais de desenvolvimento sem parâmetros, a versão mantém-se `1.0.0`.
* **Comportamento em CI:** O Jenkins injeta o identificador semântico de build através da flag `-PappVersion="stable-v1.0.${BUILD_NUMBER}"`, gerando um binário único e auditável: `bookstore-stable-v1.0.N.jar`.

### 3.2. Infraestrutura Vagrant (`CA5/part1/Vagrantfile`)

O `Vagrantfile` define a rede privada `192.168.56.0/24` e provisiona as três VMs:
* Configura as interfaces de rede com IPs estáticos.
* Gera no host o par de chaves SSH `ed25519` para cada VM na pasta `keys/`.
* No nó `ctrl`, executa o script de bootstrap `provision/ctrl.sh`:
  - Instala `ansible`, `git`, `openjdk-17-jdk` (para build e execução do Bookstore) e `openjdk-21-jre-headless` (para o agente de execução do Jenkins).
  - Garante permissões estritas `0600` nas chaves SSH copiadas para `/home/vagrant/.ssh/`.

Comando de inicialização:
```powershell
cd CA5/part1
vagrant up
```

### 3.3. Automação e Provisionamento com Ansible

A pasta `CA5/part1/ansible/` organiza a infraestrutura como código (IaC) de forma modular:

* **`hosts.ini`:**
  ```ini
  [ctrl]
  localhost ansible_connection=local

  [blue]
  192.168.56.21 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/id_blue

  [green]
  192.168.56.22 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/id_green
  ```

* **Roles Desenvolvidas:**
  1. `common`: Atualização de repositórios, dependências base e criação do utilizador de sistema `vagrant`.
  2. `bookstore_runtime`: Criação da árvore de pastas `/opt/bookstore/` (`releases/`, `data/`, `log/`), configuração da firewall e criação do serviço `systemd` (`bookstore.service`) que aponta sempre para o link simbólico `/opt/bookstore/current.jar`.
  3. `bookstore_artifact`: Faz download autenticado de uma versão arquivada no Jenkins usando a REST API, atualiza o symlink de forma atómica, reinicia o serviço systemd e valida a saúde da aplicação nos endpoints `/actuator/health` e `/info/details`.

* **Playbooks:**
  - `site.yml`: Provisiona os nós `blue` e `green`, compila localmente no `ctrl` a versão inicial `1.0.0` e faz o deploy base no ambiente `blue`.
  - `deploy-green.yml`: Efetua o deploy da nova versão candidata gerada pelo Jenkins exclusivamente no nó `green`.
  - `rollback.yml`: Restaura uma versão estável anterior no nó `green`.

### 3.4. Configuração do Jenkins e Segurança de Credenciais

De acordo com as boas práticas do setor e os requisitos do trabalho, **nenhum segredo, password ou chave privada reside no repositório**:

1. **Agente SSH `ctrl`:**
   - Configurado no menu *Gerir o Jenkins > Nós > Novo Nó*.
   - Nome: `ctrl`, Rótulo: `ca5-p1`, Executores: `2`.
   - Método de lançamento: *Launch agents via SSH* apontando para `192.168.56.20:22`.
   - Credencial associada: `jenkins-agent-key` (SSH Username with private key com o conteúdo de `keys/ctrl`).
2. **Credenciais Armazenadas:**
   - `github-pat`: *Secret text* para autenticação com o GitHub no checkout.
   - `jenkins-artifacts`: *Username with password* (`admin` + API Token) injetado nas variáveis de ambiente `JENKINS_USER` e `JENKINS_API_TOKEN` para o download seguro dos artefactos durante a execução do Ansible.

### 3.5. Pipeline Declarativa (`CA5/part1/Jenkinsfile`)

A pipeline foi estruturada nas seguintes etapas declarativas sequenciais:

1. **Checkout:** Clona o repositório na revisão exata do branch com a credencial `github-pat`.
2. **Assemble:** Executa `./gradlew clean bootJar "-PappVersion=${STABLE_TAG}"` no agente `ctrl`, gerando o binário versionado.
3. **Test:** Executa os testes unitários via `./gradlew test` e recolhe os resultados no formato JUnit através do step `junit '**/build/test-results/test/*.xml'`.
4. **Archive:** Calcula o checksum criptográfico SHA-256 do artefacto (`sha256sum`) e arquiva em permanência os ficheiros `dist/bookstore-${STABLE_TAG}.jar` e `dist/SHA256SUMS`.
5. **Deploy (Condicional):** Controlado pelo parâmetro booleano `DEPLOY`:
   ```groovy
   stage('Deploy') {
       when { expression { return params.DEPLOY } }
       steps {
           withCredentials([usernamePassword(credentialsId: 'jenkins-artifacts', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_API_TOKEN')]) {
               dir('CA5/part1/ansible') {
                   sh "ansible-playbook deploy-green.yml -e stable_version=$STABLE_TAG -e build_number=$BUILD_NUMBER"
               }
           }
       }
   }
   ```
6. **Declarative Post Actions:** Em caso de sucesso com deploy ativo, efetua uma validação externa via HTTP GET a `http://192.168.56.22:8080/info/details` confirmando que a versão reportada pela aplicação é idêntica à tag compilada.

### 3.6. Mecanismo de Rollback Idempotente

Caso uma versão recente apresente comportamentos indesejados no ambiente `green`, foi criado o pipeline de rollback `ca5-part1-rollback` governado pelo `CA5/part1/Jenkinsfile.rollback`:

* Aceita o parâmetro `STABLE_VERSION` (por exemplo, `stable-v1.0.2`).
* Executa o playbook `CA5/part1/ansible/rollback.yml`.
* O Ansible descarrega o artefacto histórico diretamente dos arquivos do Jenkins, substitui o symlink `/opt/bookstore/current.jar`, reinicia o serviço e aguarda até que `/actuator/health` responda `UP` e `/info/details` confirme a versão restaurada.

---

## 4. Evidências e Demonstração da Parte 1

### 4.1. Execução da Pipeline de CI/CD (Build #4 com Deploy Ativo)

A execução com `DEPLOY=true` compilou a versão `stable-v1.0.4`, correu a suite de testes, arquivou o artefacto e executou o playbook `deploy-green.yml`:

![Pipeline Stage View - Deploy no Green com Sucesso](images/ca5-p1-pipeline-deploy-success.png)

### 4.2. Comprovação do Deployment Blue/Green

Após o deployment, o ambiente de produção estável (`blue`) permaneceu com a versão inicial `1.0.0`, enquanto o ambiente candidato (`green`) passou a executar a versão `1.0.4`:

* **Ambiente Blue (192.168.56.21):**
  ```bash
  $ curl -s http://192.168.56.21:8080/info/details
  {
    "_links": {
      "service": { "href": "bookstore-api" },
      "version": { "href": "1.0.0" },
      "environment": { "href": "blue" },
      "buildTimestamp": { "href": "local-build" },
      "root": { "href": "http://192.168.56.21:8080/" }
    }
  }
  ```

* **Ambiente Green pós-Deploy (192.168.56.22):**
  ```bash
  $ curl -s http://192.168.56.22:8080/info/details
  {
    "_links": {
      "service": { "href": "bookstore-api" },
      "version": { "href": "1.0.4" },
      "environment": { "href": "green" },
      "buildTimestamp": { "href": "local-build" },
      "root": { "href": "http://192.168.56.22:8080/" }
    }
  }
  ```

### 4.3. Comprovação do Rollback para a Versão 1.0.2

Foi disparado o job `ca5-part1-rollback` selecionando o parâmetro `STABLE_VERSION=stable-v1.0.2`. A pipeline executou todas as fases com sucesso:

![Pipeline Stage View - Rollback no Green com Sucesso](images/ca5-p1-rollback-success.png)

Log de execução do Ansible na pipeline de rollback:

```text
PLAY [Rollback to an archived stable version on the green VM] ******************
TASK [bookstore_artifact : Jenkins credentials must come from the environment] ***
ok: [green]
TASK [bookstore_artifact : Download the archived artifact from Jenkins] ********
changed: [green]
TASK [bookstore_artifact : Stop the application currently running] *************
changed: [green]
TASK [bookstore_artifact : Point current.jar to the selected release] **********
changed: [green]
TASK [bookstore_artifact : Start the application] ******************************
changed: [green]
TASK [bookstore_artifact : Health check - /actuator/health must report UP] *****
ok: [green]
TASK [bookstore_artifact : Report] *********************************************
ok: [green] => {
    "msg": "green is running stable-v1.0.2 (Jenkins build 2)"
}
PLAY RECAP *********************************************************************
green                      : ok=14   changed=4    unreachable=0    failed=0
```

Verificação via HTTP GET após o rollback:
```bash
$ curl -s http://192.168.56.22:8080/info/details
{
  "_links": {
    "service": { "href": "bookstore-api" },
    "version": { "href": "1.0.2" },
    "environment": { "href": "green" },
    "buildTimestamp": { "href": "local-build" },
    "root": { "href": "http://192.168.56.22:8080/" }
  }
}
```

A VM `green` reverteu imediatamente para a versão `1.0.2` sem qualquer falha ou necessidade de recompilação do código.

---

## 5. Parte 2 — Multibranch, Docker Hub e Deploy em Produção

O objetivo da **Parte 2** é uma pipeline **Multibranch** que, a cada push em `development` ou `main` (disparado por **webhook do GitHub**), compila o Bookstore, executa **testes unitários e de integração em paralelo e em dois agentes**, constrói uma **imagem Docker** com uma tag única, publica-a no **Docker Hub** e, **apenas no branch `main`**, faz o deploy numa VM de produção com **Ansible**, seguido de health checks e notificação por email. Tal como na Parte 1 do CA4, a aplicação e a base de dados H2 correm **no mesmo contentor**.

### 5.1. Arquitetura e Nós

| Nó | IP | Sistema | Papel |
|---|---|---|---|
| **Host (Jenkins Controller / Built-In Node)** | `192.168.56.1:9090` | Windows 11 | Orquestração; executa também os **testes de integração** (execução distribuída) |
| **ctrl2 (Agente Jenkins `ca5-p2`)** | `192.168.56.30` | Ubuntu 24.04 (`bento/ubuntu-24.04`) | Gradle, Docker (build/push da imagem) e Ansible (deploy) |
| **prod (Produção)** | `192.168.56.31` | Ubuntu 24.04 | Docker Engine; corre o contentor `bookstore` na porta `8080` |

![Nós Jenkins: controller Windows e agente Linux ctrl2](images/ca5-p2-nodes.png)

Ficheiros da Parte 2:

```text
CA5/part2/
  .gitignore            # .vagrant/, keys/, secrets/, docker-test/
  Vagrantfile           # prod + ctrl2
  provision/ctrl2.sh    # Ansible, Docker, JDK 17 (Gradle) e JRE 21 (agente Jenkins)
  Dockerfile            # imagem do Bookstore com H2 embutida
  Jenkinsfile           # pipeline Multibranch
  ansible/
    ansible.cfg  hosts.ini  site.yml  deploy.yml
    group_vars/all.yml
    roles/docker/tasks/main.yml
```

**Decisões e justificações:**

1. **Agente Linux `ctrl2` + controller Windows:** o Ansible não corre em Windows; o `ctrl2` concentra Gradle, Docker e Ansible. O controller Windows (Built-In Node, 2 executores) corre os testes de integração em paralelo, demonstrando a execução distribuída. Por defeito o Jenkins recomenda 0 executores no controller; aqui são usados 2 propositadamente para este requisito.
2. **1 vCPU por VM:** com o Hyper-V ativo no Windows, o VirtualBox corre em modo NEM (`HM: HMR3Init: Attempting fall back to NEM: VT-x is not available` no `VBox.log`). Com 2 vCPUs a VM `prod` ficava presa no arranque em `Begin: Loading essential drivers ...` e o Vagrant terminava em *Timed out while waiting for the machine to boot*. Com 1 vCPU o arranque é fiável.
3. **Chaves SSH geradas pelo Vagrantfile e fora do Git:** `keys/` está no `.gitignore`. Num commit inicial as chaves foram incluídas por falta do `.gitignore`; foram removidas do índice (`git rm --cached`) e **regeneradas**, recriando as VMs, para que as chaves expostas no histórico deixassem de ter validade.
4. **Ferramenta Git por nó:** o Git do controller Windows está configurado como `git.exe`; no nó `ctrl2` foi definida uma *Tool Location* `(Git) Default = /usr/bin/git`, porque os dois nós têm sistemas operativos diferentes (sem isso o checkout falhava com `Cannot run program "git.exe"`).

### 5.2. Infraestrutura (Vagrant + Ansible)

* `Vagrantfile`: mesma box e mesma gestão de chaves da Parte 1; `prod` com a rede privada `192.168.56.31` e sem pasta partilhada; `ctrl2` com a pasta `CA5/part2` montada em `/vagrant` e o provisionamento `ansible_local` (`site.yml`).
* `provision/ctrl2.sh`: instala `ansible`, `docker.io`, `python3-docker`, `openjdk-17-jdk-headless` e `openjdk-21-jre-headless`; adiciona o utilizador `vagrant` ao grupo `docker` (o agente Jenkins corre como `vagrant`).
* `site.yml` → role `docker` na `prod`: Docker Engine, SDK Python (usado pela coleção `community.docker`) e `ufw` (só 22 e 8080 abertos). A aplicação **não** é arrancada aqui: é responsabilidade da pipeline.

Reprodução:

```bat
cd CA5\part2
vagrant up prod
vagrant up ctrl2
vagrant ssh ctrl2 -c "cd /vagrant/ansible && ansible all -m ping"
```

### 5.3. Imagem Docker (`CA5/part2/Dockerfile`)

```dockerfile
FROM eclipse-temurin:17-jre-alpine
ARG APP_VERSION=dev
ARG GIT_COMMIT=unknown
LABEL org.opencontainers.image.version="$APP_VERSION" org.opencontainers.image.revision="$GIT_COMMIT"
RUN addgroup -S bookstore && adduser -S -G bookstore -H -h /app -s /sbin/nologin bookstore \
 && mkdir -p /app/data && chown bookstore:bookstore /app/data
WORKDIR /app
COPY bookstore.jar /app/bookstore.jar
USER bookstore
VOLUME /app/data
EXPOSE 8080
ENV SPRING_DATASOURCE_URL=jdbc:h2:file:/app/data/bookstore SERVICE_ENVIRONMENT=production
HEALTHCHECK --interval=15s --timeout=3s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1
ENTRYPOINT ["java", "-jar", "/app/bookstore.jar"]
```

* **Não é multi-stage, de propósito (*build once, deploy many*):** a pipeline já compilou e testou o JAR; a imagem apenas o empacota, garantindo que o que chega à produção é exatamente o artefacto testado.
* **JRE Alpine e utilizador non-root** (como no CA4), **H2 em ficheiro num volume** (dados sobrevivem a redeploys), **labels OCI** com versão e commit (rastreabilidade imagem ↔ código) e **HEALTHCHECK**.

Teste manual da imagem no `ctrl2`, antes de a integrar na pipeline:

```text
$ docker ps --filter name=bs-test
CONTAINER ID   IMAGE                  ...   STATUS                        PORTS                    NAMES
db7ee0692f58   bookstore-test:local   ...   Up About a minute (healthy)   0.0.0.0:8085->8080/tcp   bs-test
$ curl -s localhost:8085/info/details
{"_links":{"service":{"href":"bookstore-api"},"version":{"href":"1.1.0"},"environment":{"href":"production"},...}}
$ docker exec bs-test id
uid=100(bookstore) gid=101(bookstore) groups=101(bookstore)
```

A versão vem de `-PappVersion` (alteração ao `CA1/part2/app/build.gradle`: `version = findProperty('appVersion') ?: '1.0.0'`).

### 5.4. Playbook de Deploy (`CA5/part2/ansible/deploy.yml`)

Executado pelo Jenkins no `ctrl2` com `ansible-playbook deploy.yml -e image=<user>/cogsi-ca5-bookstore -e image_tag=<tag>`; as credenciais do Docker Hub chegam apenas por variáveis de ambiente (`DH_USER`, `DH_TOKEN`) injetadas por `withCredentials`. Cobre os requisitos pela ordem:

| Requisito | Tarefa(s) |
|---|---|
| Garantir Docker instalado | `apt: docker.io, python3-docker` + `systemd: docker started/enabled` |
| Autenticar no Docker Hub e fazer pull da tag gerada | `community.docker.docker_login` (`no_log`) + `docker_image source: pull` |
| Parar e remover o contentor existente | `docker_container_info` (reporta a imagem a substituir) + `docker_container state: absent` |
| Arrancar novo contentor | `docker_container` com `restart_policy: unless-stopped`, porta `8080`, volume `bookstore-data` |
| Verificação | `uri /actuator/health` até `UP` (40 tentativas × 3 s); `docker_login state: absent`; `docker_prune images` |

### 5.5. Configuração do Jenkins

| Elemento | Configuração |
|---|---|
| Credenciais | `github-pat` (token *fine-grained*, só leitura do repositório), `dockerhub` (access token Read & Write), `ctrl2-ssh` (chave do agente), `smtp` (Mailtrap) |
| Agente `ctrl2` | *Launch agents via SSH*, host `192.168.56.30`, label `ca5-p2`, JavaPath `/usr/lib/jvm/java-21-openjdk-amd64/bin/java`, Tool Location Git `/usr/bin/git` |
| Built-In Node | 2 executores (label `built-in`) para os testes de integração |
| Job `ca5-part2` | *Multibranch Pipeline*, fonte GitHub, filtro de branches `main development`, Script Path `CA5/part2/Jenkinsfile` |
| Email | *Extended E-mail Notification* com SMTP do Mailtrap (sandbox) |

### 5.6. Pipeline (`CA5/part2/Jenkinsfile`)

| Stage | Onde | O que faz |
|---|---|---|
| Checkout | ctrl2 | `checkout scm` do branch que disparou o build |
| Assemble | ctrl2 | `./gradlew clean bootJar -PappVersion=1.1.<build>` |
| Test → Unit tests | ctrl2 | `./gradlew test` + `junit` |
| Test → Integration tests | controller Windows | `checkout scm` + `gradlew.bat integrationTest` + `junit` (em paralelo com os unitários) |
| Build and Tag Docker Image | ctrl2 | `docker build` com a tag única `<branch>-<build>` (ex.: `main-1`) |
| Archive | ctrl2 | `Dockerfile`, `build-metadata.json` (imagem, tag, versão, branch, commit, URL do build) e `image-inspect.json` |
| Push Docker Image | ctrl2 | `docker login --password-stdin` com a credencial `dockerhub`, `docker push`, `docker logout` |
| Deploy | ctrl2 | `when { branch 'main' }` → `ansible-playbook deploy.yml` |
| Post: success | ctrl2 | Em `main`: health checks a `/actuator/health`, `/info/details` (versão do build) e `/books`; email SUCCESS |
| Post: unstable / failure | — | Email UNSTABLE / FAILURE com o link para os resultados ou a consola |

Justificações:

* **Tag única `<branch>-<build>`:** uma tag publicada nunca é reescrita e o deploy usa exatamente a imagem do build; a tag inclui o branch porque cada branch do Multibranch tem a sua numeração.
* **`when { branch 'main' }`:** `development` executa build, testes e push, mas o stage Deploy é ignorado.
* **Testes em paralelo em workspaces separados:** cada ramo tem o seu checkout e a sua pasta `build/`, evitando conflitos entre execuções Gradle; o tempo do stage Test fica próximo do ramo mais lento em vez da soma dos dois.
* **Segredos:** só existem em Jenkins Credentials; o Jenkinsfile refere apenas IDs e o `withCredentials` mascara os valores nos logs.

### 5.7. Webhook do GitHub

O Jenkins está em `localhost:9090`, inacessível a partir da Internet. Foi exposto apenas através de um túnel **ngrok** com domínio estático:

```bat
ngrok http --domain=nag-trapezoid-scuff.ngrok-free.dev 9090
```

Webhook no GitHub: Payload URL `https://nag-trapezoid-scuff.ngrok-free.dev/github-webhook/`, `application/json`, *Just the push event*. A primeira configuração usava o URL sem `/github-webhook/` e o Jenkins respondia `403 No valid crumb was included in the request` (proteção CSRF); o endpoint `/github-webhook/` do plugin GitHub é o único que aceita pedidos do GitHub sem *crumb*.

Segurança: com o túnel o Jenkins fica exposto, por isso o acesso anónimo está desligado (*Logged-in users can do anything*, sem leitura anónima) e o registo de contas está desativado.

![Entrega do webhook no GitHub com sucesso](images/ca5-p2-webhook-delivery.png)

![Build disparado pelo push event recebido via webhook](images/ca5-p2-dev-build-cause.png)

### 5.8. Evidências

**Branch `development` (build #3):** testes unitários e de integração em paralelo, imagem `rochaprt/cogsi-ca5-bookstore:development-3` publicada e **Deploy ignorado**.

![Pipeline em development: testes em paralelo e Deploy ignorado](images/ca5-p2-dev-stage-view.png)

![Artefactos arquivados: Dockerfile e metadata do build](images/ca5-p2-dev-artifacts.png)

![Email de sucesso em development: Deployed to production false](images/ca5-p2-dev-email.png)

**Branch `main` (build #1):** mesmas stages, agora com **Deploy** executado.

![Pipeline em main: Deploy executado](images/ca5-p2-main-stage-view.png)

Consola do build: `PLAY RECAP` do Ansible sem falhas (`prod : ok=13 changed=5 failed=0`) e verificação pós-deploy (`production is healthy and running rochaprt/cogsi-ca5-bookstore:main-1`):

![Consola do deploy em main e health checks](images/ca5-p2-main-deploy-console.png)

A produção passou a servir a versão do build (`1.1.1`, ambiente `production`):

![info/details da VM prod](images/ca5-p2-prod-info.png)

![Email de sucesso em main: Deployed to production true](images/ca5-p2-main-email.png)

### 5.9. Reproduzir a Parte 2

1. `vagrant up prod` e `vagrant up ctrl2` em `CA5/part2`.
2. Arrancar o Jenkins (`JENKINS_HOME=C:\jenkins\home`, porta 9090) e confirmar o nó `ctrl2` online.
3. Arrancar o túnel ngrok (secção 5.7).
4. Fazer push para `development` (build sem deploy) e fazer merge para `main` (build com deploy).
5. Verificar `http://192.168.56.31:8080/info/details`.


---

## 6. Alternativa CI/CD — GitHub Actions

*(Em desenvolvimento na segunda fase do projeto — análise comparativa detalhada entre Jenkins e GitHub Actions, diagrama da arquitetura alternativa e implementação do workflow `.github/workflows/ca5-part2.yml`).*

---

## 7. Autoavaliação

| Membro da Equipa | Número de Estudante | Contribuição (%) | Responsabilidades Principais |
|---|---|---|---|
| **Tiago Fontes** | 1231013 | 50% | Configuração do Jenkins, nós distribuídos, Pipeline Parte 1, deployment Blue/Green e Rollback. |
| **Pedro Rocha** | 1220788 | 50% | Modelação da arquitetura, infraestrutura Docker, pipeline Multibranch Parte 2 e Alternativa. |
