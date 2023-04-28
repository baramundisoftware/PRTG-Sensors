# Copyright (c) 2018 baramundi software GmbH - https://www.baramundi.com

using module ".\bMS Sensor.psm1"
param (
    [Parameter(Mandatory=$true)]
    [string]$jobName
)
try {
    # Get bConnect context
    $ctx = Get-bConnectContext
    # Get job id
    [Array]$jobs = [Array](Invoke-bConnect $ctx "jobs") | Where-Object { $_.Name -eq $jobName } | Select-Object -First 1
    if ((-not $jobs) -or ($jobs.Count -eq 0)) {
        throw "Unable to find job named $jobName"
    }
    $jobId = $jobs[0].Id
    # Get job instances
    [Array]$instances = Invoke-bConnect $ctx "jobinstances" -Query @{ "JobId" = $jobId }
    $channels = @()
    # Total instances
    $channels += Get-PrtgChannel "Total Instances" "Count" $instances.Count
    # Finished error instances
    $finishedError = Get-PrtgChannel "Finished error" "Count" ($instances | Where-Object { $_.BmsNetState -eq 3 } | Measure-Object | Select-Object -ExpandProperty Count)
    $finishedError.LimitMaxError = 0
    $finishedError.LimitMode = 1
    $channels += $finishedError
    # Finished cancelled instances
    $finishedCancelled = Get-PrtgChannel "Finished cancelled" "Count" ($instances | Where-Object { $_.BmsNetState -eq 4 } | Measure-Object | Select-Object -ExpandProperty Count)
    $finishedCancelled.LimitMaxWarning = 0
    $finishedCancelled.LimitMode = 1
    $channels += $finishedCancelled
    # Waiting for user instances
    $channels += Get-PrtgChannel "Waiting for user" "Count" ($instances | Where-Object { $_.BmsNetState -eq 7 } | Measure-Object | Select-Object -ExpandProperty Count)
    # Waiting for user instances
    $channels += Get-PrtgChannel "Waiting for user (non-blocking)" "Count" ($instances | Where-Object { $_.BmsNetState -eq 11 } | Measure-Object | Select-Object -ExpandProperty Count)
    # Requirements not met instances
    $channels += Get-PrtgChannel "Requirements not met" "Count" ($instances | Where-Object { $_.BmsNetState -eq 8 } | Measure-Object | Select-Object -ExpandProperty Count)
    # Skipped due to incompatibility instances
    $channels += Get-PrtgChannel "Skipped due to incompatibility" "Count" ($instances | Where-Object { $_.BmsNetState -eq 10 } | Measure-Object | Select-Object -ExpandProperty Count)
    # Build result
    $r = Get-PrtgChannelsResult $channels
    Write-Output $r
}
catch {
    $e = Get-PrtgErrorResult $_.Exception.Message $_.Exception.ToString()
    Write-Output $e
}