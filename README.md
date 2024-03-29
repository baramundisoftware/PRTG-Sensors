# baramundi Management Suite - Sensors for PRTG
# Copyright (c) 2018 baramundi software GmbH - https://www.baramundi.com


## Prerequisites
The supplied sensors can be used to monitor several aspects of a bMS installation through PTRG. The scripts are built using PowerShell version 5.1. Please assert that this version is installed on the servers that run the sensors. 
The sensors use the bConnect interface to read information from your bConnect installation. Please install and configure the interface before proceeding with the installation of the PRTG sensors.
The package contains the following sensors:
- bMS Endpoint Summary.ps1: provides an overview over the endpoints registered in the bMS.
- bMS Job Summary.ps1: watches a job and provides information about its instances.
- bMS Endpoint.ps1: monitors a specific endpoint, e.g. a critical system.


## Installation
Please download the repository as zip and unzip the file. This file contains the sensor files that need to be placed in specific directories of your PRTG installation.  
For a one-server-installation of PRTG that uses the default folders you can use the included PowerShell script PublishTo-Prtg.ps1. In a more complex scenario, you can adjust the script to copy the files to the correct folders.
By default, the script copies the contents to the following folders:
- Lookups are used to map sensor values to easier to interpret string representations and have to be placed in the folder `<PRTG-Program-Dir>\lookups\custom`, e.g. `C:\Program Files (x86)\PRTG Network Monitor\lookups\custom`
- Scripts contain the code that accesses the bConnect interface and transforms the answer into a format that PRTG can interpret. The folder that contains these scripts is `<PRTG-Program-Dir>\Custom Sensors\EXEXML`, e.g. `C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML`. 
In order to load the custom lookups, please reload the lookup files in the PRTG admin area.


## Security
In order to access the bConnect interface, authentication with a username and password is required. In order to keep the password confidential, the base URL and the credentials are stored in a file. The password is encrypted using the Windows Data Protection API so that it is only accessible on the machine and under the account that was used to store the file.  
In addition, please make sure that the bConnect interface uses TLS. 


## Configuration
After the files have been copied, the bConnect context (URL and credentials) needs to be stored. Please perform the following steps while logged in with the account that is used to access the Windows computers from PRTG. 
Open a PowerShell prompt and change location to the directory that contains the PowerShell scripts, e.g.:

    sl "${env:ProgramFiles(x86)}\PRTG Network Monitor\Custom Sensors\EXEXML"
Import the module that contains the basic functionality for the sensors:

    Import-Module '.\bMS Sensor.psm1'
Call the function `Set-bConnectContext` and provide the information:

    PS C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML> Set-bConnectContext
    Please enter the URL of the bConnect server, e.g. https://srv-baramundi.bms-demo.local: https://srv-baramundi.bms-demo.local
    Please enter the name of the user that is used to access the bConnect interface: MyAccount
    Please enter the password of the user that is used to access the bConnect interface: ******
    
After the function is finished, the context is stored. Before creating sensors, please use the commandlet `Test-bConnectContext` to test the connectivity to the bConnect interface. 


## Sensor creation
In order to create a sensor for the bMS, select the parent device and choose `Add sensor`.  Select the sensor type `EXE/Script Advanced` in the group `Custom sensors`. Adjust the following settings: 
- Name: enter a name that allows for easy identification of the sensor.
- Tags: for easy selection, you can use a dedicated tag for all bMS sensors, e.g. `bMS`.
- EXE/Script: select the corresponding script (see below).
- Parameters: set the parameters as required (see below). Please enclose values that contains spaces in quotation marks.
- Security context: assert that the script is run under the user account that was used to store and encrypt the bConnect context information. In a default installation, the probe runs under _Local system_, so selecting the second option `Use windows credentials of parent device`  might be a better choice.
- EXE result: for easier troubleshooting, it is advisable to store the result of the sensor in the logs directory, at a minimum if errors occure.

The following table contains some hints on the settings for specific sensors:

Sensor; Parent device; Parameters
- bMS Endpoint Summary.ps1; bMS server; -none-
- bMS Job Summary.ps1; bMS server; Job name
- bMS Endpoint.ps1; Device to be monitored; FQDN (or display name) of monitored device, e.g. %host


## Troubleshooting
If the sensors report errors due to an unsupported file format, please carry out the following steps to identity the cause:
- Make sure that the sensor stores the EXE result in the file system, so that you can access the error message in the folder `C:\ProgramData\Paessler\PRTG Network Monitor\Logs (Sensors)`. 
- Run Test-bConnectContext to check whether the bConnect connection works (see chapter Configuration).
- Assert that the bConnect certificate is trusted on the machine that the probe is executed on.
