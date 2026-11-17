---
title: 'Lab 2.5 – Deploy a Conditional Access baseline in report-only'
lab:
    title: 'Lab 2.5 – Deploy a Conditional Access baseline in report-only'
    module: 'Day 2 – Authentication and access'
---

# Lab 2.5 – Deploy a Conditional Access baseline in report-only

**Estimated time:** 50 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Import a complete, community-maintained Conditional Access baseline of 31 policies in report-only mode, protect it with a break-glass account, and read from the sign-in logs what the baseline *would* have blocked.

**Why:** Microsoft lab 13 builds one policy. A real tenant needs a set of policies that covers every user type and every gap – and that set must be readable for the next admin. The baseline by Joey Verlinden, based on Microsoft's Conditional Access framework by Claus Jespersen, is widely used for exactly that. Importing it is the easy part. The skill is the rollout: emergency access first, report-only, evidence from the logs, then switch on policy by policy.

Source: [github.com/j0eyv/ConditionalAccessBaseline](https://github.com/j0eyv/ConditionalAccessBaseline) (MIT license). The import script downloads the current version at runtime.

### How it works

The baseline is organized by **persona** – the kind of identity a policy is for – and the policy name says everything:

```text
CA205 - Internals - BaseProtection - AnyApp - Windows - CompliantorAADHJ
number  persona     purpose          target   platform  control
```

| Number range | Persona |
|---|---|
| CA0xx | Global – applies to everyone or closes gaps no other persona covers |
| CA1xx | Admins – anyone holding an admin role |
| CA2xx | Internals – employees |
| CA3xx | Service accounts – user accounts used by systems |
| CA4xx | Guests |
| CA5xx | Agents – AI agent identities; needs Agent 365 licensing, skipped by the script |

Every policy has its **own exclusion group** (`CA205-… - Exclude`) plus the shared `CA-BreakGlassAccounts - Exclude`. An exception is therefore always visible, scoped to one policy and reviewable – instead of one user excluded from everything.

The exported policies contain the object IDs of the author's tenant. The script creates the groups and named locations in your tenant, replaces every ID, strips export-only properties and creates the policies – in report-only unless you say otherwise. Existing policies with the same name are never touched.

### Part A – Emergency access first

1. **Entra ID → Users → New user** – `breakglass01`, cloud-only, a long random password (note it). **Assigned roles → Global Administrator**.

   In production an emergency account has two phishing-resistant credentials (FIDO2 keys in a safe), no mailbox, and an alert on every sign-in. For the lab the password is enough.

2. Check that security defaults are off: **Entra ID → Overview → Properties → Manage security defaults** – the script stops if they are on.

### Part B – Import

3. In PowerShell, from the lab files folder – first a dry run:

   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\Import-CABaseline.ps1 -BreakGlassUpn breakglass01@<tenant>.onmicrosoft.com -WhatIf
   ```

   Sign in as admin and consent. Read what *would* be created: named locations, exclusion groups, 31 policies.

4. Run it for real:

   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\Import-CABaseline.ps1 -BreakGlassUpn breakglass01@<tenant>.onmicrosoft.com
   ```

   `ALLOWED COUNTRIES` is created with `AT`, `DE`, `CH`. Use `-AllowedCountries` for other countries.

5. **Entra ID → Conditional Access → Policies** – 31 policies `CA000`–`CA404`, all **Report-only**. **Groups** – search `- Exclude`; `CA-BreakGlassAccounts - Exclude` has `breakglass01` as member.

### Part C – Read the baseline

6. Open three policies and answer the question in the table:

   | Policy | Question |
   |---|---|
   | `CA001-…-BLOCK-CountryWhitelist` | Which named location is excluded – and what happens to a user travelling to Spain once this is on? |
   | `CA004-…-AuthenticationFlows` | Compare with `LAB202` from Lab 2.2. Which resource does `LAB202` exclude that `CA004` does not, and what breaks because of it? |
   | `CA105-…-PhishingResistantMFA` | Which roles are included? Would this policy have been enough for Lab 2.3? |

### Part D – What would have happened

7. Generate sign-ins: in the test user browser, sign in as test user B at `https://myapplications.microsoft.com` and open Outlook on the web. Then sign in as test user A.

8. As admin: **Monitoring & health → Sign-in logs** → open the sign-in of test user B → tab **Report-only**. Every baseline policy is listed with its result:

   | Result | Meaning |
   |---|---|
   | **Report-only: Success** | The user met the requirement |
   | **Report-only: Failure** | The policy would have **blocked** the sign-in |
   | **Report-only: User action required** | The user would have been asked for something, for example MFA |
   | **Report-only: Not applied** | The policy did not match |

9. Find at least one **Failure**. `CA205` (Windows device must be compliant or hybrid joined) is the typical one: the lab VM is not managed by Intune.

10. **Conditional Access → Policies → What If** – user test user B, any cloud app, platform **Windows**, country **Spain**. Which baseline policies would apply, and with which result?

### Checkpoint

- [ ] `breakglass01` exists, is Global Administrator and is a member of `CA-BreakGlassAccounts - Exclude`
- [ ] 31 baseline policies exist, all in report-only
- [ ] You found a **Report-only: Failure** for test user B and can name the policy and the reason
- [ ] You can explain the difference between `CA004` and `LAB202`

**Do not switch the baseline on in the lab tenant.** `CA205` alone would block every participant on an unmanaged lab VM. In production, switch on in waves – usually CA002 (legacy authentication), the admin policies, then the user MFA policies – and only after report-only showed no unexpected failures for at least a week.

**Note:** The answer to the `CA004` question: `LAB202` excludes **Device Registration Service**. Since September 2024 an authentication flows policy that targets all resources also applies to device registration, so some device setups that register through device code flow fail under `CA004`. A baseline is a starting point, not something to switch on unread.

**Cleanup:** The script never deletes. To remove the baseline:

```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Policy.Read.All","Group.ReadWrite.All" -NoWelcome
Get-MgIdentityConditionalAccessPolicy -All | Where-Object DisplayName -match '^CA\d{3}-' |
    ForEach-Object { Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $_.Id }
Get-MgGroup -All -Filter "startswith(displayName,'CA')" | Where-Object DisplayName -like '* - Exclude' |
    ForEach-Object { Remove-MgGroup -GroupId $_.Id }
```
