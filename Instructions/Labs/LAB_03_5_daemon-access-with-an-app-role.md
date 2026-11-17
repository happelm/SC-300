---
title: 'Lab 3.5 – Daemon access with an app role'
lab:
    title: 'Lab 3.5 – Daemon access with an app role'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.5 – Daemon access with an app role

**Estimated time:** 35 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** A service **Employee Sync** gets an app-only token for your API with the client credentials flow. The token has `roles` instead of `scp` and no user in it.

**Why:** Nightly syncs, backup scripts, HR interfaces: nobody is at the keyboard. The old answer was a service account with a password; the right answer is an app identity that authenticates itself. Application permissions are not limited by any user's rights – a service with `Employees.Read.All` reads everything. That is why they always need admin consent, and why least privilege matters even more here.

Requires Lab 3.3.

### Part A – Identity and credential

1. **App registrations → + New registration** – `Employee Sync`, single tenant, no redirect URI. Note the client ID.

2. **Certificates & secrets → + New client secret** – description `lab`, expires in **90 days** → copy the **Value** (not the Secret ID) right away.

   A secret is a lab shortcut. In production the order is: managed identity (if the code runs in Azure) › workload identity federation (GitHub, AWS, GCP, Kubernetes) › certificate › secret.

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

**Why `/.default`:** With client credentials you never ask for single permissions. `/.default` means "everything already consented for this app on this resource". There is no one to ask at runtime, so the decision is made beforehand, at admin consent – and only from what is declared under **API permissions**. This is the case where the declaration from Lab 3.2 is mandatory.

**Compare with Lab 3.4:** Same API, same `aud`. Delegated: `scp` + user, rights = scope ∩ user rights. App-only: `roles`, no user, rights = scope.
