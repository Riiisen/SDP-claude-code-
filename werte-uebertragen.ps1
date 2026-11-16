# werte-uebertragen.ps1
# Liest die beste Zeile (Spalte "Beste" = x) aus pid-tuning.csv, traegt
# KP, KD, BASE_POWER und SLOW_PCT in meilenstein.nxc ein, kompiliert und
# uebertraegt das Programm per USB auf den NXT.
# Start: Doppelklick auf werte-uebertragen.bat

$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvPath = Join-Path $here 'pid-tuning.csv'
$nxcPath = Join-Path $here 'meilenstein.nxc'

function Fail($msg) {
    Write-Host ""
    Write-Host "FEHLER: $msg" -ForegroundColor Red
    exit 1
}

# ---------- 1. Beste Zeile aus der Tabelle holen ----------
if (-not (Test-Path $csvPath)) { Fail "pid-tuning.csv nicht gefunden." }
$rows = Import-Csv -Path $csvPath -Delimiter ';' -Encoding UTF8
$best = @($rows | Where-Object { $_.Beste -and $_.Beste.Trim().ToLower() -eq 'x' })
if ($best.Count -eq 0) { Fail "Keine Zeile mit 'x' in der Spalte 'Beste'. Bitte die beste Zeile markieren." }
if ($best.Count -gt 1) {
    Write-Host "Hinweis: $($best.Count) Zeilen mit 'x' markiert, nehme die letzte." -ForegroundColor Yellow
}
$row = $best[-1]

$values = [ordered]@{}
foreach ($pair in @(@('KP','KP'), @('KD','KD'), @('BASE_POWER','BASE'), @('SLOW_PCT','SLOW'))) {
    $define = $pair[0]; $column = $pair[1]
    $text = "$($row.$column)".Trim()
    $num = 0
    if (-not [int]::TryParse($text, [ref]$num)) { Fail "Spalte '$column' enthaelt keine ganze Zahl: '$text'." }
    $values[$define] = $num
}
if ($values['BASE_POWER'] -lt 0 -or $values['BASE_POWER'] -gt 100) { Fail "BASE muss zwischen 0 und 100 liegen." }
if ($values['SLOW_PCT'] -lt 0 -or $values['SLOW_PCT'] -gt 90)      { Fail "SLOW muss zwischen 0 und 90 liegen." }

Write-Host "Beste Zeile vom $($row.Datum): $($row.Stelle) - $($row.Ergebnis)"
foreach ($k in $values.Keys) { Write-Host ("  {0,-11} = {1}" -f $k, $values[$k]) }

# ---------- 2. Werte in meilenstein.nxc eintragen ----------
if (-not (Test-Path $nxcPath)) { Fail "meilenstein.nxc nicht gefunden." }
$code = [IO.File]::ReadAllText($nxcPath)
foreach ($k in $values.Keys) {
    $pattern = "(?m)^(#define\s+$k\s+)-?\d+"
    if ($code -notmatch $pattern) { Fail "#define $k nicht in meilenstein.nxc gefunden." }
    $code = [regex]::Replace($code, $pattern, ('${1}' + $values[$k]), 1)
}
[IO.File]::WriteAllText($nxcPath, $code, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Werte in meilenstein.nxc eingetragen."

# ---------- 3. Compiler aus dem Kurs-Plugin suchen ----------
$extRoot = Join-Path $env:USERPROFILE '.vscode\extensions'
$ext = Get-ChildItem $extRoot -Directory -Filter 'uni-freiburg-imtek.nxt-compiler-*' -ErrorAction SilentlyContinue |
       Sort-Object { [version]($_.Name -replace '^.*-(\d+\.\d+\.\d+).*$', '$1') } -Descending |
       Select-Object -First 1
if (-not $ext) { Fail "VS-Code-Plugin 'nxt-compiler' nicht gefunden." }
$nbc = Join-Path $ext.FullName 'bin\win32-x64\nbc.exe'
if (-not (Test-Path $nbc)) { Fail "nbc.exe nicht gefunden in $($ext.FullName)." }

# ---------- 4. NXT angeschlossen? ----------
$dev = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match 'VID_0694' -and $_.Status -eq 'OK' }
if (-not $dev) { Fail "NXT nicht per USB gefunden. Einschalten, Kabel direkt am Laptop einstecken, nochmal starten." }

# ---------- 5. Kompilieren und uebertragen ----------
Write-Host "Kompiliere und uebertrage ..."
$output = & $nbc -S=usb -d $nxcPath 2>&1
$exit = $LASTEXITCODE
$errors = $output | Where-Object { "$_" -match 'Error|line \d+' }
if ($exit -ne 0) {
    $errors | ForEach-Object { Write-Host "  $_" }
    Fail "Uebertragung fehlgeschlagen (Code $exit). NXT aus- und einschalten, Kabel neu einstecken."
}
Write-Host ""
Write-Host "Fertig: meilenstein mit den besten Werten ist auf dem NXT." -ForegroundColor Green
