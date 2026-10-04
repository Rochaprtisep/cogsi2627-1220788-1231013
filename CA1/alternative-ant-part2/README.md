# Bookstore (Ant + Ivy)

This project is the **Bookstore REST API** (Spring Boot + Spring Data JPA + H2 + Spring HATEOAS) from Part 2, built with **Apache Ant** and **Apache Ivy** as an alternative to Gradle.

The application provides:

* Management of books, clients and orders (with relationships)
* HATEOAS-based API navigation
* An in-memory H2 database, initialised programmatically with sample data
* An H2 console for database inspection

## Project Goals

This project reproduces the Part 2 Gradle build with Ant, to compare both tools. It is used to:

* Replace the Gradle build script (`build.gradle`) with an Ant build file (`build.xml`)
* Manage dependencies with Ivy (`ivy.xml`) instead of a version catalog and a BOM
* Write by hand the targets that Gradle and its plugins provide (`compile`, `jar`, `run`, `installDist`)
* Recreate the custom tasks (`deployToDev`, `javadocZip`, `runDist`) as Ant targets
* Filter configuration files at build time (`filterset`)
* Separate unit tests from integration tests without a "source set"

## Prerequisites

To build and run this project, you need:

* Java JDK 17 or later, available in the `PATH`
* Apache Ant 1.10.6 or later (needed for the `junitlauncher` task), with `ANT_HOME\bin` in the `PATH`
* Internet access for dependency resolution (Maven Central)

Note: Ivy does not need to be installed. The `build.xml` downloads the Ivy JAR into `ivy/` on the first run (a minimal "wrapper"). Ant itself must be installed manually, and there is no toolchain: the JDK in the `PATH` is used.

## Project Structure

```
alternative-ant-part2/
├── build.xml                  # Build file with all targets (equivalent to build.gradle)
├── ivy.xml                    # Dependencies (equivalent to libs.versions.toml + dependencies block)
├── .gitignore                 # Ignores build/, lib/ and ivy/
└── src/
    ├── main/java              # Bookstore source code
    ├── main/resources         # application.properties (with placeholders)
    ├── test/java              # Unit tests
    ├── integrationTest/java   # Integration tests
    └── dist/bin               # Start scripts (bookstore.bat and bookstore)
```

Generated folders (not committed):

* `ivy/` – the Ivy JAR
* `lib/compile`, `lib/runtime`, `lib/test` – the dependencies of each configuration
* `build/` – compiled classes, JAR, reports and other artefacts

## Dependencies

Dependencies are declared in `ivy.xml` and grouped into three configurations:

| Ivy configuration | Extends   | Gradle equivalent                         |
|-------------------|-----------|-------------------------------------------|
| `compile`         | –         | `implementation` / `compileClasspath`     |
| `runtime`         | `compile` | `runtimeOnly` / `runtimeClasspath`        |
| `test`            | `runtime` | `testImplementation` / `testRuntimeClasspath` |

Without the Spring Boot BOM, every version must be written explicitly. The versions of `h2` (2.3.232) and `junit-platform-launcher` (1.12.2) were taken from the Gradle build:

```
cd ../part2
./gradlew :app:dependencies --configuration testRuntimeClasspath
```

To download the dependencies into `lib/`:

```
ant resolve
```

The first run takes a few minutes. Afterwards, `h2` appears only in `lib/runtime` and `lib/test`, and `mockito` only in `lib/test`.

## Build

To build the project:

```
ant clean build
```

This will:

* Download Ivy (first run only) and resolve the dependencies
* Compile the source code (with `-parameters`, required by Spring)
* Copy the resources, replacing the configuration placeholders
* Generate the application JAR (`build/libs/bookstore-1.0.0.jar`)
* Run the unit and integration tests

Note: there is no fat JAR. `bookstore-1.0.0.jar` contains only the application classes, like the `-plain.jar` produced by Gradle.

`build` is the default target, so `ant` alone does the same as `ant build`.

## Exploring Available Ant Targets

List the main targets (those with a description):

```
ant -p
```

| Target            | Description                                               |
|-------------------|-----------------------------------------------------------|
| `resolve`         | Downloads the dependencies declared in `ivy.xml` into `lib/` |
| `clean`           | Deletes the build directory                               |
| `compile`         | Compiles the application                                  |
| `jar`             | Packages the application classes into a JAR               |
| `run`             | Runs the application (equivalent to `bootRun`)            |
| `deployToDev`     | Deploys the JAR, runtime libs and config to `build/deployment/dev` |
| `javadoc`         | Generates the Javadoc                                     |
| `javadocZip`      | Generates the Javadoc and packages it into a zip          |
| `installDist`     | Creates the distribution in `build/install`               |
| `runDist`         | Runs the application using the distribution scripts       |
| `test`            | Runs the unit tests                                       |
| `integrationTest` | Runs the integration tests                                |
| `build`           | Compiles, packages and runs all tests                     |

Several targets can be run in one call, for example `ant clean jar javadocZip`.

