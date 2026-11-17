---
title: 'Concepts – Applications and workload identities'
---

# Concepts – Applications and workload identities

A reference for Day 3 and for later: the object model, app types and flows, credentials, permissions and consent, APIs, tokens and hardening. The labs refer to the sections here instead of repeating them.

## 1. Two objects: application and service principal

Everything in Entra app management comes down to two objects. Mixing them up is the most common source of confusion.

| | Application object | Service principal |
|---|---|---|
| Admin center | **App registrations** | **Enterprise apps** |
| Metaphor | The blueprint | The instance built from it |
| Lives in | The **home tenant** only | **Every tenant** that uses the app |
| Count | Exactly one, worldwide | One per tenant |
| Holds | Client ID, redirect URIs, requested permissions, credentials, exposed API, app roles | Consent grants, user and group assignments, Conditional Access targeting, local role assignments |
| Microsoft Graph | `/applications` | `/servicePrincipals` |

What follows from it:

- A **single-tenant** app has its application object and its service principal in the same tenant.
- A **multitenant** app has one application object in the developer's tenant. Every customer tenant gets its own service principal the moment an admin or user consents.
- Microsoft's own apps – Graph PowerShell, Azure CLI, Graph Explorer – have their application object in a Microsoft tenant. You never see them under your **App registrations**, only as a service principal under **Enterprise apps** after first use.
- The `appId` (client ID) is the same in every tenant. The object `id` of the service principal is different in each tenant – and different from the object `id` of the application.

> App registration = what the app is and may ask for. Enterprise app = what this tenant actually lets it do.

## 2. App types and OAuth flows

The deciding question: **can the app keep a secret from the person running it?**

### Public clients – no safe place for a secret

The code runs on the user's device; memory and traffic can be read.

- **Single-page app (SPA)** – React, Angular, Vue, plain JavaScript → authorization code flow with PKCE. Never a client secret. The implicit flow is legacy and off by default.
- **Mobile and desktop apps** → authorization code flow with PKCE, through the system browser or a broker.
- **Input-constrained devices** – a CLI on a headless Linux server, a TV, a kiosk → device code flow.

### Confidential clients – a protected server

The code runs where users cannot reach file system or memory; credentials are allowed and expected.

- **Server-side web app** (ASP.NET Core, Spring, an Express backend) → authorization code flow, with a credential at the token exchange.
- **Daemon, service, job, API** – no user at all → client credentials flow with application permissions.

### PKCE

**PKCE** (Proof Key for Code Exchange, pronounced "pixie") protects public clients against a stolen authorization code:

1. For every sign-in the client creates a random one-time secret, the **code verifier**.
2. It hashes it with SHA-256 into the **code challenge** and sends only the challenge to `/authorize`.
3. When it redeems the code at `/token`, it sends the original verifier. Entra hashes it again and compares.

A stolen code without the verifier is worthless. For a public client, PKCE takes the place of the secret a confidential client would send at this step.

### Choosing a flow

| App type | Code runs on | User present | Flow | Credential |
|---|---|---|---|---|
| SPA | Browser | Yes | Auth code + PKCE | None |
| Mobile, desktop | Device | Yes | Auth code + PKCE | None |
| Input-constrained | Device without browser | Yes | Device code | None |
| Web app | Web server | Yes | Auth code | Managed identity, certificate |
| Daemon, script, API | Server, cloud, pipeline | **No** | Client credentials | Managed identity, federated credential, certificate |

**ROPC** (resource owner password credentials): the app collects user name and password and sends them to Entra. It bypasses MFA and federation and does not work with passwordless accounts. In an exam scenario it is almost always the wrong answer.

**Device code flow** is the only flow where the device that asks for the token is not the device that signs in. That is what makes device code phishing possible – see [Lab 2.2](Labs/LAB_02_2_block-device-code-flow-without-breaking-operations.html).

## 3. Credentials for workload identities

For every confidential client the order of preference is:

**Managed identity › Workload identity federation › Certificate › Client secret**

1. **Managed identity** – the code runs on an Azure resource (VM, App Service, Functions, Container Apps, AKS). No credential in code or configuration; Azure issues and rotates it.
   - *System-assigned* – tied 1:1 to the resource and deleted with it.
   - *User-assigned* – a resource of its own, attachable to several resources, outlives them.
