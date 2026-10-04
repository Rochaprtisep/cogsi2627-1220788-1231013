# CA1 - Build Tools

## Part 1 - Exploring Gradle

Este relatório técnico descreve a análise, configuração e execução das tarefas propostas para a Parte 1 do CA1, utilizando o Gradle como ferramenta de build. Em conformidade com o formato de tutorial exigido, documentam-se abaixo os passos, comandos e opções adotadas.

### 1. Ciclo de Vida do Build e Tarefas
O comando `.\gradlew tasks` permite explorar as tarefas disponíveis no projeto, organizando-as por grupos lógicos (como *build*, *documentation* ou *verification*). 

O Gradle opera num ciclo de vida composto por três fases principais: Inicialização, Configuração e Execução. Quando executamos uma tarefa complexa como o `build`, o Gradle determina o grafo de tarefas necessárias e executa-as de forma sequencial. Por exemplo, o ciclo típico para compilar e testar código Java segue o fluxo: `compileJava` -> `processResources` -> `classes` -> `jar` -> `test` -> `build`.

**Output do comando `.\gradlew tasks`:**

    Welcome to Gradle 9.4.0!
    
    Here are the highlights of this release:
     - Java 26 support
     - Non-class-based JVM tests
     - Enhanced console progress bar
    
    For more details see https://docs.gradle.org/9.4.0/release-notes.html
    
    Starting a Gradle Daemon (subsequent builds will be faster)
    Calculating task graph as no cached configuration is available for tasks: tasks
    
    > Task :tasks
    
    ------------------------------------------------------------
    Tasks runnable from root project 'gradle_demo'
    ------------------------------------------------------------
    
    Application tasks
    -----------------
    run - Runs this project as a JVM application
    
    Build tasks
    -----------
    assemble - Assembles the outputs of this project.
    build - Assembles and tests this project.
    buildDependents - Assembles and tests this project and all projects that depend on it.
    buildNeeded - Assembles and tests this project and all projects it depends on.
    classes - Assembles main classes.
    clean - Deletes the build directory.
    cleanLogs - Deletes log files from the build directory
    copyDependencies - Copies runtime dependencies to the application lib directory
    jar - Assembles a jar archive containing the classes of the 'main' feature.
    packageApp - Builds the JAR and copies runtime dependencies
    testClasses - Assembles test classes.
    
    Build Setup tasks
    -----------------
    init - Initializes a new Gradle build.
    updateDaemonJvm - Generates or updates the Gradle Daemon JVM criteria.
    wrapper - Generates Gradle wrapper files.
    
    DevOps tasks
    ------------
    runClient - Launches the chat client and connects it to a chat server
    
    Distribution tasks
    ------------------
    assembleDist - Assembles the main distributions
    distTar - Bundles the project as a distribution.
    distZip - Bundles the project as a distribution.
    installDist - Installs the project as a distribution as-is.
    
    Documentation tasks
    -------------------
    javadoc - Generates Javadoc API documentation for the 'main' feature.
    
    Help tasks
    ----------
    artifactTransforms - Displays the Artifact Transforms that can be executed in root project 'gradle_demo'.
    buildEnvironment - Displays all buildscript dependencies declared in root project 'gradle_demo'.
    dependencies - Displays all dependencies declared in root project 'gradle_demo'.
    dependencyInsight - Displays the insight into a specific dependency in root project 'gradle_demo'.
    help - Displays a help message.
    javaToolchains - Displays the detected java toolchains.
    outgoingVariants - Displays the outgoing variants of root project 'gradle_demo'.
    printProjectInfo - Displays basic project and build information
    projects - Displays the sub-projects of root project 'gradle_demo'.
    properties - Displays the properties of root project 'gradle_demo'.
    resolvableConfigurations - Displays the configurations that can be resolved in root project 'gradle_demo'.
    tasks - Displays the tasks runnable from root project 'gradle_demo' (some of the displayed tasks may belong to subprojects).
    
    Verification tasks
    ------------------
    check - Runs all checks.
    test - Runs the test suite.
    
    To see all tasks and more detail, run gradlew tasks --all
    
    To see more detail about a task, run gradlew help --task <task>
    
    BUILD SUCCESSFUL in 17s
    1 actionable task: 1 executed
    Configuration cache entry stored.


