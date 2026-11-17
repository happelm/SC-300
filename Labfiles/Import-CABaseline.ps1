<#
.SYNOPSIS
    Imports the Conditional Access baseline by Joey Verlinden into a tenant - in report-only
    mode by default.

.DESCRIPTION
    Used in SC-300 Lab 2.5. Source: https://github.com/j0eyv/ConditionalAccessBaseline (MIT
    license, (c) j0eyv). The script downloads the current version of the baseline at runtime,
    so it always imports what Joey published last.

    The exported policies contain object IDs from the author's tenant. The script
      1. creates (or reuses, matched by display name) the exclusion groups and named locations,
      2. replaces every group and named location ID in the policies with the IDs in your tenant,
      3. removes read-only and export-only properties,
      4. creates each policy that does not exist yet (matched by display name), in the state
         given by -State.

    Existing policies with the same name are never changed. The agent policies (CA5xx) need
    Microsoft Agent 365 licensing and are skipped unless -IncludeAgentPolicies is set.

.PARAMETER State
    State of the created policies. Default: enabledForReportingButNotEnforced (report-only).

.PARAMETER AllowedCountries
    ISO country codes for the named location "ALLOWED COUNTRIES" (CA001). Default: AT, DE, CH.

.PARAMETER ServiceAccountCountries
    ISO country codes for "ALLOWED COUNTRIES - SERVICE ACCOUNTS" (CA301). Default: AT.

.PARAMETER BreakGlassUpn
    UPNs of emergency access accounts. They are added to "CA-BreakGlassAccounts - Exclude",
    which every policy of the baseline excludes.

.PARAMETER Include
    Wildcard filter on policy names, e.g. 'CA0*','CA1*'. Default: all.

.PARAMETER SourcePath
    Use a local copy of the baseline's Config folder instead of downloading it.

.PARAMETER ExportPath
    Offline mode: write the transformed policy bodies to this folder and do not connect to a
    tenant. Group and location IDs are replaced by placeholders. Use it to review what would
    be imported.

.EXAMPLE
    PowerShell.exe -ExecutionPolicy Bypass -File .\Import-CABaseline.ps1 -BreakGlassUpn breakglass@contoso.onmicrosoft.com

.EXAMPLE
    # Show what would happen, change nothing
    .\Import-CABaseline.ps1 -WhatIf

.EXAMPLE
    # Only the global and admin policies
    .\Import-CABaseline.ps1 -Include 'CA0*','CA1*'

.NOTES
    Windows PowerShell 5.1 and PowerShell 7. Requires Microsoft.Graph.Authentication.
    Delegated permissions: Policy.ReadWrite.ConditionalAccess, Policy.Read.All,
    Group.ReadWrite.All, Application.ReadWrite.All (only to create the Microsoft Intune
    Enrollment service principal if it is missing). Sign in as Conditional Access
    Administrator plus Groups Administrator, or Global Administrator in a lab.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('enabledForReportingButNotEnforced', 'disabled', 'enabled')]
    [string]$State = 'enabledForReportingButNotEnforced',
    [string[]]$AllowedCountries = @('AT', 'DE', 'CH'),
    [string[]]$ServiceAccountCountries = @('AT'),
    [string[]]$BreakGlassUpn,
    [string[]]$Include = @('*'),
    [switch]$IncludeAgentPolicies,
    [string]$SourcePath,
    [string]$ExportPath
)

$ErrorActionPreference = 'Stop'
# PowerShell.exe -File passes 'CA0*','CA1*' as one string - split it
$Include = @($Include | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$graph = 'https://graph.microsoft.com/beta'
$intuneEnrollmentAppId = 'd4ebce55-015a-49b5-a083-c84d1797ae8c'
$compliantNetworkId = '3d46dbda-8382-466a-856d-eb00cbc6b910'   # well-known ID, same in every tenant
$offline = [bool]$ExportPath

#region Helpers
function ConvertTo-Plain {
    # PSCustomObject from ConvertFrom-Json -> ordered hashtables and arrays (PS 5.1 has no -AsHashtable)
    param($Object)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Management.Automation.PSCustomObject]) {
        $h = [ordered]@{}
        foreach ($p in $Object.PSObject.Properties) { $h[$p.Name] = ConvertTo-Plain $p.Value }
        return $h
    }
    if ($Object -is [System.Collections.IEnumerable] -and $Object -isnot [string]) {
        $list = New-Object System.Collections.ArrayList
        foreach ($i in $Object) { [void]$list.Add((ConvertTo-Plain $i)) }
        return , $list.ToArray()
    }
    return $Object
}

