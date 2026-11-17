# Lab files

Download the whole folder as ZIP from the repo start page (**Code → Download ZIP**) or copy single files from [GitHub](https://github.com/happelm/SC-300/tree/main/Labfiles).

| File | Lab | Purpose |
|---|---|---|
| `ConvertFrom-Jwt.ps1` | 2.2, 3.4, 3.5 | Decodes the payload of an access token so you can read `aud`, `scp`, `roles` – used by the other scripts |
| `Invoke-DeviceCodeFlow.ps1` | 2.2, 3.4 | Device code flow with raw HTTP calls, shows the token claims |
| `Get-ClientCredentialsToken.ps1` | 3.5 | App-only token with client credentials and `/.default` |
| `New-GuestInvitation.ps1` | 1.2 | Invites a guest without the invitation email and prints the redeem URL |
| `entra-spa-demo/index.html`, `entra-spa-demo/app.js` | 3.2 | Single-page app: MSAL.js, auth code flow with PKCE, `GET`/`PATCH /me`, token claims |

All PowerShell scripts run in Windows PowerShell 5.1 and PowerShell 7:

```powershell
PowerShell.exe -ExecutionPolicy Bypass -File .\Invoke-DeviceCodeFlow.ps1 -TenantId <tenant-id> -ClientId <client-id>
```
