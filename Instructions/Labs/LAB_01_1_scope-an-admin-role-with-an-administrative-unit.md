---
title: 'Lab 1.1 – Scope an admin role with an administrative unit'
lab:
    title: 'Lab 1.1 – Scope an admin role with an administrative unit'
    module: 'Day 1 – Identities and external users'
---

# Lab 1.1 – Scope an admin role with an administrative unit

**Estimated time:** 25 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user A can reset passwords for the users of one department – and only for them.

**Why:** The Microsoft lab 01 assigns roles tenant-wide. In real organizations the helpdesk of a site or a subsidiary must not touch the CEO's account. Administrative units (AUs) are the Entra answer: the same built-in role, but limited to a set of objects. The difference only shows when you test both sides – what works and what does not.

1. **Entra ID → Roles & admins → Admin units → + Add**:

   | Setting | Value |
   |---|---|
   | Name | `AU-Sales` |
   | Restricted management administrative unit | **No** |

   Skip the role assignment page for now and create the AU.

2. Open `AU-Sales` → **Users → + Add member** – add two users whose department is Sales (filter the user list by **Department**). Do **not** add test user B.

3. In `AU-Sales` → **Roles and administrators** → **Helpdesk Administrator** → **+ Add assignments** – assign test user A.

4. Check the scope from the user side: **Entra ID → Users →** test user A **→ Assigned roles**. The assignment shows the scope `AU-Sales`, not `Directory`.

5. In the test user browser, sign in as test user A at `https://entra.microsoft.com`. Open one of the Sales users and select **Reset password**.

6. Still as test user A, open test user B and try **Reset password**.

7. Back as admin, method **GET** in Graph Explorer – list the role assignments of test user A (object ID from **Users →** test user A **→ Overview**):

   ```text
   https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?$filter=principalId eq '{object ID of test user A}'&$expand=roleDefinition($select=displayName)&$select=directoryScopeId
   ```

   `directoryScopeId` is `/administrativeUnits/{id}` for a scoped assignment and `/` for a tenant-wide one. Filtering on `directoryScopeId ne '/'` would be shorter, but Graph rejects `ne` and `startswith` on this property.

### Checkpoint

- [ ] Test user A can reset the password of a Sales user in `AU-Sales`
- [ ] Test user A cannot reset the password of test user B (the button is missing or the action fails)
- [ ] Graph shows the assignment with `directoryScopeId` `/administrativeUnits/...`

**Note:** A Helpdesk Administrator can only reset passwords of users who hold no admin role (or only a limited set of roles). If step 5 fails for a Sales user, check that the user has no role assignment.

**Why "Restricted management" stays off here:** A restricted management AU also locks out tenant-wide admins – even a Global Administrator cannot change its members unless they hold a role scoped to that AU. Use it for objects that must not be touched by the general IT staff, such as executive accounts. Try it afterwards with a second AU if time permits, and see what the admin loses.