2. **Workload identity federation** – the code runs outside Azure (GitHub Actions, Azure DevOps, Kubernetes, AWS, Google Cloud). A **federated credential** on the app registration trusts tokens from an external issuer for an exact subject – for GitHub, for example, `repo:<org>/<repo>:ref:refs/heads/main`. The workload exchanges its own token for an Entra token. Nothing to store, nothing to rotate. Free – no Workload ID Premium needed.
3. **Certificate (X.509)** – the solid choice where neither of the above applies, typically on-premises. Only the public key is uploaded; the private key stays on the host, ideally in a certificate store, Key Vault or HSM. Needs lifecycle management – an expired certificate stops the workload. See [Lab 3.5, Part D](Labs/LAB_03_5_daemon-access-with-an-app-role.html).
4. **Client secret** – a password. Ends up in repositories, scripts and chats, is rarely rotated. Acceptable for a lab, not for production.

**Application management policies** enforce this order tenant-wide – for example *block password addition* or *restrict max certificate lifetime*. They are part of Entra ID at no extra cost: **Entra ID → Enterprise apps → Application policies**. See [Lab 3.6, Part B](Labs/LAB_03_6_delegate-app-credential-management.html).

> A single-page app uses **none** of these. It is a public client without a credential and works with the identity of the signed-in user. A secret in browser JavaScript can be read with F12.

## 4. Permissions and consent

### Delegated and application permissions

| | Delegated | Application |
|---|---|---|
| Context | App **and** a signed-in user | App **alone** |
| Token claim | `scp` (space-separated scopes) | `roles` |
| Effective right | **Scope ∩ what the user may do** | **Scope only** |
| Consent | User or admin (some scopes admin only) | **Always** admin consent |
| Requested as | Single scopes, for example `User.Read` | `<resource>/.default` |
| Typical app | SPA, web app acting as the user | Daemon reading all mailboxes at night |

### The intersection rule

With delegated permissions the effective right is the **intersection** of the app's scope and the user's own rights in the directory:

- A standard user cannot change `jobTitle`, `department`, `displayName` or `userPrincipalName` on their own account. These are organizational attributes. The call fails with `403 Insufficient privileges` – whatever the app's scope, even with `User.ReadWrite.All`, because the user side of the intersection is empty.
- For the delegated call to succeed, the **signed-in user** needs a directory role such as *User Administrator*. A bigger scope alone does not help.
- With **application** permissions there is no user who limits the call. With `User.ReadWrite.All` as an application permission, the same `PATCH` succeeds.

> Delegated = scope ∩ user rights. App-only = scope. A bigger scope helps a privileged caller, because their user right exists – it does nothing for a standard user.

### What `User.ReadWrite` can write on `/me`

| Writable by the user | Blocked for the user |
|---|---|
| `mobilePhone`, `preferredLanguage`, the photo at `/me/photo/$value`, and `aboutMe`\*, `birthday`\*, `interests`\*, `skills`\*, `pastProjects`\*, `responsibilities`\*, `mySite`\* | `jobTitle`, `department`, `officeLocation`, `employeeId`, `displayName`, `givenName`, `surname`, `userPrincipalName`, `mail`, `manager` |

\* These are SharePoint user profile attributes, not directory attributes. On `v1.0` they often fail for reasons that have nothing to do with permissions. Use `mobilePhone` for write tests.

### Consent

- **Dynamic consent** – the app asks for scopes at sign-in, and the consent creates an `oauth2PermissionGrant` on the service principal. This works even when **API permissions** in the app registration is empty.
- **API permissions** in the app registration writes `requiredResourceAccess` – a declaration of what the app wants. It is what **Grant admin consent** and `/.default` are built from. Application permissions only work through this declaration.

> `requiredResourceAccess` on the application = the app would like. The grant on the service principal = the tenant allows. Only the grant ends up in a token.

- **User consent settings** (**Enterprise apps → Consent and permissions**): *Do not allow user consent* / *Allow user consent for apps from verified publishers, for selected permissions* / *Allow user consent for apps*. The middle option is the recommended default.
- **Admin consent** grants a permission for the whole tenant. Required for every application permission and for admin-only scopes.
- **Admin consent workflow** – users who cannot consent can request approval; reviewers approve from a queue. Keeps user consent restricted without blocking legitimate requests.
- **Illicit consent grant (consent phishing)** – the attacker gets a user to consent to a malicious multitenant app. The grant survives every password reset. Countermeasures: restrict user consent, use the admin consent workflow, review grants regularly, and watch OAuth app policies in Defender for Cloud Apps.

### Verified publisher

