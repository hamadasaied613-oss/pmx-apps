param(
    [string]$Domain = "pmxs.space",
    [string]$IntervalSeconds = 60,
    [switch]$Continuous
)

$StartTime = Get-Date "2026-06-30T12:57:02Z"
$BotToken = "8765968989:AAHDelDZZkFcUCRa09lqtQmh7VBGl50EMUA"
$ChatId = "6544206847"
$Notified = $false

function Send-Telegram {
    param([string]$Message)
    $body = @{ chat_id = $ChatId; text = $Message; parse_mode = "Markdown" } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Host "  [TELEGRAM] Notification sent" -ForegroundColor Green
    } catch {
        Write-Host "  [TELEGRAM] Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-DnsRecords {
    param([string]$Domain)
    $results = @{ A = @(); CNAME = @(); MX = @(); TXT = @(); NS = @() }
    $resolved = $false

    $a = Resolve-DnsName -Name $Domain -Type A -ErrorAction SilentlyContinue
    if ($a) {
        $resolved = $true
        $results.A = $a | ForEach-Object { $_.IPAddress }
    }

    $cname = Resolve-DnsName -Name "www.$Domain" -Type CNAME -ErrorAction SilentlyContinue
    if ($cname) {
        $resolved = $true
        $results.CNAME = $cname | ForEach-Object { $_.NameHost }
    }

    $mx = Resolve-DnsName -Name $Domain -Type MX -ErrorAction SilentlyContinue
    if ($mx) { $results.MX = $mx | ForEach-Object { "$($_.Exchange) (priority $($_.Preference))" } }

    $txt = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction SilentlyContinue
    if ($txt) { $results.TXT = $txt | ForEach-Object { $_.Strings } }

    $ns = Resolve-DnsName -Name $Domain -Type NS -ErrorAction SilentlyContinue
    if ($ns) { $results.NS = $ns | ForEach-Object { $_.NameHost } }

    return @{ Resolved = $resolved; Records = $results }
}

do {
    $elapsed = [math]::Round(((Get-Date) - $StartTime).TotalHours, 1)
    $result = Test-DnsRecords -Domain $Domain

    if ($result.Resolved) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  DNS RESOLVED for $Domain" -ForegroundColor Green
        Write-Host "  Propagation time: ${elapsed}h" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan

        if ($result.Records.A.Count -gt 0) {
            Write-Host "`n  A Records:" -ForegroundColor Yellow
            $result.Records.A | ForEach-Object { Write-Host "    $_" }
        }
        if ($result.Records.CNAME.Count -gt 0) {
            Write-Host "`n  CNAME www ->" -ForegroundColor Yellow
            $result.Records.CNAME | ForEach-Object { Write-Host "    $_" }
        }
        if ($result.Records.MX.Count -gt 0) {
            Write-Host "`n  MX Records:" -ForegroundColor Yellow
            $result.Records.MX | ForEach-Object { Write-Host "    $_" }
        }
        if ($result.Records.TXT.Count -gt 0) {
            Write-Host "`n  TXT Records:" -ForegroundColor Yellow
            $result.Records.TXT | ForEach-Object { Write-Host "    $_" }
        }
        if ($result.Records.NS.Count -gt 0) {
            Write-Host "`n  NS Records:" -ForegroundColor Yellow
            $result.Records.NS | ForEach-Object { Write-Host "    $_" }
        }

        if (-not $Notified) {
            $msg = @"
[DNS RESOLVED] pmxs.space
Propagation: ${elapsed}h
A: $($result.Records.A -join ', ')
CNAME: $($result.Records.CNAME -join ', ')
MX: $($result.Records.MX -join ', ')
NS: $($result.Records.NS -join ', ')
Ready to deploy domain on GitHub Pages
"@
            Send-Telegram -Message $msg
            $Notified = $true

            if (-not $Continuous) {
                Write-Host "`n  [READY] Run deploy_domain.ps1 to set CNAME on GitHub Pages" -ForegroundColor Green
                break
            }
        }
    } else {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Domain NOT resolving - ${elapsed}h since registration" -ForegroundColor Yellow
        if ($Continuous) {
            Write-Host "  Checking again in ${IntervalSeconds}s... (Ctrl+C to stop)" -ForegroundColor DarkGray
            Start-Sleep -Seconds $IntervalSeconds
        } else {
            Write-Host "  DNS not ready yet. Run again later or use -Continuous to monitor." -ForegroundColor Cyan
            break
        }
    }
} while ($Continuous)
