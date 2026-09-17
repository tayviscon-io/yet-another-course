$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here "..\..")
$verify = Join-Path $repoRoot "scripts\verify-courses.ps1"

function Invoke-Verify([string]$FixtureName) {
    $root = Join-Path $here "fixtures\$FixtureName"
    $p = Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile", "-File", $verify, "-RepoRoot", $root
    ) -Wait -PassThru -NoNewWindow
    return $p.ExitCode
}

if (-not (Test-Path $verify)) { throw "missing $verify" }

$good = Invoke-Verify "good-course"
if ($good -ne 0) { throw "expected good-course exit 0, got $good" }

$bad = Invoke-Verify "missing-task"
if ($bad -ne 1) { throw "expected missing-task exit 1, got $bad" }

Write-Output "verify-tests-pass"
