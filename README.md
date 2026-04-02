# scaling-enigma

## Correção para o erro `code=3221225781 (0xC0000135)` no Codex

Esse erro normalmente indica que um processo do Codex foi iniciado no Windows sem dependências necessárias (DLL/runtime ausente) **ou** com configuração de execução incompatível no WSL.

## Baixar e executar no seu computador (sem erro de caminho)

Se você ainda não tem o repositório local, faça assim:

1. Baixe este projeto como ZIP e extraia para uma pasta real, por exemplo:
   `C:\Users\SEU_USUARIO\Downloads\scaling-enigma`
2. Abra o PowerShell e execute exatamente:

```powershell
$repo = "$env:USERPROFILE\Downloads\scaling-enigma"
Test-Path "$repo\scripts\fix-codex-3221225781.ps1"
```

### Se aparecer erro de parser na linha 50 (`debug` inesperado)
Isso indica que você está com uma versão antiga do script dentro do ZIP.

Corrija rápido no seu PC com este patch automático:

```powershell
$script = Get-ChildItem "$env:USERPROFILE\Downloads\scaling-enigma-codex-fix-this-error" -Recurse -Filter "fix-codex-3221225781.ps1" | Select-Object -First 1 -ExpandProperty FullName
(Get-Content $script -Raw).Replace('[logs]`r`nlevel = "debug"','[logs]`r`nlevel = ' + '"debug"') | Set-Content $script -Encoding UTF8
powershell -ExecutionPolicy Bypass -File $script
```

Opcional: confirme a versão do script:

```powershell
Select-String -Path $script -Pattern "Script-Version"
```

### Plano B (mais rápido): criar e rodar script sem ZIP
Se o `$script` vier vazio/null, pule o ZIP e rode este bloco único:

```powershell
$localDir = Join-Path $env:TEMP "codex-fix"
$null = New-Item -ItemType Directory -Path $localDir -Force
$localScript = Join-Path $localDir "fix-codex-now.ps1"
@'
param([switch]$EnableWsl)
$config = "$env:USERPROFILE\.codex\config.toml"
$dir = Split-Path -Parent $config
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
if (-not (Test-Path $config)) { "# criado automaticamente`n" | Set-Content $config -Encoding UTF8 }
$content = Get-Content $config -Raw
if ($content -notmatch '(?m)^\[execution\]\s*$') { $content += "`n[execution]`n" }
$useWsl = if ($EnableWsl) { 'true' } else { 'false' }
if ($content -match '(?m)^\s*use_wsl\s*=\s*(true|false)\s*$') {
  $content = [regex]::Replace($content, '(?m)^\s*use_wsl\s*=\s*(true|false)\s*$', "use_wsl = $useWsl")
} else {
  $content = [regex]::Replace($content, '(?m)^\[execution\]\s*$', "[execution]`r`nuse_wsl = $useWsl")
}
if ($content -notmatch '(?m)^\[logs\]\s*$') { $content += "`n[logs]`n" }
if ($content -match '(?m)^\s*level\s*=\s*"[^"]+"\s*$') {
  $content = [regex]::Replace($content, '(?m)^\s*level\s*=\s*"[^"]+"\s*$', 'level = "debug"')
} else {
  $content = [regex]::Replace($content, '(?m)^\[logs\]\s*$', "[logs]`r`nlevel = " + '"debug"')
}
Set-Content -Path $config -Value $content -Encoding UTF8
Write-Host "OK: config atualizada em $config"
'@ | Set-Content -Path $localScript -Encoding UTF8