### 2. Árvore de Dependências
Para inspecionar o grafo de dependências e compreender como as bibliotecas externas são resolvidas, utilizou-se o comando `.\gradlew dependencies`. 

A resolução é feita automaticamente a partir dos repositórios configurados (como o Maven Central), garantindo que todas as bibliotecas necessárias para a compilação e execução estão presentes. O comando demonstra a árvore de dependências do projeto raiz.

**Output do comando `.\gradlew dependencies`:**

    PS C:\Users\tiago\Desktop\Mestrado\COGSI\cogsi2627-1220788-1231013\CA1\part1> .\gradlew dependencies
    Calculating task graph as no cached configuration is available for tasks: dependencies
    
    > Task :dependencies
    
    ------------------------------------------------------------
    Root project 'gradle_demo'
    ------------------------------------------------------------
    
    No configurations
    
    A web-based, searchable dependency report is available by adding the --scan option.
    
    BUILD SUCCESSFUL in 842ms
    1 actionable task: 1 executed
    Configuration cache entry stored.


### 3. Gradle Wrapper e JDK Toolchain
Para garantir a consistência do ambiente de desenvolvimento entre todos os membros da equipa, utilizou-se o Gradle Wrapper e a JDK Toolchain.

* **Gradle Wrapper:** O uso dos scripts `gradlew` e do ficheiro `gradle-wrapper.properties` fixa a versão do Gradle utilizada no projeto (versão 9.4.0). Na primeira execução, o Wrapper descarrega automaticamente essa versão exata. Isto evita a necessidade de instalar o Gradle manualmente no sistema operativo, garantindo que todos os developers e os servidores de Integração Contínua (CI) usam exatamente a mesma ferramenta.
* **JDK Toolchain:** A Toolchain faz o mesmo para o Java. Ao declararmos a versão da linguagem (Java 21), o Gradle verifica se esse JDK está disponível na máquina. Caso não esteja, o plugin configurado descarrega-o e provisiona-o automaticamente, eliminando configurações manuais na máquina. 

O output abaixo comprova que as funcionalidades de *Auto-detection* e *Auto-download* estão ativas, e lista as várias versões do Java detetadas localmente.

**Output do comando `.\gradlew javaToolchains`:**

    PS C:\Users\tiago\Desktop\Mestrado\COGSI\cogsi2627-1220788-1231013\CA1\part1> .\gradlew javaToolchains
    Calculating task graph as no cached configuration is available for tasks: javaToolchains
    
    > Task :javaToolchains
    
     + Options
         | Auto-detection:     Enabled
         | Auto-download:      Enabled
    
     + Oracle JRE 8 (1.8.0_441-b07)
         | Location:           C:\Program Files\Java\jre1.8.0_441
         | Language Version:   8
         | Vendor:             Oracle
         | Architecture:       amd64
         | Is JDK:             false
         | Detected by:        Windows Registry
    
     + Amazon Corretto JDK 11 (11.0.22+7-LTS)
         | Location:           C:\Users\tiago\.jdks\corretto-11.0.22
         | Language Version:   11
         | Vendor:             Amazon Corretto
         | Architecture:       amd64
         | Is JDK:             true
         | Detected by:        IntelliJ
    
     + OpenJDK JDK 21 (21+35-2513)
         | Location:           C:\Users\tiago\.jdks\openjdk-21
         | Language Version:   21
         | Vendor:             Oracle
         | Architecture:       amd64
         | Is JDK:             true
         | Detected by:        IntelliJ
    
     + Oracle JDK 21 (21.0.1+12-LTS-29)
         | Location:           C:\Program Files\Java\jdk-21
         | Language Version:   21
         | Vendor:             Oracle
         | Architecture:       amd64
         | Is JDK:             true
         | Detected by:        Current JVM
    
     + OpenJDK JDK 22 (22.0.1+8-16)
         | Location:           C:\Users\tiago\.jdks\openjdk-22.0.1
         | Language Version:   22
         | Vendor:             Oracle
         | Architecture:       amd64
         | Is JDK:             true
         | Detected by:        IntelliJ
    
     + OpenJDK JDK 23 (23+37-2369)
         | Location:           C:\Users\tiago\.jdks\openjdk-23
         | Language Version:   23
         | Vendor:             Oracle
         | Architecture:       amd64
         | Is JDK:             true
         | Detected by:        IntelliJ
    
     + Oracle JDK 24 (24+36-3646)
         | Location:           C:\Program Files\Java\jdk-24
         | Language Version:   24
         | Vendor:             Oracle
         | Architecture:       amd64
         | Is JDK:             true
         | Detected by:        Windows Registry
    
    
    BUILD SUCCESSFUL in 1s
    1 actionable task: 1 executed
    Configuration cache entry stored.


