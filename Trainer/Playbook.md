---
title: 'Trainer playbook'
---

# SC-300 trainer playbook

How this course is run: what each day covers, which Microsoft labs we keep or replace and why, the demos, and the issues that have cost time before. Participants may read this too – nothing here is a secret, and knowing the traps is part of the skill.

> Before every run: check the [study guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/sc-300) for a new skills outline and run every lab marked *draft* once in a fresh hosted tenant.

## The course in one picture

| Day | Exam domain | Weight | Core message |
|---|---|---|---|
| 1 | Implement and manage user identities | 20–25 % | An identity is an object with lifecycle, scope and trust boundaries – not just a login |
| 2 | Implement authentication and access management | 25–30 % | Strength of the method, context of the request, risk of the user – three separate inputs to one decision |
| 3 | Plan and implement workload identities | 20–25 % | Every app is an identity. Delegated = scope ∩ user rights, app-only = scope |
| 4 | Plan and automate identity governance | 20–25 % | Standing access is the risk – grant just in time, review, log |

Weights as of the April 2026 skills outline. The study guide lists *Implement authentication and access management* with two different ranges in two places – 25–30 % in the overview is the number to quote.

## Lab environment and licensing reality

Each participant gets a hosted Microsoft 365 E5 tenant (`WWLx…onmicrosoft.com`) and a lab VM through GoDeploy: Entra ID P2, Defender for Cloud Apps, local admin on the VM (Node.js, Graph PowerShell install without issues), no Azure subscription guaranteed, no Entra-joined Windows device.

| Feature | Available in the hosted tenant | How we teach it |
|---|---|---|
| Conditional Access, authentication strengths, authentication context, protected actions | Yes (P1) | Labs 2.1–2.3 |
| ID Protection, PIM, access reviews, entitlement management | Yes (P2) | Lab 2.4, 4.1, Microsoft labs |
| Lifecycle Workflows | **No** – needs Entra ID Governance or Entra Suite | Trainer demo |
| Global Secure Access – Microsoft traffic profile | License yes (P1), but needs an Entra-joined Windows 11 device with the client | Trainer demo |
| Global Secure Access – Internet Access, Private Access | **No** – needs Entra Suite or the standalone SKUs | Trainer demo, slides |
| Conditional Access for workload identities, risky workload identities | **No** – needs Workload ID Premium | Slides |
| Managed identities, Key Vault (Microsoft lab 16), VM sign-in (lab 10), PIM for Azure resources (lab 11) | Only with an Azure subscription | Trainer demo |

## Microsoft labs – keep, extend or replace

| Lab | Verdict | Reason |
|---|---|---|
| 00 Lab setup | Replace → 0.1 | Still says "Azure AD Premium P2 trial"; hosted tenant needs none of it |
| 01 Manage user roles | Keep, extend → 1.1 | Fine for roles; scoping with administrative units is missing |
| 02 Tenant properties | Optional | Low exam value |
| 03 Group-based licensing | Keep | Works and is tested |
| 04 External collaboration settings | Keep | Short, prerequisite for 1.2 |
| 05 Add guest users | Replace → 1.2 | Depends on the invitation mail, which often does not arrive |
| 06 Federated identity provider | Keep with notes → 1.3 | Breaks on Google's *Testing* publishing status |
| 07 Entra Connect | Demo | 670 lines, 50 "Azure AD" references, needs a DC |
| 08 Enable MFA | Replace → 2.1 | Teaches per-user MFA |
| 09 SSPR | Keep | Works |
| 10 VM sign-in | Demo | Needs Azure |
| 11 PIM for Azure resources | Demo | Needs Azure |
| 12 Smart lockout | Optional | Five settings, no test |
| 13 Conditional Access | Keep | One of the better labs: has a test and What If |
| 14 Risk policies | Replace → 2.4 | Creates policies, never triggers them |
| 15 MFA registration policy | Replace → 2.1 | Legacy ID Protection policy; registration belongs to Conditional Access and TAP now |
| 16 Key Vault and managed identity | Demo | Needs Azure; good content otherwise |
| 17, 18 Defender for Cloud Apps | Keep | 18 if time permits |
| 19 Register an application | Replace → 3.3–3.6 | No token, no test; calls scopes "application permissions"; custom role with wrong permissions, never assigned |
| 20 Access management for apps | Keep | 5 minutes, user assignment |
| 21 Admin consent | Replace → 3.7 | Admin side only |
| 22 Entitlement management | Keep | Good |
| 23 Terms of use | Keep | Remove protected actions first (see known issues) |
| 24 External user lifecycle | Optional | Short |
| 25 Access reviews | Keep | Good |
| 26 PIM for roles | Keep, extend → 4.1 | Uses *Require MFA on activation*; authentication context is the better answer |
| 27 Sentinel KQL | Optional | Needs Azure / Log Analytics |
| 28 Identity Secure Score | Keep | Short closing lab |

