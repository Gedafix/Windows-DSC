#BEGIN POWERSHELL SCRIPT

Configuration RedForestBuild{
    #Do not attach this DSC Configuration until AFTER the Red Forest has been created using the HGS Commandlets or all AD Related Configs will fail spectacularly
        # Install-WindowsFeature -Name HostGuardianServiceRole -IncludeManagementTools -Restart
        # $adminPassword = Read-Host -AsSecureString -Prompt "Enter a password for the Red Forest Safe Mode MAKE IT COMPLEX"
        # Install-HgsServer -HgsDomainName 'cool-name.net' -SafeModeAdministratorPassword $adminPassword -Restart
    #For the first node in the domain ONLY, copy the PFX files containing the HGS Certificates to the System before initializing

    #Once Active Directory has been built, you need to add the Root Certificate to the PKI Trust Store in Active Directory
        #Failure to do this will cause the Root CA to be cleared on every machine that joins the Active Directory Domain
        #This will cause severe DSC Complications as the machine will lose connectivity to Azure mid-deploy, this only needs to be performed once per forest
        
        # CertUtil.exe -dspublish -f FILENAME RootCA
    
    #Download and Install Required Resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xSystemSecurity'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
    Import-DscResource -ModuleName 'xDnsServer'
    Import-DscResource -ModuleName 'GuardedFabricTools'

    #Initialize Script Variables
    $ADMIN_PATH = Get-AutomationVariable -Name "ADMIN_PATH"
    $API_FOLDER_PATH = Get-AutomationVariable -Name "API_FOLDER_PATH"
    $DOMAIN_NAME = "cool-name.net"

    #Roles and Feature Install Array
	$Features = @(
        'HostGuardianServiceRole',
        'RSAT-Shielded-VM-Tools'
    )

    Node HGS{
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
            WindowsFeatureSet InstallFeatures{
                Name = $Features
                Ensure = 'Present'
                IncludeAllSubFeature = $true
            }

            #Wait for Forest to be contacted
            WaitForADDomain HGSForestWait{
                DomainName = $DOMAIN_NAME
            }
            
        #------------------#
        # Monitor Services #
        #------------------#

            #Active Directory Service Monitoring (NTDS)
            Service NTDSService{
                Name        = 'NTDS'
                StartupType = 'Automatic'
                State       = 'Running'
                DependsOn = '[WaitForADDomain]HGSForestWait'
            }

        #-----------------------#
        # Post-Install Services #
        #-----------------------#

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
                DependsOn = '[WaitForADDomain]HGSForestWait'
            }

            #Renames the Default-First-Site-Name to SE1 Primary Datacenter
            ADReplicationSite cool-name-SE1{
                Name = 'Red-Forest-SE1'
                RenameDefaultFirstSiteName = $true
                Ensure = 'Present'
                DependsOn = '[WaitForADDomain]HGSForestWait'
            }

            ADReplicationSite cool-name-LAS1{
                Name = 'Red-Forest-LAS1'
                Ensure = 'Present'
                DependsOn = '[WaitForADDomain]HGSForestWait'
            }

            #Pre-Stages the Forest Wide  Groups required for HGS Architecture
             ADGroup HGS-Users-Group{
                GroupName = 'Admin-HGS-Users'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Tier Zero HGS Users Group'
                Ensure = 'Present'
                DependsOn = '[WaitForADDomain]HGSForestWait'
            } 

            ADGroup HGS-Admins-Group{
                GroupName = 'Admin-HGS-Admins'
                GroupScope = 'Universal'
                Category = 'Security'
                Description = 'Tier Zero HGS Admins Group'
                Ensure = 'Present'
                DependsOn = '[WaitForADDomain]HGSForestWait'
            } 

            #Configures Universal DNS Server Settings
            xDnsServerForwarder 'DNS-Default-Forwarder'{
                IsSingleInstance = "Yes"
                IPAddresses = "10.78.0.10"
                UseRootHint = $false
                DependsOn = '[WaitForADDomain]HGSForestWait'
            }
            
            xDnsServerADZone 'DNS-Default-ARPA'{
                Name = '10.in-addr.arpa'
                DynamicUpdate = 'Secure'
                ReplicationScope = 'Forest'
                Ensure = 'Present'
                DependsOn = '[WaitForADDomain]HGSForestWait'
            }
    }
}