function Remove-ExportNoise {
    # Removes OData annotations, read-only properties and nulls. -KeepType keeps @odata.type
    # on the top level (named locations need it to know their type).
    param($Object, [switch]$KeepType, [int]$Level = 0)
    if ($Object -is [System.Collections.IDictionary]) {
        $h = [ordered]@{}
        foreach ($k in @($Object.Keys)) {
            $v = $Object[$k]
            if ($null -eq $v) { continue }
            if ($k -eq '@odata.type' -and $KeepType -and $Level -eq 0) { $h[$k] = $v; continue }
            if ($k -like '*@odata*' -or $k -like '#*') { continue }
            if ($Level -eq 0 -and $k -in 'id', 'templateId', 'createdDateTime', 'modifiedDateTime', 'deletedDateTime', 'partialEnablementStrategy') { continue }
            $h[$k] = Remove-ExportNoise -Object $v -Level ($Level + 1)
        }
        return $h
    }
    if ($Object -is [array]) {
        return , @($Object | ForEach-Object { Remove-ExportNoise -Object $_ -Level ($Level + 1) })
    }
    return $Object
}

function Read-ExportFile {
    param([string]$Path)
    # ReadAllText detects the BOM - the baseline mixes UTF-16 and UTF-8 files
    ConvertTo-Plain ([IO.File]::ReadAllText($Path) | ConvertFrom-Json)
}

