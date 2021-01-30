#BEGIN POWERSHELL SCRIPT

Configuration S2DHypervisorDell{

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xHyper-V'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xSystemSecurity'
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    Import-DscResource -ModuleName 'GuardedFabricTools'
    
    #Initialize Variables
    $ADMIN_PATH = Get-AutomationVariable -Name "ADMIN_PATH"
    $API_FOLDER_PATH = Get-AutomationVariable -Name "API_FOLDER_PATH"
    $DOMAIN_NAME= Get-AutomationVariable -Name "DOMAIN_NAME"

    #Import Credentials From Azure Vault
    $DOMAIN_JOIN = Get-AutomationPSCredential -Name "DOMAIN_JOIN"

    #Windows features to install
	$Features = @(
        'Hyper-V',
        'BitLocker',
        'HostGuardian',
        'RSAT-Shielded-VM-Tools',
        'RSAT-Hyper-V-Tools',
        'Hyper-V-Tools',
        'Hyper-V-PowerShell',
        'Failover-Clustering',
        'RSAT-Clustering-PowerShell',
        'FS-FileServer',
        'NetworkVirtualization',
        'RSAT-Clustering-Mgmt',
        'Data-Center-Bridging'
    )

    Node Node{

        #------------------#
        # Base OS Settings #
        #------------------#
        
            #Set UAC Configuration
            xUAC UAC{
                Setting = "AlwaysNotify"         
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

            #Join Active Directory Domain
            xDSCDomainjoin JoinDomain{
                Domain = $DOMAIN_NAME
                Credential = $DOMAIN_JOIN
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
       
            #VM Host Switch 
            xVMSwitch ExternalVSwitch{
                Name = 'OS-Traffic'
                Type = 'External'
                AllowManagementOS = $true
                Ensure = 'Present'
                NetAdapterName = 'NIC1','NIC2'
                EnableEmbeddedTeaming = $true
                DependsOn = '[WindowsFeatureSet]InstallFeatures'
            }

        #------------------#
        # Monitor Services #
        #------------------#          
                   
    }
}