#BEGIN POWERSHELL SCRIPT

Configuration ActiveDirectoryBuild{
    
    #Once Active Directory has been built, you need to add the Root Certificate to the PKI Trust Store in Active Directory
        #Failure to do this will cause the Root CA to be cleared on every machine that joins the Active Directory Domain
        #This will cause significant DSC Complications as the machine will lose connectivity to Azure mid-deploy, this only needs to be performed once per forest
        #This step is not necessary if your organization does not TLS Decrypt your proxy traffic (shame shame!)
        
        #CertUtil.exe -dspublish -f FILENAME RootCA
    
    #Download and Install Required Resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xSystemSecurity'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
    Import-DscResource -ModuleName 'xDnsServer'

    #Initialize Script Variables
    $DOMAIN_NAME = Get-AutomationVariable -Name "DOMAIN_NAME"
    $ADMIN_PATH = Get-AutomationVariable -Name "ADMIN_PATH"
    $API_FOLDER_PATH = Get-AutomationVariable -Name "API_FOLDER_PATH"
    $BASE_DN = Get-AutomationVariable -Name "BASE_DN"

    #Import Credentials From Azure Vault
    $DEFAULT_DC_CRED = Get-AutomationPSCredential -Name 'DEFAULT_DC_CRED'
    $DOMAIN_CONTROLLER_JOIN = Get-AutomationPSCredential -Name 'DOMAIN_CONTROLLER_JOIN'
    $DOMAIN_JOIN = Get-AutomationPSCredential -Name 'DOMAIN_JOIN'
    $TEMP_PASSWORD = Get-AutomationPSCredential -Name 'TEMP_PASSWORD'

    #Roles and Feature Install Array
	$Features = @(
        'AD-Domain-Services',
        'DNS',
        'RSAT-AD-PowerShell',
        'RSAT-ADDS',
        'RSAT-DNS-Server',
        'BitLocker',
        'RSAT-Feature-Tools-BitLocker-BdeAducExt'
    )

    Node Node{

        #------------------#
        # Base OS Settings #
        #------------------#

            #Set UAC Configuration
            xUAC UAC{
                Setting = 'AlwaysNotify'         
            }

            #Set and monitor the Timezone
            TimeZone TimeZoneSet{
                IsSingleInstance = 'Yes'
                TimeZone = 'Pacific Standard Time'
            }

            #Set and monitor PowerShell Execution policy
            PowerShellExecutionPolicy PowerShellExecutionPolicySet{
                ExecutionPolicyScope = 'LocalMachine'
                ExecutionPolicy = 'RemoteSigned'
            }

            #Create the Admin Folder
            File AdminFolder{
                Ensure = 'Present'
                Type = 'Directory'
                DestinationPath = $ADMIN_PATH
            }

            #Delete the API Registration Folder
            File RemoveAPIFolder{
                Ensure = 'Absent'
                Type = 'Directory'
                Force = $true
                DestinationPath = $API_FOLDER_PATH
            }

        #------------------#
        # Install Services #
        #------------------#

            ##Windows Features Installation
            WindowsFeatureSet InstallFeatures
            {
                Name = $Features
                Ensure = 'Present'
                IncludeAllSubFeature = $true
            }

            #Configures the First Domain Controller in the Forest
            ADDomain ForestBuild{
                DomainName = $DOMAIN_NAME
                Credential = $DEFAULT_DC_CRED
                SafemodeAdministratorPassword = $DEFAULT_DC_CRED
                DependsOn = '[WindowsFeatureSet]InstallFeatures'
            }

        #------------------#
        # Monitor Services #
        #------------------#

            #Active Directory Service Monitoring (NTDS)
            Service NTDSService{
                Name        = 'NTDS'
                StartupType = 'Automatic'
                State       = 'Running'
                DependsOn = '[ADDomain]ForestBuild'
            }

        #-------------------------------#
        # Directory Services Management #
        #-------------------------------#

            #Sets the Default Password and Lock-Out Policies
            ADDomainDefaultPasswordPolicy DomainPasswordPolicy{
                DomainName = $DOMAIN_NAME
                PasswordHistoryCount = 24
                MinPasswordAge = 1440
                MaxPasswordAge = 525600
                MinPasswordLength = 30
                ComplexityEnabled = $true
                ReversibleEncryptionEnabled = $false
                LockoutDuration = 15
                LockoutObservationWindow = 15
                LockoutThreshold = 50
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Renames the Default-First-Site-Name to Primary Datacenter
            ADReplicationSite cool-name-SE1{
                Name = 'cool-name-SE1'
                RenameDefaultFirstSiteName = $true
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Builds the AD Replication Site for Secondary Datacenter
            ADReplicationSite cool-name-LAS{
                Name = 'cool-name-LAS'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Builds the AD Replication Site-for-Site Servers
            ADReplicationSite cool-name-ORG{
                Name = 'cool-name-ORG'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            }
            
            #Creates the KDS Root Key used to Build Group Managed Service Accounts
            ADKDSKey KDSRootKey{
                Ensure = 'Present'
                EffectiveTime = '7/1/2019 09:00' #Change date to minimum ten hours behind current time or it will be unuseable
                AllowUnsafeEffectiveTime = $true
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Pre-Stages the Forest Wide TIER Groups required for ESAE Architecture
            ADGroup TierZero-Group{
                GroupName = 'Admin-Tier-Zero'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Tier Zero Admin Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            ADGroup TierOne-Group{
                GroupName = 'Admin-Tier-One'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Tier One Admin Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            ADGroup TierTwo-Group{
                GroupName = 'Admin-Tier-Two'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Tier Two Admin Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            #Pre-Stages the PAW Users User Group
            ADGroup PAWUser-Group{
                GroupName = 'PAW-Users'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'PAW Users Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 
        
            #Pre-Stages the DHCP Admins User Group
            ADGroup Admin-DHCP-Manage{
                GroupName = 'Admin-DHCP-Manage'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'DHCP Admin Management Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            #Pre-Stages the Domain Join Delegation Group
            ADGroup Admin-DomJoin-Group{
                GroupName = 'Admin-Domain-Join'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Cool Name Domain Join Delegation Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            #Pre-Stages the SQL Server Administrative Group
            ADGroup Admin-SQL-Group{
                GroupName = 'Admin-SQL-Group'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Cool Name SQL Server Administrative Group for Administrative Users and Service Accounts'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            #Pre-Stages gMSA Service Accounts for SQL Cluster use
            ADGroup Admin-gmsa-SQL-Group{
                GroupName = 'Admin-gmsa-SQL-Group'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Cool Name SQL Server gMSA Delegation Group for Computer Objects'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 
                ADManagedServiceAccount 'gmsaSVC-SQL'
                {
                    Description = 'Cool Name SQL Server gMSA Account'
                    Ensure = 'Present'
                    ServiceAccountName = 'gmsaSVC-SQL'
                    AccountType = 'Group'
                    DependsOn = '[ADGroup]Admin-gmsa-SQL-Group'
                }

            #Pre-Stages the Cluster Name Object Delegation Groups
            ADGroup Cluster-Tier-One{
                GroupName = 'Cluster-Tier-One'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Cool Name CNO Delegation Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 

            ADGroup Cluster-Tier-Zero{
                GroupName = 'Cluster-Tier-Zero'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Cool Name CNO Delegation Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 
            
            #Pre-Stages the Root Level Resource OU
            ADOrganizationalUnit 'OU-Resources'{
                Name = 'Resources'
                Path = $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Pre-Stages the Privately Managed OU and Sub-Folders
            ADOrganizationalUnit 'OU-PM'{
                Name = 'PM'
                Path = $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            }

            ADOrganizationalUnit 'OU-DHCP'{
                Name = 'DHCP'
                Path = "OU=PM," + $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADOrganizationalUnit]OU-PM'
            }

            #Pre-Stages the Tier Level OU Structure
            ADOrganizationalUnit 'OU-Critical-Systems'{
                Name = 'Critical Systems (TIER 0)'
                Path = "OU=Resources," + $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADOrganizationalUnit]OU-Resources'
            }

            ADOrganizationalUnit 'OU-Guarded-Fabric'{
                Name = 'Guarded Fabric (TIER 1)'
                Path = "OU=Resources," + $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADOrganizationalUnit]OU-Resources'
            }

            ADOrganizationalUnit 'OU-Applications'{
                Name = 'Applications (TIER 1)'
                Path = "OU=Resources," + $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADOrganizationalUnit]OU-Resources'
            }

            ADOrganizationalUnit 'OU-Managed-Devices'{
                Name = 'Managed Devices (TIER 2)'
                Path = "OU=Resources," + $BASE_DN
                Ensure = 'Present'
                DependsOn = '[ADOrganizationalUnit]OU-Resources'
            }

            #Pre-Stages Cluster Name Objects for Base Services
            ADComputer 'CNO-COREADMIN'{
                ComputerName = 'COREADMIN'
                Description = "Cluster Name Object for S2D Admin Cluster"
                EnabledOnCreation = $false
                DependsOn = '[ADDomain]ForestBuild'
            }

            ADComputer 'CNO-CORESQL'{
                ComputerName = 'CORESQL'
                Description = "Cluster Name Object for S2D SQL Cluster"
                EnabledOnCreation = $false
                DependsOn = '[ADDomain]ForestBuild'
            }

            ADComputer 'CNO-CORESQLDR'{
                ComputerName = 'CORESQLDR'
                Description = "Cluster Name Object for S2D SQL DR Cluster"
                EnabledOnCreation = $false
                DependsOn = '[ADDomain]ForestBuild'
            }

            ADComputer 'CNO-COREPRIMARY'{
                ComputerName = 'COREPRIMARY'
                Description = "Cluster Name Object for S2D Primary Cluster"
                EnabledOnCreation = $false
                DependsOn = '[ADDomain]ForestBuild'
            }

            ADComputer 'CNO-CORESECONDARY'{
                ComputerName = 'CORESECONDARY'
                Description = "Cluster Name Object for S2D Secondary Cluster"
                EnabledOnCreation = $false
                DependsOn = '[ADDomain]ForestBuild'
            }

            ADComputer 'CNO-CORESOFS'{
                ComputerName = 'CORESOFS'
                Description = "Cluster Name Object for Scale Out File Server Cluster"
                EnabledOnCreation = $false
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Configures Universal DNS Server Settings
            xDnsServerConditionalForwarder 'DNS-cool-name'{
                Name = "Cool Name"
                MasterServers = "10.78.20.219","10.78.20.220"
                ReplicationScope = "Forest"
                DependsOn = '[ADDomain]ForestBuild'
            }

            xDnsServerConditionalForwarder 'DNS-cool-name.net'{
                Name = "cool-name.net"
                MasterServers = "10.78.0.11","10.78.0.12","10.78.8.11"
                ReplicationScope = "Forest"
                DependsOn = '[ADDomain]ForestBuild'
            }

            xDnsServerForwarder 'DNS-Default-Forwarder'{
                IsSingleInstance = "Yes"
                IPAddresses = "10.78.62.176","10.78.130.26"
                UseRootHint = $false
                DependsOn = '[ADDomain]ForestBuild'
            }
            
            xDnsServerADZone 'DNS-Default-ARPA'{
                Name = '10.in-addr.arpa'
                DynamicUpdate = 'Secure'
                ReplicationScope = 'Forest'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Create and pre-stages the AD-Join Account
            ADUser 'Admin-Domain-Join'{
                UserName = 'AD-Domain-Join'
                DomainName = $DOMAIN_NAME
                Password   = $DOMAIN_JOIN
                Description = "Domain Join Account"
                Ensure = 'Present'
                RestoreFromRecycleBin = $true
                PasswordNeverExpires = $true
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Create and pre-stages the DC-Join Account, The domain admin group should be added to this user on-demand
            ADUser 'Admin-DC-Join'{
                UserName = 'DC-Domain-Join'
                DomainName = $DOMAIN_NAME
                Password   = $DOMAIN_CONTROLLER_JOIN
                Description = "Domain Controller Join Account"
                Ensure = 'Present'
                RestoreFromRecycleBin = $true
                PasswordNeverExpires = $true
                DependsOn = '[ADDomain]ForestBuild'
            }

            #Pre-Stages gMSA Service Accounts for SCVMM Use
            ADGroup Admin-gmsa-SCVMM-Group{
                GroupName = 'Admin-gmsa-SCVMM-Group'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Cool Name SCVMM Server gMSA Delegation Group'
                Ensure = 'Present'
                DependsOn = '[ADDomain]ForestBuild'
            } 
                ADManagedServiceAccount 'gmsaSVC-SCVMM'
                {
                    Description = 'Cool Name SCVMM Server gMSA Account'
                    Ensure = 'Present'
                    ServiceAccountName = 'gmsaSVC-SCVMM'
                    AccountType = 'Group'
                    DependsOn = '[ADGroup]Admin-gmsa-SCVMM-Group'
                }

        #-----------------#
        # User Management #   
        #-----------------#

            #Creates Administrative Users for use in the Admin Forest (No Email)
            ADUser 'Admin-User-One-ADM'{
                DomainName = $DOMAIN_NAME
                Password = $TEMP_PASSWORD
                Ensure = 'Present'
                RestoreFromRecycleBin = $true
                PasswordNeverResets = $true
		        CannotChangePassword = $true
                Path = "OU=Managed Devices (TIER 2),OU=Resources," + $BASE_DN
                DependsOn = '[ADOrganizationalUnit]OU-Managed-Devices'

                UserName = 'AdminOne'
                UserPrincipalName = "AdminOne@cool-name.net"
                Description = "AdminOne"
		        DisplayName = "AdminOne"
                Company = "Cool Name Inc" 
            }

            ADUser 'Admin-User-Two-ADM'{
                DomainName = $DOMAIN_NAME
                Password = $TEMP_PASSWORD
                Ensure = 'Present'
                RestoreFromRecycleBin = $true
                PasswordNeverResets = $true
		        CannotChangePassword = $true
                Path = "OU=Managed Devices (TIER 2),OU=Resources," + $BASE_DN
                DependsOn = '[ADOrganizationalUnit]OU-Managed-Devices'

                UserName = 'AdminTwo'
                UserPrincipalName = "AdminTwo@cool-name.net"
                Description = "AdminTwo"
		        DisplayName = "AdminTwo"
                Company = "Cool Name Inc"
            }

            ADUser 'Admin-User-Three-ADM'{
                DomainName = $DOMAIN_NAME
                Password = $TEMP_PASSWORD
                Ensure = 'Present'
                RestoreFromRecycleBin = $true
                PasswordNeverResets = $true
		        CannotChangePassword = $true
                Path = "OU=Managed Devices (TIER 2),OU=Resources," + $BASE_DN
                DependsOn = '[ADOrganizationalUnit]OU-Managed-Devices'

                UserName = 'AdminThree'
                UserPrincipalName = "AdminThree@cool-name.net"
                Description = "AdminThree"
		        DisplayName = "AdminThree"
                Company = "Cool Name Inc"
            }

            #Creates Standard Non-Admin Users for use in the Admin Forest (Required Email)
    }
}
