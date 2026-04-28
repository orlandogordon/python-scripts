# Azure Resource Graph Query — Incremental Build Progression

A step-by-step progression for building and validating the policy-state enrichment query against Azure Resource Graph (ARG). Each step is independently runnable; if something breaks you'll know exactly which addition caused it.

## How to run

Use the Azure CLI:

```bash
az graph query -q "<paste query here>"
```

Replace `<MG_ID>` with your actual management group ID. Keep `| take 20` (or similar) near the top while iterating to keep result sets small and feedback fast.

---

## Step 1 — Baseline: just policy states, parsed

Confirms the base table works, the scope filter is correct, and `extract()` parses what you expect.

```kusto
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| take 20
| extend rid = tolower(tostring(properties.resourceId))
| project
    rid,
    subIdFromRid = tostring(extract(@'/subscriptions/([^/]+)', 1, rid)),
    rgFromRid    = tostring(extract(@'/resourcegroups/([^/]+)', 1, rid)),
    complianceState = tostring(properties.complianceState)
```

**What to verify:** rows come back, `subIdFromRid` is populated for most, `rgFromRid` is populated for resource-and-RG-scoped rows. If subscription-scoped or MG-scoped rows show empty `rgFromRid`, that's expected.

---

## Step 2 — Add full projection (still no joins)

Just expanding the project list. If this breaks, it's a column-name or type issue, not a join issue.

```kusto
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| take 20
| extend rid = tolower(tostring(properties.resourceId))
| project
    policyDefinitionId = tolower(tostring(properties.policyDefinitionId)),
    assignmentId = tostring(properties.policyAssignmentId),
    referenceId = tolower(tostring(properties.policyDefinitionReferenceId)),
    policyDefinitionAction = properties.policyDefinitionAction,
    policyAssignmentScope = tostring(properties.policyAssignmentScope),
    policySetDefinitionCategory = tostring(properties.policySetDefinitionCategory),
    complianceState = tostring(properties.complianceState),
    resourceId = rid,
    subIdFromRid = tostring(extract(@'/subscriptions/([^/]+)', 1, rid)),
    rgFromRid    = tostring(extract(@'/resourcegroups/([^/]+)', 1, rid)),
    isDeleted = properties.isDeleted,
    policy_assessment_timestamp = properties.timestamp
```

---

## Step 3 — Join to `resources` only (no union yet)

The simplest possible join. If it fails, the issue is the join syntax itself, not the union.

```kusto
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| take 20
| extend resourceId = tolower(tostring(properties.resourceId))
| project resourceId, complianceState = tostring(properties.complianceState)
| join kind=leftouter (
    resources
    | project
        resourceId = tolower(tostring(id)),
        name,
        type,
        resourceGroup,
        subscriptionId,
        location,
        tags
) on resourceId
| project-away resourceId1
```

**What to verify:** rows return, joined fields (`name`, `type`, etc.) are populated for resource-scoped policy states, null for RG/sub/MG-scoped ones. This confirms the original symptom in isolation.

---

## Step 4 — Standalone `resourcecontainers` query (sanity check)

Before unioning, verify `resourcecontainers` returns what you think it does. Run this on its own:

```kusto
resourcecontainers
| where type in (
    'microsoft.resources/subscriptions',
    'microsoft.resources/subscriptions/resourcegroups',
    'microsoft.management/managementgroups'
)
| take 20
| project id, name, type, resourceGroup, subscriptionId, tags
```

**What to verify:** all three types appear, `tags` exists (may be null for some), `resourceGroup` is populated for RG rows.

---

## Step 5 — Union the two tables, no join yet

Confirm the union itself is valid before putting it on the right side of a join. Column types and counts must match exactly.

```kusto
resources
| project
    resourceId = tolower(tostring(id)),
    name,
    type = tostring(type),
    resourceGroup = tostring(resourceGroup),
    subscriptionId = tostring(subscriptionId),
    location = tostring(location),
    tags
| union (
    resourcecontainers
    | where type in (
        'microsoft.resources/subscriptions',
        'microsoft.resources/subscriptions/resourcegroups',
        'microsoft.management/managementgroups'
    )
    | project
        resourceId = tolower(tostring(id)),
        name,
        type = tostring(type),
        resourceGroup = tostring(resourceGroup),
        subscriptionId = tostring(subscriptionId),
        location = '',
        tags
)
| take 20
```

