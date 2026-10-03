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