Not covered by any Microsoft lab although in the skills outline: Temporary Access Pass, passkeys, authentication flows (device code), authentication context, protected actions, admin consent workflow, cross-tenant access settings, Global Secure Access, Lifecycle Workflows, Microsoft Entra Kerberos.

## Day 1 – Identities and external users

**Flow:** objects and roles → administrative units → licensing → B2B → identity providers → hybrid (demo).

**Demos**

1. *Object IDs everywhere* – one user in the admin center, then `GET /users/{upn}` in Graph Explorer. Point out `id`, `userPrincipalName`, `onPremisesSyncEnabled`. Sets up Day 3 – the same object model applies to service principals.
2. *Restricted management AU* – create one with a single user, show that the Global Administrator can no longer edit that user. Good discussion starter about who protects the executives.
3. *Entra Connect / Cloud Sync* – show the sync status in **Entra ID → Entra Connect**, explain cloud sync vs. connect sync, source of authority. Do not run Microsoft lab 07 in class.

**Discussion:** What does a guest object look like after redemption? (`userType`, `externalUserState`, `creationType`, identities collection.)

**Known issues**

- `roleAssignments?$filter=directoryScopeId ne '/'` fails with `Request_UnsupportedQuery` – Graph supports only `eq` on that property. The labs filter on `principalId` instead.
- Invitation emails come from `invites@<tenant>.onmicrosoft.com` since December 2025 (before: `invites@microsoft.com`). The onmicrosoft.com domain has no sender reputation; many recipients filter or reject it. Lab 1.2 avoids the mail entirely. For customers: set a verified custom domain as default (Exchange Online license needed) or send the redeem URL from your own system.
- Google federation: OAuth consent screen on *Testing* blocks every Google account that is not a listed test user – the error is on Google's side, not in Entra.
- The redeem URL exists only in the response to `POST /invitations`. Re-inviting the same address returns the same object ID and a fresh URL.

## Day 2 – Authentication and access

**Flow:** methods policy → TAP and passkeys → authentication strengths → SSPR → Conditional Access (Microsoft 13) → authentication flows → authentication context and protected actions → ID Protection → Global Secure Access (demo).

**Demos**

1. *Per-user MFA vs. Conditional Access* – open **Users → Per-user MFA** and the methods policy migration status side by side. Message: per-user MFA still exists, but its method settings moved to the Authentication methods policy; MFA enforcement belongs in Conditional Access.
2. *Device code phishing in 60 seconds* – start `Invoke-DeviceCodeFlow.ps1` with the first-party Graph PowerShell client ID, hand the code to a participant, show that they sign in on the real Microsoft page and the token lands in your console. Then the Conditional Access block. Nothing explains the risk better.
3. *Authentication context ≠ authentication strength* – one policy on screen: context is the **target**, strength is the **grant**. The question "isn't authentication context the same as authentication strength?" comes up every time.
4. *Global Secure Access* (needs an Entra-joined Windows 11 VM with the client): enable the Microsoft traffic profile, show source IP restoration in the sign-in log, then a Conditional Access policy with the **compliant network** condition. Explain Internet Access and Private Access licensing (Entra Suite) on slides.

**Discussion:** Which of your production exceptions to device code flow are real? (Teams Rooms, Tunnel Gateway setup, Azure CLI on headless servers.) Which could move to workload identities?

**Known issues**

- Turning on a phishing-resistant policy before the user has a passkey locks the user out of registration – the TAP itself is not phishing-resistant. Lab 2.1 has the right order.
- An authentication-flows policy that targets *All resources* also hits device registration since September 2024 – exclude **Device Registration Service**.
- Protected actions need the policy **On**; in report-only the step-up is never satisfied and the user loops.
- Password change as risk remediation only works for users who can do MFA.

## Day 3 – Workload identities and apps

This is the day where most uncertainty sits. The labs form one chain – keep the order.

