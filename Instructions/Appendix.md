---
title: 'Appendix – Conventions, objects, error codes'
---

# Appendix – Conventions, objects, error codes

## Conventions

- **Test user A** and **test user B** are the two users you chose in [Lab 0.1](Labs/LAB_00_1_set-up-your-lab.html). Test user A becomes the passwordless, privileged test user; test user B stays a standard user.
- **Admin browser** – your normal browser, signed in as `admin@WWLx…`. **Test user browser** – a separate Edge profile or an InPrivate window.
- In Graph Explorer, set the method in the drop-down left of the URL box, clear the URL box and paste only the URL from the lab. Values in `{braces}` or `<angle brackets>` are placeholders.

## Objects created in the own labs

| Object | Type | Lab | Used again in |
|---|---|---|---|
| `AU-Sales` | Administrative unit | 1.1 | – |
| `SC300-Passwordless` | Security group (test user A) | 2.1 | 2.3, 2.4, 4.1 |
| `SC300-DeviceCode-Exception` | Security group, empty by default | 2.2 | 3.4, 4.1 |
| `CA201 – Phishing-resistant MFA – SC300-Passwordless` | Conditional Access policy | 2.1 | 2.3 |
| `CA202 – Block device code flow` | Conditional Access policy | 2.2 | 3.4, 4.1 |
| `CA203 – Step-up c1 – phishing-resistant` | Conditional Access policy | 2.3 | 4.1 |
| `CA204 – High user risk – secure password change` | Conditional Access policy | 2.4 | – |
| `Phishing-resistant step-up` (`c1`) | Authentication context | 2.3 | 4.1 |
| `SC300 SPA Demo` | App registration (SPA) | 3.2 | 3.7 |
| `Employee API` | App registration (resource) | 3.3 | 3.4, 3.5, 3.6 |
| `Employee Client` | App registration (public client) | 3.4 | – |
| `Employee Sync` | App registration (daemon) | 3.5 | 3.6, 4.2 |
| `App Credential Manager` | Custom role | 3.6 | – |
| `SC300 Consent Test` | App registration (SPA) | 3.7 | – |

## Order dependencies

- Lab 2.3 and 2.4 need the passkey of test user A from Lab 2.1.
- **Before the Microsoft terms of use lab (Day 4):** remove the protected actions from Lab 2.3. Creating a terms of use page counts as a Conditional Access change and fails otherwise.
- If `CA202` is on, device code flow for test user B needs the exception group (Lab 3.4) – or the just-in-time activation from Lab 4.1.

## Error codes you will meet

| Code | Meaning | Typical cause in these labs |
|---|---|---|
| `AADSTS50011` | Redirect URI mismatch | Port, trailing slash or `http`/`https` differs from the app registration (Lab 3.2) |
| `AADSTS53003` | Blocked by Conditional Access | `CA202` blocks device code flow (Lab 2.2) |
| `AADSTS530036` | Refresh token invalid due to authentication flow checks | Protocol tracking after a device code session (Lab 2.2) |
| `AADSTS65001` | No consent | Admin-only scope requested by a user (Lab 3.4) or consent not granted |
| `AADSTS700016` | Application not found in directory | Wrong client ID, or the app is in another tenant |
| `AADSTS7000218` | Request body must contain `client_assertion` or `client_secret` | **Allow public client flows** not set to Yes (Lab 3.4) |
| `AADSTS7000215` | Invalid client secret | The Secret **ID** was used instead of the **Value** (Lab 3.5) |
| `AADSTS9002326` | Cross-origin token redemption only for SPA | Redirect URI registered under **Web** instead of **Single-page application** (Lab 3.2) |
| `AADSTS500011` | Resource principal not found | Wrong application ID URI – often the client ID of the client app instead of the API |
| HTTP 403 `Authorization_RequestDenied` | Insufficient privileges | Delegated call for an attribute the user may not change (Lab 3.1) |
| HTTP 204 | No content | **Success** of a `PATCH` – the body is empty on purpose |

## Cleanup after the course

1. Turn off or delete `CA201`–`CA204`.
2. Remove protected actions, PIM settings changes and the eligible assignments.
3. Delete the app registrations from the table above – their service principals go with them.
4. Delete the custom role `App Credential Manager`, the groups and `AU-Sales`.
5. Reset **User consent settings** and **Admin consent settings** to the values you noted in Lab 3.7.
