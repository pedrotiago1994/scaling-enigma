param(
    [string]$ConfigPath = "$env:USERPROFILE\.codex\config.toml",
    [switch]$InstallVcRedist,
    [switch]$EnableWsl
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}

function Ensure-Config {
    param([string]$Path)

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if (-not (Test-Path $Path)) {
        "# Arquivo criado automaticamente para diagnóstico do Codex`n" | Set-Content -Path $Path -Encoding UTF8
    }

    $backup = "$Path.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -Path $Path -Destination $backup -Force
    Write-Host "Backup criado em: $backup"

    $content = Get-Content -Path $Path -Raw

    if ($content -notmatch '(?m)^\[execution\]\s*$') {
        $content += "`n[execution]`n"
    }

    $useWslValue = if ($EnableWsl) { 'true' } else { 'false' }

    if ($content -match '(?m)^\s*use_wsl\s*=\s*(true|false)\s*$') {
        $content = [regex]::Replace($content, '(?m)^\s*use_wsl\s*=\s*(true|false)\s*$', "use_wsl = $useWslValue")
    } else {
        $content = [regex]::Replace($content, '(?m)^\[execution\]\s*$', "[execution]`r`nuse_wsl = $useWslValue")
    }

    if ($content -notmatch '(?m)^\[logs\]\s*$') {
        $content += "`n[logs]`n"
    }

    if ($content -match '(?m)^\s*level\s*=\s*"[^"]+"\s*$') {
        $content = [regex]::Replace($content, '(?m)^\s*level\s*=\s*"[^"]+"\s*$', 'level = "debug"')
    } else {
        $content = [regex]::Replace($content, '(?m)^\[logs\]\s*$', "[logs]`r`nlevel = `"debug`"")
    }

    Set-Content -Path $Path -Value $content -Encoding UTF8
    Write-Host "config.toml atualizado em: $Path"
}

function Test-VcRedistInstalled {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $v = Get-ItemProperty -Path $p -ErrorAction SilentlyContinue
            if ($null -ne $v -and $v.Installed -eq 1) {
                return $true
            }
        }
    }

    return $false
}

function Install-VcRedist {
    Write-Step "Instalando/atualizando Microsoft VC++ Redistributable (x64)"

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget não encontrado. Instale o App Installer da Microsoft Store e execute novamente."
    }

    winget install --id Microsoft.VCRedist.2015+.x64 --accept-package-agreements --accept-source-agreements --silent
}

Write-Step "Aplicando correções do Codex (erro 3221225781 / 0xC0000135)"
Ensure-Config -Path $ConfigPath

$hasVc = Test-VcRedistInstalled
if ($hasVc) {
    Write-Host "VC++ Redistributable x64 já está instalado."
} elseif ($InstallVcRedist) {
    Install-VcRedist
} else {
    Write-Warning "VC++ Redistributable x64 não detectado. Rode com -InstallVcRedist para instalar automaticamente."
}

Write-Step "Concluído"
Write-Host "Próximos passos:"
Write-Host "1) Reinicie o VS Code"
Write-Host "2) Se necessário, clique em 'Recarregar' na extensão Codex"
Write-Host "3) Se ainda falhar, rode novamente com -EnableWsl para testar execução no WSL"
