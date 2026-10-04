# Bookstore (Ant + Ivy)

Este projeto é a **Bookstore REST API** (Spring Boot + Spring Data JPA + H2 + Spring HATEOAS) da Parte 2, construída com **Apache Ant** e **Apache Ivy** como alternativa ao Gradle.

A aplicação disponibiliza:

* Gestão de livros, clientes e encomendas (com relações entre si)
* Navegação na API baseada em HATEOAS
* Uma base de dados H2 em memória, inicializada programaticamente com dados de exemplo
* Uma consola H2 para inspeção da base de dados

## Objetivos do Projeto

Este projeto reproduz o build Gradle da Parte 2 com Ant, de forma a comparar as duas ferramentas. Serve para:

* Substituir o script de build Gradle (`build.gradle`) por um ficheiro de build Ant (`build.xml`)
* Gerir as dependências com Ivy (`ivy.xml`) em vez de um version catalog e de um BOM
* Escrever à mão os targets que o Gradle e os seus plugins fornecem (`compile`, `jar`, `run`, `installDist`)
* Recriar as tarefas personalizadas (`deployToDev`, `javadocZip`, `runDist`) como targets Ant
* Filtrar ficheiros de configuração em tempo de build (`filterset`)
* Separar os testes unitários dos testes de integração sem recorrer a um "source set"

## Pré-requisitos

Para construir e executar este projeto é necessário:

* Java JDK 17 ou superior, disponível no `PATH`
* Apache Ant 1.10.6 ou superior (necessário para a tarefa `junitlauncher`), com `ANT_HOME\bin` no `PATH`
* Acesso à Internet para a resolução de dependências (Maven Central)

Nota: o Ivy não precisa de ser instalado. O `build.xml` descarrega o JAR do Ivy para `ivy/` na primeira execução (um "wrapper" mínimo). O Ant tem de ser instalado manualmente e não existe toolchain: é usado o JDK que estiver no `PATH`.

## Estrutura do Projeto

```
alternative-ant-part2/
├── build.xml                  # Ficheiro de build com todos os targets (equivalente ao build.gradle)
├── ivy.xml                    # Dependências (equivalente ao libs.versions.toml + bloco dependencies)
├── .gitignore                 # Ignora build/, lib/ e ivy/
└── src/
    ├── main/java              # Código-fonte da Bookstore
    ├── main/resources         # application.properties (com placeholders)
    ├── test/java              # Testes unitários
    ├── integrationTest/java   # Testes de integração
    └── dist/bin               # Scripts de arranque (bookstore.bat e bookstore)
```

Pastas geradas (não incluídas no repositório):

* `ivy/` – o JAR do Ivy
* `lib/compile`, `lib/runtime`, `lib/test` – as dependências de cada configuração
* `build/` – classes compiladas, JAR, relatórios e outros artefactos

## Dependências

As dependências são declaradas no `ivy.xml` e agrupadas em três configurações:

| Configuração Ivy | Estende   | Equivalente Gradle                            |
|------------------|-----------|-----------------------------------------------|
| `compile`        | –         | `implementation` / `compileClasspath`         |
| `runtime`        | `compile` | `runtimeOnly` / `runtimeClasspath`            |
| `test`           | `runtime` | `testImplementation` / `testRuntimeClasspath` |

Sem o BOM do Spring Boot, todas as versões têm de ser escritas explicitamente. As versões do `h2` (2.3.232) e do `junit-platform-launcher` (1.12.2) foram retiradas do build Gradle:

```
cd ../part2
./gradlew :app:dependencies --configuration testRuntimeClasspath
```

Para descarregar as dependências para `lib/`:

```
ant resolve
```

A primeira execução demora alguns minutos. Depois disso, o `h2` aparece apenas em `lib/runtime` e `lib/test`, e o `mockito` apenas em `lib/test`.

## Build

Para construir o projeto:

```
ant clean build
```

Isto irá:

* Descarregar o Ivy (apenas na primeira execução) e resolver as dependências
* Compilar o código-fonte (com `-parameters`, necessário para o Spring)
* Copiar os recursos, substituindo os placeholders de configuração
* Gerar o JAR da aplicação (`build/libs/bookstore-1.0.0.jar`)
* Executar os testes unitários e de integração

Nota: não é gerado um fat JAR. O `bookstore-1.0.0.jar` contém apenas as classes da aplicação, tal como o `-plain.jar` produzido pelo Gradle.

`build` é o target por omissão, por isso `ant` sozinho faz o mesmo que `ant build`.

## Explorar os Targets Ant Disponíveis

Listar os targets principais (os que têm descrição):

```
ant -p
```

| Target            | Descrição                                                         |
|-------------------|-------------------------------------------------------------------|
| `resolve`         | Descarrega as dependências declaradas no `ivy.xml` para `lib/`    |
| `clean`           | Apaga a diretoria de build                                        |
| `compile`         | Compila a aplicação                                               |
| `jar`             | Empacota as classes da aplicação num JAR                          |
| `run`             | Executa a aplicação (equivalente ao `bootRun`)                    |
| `deployToDev`     | Faz o deploy do JAR, das bibliotecas de runtime e da configuração para `build/deployment/dev` |
| `javadoc`         | Gera o Javadoc                                                    |
| `javadocZip`      | Gera o Javadoc e empacota-o num zip                               |
| `installDist`     | Cria a distribuição em `build/install`                            |
| `runDist`         | Executa a aplicação através dos scripts da distribuição           |
| `test`            | Executa os testes unitários                                       |
| `integrationTest` | Executa os testes de integração                                   |
| `build`           | Compila, empacota e executa todos os testes                       |

É possível executar vários targets numa só chamada, por exemplo `ant clean jar javadocZip`.

