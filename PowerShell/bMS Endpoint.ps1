# Copyright (c) 2018 baramundi software AG - https://www.baramundi.com

using module ".\bMS Sensor.psm1"
param (
    [Parameter(Mandatory=$true)]
    [string]$fqdn
)
try {
    # Get bConnect context
    $ctx = Get-bConnectContext
    # Get endpoint
    $hostName = $fqdn
    $domainName = $null
    $indexOfFirstDot = $fqdn.IndexOf(".")
    if ($indexOfFirstDot -ge 0) {
        $hostName = $fqdn.Substring(0, $indexOfFirstDot)
        $domainName = $fqdn.Substring($indexOfFirstDot + 1)
    }
    [Array]$allEndpoints = [Array](Invoke-bConnect $ctx "endpoints") | Where-Object { $_.Type -ne 16 }
    [Array]$endpoints = $allEndpoints | Where-Object { ($_.HostName -eq $hostName) -And ((-Not $domain) -Or ($_.Domain -eq $domainName)) } | Select-Object -First 1
    if ((-not $endpoints) -or ($endpoints.Count -eq 0)) {
        # Search by display name
        $endpoints = $allEndpoints | Where-Object { $_.DisplayName -eq $fqdn } | Select-Object -First 1
        # If not found, throw exception
        if ((-not $endpoints) -or ($endpoints.Count -eq 0)) {
            throw "Unable to find endpoint named $fqdn ($hostName, $domainName)"
        }
    }
    $endpoint = $endpoints[0]
    $channels = @()
    $winAndMac = @(1, 4)
    # LastSeen
    $lastSeenValue = -1
    if ($endpoint.LastSeen) {
        $lastSeenValue = [DateTime]::Now.Subtract([DateTime]($endpoint.LastSeen)).TotalHours
    }
    $lastSeen = Get-PrtgChannel "Last seen in hours" "TimeHours" $lastSeenValue 
    $lastSeen.LimitMinWarning = 0
    $lastSeen.LimitMaxWarning = 4
    $lastSeen.LimitMaxError = 8
    $lastSeen.LimitMode = 1
    $channels += $lastSeen
    # Management State
    $managementStateValue = $endpoint.ManagementState
    if ($winAndMac -contains $endpoint.Type) {
        $managementStateValue = -1
    }
    $managementState = Get-PrtgChannel "Management state" "Custom" $managementStateValue
    $managementState.ValueLookup = "oid.baramundi.managementstate"
    $channels += $managementState
    # Compliance State
    $complianceStateValue = $endpoint.ComplianceState
    if ($winAndMac -contains $endpoint.Type) {
        $complianceStateValue = -1
    }
    $complianceState = Get-PrtgChannel "Compliance state" "Custom" $complianceStateValue
    $complianceState.ValueLookup = "oid.baramundi.compliancestate"
    $channels += $complianceState
     # Get job instances
     [Array]$instances = Invoke-bConnect $ctx "jobinstances" -Query @{ "EndpointId" = $endpoint.Id }
     # Total instances
     $channels += Get-PrtgChannel "Job Instances: Total" "Count" $instances.Count
     # Finished error instances
     $finishedError = Get-PrtgChannel "Job Instances: Finished error" "Count" ($instances | Where-Object { $_.BmsNetState -eq 3 } | Measure-Object | Select-Object -ExpandProperty Count)
     $finishedError.LimitMaxError = 0
     $finishedError.LimitMode = 1
     $channels += $finishedError
     # Finished cancelled instances
     $finishedCancelled = Get-PrtgChannel "Job Instances: Finished cancelled" "Count" ($instances | Where-Object { $_.BmsNetState -eq 4 } | Measure-Object | Select-Object -ExpandProperty Count)
     $finishedCancelled.LimitMaxWarning = 0
     $finishedCancelled.LimitMode = 1
     $channels += $finishedCancelled
     # Waiting for user instances
     $channels += Get-PrtgChannel "Job Instances: Waiting for user" "Count" ($instances | Where-Object { $_.BmsNetState -eq 7 } | Measure-Object | Select-Object -ExpandProperty Count)
     # Waiting for user instances
     $channels += Get-PrtgChannel "Job Instances: Waiting for user (non-blocking)" "Count" ($instances | Where-Object { $_.BmsNetState -eq 11 } | Measure-Object | Select-Object -ExpandProperty Count)
     # Requirements not met instances
     $channels += Get-PrtgChannel "Job Instances: Requirements not met" "Count" ($instances | Where-Object { $_.BmsNetState -eq 8 } | Measure-Object | Select-Object -ExpandProperty Count)
     # Skipped due to incompatibility instances
     $channels += Get-PrtgChannel "Job Instances: Skipped due to incompatibility" "Count" ($instances | Where-Object { $_.BmsNetState -eq 10 } | Measure-Object | Select-Object -ExpandProperty Count)
    # Build result
    $r = Get-PrtgChannelsResult $channels
    Write-Output $r
}
catch {
    $e = Get-PrtgErrorResult $_.Exception.Message $_.Exception.ToString()
    Write-Output $e
}