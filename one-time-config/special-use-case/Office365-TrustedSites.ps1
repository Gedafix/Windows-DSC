########################################################### 
# AUTHOR  : Branko Vucinec - http://blog.brankovucinec.com
# DATE    : 09-07-2015  
# COMMENT : This script import Trusted Sites from an XML 
#           input file.
# VERSION : 1.0 
########################################################### 

#---------------------------------------------------------- 
#READ VARIABLES FROM XML FILE
#---------------------------------------------------------- 
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
[xml]$xml = Get-Content "$MyDir\Office365-TrustedSites.xml"
$ComputerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
$DWord = 2

#---------------------------------------------------------- 
#START FUNCTIONS 
#----------------------------------------------------------
Function CreateKeyReg
{
    Param
    (
        [String]$KeyPath,
        [String]$Name
    )
         New-Item -Path "$KeyPath" -ItemType File -Name "$Name" -ErrorAction SilentlyContinue | Out-Null
}

#Function to set the Registry Values
Function SetRegValue
{
Param
    (
        [String]$RegPath
    )
            Set-ItemProperty -Path $RegPath -Name "http" -Value $DWord -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $RegPath -Name "https" -Value $DWord -ErrorAction SilentlyContinue | Out-Null
}

#---------------------------------------------------------- 
#START
#---------------------------------------------------------- 
foreach( $entry in $xml.trusted)
{
    [array]$Trusted = $entry.site
}

for($i = 0; $i -lt $Trusted.count; $i++)
{
    [string]$PrimaryDomain = $Trusted[$i].Split('.')[1..10] -join '.'
    [string]$SubDomain = $Trusted[$i].Split('.')[0]

    CreateKeyReg -KeyPath $ComputerRegPath -Name $PrimaryDomain
    CreateKeyReg -KeyPath "$ComputerRegPath\$PrimaryDomain" -Name $SubDomain 
    SetRegValue -RegPath "$ComputerRegPath\$PrimaryDomain\$SubDomain" -DWord $DWord
}