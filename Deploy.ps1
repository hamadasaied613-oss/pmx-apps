<#
.SYNOPSIS
    PMX Deployment Script - merge of check_dns.ps1 + deploy_domain.ps1 + deploy logic
.PARAMETER Sync
    Sync public files from main repo and push to GitHub Pages
.PARAMETER CheckDNS
    Check pmxs.space DNS propagation (one-time)
.PARAMETER Continuous
    Used with -CheckDNS: poll until resolved
.PARAMETER DeployDomain
    Set CNAME on GitHub Pages after DNS resolves
.PARAMETER Full
    Run: CheckDNS (if resolved) -> DeployDomain -> Sync
#>

param(
    [switch]$Sync,
    [switch]$CheckDNS,
    [switch]$Continuous,
    [switch]$DeployDomain,
    [switch]$Full
)

$Domain = "pmxs.space"
$Repo = "hamadasaied613-oss/pmx-apps"
$BotToken = "8765968989:AAHDelDZZkFcUCRa09lqtQmh7VBGl50EMUA"
$ChatId = "6544206847"
$Root = Resolve-Path "$PSScriptRoot\.."
$StartTime = Get-Date "2026-06-30T12:57:02Z"

function Write-Log { param([string]$M) Write-Host "$(Get-Date -Format 'HH:mm:ss') $M" }

function Send-Telegram {
    param([string]$Message)
    try { $body = @{ chat_id = $ChatId; text = $Message; parse_mode = "Markdown" } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Log "[TELEGRAM] Sent" } catch { Write-Log "[TELEGRAM] Failed" }
}

function Test-DnsRecord {
    $a = Resolve-DnsName $Domain -Type A -Server 8.8.8.8 -ErrorAction SilentlyContinue
    if ($a) { return $true, ($a | ForEach-Object { $_.IPAddress }) }
    $a = Resolve-DnsName $Domain -Type A -ErrorAction SilentlyContinue
    if ($a) { return $true, ($a | ForEach-Object { $_.IPAddress }) }
    return $false, @()
}

# === CHECK DNS ===
if ($CheckDNS -or $Full) {
    Write-Log "[DNS] Checking $Domain..."
    do {
        $ok, $ips = Test-DnsRecord
        $elapsed = [math]::Round(((Get-Date).ToUniversalTime() - $StartTime).TotalHours, 1)
        if ($ok) {
            Write-Log "[DNS] RESOLVED after ${elapsed}h" -ForegroundColor Green
            $ips | ForEach-Object { Write-Log "  IP: $_" }
            Send-Telegram "[DNS] $Domain resolved after ${elapsed}h - A records: $($ips -join ', ')"
            if (-not $Continuous -and -not $Full) { return }
            break
        } else {
            Write-Log "[DNS] NOT resolving (${elapsed}h)" -ForegroundColor Yellow
            if (-not $Continuous -and -not $Full) { return }
            Start-Sleep -Seconds 300
        }
    } while ($Continuous -or $Full)
}

# === DEPLOY DOMAIN ===
if ($DeployDomain -or $Full) {
    if ($Full) { $ok, $ips = Test-DnsRecord; if (-not $ok) { Write-Log "[DNS] Not resolved - aborting Full"; return } }
    Write-Log "[DOMAIN] Setting CNAME $Domain on GitHub Pages..."
    try {
        $r = gh api repos/$Repo/pages -X PUT -f cname=$Domain --jq '.cname' 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Log "[DOMAIN] CNAME set: $r" -ForegroundColor Green }
        else { throw $r }
    } catch { Write-Log "[DOMAIN] Failed: $_" -ForegroundColor Red; return }
    $waited = 0; $maxWait = 300
    while ($waited -lt $maxWait) {
        try { $r = Invoke-WebRequest "https://$Domain" -UseBasicParsing -ErrorAction Stop
            Write-Log "[HTTPS] Provisioned! Status $($r.StatusCode)" -ForegroundColor Green
            Send-Telegram "[DEPLOY] $Domain live with HTTPS" ; break }
        catch { Start-Sleep -Seconds 30; $waited += 30; Write-Log "[HTTPS] Waiting (${waited}s)..." }
    }
    if ($waited -ge $maxWait) { Write-Log "[HTTPS] Timeout - check manually" -ForegroundColor Yellow }
    if ($Full) { return }
}

# === SYNC ===
if ($Sync -or ($Full -and -not $CheckDNS -and -not $DeployDomain)) {
    Write-Log "[SYNC] Deploying public files..."
    Set-Location $PSScriptRoot
    if (Test-Path "$Root\apps") { Copy-Item "$Root\apps\*" "apps\" -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path "$Root\pmx-ui") { Copy-Item "$Root\pmx-ui\*" "pmx-ui\" -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path "$Root\assets") { Copy-Item "$Root\assets\*" "assets\" -Recurse -Force -ErrorAction SilentlyContinue }
    Copy-Item "$Root\index.html" "index.html" -Force -ErrorAction SilentlyContinue
    if (Test-Path "$Root\CNAME") { Remove-Item "CNAME" -Force -ErrorAction SilentlyContinue }
    git add -A
    git commit -m "Deploy $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
    git push origin master 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Log "[SYNC] Pushed" -ForegroundColor Green; Send-Telegram "[DEPLOY] Public apps deployed" }
    else { Write-Log "[SYNC] Push failed - pull first" -ForegroundColor Red }
}

if (-not $CheckDNS -and -not $DeployDomain -and -not $Sync -and -not $Full) {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\Deploy.ps1 -Sync              # Deploy public files"
    Write-Host "  .\Deploy.ps1 -CheckDNS          # One-time DNS check"
    Write-Host "  .\Deploy.ps1 -CheckDNS -Continuous  # Monitor DNS"
    Write-Host "  .\Deploy.ps1 -DeployDomain      # Set CNAME (after DNS)"
    Write-Host "  .\Deploy.ps1 -Full              # All steps sequentially"
}