The blue badge next to an app name on the consent screen. The publisher has a verified **Microsoft AI Cloud Partner Program** account with the same identity as the app owner and has added its partner ID to the multitenant app (**Branding & properties → Publisher verification**). It matters because *allow user consent for verified publishers* is the recommended setting.

## 5. APIs: calling them and exposing your own

### Three roles

Every OAuth exchange has three parties. Separating them makes every error message easier to place.

| Role | Who | Example |
|---|---|---|
| **Client** | The app that wants access | Your SPA, a sync script |
| **Authorization server** | Issues tokens | Entra ID at `login.microsoftonline.com` |
| **Resource server** | The protected API the token is for | Microsoft Graph or your own API |

The `aud` claim names the resource server. A token is only valid at the resource it was issued for – a Graph token is worthless at any other API, and the client needs one token per resource.

### Entra endpoints

Tenant-specific under `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/`:

- `/authorize` – interactive sign-in and consent, returns the authorization code. The **code challenge** goes here.
- `/token` – exchanges a code, client credentials, a device code or a refresh token for tokens. The **code verifier** goes here.
- `/devicecode` – issues `device_code` and `user_code`.

The v2.0 endpoint works with `scope`; the old v1.0 endpoint worked with `resource`. New apps and current MSAL versions use v2.0.

### Microsoft Graph as a resource server

- `https://graph.microsoft.com/v1.0` is generally available; `/beta` is preview and not for production scripts.
- `aud` is `https://graph.microsoft.com` or Graph's client ID `00000003-0000-0000-c000-000000000000`.
- `$select` is needed for properties outside the default set, such as `mobilePhone`.
- A successful `PATCH` returns **204 No Content** – an empty body is success.
- Under load Graph answers `429 Too Many Requests` with a `Retry-After` header. Wait for it; do not retry in a tight loop.
- Not every filter works on every property. `roleAssignments?$filter=directoryScopeId ne '/'` fails with `Request_UnsupportedQuery` – only `eq` is supported there.

### `.default`

With **client credentials** you never request single permissions. You request `https://graph.microsoft.com/.default` (or `api://<your-api>/.default`): everything an admin has already consented to for this app on that resource. There is no one to ask at runtime, so the decision is made at admin consent, from `requiredResourceAccess`.

**Delegated** flows request concrete scopes such as `User.Read`.

### Exposing your own API

On the app registration of the API (**Expose an API**, **App roles**):

- **Application ID URI** – `api://<client-id>` or a verified domain. It becomes the `aud` of tokens for this API. Application management policies can block custom URIs that are not in a secure format.
- **Scopes** – delegated permissions; they end up in `scp`. *Who can consent* decides whether users may consent (`type: User` in the manifest) or only admins (`type: Admin`).
- **App roles** – with member type *Applications* they are application permissions and end up in `roles`. With member type *Users/Groups* they are assigned to people under **Enterprise apps → Users and groups**.

### Validating tokens in your API

An API that accepts Entra tokens must check, in this order:

1. The **signature**, against Entra's public keys – the `jwks_uri` from `https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration`.
2. `iss` – the issuer is your tenant.
3. `aud` – the token is for this API.
4. `exp` and `nbf` – the token is valid now.
5. `scp` (delegated) **or** `roles` (app-only) contains the permission the operation needs.

Never trust a claim from an unvalidated token, and never authorize on `appid` or `upn` alone. In practice a library does steps 1–4 – Microsoft.Identity.Web for .NET, for example; step 5 is your code.

## 6. Reading an access token

A JWT (JSON Web Token) has three Base64URL parts separated by dots: header, payload with the claims, and signature. Paste a token into `https://jwt.ms` or use `ConvertFrom-Jwt.ps1` from the lab files.

| Claim | Meaning |
|---|---|
| `aud` | Audience – the resource the token is for |
| `iss` | Issuer – which tenant issued it |
| `scp` | Delegated scopes – only in tokens with a user |
| `roles` | Application permissions or app role assignments |
| `tid` | Tenant ID |
| `appid` / `azp` | Client ID of the app that requested the token (v1 / v2 token) |
| `oid` | Object ID of the user – or of the service principal in an app-only token |
| `upn`, `name` | The user – missing in app-only tokens |
| `acrs` | Authentication context IDs the sign-in satisfied, for example `c1` |
| `ver` | Token version, `1.0` or `2.0` |
| `iat` / `nbf` / `exp` | Issued at, not before, expires (Unix time) |

The contrast that makes delegated vs. application tangible:

