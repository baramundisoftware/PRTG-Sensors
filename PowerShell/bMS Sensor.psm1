# Copyright (c) 2018 baramundi software AG - https://www.baramundi.com

function Get-bConnectContextPath() {
    return Join-Path $PSScriptRoot ".bConnect.ctx"
}

function Set-bConnectContext() {
    $url = Read-Host "Please enter the URL of the bConnect server, e.g. https://srv-baramundi.bms-demo.local"
    $user = Read-Host "Please enter the name of the user that is used to access the bConnect interface"
    $pwd = Read-Host "Please enter the password of the user that is used to access the bConnect interface" -AsSecureString
    $path = Get-bConnectContextPath
    $url, $user, (ConvertFrom-SecureString $pwd) -join "|" | Out-File $path
}

function Test-bConnectContext() {
    $ctx = Get-bConnectContext
    Write-Host "bConnect URL is $($ctx.baseUrl)."
    Write-Host "User is $($ctx.cred.UserName)."
    Invoke-bConnect $ctx "info" ""
    Write-Host "If the bConnect information is shown above, the connection attempt was successful."
}

function Get-bConnectContext() {
    try {
        $path = Get-bConnectContextPath
        $data = (Get-Content $path).Split("|")
        $user = $data[1]
        $pwd = ConvertTo-SecureString $data[2]
        $cred = [PSCredential]::new($user, $pwd)
        return [bConnectContext]::new($data[0], $cred)
    }
    catch {
        throw [System.ApplicationException]::new("Error when loading bConnect context. Please run Set-bConnectContext for the current user", $_.Exception)        
    }
}

class bConnectContext {
    [string]$baseUrl;
    [pscredential]$cred;

    bConnectContext(
        [string]$baseUrl,
        [PSCredential]$cred
    ) {
        $this.baseUrl = $baseUrl;
        $this.cred = $cred;   
    }
}

function Invoke-bConnect(
    # bConnect Context
    [Parameter(Mandatory = $true)]
    [bConnectContext]
    $bConnectCtx,
    # Name of the controller without extension or version, e.g. "endpoints"
    [Parameter(Mandatory = $true)]
    [string]$controller, 
    # Version of the controller
    [Parameter(Mandatory = $false)]
    [string]$version = "v1.0",
    # Query parameters as hashtable
    [Parameter(Mandatory = $false)]
    [Hashtable]$query = $null
) {
    $relUrl = "/bConnect"
    if ($version) {
        $relUrl += "/$version"
    }
    $relUrl += "/$controller.json"
    if ($query -and ($query.Count -gt 0)) {
        [Array]$queryParams = $query.Keys | ForEach-Object { "{0}={1}" -f $_, [Uri]::EscapeDataString($query[$_]) }
        $relUrl += "?" + ($queryParams -join "&")
    }
    $baseuri = [Uri]::new($bConnectCtx.baseUrl, [UriKind]::Absolute);
    $uri = [Uri]::new($baseUri, $relUrl)
    return  Invoke-RestMethod $uri.ToString() -Credential $bConnectCtx.cred
}

class channel {
    [string]$Channel;
    [int]$Value;
    [string]$Unit;
    $LimitMaxError;
    $LimitMaxWarning;
    $LimitMinError;
    $LimitMinWarning;
    [string]$LimitErrorMsg;
    [string]$LimitWarningMsg;
    [int]$LimitMode;
    [string]$ValueLookup;

    channel([string]$name, [string]$unit, [int]$value) {
        $this.Channel = $name;
        $this.Value = $value;
        $this.Unit = $unit;
    }
}

class prtg {
}

class prtgChannels : prtg {
    [channel[]]$result = @();

    prtgChannels([channel[]]$channels) {
        $this.result = $channels;
    }
}

class prtgError : prtg {
    [string]$error;
    [string]$text;
    
    prtgError([string]$error, [string]$text) {
        $this.error = $error;
        $this.text = $text;
    }
}

class container {
    [prtg]$prtg;

    container([prtg]$prtg) {
        $this.prtg = $prtg;
    }
}

function Get-PrtgChannel(
    # Name of the channel
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$name, 
    # Unit of the channel
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$unit,
    # Value
    [Parameter(Mandatory = $true, Position = 2)]
    [int]$value
) {
    return [channel]::new($name, $unit, $value)
}

function Get-PrtgChannelsResult(
    # List of channels to return
    [Parameter(Mandatory = $true, Position = 0)]
    [channel[]]$channels) {
    $cont = [container]::new([prtgChannels]::new($channels));
    return ConvertTo-Json $cont -Depth 5
}

function Get-PrtgErrorResult(
    # Error code
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$error, 
    # Message text
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$text
) {
    $cont = [container]::new([prtgError]::new($error, $text));
    return ConvertTo-Json $cont -Depth 5
}

Export-ModuleMember -Function Set-bConnectContext
Export-ModuleMember -Function Test-bConnectContext
Export-ModuleMember -Function Get-bConnectContext
Export-ModuleMember -Function Invoke-bConnect
Export-ModuleMember -Function Get-PrtgChannel
Export-ModuleMember -Function Get-PrtgChannelsResult
Export-ModuleMember -Function Get-PrtgErrorResult