**What to verify:** rows from both tables appear, no type-mismatch errors. If this fails, it's almost certainly a column-type mismatch — `tostring()` everything aggressively to fix.

---

## Step 6 — Put the union on the right side of the join

The moment of truth. ARG sometimes rejects complex right-hand-sides; if it does, this step will tell you.

```kusto
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| take 20
| extend resourceId = tolower(tostring(properties.resourceId))
| project resourceId, complianceState = tostring(properties.complianceState)
| join kind=leftouter (
    resources
    | project
        resourceId = tolower(tostring(id)),
        name,
        type = tostring(type),
        resourceGroup = tostring(resourceGroup),
        subscriptionId = tostring(subscriptionId),
        location = tostring(location),
        tags
    | union (
        resourcecontainers
        | where type in (
            'microsoft.resources/subscriptions',
            'microsoft.resources/subscriptions/resourcegroups',
            'microsoft.management/managementgroups'
        )
        | project
            resourceId = tolower(tostring(id)),
            name,
            type = tostring(type),
            resourceGroup = tostring(resourceGroup),
            subscriptionId = tostring(subscriptionId),
            location = '',
            tags
    )
) on resourceId
| project-away resourceId1
```

**What to verify:** rows return, RG-scoped and sub-scoped policy states now have non-null `name` and `type`. If this step fails with "invalid query" but Step 5 worked, the issue is specifically the union-on-right-side-of-join pattern, and you'll need Path B.

---

## Step 7 — Test the 1000-row join cap

Before adding everything else, run Step 6 *without* `| take 20` near the top and instead with `| take 5000` to see how many rows actually come back. If ARG truncates, you'll see it here. Also useful: check whether the right-side union is what's getting truncated.

```kusto
// Count what the right side would produce
resources
| project resourceId = tolower(tostring(id))
| union (
    resourcecontainers
    | where type in (
        'microsoft.resources/subscriptions',
        'microsoft.resources/subscriptions/resourcegroups',
        'microsoft.management/managementgroups'
    )
    | project resourceId = tolower(tostring(id))
)
| count
```

**What to verify:** if this count is over ~1000, the join in Step 6 is being silently truncated and you'll get nulls in production even though the small `take 20` test looked fine. This is the failure mode most likely to bite.

If you hit it, the workaround is `join hint.remote=left` or `join hint.strategy=shuffle` — but ARG support for hints is spottier than ADX. This is the point to seriously reconsider Path B (split into multiple queries and merge in Python).

---

## Step 8 — Full projection and tag extraction

If Steps 6 and 7 both pass, plug in the full field list and the mnemonic/environment extraction:

```kusto
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| extend rid = tolower(tostring(properties.resourceId))
| project
    policyDefinitionId = tolower(tostring(properties.policyDefinitionId)),
    assignmentId = tostring(properties.policyAssignmentId),
    referenceId = tolower(tostring(properties.policyDefinitionReferenceId)),
    policyDefinitionAction = properties.policyDefinitionAction,
    policyAssignmentScope = tostring(properties.policyAssignmentScope),
    policySetDefinitionCategory = tostring(properties.policySetDefinitionCategory),
    complianceState = tostring(properties.complianceState),
    resourceId = rid,
    subIdFromRid = tostring(extract(@'/subscriptions/([^/]+)', 1, rid)),
    rgFromRid    = tostring(extract(@'/resourcegroups/([^/]+)', 1, rid)),
    isDeleted = properties.isDeleted,
    policy_assessment_timestamp = properties.timestamp
| join kind=leftouter (
    resources
    | project
        resourceId = tolower(tostring(id)),
        resName = name,
        resType = tostring(type),
        resGroup = tostring(resourceGroup),
        subId = tostring(subscriptionId),
        location = tostring(location),
        tags
    | union (
        resourcecontainers
        | where type in (
            'microsoft.resources/subscriptions',
            'microsoft.resources/subscriptions/resourcegroups',
            'microsoft.management/managementgroups'
        )
        | project
            resourceId = tolower(tostring(id)),
            resName = name,
            resType = tostring(type),
            resGroup = tostring(resourceGroup),
            subId = tostring(subscriptionId),
            location = '',
            tags
    )
) on resourceId
| extend
    name           = coalesce(resName, ''),
    type           = coalesce(resType, ''),
    resourceGroup  = coalesce(resGroup, rgFromRid, ''),
    subscriptionId = coalesce(subId, subIdFromRid, ''),
    mnemonic       = tostring(coalesce(tags['mnemonic'],    tags['Mnemonic'])),
    environment    = tostring(coalesce(tags['environment'], tags['Environment'], tags['env'], tags['Env']))
| project-away resourceId1, resName, resType, resGroup, subId, rid
| order by assignmentId asc, referenceId asc
```

