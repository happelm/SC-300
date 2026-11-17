---
title: 'Lab 3.2 – Your own single-page app'
lab:
    title: 'Lab 3.2 – Your own single-page app'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.2 – Your own single-page app

**Estimated time:** 40 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** The same Graph calls as in Lab 3.1, but from an app you registered yourself. In the token, `appid` is now your app – and you can explain why the app holds no secret.

**Why:** Lab 3.1 used a Microsoft app. Here you are the developer: you choose the platform type, the redirect URI and the permissions. A single-page app runs in the browser, so anything it contains can be read with F12 – it is a public client and signs in with the authorization code flow and PKCE instead of a secret.

### Part A – Local web server

1. On your lab VM, install Node.js and a static web server (close and reopen PowerShell after the first command):

   ```powershell
   winget install -e --id OpenJS.NodeJS.LTS
   ```

   ```powershell
   npm install -g serve
   ```

   If `npx serve` fails with *could not determine executable to run*, that is why we install `serve` globally.

### Part B – Register the app

2. As admin: **Entra ID → App registrations → + New registration**:

   | Setting | Value |
   |---|---|
   | Name | `SC300 SPA Demo` |
   | Supported account types | **Single tenant** |
   | Redirect URI – platform | **Single-page application (SPA)** |
   | Redirect URI | `http://localhost:3000` |

   Note **Application (client) ID** and **Directory (tenant) ID**.

3. Do **not** add API permissions yet.

### Part C – Run it

4. In `C:\LabFiles\SC-300\Labfiles\entra-spa-demo\app.js` set `clientId` and `tenantId` in the `CONFIG` block at the top.

5. In PowerShell:

   ```powershell
   cd C:\LabFiles\SC-300\Labfiles\entra-spa-demo
   serve -l 3000
   ```

6. Open `http://localhost:3000` in the test user browser, **Sign in** as test user B, accept the consent page.

7. **Load profile**, change the mobile phone, **Save** (expect 204). Then **Try PATCH jobTitle** (expect 403).

8. **Show token claims** – compare `appid` and `scp` with Lab 3.1.

### Part D – Where did the permission come from

9. As admin, open **App registrations → SC300 SPA Demo → API permissions**. Then **Enterprise apps → SC300 SPA Demo → Permissions → User consent**.

### Checkpoint

- [ ] The app signs in, reads and writes `mobilePhone`, and gets 403 for `jobTitle`
- [ ] `appid` in the token is the client ID of `SC300 SPA Demo`
- [ ] You can explain why the app works although **API permissions** in the app registration is empty

**Why it works without API permissions:** MSAL asks for `User.Read` and `User.ReadWrite` at sign-in (dynamic consent). The user's consent creates a grant on the **service principal** under Enterprise apps. The **API permissions** blade only writes `requiredResourceAccess` into the app registration – a declaration of what the app wants, used for admin consent and for `/.default`. Fill it in anyway: it documents the app, and Lab 3.5 shows where the declaration is mandatory.

**Common errors:**

| Error | Cause |
|---|---|
| `AADSTS50011` | The redirect URI does not match exactly – port, trailing slash, or `http` vs `https` |
| `AADSTS9002326` *Cross-origin token redemption is permitted only for the 'Single-Page Application' client-type* | The URI is registered under **Web** instead of **Single-page application** |
| Panel shows *opened via file://* | You double-clicked `index.html` instead of using the web server |
| Panel shows *placeholder GUIDs* | Step 4 not done or file not saved |
