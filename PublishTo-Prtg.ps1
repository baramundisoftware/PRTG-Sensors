# Copyright (c) 2018 baramundi software AG - https://www.baramundi.com

Write-Host "$([System.DateTime]::Now.ToLongTimeString()): Copying lookups to PRTG Custom Lookups folder"
Copy-Item .\Lookups\* "${env:ProgramFiles(x86)}\PRTG Network Monitor\Lookups\Custom" -Force -Verbose
Write-Host "$([System.DateTime]::Now.ToLongTimeString()): Copying PowerShell scripts to PRTG EXEXML sensors folder"
Copy-Item .\PowerShell\* "${env:ProgramFiles(x86)}\PRTG Network Monitor\Custom Sensors\EXEXML" -Force -Verbose
