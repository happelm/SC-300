---
title: 'Lab 3.4 – Client app with delegated access to your API'
lab:
    title: 'Lab 3.4 – Client app with delegated access to your API'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.4 – Client app with delegated access to your API

**Estimated time:** 30 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** A second app **Employee Client** gets the scope `Employees.Read` on your API, test user B gets a token for it, and the token proves it: `aud` is your API, `scp` is your scope.

**Why:** Lab 3.3 only defined what could be granted. Here the first real permission is created, for the most common case: an app acting on behalf of a person. And you see the one artifact where every configuration decision ends up – the access token. When something fails in production, a decoded token tells you in seconds whether the configuration or the application is wrong.

Requires Lab 3.3.

### How it works

The client asks for a specific scope during sign-in. Entra checks whether consent exists – from the user, or from an admin for everyone – and if so writes the scope into the `scp` claim. The token is issued for the API from Lab 3.3, visible in `aud`; a Graph token would be worthless there. The user is in the token too (`upn`, `oid`), so the API can apply its own rules on top: scope ∩ what this user may do.

The lab uses device code flow because it needs no redirect URI, no web server and no library, and still runs a real interactive sign-in with MFA and Conditional Access. That makes the protocol visible: the long `device_code` stays in the script, the short `user_code` goes to the person, and the script polls `/token` until the sign-in is done.

1. **App registrations → + New registration** – `Employee Client`, single tenant, no redirect URI. Note the client ID.

2. **Authentication → Advanced settings → Allow public client flows → Yes → Save.** The script uses device code flow, which needs a public client. Without this switch the token request fails with `AADSTS7000218`.

3. **API permissions → + Add a permission → APIs my organization uses → Employee API → Delegated permissions** → `Employees.Read` → **Add permissions**.

   Look at the column **Admin consent required**: *No* for `Employees.Read`. That comes from *Who can consent* in Lab 3.3.

4. Do **not** grant admin consent. Test user B will consent personally.

5. In PowerShell, from the lab files folder:

   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\Invoke-DeviceCodeFlow.ps1 `
       -TenantId <tenant-id> -ClientId <client-id of Employee Client> `
       -Scope "api://<client-id of Employee API>/Employees.Read"
   ```

   Sign in as test user B in the test user browser, accept the consent page. Watch the `authorization_pending` lines while the script polls.

6. Read the claims the script prints.

7. Run the script again with the scope `api://<client-id of Employee API>/Employees.Write.All`.

### Checkpoint

- [ ] `aud` is `api://<client-id of Employee API>` – not Microsoft Graph
- [ ] `appid` is the client ID of `Employee Client`, `scp` is `Employees.Read`, `upn` is test user B
- [ ] The request for `Employees.Write.All` ends in an approval-required page or `AADSTS65001` – test user B cannot consent to an admin-only scope

**Note:** Device code flow is used here because it needs no redirect URI, no web server and no library. For a real app it is the wrong choice – the user-facing flow is authorization code with PKCE (Lab 3.2). If you blocked device code flow in Lab 2.2, add test user B to `SC300-DeviceCode-Exception` for this lab.

**Why the token goes to the API and not to Graph:** A token is only valid for the resource in `aud`. Your API would reject a Graph token, and Graph rejects this one. The client must request a token per resource.