### 4. Implementação de Tarefas Personalizadas
Durante a execução prática, configurou-se e expandiu-se o projeto base com as seguintes adições:

1. **runServer:** Registou-se uma nova tarefa do tipo `JavaExec` no ficheiro `build.gradle` para iniciar o servidor de chat e permitir a conexão do cliente.
2. **Testes Unitários:** O catálogo de versões (`libs.versions.toml`) foi atualizado com o JUnit 5 e Log4j2. Após a injeção das respetivas dependências, validou-se com sucesso a execução da classe `AppTest.java` através da ferramenta de testes do Gradle.
3. **Backup e Zip:** Criou-se a tarefa `backupSources` baseada no tipo nativo `Copy` para salvaguardar exclusivamente as diretorias de código. Para arquivar esta cópia de segurança, implementou-se a tarefa `zipBackup` (tipo `Zip`), assegurando a correta ordem de execução através da dependência explícita (`dependsOn tasks.named('backupSources')`).



## Part 2 - Spring Boot com Gradle

Este relatório técnico descreve a conversão do projeto **Bookstore REST API** (Spring Boot + Spring Data JPA + H2 + Spring HATEOAS) de Maven para Gradle e a implementação das tarefas propostas para a Parte 2 do CA1. Tal como na Parte 1, documentam-se abaixo os passos, comandos e opções adotadas. O código encontra-se na pasta `part2`.

### 1. Estrutura do Projeto e Conversão de Maven para Gradle
O projeto foi criado com `gradle init` como uma *multi-project build*, com o projeto raiz `bookstore` e o subprojeto `app`, onde fica o código da aplicação:

    part2/
    ├── settings.gradle                # Projeto raiz + subprojeto 'app' + plugin foojay
    ├── gradle.properties              # Ativa o configuration cache
    ├── gradle/libs.versions.toml      # Catálogo de versões (dependências e plugins)
    ├── gradlew / gradlew.bat          # Gradle Wrapper (9.4.0)
    └── app/
        ├── build.gradle               # Script de build com as tarefas personalizadas
        └── src/
            ├── main/java              # Código da Bookstore
            ├── main/resources         # application.properties (com placeholders)
            ├── test/java              # Testes unitários
            └── integrationTest/java   # Testes de integração (source set próprio)

A conversão do `pom.xml` para o `build.gradle` assentou nos seguintes pontos:

* **Plugins:** `java`, `application`, `org.springframework.boot` e `io.spring.dependency-management`. O plugin do Spring Boot substitui o *parent* do Maven e acrescenta as tarefas `bootRun` e `bootJar`.
* **JDK Toolchain:** a versão do Java foi fixada em 17. O plugin `foojay-resolver-convention`, declarado no `settings.gradle`, descarrega este JDK caso não exista na máquina.
* **Nome dos artefactos:** através de `base { archivesName = 'bookstore' }`, os JARs passam a chamar-se `bookstore-1.0.0.jar` (o *fat JAR* do Spring Boot) e `bookstore-1.0.0-plain.jar` (apenas as classes da aplicação).

