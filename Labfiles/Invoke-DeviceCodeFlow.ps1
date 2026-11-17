<#
.SYNOPSIS
    Runs the OAuth 2.0 device code flow against Microsoft Entra ID with raw HTTP calls
    and shows the claims of the access token.

.DESCRIPTION
    Used in SC-300 Labs 2.2 and 3.4. No module needed - every request is visible.
    The app registration must have "Allow public client flows" set to Yes,
    otherwise the token request fails with AADSTS7000218.

.EXAMPLE
    PowerShell.exe -ExecutionPolicy Bypass -File .\Invoke-DeviceCodeFlow.ps1 `
        -TenantId <tenant-id> -ClientId <client-id> -Scope "User.Read"

.EXAMPLE
    # Token for your own API (Lab 3.4)
    .\Invoke-DeviceCodeFlow.ps1 -TenantId <tenant-id> -ClientId <client-id> `
        -Scope "api://<api-client-id>/Employees.Read"

.NOTES
    Windows PowerShell 5.1 and PowerShell 7 compatible.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$TenantId,
    [Parameter(Mandatory)] [string]$ClientId,
    [string]$Scope = 'User.Read'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ConvertFrom-Jwt.ps1')

$authority = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0"

# 1) Ask Entra ID for a device code
Write-Host "`n1) POST $authority/devicecode" -ForegroundColor Cyan
$device = Invoke-RestMethod -Method Post -Uri "$authority/devicecode" `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body @{ client_id = $ClientId; scope = $Scope }

Write-Host ''
Write-Host '   Open  : ' -NoNewline; Write-Host $device.verification_uri -ForegroundColor Yellow
Write-Host '   Code  : ' -NoNewline; Write-Host $device.user_code        -ForegroundColor Yellow
Write-Host "   The long device_code stays in this script - the user never sees it." -ForegroundColor DarkGray
Write-Host ''

# 2) Poll the token endpoint until the user has signed in
Write-Host "2) Polling POST $authority/token every $($device.interval) s" -ForegroundColor Cyan
$deadline = (Get-Date).AddSeconds([int]$device.expires_in)
$token = $null
while (-not $token -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds ([int]$device.interval)
    try {
        $token = Invoke-RestMethod -Method Post -Uri "$authority/token" `
            -ContentType 'application/x-www-form-urlencoded' `
            -Body @{
                grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
                client_id   = $ClientId
                device_code = $device.device_code
            }
    }
    catch {
        $body = $null
        if ($_.ErrorDetails.Message) { $body = $_.ErrorDetails.Message | ConvertFrom-Json }
        if ($body -and $body.error -eq 'authorization_pending') {
            Write-Host '   ... authorization_pending' -ForegroundColor DarkGray
            continue
        }
        if ($body) {
            Write-Host "`n   $($body.error)" -ForegroundColor Red
            Write-Host "   $($body.error_description)" -ForegroundColor Red
            exit 1
        }
        throw
    }
}
if (-not $token) { Write-Host 'The device code expired.' -ForegroundColor Red; exit 1 }

# 3) Show what Entra ID put into the token
Write-Host "`n3) Access token claims" -ForegroundColor Cyan
ConvertFrom-Jwt -Token $token.access_token |
    Select-Object aud, appid, scp, roles, upn, tid, expLocal |
    Format-List

$global:LabToken = $token.access_token
Write-Host 'The raw token is in $LabToken - paste it into https://jwt.ms to see all claims.' -ForegroundColor DarkGray
