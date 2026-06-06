# MarketLab Windows setup
# Installs mise via Scoop when available, activates it, and runs project setup tasks.
# Run from project root:
#   pwsh -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
# or:
#   powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1

[CmdletBinding()]
param(
    [switch]$SkipHooks
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

# --- 1. Verify project root ----------------------------------------------------
if (-not (Test-Path "mise.toml")) {
    throw "mise.toml not found. Run this script from the project root."
}

# --- 2. Install mise -----------------------------------------------------------

if (-not (Test-Command "scoop")){
    Write-Step "Installing Scoop"
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
} else {
    Write-Step "Scoop already installed"
}

if (-not (Test-Command "mise")) {
    if (Test-Command "scoop") {
        Write-Step "Installing mise via Scoop"
        Invoke-NativeCommand -Command "scoop" -Arguments @("install", "mise")
    } else {
        throw @"
mise was not found, and Scoop is not installed.

Install mise first, then rerun this script:
  https://mise.jdx.dev/installing-mise.html

If you use Scoop, install it from https://scoop.sh/ and run:
  scoop install mise
"@
    }
} else {
    Write-Step "mise already installed"
}

# --- 2b. Install Visual C++ 2022 runtime (mise depends on it) ------------------
# A clean Windows install lacks the MSVC runtime DLLs that mise.exe needs to run.
# Without them, `mise activate pwsh` fails with exit code -1073741515
# (0xC0000135, STATUS_DLL_NOT_FOUND). Scoop itself suggests extras/vcredist2022.
Write-Step "Ensuring Visual C++ 2022 runtime (vcredist2022)"
# Scoop needs Git to manage any bucket other than 'main' (e.g. 'extras').
if (-not (Test-Command "git")) {
    Write-Step "Installing Git via Scoop"
    Invoke-NativeCommand -Command "scoop" -Arguments @("install", "git")
}
$buckets = & scoop bucket list
if (-not ($buckets -match "extras")) {
    Invoke-NativeCommand -Command "scoop" -Arguments @("bucket", "add", "extras")
}
Invoke-NativeCommand -Command "scoop" -Arguments @("install", "vcredist2022")

# --- 3. Activate mise in current session + persist in PowerShell profile ------
Write-Step "Activating mise in current session"
$activationScript = & mise activate pwsh
if ($LASTEXITCODE -ne 0) {
    throw "mise activate pwsh failed with exit code $LASTEXITCODE."
}
$activationScript | Out-String | Invoke-Expression

$profilePath = $PROFILE.CurrentUserAllHosts
$activationLine = '(& mise activate pwsh) | Out-String | Invoke-Expression'
$profileParent = Split-Path -Parent $profilePath

if (-not (Test-Path $profileParent)) {
    New-Item -Path $profileParent -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
}

if (-not (Select-String -Path $profilePath -Pattern 'mise activate pwsh' -Quiet)) {
    Write-Step "Adding mise activation to PowerShell profile: $profilePath"
    $profileContent = Get-Content -Path $profilePath -Raw
    if ($profileContent -and -not $profileContent.EndsWith("`n")) {
        Add-Content -Path $profilePath -Value ""
    }
    Add-Content -Path $profilePath -Value $activationLine
} else {
    Write-Step "PowerShell profile already activates mise"
}

# --- 4. Trust and install project tools ---------------------------------------
Write-Step "mise trust"
Invoke-NativeCommand -Command "mise" -Arguments @("trust")

Write-Step "mise install (node, bun, gh, prek, supabase, task)"
Invoke-NativeCommand -Command "mise" -Arguments @("install")

# --- 5. Project setup ----------------------------------------------------------
Write-Step "Running task setup"
Invoke-NativeCommand -Command "task" -Arguments @("setup")

# --- 6. prek hooks -------------------------------------------------------------
if (-not $SkipHooks) {
    Write-Step "Running task hooks:install"
    Invoke-NativeCommand -Command "task" -Arguments @("hooks:install")
}

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Open a new window with the same PowerShell executable you used for this script (so mise activation loads) and run:" -ForegroundColor Yellow
Write-Host "  task dev" -ForegroundColor Yellow