### 2. Catálogo de Versões e Gestão de Dependências
As dependências e os plugins foram declarados no catálogo de versões `gradle/libs.versions.toml`. As quatro *starters* da aplicação foram agrupadas num *bundle*, o que simplifica o bloco `dependencies` do `build.gradle`:

    dependencies {
        implementation libs.bundles.spring.boot.app
        runtimeOnly libs.h2

        testImplementation libs.spring.boot.starter.test
        testRuntimeOnly libs.junit.platform.launcher
    }

As bibliotecas foram declaradas **sem versão**. A única versão escrita no catálogo é a do Spring Boot (3.5.9); as restantes são escolhidas pelo BOM do Spring Boot, aplicado pelo plugin `io.spring.dependency-management`, o que garante que todas as bibliotecas são compatíveis entre si. Também se respeitaram os *scopes* do Maven: o H2 só é necessário em execução (`runtimeOnly`) e as bibliotecas de teste só ficam no classpath dos testes.

O comando abaixo mostra as versões escolhidas pelo BOM para o H2 e para o JUnit Platform Launcher (a seta `->` indica a versão resolvida):

**Output do comando `.\gradlew :app:dependencies --configuration testRuntimeClasspath | findstr "junit-platform-launcher h2database"`:**

    +--- com.h2database:h2 -> 2.3.232
    |    |    |    +--- org.junit.platform:junit-platform-launcher:1.12.2 (c)
    |    \--- org.junit.platform:junit-platform-launcher -> 1.12.2
    \--- org.junit.platform:junit-platform-launcher -> 1.12.2 (*)

### 3. Build e Execução da Aplicação
Para compilar, testar e empacotar o projeto:

    .\gradlew clean build

Para arrancar a aplicação:

    .\gradlew bootRun

A aplicação fica disponível em `http://localhost:8080`. A tarefa mantém-se em execução (a barra de progresso fica nos ~80%) até o servidor ser parado com `Ctrl+C`, porque um servidor web corre indefinidamente. Os principais endpoints são `/`, `/books`, `/clients`, `/orders`, `/info/details` e `/health`, e a consola do H2 está em `/h2-console` (JDBC URL `jdbc:h2:mem:bookstore`, utilizador `sa`, sem password).

**Output do comando `.\gradlew clean build`:**

    > Task :app:clean
    > Task :app:processTestResources NO-SOURCE
    > Task :app:processIntegrationTestResources NO-SOURCE
    > Task :app:processResources
    > Task :app:compileJava
    > Task :app:classes
    > Task :app:resolveMainClassName
    > Task :app:jar
    > Task :app:compileTestJava
    > Task :app:testClasses
    > Task :app:bootJar
    > Task :app:startScripts
    > Task :app:bootStartScripts
    > Task :app:distTar
    > Task :app:bootDistTar
    > Task :app:compileIntegrationTestJava
    > Task :app:integrationTestClasses
    > Task :app:test
    > Task :app:bootDistZip
    > Task :app:distZip
    > Task :app:assemble
    > Task :app:integrationTest
    > Task :app:check
    > Task :app:build

    BUILD SUCCESSFUL in 33s
    16 actionable tasks: 16 executed
    Configuration cache entry stored.

### 4. Substituição de Placeholders na Configuração
Os metadados do serviço no `application.properties` passaram a usar *placeholders*, que são substituídos durante o build:

    service.version=@projectVersion@
    service.environment=@environment@
    service.build.timestamp=@buildTimestamp@

O `InfoController` foi alterado para ler também o `service.build.timestamp` e expô-lo em `GET /info/details`.

A substituição é feita com o filtro `ReplaceTokens` (uma classe do Ant que o Gradle reutiliza), aplicado em dois sítios:

