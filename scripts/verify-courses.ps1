param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$SkipGradle
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Fail([string]$Message) {
    [Console]::Error.WriteLine("VERIFY FAILED: $Message")
    exit 1
}

function Get-YamlContentList {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $inContent = $false
    $items = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ($line -match '^content:\s*$') {
            $inContent = $true
            continue
        }
        if ($inContent) {
            if ($line -match '^\s*-\s+(.+)$') {
                $raw = $Matches[1].Trim()
                if ($raw -match '^["''](.+)["'']$') { $raw = $Matches[1] }
                $items.Add($raw)
            } elseif ($line -match '^\S') {
                break
            } elseif ($line -match '^\s*$') {
                continue
            } else {
                break
            }
        }
    }
    return ,$items.ToArray()
}

function Get-CatalogCourses {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { Fail "missing catalog.yaml at $Path" }
    $courses = @()
    $current = $null
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match '^\s*-\s+id:\s*(.+)\s*$') {
            if ($null -ne $current) { $courses += $current }
            $current = [pscustomobject]@{
                id     = $Matches[1].Trim()
                title  = ""
                path   = ""
                status = ""
            }
        } elseif ($null -ne $current) {
            if ($line -match '^\s+title:\s*(.+)\s*$') { $current.title = $Matches[1].Trim() }
            if ($line -match '^\s+path:\s*(.+)\s*$') { $current.path = $Matches[1].Trim() }
            if ($line -match '^\s+status:\s*(.+)\s*$') { $current.status = $Matches[1].Trim() }
        }
    }
    if ($null -ne $current) { $courses += $current }
    if ($courses.Count -eq 0) { Fail "catalog.yaml has no courses" }
    return $courses
}

function Test-Lesson {
    param([Parameter(Mandatory=$true)][string]$LessonDir)
    $info = Join-Path $LessonDir "lesson-info.yaml"
    if (-not (Test-Path -LiteralPath $info)) {
        Fail "missing lesson-info.yaml in $LessonDir"
    }
    $tasks = Get-YamlContentList -Path $info
    foreach ($task in $tasks) {
        if ([string]::IsNullOrWhiteSpace($task)) { continue }
        $taskDir = Join-Path $LessonDir $task
        if (-not (Test-Path -LiteralPath $taskDir)) {
            Fail "missing task directory $taskDir"
        }
        foreach ($req in @("task-info.yaml", "task.md")) {
            $file = Join-Path $taskDir $req
            if (-not (Test-Path -LiteralPath $file)) {
                Fail "missing $req in $taskDir"
            }
        }
    }
}

function Test-CourseTree {
    param([Parameter(Mandatory=$true)][string]$CourseDir)
    $courseInfo = Join-Path $CourseDir "course-info.yaml"
    if (-not (Test-Path -LiteralPath $courseInfo)) {
        Fail "missing course-info.yaml in $CourseDir"
    }
    $items = Get-YamlContentList -Path $courseInfo
    if ($items.Count -eq 0) { Fail "course-info.yaml content is empty in $CourseDir" }
    foreach ($item in $items) {
        $dir = Join-Path $CourseDir $item
        if (-not (Test-Path -LiteralPath $dir)) {
            Fail "missing content path $dir"
        }
        $sectionInfo = Join-Path $dir "section-info.yaml"
        $lessonInfo = Join-Path $dir "lesson-info.yaml"
        if (Test-Path -LiteralPath $sectionInfo) {
            $lessons = Get-YamlContentList -Path $sectionInfo
            foreach ($lesson in $lessons) {
                Test-Lesson -LessonDir (Join-Path $dir $lesson)
            }
        } elseif (Test-Path -LiteralPath $lessonInfo) {
            Test-Lesson -LessonDir $dir
        } else {
            Fail "neither section-info.yaml nor lesson-info.yaml in $dir"
        }
    }
}

function Invoke-CourseGradle {
    param([Parameter(Mandatory=$true)][string]$CourseDir)
    $wrapper = Join-Path $CourseDir "gradlew.bat"
    if (-not (Test-Path -LiteralPath $wrapper)) {
        Fail "missing gradlew.bat in $CourseDir"
    }
    $tasks = Start-Process -FilePath $wrapper -ArgumentList @("tasks", "--no-daemon") -WorkingDirectory $CourseDir -Wait -PassThru -NoNewWindow
    if ($tasks.ExitCode -ne 0) {
        Fail "gradlew tasks failed in $CourseDir (exit $($tasks.ExitCode))"
    }
    $javaFiles = @(Get-ChildItem -LiteralPath $CourseDir -Recurse -File -Filter "*.java" -ErrorAction SilentlyContinue)
    if ($javaFiles.Count -gt 0) {
        $test = Start-Process -FilePath $wrapper -ArgumentList @("test", "--no-daemon") -WorkingDirectory $CourseDir -Wait -PassThru -NoNewWindow
        if ($test.ExitCode -ne 0) {
            Fail "gradlew test failed in $CourseDir (exit $($test.ExitCode))"
        }
    }
}

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$rootCourseInfo = Join-Path $RepoRoot "course-info.yaml"
if (Test-Path -LiteralPath $rootCourseInfo) {
    Fail "course-info.yaml must not exist at repo root: $rootCourseInfo"
}

$catalogPath = Join-Path $RepoRoot "catalog.yaml"
$courses = @(Get-CatalogCourses -Path $catalogPath)
foreach ($course in $courses) {
    if ($course.status -notin @("content", "stub")) {
        Fail "invalid status '$($course.status)' for $($course.id)"
    }
    $expectedPath = "courses/$($course.id)"
    if ($course.path -ne $expectedPath) {
        Fail "path '$($course.path)' must equal '$expectedPath'"
    }
    $courseDir = Join-Path $RepoRoot ($course.path -replace "/", [IO.Path]::DirectorySeparatorChar)
    Test-CourseTree -CourseDir $courseDir
    if (-not $SkipGradle) {
        Invoke-CourseGradle -CourseDir $courseDir
    }
}

Write-Output "VERIFY OK: $($courses.Count) courses"
exit 0
