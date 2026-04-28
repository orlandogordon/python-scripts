
def get_query(query_managed_id):
    return f"""
    policyresources
    | where type == 'microsoft.policyinsights/policystates'
    | where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/{query_managed_id}
    | project policyDefinitionId = tolower(tostring(properties.policyDefinitionId)),
        assignmentId = (tostring(properties.policyAssignmentId)),
        referenceId = tolower(tostring(properties.policyDefinitionReferenceId)),
        policyDefinitionAction = properties.PolicyDefinitionAction,
        policyAssignmentScope = properties.policyAssignmentScope,
        policySetDefinitionCategory = properties.policySetDefinitionCategory,
        complianceState = properties.complianceState,
        resourceId = tolower(toString(properties.resourceId)),
        isDeleted = properties.isDeleted,
        policy_assessment_timestamp = properties.timestamp
        | join kind=leftouter (
            resources
            | extend resourceId = tolower(tostring(id))
            | join kind = inner (
                resourcecontainers
                | where type == 'microsoft.resources/subscriptions'
                | project subsciptionId, subscriptionName = name
            ) in subscriptionId
            | project resourceId = tostring(tolower(resourceId)),
            subscriptionId,
            subscriptionName,
            resourceGroup,
            name,
            type,
            tags,
            location
        ) on resourceId
        | project-away resourceId1
        | order by assignmentId, referenceId asc
    """



def get_query(query_managed_id):
    return f"""
    policyresources
    | where type == 'microsoft.policyinsights/policystates'
    | where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/{query_managed_id}'
    | project
        policyDefinitionId = tolower(tostring(properties.policyDefinitionId)),
        assignmentId = tostring(properties.policyAssignmentId),
        referenceId = tolower(tostring(properties.policyDefinitionReferenceId)),
        policyDefinitionAction = properties.policyDefinitionAction,
        policyAssignmentScope = tostring(properties.policyAssignmentScope),
        policySetDefinitionCategory = tostring(properties.policySetDefinitionCategory),
        complianceState = tostring(properties.complianceState),
        resourceId = tolower(tostring(properties.resourceId)),
        isDeleted = properties.isDeleted,
        policy_assessment_timestamp = properties.timestamp
    | join kind=leftouter (
        // Build a unified lookup that covers ARM resources, RGs, subs, and mgmt groups
        resources
        | project
            resourceId = tolower(tostring(id)),
            name,
            type,
            resourceGroup,
            subscriptionId,
            location,
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
                type,
                resourceGroup = tostring(resourceGroup),
                subscriptionId,
                location,
                tags
        )
        // Attach subscription name to everything in one shot
        | join kind=leftouter (
            resourcecontainers
            | where type == 'microsoft.resources/subscriptions'
            | project subscriptionId, subscriptionName = name
        ) on subscriptionId
        | project-away subscriptionId1
    ) on resourceId
    | extend
        mnemonic   = tostring(coalesce(tags['mnemonic'],   tags['Mnemonic'])),
        environment = tostring(coalesce(tags['environment'], tags['Environment'], tags['env'], tags['Env']))
    | project-away resourceId1
    | order by assignmentId asc, referenceId asc
    """







def get_query(query_managed_id):
    """
    Returns an Azure Resource Graph query that joins policy state rows
    against both the resources and resourcecontainers tables, so that
    policy assignments scoped to resources, resource groups, subscriptions,
    and management groups all get enriched with name/type/RG/subscription.

    Resource group and subscription ID are also parsed directly from the
    policy state's resourceId as a fallback, so they are populated even
    when the join misses.
    """
    return """
    policyresources
    | where type == 'microsoft.policyinsights/policystates'
    | where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/""" + query_managed_id + """'
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
    | extend
        name           = coalesce(resName, ''),
        type           = coalesce(resType, ''),
        resourceGroup  = coalesce(resGroup, rgFromRid, ''),
        subscriptionId = coalesce(subId, subIdFromRid, '')
    | project-away resourceId1, resName, resType, resGroup, subId, rid
    | order by assignmentId asc, referenceId asc
    """