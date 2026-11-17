---
title: 'Lab 3.1 – Delegated permissions in Graph Explorer'
lab:
    title: 'Lab 3.1 – Delegated permissions in Graph Explorer'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.1 – Delegated permissions in Graph Explorer

**Estimated time:** 25 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** As test user B, change your own mobile phone number through Microsoft Graph, fail to change your own job title – and explain why the second call fails although the app has the permission.

**Why:** This is the permission model without any code and without your own app registration. Graph Explorer is a Microsoft multitenant app; its first use only creates a service principal in your tenant. Everything you see here – scopes, consent, the token, the 403 – applies one to one to every app your users sign in to.

Use the **test user** browser, signed in as test user B.

### Part A – Read

1. Open `https://aka.ms/ge` and sign in as test user B. Method **GET**, version **v1.0**:

   ```text
   https://graph.microsoft.com/v1.0/me?$select=displayName,jobTitle,department,mobilePhone
   ```

   Without `$select` Graph returns only a default set of properties – `mobilePhone` is not always in it.

### Part B – Write an allowed attribute

2. Tab **Modify permissions** → find `User.ReadWrite` → **Consent**. Accept the consent page.

3. Method **PATCH**, URL `https://graph.microsoft.com/v1.0/me`, **Request body**:

   ```json
   { "mobilePhone": "+43 660 1234567" }
   ```

   Expected: **204 No Content** – an empty response body is success.

4. Run step 1 again – the new number is there.

### Part C – Write an organizational attribute

5. Method **PATCH**, same URL, body:

   ```json
   { "jobTitle": "Chief Demo Officer" }
   ```

   Expected: **403**, `Authorization_RequestDenied`, *Insufficient privileges*.

6. **Modify permissions** → consent to `User.ReadWrite.All` as well (if the consent page says admin approval is required, stop here – that is already part of the answer). Repeat step 5.

7. Tab **Access token** → copy the token → open `https://jwt.ms` and paste it. Find `aud`, `appid`, `scp`.

### Checkpoint

- [ ] `PATCH mobilePhone` returned **204**, `PATCH jobTitle` returned **403**
- [ ] You can explain why a bigger scope does not fix the 403 for test user B
- [ ] In the token, `appid` is the Graph Explorer, not an app of your tenant

**Why the 403:** With delegated permissions the app acts *as the user*. The effective right is the **intersection** of the app's scope and what the user may do in the directory. A standard user may edit `mobilePhone` on their own account, but not `jobTitle` – that is an organizational attribute. The scope can be as big as you like; the user side of the intersection stays empty. With an admin role such as User Administrator the same call succeeds. With application permissions (Lab 3.5) there is no user at all, so only the scope counts.

**Note:** Do not test with `aboutMe`, `skills` or `interests`. These come from the SharePoint user profile, not from the directory, and often fail on `v1.0` for a completely different reason. A second, unrelated error in the same lab hides the lesson.
