---
title: 'Lab 3.6 – Delegate app credential management with a custom role'
lab:
    title: 'Lab 3.6 – Delegate app credential management with a custom role'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.6 – Delegate app credential management with a custom role

**Estimated time:** 40 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user B can renew the credentials of **Employee Sync** – and nothing else: no permissions, no other app. Then an application management policy makes sure that renewal can only be a certificate.

**Why:** The secret from Lab 3.5 expires. The person who renews it is usually the app owner, not the identity team. The common shortcuts are both bad: the business waits for an admin every time, or someone gets *Application Administrator*, which manages **every** app in the tenant. A custom role assigned on one app registration solves both. Microsoft lab 19 creates a custom role but never assigns or tests it – and picks permissions for password SSO and provisioning secrets, not for app credentials.

Requires Lab 3.5 including Part D.

### How it works

A custom role is a list of allowed operations – it does nothing until it is assigned, and the **place** of the assignment decides its reach. Assigned under **Roles & admins**, it applies to the whole directory. Assigned inside an app registration, it applies to that one object only. That is why Part A ends with four tests: an allowed operation, an operation outside the role, another object, and a setting that is not controlled by roles at all.

An application management policy works on a different axis: not *who* may change credentials, but *which kind* of credential may exist – for every person, admins included. Role and policy together give least privilege for people and for credentials.

### Part A – Delegate with a custom role

1. **Entra ID → Roles & admins → Roles & admins → + New custom role**:

   | Setting | Value |
   |---|---|
   | Name | `App Credential Manager` |
   | Permissions | `microsoft.directory/applications/credentials/update` |

2. **App registrations → Employee Sync → Roles and administrators → App Credential Manager → + Add assignments** – assign test user B. Assigning here, inside the app, scopes the role to this one object.

3. Test as test user B at `https://entra.microsoft.com` (wait a few minutes after the assignment):

   | Test | Expected |
   |---|---|
   | **App registrations → All applications → Employee Sync → Certificates & secrets → + New client secret** | Works |
   | **Employee Sync → API permissions → + Add a permission** | Not allowed |
   | **Employee API → Certificates & secrets → + New client secret** | Not allowed |
   | **App registrations → + New registration** | Depends on **User settings → Users can register applications**, not on this role |

4. As admin, check the scope in Graph Explorer, method **GET** (object ID of test user B from **Users**):

   ```text
   https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?$filter=principalId eq '{object ID of test user B}'&$expand=roleDefinition($select=displayName)&$select=directoryScopeId
   ```

   The `App Credential Manager` assignment has `directoryScopeId` `/{object ID of Employee Sync}` – the object ID of the app registration, not its client ID.

### Part B – Allow certificates only

The role decides **who** may manage credentials. An application management policy decides **what kind** of credential is allowed at all – for everyone, admins included.

5. As admin: **Entra ID → Enterprise apps → Application policies** → **Block password addition**:

   | Setting | Value |
   |---|---|
   | Status | **On** |
   | Applies to | **Select applications** → `Employee Sync` |

   **Save.** Applying it to one app keeps the rest of the tenant – and the other labs – unaffected.

6. As test user B: **Employee Sync → Certificates & secrets → + New client secret**. The secret is refused with a message that a policy blocks it.

7. As test user B: **Certificates → Upload certificate** – use `EmployeeSync.cer` from Lab 3.5 (copy it from the admin desktop or export the public key again). The upload works.

8. As admin, try step 6 yourself – the policy applies to you too.

### Checkpoint

- [ ] Test user B created a secret on `Employee Sync` before the policy
- [ ] Test user B could not add permissions and could not touch `Employee API`
- [ ] Graph shows the role assignment scoped to the application object
- [ ] After the policy, nobody could add a secret to `Employee Sync`, but a certificate upload worked

**Note:** The application owner (**Owners** blade) could also manage credentials – and everything else on the app, including its permissions. The custom role is narrower than ownership.

**Why the policy and the role belong together:** The custom role is least privilege for people, the policy is least privilege for credentials. Without the policy, test user B could still create a two-year secret and paste it into a script. Tenant-wide, the same blade can cap secret and certificate lifetime or block secrets for all apps created after a date – the usual way to phase secrets out without breaking existing apps.

**Why the place of assignment matters:** A custom role is a list of operations; it does nothing until it is assigned, and the place of assignment decides the reach. Assigned under **Roles & admins** it applies to the whole directory; assigned inside an app registration it applies to that app only.
