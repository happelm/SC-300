---
title: 'Lab 2.3 – Authentication context and protected actions'
lab:
    title: 'Lab 2.3 – Authentication context and protected actions'
    module: 'Day 2 – Authentication and access'
---

# Lab 2.3 – Authentication context and protected actions

**Estimated time:** 35 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Test user A can open Conditional Access policies as Conditional Access Administrator, but can only change or delete one after a fresh passkey sign-in.

**Why:** A normal Conditional Access policy is evaluated at sign-in. An authentication context is evaluated when a specific action is attempted – no matter how the user signed in earlier. Protected actions use that to guard the permissions an attacker wants most: changing Conditional Access, deleting named locations, hard-deleting objects. No developer is needed – PIM (Lab 4.1), sensitivity labels and protected actions all consume authentication contexts out of the box.

Requires Lab 2.1 (test user A has a passkey).

### Part A – Context and policy

1. **Entra ID → Conditional Access → Authentication contexts → + New authentication context**:

   | Setting | Value |
   |---|---|
   | Name | `Phishing-resistant step-up` |
   | ID | `c1` |
   | Publish to apps | **checked** |

   Without **Publish to apps** the context does not appear in protected actions or PIM.

2. **Conditional Access → Policies → + New policy**:

   | Setting | Value |
   |---|---|
   | Name | `CA203 – Step-up c1 – phishing-resistant` |
   | Users | Include `SC300-Passwordless`; exclude your admin account |
   | Target resources | **Authentication context → `Phishing-resistant step-up`** |
   | Grant | **Require authentication strength → Phishing-resistant MFA** |
   | Session | **Sign-in frequency → Every time** |
   | Enable policy | **On** (Report-only is not enough – the protected action would never be satisfied) |

   Authentication context is the **target** of the policy, authentication strength is its **grant control** – two different things in the same policy.

### Part B – Protect the action

3. **Entra ID → Roles & admins → Roles & admins → Conditional Access Administrator → + Add assignments** – assign test user A.

4. **Roles & admins → Protected actions → Add protected actions**. Context **`Phishing-resistant step-up`**, permissions:
   - `microsoft.directory/conditionalAccessPolicies/delete`
   - `microsoft.directory/conditionalAccessPolicies/basic/update`

   **Add** → **Save**.

5. Method **GET** in Graph Explorer (beta) – check the assignment:

   ```text
   https://graph.microsoft.com/beta/roleManagement/directory/resourceNamespaces/microsoft.directory/resourceActions/microsoft.directory-conditionalAccessPolicies-delete-delete?$select=name,authenticationContextId,isAuthenticationContextSettable
   ```

### Part C – Test

6. In the test user browser, sign in as test user A at `https://entra.microsoft.com` (with the passkey – `CA201` from Lab 2.1 requires it). The user is now strongly authenticated.

7. **Conditional Access → Policies** → open `CA202`. Editing is disabled and a note at the bottom asks you to reauthenticate. Select it and sign in with the passkey.

8. Change the policy description and save.

9. As admin: sign-in logs → the step-up sign-in of test user A → **Conditional Access** tab. `CA203` was applied and the request contained authentication context `c1`.

### Checkpoint

- [ ] Graph shows `authenticationContextId` `c1` on the delete permission
- [ ] Test user A had to reauthenticate before editing a policy, although already signed in with a passkey
- [ ] The sign-in log shows `CA203` applied to the step-up

**Note:** The protected action applies to everyone who performs it. Your admin account is not in `CA203`, so for the admin no policy applies to `c1` and editing works. If you ever lock yourself out of the Conditional Access page, `https://aka.ms/MSALProtectedActions` opens it with a fresh step-up.

**Before Day 4:** Creating a terms of use page registers it with Conditional Access and counts as a protected action. Remove the two protected actions (**Protected actions → select → Remove**) before you run the Microsoft terms of use lab, or the creation fails.

**Why sign-in frequency "Every time":** Without it, a passkey sign-in from an hour ago would still satisfy the policy. The value of step-up is a fresh proof at the moment of the sensitive action.
