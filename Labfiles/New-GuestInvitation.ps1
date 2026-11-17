<#
.SYNOPSIS
    Invites a B2B guest WITHOUT sending the invitation email and prints the redeem URL.

.DESCRIPTION
    Used in SC-300 Lab 1.2. The redeem URL only exists in the response to the
    invitation request - the admin center never shows it. Run the script again for an
    existing guest: Entra ID keeps the same user object and returns a fresh redeem URL.

.EXAMPLE
    PowerShell.exe -ExecutionPolicy Bypass -File .\New-GuestInvitation.ps1 `
        -Email "someone@outlook.com"

.NOTES
    Requires Microsoft.Graph.Identity.SignIns. Windows PowerShell 5.1 and PowerShell 7 compatible.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Email,
    [string]$DisplayName,
    [string]$RedirectUrl = 'https://myapplications.microsoft.com'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable Microsoft.Graph.Identity.SignIns)) {
    Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force
}
Connect-MgGraph -Scopes 'User.Invite.All' -NoWelcome

$body = @{
    invitedUserEmailAddress = $Email
    inviteRedirectUrl       = $RedirectUrl
    sendInvitationMessage   = $false
}
if ($DisplayName) { $body.invitedUserDisplayName = $DisplayName }

$invite = New-MgInvitation -BodyParameter $body

[pscustomobject]@{
    GuestObjectId = $invite.InvitedUser.Id
    Status        = $invite.Status
    RedeemUrl     = $invite.InviteRedeemUrl
} | Format-List

Write-Host 'Send the RedeemUrl to the guest yourself (Teams, mail, chat).' -ForegroundColor Yellow
