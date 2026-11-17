---
title: 'Lab 1.3 – Google federation (Microsoft lab 06 with notes)'
lab:
    title: 'Lab 1.3 – Google federation (Microsoft lab 06 with notes)'
    module: 'Day 1 – Identities and external users'
---

# Lab 1.3 – Google federation (Microsoft lab 06 with notes)

**Estimated time:** 40 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** A Gmail user signs in to your tenant with Google – and you know the three places where this usually breaks.

Run [Microsoft lab 06 – Add a federated identity provider](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_06_AddFederatedIdentityProvider.html) and use the notes below at the matching steps.

### Notes to the Microsoft lab

1. **Google Cloud project, OAuth consent screen:** Leave the **Publishing status** on **Testing** only if you add your Gmail address under **Test users**. In Testing, Google blocks every account that is not on that list – before Entra ID is even contacted. The symptom is a Google error page, not an Entra error.

2. **Authorized domains** on the consent screen: `microsoftonline.com`. **Authorized redirect URIs** in the Google OAuth client – enter all three, exactly:

   ```text
   https://login.microsoftonline.com
   https://login.microsoftonline.com/te/<tenant-id>/oauth2/authresp
   https://login.microsoftonline.com/te/<tenant-name>.onmicrosoft.com/oauth2/authresp
   ```

3. **Invite the guest** with the script from [Lab 1.2](LAB_01_2_invite-a-guest-without-the-invitation-email.html) instead of the portal, and open the redeem URL yourself. The guest must sign in with **exactly** the invited Gmail address. If the browser is already signed in to another Google account, use an InPrivate window.

4. The built-in Google provider is for `gmail.com` and `googlemail.com` addresses. A Google Workspace domain (`name@company.com`) needs SAML/WS-Fed federation instead.

### Checkpoint

- [ ] The Gmail guest shows **Accepted** and, in the sign-in log, **Identity provider** `google.com`

**Note:** If you see "header too long" during the redirect, clear the cookies or use a fresh InPrivate window.

**If the redemption fails with AADSTS165000** on the way back from Google although the Google consent page appeared: tell the trainer. This error was reported as a service-side issue with Google redemption during 2026 – check the redirect URIs first, then try **Reset redemption status** and a new redeem URL.
