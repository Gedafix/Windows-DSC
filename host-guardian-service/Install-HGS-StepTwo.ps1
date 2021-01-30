Import-Module HgsServer

#Install the First Node in the HGS Cluster and set DSRM Password
$DSRMPassword = Read-Host "Please Enter DSRM Password" -AsSecureString
Install-HGSServer -HgsDomainName "cool-name.net" -SafeModeAdministratorPassword $DSRMPassword -Restart