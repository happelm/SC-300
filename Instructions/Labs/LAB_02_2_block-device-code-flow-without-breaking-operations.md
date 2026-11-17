---
title: 'Lab 2.2 – Block device code flow without breaking operations'
lab:
    title: 'Lab 2.2 – Block device code flow without breaking operations'
    module: 'Day 2 – Authentication and access'
---

# Lab 2.2 – Block device code flow without breaking operations

**Estimated time:** 35 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Device code flow is blocked for everyone except a documented exception group – and you saw the effect in report-only mode before you switched it on.

**Why:** Device code phishing needs no fake website: the attacker starts the flow, sends the victim a code, and the victim enters it on the real `microsoft.com/devicelogin` page and approves MFA. The tokens go to the attacker. Microsoft recommends blocking device code flow wherever possible. But some tools need it – headless setups like Microsoft Tunnel Gateway or Teams Rooms devices – so a blind block breaks operations. This lab is the safe rollout pattern: measure, report-only, exception, enforce.

### Part A – See the flow and its traces

1. In PowerShell, sign in as **test user B** with device code:

   ```powershell
   Disconnect-MgGraph -ErrorAction SilentlyContinue
   Connect-MgGraph -UseDeviceCode -Scopes "User.Read" -NoWelcome
   Get-MgContext | Select-Object Account, AuthType
   ```

   Open `https://microsoft.com/devicelogin` in the test user browser, enter the code, sign in as test user B. If a consent page appears, accept it.

2. As admin: **Sign-in logs** → **Add filters → Authentication protocol → Device code**. The sign-in of test user B is listed with application **Microsoft Graph Command Line Tools**.

### Part B – Report-only

3. **Entra ID → Groups → New group** – security group `SC300-DeviceCode-Exception`, no members yet.

4. **Conditional Access → Policies → + New policy**:

   | Setting | Value |
   |---|---|
   | Name | `CA202 – Block device code flow` |
   | Users | Include **All users**; exclude your admin account and `SC300-DeviceCode-Exception` |
   | Target resources | Include **All resources**; exclude **Device Registration Service** |
   | Conditions → Authentication flows | **Configure: Yes**, **Device code flow** |
   | Grant | **Block access** |
   | Enable policy | **Report-only** |

5. Repeat step 1 (disconnect, connect with device code as test user B). It still works.

6. Open the new sign-in in the log → tab **Report-only**. `CA202` shows **Report-only: Failure** – this is the evidence you take to the change board before enforcing.

### Part C – Enforce and except

7. Set `CA202` to **On**. Repeat step 1. The sign-in is blocked – note the error code in the browser (`AADSTS53003`).

8. Add test user B to `SC300-DeviceCode-Exception`. Wait a minute, repeat step 1. It works again.

9. Remove test user B from the group again.

### Checkpoint

- [ ] The sign-in log filter **Authentication protocol = Device code** shows the test sign-ins
- [ ] Report-only showed **Failure** for `CA202` before you enforced it
- [ ] With `CA202` on, device code sign-in of test user B is blocked; as a member of the exception group it works

**Note:** An exception is per account, not per tool. A user in the exception group can use device code flow for anything. Keep the group empty by default and grant membership just in time – Lab 4.1 does that with PIM for Groups.

**Why exclude Device Registration Service:** Since September 2024 an authentication flows policy that targets all resources also applies to device registration. Some device setups register through device code flow and would break without this exclusion.

**Protocol tracking:** A session that started with device code flow stays marked even after token refresh. If a user is blocked although the current sign-in was not device code, check **Original transfer method** in the sign-in details – error `AADSTS530036` is that case.
