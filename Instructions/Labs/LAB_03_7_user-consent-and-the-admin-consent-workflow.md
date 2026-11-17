---
title: 'Lab 3.7 – User consent and the admin consent workflow'
lab:
    title: 'Lab 3.7 – User consent and the admin consent workflow'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.7 – User consent and the admin consent workflow

**Estimated time:** 30 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Users can no longer consent to unknown apps on their own, but they can request approval – and you approve a request and find the resulting grant.

**Why:** Consent phishing ("illicit consent grant") does not steal a password: the victim approves a malicious multitenant app, and its grant survives every password reset. Turning user consent off completely stops that, but also every legitimate request – users then look for workarounds. The admin consent workflow is the middle ground. Microsoft lab 21 only shows the admin side of consent; this lab shows the whole loop.

Requires Lab 3.2 (or any app that test user B has not consented to yet).

### Part A – Settings

1. **Entra ID → Enterprise apps → Consent and permissions → User consent settings** – note the current value, then select **Allow user consent for apps from verified publishers, for selected permissions** → **Save**.

2. **Consent and permissions → Admin consent settings**:

   | Setting | Value |
   |---|---|
   | Users can request admin consent to apps they are unable to consent to | **Yes** |
   | Who can review admin consent requests | your admin account |
   | Consent request expires after (days) | 7 |

   **Save.** It can take up to an hour until the workflow is active – do Part B after the break or after another lab.

### Part B – Request

3. Test user B already consented to `SC300 SPA Demo` in Lab 3.2 – an existing grant stays valid when the settings change. Create a fresh app registration instead:

   | Setting | Value |
   |---|---|
   | Name | `SC300 Consent Test` |
   | Supported account types | **Single tenant** |
   | Redirect URI | **Single-page application (SPA)**, `http://localhost:3000` |

   Put its client ID into `clientId` in `app.js` and restart `serve -l 3000`.

4. As test user B, open `http://localhost:3000` and sign in. The page says **Approval required**. Enter a justification → **Request approval**.

### Part C – Review

5. As admin: **Enterprise apps → Activity → Admin consent requests → My pending** – open the request → **Review permissions and consent** → **Accept**.

6. As test user B, sign in again – no prompt.

7. **Enterprise apps →** the app **→ Permissions → Admin consent** – the grant is listed. **Audit logs** → filter **Activity: Consent to application** – the entry shows who consented and to what.

### Checkpoint

- [ ] Test user B could not consent but could request approval
- [ ] The request appeared under **My pending** and was accepted
- [ ] The audit log shows the consent with your admin account as actor

**Note:** *Verified publishers* only helps if the publisher is verified: a Microsoft partner links its partner ID to a multitenant app. Your lab apps are unverified, so test user B lands in the workflow – which is the point here.

**Why reviewers are not enough:** Being a reviewer does not grant the right to consent. To approve a request for Microsoft Graph **application** permissions the reviewer needs a role that may grant them; others can only deny or block.