- Delegated token: `scp: "User.Read User.ReadWrite"` plus `upn` and `name`.
- App-only token: `roles: ["User.ReadWrite.All"]`, no `scp`, no user.

Note: Microsoft Graph tokens cannot be validated by your own code – their signature is meant for Graph. jwt.ms reads them fine; just do not build a validation test on them.

## 7. Error codes

`AADSTS` codes come from the authorization server (Entra). HTTP status codes come from the resource server (Graph or your API). The full table is in the [appendix](Appendix.html#error-codes-you-will-meet).

## 8. Hardening applications

- **Who may register apps** – **Entra ID → User settings → Users can register applications = No**; give developers the *Application Developer* role instead.
- **Allow public client flows** – off by default on your own registrations. Turning it on allows device code flow and ROPC for **this app only**. Microsoft's own apps such as Graph PowerShell (`14d82eec-204b-4c2f-b7e8-296a70dab67e`) have it on, which is why `Connect-MgGraph -UseDeviceCode` works in every tenant.
- **App instance property lock** – stops anyone in a tenant from adding credentials to the service principal of an app, where they would bypass the app owner. Enabled by default for new app registrations since June 2026; check older apps under **App registrations → Authentication → App instance property lock**.
- **Application management policies** – tenant default or per app: block secrets, cap secret and certificate lifetime, allow only trusted certificate authorities, block insecure identifier URIs.
- **Credential hygiene** – prefer managed identity, federation or certificates; alert on expiring credentials; treat any secret that was ever in source control or a chat as compromised.
- **Block device code flow** with Conditional Access → **Conditions → Authentication flows**, exclude **Device Registration Service**, and grant exceptions just in time with PIM for Groups – [Lab 2.2](Labs/LAB_02_2_block-device-code-flow-without-breaking-operations.html) and [Lab 4.1](Labs/LAB_04_1_just-in-time-access-with-pim.html).
- **Workload identities in Conditional Access and ID Protection** – blocking a service principal by location, or detecting a leaked credential, needs Workload ID Premium.

## 9. Exam traps

| Statement | Correct reading |
|---|---|
| "The app asks for user name and password" | ROPC – wrong, bypasses MFA |
| Implicit flow for a new SPA | Wrong – authorization code with PKCE |
| Managed identity for an on-premises server | Wrong – only for code on Azure resources; use a certificate or federation |
| Delegated call fails despite a big scope | The user lacks the directory right, not the app |
| App-only call needs no admin role for a user | Correct – there is no user |
| `PATCH` returns 204 | Success |
| Enterprise app vs. app registration | Access, assignment, consent vs. definition and configuration |
| Scope for client credentials | `…/.default`, never single permissions |
| Authentication context vs. authentication strength | Context is the **target** of a policy, strength is a **grant control** |
| Block device code flow | Conditional Access → Authentication flows; exceptions just in time |
| Protect against malicious apps | Restrict user consent, admin consent workflow, verified publishers |

## 10. Abbreviations

| Abbreviation | Stands for | Meaning |
|---|---|---|
| AKS | Azure Kubernetes Service | Managed Kubernetes in Azure |
| API | Application Programming Interface | Programmatic interface, for example Microsoft Graph |
| AU | Administrative unit | Container that scopes admin roles to a set of objects |
| CA | Conditional Access | Policy engine for access decisions |
| CLI | Command-line interface | For example Azure CLI |
| FIDO2 | Fast Identity Online 2 | Standard behind passkeys |
| GA | General availability | Supported for production |
| HSM | Hardware security module | Hardware key store |
| JWT | JSON Web Token | Signed token format: header.payload.signature |
| MFA | Multifactor authentication | |
| MI | Managed identity | Azure-managed identity for code on Azure resources |
| MSAL | Microsoft Authentication Library | Sign-in library, for example `msal-browser.js` |
| OAuth 2.0 | Open Authorization | Authorization framework |
| OIDC | OpenID Connect | Authentication layer on top of OAuth 2.0 |
| PIM | Privileged Identity Management | Just-in-time activation of roles and group memberships |
| PKCE | Proof Key for Code Exchange | Code protection for public clients |
| ROPC | Resource owner password credentials | Password flow – avoid |
| SP | Service principal | The app's instance in a tenant |
| SPA | Single-page application | Browser app |
| TAP | Temporary Access Pass | Time-limited passcode for onboarding and recovery |
| UPN | User principal name | Sign-in name, `name@domain` |
| URI | Uniform resource identifier | For example a redirect URI or application ID URI |
| WIF | Workload identity federation | Token exchange for workloads outside Azure |