function Find-ByName {
    param([string]$Collection, [string]$Name)
    $filter = [uri]::EscapeDataString("displayName eq '$($Name.Replace("'", "''"))'")
    $r = Invoke-MgGraphRequest -Method GET -Uri "$graph/$Collection`?`$filter=$filter"
    @($r.value)
}

function Write-Step { param([string]$Text) Write-Host "`n== $Text" -ForegroundColor Cyan }
#endregion

#region Source
Write-Step 'Baseline source'
if (-not $SourcePath) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $work = Join-Path ([IO.Path]::GetTempPath()) ("cabaseline-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $work | Out-Null
    $zip = Join-Path $work 'baseline.zip'
    Invoke-WebRequest -Uri 'https://github.com/j0eyv/ConditionalAccessBaseline/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $work
    $SourcePath = Join-Path (Get-ChildItem $work -Directory | Select-Object -First 1).FullName 'Config'
}
Write-Host "Using $SourcePath"

$migration = Read-ExportFile (Join-Path $SourcePath 'MigrationTable.json')
$sourceGroups = @{}
foreach ($o in $migration.Objects) { if ($o.Type -eq 'Group') { $sourceGroups[$o.Id] = $o.DisplayName } }

$sourceLocations = @{}
foreach ($f in Get-ChildItem (Join-Path $SourcePath 'NamedLocations') -Filter *.json) {
    $loc = Read-ExportFile $f.FullName
    $sourceLocations[$loc.id] = $loc
}

$policies = foreach ($f in Get-ChildItem (Join-Path $SourcePath 'ConditionalAccess') -Filter *.json | Sort-Object Name) {
    $p = Read-ExportFile $f.FullName
    $name = $p.displayName
    if (-not ($Include | Where-Object { $name -like $_ })) { continue }
    if ($name -like 'CA5*' -and -not $IncludeAgentPolicies) { Write-Host "Skip (agent policy): $name" -ForegroundColor DarkGray; continue }
    $p
}
Write-Host "$(@($policies).Count) policies selected"
#endregion

#region Tenant preparation
$groupMap = @{}
$locationMap = @{ 'All' = 'All'; 'AllTrusted' = 'AllTrusted'; $compliantNetworkId = $compliantNetworkId }

if ($offline) {
    foreach ($id in $sourceGroups.Keys) { $groupMap[$id] = "<group: $($sourceGroups[$id])>" }
    foreach ($id in $sourceLocations.Keys) { if (-not $locationMap.ContainsKey($id)) { $locationMap[$id] = "<location: $($sourceLocations[$id].displayName)>" } }
}
else {
    if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
    }
    Connect-MgGraph -NoWelcome -Scopes 'Policy.ReadWrite.ConditionalAccess', 'Policy.Read.All', 'Group.ReadWrite.All', 'Application.ReadWrite.All'

    Write-Step 'Prerequisites'
    $sd = Invoke-MgGraphRequest -Method GET -Uri "$graph/policies/identitySecurityDefaultsEnforcementPolicy"
    if ($sd.isEnabled) { throw 'Security defaults are enabled. Turn them off before importing Conditional Access policies.' }
    Write-Host 'Security defaults: off'

    $policyJson = ($policies | ConvertTo-Json -Depth 20 -Compress)
    if ($policyJson -match $intuneEnrollmentAppId) {
        $sp = Invoke-MgGraphRequest -Method GET -Uri "$graph/servicePrincipals?`$filter=appId eq '$intuneEnrollmentAppId'"
        if (-not $sp.value) {
            if ($PSCmdlet.ShouldProcess('Microsoft Intune Enrollment', 'Create service principal')) {
                Invoke-MgGraphRequest -Method POST -Uri "$graph/servicePrincipals" -Body @{ appId = $intuneEnrollmentAppId } | Out-Null
                Write-Host 'Created service principal Microsoft Intune Enrollment'
            }
        }
        else { Write-Host 'Microsoft Intune Enrollment service principal exists' }
    }

    Write-Step 'Named locations'
    foreach ($id in $sourceLocations.Keys) {
        if ($locationMap.ContainsKey($id)) { continue }
        if ($policyJson -notmatch $id) { continue }
        $loc = Remove-ExportNoise -Object $sourceLocations[$id] -KeepType
        switch ($loc.displayName) {
            'ALLOWED COUNTRIES'                   { $loc.countriesAndRegions = $AllowedCountries }
            'ALLOWED COUNTRIES - SERVICE ACCOUNTS' { $loc.countriesAndRegions = $ServiceAccountCountries }
        }
        $existing = Find-ByName -Collection 'identity/conditionalAccess/namedLocations' -Name $loc.displayName
        if ($existing) {
            $locationMap[$id] = $existing[0].id
            Write-Host "Reuse   $($loc.displayName)"
        }
        elseif ($PSCmdlet.ShouldProcess($loc.displayName, 'Create named location')) {
            $new = Invoke-MgGraphRequest -Method POST -Uri "$graph/identity/conditionalAccess/namedLocations" -Body ($loc | ConvertTo-Json -Depth 10) -ContentType 'application/json'
            $locationMap[$id] = $new.id
            Write-Host "Created $($loc.displayName) ($($loc.countriesAndRegions -join ', '))" -ForegroundColor Green
        }
        else { $locationMap[$id] = "<new location: $($loc.displayName)>" }
    }

    Write-Step 'Exclusion groups'
    foreach ($id in $sourceGroups.Keys) {
        if ($policyJson -notmatch $id) { continue }
        $name = $sourceGroups[$id]
        $existing = Find-ByName -Collection 'groups' -Name $name
        if ($existing) {
            $groupMap[$id] = $existing[0].id
            Write-Host "Reuse   $name"
        }
        elseif ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
            $nick = ($name -replace '[^a-zA-Z0-9]', '')
            if ($nick.Length -gt 50) { $nick = $nick.Substring(0, 50) }
            $body = @{
                displayName     = $name
                description     = 'Conditional Access baseline (j0eyv) - exclusion group'
                mailEnabled     = $false
                mailNickname    = $nick + (Get-Random -Maximum 9999)
                securityEnabled = $true
            }
            $new = Invoke-MgGraphRequest -Method POST -Uri "$graph/groups" -Body $body
            $groupMap[$id] = $new.id
            Write-Host "Created $name" -ForegroundColor Green
        }
        else { $groupMap[$id] = "<new group: $name>" }
    }

    if ($BreakGlassUpn) {
        $bgId = ($sourceGroups.GetEnumerator() | Where-Object Value -eq 'CA-BreakGlassAccounts - Exclude').Key
        $bgGroup = $groupMap[$bgId]
        foreach ($upn in $BreakGlassUpn) {
            if ($bgGroup -like '<*') { Write-Host "What if: add $upn to CA-BreakGlassAccounts - Exclude"; continue }
            $user = Invoke-MgGraphRequest -Method GET -Uri "$graph/users/$([uri]::EscapeDataString($upn))?`$select=id"
            $members = Invoke-MgGraphRequest -Method GET -Uri "$graph/groups/$bgGroup/members?`$select=id"
            if ($members.value.id -contains $user.id) { Write-Host "Break-glass $upn already excluded"; continue }
            if ($PSCmdlet.ShouldProcess($upn, 'Add to CA-BreakGlassAccounts - Exclude')) {
                Invoke-MgGraphRequest -Method POST -Uri "$graph/groups/$bgGroup/members/`$ref" -Body @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | Out-Null
                Write-Host "Break-glass $upn added to the exclusion group" -ForegroundColor Green
            }
        }
    }
    else {
        Write-Warning 'No -BreakGlassUpn given. Add your emergency access accounts to "CA-BreakGlassAccounts - Exclude" before you enable any policy.'
    }
}
#endregion

