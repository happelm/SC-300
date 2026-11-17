---
title: 'Lab 0.1 – Set up your lab'
lab:
    title: 'Lab 0.1 – Set up your lab'
    module: 'Day 0 – Setup'
---

# Lab 0.1 – Set up your lab

**Estimated time:** 20 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Your hosted tenant is ready: you know your admin account and test users, you can sign in as two people at the same time, and Graph Explorer and Microsoft Graph PowerShell work.

**Why:** Almost every lab in this course has two sides – the admin who configures and the user who feels the effect. If you test with the same browser session you configured in, you test nothing: cached tokens and an existing MFA claim hide what the user really sees.

1. Open your lab environment (GoDeploy) and note the tenant values:

   | Setting | Value |
   |---|---|
   | Tenant | `WWLxNNNNNN.onmicrosoft.com` |
   | Admin | `admin@WWLxNNNNNN.onmicrosoft.com` |
   | Admin password | from the lab environment |

2. Sign in to `https://entra.microsoft.com` with the admin account. **Entra ID → Overview** – note the **Tenant ID**. You will need it in several scripts.

3. **Entra ID → Overview → Licenses** – check that **Microsoft Entra ID P2** is listed. P2 is required for ID Protection (Lab 2.4), PIM (Lab 4.1) and access reviews.

4. **Entra ID → Users → All users** – the tenant comes with test users such as Adele Vance, Delia Dennis and Miriam Graham. Reset the password of **two** of them and note the temporary passwords. These are your test users for the whole course:

   | Role in the labs | User |
   |---|---|
   | Test user A | (your choice) |
   | Test user B | (your choice) |

5. Set up a second browser identity for the test user. Pick one:
   - Microsoft Edge: **Profile → Add profile → Continue without signing in** – a separate profile keeps its own cookies.
   - An InPrivate window (`Ctrl+Shift+N`) – simpler, but closes all its sessions when you close the last InPrivate window.

   Sign in as test user A at `https://myaccount.microsoft.com` and change the temporary password.

6. Open Graph Explorer (`https://aka.ms/ge`) in the **admin** browser and sign in as admin. Method **GET** – run:

   ```text
   https://graph.microsoft.com/v1.0/organization?$select=id,displayName,verifiedDomains
   ```

7. Open Windows PowerShell and install Microsoft Graph PowerShell for your user (skip if it is already installed):

   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser -Force
   Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
   Get-MgContext | Select-Object Account, TenantId, AppName
   Get-MgUser -Top 5 | Select-Object DisplayName, UserPrincipalName
   ```

8. Download the lab files from `https://github.com/happelm/SC-300/tree/main/Labfiles` (**Code → Download ZIP** on the repo start page) and extract them to `C:\LabFiles\SC-300`.

### Checkpoint

- [ ] Tenant ID noted
- [ ] Two test users with known passwords, one of them signed in in a separate browser profile or InPrivate window
- [ ] Graph Explorer returns your organization
- [ ] `Get-MgContext` shows `Microsoft Graph Command Line Tools` as `AppName` and your tenant ID

**Note:** `AppName` in step 7 is the first appearance of a theme for Day 3: you did not register an app, yet you signed in through one. Microsoft Graph PowerShell is an app registration in a Microsoft tenant; your tenant now holds a service principal for it under **Enterprise apps**.

**Why not just use the admin for everything:** Conditional Access, MFA registration and consent prompts all behave differently for admins and for the first sign-in of a user. Test as the person the policy is meant for.
