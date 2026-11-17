---
title: 'Lab 2.4 – Trigger and remediate user risk'
lab:
    title: 'Lab 2.4 – Trigger and remediate user risk'
    module: 'Day 2 – Authentication and access'
---

# Lab 2.4 – Trigger and remediate user risk

**Estimated time:** 30 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user A is marked as compromised, the user-risk policy forces a secure password change at the next sign-in, and the risk state changes to remediated.

**Why:** The Microsoft lab 14 creates risk policies but never triggers one – so nobody sees what a user actually experiences. Real detections like anonymous IP or password spray take time to appear. Confirming a user as compromised sets the risk to **High** immediately, which makes the full loop visible in one lab: detection, policy, self-remediation, report.

Requires Lab 2.1 (test user A has a passkey, so MFA is possible).

1. **Conditional Access → Policies → + New policy**:

   | Setting | Value |
   |---|---|
   | Name | `LAB204 – High user risk – secure password change` |
   | Users | Include `SC300-Passwordless`; exclude your admin account |
   | Target resources | **All resources** |
   | Conditions → User risk | **Configure: Yes**, **High** |
   | Grant | **Grant access** → **Require multifactor authentication** and **Require password change** (require all) |
   | Session | **Sign-in frequency → Every time** |
   | Enable policy | **On** |

2. Find the object ID of test user A: **Users →** test user A **→ Overview → Object ID**.

3. In Graph Explorer as admin, **Modify permissions** → consent to `IdentityRiskyUser.ReadWrite.All`. Method **POST** – request body:

   ```json
   { "userIds": [ "<object ID of test user A>" ] }
   ```

   URL:

   ```text
   https://graph.microsoft.com/v1.0/identityProtection/riskyUsers/confirmCompromised
   ```

   Expected response: **204 No Content**.

4. **ID Protection → Risky users** – test user A is listed with risk level **High**, risk detail **Admin confirmed user compromised**.

5. In a fresh InPrivate window, sign in as test user A at `https://myapplications.microsoft.com`. Complete the passkey sign-in, then change the password when asked.

6. Back in **Risky users**, refresh. Open test user A → **Risk history**.

### Checkpoint

- [ ] Test user A appeared as **High** risk after the Graph call
- [ ] The next sign-in required MFA and a password change
- [ ] The risk state of test user A is now **Remediated**

**Note:** Password change as a remediation only works for users who can do MFA – otherwise the user is stuck and the helpdesk has to dismiss the risk. Register a method before you put users in scope of a risk policy.

**Why confirm instead of dismiss:** **Confirm compromised** also feeds the machine learning behind ID Protection; **Dismiss** tells it the detection was wrong. Both are actions in the **Risky users** report as well – the Graph call is the same operation a SOAR playbook would run.
