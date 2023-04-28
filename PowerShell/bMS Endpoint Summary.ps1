# Copyright (c) 2018 baramundi software GmbH - https://www.baramundi.com

using module ".\bMS Sensor.psm1"
try {
    # Get bConnect context
    $ctx = Get-bConnectContext
    # Get endpoints
    [Array]$endpoints = [Array](Invoke-bConnect $ctx "endpoints") | Where-Object { $_.Type -ne 16 }

    $winAndMac = @(1, 4)
    $today = [DateTime]::Today
    $channels = @()
    # Total endpoints
    $channels += Get-PrtgChannel "Total endpoints" "Count" $endpoints.Count
    # Active endpoints
    $channels += Get-PrtgChannel "Active endpoints" "Count" ($endpoints | 
            Where-Object { ($_.Options -band 2147483648) -ne 2147483648 } | 
            Measure-Object | 
            Select-Object -ExpandProperty Count)
    # Inactive endpoints
    $channels += Get-PrtgChannel "Inactive endpoints" "Count" ($endpoints | 
            Where-Object { ($_.Options -band 2147483648) -eq 2147483648 } | 
            Measure-Object | 
            Select-Object -ExpandProperty Count)
    # Not compliant endpoints
    $notCompliant = Get-PrtgChannel "Not compliant endpoints" "Count" ($endpoints | 
            Where-Object { (-Not ($winAndMac -contains $_.Type)) -And ($_.ComplianceState -eq 4) } | 
            Measure-Object | 
            Select-Object -ExpandProperty Count)
    $notCompliant.LimitMaxError = 0
    $notCompliant.LimitMode = 1
    $channels += $notCompliant
    # Endpoints having compliance check deactivated
    $complDeactivated = Get-PrtgChannel "Compliance check deactivated" "Count" ($endpoints | 
            Where-Object { (-Not ($winAndMac -contains $_.Type)) -And ($_.ComplianceState -eq 5) } | 
            Measure-Object | 
            Select-Object -ExpandProperty Count)
    $complDeactivated.LimitMaxWarning = 0
    $complDeactivated.LimitMode = 1
    $channels += $complDeactivated
    # Max last seen in days
    $lastSeen = Get-PrtgChannel "Max last seen in days" "Count" ($endpoints | 
            Where-Object { $_.LastSeen } | 
            ForEach-Object { [int]($today.Subtract(([DateTime]($_.LastSeen)).Date).TotalDays) } | 
            Measure-Object -Maximum | 
            Select-Object -ExpandProperty Maximum)
    $lastSeen.LimitMaxWarning = 10
    $lastSeen.LimitMaxError = 60
    $lastSeen.LimitMode = 1
    $channels += $lastSeen
    # Build result
    $r = Get-PrtgChannelsResult $channels
    Write-Output $r
}
catch {
    $e = Get-PrtgErrorResult $_.Exception.Message $_.Exception.ToString()
    Write-Output $e
}