**Flow:** application object vs. service principal → delegated permissions in Graph Explorer (3.1) → own SPA (3.2) → own API (3.3) → delegated client (3.4) → daemon with app role (3.5) → credential delegation (3.6) → consent (3.7) → Defender for Cloud Apps.

**Whiteboard first**

| | App registration (application object) | Enterprise app (service principal) |
|---|---|---|
| Exists | once, in the home tenant | once per tenant that uses the app |
| Holds | client ID, redirect URIs, requested permissions, credentials, exposed API, app roles | consent grants, user assignment, Conditional Access targeting, local role assignments |
| Graph | `/applications` | `/servicePrincipals` |

Then the client type question: *can this app keep a secret from the person running it?* No → public client (SPA, mobile, desktop, CLI) → auth code + PKCE or device code, no credential. Yes → confidential client → auth code (web app) or client credentials (daemon), credential order managed identity › workload identity federation › certificate › secret.

**Demos**

1. *Same token, different app* – decode a Graph Explorer token (3.1) and a token from the own SPA (3.2) side by side: `aud` and `scp` identical, `appid` different.
2. *Dynamic consent* – show the SPA working with an **empty** API permissions blade, then show the grant under **Enterprise apps → Permissions**. `requiredResourceAccess` is a declaration; the `oauth2PermissionGrant` on the service principal is the permission. Then show where the declaration is mandatory: `/.default` in Lab 3.5.
3. *The jobTitle 403* – same call as standard user (403) and as User Administrator (204). Delegated = scope ∩ user rights.
4. *Error messages with AI* – paste an `AADSTS` error into Claude and let it explain cause and fix; then verify against the error code reference. Good moment for "AI as sparring partner, not oracle": ask it to generate a Graph script with permission GUIDs and check the GUIDs with `Find-MgGraphPermission`.

**Known issues**

- `aboutMe`, `skills`, `interests` are SharePoint user profile attributes, not directory attributes – they often fail on `v1.0` for reasons that have nothing to do with permissions. Use `mobilePhone` for write tests.
- `AADSTS9002326` (*cross-origin token redemption is permitted only for the Single-Page Application client type*) – the redirect URI is under **Web** instead of **SPA**. Shows up the moment someone publishes the SPA behind Application Proxy and adds the new URL to the wrong platform.
- `npx serve` fails with *could not determine executable to run* on fresh Node installs – install `serve` globally.
- The SPA demo shows a clear message for the usual setup errors (placeholder IDs, `file://`, MSAL not loaded). If a participant reports "nothing happens on sign-in", open the browser console.
- Admin consent workflow takes up to an hour to become active after enabling it – enable it before lunch, use it after.

## Day 4 – Governance and monitoring

**Flow:** entitlement management → access reviews → terms of use → PIM (Microsoft 26) → PIM with authentication context and PIM for Groups (4.1) → external user lifecycle → logs and Graph (4.2) → Secure Score.

**Demos**

1. *Lifecycle Workflows* (not licensed in the hosted tenant) – joiner workflow with a *Generate TAP and send email* task to the manager. Connects Day 2 (TAP) with Day 4.
2. *PIM "require MFA" vs. authentication context* – activate a role twice: once with the MFA setting (no prompt, the session already has MFA), once with the context (passkey prompt).

**Known issues**

- Creating a terms of use page counts as a Conditional Access change – it fails while the protected actions from Lab 2.3 exist. Remove them before Microsoft lab 23.
- PIM activations take a minute or two to apply; sign out and in before testing the new role.

## Exam traps worth one slide each

- ROPC (app collects user name and password) is never the right answer.
- Implicit flow for a new SPA is wrong – auth code with PKCE.
- Managed identity only exists for code running in Azure. On-premises: certificate or workload identity federation.
- A delegated call fails despite a big scope → the user lacks the directory right, not the app.
- Client credentials request `…/.default`, never single scopes.
- `PATCH` returning 204 is success.
- Authentication context is a target, authentication strength is a grant control.
- Block device code flow with Conditional Access → Conditions → Authentication flows; manage exceptions just in time.

## Pre-course checklist

- [ ] Study guide checked for a new skills outline
- [ ] Every *draft* lab run once in a hosted tenant – remove the draft banner and "(draft)" in `index.md`/`README.md` for each lab that ran
- [ ] Demo tenant with Entra Suite or Governance trial for Lifecycle Workflows and Global Secure Access, plus an Entra-joined Windows 11 VM with the GSA client
- [ ] Graph calls in Lab 4.2 (sign-in logs, audit logs, PIM requests) run once – they are checked against the documentation only
