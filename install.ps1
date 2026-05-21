param(
    [string]$PowerShellProfilePath,
    [switch]$InstallScoopApps,
    [switch]$InstallWingetApps,
    [switch]$NoBackup,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupRoot = Join-Path $HOME ".dotfiles-backup"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Ensure-Directory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return
    }

    if ($DryRun) {
        Write-Host "[dry-run] create directory: $Path"
        return
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Backup-File {
    param([string]$Path)

    if ($NoBackup -or -not (Test-Path -LiteralPath $Path)) {
        return
    }

    $relative = $Path -replace "^[A-Za-z]:\\", ""
    $backupPath = Join-Path (Join-Path $BackupRoot $Timestamp) $relative
    $backupDir = Split-Path -Parent $backupPath

    if ($DryRun) {
        Write-Host "[dry-run] backup: $Path -> $backupPath"
        return
    }

    Ensure-Directory $backupDir
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
}

function Install-File {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Warning "skip missing source: $Source"
        return
    }

    $destinationDir = Split-Path -Parent $Destination
    Ensure-Directory $destinationDir
    Backup-File $Destination

    if ($DryRun) {
        Write-Host "[dry-run] copy: $Source -> $Destination"
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "installed: $Destination"
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PwshProfilePath {
    if ($PowerShellProfilePath) {
        return $PowerShellProfilePath
    }

    $preferredPath = "F:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path -LiteralPath (Split-Path -Parent $preferredPath)) {
        return $preferredPath
    }

    if (Test-Command "pwsh") {
        $pwshProfile = pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost'
        if ($LASTEXITCODE -eq 0 -and $pwshProfile) {
            return $pwshProfile.Trim()
        }
    }

    return (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1")
}

function Get-ScoopRoot {
    if ($env:SCOOP -and (Test-Path -LiteralPath $env:SCOOP)) {
        return $env:SCOOP
    }

    $scoopCommand = Get-Command "scoop" -ErrorAction SilentlyContinue
    if ($scoopCommand -and $scoopCommand.Source) {
        $commandPath = $scoopCommand.Source
        $commandDir = Split-Path -Parent $commandPath
        if ((Split-Path -Leaf $commandDir) -eq "shims") {
            $rootFromShim = Split-Path -Parent $commandDir
            if (Test-Path -LiteralPath $rootFromShim) {
                return $rootFromShim
            }
        }
    }

    $defaultRoot = Join-Path $HOME "scoop"
    if (Test-Path -LiteralPath $defaultRoot) {
        return $defaultRoot
    }

    return $null
}

function Install-ScoopState {
    $appsPath = Join-Path $RepoRoot "scoop\apps.json"
    $bucketsPath = Join-Path $RepoRoot "scoop\buckets.txt"

    if (-not (Test-Command "scoop")) {
        Write-Warning "scoop is not available; skip Scoop restore"
        return
    }

    $scoopRoot = Get-ScoopRoot

    if (Test-Path -LiteralPath $bucketsPath) {
        Write-Step "Restore Scoop buckets"
        $existingBuckets = @()
        if ($scoopRoot) {
            $bucketsRoot = Join-Path $scoopRoot "buckets"
            if (Test-Path -LiteralPath $bucketsRoot) {
                $existingBuckets = @(Get-ChildItem -LiteralPath $bucketsRoot -Directory | Select-Object -ExpandProperty Name)
            }
        }

        Get-Content -LiteralPath $bucketsPath | Where-Object { $_.Trim() } | ForEach-Object {
            $bucket = $_.Trim()
            if ($existingBuckets -contains $bucket) {
                Write-Host "bucket exists: $bucket"
                return
            }

            if ($DryRun) {
                Write-Host "[dry-run] scoop bucket add $bucket"
                return
            }

            scoop bucket add $bucket
        }
    }

    if (Test-Path -LiteralPath $appsPath) {
        Write-Step "Restore Scoop apps"
        $state = Get-Content -LiteralPath $appsPath -Raw | ConvertFrom-Json
        $installedApps = @()
        if ($scoopRoot) {
            $appsRoot = Join-Path $scoopRoot "apps"
            if (Test-Path -LiteralPath $appsRoot) {
                $installedApps = @(Get-ChildItem -LiteralPath $appsRoot -Directory | Select-Object -ExpandProperty Name)
            }
        }

        foreach ($app in $state.apps) {
            if ($installedApps -contains $app.Name) {
                Write-Host "app exists: $($app.Name)"
                continue
            }

            if ($DryRun) {
                Write-Host "[dry-run] scoop install $($app.Name)"
                continue
            }

            scoop install $app.Name
        }
    }
}

function Install-WingetState {
    $packagesPath = Join-Path $RepoRoot "winget\packages.json"

    if (-not (Test-Path -LiteralPath $packagesPath)) {
        Write-Warning "skip missing winget package file: $packagesPath"
        return
    }

    if (-not (Test-Command "winget")) {
        Write-Warning "winget is not available; skip winget restore"
        return
    }

    Write-Step "Restore winget packages"

    if ($DryRun) {
        Write-Host "[dry-run] winget import --import-file `"$packagesPath`" --accept-package-agreements --accept-source-agreements --ignore-unavailable"
        return
    }

    winget import `
        --import-file $packagesPath `
        --accept-package-agreements `
        --accept-source-agreements `
        --ignore-unavailable
}

Write-Step "Install dotfiles from $RepoRoot"

$files = @(
    @{
        Source = "powershell\Microsoft.PowerShell_profile.ps1"
        Destination = Get-PwshProfilePath
    },
    @{
        Source = "git\.gitconfig"
        Destination = Join-Path $HOME ".gitconfig"
    },
    @{
        Source = "vscode\settings.json"
        Destination = Join-Path $env:APPDATA "Code\User\settings.json"
    },
    @{
        Source = "alacritty\alacritty.toml"
        Destination = Join-Path $env:APPDATA "alacritty\alacritty.toml"
    },
    @{
        Source = "wsl\.wslconfig"
        Destination = Join-Path $HOME ".wslconfig"
    }
)

foreach ($file in $files) {
    Install-File `
        -Source (Join-Path $RepoRoot $file.Source) `
        -Destination $file.Destination
}

if ($InstallScoopApps) {
    Install-ScoopState
}
else {
    Write-Host "skip Scoop apps; rerun with -InstallScoopApps to restore them"
}

if ($InstallWingetApps) {
    Install-WingetState
}
else {
    Write-Host "skip winget apps; rerun with -InstallWingetApps to restore them"
}

Write-Step "Done"