* **Execuções locais:** a tarefa `processResources` substitui os *placeholders* pela versão do projeto, por `local` e por `local-build`. Assim, o `bootRun`, os testes e o `installDist` usam sempre valores locais. Os valores são registados com `inputs.properties(...)` para que o Gradle saiba quando tem de voltar a executar a tarefa.
* **Deployment em dev:** a tarefa `copyConfigToDev` (secção seguinte) usa `dev` e o timestamp do momento do deployment.

### 5. Tarefa `deployToDev`
Foi criada a tarefa `deployToDev`, no grupo `deployment`, que orquestra quatro tarefas baseadas em tipos nativos do Gradle:

1. **`cleanDevDeployment`** (`Delete`): apaga a pasta `build/deployment/dev`.
2. **`copyAppToDev`** (`Copy`): copia o JAR da aplicação (o resultado da tarefa `jar`).
3. **`copyLibsToDev`** (`Copy`): copia para `lib/` apenas as dependências de execução (`configurations.runtimeClasspath`).
4. **`copyConfigToDev`** (`Copy`): copia os ficheiros `.properties` e substitui os *placeholders* pelos valores de dev.

As três tarefas de cópia dependem de `cleanDevDeployment` (`dependsOn`), e a ordem entre elas é garantida com `mustRunAfter`.

O timestamp criou um problema com o *configuration cache* (ativo em `gradle.properties`): o valor era calculado na fase de configuração e, ao reutilizar a cache, todos os deployments ficavam com o mesmo timestamp. A solução foi marcar a tarefa com `notCompatibleWithConfigurationCache(...)`, o que obriga o Gradle a voltar a calcular o timestamp em cada deployment.

**Output do comando `.\gradlew tasks --group deployment`:**

    Deployment tasks
    ----------------
    cleanDevDeployment - Deletes the dev deployment directory.
    copyAppToDev - Copies the application jar to the dev deployment directory.
    copyConfigToDev - Copies the .properties files to the dev deployment, replacing tokens.
    copyLibsToDev - Copies the runtime dependencies to the lib folder.
    deployToDev - Deploys the jar, runtime libs and config to build/deployment/dev.

**Output do comando `.\gradlew deployToDev`:**

    > Task :app:cleanDevDeployment UP-TO-DATE
    > Task :app:compileJava UP-TO-DATE
    > Task :app:processResources UP-TO-DATE
    > Task :app:classes UP-TO-DATE
    > Task :app:jar UP-TO-DATE
    > Task :app:copyAppToDev
    > Task :app:copyLibsToDev
    > Task :app:copyConfigToDev

    > Task :app:deployToDev
    Bookstore deployed to: ...\CA1\part2\app\build\deployment\dev

    BUILD SUCCESSFUL in 4s
    8 actionable tasks: 4 executed, 4 up-to-date
    Configuration cache entry discarded because incompatible task was found: 'task `:app:copyConfigToDev` of type `org.gradle.api.tasks.Copy`'.

A última linha confirma que o *configuration cache* é descartado por causa da `copyConfigToDev`, como pretendido. O conteúdo resultante da pasta `app/build/deployment/dev` é:

    lib
    application.properties
    bookstore-1.0.0-plain.jar

E o `application.properties` já tem os valores de dev:

    service.version=1.0.0
    service.environment=dev
    service.build.timestamp=2026-10-04T15:38:46.6528764+01:00

Para correr a aplicação a partir do deployment:

    cd app\build\deployment\dev
    java -cp "bookstore-1.0.0-plain.jar;lib/*" com.example.bookstore.BookstoreApplication

O `application.properties` externo tem prioridade sobre o que está dentro do JAR, por isso `/info/details` mostra `dev` e o timestamp do deployment.

### 6. Tarefa `runDist`
O plugin `application` gera, com a tarefa `installDist`, uma distribuição em `app/build/install/bookstore` com os scripts de arranque (`bin/bookstore` e `bin/bookstore.bat`) e todas as dependências em `lib/`.

