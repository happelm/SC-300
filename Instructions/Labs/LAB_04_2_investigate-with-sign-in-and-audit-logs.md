---
title: 'Lab 4.2 – Investigate with sign-in and audit logs'
lab:
    title: 'Lab 4.2 – Investigate with sign-in and audit logs'
    module: 'Day 4 – Governance and monitoring'
---

# Lab 4.2 – Investigate with sign-in and audit logs

**Estimated time:** 30 minutes

> **Draft:** This lab is new and has not been run in this environment yet. If a step behaves differently, tell the trainer.

**Goal:** Answer five questions about the last three days in your tenant from the logs – first in the admin center, then with one Graph call each.

**Why:** Every lab of this course left traces. Reading them back is the skill you need on the first day of a real incident: who did what, which policy decided, which app got which permission. The admin center answers one question at a time; Graph answers it in a form you can save, filter and turn into a report.

Use your admin account. In Graph Explorer consent to `AuditLog.Read.All` once (**Modify permissions**).

### The questions

1. **Which Conditional Access policies blocked or failed a sign-in today?**
   Admin center: **Sign-in logs** → filter **Status: Failure** → tab **Conditional Access** of each entry.
   Graph, method **GET**:

   ```text
   https://graph.microsoft.com/v1.0/auditLogs/signIns?$filter=conditionalAccessStatus eq 'failure' and createdDateTime ge {yyyy-mm-dd}T00:00:00Z&$select=createdDateTime,userPrincipalName,appDisplayName,status,appliedConditionalAccessPolicies&$top=50
   ```

   Replace `{yyyy-mm-dd}` with today's date. In the result, look for `appliedConditionalAccessPolicies` entries with `result` `failure`.

2. **Who used device code flow?**
   Admin center: **Sign-in logs → Add filters → Authentication protocol → Device code**.
   Graph:

   ```text
   https://graph.microsoft.com/beta/auditLogs/signIns?$filter=authenticationProtocol eq 'deviceCode'&$select=createdDateTime,userPrincipalName,appDisplayName,status
   ```

3. **Which apps received admin consent, and from whom?**
   Admin center: **Audit logs → Activity: Consent to application**.
   Graph:

   ```text
   https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?$filter=activityDisplayName eq 'Consent to application'&$select=activityDateTime,initiatedBy,targetResources,result
   ```

4. **Which application permissions are granted in this tenant?** (This is not in a log – it is the current state.)

   ```text
   https://graph.microsoft.com/v1.0/servicePrincipals?$filter=displayName eq 'Employee Sync'&$select=id,appId,displayName
   ```

   Then, with the `id` from that result:

   ```text
   https://graph.microsoft.com/v1.0/servicePrincipals/{id}/appRoleAssignments?$select=resourceDisplayName,appRoleId,createdDateTime
   ```

   The result names the resource (`Employee API`) but only the GUID of the role. Compare `appRoleId` with the `id` of the app role in the manifest of `Employee API` (Lab 3.3).

5. **Who activated a role through PIM, and why?**
   Admin center: **Privileged Identity Management → Microsoft Entra roles → Resource audit**.
   Graph:

   ```text
   https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleRequests?$filter=action eq 'selfActivate'&$select=createdDateTime,principalId,roleDefinitionId,justification,status
   ```

### Checkpoint

- [ ] You found at least one sign-in blocked by a policy you created this week
- [ ] You found the device code sign-ins from Lab 2.2
- [ ] You can name the actor of the admin consent from Lab 3.5 and the justification of the PIM activation from Lab 4.1

**Note:** Sign-in logs are kept for 30 days with P1/P2. For longer retention and for queries across sign-ins and audit events, send the logs to a Log Analytics workspace (**Diagnostic settings**) – Microsoft lab 27 shows the KQL side.

**Why some queries use beta:** `authenticationProtocol` is a filterable property only on the beta sign-in endpoint. Use beta for investigation, v1.0 for anything you automate.
