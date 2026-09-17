# Yet Another Course monorepo

- **Date:** 2026-09-17
- **Status:** Draft, awaiting review
- **Owner:** Tayviscon IO
- **Target repository:** `tayviscon-io/yet-another-course`

## Problem

Организация `tayviscon-io` держит серию JetBrains Academy курсов как отдельные GitHub-репозитории `yet-another-*-course`. Это даёт лишний шум в организации. Нужен один git-репозиторий со всеми курсами, без потери структуры плагина Academy и без потери уже написанного материала.

## Non-goals

- Не трогать `tayviscon`, `tayviscon-jetbrains-theme`, FME, `tayviscon-old-v2`, `.github`.
- Не сливать курсы в один JetBrains Academy курс.
- Не делать корневой Gradle / composite build.
- Не переписывать тексты уроков и порядок `content` у курсов с материалом.
- Не публиковать курсы в JetBrains Marketplace в рамках этой работы.

## Constraints from JetBrains Academy

Плагин ожидает `course-info.yaml` в корне **конкретного курса**. Если положить его в корень git-репозитория, весь монорепозиторий станет одним курсом.

У разных курсов уже есть одинаковые имена (`Введение` и другие). Их нельзя смешать в одном course root без переименования и коллизий Gradle-модулей: `settings.gradle` считает модулем любую папку с `src/`.

Поэтому каждый курс остаётся независимым Academy/Gradle-проектом. В IntelliJ курс открывается из `courses/<id>/`, не из корня репозитория.

## Architecture

```
yet-another-course/                 # git root, манифест серии
  README.md                         # манифест; ссылки на courses/<id>/
  catalog.yaml                      # машиночитаемый список курсов
  .gitignore
  scripts/verify-courses.ps1
  docs/superpowers/specs/           # эта спецификация
  courses/
    java/
    sql/
    jdbc/
    http-servlets/
    apache-maven/
    junit-5/
    gradle/
    hibernate/
    spring/
    bash/
    docker/
    apache-kafka/
    pattern/
```

В корне репозитория **нет** `course-info.yaml`, `build.gradle`, `settings.gradle`.

Каждый `courses/<id>/` содержит полный курс: `course-info.yaml`, Gradle wrapper, секции/уроки/задания.

## Course catalog

`catalog.yaml` — единственный машиночитаемый индекс. Схема:

```yaml
series: yet-another-course
courses:
  - id: java
    title: Yet Another Java Course
    path: courses/java
    status: stub
  - id: sql
    title: Yet Another SQL Course
    path: courses/sql
    status: content
```

`status` только `content` или `stub`. `id` совпадает с именем папки. Порядок курсов в каталоге и в README совпадает с текущим манифестом:

| id | title | source | status |
|---|---|---|---|
| java | Yet Another Java Course | empty GitHub repo | stub |
| sql | Yet Another SQL Course | GitHub + local extra task | content |
| jdbc | Yet Another JDBC Course | empty GitHub repo | stub |
| http-servlets | Yet Another HTTP.Servlets Course | empty GitHub repo | stub |
| apache-maven | Yet Another Apache Maven Course | empty GitHub repo | stub |
| junit-5 | Yet Another JUnit 5 Course | empty GitHub repo | stub |
| gradle | Yet Another Gradle Course | empty GitHub repo | stub |
| hibernate | Yet Another Hibernate Course | empty GitHub repo | stub |
| spring | Yet Another Spring Course | empty GitHub repo | stub |
| bash | Yet Another Bash Course | empty GitHub repo | stub |
| docker | Yet Another Docker Course | GitHub | content |
| apache-kafka | Yet Another Apache Kafka Course | GitHub | content |
| pattern | Yet Another Pattern Course | GitHub | content |

README манифеста ссылается на относительные пути `courses/<id>/`, не на `github.com/tayviscon-io/yet-another-*-course`.

README внутри каждого content-курса правится так: ссылки на свой бывший репозиторий (contributors, contrib.rocks) ведут на монорепозиторий. Смысл курса не меняется.

## Content courses

Источники:

- `pattern` — полный git с `tayviscon-io/yet-another-pattern-course`.
- `docker` — полный git с `tayviscon-io/yet-another-docker-course`.
- `apache-kafka` — полный git с `tayviscon-io/yet-another-apache-kafka-course`.
- `sql` — полный git с `tayviscon-io/yet-another-sql-course`, затем overlay локального задания, которого нет на GitHub.

Локальный overlay для SQL (из `V:\workspace\tayviscon\yet-another-sql-course`, не из `.study-yac`):

- урок `Продвинутый SQL для работы с данными/Транзакции и блокировки`
- задание `Блокировка строк. Запросы`
- `lesson-info.yaml` этого урока должен содержать это задание последним пунктом `content`

Не копировать из локальных checkout:

- `**/lesson-remote-info.yaml`
- `**/section-remote-info.yaml`
- `**/task-remote-info.yaml`
- `.idea/`, `build/`, `.gradle/`

Структура секций, уроков и YAML content-курсов не переименовывается и не «выравнивается» между курсами. Разница `yaml_version: 2` (docker, kafka) и `yaml_version: 5` (sql, pattern) сохраняется.

## Stub courses

Шаблон каркаса берётся с `yet-another-pattern-course` / `yet-another-sql-course`, не с docker/kafka:

- `yaml_version: 5`
- Java 17
- `settings.gradle` с автообнаружением папок, у которых есть `src/`
- **без** модуля `util`
- Gradle wrapper копируется из шаблона

Минимальное содержимое каждого stub:

