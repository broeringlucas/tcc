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

    With -SampleResources, it ALSO samples, through adb, roughly every 2s
    (piggybacked on the existing log-polling loop): CPU time (`/proc/<pid>/stat`,
    converted to a %-of-one-core rate between consecutive samples — see
    Get-CpuPercentSinceLast), resident/peak memory (`VmRSS`/`VmHWM` from
    `/proc/<pid>/status`), a full PSS breakdown (`dumpsys meminfo <pid>`: Java
    Heap, Native Heap, Graphics, Private Other, System, Total), per-core
    current/max frequency (`scaling_cur_freq`/`scaling_max_freq`) and
    governor (`scaling_governor`), and 2 CPU thermal-zone temperatures —
    consolidated into results\resources.csv. All of it (including the PID
    itself, re-resolved every sample via `pidof`) comes from a SINGLE `adb
    shell` call per sample, using the device's own clock (`date +%s.%N`) for
    the timestamp, not the host's.

    ⚠️ -SampleResources is opt-in, OFF by default, because `dumpsys meminfo`
    makes the measured app scan its own smaps — i.e. the act of sampling
    burns CPU *inside the process being measured* and can skew DB_/PROCESS_/
    frame times for that run. Treat a -SampleResources run as a separate pass
    whose Load/Search/Scroll/Theme timing numbers are NOT the official ones —
    only resources.csv matters from it. Recommended protocol: run once
    without -SampleResources (the official timing numbers) and once with it
    (the resource numbers), then diff DB_/PROCESS_ times between the two to
    quantify how much the polling itself perturbs things.

    -SampleResources also starts a parallel `adb logcat -v epoch -s flutter`
    capture per approach (results\run<N>\<pos>_<approach>.logcat.log) so the
    `PERF {...}` lines carry the device's own clock, the same one the
    resource samples use — lets you correlate a sample to a scenario by
    timestamp instead of guessing from elapsed time. ⚠️ Not validated against
    a live run yet: check that file after the first real run to confirm the
    `flutter` logcat tag actually carries these lines, and whether they
    appear progressively (one scenario at a time) or only in a burst at the
    end — either way, each scenario's elapsed time is still short for
    Load 1k/10k and Search (milliseconds), so only Load-100k, Scroll and
    Theme will have enough ~2-4s samples to say anything about trends inside
    them.

    Two numbers below are hardcoded for THIS device (Xiaomi Mi 9) and would
    need re-checking on a different one: CLK_TCK=100 (`adb shell getconf
    CLK_TCK`, used to convert utime/stime ticks to seconds) and thermal zones
    1/7 (`adb shell cat /sys/class/thermal/thermal_zone<N>/type` — confirmed
    `cpu-0-0-usr`/`cpu-1-0-usr`, i.e. one silver-cluster and one gold/prime-
    cluster sensor, both in milli-°C; the generic `soc`/`lmh-dcvs*` zones were
    tried and discarded — implausible values, unclear unit/meaning).

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
    Output folder for logs and the consolidated files. Default: results
    (results_recursos when -SampleResources is used, so the clean pass is never overwritten).

.PARAMETER MaxTempC
    Maximum battery temperature (°C) to start a run — the script loops,
    polling every 15s, until the device cools down to this limit. Default: 29
    (lowered from an earlier 33 — a run that started at 28°C spent much more
    time in the fast path of a bimodal Load timing than one starting at 30-31°C,
    so this keeps the starting temperature tighter across approaches). The
    data collection this was tuned from actually used -MaxTempC 30 (29 proved
    unreachable at rest on this device) — keep that in mind if a later
    chapter cites a specific threshold.

.PARAMETER MaxThermalWaitMinutes
    Hard cap on how long Wait-ForThermal will poll before giving up and
    proceeding anyway (with a warning) even though the device never reached
    -MaxTempC. Without this, a threshold the device can't reach loops
    forever. Default: 20.

.PARAMETER Quick
    Turns on --dart-define=AUTO_QUICK=true (2 samples instead of 20 for
    Load/Search) — useful to test the flow without waiting for the full
    protocol.