## Step 8a — Full projection and tag extraction

If Steps 6 and 7 both pass, plug in the full field list and the mnemonic/environment extraction:

```kusto
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| take 20
| extend rid = tolower(tostring(properties.resourceId))
| project
    policyDefinitionId = tolower(tostring(properties.policyDefinitionId)),
    assignmentId = tostring(properties.policyAssignmentId),
    referenceId = tolower(tostring(properties.policyDefinitionReferenceId)),
    complianceState = tostring(properties.complianceState),
    resourceId = rid,
    subIdFromRid = tostring(extract(@'/subscriptions/([^/]+)', 1, rid)),
    rgFromRid    = tostring(extract(@'/resourcegroups/([^/]+)', 1, rid))
| join kind=leftouter (
    resources
    | project
        resourceId = tolower(tostring(id)),
        resName = name,
        resType = tostring(type),
        resGroup = tostring(resourceGroup),
        subId = tostring(subscriptionId),
        tags
    | union (
        resourcecontainers
        | where type in (
            'microsoft.resources/subscriptions',
            'microsoft.resources/subscriptions/resourcegroups',
            'microsoft.management/managementgroups'
        )
        | project
            resourceId = tolower(tostring(id)),
            resName = name,
            resType = tostring(type),
            resGroup = tostring(resourceGroup),
            subId = tostring(subscriptionId),
            tags
    )
) on resourceId
| project-away resourceId1
```

## 8b
// ...same as 8a above, but add at the end before project-away:
| extend
    name           = coalesce(resName, ''),
    type           = coalesce(resType, ''),
    resourceGroup  = coalesce(resGroup, rgFromRid, ''),
    subscriptionId = coalesce(subId, subIdFromRid, ''),
    mnemonic       = tostring(coalesce(tostring(tags.mnemonic), tostring(tags.Mnemonic))),
    environment    = tostring(coalesce(tostring(tags.environment), tostring(tags.Environment), tostring(tags.env), tostring(tags.Env)))
| project-away resourceId1, resName, resType, resGroup, subId, rid

---

## Decision points along the way

| If this step fails | What it means | Next move |
|---|---|---|
| Step 3 | Join syntax problem | Fix join syntax before continuing |
| Step 5 | Column type mismatch in union | Add `tostring()` more aggressively |
| Step 6 (but Step 5 passed) | ARG rejects union-on-right-of-join | Switch to Path B; this shape won't work |
| Step 7 shows >1000 rows | Silent truncation will bite in production | Try `join hint` or switch to Path B |
| Steps 1–7 all pass | Query shape is valid | Step 8 should work |

---

## Path B fallback (if anything in Steps 6–7 fails)

Split into separate ARG queries and merge in Python:

1. **Query 1:** policy states with `extract()` to parse `subscriptionId` and `resourceGroup` from the resourceId. No joins.
2. **Query 2:** flat lookup of `resources` projecting `id, name, type, tags`.
3. **Query 3 (optional):** subscription name map from `resourcecontainers` filtered to `microsoft.resources/subscriptions`.
4. Merge in pandas using the resourceId as the key.

This sidesteps every ARG limitation (table reference cap, 1000-row join cap, union-on-right-of-join restrictions) and makes each query independently cacheable.
