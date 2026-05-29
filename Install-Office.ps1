#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Write-Header($msg) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}
function Write-Step($msg) { Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-OK($msg)   { Write-Host "[+] $msg" -ForegroundColor Green  }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Red    }

# STEP 1: Detect and uninstall existing Office
Write-Header "STEP 1 - Detecting Existing Microsoft Office"

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$officeProducts = @()
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $officeProducts += Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -match "Microsoft Office|Microsoft 365|Office 16|Office 15|Office 14" -and
                $_.DisplayName -notmatch "Visual C\+\+|\.NET|Runtime"
            }
    }
}

if ($officeProducts.Count -eq 0) {
    Write-OK "No existing Microsoft Office found. Skipping uninstall."
} else {
    Write-Warn "Found $($officeProducts.Count) Office product(s):"
    foreach ($p in $officeProducts) {
        Write-Host "    - $($p.DisplayName)" -ForegroundColor Magenta
    }

    Write-Step "Uninstalling..."

    foreach ($product in $officeProducts) {
        $name = $product.DisplayName
        Write-Step "Uninstalling: $name"

        $uninstallCmd = ""
        if ($product.QuietUninstallString) {
            $uninstallCmd = $product.QuietUninstallString
        } elseif ($product.UninstallString) {
            $uninstallCmd = $product.UninstallString
        }

        if ($uninstallCmd -eq "") {
            Write-Warn "No uninstall string for '$name' - skipping."
            continue
        }

        if ($uninstallCmd -match "msiexec") {
            $uninstallCmd = $uninstallCmd -replace "/I", "/X" -replace "/i", "/X"
            if ($uninstallCmd -notmatch "/quiet|/qn|/qb") {
                $uninstallCmd += " /quiet /norestart"
            }
        }

        try {
            $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninstallCmd`"" -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                Write-OK "'$name' uninstalled successfully."
            } else {
                Write-Warn "'$name' exited with code $($proc.ExitCode)."
            }
        } catch {
            Write-Warn "Error uninstalling '$name': $_"
        }
    }

    Write-OK "Uninstall phase complete."
}

# STEP 2: Create C:\Office
Write-Header "STEP 2 - Creating C:\Office Folder"

$officeDir = "C:\Office"
if (Test-Path $officeDir) {
    Write-OK "Folder '$officeDir' already exists."
} else {
    New-Item -ItemType Directory -Path $officeDir | Out-Null
    Write-OK "Folder '$officeDir' created."
}

# STEP 3: Download files
Write-Header "STEP 3 - Downloading Office Deployment Tool Files"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$files = @(
    @{ Url = "https://github.com/mueezejaz/msofficeInstallationScript/releases/download/0.0.1/setup.exe"; Dest = "$officeDir\setup.exe"; Name = "setup.exe" },
    @{ Url = "https://github.com/mueezejaz/msofficeInstallationScript/releases/download/0.0.1/Configuration.xml"; Dest = "$officeDir\Configuration.xml"; Name = "Configuration.xml" }
)

foreach ($file in $files) {
    Write-Step "Downloading $($file.Name)..."
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile $file.Dest -UseBasicParsing
        $size = (Get-Item $file.Dest).Length
        Write-OK "$($file.Name) downloaded ($size bytes)"
    } catch {
        Write-Warn "Failed to download $($file.Name): $_"
        exit 1
    }
}

# STEP 4: Install Office
Write-Header "STEP 4 - Installing Microsoft Office"

$setupExe = "$officeDir\setup.exe"
$configXml = "$officeDir\Configuration.xml"

if (-not (Test-Path $setupExe)) {
    Write-Warn "setup.exe not found. Aborting."
    exit 1
}
if (-not (Test-Path $configXml)) {
    Write-Warn "Configuration.xml not found. Aborting."
    exit 1
}

Write-Step "Running: $setupExe /configure `"$configXml`""

try {
    $install = Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configXml`"" -Wait -PassThru -NoNewWindow
    if ($install.ExitCode -eq 0) {
        Write-OK "Office installation completed successfully!"
    } else {
        Write-Warn "Setup exited with code $($install.ExitCode). Check logs in %TEMP% for details."
        exit $install.ExitCode
    }
} catch {
    Write-Warn "Error during installation: $_"
    exit 1
}

Write-Header "ALL DONE"
Write-OK "Microsoft Office installed. You may need to restart your PC."
