param(
    [string]$Domain = "pmxs.space",
    [string]$Repo = "hamadasaied613-oss/pmx-apps",
    [string]$GithubToken = "",
    [switch]$Force
)

$BotToken = "8765968989:AAHDelDZZkFcUCRa09lqtQmh7VBGl50EMUA"
$ChatId = "6544206847"
$DeployLog = Join-Path $PSScriptRoot "deploy_domain.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath $DeployLog -Append -Encoding UTF8
    Write-Host "$timestamp $Message"
}

function Send-Telegram {
    param([string]$Message)
    $body = @{ chat_id = $ChatId; text = $Message; parse_mode = "Markdown" } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Log "[TELEGRAM] Notification sent"
    } catch {
        Write-Log "[TELEGRAM] Failed: $($_.Exception.Message)"
    }
}

function Test-DnsReady {
    Write-Log "[CHECK] Testing DNS resolution for $Domain..."
    $a = Resolve-DnsName -Name $Domain -Type A -ErrorAction SilentlyContinue
    if (-not $a) {
        Write-Log "[FAIL] $Domain does not resolve yet"
        return $false
    }
    $ips = $a | ForEach-Object { $_.IPAddress }
    $ghIps = @("185.199.108.153", "185.199.109.153", "185.199.110.153", "185.199.111.153")
    $match = $ips | Where-Object { $_ -in $ghIps } | Measure-Object
    if ($match.Count -eq 0) {
        Write-Log "[WARN] A records don't match GitHub Pages IPs: $($ips -join ', ')"
        if (-not $Force) {
            Write-Log "[ABORT] Use -Force to deploy anyway"
            return $false
        }
        Write-Log "[FORCE] Proceeding despite mismatch"
    }
    return $true
}

function Set-GithubCname {
    param([string]$Token)
    $headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github.v3+json"
    }
    $body = @{ cname = $Domain } | ConvertTo-Json
    Write-Log "[API] Setting CNAME $Domain on GitHub Pages for $Repo..."
    try {
        $result = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/pages" -Method Put -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec 30
        Write-Log "[OK] CNAME set successfully"
        return $null
    } catch {
        $err = $_.Exception.Message
        Write-Log "[FAIL] GitHub API error: $err"
        return $err
    }
}

function Wait-Https {
    Write-Log "[HTTPS] Waiting for Let's Encrypt provisioning (up to 10 min)..."
    $maxWait = 600
    $waited = 0
    $url = "https://$Domain"
    while ($waited -lt $maxWait) {
        try {
            $req = [System.Net.WebRequest]::Create($url)
            $req.Timeout = 10000
            $resp = $req.GetResponse()
            $status = [int]$resp.StatusCode
            $resp.Close()
            if ($status -eq 200) {
                Write-Log "[HTTPS] Provisioned! $url returns 200"
                return $true
            }
        } catch {
            Write-Log "[HTTPS] Not ready yet (${waited}s)..."
        }
        Start-Sleep -Seconds 30
        $waited += 30
    }
    Write-Log "[HTTPS] Timeout after ${maxWait}s - check manually later"
    return $false
}

# === MAIN ===
Write-Log "==================================="
Write-Log "  PMX DOMAIN DEPLOYMENT"
Write-Log "  Domain: $Domain"
Write-Log "  Repo: $Repo"
Write-Log "==================================="

if (-not $GithubToken) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        Write-Log "[AUTH] Using gh CLI authentication..."
        $GithubToken = "gh-cli"
    } else {
        Write-Log "[FAIL] No GitHub token provided and gh CLI not found"
        Write-Log "  Set -GithubToken or install GitHub CLI (gh) and run 'gh auth login'"
        exit 1
    }
}

$dnsOk = Test-DnsReady
if (-not $dnsOk) {
    Write-Log "[EXIT] DNS not ready. Run check_dns.ps1 -Continuous to monitor propagation."
    exit 1
}

if ($GithubToken -eq "gh-cli") {
    Write-Log "[API] Using gh CLI to set CNAME..."
    $result = gh api "repos/$Repo/pages" -X PUT -H "Accept: application/vnd.github.v3+json" -f "cname=$Domain" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "[OK] CNAME set via gh CLI"
    } else {
        Write-Log "[FAIL] gh CLI error: $result"
        exit 1
    }
} else {
    $err = Set-GithubCname -Token $GithubToken
    if ($err) { exit 1 }
}

$httpsOk = Wait-Https

$summaryMsg = @"
[DEPLOY COMPLETE] pmxs.space
Domain: $Domain
CNAME: Configured on GitHub Pages
HTTPS: $(if ($httpsOk) { 'Provisioned' } else { 'Pending (check later)' })
URL: https://$Domain
"@
Send-Telegram -Message $summaryMsg

Write-Log "==================================="
Write-Log "  DEPLOYMENT SUMMARY"
Write-Log "  Domain: $Domain"
Write-Log "  CNAME: Set on GitHub Pages"
Write-Log "  HTTPS: $(if ($httpsOk) { 'Provisioned' } else { 'Pending' })"
Write-Log "  Telegram: Notification sent"
Write-Log "==================================="

if ($httpsOk) {
    Write-Host "`nSite is live at: https://$Domain" -ForegroundColor Green
} else {
    Write-Host "`nCNAME is set. HTTPS provisioning in progress." -ForegroundColor Yellow
    Write-Host "Check back in 5-10 min: https://$Domain" -ForegroundColor Yellow
}
