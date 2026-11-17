---
title: 'Lab 3.5 – Daemon access with an app role'
lab:
    title: 'Lab 3.5 – Daemon access with an app role'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.5 – Daemon access with an app role

**Estimated time:** 55 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** A service **Employee Sync** gets an app-only token for your API with the client credentials flow – first with a secret, then with a certificate. The token has `roles` instead of `scp` and no user in it, and the service can change what test user B could not change in Lab 3.1.

**Why:** Nightly syncs, backup scripts, HR interfaces: nobody is at the keyboard. The old answer was a service account with a password; the right answer is an app identity that authenticates itself. Application permissions are not limited by any user's rights – a service with `Employees.Read.All` reads everything. That is why they always need admin consent, and why least privilege matters even more here.

Requires Lab 3.3.

### Part A – Identity and credential

1. **App registrations → + New registration** – `Employee Sync`, single tenant, no redirect URI. Note the client ID.

2. **Certificates & secrets → + New client secret** – description `lab`, expires in **90 days** → copy the **Value** (not the Secret ID) right away.

   A secret is the quick start. Part D replaces it with a certificate – see [Concepts, section 3](../Concepts.html) for the full order of preference.

### Part B – Permission without consent

3. **API permissions → + Add a permission → APIs my organization uses → Employee API → Application permissions** → `Employees.Read.All` → **Add permissions**. Do **not** grant consent yet.

4. Get a token:

   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\Get-ClientCredentialsToken.ps1 `
       -TenantId <tenant-id> -ClientId <client-id of Employee Sync> `
       -Resource "api://<client-id of Employee API>"
   ```

   Paste the secret when asked. Look at `roles`.

### Part C – With consent

5. **API permissions → Grant admin consent for <tenant>** → **Yes**.

6. Run the script from step 4 again.

7. **Enterprise apps → Employee Sync → Permissions** – the grant is listed under **Admin consent** with type **Application**.

### Checkpoint

- [ ] Without admin consent the token has **no** `roles` claim – Entra still issues it; your API would reject the call
- [ ] With admin consent, `roles` contains `Employees.Read.All`
- [ ] `scp` and `upn` are missing – there is no user in this token
- [ ] With the certificate, `Employee Sync` changed `jobTitle` of test user B – the same change that returned 403 for test user B in Lab 3.1
- [ ] The service principal sign-in log shows the secret and the certificate sign-ins with different credential types

### Part D – Certificate instead of secret

A secret is a password: whoever copies it is the app. With a certificate only the public key goes to Entra; the private key stays in the certificate store of the machine that runs the job. Graph PowerShell signs a short assertion with it at every sign-in.

8. On your lab VM, create a self-signed certificate and export the public key:

   ```powershell
   $cert = New-SelfSignedCertificate -Subject "CN=Employee Sync" `
       -CertStoreLocation "Cert:\CurrentUser\My" -KeySpec Signature `
       -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddMonths(6)
   Export-Certificate -Cert $cert -FilePath "$env:USERPROFILE\Desktop\EmployeeSync.cer" | Out-Null
   $cert.Thumbprint
   ```

   `NonExportable` means the private key can never leave this machine – not even by its admin.

9. **App registrations → Employee Sync → Certificates & secrets → Certificates → Upload certificate** → `EmployeeSync.cer`. Compare the thumbprint with the output of step 8.

10. Give the service a Graph permission: **API permissions → + Add a permission → Microsoft Graph → Application permissions** → `User.ReadWrite.All` → **Add permissions → Grant admin consent**.

11. Sign in as the app – no user, no prompt:

    ```powershell
    Connect-MgGraph -ClientId <client-id of Employee Sync> -TenantId <tenant-id> `
        -CertificateThumbprint <thumbprint> -NoWelcome
    Get-MgContext | Select-Object AppName, AuthType, Scopes
    ```

    `AuthType` is `AppOnly`; `Scopes` lists the application permissions from the token's `roles` claim.

12. Change the job title of test user B – the call that failed in Lab 3.1:

    ```powershell
    Update-MgUser -UserId <UPN of test user B> -JobTitle "Chief Demo Officer"
    Get-MgUser -UserId <UPN of test user B> -Property displayName,jobTitle | Select-Object DisplayName, JobTitle
    Disconnect-MgGraph
    ```

13. **Entra ID → Monitoring & health → Sign-in logs → Service principal sign-ins** – find the sign-in of `Employee Sync`. **Client credential type** shows **Client secret** for Part B and C and **Client assertion** (certificate) for Part D.

**Why `/.default`:** With client credentials you never ask for single permissions. `/.default` means "everything already consented for this app on this resource". There is no one to ask at runtime, so the decision is made beforehand, at admin consent – and only from what is declared under **API permissions**. This is the case where the declaration from Lab 3.2 is mandatory.

**Compare with Lab 3.4 and 3.1:** Same API, same `aud`. Delegated: `scp` + user, rights = scope ∩ user rights. App-only: `roles`, no user, rights = scope. That is why `User.ReadWrite.All` as an application permission is one of the most powerful permissions in a tenant – treat the certificate like an admin password.

**Note:** `User.ReadWrite.All` as an application permission cannot change users who hold privileged admin roles. If step 12 fails with 403, check that test user B has no role assignment left from an earlier lab.

**Remove the Graph permission** at the end of the course (Appendix → Cleanup).