## Run

To run the application:

```
ant run
```

The application starts at `http://localhost:8080` and keeps running until it is stopped with `Ctrl+C`.

Main endpoints:

* `GET /` – API entry point with HATEOAS links
* `GET /books`, `GET /clients`, `GET /orders`
* `GET /info/details` – service name, version, environment and build timestamp
* `GET /health`

H2 console: `http://localhost:8080/h2-console`

* **JDBC URL**: `jdbc:h2:mem:bookstore`
* **Username**: `sa`
* **Password**: (leave empty)

## Configuration Placeholders

The service metadata in `application.properties` uses placeholders that are replaced by Ant with a `filterset`:

```
service.version=@projectVersion@
service.environment=@environment@
service.build.timestamp=@buildTimestamp@
```

The `filterset` uses `@` as the token delimiter by default, so the placeholders from Part 2 work without changes (the `ReplaceTokens` filter used in Gradle is itself an Ant class).

* In local runs (`run`, tests, `jar`, `installDist`) they are replaced by `process-resources` with the project version, `local` and `local-build`.
* In the dev deployment (`deployToDev`) they are replaced with the project version, `dev` and the current timestamp.

## Deploying to the Development Environment

To create a deployment in `build/deployment/dev`:

```
ant deployToDev
```

This target depends on four targets, executed from left to right:

1. `deploy-clean` – deletes the deployment directory
2. `deploy-app` – copies the application JAR
3. `deploy-libs` – copies the runtime dependencies into `lib/`
4. `deploy-config` – copies the `.properties` files, replacing the placeholders

Resulting structure:

```
build/deployment/dev/
├── application.properties
├── bookstore-1.0.0.jar
└── lib/
```

To run the application from the deployment directory:

```
cd build/deployment/dev
java -cp "bookstore-1.0.0.jar:lib/*" com.example.bookstore.BookstoreApplication
```

On Windows, replace `:` with `;` in the classpath separator.

The external `application.properties` takes precedence over the one inside the JAR, so `/info/details` shows `environment = dev` and the deployment timestamp.

## Running from the Distribution

Ant has no `application` plugin, so the start scripts are written by hand in `src/dist/bin`. To run the application using them:

```
ant runDist
```

This target depends on `installDist`, which creates `build/install/bookstore`:

```
build/install/bookstore/
├── bin/
│   ├── bookstore          # Linux/macOS
│   └── bookstore.bat      # Windows
└── lib/                   # Application JAR + runtime dependencies
```

`runDist` detects the operating system and runs `bin/bookstore.bat` on Windows or `bin/bookstore` on Linux/macOS.

Notes:

* The scripts use a classpath wildcard (`lib/*`), so the `The input line is too long` error from Part 2 does not happen.
* `installDist` uses `fixcrlf` to give each script the correct line endings, because Git on Windows may convert the Unix script to CRLF.
* The scripts use the `java` found in the `PATH` (they do not read `JAVA_HOME`).

## Javadoc

To generate the Javadoc and package it into a zip file:

```
ant javadocZip
```

The documentation is generated in `build/docs/javadoc/index.html` and the archive in `build/docs-zip/bookstore-1.0.0-javadoc.zip`.

## Testing

Run only the unit tests:

```
ant test
```

Run only the integration tests (which start the full Spring context):

```
ant integrationTest
```

Run both (and package the application):

```
ant build
```

The tests run in a separate JVM (`<fork>`), as Gradle does by default.

Test reports:

* Unit tests: XML reports in `build/reports/tests/test`
* Integration tests: XML reports in `build/reports/tests/integrationTest` and an HTML report in `build/reports/tests/integrationTest/html/junit-noframes.html`

## Comparison with Gradle

| Feature                  | Gradle (Part 2)                                  | Ant + Ivy                                          |
|--------------------------|--------------------------------------------------|----------------------------------------------------|
| Tool installation        | Gradle Wrapper (`gradlew`)                       | Ant installed manually; Ivy downloaded by `build.xml` |
| Dependency versions      | Managed by the Spring Boot BOM                   | Written explicitly in `ivy.xml`                    |
| Standard tasks           | Provided by the `java`, `application` and Spring Boot plugins | Written by hand (`compile`, `jar`, `run`, ...)     |
| `-parameters` flag       | Added automatically by the Spring Boot plugin    | Must be added to `<javac>`                         |
| Executable JAR           | `bootJar` (fat JAR)                              | Only the plain JAR                                 |
| Start scripts            | Generated by `installDist`                       | Written by hand in `src/dist/bin`                  |
| Integration tests        | Dedicated source set                             | An extra `<javac>` and `<junitlauncher>` with manual classpaths |
| Task ordering            | `dependsOn` + `mustRunAfter`                     | Order of the `depends` list                        |
| Incremental build/cache  | Up-to-date checks and build cache                | No build cache; targets run on every invocation (some tasks, such as `<javac>` and `<copy>`, only skip unchanged files) |
