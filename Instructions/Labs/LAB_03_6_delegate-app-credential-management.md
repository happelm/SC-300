---
title: 'Lab 3.6 – Delegate app credential management with a custom role'
lab:
    title: 'Lab 3.6 – Delegate app credential management with a custom role'
    module: 'Day 3 – Workload identities and apps'
---

# Lab 3.6 – Delegate app credential management with a custom role

**Estimated time:** 25 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user B can renew the secret of **Employee Sync** – and nothing else: no permissions, no other app.

**Why:** The secret from Lab 3.5 expires. The person who renews it is usually the app owner, not the identity team. The common shortcuts are both bad: the business waits for an admin every time, or someone gets *Application Administrator*, which manages **every** app in the tenant. A custom role assigned on one app registration solves both. Microsoft lab 19 creates a custom role but never assigns or tests it – and picks permissions for password SSO and provisioning secrets, not for app credentials.

Requires Lab 3.5.

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

### Checkpoint

- [ ] Test user B created a secret on `Employee Sync`
- [ ] Test user B could not add permissions and could not touch `Employee API`
- [ ] Graph shows the assignment scoped to the application object

**Note:** The application owner (**Owners** blade) could also manage credentials – and everything else on the app, including its permissions. The custom role is narrower than ownership.

**Why the place of assignment matters:** A custom role is a list of operations; it does nothing until it is assigned, and the place of assignment decides the reach. Assigned under **Roles & admins** it applies to the whole directory; assigned inside an app registration it applies to that app only.