```
course-info.yaml
build.gradle
settings.gradle
gradle/wrapper/
gradlew
gradlew.bat
.gitignore
README.md
Введение/
  lesson-info.yaml          # content: [Обзор курса]
  Обзор курса/
    task-info.yaml          # type: theory
    task.md                 # короткий placeholder: курс в разработке
```

`course-info.yaml` stub:

- `type: marketplace`
- `title` из таблицы выше
- `language: Russian`
- `programming_language: Java`
- `summary` из текущего манифеста (формулировка курса в списке)
- `content: [Введение]`

Это валидный открываемый Academy-курс, не пустая папка. Дальнейшие уроки добавляются обычным способом плагина.

## Git assembly

Рабочая копия — полноценный (не shallow) clone `tayviscon-io/yet-another-course`.

Порядок коммитов:

1. Эта спецификация и корневой `.gitignore`. `catalog.yaml` появляется вместе с курсами, сразу в полном виде.
2. `git subtree add --prefix=courses/pattern` с ветки `main`.
3. `git subtree add --prefix=courses/sql` с ветки `main`.
4. `git subtree add --prefix=courses/docker` с ветки `master`.
5. `git subtree add --prefix=courses/apache-kafka` с ветки `master`.
6. Overlay SQL-задания `Блокировка строк. Запросы` отдельным коммитом.
7. Добавление девяти stub-курсов одним или несколькими коммитами.
8. Корневой README, README content-курсов и полный `catalog.yaml` (не черновик с пустыми полями).
9. `scripts/verify-courses.ps1`.

История content-курсов сохраняется через subtree. Stub-курсы — новые файлы, истории у пустых GitHub-репозиториев нет.

Корневой `.gitignore` игнорирует `.idea/`, `build/`, `.gradle/`, `*-remote-info.yaml` на всём дереве.

## Link updates before delete

Обязательно поправить:

- `yet-another-course/README.md` (список курсов)
- README каждого перенесённого content-курса (self-links, contrib.rocks)
- `tayviscon-io/.github` profile README, если там появятся/есть ссылки на отдельные курсы (на момент исследования прямых ссылок на курсы там не было)

Публичных ссылок вне GitHub на отдельные `yet-another-*-course` репозитории не найдено. Прямые URL вида `https://github.com/tayviscon-io/yet-another-sql-course` после удаления перестанут работать. Новые канонические пути: `https://github.com/tayviscon-io/yet-another-course/tree/main/courses/<id>`.

## GitHub actions

После зелёной проверки и пуша в `tayviscon-io/yet-another-course` удалить репозитории:

- `yet-another-java-course`
- `yet-another-sql-course`
- `yet-another-jdbc-course`
- `yet-another-http-servlets-course`
- `yet-another-apache-maven-course`
- `yet-another-junit-5-course`
- `yet-another-gradle-course`
- `yet-another-hibernate-course`
- `yet-another-spring-course`
- `yet-another-bash-course`
- `yet-another-docker-course`
- `yet-another-apache-kafka-course`
- `yet-another-pattern-course`

Не удалять `yet-another-course`.

Удаление только после:

1. успешного пуша монорепозитория;
2. зелёного `scripts/verify-courses.ps1`;
3. повторной сверки списка `gh repo list tayviscon-io`.

Если `gh` нет в PATH — установить GitHub CLI и аутентифицироваться. Без успешного пуша удаление не выполняется.

## Verification

`scripts/verify-courses.ps1`:

1. Читает `catalog.yaml`.
2. Для каждого курса проверяет существование `path/course-info.yaml`.
3. Сверяет `content` в `course-info.yaml` с папками на диске.
4. Для каждого урока проверяет `lesson-info.yaml`; для каждого задания — `task-info.yaml` и `task.md`.
5. Запускает `.\gradlew.bat tasks` **из папки курса** (сеть разрешена: wrapper должен скачать дистрибутив Gradle при необходимости).
6. Если в курсе есть `*.java` — дополнительно `.\gradlew.bat test`. Нет тестовых классов — это не ошибка. Падение конфигурации Gradle — ошибка. Если у docker/kafka `settings.gradle` ссылается на отсутствующий модуль `util`, чинится только Gradle-конфиг, уроки не трогаются.

Скрипт завершается ненулевым кодом при первой ошибке. Пока скрипт красный: нет пуша удаления и нет `gh repo delete`.

Проверка плагина в IntelliJ — ручной шаг владельца: File → Open → `courses/<id>`. Автоматическая проверка в этой работе — YAML + Gradle.

## Error handling

- Коллизия имён при subtree: не решать «вклеиванием» в корень; курсы живут только под `courses/<id>/`.
- Локальный SQL overlay не совпал с GitHub-уроком: остановить работу, не выдумывать задание.
- Gradle одного курса упал: чинить этот курс, не отключать проверку.
- Нет прав на delete: оставить монорепозиторий запушенным и сообщить список репозиториев, которые осталось удалить вручную.
- Случайный `course-info.yaml` в корне монорепозитория — дефект, его нельзя коммитить.

## Success criteria

- Один публичный репозиторий `tayviscon-io/yet-another-course` содержит манифест и все 13 курсов.
- SQL, Pattern, Kafka, Docker открываются как отдельные Academy-курсы из своих папок и проходят verify.
- Девять stub-курсов открываемы (YAML + Gradle).
- В манифесте нет ссылок на удалённые репозитории.
- 13 старых `yet-another-*-course` репозиториев удалены (кроме самого `yet-another-course`).
- Исключённые репозитории организации на месте.
