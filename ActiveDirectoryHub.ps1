#BEGIN POWERSHELL SCRIPT 

Configuration ActiveDirectoryHub{
    
    #Download and Install Required Resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xSystemSecurity'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'

    #Initialize Script Variables
    $DOMAIN_NAME = Get-AutomationVariable -Name "DOMAIN_NAME"
    $ADMIN_PATH = Get-AutomationVariable -Name "ADMIN_PATH"
    $API_FOLDER_PATH = Get-AutomationVariable -Name "API_FOLDER_PATH"

    #Import Credentials From Azure Vault
    $DOMAIN_CONTROLLER_JOIN = Get-AutomationPSCredential -Name 'DOMAIN_CONTROLLER_JOIN'
    $DOMAIN_JOIN = Get-AutomationPSCredential -Name 'DOMAIN_JOIN'

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

            #Detect Forest's exists before performing join
            WaitForADDomain 'WaitForestAvailability'{
                DomainName = $DOMAIN_NAME
                Credential = $DOMAIN_JOIN
                DependsOn = '[WindowsFeatureSet]InstallFeatures'
            }

            #Configures the Domain Controller and Joins an Existing Domain
            ADDomainController ForestJoin{
                DomainName = $DOMAIN_NAME
                Credential = $DOMAIN_CONTROLLER_JOIN
                SafemodeAdministratorPassword = $DOMAIN_CONTROLLER_JOIN
                DependsOn = '[WaitForADDomain]WaitForestAvailability'
            }

        #------------------#
        # Monitor Services #
        #------------------#

            #Active Directory Service Monitoring (NTDS)
            Service NTDSService{
                Name        = 'NTDS'
                StartupType = 'Automatic'
                State       = 'Running'
                DependsOn = '[ADDomainController]ForestJoin'
            }

        #-----------------------#
        # Post-Install Services #
        #-----------------------#

            #Do not add Post-Install Services to a HUB Domain Controller Build

    }
}