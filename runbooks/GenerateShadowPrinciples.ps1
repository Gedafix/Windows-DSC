##Create the Shadow Principle for Domain Admins Group in DEMO
    $ProdPrincipal = ‘Domain Admins’ 
    $ProdDC = ‘child-dc.demo.local’ 
    $ShadowSuffix = ‘PROD-‘
    $ProdShadowPrincipal = Get-ADGroup -Identity $ProdPrincipal -Properties ObjectSID -Server $ProdDC
    $ShadowPrincipalContainer = ‘CN=Shadow Principal Configuration,CN=Services,’+(Get-ADRootDSE).configurationNamingContext
 
    New-ADObject -Type msDS-ShadowPrincipal -Name "$ShadowSuffix$($ProdShadowPrincipal.SamAccountName)" -Path $ShadowPrincipalContainer -OtherAttributes @{'msDS-ShadowPrincipalSid'= $ProdShadowPrincipal.ObjectSID}

##Create the Shadow Principle for Demo Account Account in DEMO
    $ProdPrincipal = ‘demoDomainAdmin’ 
    $ProdDC = ‘child-dc.demo.local’ 
    $ShadowSuffix = ‘PROD-‘
    $ProdShadowPrincipal = Get-ADUser -Identity $ProdPrincipal -Properties ObjectSID -Server $ProdDC
    $ShadowPrincipalContainer = ‘CN=Shadow Principal Configuration,CN=Services,’+(Get-ADRootDSE).configurationNamingContext
 
    New-ADObject -Type msDS-ShadowPrincipal -Name "$ShadowSuffix$($ProdShadowPrincipal.SamAccountName)" -Path $ShadowPrincipalContainer -OtherAttributes @{'msDS-ShadowPrincipalSid'= $ProdShadowPrincipal.ObjectSID}

##Add the Privileged Account to Domain Admins
    Set-adObject -Identity "CN=PROD-Domain Admins,CN=Shadow Principal Configuration,CN=Services,CN=Configuration,DC=cool-name,DC=net" -Add @{'member'="<TTL=180,CN=Non-Privileged Demo Account,OU=Staff,OU=Managed Devices (TIER 2),OU=Resources,DC=cool-name,DC=net>"}