powershell -ExecutionPolicy Bypass -File $localScript
Write-Host "Script salvo em: $localScript"
```

### Se você baixou ZIP (pasta compactada)
Pelo seu print, o arquivo está como **pasta compactada** (`scaling-enigma-codex-fix-this-error`) e ainda não foi extraído.

Extraia e rode assim:

```powershell
$zip = "$env:USERPROFILE\Downloads\scaling-enigma-codex-fix-this-error.zip"
$dest = "$env:USERPROFILE\Downloads\scaling-enigma-codex-fix-this-error"
Expand-Archive -Path $zip -DestinationPath $dest -Force
```

Depois encontre automaticamente o script:

```powershell
$script = Get-ChildItem "$dest" -Recurse -Filter "fix-codex-3221225781.ps1" | Select-Object -First 1 -ExpandProperty FullName
$script
```

Se apareceu um caminho, execute:

```powershell
powershell -ExecutionPolicy Bypass -File "$script"
```

Se retornar `True`, execute:

```powershell
powershell -ExecutionPolicy Bypass -File "$repo\scripts\fix-codex-3221225781.ps1"
```

Com instalação automática do VC++:

```powershell
powershell -ExecutionPolicy Bypass -File "$repo\scripts\fix-codex-3221225781.ps1" -InstallVcRedist
```

> No seu print, o erro ocorreu porque `C:\caminho\para\...` era apenas exemplo e não um diretório real.

---

### Se o `config.toml` já está correto e o erro continua
Quando o arquivo já está assim:

```toml
[execution]
use_wsl = false
[logs]
level = "debug"
```

...e mesmo assim aparece `3221225781`, normalmente falta runtime do Windows.

Execute no PowerShell (Administrador):

```powershell
winget install --id Microsoft.VCRedist.2015+.x64 --accept-package-agreements --accept-source-agreements --silent
```

Depois:
1. Reinicie o Windows.
2. Abra o VS Code.
3. Recarregue a extensão Codex.

Se ainda falhar, teste com WSL habilitado:

```powershell
(Get-Content "$env:USERPROFILE\.codex\config.toml" -Raw).Replace('use_wsl = false','use_wsl = true') | Set-Content "$env:USERPROFILE\.codex\config.toml" -Encoding UTF8
```

## Dá para fazer isso automaticamente no seu computador?
Sim — eu não consigo executar diretamente no seu PC remoto, mas deixei um script PowerShell para você rodar e automatizar quase tudo.

Arquivo: `scripts/fix-codex-3221225781.ps1`

### Execução rápida (PowerShell como usuário normal)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fix-codex-3221225781.ps1
```

### Importante: erro "arquivo .ps1 não existe"
Se aparecer essa mensagem, você está executando o comando fora da pasta do projeto (ex.: `C:\Windows\System32`).

Faça assim:

```powershell
cd "C:\caminho\para\scaling-enigma"
Test-Path .\scripts\fix-codex-3221225781.ps1
```

Se o `Test-Path` retornar `True`, rode:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fix-codex-3221225781.ps1
```

Ou execute com caminho absoluto:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\caminho\para\scaling-enigma\scripts\fix-codex-3221225781.ps1"
```

### Instalar VC++ automaticamente também

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fix-codex-3221225781.ps1 -InstallVcRedist
```

### Testar com WSL habilitado

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fix-codex-3221225781.ps1 -EnableWsl
```

---

## O que o script faz

1. Cria backup do `config.toml` do Codex.
2. Garante/ajusta:
   - `[execution]` com `use_wsl = false` (ou `true` se usar `-EnableWsl`)
   - `[logs]` com `level = "debug"`
3. Verifica se o **VC++ Redistributable x64** já existe no registro do Windows.
4. Se você passar `-InstallVcRedist`, tenta instalar via `winget`.

---

## Passo a passo manual (se preferir)

### Passo 1 — validar e limpar `config.toml`
Abra o `config.toml` do Codex e remova entradas antigas/inválidas.

Use uma configuração mínima para testar:

```toml
# Exemplo de config mínima para diagnóstico
[execution]
# Em caso de erro no WSL, force execução nativa no Windows
use_wsl = false

[logs]
level = "debug"
```

> Se o seu arquivo já tiver outras seções, mantenha-as, mas confirme se não há chaves duplicadas ou nomes incorretos.

### Passo 2 — confirmar runtimes do Windows
O código `0xC0000135` também pode ser causado por runtime ausente.

1. Instale/atualize **Microsoft Visual C++ Redistributable 2015–2022** (x64).
2. Reinicie o Windows.
3. Abra novamente o VS Code/Codex.

### Passo 3 — testar com e sem WSL
Se você usa WSL, teste as duas opções:

- `use_wsl = false` (nativo Windows)
- `use_wsl = true` (WSL)

Mantenha a opção que não reproduz o erro.

### Passo 4 — reset da extensão Codex
Se continuar falhando:

1. Feche o VS Code.
2. Reabra e clique em **Recarregar** na janela de erro.
3. Se persistir, reinstale a extensão do Codex e teste novamente.

### Passo 5 — coletar logs para diagnóstico final
Com `level = "debug"`, reproduza o erro e anexe os logs do Codex para identificar exatamente qual binário/dependência está faltando.

---

## Resumo rápido
- `3221225781 = 0xC0000135` → dependência de runtime ausente/incompatível.
- Primeira ação recomendada: desabilitar WSL no `config.toml` para teste.
- Segunda ação recomendada: instalar VC++ Redistributable e reiniciar.
- Para agilizar: rode `scripts/fix-codex-3221225781.ps1`.
