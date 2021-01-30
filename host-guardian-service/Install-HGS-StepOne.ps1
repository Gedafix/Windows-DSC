## Get current directory Running path since this is a USB stick and it could change
$thisScriptDirectoryPath = Split-Path -parent $MyInvocation.MyCommand.Definition

## Enable PSRemoting and WinRM configuration
winrm quickconfig -force
enable-psremoting -force

## Install the Root Certificate for Proxy Access
$PemPath = $thisScriptDirectoryPath + "\Root.pem"
certutil -addstore -f -enterprise -user root $PemPath

##Install HGS Roles
Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools
Install-WindowsFeature DNS -IncludeManagementTools

## Ask for and rename this machine
$RenameComputerVariable = read-host "Please enter this Machines New Name"
Rename-Computer $RenameComputerVariable

## Restart this Computer
Restart-Computer