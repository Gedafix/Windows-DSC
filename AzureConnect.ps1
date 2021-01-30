#BEGIN POWERSHELL DSC TEMPLATE FILE

Configuration AzureConnect{

    #Import Code Resources for Configuration
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xSystemSecurity'
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    
    #Initialize Variables
    $ADMIN_PATH = Get-AutomationVariable -Name "ADMIN_PATH"
    $API_FOLDER_PATH = Get-AutomationVariable -Name "API_FOLDER_PATH"
    $DOMAIN_NAME= Get-AutomationVariable -Name "DOMAIN_NAME"

    #Import Credentials From Azure Vault
    $DOMAIN_JOIN = Get-AutomationPSCredential -Name "DOMAIN_JOIN"

    #Windows features to install
	$Features = @(
        'BitLocker'
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
    
        #------------------#
        # Monitor Services #
        #------------------#          
  
    }
}