.PARAMETER RestSeconds
    Rest interval between approaches, in seconds. Default: 120.

.PARAMETER RunTimeoutMinutes
    Max time to wait for a single approach run to print its `"type":"done"`
    (or `"type":"error"`) PERF line before giving up and killing it. The app
    closes itself when the protocol finishes, but the attached `flutter run`
    CLI session doesn't always quit on its own afterwards — this timeout is
    what lets the script move on instead of hanging forever. Default: 15.

.PARAMETER SampleResources
    Opt-in: samples CPU/memory/frequency/thermal via adb and captures a
    parallel timestamped logcat stream during each approach. See the
    contamination warning in .DESCRIPTION. Default: off.

.PARAMETER NoPss
    With -SampleResources: skips `dumpsys meminfo` (the heavy part). CPU, frequency,
    temperature and VmRSS/VmHWM are still collected. Recommended for the CPU pass.

.PARAMETER Package
    Android application id, used to resolve the app's PID (via `pidof`,
    inside the same combined adb call) for CPU/memory sampling. Only used
    when -SampleResources is set. Default: com.lucasbroering.tcc.

.PARAMETER CpuCores
    Number of CPU cores to sample `scaling_cur_freq` from (cpu0..cpu<N-1>).
    Only used when -SampleResources is set. Default: 8 (Xiaomi Mi 9 /
    Snapdragon 855: 4 silver + 3 gold + 1 prime).

.EXAMPLE
    .\tool\run_protocol.ps1 -Device emulator-5554 -Quick

.EXAMPLE
    .\tool\run_protocol.ps1 -Device ABC123 -Repeats 2

.EXAMPLE
    .\tool\run_protocol.ps1 -Device ABC123 -SampleResources
#>

param(
    [string]$Device,
    [string]$Flutter = 'C:\Users\lucas\fvm\versions\stable\bin\flutter.bat',
    [string]$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    [ValidateRange(1, 100)]
    [int]$Repeats = 1,
    [string]$OutDir = 'results',
    [double]$MaxTempC = 29,
    [int]$MaxThermalWaitMinutes = 20,
    [switch]$Quick,
    [int]$RestSeconds = 120,
    [int]$RunTimeoutMinutes = 15,
    [switch]$SampleResources,
    [switch]$NoPss,
    [string]$Package = 'com.lucasbroering.tcc',
    [int]$CpuCores = 8
)

# CLK_TCK (clock ticks/second used by /proc/<pid>/stat's utime/stime) and the
# 2 thermal-zone ids below are specific to this device's kernel build —
# confirmed via `adb shell getconf CLK_TCK` and `adb shell cat
# /sys/class/thermal/thermal_zone<N>/type` on the Xiaomi Mi 9. Re-check both
# if this script is ever pointed at a different device.
$CpuClockTicksPerSecond = 100
$ThermalZoneIds = @(1, 7)

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

