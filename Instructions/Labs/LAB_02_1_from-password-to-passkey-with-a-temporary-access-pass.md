---
title: 'Lab 2.1 – From password to passkey with a Temporary Access Pass'
lab:
    title: 'Lab 2.1 – From password to passkey with a Temporary Access Pass'
    module: 'Day 2 – Authentication and access'
---

# Lab 2.1 – From password to passkey with a Temporary Access Pass

**Estimated time:** 45 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user A gets a Temporary Access Pass (TAP), registers a passkey in Microsoft Authenticator with it, and from then on a Conditional Access policy accepts only phishing-resistant sign-ins for this user.

**Why:** The Microsoft lab 08 still teaches per-user MFA – the model Microsoft recommends switching away from. Modern onboarding has no password and no SMS in it: the helpdesk issues a short-lived TAP, the user registers a phishing-resistant method, and Conditional Access requires exactly that strength. This lab builds that chain end to end.

You need your phone with Microsoft Authenticator (Android 14 or later, iOS 17 or later).

### Part A – Where are we coming from

1. **Entra ID → Users → Per-user MFA** – check that no user is **Enabled** or **Enforced**. Per-user MFA and Conditional Access MFA should not be mixed: per-user MFA asks on every sign-in and ignores everything Conditional Access knows about the session.

2. **Entra ID → Authentication methods → Policies** – check **Manage migration**. If it is not **Migration Complete**, the legacy MFA and SSPR method settings still apply in addition to this page.

### Part B – Enable the methods

3. **Entra ID → Groups → New group** – security group `SC300-Passwordless`, member: test user A.

4. **Authentication methods → Policies → Temporary Access Pass** → **Enable**, target `SC300-Passwordless`. **Configure**:

   | Setting | Value |
   |---|---|
   | Minimum lifetime | 1 hour |
   | Maximum lifetime | 8 hours |
   | Default lifetime | 1 hour |
   | One-time use | **Yes** |

5. **Authentication methods → Policies → Passkey (FIDO2)** → **Enable**, target `SC300-Passwordless`. On **Configure**, if a banner offers passkey profiles, opt in. Add a profile:

   | Setting | Value |
   |---|---|
   | Name | `Authenticator passkeys` |
   | Passkey types | **Device-bound** |
   | Target specific AAGUIDs | **Allow** → **+ Add AAGUID → Microsoft Authenticator** |

   On **Enable and target**, assign this profile to `SC300-Passwordless` and **Save**.

### Part C – Onboard the user

6. **Entra ID → Users →** test user A **→ Authentication methods → + Add authentication method → Temporary Access Pass** – one-time use, 1 hour. Copy the pass – it is shown only once.

7. In the test user browser (sign out first), go to `https://aka.ms/mysecurityinfo` and sign in as test user A. Choose **Use a Temporary Access Pass** instead of the password.

8. **+ Add sign-in method → Passkey** → **Microsoft Authenticator** and follow the prompts on the phone. With a one-time TAP you have 10 minutes for this registration.

### Part D – Require the strength

9. **Entra ID → Conditional Access → Policies → + New policy**:

   | Setting | Value |
   |---|---|
   | Name | `LAB201 – Phishing-resistant MFA – SC300-Passwordless` |
   | Users | Include `SC300-Passwordless`; exclude your admin account |
   | Target resources | **All resources** |
   | Grant | **Require authentication strength → Phishing-resistant MFA** |
   | Enable policy | **On** |

10. In a fresh InPrivate window, sign in as test user A at `https://myapplications.microsoft.com` – first with **password** only (use **Other ways to sign in** if the passkey is offered).

11. Sign in again, this time with the **passkey**.

12. As admin: **Entra ID → Monitoring & health → Sign-in logs** – open both sign-ins of test user A. Check **Authentication Details** and the **Conditional Access** tab.

### Checkpoint

- [ ] Test user A signed in with a TAP and registered a passkey in Authenticator
- [ ] A password sign-in of test user A is not enough – the user is asked for a stronger method
- [ ] The passkey sign-in succeeds; the sign-in log shows the passkey and `LAB201` as **Success**

**Note:** Order matters. If you turn on `LAB201` before the user has a passkey, the user can no longer reach the registration page: the TAP itself is not phishing-resistant. In production, combine the TAP with a policy for the user action **Register security information** that accepts a TAP.

**Why not SMS or Authenticator push:** Both can be relayed by an adversary-in-the-middle phishing page. A passkey is bound to the real sign-in domain – the phishing page cannot get a valid signature for `login.microsoftonline.com`.
