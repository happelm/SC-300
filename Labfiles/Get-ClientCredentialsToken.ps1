<#
.SYNOPSIS
    Gets an app-only access token with the OAuth 2.0 client credentials flow
    (client secret) and shows its claims.

.DESCRIPTION
    Used in SC-300 Lab 3.5. The scope MUST end in /.default - with client credentials
    you never request single permissions, you get everything an admin has already
    consented to for this app on that resource.

.EXAMPLE
    PowerShell.exe -ExecutionPolicy Bypass -File .\Get-ClientCredentialsToken.ps1 `
        -TenantId <tenant-id> -ClientId <client-id> -Resource "api://<api-client-id>"

.EXAMPLE
    # App-only token for Microsoft Graph
    .\Get-ClientCredentialsToken.ps1 -TenantId <tenant-id> -ClientId <client-id> `
        -Resource "https://graph.microsoft.com"

.NOTES
    The secret is read with Read-Host -AsSecureString so it does not end up in your
    console history. Windows PowerShell 5.1 and PowerShell 7 compatible.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$TenantId,
    [Parameter(Mandatory)] [string]$ClientId,
    [Parameter(Mandatory)] [string]$Resource
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ConvertFrom-Jwt.ps1')

$secure = Read-Host -Prompt 'Client secret (value, not the secret ID)' -AsSecureString
$secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

$scope = $Resource.TrimEnd('/') + '/.default'
$uri   = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
Write-Host "POST $uri  (scope = $scope)" -ForegroundColor Cyan

try {
    $token = Invoke-RestMethod -Method Post -Uri $uri `
        -ContentType 'application/x-www-form-urlencoded' `
        -Body @{
            grant_type    = 'client_credentials'
            client_id     = $ClientId
            client_secret = $secret
            scope         = $scope
        }
}
catch {
    if ($_.ErrorDetails.Message) {
        $body = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "$($body.error)`n$($body.error_description)" -ForegroundColor Red
        exit 1
    }
    throw
}

ConvertFrom-Jwt -Token $token.access_token |
    Select-Object aud, appid, roles, scp, upn, tid, expLocal |
    Format-List

if (-not (ConvertFrom-Jwt -Token $token.access_token).roles) {
    Write-Host 'No roles claim: admin consent for the application permission is missing.' -ForegroundColor Yellow
}
$global:LabToken = $token.access_token