function Get-ResourceSample {
    param([string]$Package, [int]$CpuCores)

    # Device-side script, single adb round-trip. PID is re-resolved every
    # sample (not cached) — it's one extra `pidof` call but avoids ever
    # acting on a stale PID. P is forced to a non-existent numeric value
    # (never empty) before touching /proc/$P/* — on this device's shell,
    # /proc/$P/stat with an EMPTY $P collapses (double slash) into
    # /proc/stat, the *system-wide* stat, which parses as if it were a
    # valid (bogus) per-process line. Caught via a scratchpad dry run before
    # trusting this against the real app.
    #
    # ⚠️ Every literal quote below MUST be a single quote. Double quotes
    # inside the command text get mangled somewhere between PowerShell and
    # adb.exe's Windows argv handling — confirmed by testing the exact same
    # grep pattern single- vs double-quoted against this device; only the
    # single-quoted form came back with real output instead of
    # "inaccessible or not found".
    $freqCmd = (0..($CpuCores - 1) | ForEach-Object {
            "cat /sys/devices/system/cpu/cpu$_/cpufreq/scaling_cur_freq 2>/dev/null || echo na"
        }) -join '; '
    $maxGovCmd = (0..($CpuCores - 1) | ForEach-Object {
            "cat /sys/devices/system/cpu/cpu$_/cpufreq/scaling_max_freq 2>/dev/null || echo na; " +
            "cat /sys/devices/system/cpu/cpu$_/cpufreq/scaling_governor 2>/dev/null || echo na"
        }) -join '; '
    $thermCmd = ($ThermalZoneIds | ForEach-Object {
            "cat /sys/class/thermal/thermal_zone$_/temp 2>/dev/null || echo na"
        }) -join '; '

    # Com -NoPss o dumpsys meminfo (que faz o próprio app varrer a memória) não roda: coleta leve.
    $memCmd = if ($NoPss) { 'echo MEM:; ' } else { 'echo MEM:; dumpsys meminfo $P 2>/dev/null | grep -E ''Heap:|Graphics:|Private Other:|System:|TOTAL:''; ' }
    $template = 'P=$(pidof {PACKAGE}); P=${P%% *}; if [ -z "$P" ]; then P=999999999; fi; ' +
    'echo TS:$(date +%s.%N); echo PID:$P; ' +
    'echo STATUS:; cat /proc/$P/status 2>/dev/null | grep -E ''VmRSS|VmHWM''; ' +
    'echo STAT:; cat /proc/$P/stat 2>/dev/null; ' +
    '{MEMCMD}' +
    'echo TS2:$(date +%s.%N); echo STAT2:; cat /proc/$P/stat 2>/dev/null; ' +
    'echo FREQ:; {FREQCMD}; ' +
    'echo MAXGOV:; {MAXGOVCMD}; ' +
    'echo THERM:; {THERMCMD}'

    $cmd = $template.Replace('{PACKAGE}', $Package).Replace('{MEMCMD}', $memCmd).Replace('{FREQCMD}', $freqCmd).Replace('{MAXGOVCMD}', $maxGovCmd).Replace('{THERMCMD}', $thermCmd)
    $raw = & $Adb -s $Device shell $cmd

    $sample = [PSCustomObject]@{
        device_ts             = $null
        pid                   = $null
        vmrss_kb              = $null
        vmhwm_kb              = $null
        utime_ticks           = $null
        stime_ticks           = $null
        device_ts_post        = $null
        utime_ticks_post      = $null
        stime_ticks_post      = $null
        mem_java_heap_kb      = $null
        mem_native_heap_kb    = $null
        mem_graphics_kb       = $null
        mem_private_other_kb  = $null
        mem_system_kb         = $null
        mem_pss_total_kb      = $null
    }
    for ($i = 0; $i -lt $CpuCores; $i++) {
        $sample | Add-Member -NotePropertyName "freq_cpu${i}_khz" -NotePropertyValue $null
        $sample | Add-Member -NotePropertyName "freq_cpu${i}_max_khz" -NotePropertyValue $null
        $sample | Add-Member -NotePropertyName "governor_cpu${i}" -NotePropertyValue $null
    }
    for ($i = 0; $i -lt $ThermalZoneIds.Count; $i++) {
        $sample | Add-Member -NotePropertyName "thermal_zone$($ThermalZoneIds[$i])_c" -NotePropertyValue $null
    }

    $section = $null
    $freqIndex = 0
    $maxGovIndex = 0
    $thermIndex = 0
    foreach ($line in $raw) {
        if ($line -match '^TS:(.+)$') { $sample.device_ts = [double]$Matches[1]; continue }
        if ($line -match '^PID:(\d+)$') { $sample.pid = [int]$Matches[1]; continue }
        if ($line -match '^STATUS:$') { $section = 'status'; continue }
        if ($line -match '^STAT:$') { $section = 'stat'; continue }
        if ($line -match '^TS2:(.+)$') { $sample.device_ts_post = [double]$Matches[1]; continue }
        if ($line -match '^STAT2:$') { $section = 'stat2'; continue }
        if ($line -match '^MEM:$') { $section = 'mem'; continue }
        if ($line -match '^FREQ:$') { $section = 'freq'; continue }
        if ($line -match '^MAXGOV:$') { $section = 'maxgov'; continue }
        if ($line -match '^THERM:$') { $section = 'therm'; continue }

        switch ($section) {
            'status' {
                if ($line -match 'VmRSS:\s*(\d+)') { $sample.vmrss_kb = [int]$Matches[1] }
                elseif ($line -match 'VmHWM:\s*(\d+)') { $sample.vmhwm_kb = [int]$Matches[1] }
            }
            'stat' {
                # /proc/<pid>/stat: "<pid> (<comm>) <state> <ppid> ... <utime> <stime> ...".
                # <comm> can itself contain spaces/parens, so split after the
                # LAST ')', not by position from the start of the line.
                $closeIdx = $line.LastIndexOf(')')
                if ($closeIdx -ge 0) {
                    $rest = $line.Substring($closeIdx + 1).Trim() -split '\s+'
                    # rest (0-indexed, after the comm field): 0=state 1=ppid
                    # 2=pgrp 3=session 4=tty_nr 5=tpgid 6=flags 7=minflt
                    # 8=cminflt 9=majflt 10=cmajflt 11=utime 12=stime
                    if ($rest.Count -ge 13) {
                        $sample.utime_ticks = [int64]$rest[11]
                        $sample.stime_ticks = [int64]$rest[12]
                    }
                }
            }
            'stat2' {
                $closeIdx = $line.LastIndexOf(')')
                if ($closeIdx -ge 0) {
                    $rest = $line.Substring($closeIdx + 1).Trim() -split '\s+'
                    if ($rest.Count -ge 13) {
                        $sample.utime_ticks_post = [int64]$rest[11]
                        $sample.stime_ticks_post = [int64]$rest[12]
                    }
                }
            }
            'mem' {
                if ($line -match 'Java Heap:\s*(\d+)') { $sample.mem_java_heap_kb = [int]$Matches[1] }
                elseif ($line -match 'Native Heap:\s*(\d+)') { $sample.mem_native_heap_kb = [int]$Matches[1] }
                elseif ($line -match 'Graphics:\s*(\d+)') { $sample.mem_graphics_kb = [int]$Matches[1] }
                elseif ($line -match 'Private Other:\s*(\d+)') { $sample.mem_private_other_kb = [int]$Matches[1] }
                elseif ($line -match 'System:\s*(\d+)') { $sample.mem_system_kb = [int]$Matches[1] }
                elseif ($line -match 'TOTAL:\s*(\d+)') { $sample.mem_pss_total_kb = [int]$Matches[1] }
            }
            'freq' {
                if ($freqIndex -lt $CpuCores) {
                    if ($line -match '^\d+$') { $sample."freq_cpu${freqIndex}_khz" = [int]$line.Trim() }
                    $freqIndex++
                }
            }
            'maxgov' {
                # 2 lines per core: scaling_max_freq then scaling_governor.
                if ($maxGovIndex -lt (2 * $CpuCores)) {
                    $core = [math]::Floor($maxGovIndex / 2)
                    if ($maxGovIndex % 2 -eq 0) {
                        if ($line -match '^\d+$') { $sample."freq_cpu${core}_max_khz" = [int]$line.Trim() }
                    } else {
                        if ($line.Trim() -ne 'na') { $sample."governor_cpu${core}" = $line.Trim() }
                    }
                    $maxGovIndex++
                }
            }
            'therm' {
                if ($thermIndex -lt $ThermalZoneIds.Count) {
                    if ($line -match '^\d+$') {
                        $zoneId = $ThermalZoneIds[$thermIndex]
                        $sample."thermal_zone${zoneId}_c" = [double]$line.Trim() / 1000.0
                    }
                    $thermIndex++
                }
            }
        }
    }

    return $sample
}