Foi criada a tarefa `runDist` (tipo `Exec`, grupo `application`), que depende de `installDist` e escolhe o script de acordo com o sistema operativo: `cmd /c bin\bookstore.bat` no Windows e `sh bin/bookstore` em Linux/macOS.

No Windows, o script `.bat` gerado falhava com o erro `The input line is too long`, porque o classpath listava os cerca de 80 JARs um a um. Para o resolver, acrescentou-se um `doLast` à tarefa `startScripts` que substitui a linha `set CLASSPATH=...` por `set CLASSPATH=%APP_HOME%\lib\*` (um *wildcard* de classpath).

**Output do comando `.\gradlew tasks --group application`:**

    bootRun - Runs this project as a Spring Boot application.
    bootTestRun - Runs this project as a Spring Boot application using the test runtime classpath.
    run - Runs this project as a JVM application
    runDist - Runs the application using the start script generated by installDist.

### 7. Tarefa `javadocZip`
A tarefa `javadoc` foi configurada para documentar também os membros privados (`JavadocMemberLevel.PRIVATE`) e para não interromper o build por causa de avisos (`failOnError = false`). Foi criada a tarefa `javadocZip` (tipo `Zip`, grupo `documentation`), que usa o resultado da `javadoc` e gera `app/build/docs-zip/bookstore-1.0.0-javadoc.zip`.

**Output do comando `.\gradlew javadocZip`:**

    > Task :app:processResources UP-TO-DATE
    > Task :app:compileJava UP-TO-DATE
    > Task :app:classes UP-TO-DATE

    > Task :app:javadoc
    ...\controller\BookController.java:19: warning: no comment
        private final BookModelAssembler assembler;
    ...
    6 warnings

    > Task :app:javadocZip

    BUILD SUCCESSFUL in 6s
    4 actionable tasks: 2 executed, 2 up-to-date

Os seis avisos referem-se a campos privados sem comentário e não interrompem o build, graças ao `failOnError = false`.

### 8. Testes Unitários e de Integração
Foi acrescentado um teste unitário (`BookTest`, em `src/test/java`) e um teste de integração (`BookstoreApiIntegrationTest`, em `src/integrationTest/java`). O teste de integração arranca o contexto completo do Spring (`@SpringBootTest` + `@AutoConfigureMockMvc`) e verifica que `/books` devolve os dados de exemplo e que `/info/details` expõe a versão substituída pelo build.

Para separar os dois tipos de teste, criou-se um *source set* `integrationTest`:

* O *source set* tem acesso às classes da aplicação (`sourceSets.main.output`).
* As configurações `integrationTestImplementation` e `integrationTestRuntimeOnly` estendem as da aplicação e dos testes, por isso herdam todas as dependências sem as repetir.
* A tarefa `integrationTest` (tipo `Test`) corre os testes deste *source set* depois dos testes unitários (`shouldRunAfter`).
* A tarefa `check` passou a depender de `integrationTest`, por isso `.\gradlew build` corre os dois tipos de teste, como se vê no output da secção 3.

**Output do comando `.\gradlew tasks --group verification`:**

    check - Runs all checks.
    integrationTest - Runs the integration tests.
    test - Runs the test suite.

Para correr os testes:

    .\gradlew test
    .\gradlew integrationTest
    .\gradlew check

Os relatórios ficam em `app/build/reports/tests/test/index.html` e `app/build/reports/tests/integrationTest/index.html`.

**Reflexão Prática:**
A Parte 2 mostrou o valor dos plugins e do BOM do Spring Boot. Bastou declarar a versão do Spring Boot para que todas as outras bibliotecas ficassem compatíveis entre si, e o plugin tratou de pormenores como a opção `-parameters` do compilador e a geração do *fat JAR*. As tarefas personalizadas foram construídas sobretudo a partir de tipos nativos (`Delete`, `Copy`, `Zip`, `Exec`, `Test`), o que torna o `build.gradle` curto e legível.

