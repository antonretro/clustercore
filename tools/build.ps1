# Command-line build of Cluster Core with Igor (no IDE needed).
# Usage:  powershell -File tools\build.ps1 [-Run] [-Test]
#   -Run    start the game after building
#   -Test   run the self-test (--autotest): replays every level's solution at par, tours the
#           menus and saves screenshots to $env:TEMP\ccbuild\shots, prints the [TEST] lines
param([switch]$Run, [switch]$Test)
$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $PSScriptRoot
$rt   = "C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23"
$uf   = Get-ChildItem "$env:APPDATA\GameMakerStudio2-LTS2026" -Directory |
        Where-Object { Test-Path "$($_.FullName)\licence.plist" } | Select-Object -First 1
$b    = "$env:TEMP\ccbuild"
New-Item -ItemType Directory -Force "$b\cache", "$b\temp", "$b\out", "$b\shots" | Out-Null
Get-Process Cluster* -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item "$b\out\*" -Recurse -Force -ErrorAction SilentlyContinue
$buildStart = (Get-Date).AddSeconds(-2)

& "$rt\bin\igor\windows\x64\Igor.exe" /uf="$($uf.FullName)" /lf="$($uf.FullName)\licence.plist" `
    /rp="$rt" /project="$proj\Cluster Core.yyp" /cache="$b\cache" /temp="$b\temp" `
    /of="$b\out\game.win" /tf="$b\out\game.zip" -- Windows PackageZip *> "$b\build.log"
$code = $LASTEXITCODE

$logText = [System.IO.File]::ReadAllText("$b\build.log")
$errs = ($logText -split "`r?`n") | Select-String -Pattern "^Error|error :|Error :|FAILED|failed to|cannot find|not been declared|Permission denied|Warning : .*undefined" |
        Select-Object -First 40
if ($errs) { "---- build problems ----"; $errs | ForEach-Object { $_.Line } }
$exe = Get-ChildItem "$b\out" -Filter *.exe -ErrorAction SilentlyContinue |
       Where-Object { $_.LastWriteTime -ge $buildStart } | Select-Object -First 1
if ($code -ne 0 -or -not $exe -or ($logText -match 'Error\s*:\s*gml_')) {
    "BUILD FAILED (exit $code). Log: $b\build.log"
    Get-Content "$b\build.log" -Tail 30
    exit 1
}
"BUILD OK -> $($exe.FullName)"

$save = "$env:LOCALAPPDATA\Cluster_Core"
if ($Test) {
    Remove-Item "$b\shots\*.png", "$b\test.log" -Force -ErrorAction SilentlyContinue
    if (Test-Path "$save\shots") { Remove-Item "$save\shots\*.png" -Force -ErrorAction SilentlyContinue }
    $p = Start-Process $exe.FullName -ArgumentList "--autotest", "-output", "$b\test.log" -PassThru -WorkingDirectory "$b\out"
    if (-not $p.WaitForExit(180000)) { $p.Kill(); "TEST TIMEOUT (killed)" }
    if (Test-Path "$b\test.log") {
        Select-String -Path "$b\test.log" -Pattern "\[TEST\]" | ForEach-Object { $_.Line.Trim() }
        $rt_err = Select-String -Path "$b\test.log" -Pattern "ERROR in|FATAL|not set before reading|Unable to find"
        if ($rt_err) { "---- runtime errors ----"; Select-String -Path "$b\test.log" -Pattern "ERROR|called from|for object|Variable|not set|at gml_|line" | Select-Object -First 25 | ForEach-Object { $_.Line.Trim() } }
    } else { "No test.log written" }
    if (Test-Path "$save\shots") { Copy-Item "$save\shots\*.png" "$b\shots" -Force -ErrorAction SilentlyContinue }
    "Screenshots: $b\shots ($((Get-ChildItem "$b\shots" -Filter *.png).Count) files)"
} elseif ($Run) {
    Start-Process $exe.FullName -WorkingDirectory "$b\out"
}