#region Policies
Write-Step "Policies (state: $State)"
if ($offline) { New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null }
$result = foreach ($p in $policies) {
    $body = Remove-ExportNoise -Object $p
    $body.state = $State

    $users = $body.conditions.users
    if ($users) {
        foreach ($k in 'includeGroups', 'excludeGroups') {
            if ($users[$k]) {
                $users[$k] = @($users[$k] | ForEach-Object {
                    if ($groupMap.ContainsKey($_)) { $groupMap[$_] } else { throw "$($body.displayName): unknown group $_" }
                })
            }
        }
    }
    $loc = $body.conditions.locations
    if ($loc) {
        foreach ($k in 'includeLocations', 'excludeLocations') {
            if ($loc[$k]) {
                $loc[$k] = @($loc[$k] | ForEach-Object {
                    if ($locationMap.ContainsKey($_)) { $locationMap[$_] } else { throw "$($body.displayName): unknown named location $_" }
                })
            }
        }
    }

    $json = $body | ConvertTo-Json -Depth 20
    if ($offline) {
        $json | Set-Content -Path (Join-Path $ExportPath "$($body.displayName).json") -Encoding UTF8
        [pscustomobject]@{ Policy = $body.displayName; Result = 'Exported' }
        continue
    }

    if (Find-ByName -Collection 'identity/conditionalAccess/policies' -Name $body.displayName) {
        [pscustomobject]@{ Policy = $body.displayName; Result = 'Exists - not changed' }
        continue
    }
    if ($PSCmdlet.ShouldProcess($body.displayName, "Create policy ($State)")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "$graph/identity/conditionalAccess/policies" -Body $json -ContentType 'application/json' | Out-Null
            [pscustomobject]@{ Policy = $body.displayName; Result = 'Created' }
        }
        catch {
            [pscustomobject]@{ Policy = $body.displayName; Result = "FAILED: $($_.Exception.Message)" }
        }
    }
    else { [pscustomobject]@{ Policy = $body.displayName; Result = "What if: create ($State)" } }
}
$result | Format-Table -AutoSize | Out-String -Width 220 | Write-Host
#endregion

if (-not $offline) {
    Write-Host "Check the policies in Entra ID -> Conditional Access -> Policies. Report-only results appear in the sign-in logs (tab 'Report-only')." -ForegroundColor Yellow
}