As principais dificuldades vieram de funcionalidades avançadas do Gradle. O *configuration cache* acelera os builds, mas obrigou a ter cuidado com valores calculados na fase de configuração, como o timestamp do deployment. No Windows, os scripts gerados pelo `installDist` também precisaram de um ajuste manual para não ultrapassarem o limite de tamanho da linha de comandos.


## Alternativa Tecnológica: Apache Ant

Esta secção e a seguinte dedicam-se à apresentação, análise e implementação de uma solução alternativa ao Gradle para a automação do projeto, com o objetivo de demonstrar as diferenças práticas entre as ferramentas[cite: 16].

### Análise e Comparação com Gradle
Para explorar uma ferramenta de build que não seja baseada no ecossistema Gradle, o Apache Ant foi selecionado como alternativa[cite: 25]. O Ant é uma ferramenta clássica na qual as instruções de automação são configuradas através de um ficheiro XML (`build.xml`), o que contrasta com a abordagem baseada em código e scripts declarativos (Groovy/Kotlin) do Gradle.

*   **Extensibilidade e Customização:** A comparação de como as ferramentas podem ser estendidas evidencia grandes diferenças de arquitetura[cite: 25]. No Gradle, a extensibilidade flui naturalmente através da programação direta nos ficheiros de build ou pela injeção rápida de *plugins* modernos e altamente configuráveis. No Ant, a extensão requer a definição de `<macrodef>` para blocos de XML reutilizáveis, ou a programação de *Custom Tasks* puras em Java que, posteriormente, precisam de ser registadas no ficheiro XML através da tag `<taskdef>`[cite: 25].
*   **Gestão de Dependências:** A base deste CA1 assenta em dependências como o JUnit 5 e Log4j2. Enquanto o Gradle possui um motor robusto de resolução de dependências transitivas, o Ant (na sua forma base) não tem essa capacidade. Para resolver dependências de rede no Ant, seria necessário importar fisicamente os ficheiros `.jar` para o projeto ou acoplar uma segunda ferramenta dedicada (o Apache Ivy).

### Design da Solução Alternativa
Para solucionar os mesmos requisitos da Parte 1 utilizando puramente o Ant[cite: 25], o design estrutural do ficheiro `build.xml` assentaria nos seguintes *targets*:

1. **`runServer`:** Empregar a tarefa nativa `<java>` do Ant para arrancar o processo, definindo o atributo `classname` para a aplicação servidora e passando a respetiva porta via `<arg>`.
2. **Testes Unitários:** Utilizar a *task* `<junitlauncher>` do Ant (suporte moderno para JUnit 5), especificando o `classpath` manual para os ficheiros JAR do Log4j2 e do JUnit previamente transferidos.
3. **Backup e Archive (DevOps):**
   * Configuração de um target de backup usando a *task* nativa `<copy>`, instruindo o uso de um `<fileset>` que englobe explicitamente as diretorias `src/main` e `src/test`.
   * Criação do target final usando a *task* `<zip>`, garantindo a execução sequencial correta através da inclusão do atributo `depends="nome_do_target_de_backup"`.

**Reflexão Prática:** 
A implementação do Backup e Zip em Ant (`build.xml`) demonstrou que a ferramenta é mais verbosa e obriga a passos imperativos. Ao contrário do Gradle, que infere a criação de pastas automaticamente nas tarefas de cópia, no Ant tivemos de usar `<mkdir>` para as criar à mão antes de mover os ficheiros. 

A maior diferença notada na prática, no entanto, foi a ausência de um "Wrapper". Ao tentar executar o script, o terminal não reconheceu o comando porque o Apache Ant exige instalação e configuração manual prévia no sistema operativo. Isto contrasta fortemente com o script `gradlew` usado na Parte 1, que garante que qualquer developer consegue correr o projeto de imediato, provando a superioridade do Gradle na padronização e partilha de projetos em equipa.