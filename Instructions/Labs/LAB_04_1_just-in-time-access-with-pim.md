---
title: 'Lab 4.1 – Just-in-time access with PIM and authentication context'
lab:
    title: 'Lab 4.1 – Just-in-time access with PIM and authentication context'
    module: 'Day 4 – Governance and monitoring'
---

# Lab 4.1 – Just-in-time access with PIM and authentication context

**Estimated time:** 40 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user A activates *User Administrator* only after a fresh passkey sign-in, and test user B gets the device code exception from Lab 2.2 for one hour – both just in time.

**Why:** Microsoft lab 26 configures PIM with *Require MFA on activation*. That setting accepts an MFA claim the session already has – a token stolen from a signed-in admin activates the role without any new proof. An authentication context on activation brings the full Conditional Access toolbox to that moment: authentication strength, sign-in frequency, device, location. Part B applies the same just-in-time idea to an exception group – the pattern from Lab 2.2 that keeps a risky exception closed by default.

Requires Lab 2.2 and Lab 2.3. Run Microsoft lab 26 first if you have not used PIM before.

### Part A – Role activation with step-up

1. **ID Governance → Privileged Identity Management → Microsoft Entra roles → Settings → User Administrator → Edit**:

   | Setting | Value |
   |---|---|
   | Activation maximum duration | 2 hours |
   | On activation, require | **Microsoft Entra Conditional Access authentication context** → `Phishing-resistant step-up` |
   | Require justification on activation | **Yes** |

   **Update.**

2. **Microsoft Entra roles → Assignments → + Add assignments** – role **User Administrator**, member test user A, assignment type **Eligible**.

3. As test user A (test user browser): `https://myaccess.microsoft.com` or **ID Governance → Privileged Identity Management → My roles** → **User Administrator → Activate**. Enter a justification.

4. Complete the step-up with the passkey. Wait until the role shows as **Active**, then sign out and in again.

5. As test user A, change the job title of test user B in **Users**. This is the call that failed in Lab 3.1.

### Part B – An exception group just in time

6. **Privileged Identity Management → Groups → Discover groups** – select `SC300-DeviceCode-Exception` → **Manage groups**.

7. Open the group in PIM → **Settings → Member → Edit** – activation maximum duration **1 hour**, require justification **Yes** → **Update**.

8. **Assignments → + Add assignments** – role **Member**, test user B, **Eligible**.

9. As test user B: **My roles → Groups** → activate the membership with justification `Install Tunnel Gateway`.

10. Repeat the device code sign-in from Lab 2.2, step 1. It works.

11. **Groups → SC300-DeviceCode-Exception → Members** – test user B is a member; the PIM assignment shows the end time.

### Checkpoint

- [ ] Activation of User Administrator required a fresh passkey sign-in, although test user A was already signed in
- [ ] Test user A, with the active role, could change `jobTitle` of test user B
- [ ] Test user B is a member of `SC300-DeviceCode-Exception` only while the activation runs

**Note:** **PIM → Audit history** and **Entra ID → Audit logs** show activation, justification and the automatic removal at the end – the evidence an auditor wants for every exception.

**Why not leave the exception group permanent:** A member of the exception group may use device code flow for any app and any resource. A one-hour, justified, logged activation shrinks that window to the moment it is needed.