function Get-CpuPercentSinceLast {
    # %-of-one-core rate between 2 samples: (Δutime+Δstime ticks) / CLK_TCK,
    # divided by the elapsed device-clock seconds. Multi-threaded work across
    # >1 core can legitimately exceed 100% — this is NOT normalized to the
    # number of cores.
    param($Sample, $PrevTicks, $PrevDeviceTs)

    # PrevTicks/PrevDeviceTs vêm da leitura pós-dumpsys da amostra anterior (quando existe),
    # então o custo do próprio dumpsys fica FORA do intervalo medido.
    if ($null -eq $PrevTicks -or $null -eq $PrevDeviceTs) { return $null }
    if ($null -eq $Sample.utime_ticks -or $null -eq $Sample.stime_ticks -or $null -eq $Sample.device_ts) { return $null }

    $deltaTicks = ($Sample.utime_ticks + $Sample.stime_ticks) - $PrevTicks
    $deltaSeconds = $Sample.device_ts - $PrevDeviceTs
    if ($deltaSeconds -le 0) { return $null }

    return [math]::Round((($deltaTicks / $CpuClockTicksPerSecond) / $deltaSeconds) * 100, 1)
}

function Wait-ForThermal {
    $deadline = (Get-Date).AddMinutes($MaxThermalWaitMinutes)
    while ($true) {
        $temp = Get-BatteryTempC
        if ($null -eq $temp) {
            Write-Warning "Could not read battery temperature — proceeding without waiting."
            return $null
        }
        if ($temp -le $MaxTempC) {
            return $temp
        }
        if ((Get-Date) -ge $deadline) {
            Write-Warning "  Gave up waiting for temperature to reach ${MaxTempC}C after $MaxThermalWaitMinutes min (still ${temp}C) — proceeding anyway."
            return $temp
        }
        Write-Host "  Temperature ${temp}C above limit (${MaxTempC}C) — waiting 15s..."
        Start-Sleep -Seconds 15
    }
}

