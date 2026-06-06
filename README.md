# MarketLab

MarketLab is a fake-money prediction market app for the Cursor workshop.

## Setup

Open this repo in Cursor and run the setup command for your operating system.

### macOS / Linux

```bash
bash ./scripts/unix-setup.sh
```

### Windows

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
```

If `pwsh` is not available:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
```

After setup finishes, open a new Cursor terminal.

If a new PowerShell window still reports that `task` is not recognized, your
execution policy is likely blocking the PowerShell profile that activates mise.
Allow it once for your user, then open a new PowerShell window:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

## Run

```bash
task dev
```

Open [http://localhost:3000](http://localhost:3000).
