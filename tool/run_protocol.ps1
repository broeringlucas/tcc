<#
.SYNOPSIS
    Orchestrates automatic collection of the quantitative protocol (Load,
    Search, Scroll, Theme) across the 4 approaches, with thermal control
    between runs.

.DESCRIPTION
    For each repeat and each approach (always in the same fixed order), runs
    `flutter run --profile -d <device>` with `--dart-define=AUTO_APPROACH=<approach>`
    — the app opens straight into that approach's screen and the full
    protocol (ProtocolRunner) runs on its own, printing `PERF {...}` lines to
    the console and closing itself at the end. The script captures that
    output, waits for the device to cool down between runs, and in the end
    consolidates everything into results\perf.jsonl and results\runs.csv.

.PARAMETER Device
    Device id (see `flutter devices` or `adb devices`). Required.

.PARAMETER Flutter
    Path to flutter.bat. Default: the FVM-managed Flutter stable
    (C:\Users\lucas\fvm\versions\stable\bin\flutter.bat), because fvm.exe is
    blocked on this machine.

.PARAMETER Adb
    Path to adb.exe. Default: $env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe.

.PARAMETER Repeats
    How many times to repeat the full loop (the 4 approaches, always in the
    same order). Default: 1.

.PARAMETER OutDir
    Output folder for logs and the consolidated files. Default: results.

.PARAMETER MaxTempC
    Maximum battery temperature (°C) to start a run — the script loops,
    polling every 15s, until the device cools down to this limit. Default: 33.

.PARAMETER Quick
    Turns on --dart-define=AUTO_QUICK=true (2 samples instead of 20 for
    Load/Search) — useful to test the flow without waiting for the full
    protocol.

.PARAMETER RestSeconds
    Rest interval between approaches, in seconds. Default: 120.

.EXAMPLE
    .\tool\run_protocol.ps1 -Device emulator-5554 -Quick

.EXAMPLE
    .\tool\run_protocol.ps1 -Device ABC123 -Repeats 2
#>

param(
    [string]$Device,
    [string]$Flutter = 'C:\Users\lucas\fvm\versions\stable\bin\flutter.bat',
    [string]$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    [ValidateRange(1, 100)]
    [int]$Repeats = 1,
    [string]$OutDir = 'results',
    [double]$MaxTempC = 33,
    [switch]$Quick,
    [int]$RestSeconds = 120
)

$ErrorActionPreference = 'Stop'

if (-not $Device) {
    Write-Error "Pass -Device <id> (see 'flutter devices' or '& '$Adb' devices')."
    exit 1
}

if (-not (Test-Path $Flutter)) {
    Write-Error "Could not find flutter.bat at '$Flutter'. Pass -Flutter <path>."
    exit 1
}

if (-not (Test-Path $Adb)) {
    Write-Error "Could not find adb.exe at '$Adb'. Pass -Adb <path>."
    exit 1
}

$order = @('bloc', 'provider', 'riverpod', 'getx')
$orderText = $order -join ','

function Get-FlutterVersion {
    $raw = & $Flutter --version 2>$null
    $firstLine = $raw | Select-Object -First 1
    if ($firstLine -match 'Flutter\s+(\S+)') {
        return $Matches[1]
    }
    return 'unknown'
}

function Get-BatteryField {
    param([string]$FieldName)
    $raw = & $Adb -s $Device shell dumpsys battery
    foreach ($line in $raw) {
        if ($line -match "$FieldName\s*:\s*(-?\d+)") {
            return [int]$Matches[1]
        }
    }
    return $null
}

function Get-BatteryTempC {
    $raw = Get-BatteryField -FieldName 'temperature'
    if ($null -eq $raw) { return $null }
    return [double]$raw / 10.0
}

