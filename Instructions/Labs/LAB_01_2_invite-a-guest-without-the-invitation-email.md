---
title: 'Lab 1.2 – Invite a guest without the invitation email'
lab:
    title: 'Lab 1.2 – Invite a guest without the invitation email'
    module: 'Day 1 – Identities and external users'
---

# Lab 1.2 – Invite a guest without the invitation email

**Estimated time:** 30 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Invite a guest with Microsoft Graph, get the redeem URL that the admin center never shows, redeem it, and see which cross-tenant settings decided whether that worked.

**Why:** Invitation emails come from `invites@<your-tenant>.onmicrosoft.com` and often land in spam or are rejected by the recipient's mail system. In a hosted lab tenant they frequently do not arrive at all. The redeem URL removes the dependency on mail: you hand it over yourself. Knowing where the URL comes from also explains why it is not in the portal – it only exists in the response to the invitation request.

You need a personal mailbox you can sign in to – an `outlook.com` account or any other address (Email one-time passcode works for every mailbox).

### Part A – Invite and redeem

1. Check the starting point: **Entra ID → External Identities → External collaboration settings**. Note the values of **Guest invite settings** and **Collaboration restrictions**.

2. In PowerShell, from the lab files folder:

   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\New-GuestInvitation.ps1 -Email "<your personal address>"
   ```

   Sign in as admin when asked. The script prints `GuestObjectId`, `Status` (`PendingAcceptance`) and `RedeemUrl`.

3. Find the guest in **Entra ID → Users**. **Invitation state** shows **Pending acceptance**. Look for the redeem URL anywhere on the user page – it is not there.

4. Open the redeem URL in an InPrivate window and sign in with your personal account. Accept the consent page.

5. As admin, refresh the guest: **Invitation state** is now **Accepted**. Method **GET** in Graph Explorer:

   ```text
   https://graph.microsoft.com/v1.0/users?$filter=userType eq 'Guest'&$select=displayName,mail,userPrincipalName,externalUserState,externalUserStateChangeDateTime,creationType
   ```

### Part B – Redeem again

6. Run the script from step 2 **again** with the same address. Compare `GuestObjectId` with the first run.

7. **Entra ID → Users →** the guest → **Reset redemption status** → **Yes**. This is the portal way to the same result: the next sign-in redeems again, the user object stays.

### Part C – Who decided

8. **Entra ID → External Identities → Cross-tenant access settings → Default settings → Edit inbound defaults** – read the three tabs **B2B collaboration**, **B2B direct connect** and **Trust settings**. Do not change them.

9. On **Trust settings**, look at **Trust multifactor authentication from Microsoft Entra tenants**. Default is off: a guest from a partner tenant who already did MFA at home is asked again in your tenant if your Conditional Access requires MFA.

### Checkpoint

- [ ] The guest exists and shows **Accepted** without an invitation email being sent
- [ ] The second invitation returned the **same** `GuestObjectId` and a new redeem URL
- [ ] You can name the setting that controls whether MFA from a partner tenant counts in your tenant

**Note:** A personal Microsoft account (`outlook.com`) redeems with that account. An address that has neither a Microsoft account nor an Entra account redeems with **Email one-time passcode**: a code is mailed to the address – that mail comes from Microsoft and usually arrives even when the invitation mail does not.

**Why the same object ID:** The invitation manager matches the email address. For an existing guest it resets the redemption state and returns a new URL instead of creating a duplicate. Group memberships and app assignments of the guest stay.