## Executar

Para executar a aplicação:

```
ant run
```

A aplicação arranca em `http://localhost:8080` e continua em execução até ser parada com `Ctrl+C`.

Endpoints principais:

* `GET /` – ponto de entrada da API com links HATEOAS
* `GET /books`, `GET /clients`, `GET /orders`
* `GET /info/details` – nome do serviço, versão, ambiente e timestamp do build
* `GET /health`

Consola H2: `http://localhost:8080/h2-console`

* **JDBC URL**: `jdbc:h2:mem:bookstore`
* **Username**: `sa`
* **Password**: (deixar vazio)

## Placeholders de Configuração

Os metadados do serviço no `application.properties` usam placeholders que são substituídos pelo Ant através de um `filterset`:

```
service.version=@projectVersion@
service.environment=@environment@
service.build.timestamp=@buildTimestamp@
```

O `filterset` usa `@` como delimitador de tokens por omissão, por isso os placeholders da Parte 2 funcionam sem alterações (o filtro `ReplaceTokens` usado no Gradle é, ele próprio, uma classe do Ant).

* Nas execuções locais (`run`, testes, `jar`, `installDist`) são substituídos pelo `process-resources` com a versão do projeto, `local` e `local-build`.
* No deploy para dev (`deployToDev`) são substituídos com a versão do projeto, `dev` e o timestamp atual.

## Deploy para o Ambiente de Desenvolvimento

Para criar um deploy em `build/deployment/dev`:

```
ant deployToDev
```

Este target depende de quatro targets, executados da esquerda para a direita:

1. `deploy-clean` – apaga a diretoria de deploy
2. `deploy-app` – copia o JAR da aplicação
3. `deploy-libs` – copia as dependências de runtime para `lib/`
4. `deploy-config` – copia os ficheiros `.properties`, substituindo os placeholders

Estrutura resultante:

```
build/deployment/dev/
├── application.properties
├── bookstore-1.0.0.jar
└── lib/
```

Para executar a aplicação a partir da diretoria de deploy:

```
cd build/deployment/dev
java -cp "bookstore-1.0.0.jar:lib/*" com.example.bookstore.BookstoreApplication
```

Em Windows, substituir `:` por `;` como separador do classpath.

O `application.properties` externo tem precedência sobre o que está dentro do JAR, por isso o `/info/details` mostra `environment = dev` e o timestamp do deploy.

## Executar a partir da Distribuição

O Ant não tem um plugin `application`, por isso os scripts de arranque são escritos à mão em `src/dist/bin`. Para executar a aplicação através deles:

```
ant runDist
```

Este target depende do `installDist`, que cria `build/install/bookstore`:

```
build/install/bookstore/
├── bin/
│   ├── bookstore          # Linux/macOS
│   └── bookstore.bat      # Windows
└── lib/                   # JAR da aplicação + dependências de runtime
```

O `runDist` deteta o sistema operativo e executa `bin/bookstore.bat` em Windows ou `bin/bookstore` em Linux/macOS.

Notas:

* Os scripts usam um wildcard no classpath (`lib/*`), por isso o erro `The input line is too long` da Parte 2 não acontece.
* O `installDist` usa `fixcrlf` para dar a cada script os fins de linha corretos, porque o Git em Windows pode converter o script Unix para CRLF.
* Os scripts usam o `java` encontrado no `PATH` (não leem o `JAVA_HOME`).

## Javadoc

Para gerar o Javadoc e empacotá-lo num ficheiro zip:

```
ant javadocZip
```

A documentação é gerada em `build/docs/javadoc/index.html` e o arquivo em `build/docs-zip/bookstore-1.0.0-javadoc.zip`.

## Testes

Executar apenas os testes unitários:

```
ant test
```

Executar apenas os testes de integração (que arrancam o contexto Spring completo):

```
ant integrationTest
```

Executar ambos (e empacotar a aplicação):

```
ant build
```

Os testes são executados numa JVM separada (`<fork>`), tal como o Gradle faz por omissão.

Relatórios de testes:

* Testes unitários: relatórios XML em `build/reports/tests/test`
* Testes de integração: relatórios XML em `build/reports/tests/integrationTest` e um relatório HTML em `build/reports/tests/integrationTest/html/junit-noframes.html`

## Comparação com o Gradle

| Funcionalidade              | Gradle (Parte 2)                                   | Ant + Ivy                                            |
|-----------------------------|----------------------------------------------------|------------------------------------------------------|
| Instalação da ferramenta    | Gradle Wrapper (`gradlew`)                         | Ant instalado manualmente; Ivy descarregado pelo `build.xml` |
| Versões das dependências    | Geridas pelo BOM do Spring Boot                    | Escritas explicitamente no `ivy.xml`                 |
| Tarefas standard            | Fornecidas pelos plugins `java`, `application` e Spring Boot | Escritas à mão (`compile`, `jar`, `run`, ...)        |
| Flag `-parameters`          | Adicionada automaticamente pelo plugin Spring Boot | Tem de ser adicionada ao `<javac>`                   |
| JAR executável              | `bootJar` (fat JAR)                                | Apenas o JAR simples                                 |
| Scripts de arranque         | Gerados pelo `installDist`                         | Escritos à mão em `src/dist/bin`                     |
| Testes de integração        | Source set dedicado                                | Um `<javac>` e um `<junitlauncher>` extra com classpaths manuais |
| Ordem das tarefas           | `dependsOn` + `mustRunAfter`                       | Ordem da lista `depends`                             |
| Build incremental/cache     | Verificações up-to-date e build cache              | Sem build cache; os targets correm em cada invocação (algumas tarefas, como `<javac>` e `<copy>`, apenas ignoram ficheiros inalterados) |
