
HEADERS = [
    "Rsource Name",
    "Resource ID",
    "Resource Type",
    "Subscription ID",
    "Subscription Name",
    "Resource Group",
    "Policy Definition ID",
    "Compliant",
    "Resource Tags",
    "Resource Deleted",
    "Resource Location",
    "Policy Assignment Scope",
    "Policy Set Definition Category",
    "Policy Definition Action",
    "Policy Assessment Timestamp",
    "Reference ID",
    "Assignment ID",
]

FIELD_NAMES = [
    "name",
    "resourceId",
    "type",
    "subscriptionId",
    "subscriptionName",
    "resourceGroup",
    "policyDefinitionId",
    "complianceState",
    "tags",
    "isDeleted",
    "location",
    "policyAssignmentScope",
    "policySetDefinitionCategory",
    "policyDefinitionAction",
    "policy_assessment_timestamp",
    "referenceId",
    "assignmentId",
]

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
            resLocation = tostring(location),
            resTags = tags
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
                resLocation = '',
                resTags = tags
        )
    ) on resourceId
    | extend
        name           = coalesce(resName, ''),
        type           = coalesce(resType, ''),
        resourceGroup  = coalesce(resGroup, rgFromRid, ''),
        subscriptionId = coalesce(subId, subIdFromRid, ''),
        location       = coalesce(resLocation, ''),
        tags           = resTags,
        subscriptionName = ''
    | project-away resourceId1, resName, resType, resGroup, subId, rid, resLocation, resTags
    | order by assignmentId asc, referenceId asc
    """

def get_subscription_name_map():
    """Fetch all subscriptions visible to the caller and return {id: name}."""
    body = {
        "query": "resourcecontainers | where type == 'microsoft.resources/subscriptions' | project subscriptionId, name"
    }
    response = requests.post(ARG_URL, headers=headers, data=json.dumps(body))
    rows = response.json().get("data", [])
    return {row["subscriptionId"]: row["name"] for row in rows}

# Then when processing your main query results:
sub_map = get_subscription_name_map()
for row in policy_state_rows:
    row["subscriptionName"] = sub_map.get(row.get("subscriptionId"), "")


# Diagnostic Query:
policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/<MG_ID>'
| extend rid = tolower(tostring(properties.resourceId))
| extend extractedType = tolower(tostring(extract(@'/providers/([^/]+/[^/]+)/[^/]+/?$', 1, rid)))
| summarize count() by extractedType
| order by count_ desc
| take 30





## For standard query:
def get_query(query_managed_id):
    return f"""
    policyresources
    | where type == 'microsoft.policyinsights/policystates'
    | where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/{query_managed_id}'
    | extend resourceId               = tolower(tostring(properties.resourceId)),
             subscriptionId           = tolower(tostring(properties.subscriptionId)),
             resourceGroupFromState   = tolower(tostring(properties.resourceGroup)),
             resourceTypeFromState    = tostring(properties.resourceType),
             locationFromState        = tostring(properties.resourceLocation)
    // Derive name from the resource ID — last segment. Works for top-level AND child resources.
    | extend nameFromId = tostring(split(resourceId, '/')[-1])
    // Best-effort enrichment from the resources table (tags + authoritative type/location/RG/name
    // for top-level resources). leftouter so child/deleted/sub-scope rows still come through.
    | join kind=leftouter (
        resources
        | project resJoinId    = tolower(id),
                  resName      = name,
                  resType      = type,
                  resLocation  = location,
                  resGroup     = tolower(resourceGroup),
                  resTags      = tags
      ) on $left.resourceId == $right.resJoinId
    // Subscription name from resourcecontainers
    | join kind=leftouter (
        resourcecontainers
        | where type == 'microsoft.resources/subscriptions'
        | project subJoinId = tolower(subscriptionId),
                  subscriptionName = name
      ) on $left.subscriptionId == $right.subJoinId
    | project
        // Coalesce: prefer the live resources-table value, fall back to the state record / derived name
        name                          = coalesce(resName, nameFromId),
        resourceId                    = resourceId,
        type                          = coalesce(resType, resourceTypeFromState),
        subscriptionId                = subscriptionId,
        subscriptionName              = subscriptionName,
        resourceGroup                 = coalesce(resGroup, resourceGroupFromState),
        location                      = coalesce(resLocation, locationFromState),
        tags                          = resTags,                       // null when not in resources table
        policyDefinitionId            = tolower(tostring(properties.policyDefinitionId)),
        complianceState               = tostring(properties.complianceState),
        isDeleted                     = tobool(properties.isDeleted),
        policyAssignmentScope         = tostring(properties.policyAssignmentScope),
        policySetDefinitionCategory   = tostring(properties.policySetDefinitionCategory),
        policyDefinitionAction        = tostring(properties.policyDefinitionAction),
        policy_assessment_timestamp   = todatetime(properties.timestamp),
        referenceId                   = tolower(tostring(properties.policyDefinitionReferenceId)),
        assignmentId                  = tostring(properties.policyAssignmentId)
    """




## Tags unpacking
def get_query(query_managed_id):
    return f"""
    policyresources
    | where type == 'microsoft.policyinsights/policystates'
    | where tostring(properties.policyAssignmentScope) == '/providers/Microsoft.Management/managementGroups/{query_managed_id}'
    | extend resourceId               = tolower(tostring(properties.resourceId)),
             subscriptionId           = tolower(tostring(properties.subscriptionId)),
             resourceGroupFromState   = tolower(tostring(properties.resourceGroup)),
             resourceTypeFromState    = tostring(properties.resourceType),
             locationFromState        = tostring(properties.resourceLocation)
    | extend nameFromId = tostring(split(resourceId, '/')[-1])
    | join kind=leftouter (
        resources
        | extend mnemonic = tostring(coalesce(
                                tags['mnemonic'],
                                tags['Mnemonic'],
                                tags['MNEMONIC'])),
                 environment = tostring(coalesce(
                                tags['environment'],
                                tags['Environment'],
                                tags['ENVIRONMENT'],
                                tags['env'],
                                tags['Env']))
        | project resJoinId    = tolower(id),
                  resName      = name,
                  resType      = type,
                  resLocation  = location,
                  resGroup     = tolower(resourceGroup),
                  resTags      = tags,
                  mnemonic,
                  environment
      ) on $left.resourceId == $right.resJoinId
    | join kind=leftouter (
        resourcecontainers
        | where type == 'microsoft.resources/subscriptions'
        | project subJoinId = tolower(subscriptionId),
                  subscriptionName = name
      ) on $left.subscriptionId == $right.subJoinId
    | project
        name                          = coalesce(resName, nameFromId),
        resourceId                    = resourceId,
        type                          = coalesce(resType, resourceTypeFromState),
        subscriptionId                = subscriptionId,
        subscriptionName              = subscriptionName,
        resourceGroup                 = coalesce(resGroup, resourceGroupFromState),
        location                      = coalesce(resLocation, locationFromState),
        tags                          = resTags,
        mnemonic                      = mnemonic,
        environment                   = environment,
        policyDefinitionId            = tolower(tostring(properties.policyDefinitionId)),
        complianceState               = tostring(properties.complianceState),
        isDeleted                     = tobool(properties.isDeleted),
        policyAssignmentScope         = tostring(properties.policyAssignmentScope),
        policySetDefinitionCategory   = tostring(properties.policySetDefinitionCategory),
        policyDefinitionAction        = tostring(properties.policyDefinitionAction),
        policy_assessment_timestamp   = todatetime(properties.timestamp),
        referenceId                   = tolower(tostring(properties.policyDefinitionReferenceId)),
        assignmentId                  = tostring(properties.policyAssignmentId)
    """