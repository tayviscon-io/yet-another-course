param(
    [Parameter(Mandatory=$true)][string]$Id,
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$RootProjectName,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$courseDir = Join-Path $RepoRoot "courses\$Id"
$patternDir = Join-Path $RepoRoot "courses\pattern"
if (-not (Test-Path -LiteralPath (Join-Path $patternDir "gradlew.bat"))) {
    throw "pattern course wrapper missing; run subtree first"
}
if (Test-Path -LiteralPath $courseDir) { throw "already exists: $courseDir" }

# PS 5.1 Set-Content -Encoding UTF8 writes a BOM. Academy yaml/md/gradle need UTF-8 without BOM.
function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory=$true)][string]$LiteralPath,
        [Parameter(Mandatory=$true)][string]$Value
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($LiteralPath, $Value, $utf8NoBom)
}

New-Item -ItemType Directory -Force -Path $courseDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $patternDir "gradle") (Join-Path $courseDir "gradle")
Copy-Item -Force (Join-Path $patternDir "gradlew") (Join-Path $courseDir "gradlew")
Copy-Item -Force (Join-Path $patternDir "gradlew.bat") (Join-Path $courseDir "gradlew.bat")
Copy-Item -Force (Join-Path $patternDir ".gitignore") (Join-Path $courseDir ".gitignore")
Copy-Item -Force (Join-Path $patternDir "build.gradle") (Join-Path $courseDir "build.gradle")

$settings = @"
static String sanitizeName(String name) {
    return name.replaceAll("[ /\\\\:<>\`"?*|()]", "_").replaceAll("(^[.]+)|([.]+\$)", "")
}

rootProject.name = '$RootProjectName'

rootProject.projectDir.eachDirRecurse {
    if (!isTaskDir(it) || it.path.contains(".idea")) {
        return
    }
    def taskRelativePath = rootDir.toPath().relativize(it.toPath())
    def parts = []
    for (name in taskRelativePath) {
        parts.add(sanitizeName(name.toString()))
    }
    def moduleName =  parts.join("-")
    include "`$moduleName"
    project(":`$moduleName").projectDir = it
}

def isTaskDir(File dir) {
    return new File(dir, "src").exists()
}
"@
Write-Utf8NoBomFile -LiteralPath (Join-Path $courseDir "settings.gradle") -Value $settings

$courseInfo = @"
type: marketplace
title: $Title
language: Russian
summary: "$Title - это курс от компании Tayviscon IO из серии «Yet Another Course»: $Summary."
programming_language: Java
content:
  - Введение
yaml_version: 5
"@
Write-Utf8NoBomFile -LiteralPath (Join-Path $courseDir "course-info.yaml") -Value $courseInfo

$readme = @"
# $Title

Курс серии [Yet Another Course](../../README.md).

Статус: каркас. Открывайте эту папку в IntelliJ с плагином JetBrains Academy.
"@
Write-Utf8NoBomFile -LiteralPath (Join-Path $courseDir "README.md") -Value $readme

$intro = Join-Path $courseDir "Введение"
$task = Join-Path $intro "Обзор курса"
New-Item -ItemType Directory -Force -Path $task | Out-Null
Write-Utf8NoBomFile -LiteralPath (Join-Path $intro "lesson-info.yaml") -Value "content:`n  - Обзор курса`n"
Write-Utf8NoBomFile -LiteralPath (Join-Path $task "task-info.yaml") -Value "type: theory`nfiles:`n  - name: task.md`n    visible: true`n"
Write-Utf8NoBomFile -LiteralPath (Join-Path $task "task.md") -Value "# Обзор курса`n`nКурс в разработке.`n"
