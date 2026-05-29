# Microsoft Office Silent Installer

Automated PowerShell script that detects and removes any existing Microsoft Office installation, then silently installs a fresh copy using the Office Deployment Tool.

---

## How to Run

### Option 1 - One Line Command (Recommended)

Open PowerShell as Administrator and run:

```powershell
irm https://github.com/mueezejaz/msofficeInstallationScript/releases/download/0.0.1/Install-Office.ps1 | iex
```

### Option 2 - Clone the Repository

```powershell
git clone https://github.com/mueezejaz/msofficeInstallationScript.git
```

Navigate into the folder:

```powershell
cd msofficeInstallationScript
```

Run the script:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; .\Install-Office.ps1
```

---

## How It Works

**Step 1 - Detects existing Office**
The script scans the Windows registry for any installed Microsoft Office or Microsoft 365 products and lists them.

**Step 2 - Uninstalls existing Office**
If any Office installation is found, the script silently uninstalls it before proceeding. This avoids conflicts during the new installation.

**Step 3 - Creates C:\Office folder**
A dedicated folder is created at `C:\Office` to store the installation files.

**Step 4 - Downloads installation files**
The script downloads `setup.exe` (Office Deployment Tool) and `Configuration.xml` (install configuration) directly from this repository into `C:\Office`.

**Step 5 - Installs Microsoft Office**
Runs the Office Deployment Tool with the provided configuration file to silently install Office.

---

## Notes

- Do not close the PowerShell window during installation
- The installation may take several minutes depending on your internet speed
- A restart may be required after installation completes