function Invoke-ApproachRun {
    param([string]$Approach, [string[]]$Defines, [string]$LogPath, [bool]$SampleResources, [string]$Package, [int]$CpuCores)

    $logcatProc = $null
    $logcatPath = "$LogPath.logcat.log"
    if ($SampleResources) {
        & $Adb -s $Device logcat -c
        $logcatProc = Start-Process -FilePath $Adb -ArgumentList @('-s', $Device, 'logcat', '-v', 'epoch', '-s', 'flutter', 'CursorWindow:W') `
            -RedirectStandardOutput $logcatPath -RedirectStandardError "$logcatPath.stderr" -NoNewWindow -PassThru
    }

    $argList = @('run', '--profile', '-d', $Device) + $Defines
    $stderrPath = "$LogPath.stderr"
    $proc = Start-Process -FilePath $Flutter -ArgumentList $argList -RedirectStandardOutput $LogPath `
        -RedirectStandardError $stderrPath -NoNewWindow -PassThru

    $donePattern = '"type"\s*:\s*"done".*"approach"\s*:\s*"' + [regex]::Escape($Approach) + '"'
    $errorPattern = '"type"\s*:\s*"error".*"approach"\s*:\s*"' + [regex]::Escape($Approach) + '"'
    $deadline = (Get-Date).AddMinutes($RunTimeoutMinutes)
    $status = 'fail'
    $linesPrinted = 0
    $resourceSamples = New-Object System.Collections.Generic.List[object]
    $sampleFailures = 0
    $prevTicks = $null
    $prevDeviceTs = $null

    while ((Get-Date) -lt $deadline -and -not $proc.HasExited) {
        Start-Sleep -Seconds 2
        if (Test-Path $LogPath) {
            $allLines = Get-Content -Path $LogPath -ErrorAction SilentlyContinue
            if ($allLines.Count -gt $linesPrinted) {
                $allLines[$linesPrinted..($allLines.Count - 1)] | Write-Host
                $linesPrinted = $allLines.Count
            }
            $logContent = $allLines -join "`n"
            if ($logContent -match $donePattern) { $status = 'ok'; break }
            if ($logContent -match $errorPattern) { $status = 'fail'; break }
        }

        if ($SampleResources) {
            try {
                $sample = Get-ResourceSample -Package $Package -CpuCores $CpuCores
                $sample | Add-Member -NotePropertyName 'cpu_pct_1core' -NotePropertyValue (Get-CpuPercentSinceLast -Sample $sample -PrevTicks $prevTicks -PrevDeviceTs $prevDeviceTs)
                if ($null -ne $sample.utime_ticks_post -and $null -ne $sample.device_ts_post) {
                    $prevTicks = $sample.utime_ticks_post + $sample.stime_ticks_post
                    $prevDeviceTs = $sample.device_ts_post
                } elseif ($null -ne $sample.utime_ticks) {
                    $prevTicks = $sample.utime_ticks + $sample.stime_ticks
                    $prevDeviceTs = $sample.device_ts
                }
                $resourceSamples.Add($sample)
            } catch {
                $sampleFailures++
            }
        }
    }

    if (-not $proc.HasExited) {
        & taskkill /PID $proc.Id /T /F 2>$null | Out-Null
        Start-Sleep -Seconds 1
    }

    if ($null -ne $logcatProc -and -not $logcatProc.HasExited) {
        & taskkill /PID $logcatProc.Id /T /F 2>$null | Out-Null
    }

    $allLines = Get-Content -Path $LogPath -ErrorAction SilentlyContinue
    if ($allLines.Count -gt $linesPrinted) {
        $allLines[$linesPrinted..($allLines.Count - 1)] | Write-Host
    }

    return [PSCustomObject]@{ Status = $status; ResourceSamples = $resourceSamples; SampleFailures = $sampleFailures }
}

function Test-ApproachLog {
    param([string]$LogPath, [string]$InvalidLogPath)

    $validLines = New-Object System.Collections.Generic.List[string]
    $groupCounts = @{}
    $groupNs = @{}
    $hadInvalid = $false

    Get-Content -Path $LogPath -ErrorAction SilentlyContinue | ForEach-Object {
        $rawLine = $_
        if ($rawLine -match 'PERF\s+(\{.*)$') {
            $jsonText = $Matches[1]
            try {
                $obj = $jsonText | ConvertFrom-Json -ErrorAction Stop
            } catch {
                $hadInvalid = $true
                Add-Content -Path $InvalidLogPath -Value $rawLine
                return
            }
            $validLines.Add($jsonText)
            if ($null -ne $obj.n) {
                $runPart = if ($null -ne $obj.run) { $obj.run } else { 0 }
                $groupKey = "$($obj.approach)|$($obj.scenario)|$($obj.key)|$runPart"
                $count = @($obj.samples).Count
                if (-not $groupCounts.ContainsKey($groupKey)) { $groupCounts[$groupKey] = 0 }
                $groupCounts[$groupKey] += $count
                $groupNs[$groupKey] = [int]$obj.n
            }
        }
    }

    $incomplete = $false
    foreach ($k in $groupCounts.Keys) {
        if ($groupCounts[$k] -ne $groupNs[$k]) { $incomplete = $true }
    }

    $downgrade = $null
    if ($hadInvalid) { $downgrade = 'truncated' }
    elseif ($incomplete) { $downgrade = 'incomplete' }

    return [PSCustomObject]@{ Downgrade = $downgrade; ValidLines = $validLines }
}

# A passada com -SampleResources grava em outra pasta por padrão: nunca sobrescreve a coleta limpa.
if ($SampleResources -and -not $PSBoundParameters.ContainsKey('OutDir')) { $OutDir = 'results_recursos' }
if (Test-Path (Join-Path $OutDir 'perf.jsonl')) {
    Write-Warning "'$OutDir\perf.jsonl' já existe e será SOBRESCRITO no fim desta execução (copie antes se quiser guardá-lo)."
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$flutterVersion = Get-FlutterVersion
Write-Host "Flutter: $flutterVersion | Device: $Device | Repeats: $Repeats | Order: $orderText | Quick: $($Quick.IsPresent)"

& $Adb -s $Device shell svc power stayon usb

$invalidLogPath = Join-Path $OutDir 'invalid.log'
if (Test-Path $invalidLogPath) { Remove-Item $invalidLogPath -Force }

$summary = New-Object System.Collections.Generic.List[object]
$allValidPerfLines = New-Object System.Collections.Generic.List[string]
$allResourceSamples = New-Object System.Collections.Generic.List[object]
$totalSampleFailures = 0
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

        $tempBefore = Wait-ForThermal
        $batteryBefore = Get-BatteryField -FieldName 'level'

        $logPath = Join-Path $runDir "${position}_$approach.log"

        $defines = @(
            "--dart-define=AUTO_APPROACH=$approach",
            "--dart-define=SESSION_ID=run$run",
            "--dart-define=RUN_ORDER=$orderText",
            "--dart-define=RUN_POSITION=$position",
            "--dart-define=APP_FLUTTER_VERSION=$flutterVersion"
        )
        if ($Quick) {
            $defines += '--dart-define=AUTO_QUICK=true'
        }

        $runResult = Invoke-ApproachRun -Approach $approach -Defines $defines -LogPath $logPath `
            -SampleResources $SampleResources.IsPresent -Package $Package -CpuCores $CpuCores
        $status = $runResult.Status

        $tempAfter = Get-BatteryTempC
        $batteryAfter = Get-BatteryField -FieldName 'level'

        foreach ($sample in $runResult.ResourceSamples) {
            $sample | Add-Member -NotePropertyName 'run' -NotePropertyValue $run
            $sample | Add-Member -NotePropertyName 'position' -NotePropertyValue $position
            $sample | Add-Member -NotePropertyName 'approach' -NotePropertyValue $approach
            $allResourceSamples.Add($sample)
        }
        if ($runResult.SampleFailures -gt 0) {
            $totalSampleFailures += $runResult.SampleFailures
            Write-Warning "  $approach (repeat $run, position $position): $($runResult.SampleFailures) resource sample(s) failed and were skipped"
        }

        if ($SampleResources) {
            $lcFile = "$logPath.logcat.log"
            $nSum = 0
            if (Test-Path $lcFile) { $nSum = @(Get-Content -Path $lcFile -ErrorAction SilentlyContinue | Where-Object { $_ -match 'PERFORMANCE SUMMARY' }).Count }
            if ($nSum -ne 4) { Write-Warning "  $approach (repeat $run): logcat has $nSum 'PERFORMANCE SUMMARY' lines (expected 4) - scenario windows can't be computed for this run." }
        }

        $validation = Test-ApproachLog -LogPath $logPath -InvalidLogPath $invalidLogPath
        $allValidPerfLines.AddRange($validation.ValidLines)
        if ($status -eq 'ok' -and $null -ne $validation.Downgrade) {
            $status = $validation.Downgrade
        }

        if ($status -ne 'ok') {
            Write-Warning "  $approach (repeat $run, position $position) status: $status — see $logPath"
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

$perfJsonlPath = Join-Path $OutDir 'perf.jsonl'
$allValidPerfLines | Set-Content -Path $perfJsonlPath -Encoding utf8

$resourcesCsvPath = Join-Path $OutDir 'resources.csv'
if ($allResourceSamples.Count -gt 0) {
    $allResourceSamples | Export-Csv -Path $resourcesCsvPath -NoTypeInformation -Encoding utf8
} elseif ($SampleResources.IsPresent) {
    Write-Warning "No resource samples were collected despite -SampleResources — check -Package ($Package) matches the installed app id."
}

$okCount = ($summary | Where-Object { $_.status -eq 'ok' }).Count
Write-Host ""
Write-Host "Done. $($summary.Count) runs, $okCount successful."
Write-Host "Run summary: $runsCsvPath"
Write-Host "Consolidated PERF lines: $perfJsonlPath ($($allValidPerfLines.Count) lines)"
if ($SampleResources.IsPresent) {
    Write-Host "CPU/memory samples: $resourcesCsvPath ($($allResourceSamples.Count) samples, $totalSampleFailures failed/skipped)"
    Write-Warning "This run had -SampleResources on — its own PERF timing numbers may be skewed by the sampling overhead (dumpsys meminfo runs inside the measured process). Use a separate run WITHOUT -SampleResources as the official timing source."
}
if (Test-Path $invalidLogPath) {
    $invalidCount = (Get-Content -Path $invalidLogPath).Count
    Write-Warning "Invalid/truncated PERF lines found: $invalidCount — see $invalidLogPath"
}