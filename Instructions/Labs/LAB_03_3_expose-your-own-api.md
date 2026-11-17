---
title: 'Lab 3.3 – Expose your own API'
lab:
    title: 'Lab 3.3 – Expose your own API'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.3 – Expose your own API

**Estimated time:** 25 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** An app registration **Employee API** defines an application ID URI, two delegated scopes with different consent rules, and one app role for background services – and you can show all three in the manifest.

**Why:** Microsoft lab 19 creates a scope that no client ever requests, and calls scopes "application permissions" – they are not. This lab and the next two build one chain: here the resource defines what can be granted, in Lab 3.4 a user-facing client gets a scope, in Lab 3.5 a background service gets an app role. Graph hides the resource side from you; with your own API you see cause and effect in one tenant.

**Scenario:** HR publishes an Employee API. Employees read their own record through a client app. A nightly sync service reads all records without a signed-in user.

1. **App registrations → + New registration** – name `Employee API`, single tenant, **no** redirect URI. An API validates tokens; it never receives a sign-in. Note the client ID.

2. **Expose an API → Application ID URI → Add** – keep `api://<client-id>` → **Save**. This value becomes the `aud` claim of every token issued for this API.

3. **Expose an API → + Add a scope**:

   | Setting | Value |
   |---|---|
   | Scope name | `Employees.Read` |
   | Who can consent | **Admins and users** |
   | Admin consent display name | Read employee records |
   | Admin consent description | Allows the app to read employee records on behalf of the signed-in user. |
   | User consent display name | Read your employee record |
   | User consent description | Allows the app to read your employee record on your behalf. |
   | State | Enabled |

4. Add a second scope:

   | Setting | Value |
   |---|---|
   | Scope name | `Employees.Write.All` |
   | Who can consent | **Admins only** |
   | Admin consent display name | Write all employee records |
   | Admin consent description | Allows the app to change any employee record on behalf of the signed-in user. |

5. **App roles → + Create app role**:

   | Setting | Value |
   |---|---|
   | Display name | Read all employees |
   | Allowed member types | **Applications** |
   | Value | `Employees.Read.All` |
   | Description | Allows a background service to read all employee records. |

6. **Manifest** – find `identifierUris`, the two entries in `api.oauth2PermissionScopes` with `"type": "User"` and `"type": "Admin"`, and `appRoles` with `allowedMemberTypes` `Application`.

### Checkpoint

- [ ] `Employee API` has the URI `api://<client-id>`
- [ ] The manifest shows `Employees.Read` with type `User` and `Employees.Write.All` with type `Admin` under `api.oauth2PermissionScopes`
- [ ] The manifest shows the app role `Employees.Read.All` for member type `Application`

**Scope vs app role:** A **scope** is a delegated permission – it ends up in the `scp` claim and is only ever used together with a signed-in user. An **app role** for applications is an application permission – it ends up in the `roles` claim and is used without a user. Nobody can consent to it except an admin, because there is no user to ask.

**Note:** `type: User` in the manifest is the technical value behind *Admins and users*. It means a user *may* consent – whether they actually can also depends on the tenant's user consent settings (Lab 3.7).