function Wait-ForThermal {
    while ($true) {
        $temp = Get-BatteryTempC
        if ($null -eq $temp) {
            Write-Warning "Could not read battery temperature — proceeding without waiting."
            return $null
        }
        if ($temp -le $MaxTempC) {
            return $temp
        }
        Write-Host "  Temperature ${temp}C above limit (${MaxTempC}C) — waiting 15s..."
        Start-Sleep -Seconds 15
    }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$flutterVersion = Get-FlutterVersion
Write-Host "Flutter: $flutterVersion | Device: $Device | Repeats: $Repeats | Order: $orderText | Quick: $($Quick.IsPresent)"

& $Adb -s $Device shell svc power stayon usb
& $Adb -s $Device shell input keyevent KEYCODE_WAKEUP

$summary = New-Object System.Collections.Generic.List[object]
$totalRuns = $Repeats * 4
$runIndex = 0

for ($run = 1; $run -le $Repeats; $run++) {
    $runDir = Join-Path $OutDir "run$run"
    New-Item -ItemType Directory -Force -Path $runDir | Out-Null

    for ($position = 1; $position -le 4; $position++) {
        $runIndex++
        $approach = $order[$position - 1]

        Write-Host ""
        Write-Host "=== Repeat $run, position $position/4: $approach ($runIndex/$totalRuns) ==="

        & $Adb -s $Device shell input keyevent KEYCODE_WAKEUP

        $tempBefore = Wait-ForThermal
        $batteryBefore = Get-BatteryField -FieldName 'level'

        $logPath = Join-Path $runDir "${position}_$approach.log"

        $defines = @(
            "--dart-define=AUTO_APPROACH=$approach",
            "--dart-define=SESSION_ID=run$run",
            "--dart-define=RUN_ORDER=$orderText",
            "--dart-define=RUN_POSITION=$position",
            "--dart-define=FLUTTER_VERSION=$flutterVersion"
        )
        if ($Quick) {
            $defines += '--dart-define=AUTO_QUICK=true'
        }

        & $Flutter run --profile -d $Device @defines | Tee-Object -FilePath $logPath

        $tempAfter = Get-BatteryTempC
        $batteryAfter = Get-BatteryField -FieldName 'level'

        $status = 'fail'
        if (Test-Path $logPath) {
            $logContent = Get-Content -Path $logPath -Raw
            $donePattern = '"type"\s*:\s*"done".*"approach"\s*:\s*"' + [regex]::Escape($approach) + '"'
            if ($logContent -match $donePattern) {
                $status = 'ok'
            }
        }

        if ($status -eq 'fail') {
            Write-Warning "  $approach (repeat $run, position $position) did not finish successfully — see $logPath"
        }

        $summary.Add([PSCustomObject]@{
                run            = $run
                position       = $position
                approach       = $approach
                temp_before_c  = $tempBefore
                temp_after_c   = $tempAfter
                battery_before = $batteryBefore
                battery_after  = $batteryAfter
                status         = $status
            })

        if ($runIndex -lt $totalRuns) {
            Write-Host "  Waiting $RestSeconds s before the next approach..."
            Start-Sleep -Seconds $RestSeconds
        }
    }
}

$runsCsvPath = Join-Path $OutDir 'runs.csv'
$summary | Export-Csv -Path $runsCsvPath -NoTypeInformation -Encoding utf8

$perfLines = New-Object System.Collections.Generic.List[string]
Get-ChildItem -Path $OutDir -Recurse -Filter '*.log' | ForEach-Object {
    Get-Content -Path $_.FullName | ForEach-Object {
        if ($_ -match 'PERF\s+(\{.*\})') {
            $perfLines.Add($Matches[1])
        }
    }
}
$perfJsonlPath = Join-Path $OutDir 'perf.jsonl'
$perfLines | Set-Content -Path $perfJsonlPath -Encoding utf8

$okCount = ($summary | Where-Object { $_.status -eq 'ok' }).Count
Write-Host ""
Write-Host "Done. $($summary.Count) runs, $okCount successful."
Write-Host "Run summary: $runsCsvPath"
Write-Host "Consolidated PERF lines: $perfJsonlPath ($($perfLines.Count) lines)"
