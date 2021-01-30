#Get all IPv6 Addresses on the system and remove them. This will generate a loopback error, this is expected behavior
Get-NetIPAddress -AddressFamily ipv6 | Remove-NetIPAddress

#List all IP Addresses available on the system and write them to host
Write-Host "Available IP Addresses Registered on System"
Get-NetIPAddress | Select-Object IPAddress

#Enter the last octet of the production IP address for this system and configure the rest of the NIC's with it
$IPAddressVariable = Read-Host "Please enter the last octet of this systems Production Network"
$IPAddressA = "192.168.2." + $IPAddressVariable
$IPAddressB = "192.168.3." + $IPAddressVariable
$IPAddressC = "192.168.4." + $IPAddressVariable
$IPAddressD = "192.168.5." + $IPAddressVariable

Get-NetIPAddress -InterfaceAlias "SLOT 2 Port 1" | New-NetIPAddress -IPAddress $IPAddressA -PrefixLength 24
Get-NetIPAddress -InterfaceAlias "SLOT 2 Port 2" | New-NetIPAddress -IPAddress $IPAddressB -PrefixLength 24
Get-NetIPAddress -InterfaceAlias "SLOT 3 Port 1" | New-NetIPAddress -IPAddress $IPAddressC -PrefixLength 24
Get-NetIPAddress -InterfaceAlias "SLOT 3 Port 2" | New-NetIPAddress -IPAddress $IPAddressD -PrefixLength 24
