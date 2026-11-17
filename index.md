---
title: SC-300 Lab Instructions
permalink: index.html
---

# SC-300 – Microsoft Identity and Access Administrator

Lab instructions for the four-day SC-300 course. The labs combine the official Microsoft labs (marked *Microsoft*) with own labs that replace weak ones and cover topics the official set leaves out. Use the copy button on every code block.

**Lab environment:** one hosted Microsoft 365 E5 tenant per participant (`WWLx…onmicrosoft.com`). Test user A and test user B are two users you pick in Lab 0.1. Lab files: [Labfiles](https://github.com/happelm/SC-300/tree/main/Labfiles).

## Day 0 – Setup

Hosted tenant, test users, two browser identities, Graph Explorer and Graph PowerShell.

| Lab | Title | Time |
|---|---|---|
| 0.1 | [Set up your lab](Instructions/Labs/LAB_00_1_set-up-your-lab.html) (draft) | 20 min |

## Day 1 – Identities and external users

Users, groups and roles, administrative units, licensing, B2B collaboration, cross-tenant access, identity providers, hybrid identity.

| Lab | Title | Time |
|---|---|---|
| MS 01 | [Manage user roles](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_01_ManageUserRoles.html) (Microsoft) | 30 min |
| 1.1 | [Scope an admin role with an administrative unit](Instructions/Labs/LAB_01_1_scope-an-admin-role-with-an-administrative-unit.html) (draft) | 25 min |
| MS 03 | [Assign licenses using group membership](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_03_AssignLicensesToUsersByGroupMembershipAAD.html) (Microsoft) | 20 min |
| MS 04 | [Configure external collaboration settings](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_04_ConfigureExternalCollaborationSettings.html) (Microsoft) | 15 min |
| 1.2 | [Invite a guest without the invitation email](Instructions/Labs/LAB_01_2_invite-a-guest-without-the-invitation-email.html) (draft) | 30 min |
| 1.3 | [Google federation (Microsoft lab 06 with notes)](Instructions/Labs/LAB_01_3_google-federation-notes.html) (draft) | 40 min |
| MS 02 | [Working with tenant properties](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_02_WorkingWithTenantProperties.html) (Microsoft), optional | 15 min |
| MS 07 | [Add hybrid identity with Microsoft Entra Connect](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_07_AddHybridIdentityWithAzureADConnect.html) (Microsoft), trainer demo | – |

## Day 2 – Authentication and access

Authentication methods and strengths, Temporary Access Pass and passkeys, SSPR, Conditional Access, authentication flows, authentication context and protected actions, ID Protection, Global Secure Access (demo).

| Lab | Title | Time |
|---|---|---|
| 2.1 | [From password to passkey with a Temporary Access Pass](Instructions/Labs/LAB_02_1_from-password-to-passkey-with-a-temporary-access-pass.html) (draft) | 45 min |
| MS 09 | [Configure self-service password reset](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_09_ConfigureAndDeploySelfServicePasswordReset.html) (Microsoft) | 25 min |
| MS 13 | [Implement and test a Conditional Access policy](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_13_ImplementAndTestAConditionalAccessPolicy.html) (Microsoft) | 30 min |
| 2.2 | [Block device code flow without breaking operations](Instructions/Labs/LAB_02_2_block-device-code-flow-without-breaking-operations.html) (draft) | 35 min |
| 2.3 | [Authentication context and protected actions](Instructions/Labs/LAB_02_3_authentication-context-and-protected-actions.html) (draft) | 35 min |
| 2.4 | [Trigger and remediate user risk](Instructions/Labs/LAB_02_4_trigger-and-remediate-user-risk.html) (draft) | 30 min |
| 2.5 | [Deploy a Conditional Access baseline in report-only](Instructions/Labs/LAB_02_5_deploy-a-conditional-access-baseline.html) (draft) | 50 min |
| MS 12 | [Manage smart lockout values](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_12_ManageAzureADSmartLockoutValues.html) (Microsoft), if time permits | 10 min |

## Day 3 – Workload identities and apps

Delegated and application permissions, consent, app registrations, exposing an API, app roles, credentials, custom roles, Defender for Cloud Apps.

| Lab | Title | Time |
|---|---|---|
| 3.1 | [Delegated permissions in Graph Explorer](Instructions/Labs/LAB_03_1_delegated-permissions-in-graph-explorer.html) (draft) | 25 min |
| 3.2 | [Your own single-page app](Instructions/Labs/LAB_03_2_your-own-single-page-app.html) (draft) | 40 min |
| 3.3 | [Expose your own API](Instructions/Labs/LAB_03_3_expose-your-own-api.html) (draft) | 25 min |
| 3.4 | [Client app with delegated access to your API](Instructions/Labs/LAB_03_4_client-app-with-delegated-access.html) (draft) | 30 min |
| 3.5 | [Daemon access with an app role](Instructions/Labs/LAB_03_5_daemon-access-with-an-app-role.html) (draft) | 55 min |
| 3.6 | [Delegate app credential management with a custom role](Instructions/Labs/LAB_03_6_delegate-app-credential-management.html) (draft) | 40 min |
| 3.7 | [User consent and the admin consent workflow](Instructions/Labs/LAB_03_7_user-consent-and-the-admin-consent-workflow.html) (draft) | 30 min |
| MS 20 | [Implement access management for apps](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_20_ImplementAccessManagementForApps.html) (Microsoft) | 10 min |
| MS 17 | [Defender for Cloud Apps discovery and restrictions](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_17_DefenderForCloudAppsDiscoveryAndRestrictions.html) (Microsoft) | 20 min |
| MS 18 | [Defender for Cloud Apps access policies](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_18_DefenderForCloudAppsAccessPolicies.html) (Microsoft), if time permits | 30 min |

## Day 4 – Governance and monitoring

Entitlement management, access reviews, terms of use, PIM for roles and groups, lifecycle of external users, logs and Secure Score.

| Lab | Title | Time |
|---|---|---|
| MS 22 | [Entitlement management catalog and access package](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_22_CreateAndManageACatalogOfResourcesInAADEntitlementManagement.html) (Microsoft) | 30 min |
| MS 25 | [Access reviews for internal and external users](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_25_CreatingAccessReviewsForUsers.html) (Microsoft) | 20 min |
| MS 23 | [Terms of use and acceptance reporting](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_23_AddTermsOfUseAcceptanceReporting.html) (Microsoft) | 25 min |
| MS 26 | [PIM for Microsoft Entra roles](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_26_ConfigurePrivilegedIdentityManagementForAADRoles.html) (Microsoft) | 30 min |
| 4.1 | [Just-in-time access with PIM and authentication context](Instructions/Labs/LAB_04_1_just-in-time-access-with-pim.html) (draft) | 40 min |
| MS 24 | [Lifecycle of external users](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_24_ManageTheLifecycleOfExternalUsersInAADIdentityGovernanceSettings%20.html) (Microsoft), optional | 10 min |
| 4.2 | [Investigate with sign-in and audit logs](Instructions/Labs/LAB_04_2_investigate-with-sign-in-and-audit-logs.html) (draft) | 30 min |
| MS 28 | [Identity Secure Score](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_28_MonitorIdentitySecureScore.html) (Microsoft) | 15 min |
| MS 27 | [Microsoft Sentinel KQL for Entra data](https://microsoftlearning.github.io/SC-300-Identity-and-Access-Administrator/Instructions/Labs/Lab_27_MicrosoftSentinelKustoQueries.html) (Microsoft), optional – needs Azure | 30 min |

## Reference

- [Concepts – applications and workload identities](Instructions/Concepts.html) – object model, flows, credentials, permissions, APIs, tokens, hardening, abbreviations.
- [Appendix](Instructions/Appendix.html) – lab conventions, objects, error codes, cleanup

## For trainers

[Trainer playbook](Trainer/Playbook.html) – timing, demos, which Microsoft labs to skip and why, known issues.
