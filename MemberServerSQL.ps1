#BEGIN POWERSHELL SCRIPT

    #This DSC has a number of pre-requisites that must be cleared before this automation will succeed
    #If you are the first SQL DSC User in a new forest than it will fall upon you to clear these pre-requisites
    #If you are the second or more user of SQL in a forest than these pre-requistes may be already handled
        #Add the Computer Account to the Admin-gmsa-SQL-Group in Active Directory, this will grant the machine permissions to use the gmsa Account
        #Add the Admin-SQL-Group to the Local Administrators group on your machine to grant the SQL Admin Permission to the box
        #Unpack your SQL installation files into the location specified in $SqlInstallerSourcePath using the folder name specified

Configuration MemberServerSQL{

    #Import Code Resources for Configuration
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xSystemSecurity'
    Import-DscResource -ModuleName 'SqlServerDsc'
    Import-DscResource -ModuleName 'NetworkingDsc'
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    
    #Initialize Variables
    $SqlInstallerSourcePath = "C:\Admin\SQL2016_x64_ENU"
    $ADMIN_PATH = Get-AutomationVariable -Name "ADMIN_PATH"
    $API_FOLDER_PATH = Get-AutomationVariable -Name "API_FOLDER_PATH"
    $DOMAIN_NAME= Get-AutomationVariable -Name "DOMAIN_NAME"
    $SQL_ADMIN_GROUP = Get-AutomationVariable -Name "SQL_ADMIN_GROUP"
    $SQL_GMSA_ACCOUNT = Get-AutomationVariable -Name "SQL_GMSA_ACCOUNT"

    #Import Credentials From Azure Vault
    $DOMAIN_JOIN = Get-AutomationPSCredential -Name "DOMAIN_JOIN"
    
    #Initialize Group Managed Service Account - Passwords are not used but required due to a dscResource limitation
    $NewADUserCred = ConvertTo-SecureString "BogusPasswordWorkaround!1" -AsPlainText -Force
	$SqlServiceCredential = New-Object System.Management.Automation.PSCredential("$SQL_GMSA_ACCOUNT", $NewADUserCred)

    #Windows features to install
    $Features = @(
        'Net-Framework-45-Core'
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

            #Windows Features Installation
            WindowsFeatureSet InstallFeatures{
                Name = $Features
                Ensure = 'Present'
                IncludeAllSubFeature = $true
            }

            #SQL Server Install Configuration
            SqlSetup 'InstallNamedInstance-SCVMMSQL'{
                Action = 'Install'
                InstanceName = 'SCVMMSQL'
                SQLSvcAccount = $SqlServiceCredential
                AgtSvcAccount = $SqlServiceCredential
                Features = 'SQLENGINE'
                SQLSysAdminAccounts = @("$SQL_ADMIN_GROUP")
                SQLCollation = 'SQL_Latin1_General_CP1_CI_AS'            
                InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
                InstanceDir = 'C:\Program Files\Microsoft SQL Server'
                InstallSQLDataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
                SQLUserDBDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
                SQLUserDBLogDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
                SQLTempDBDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
                SQLTempDBLogDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
                SQLBackupDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup'
                SourcePath = $SqlInstallerSourcePath
                UpdateEnabled = $true
                ForceReboot = $false
                DependsOn = '[xDSCDomainjoin]JoinDomain'
            }

            #Configures SQL TCP Listening Port
            SqlServerNetwork 'ChangeTcpIpOnDefaultInstance'{
                InstanceName         = 'SQL-SVC'
                ProtocolName         = 'Tcp'
                IsEnabled            = $true
                TCPDynamicPort       = $false
                TCPPort              = 50001
                RestartService       = $true
                DependsOn            = '[SqlSetup]InstallNamedInstance-SCVMMSQL'
            }

            #Configures the Firewall settings to allow SQL Connectivity
            FireWall SQLFirewallRule
            {
                Name = "AllowSQLConnection"
                DisplayName = 'Allow SQL Connection'
                Group = 'DSC Configuration Rules'
                Ensure = 'Present'
                Enabled = 'True'
                Profile = ('Domain')
                Direction = 'InBound'
                LocalPort = ('50001')
                Protocol = 'TCP'
                Description = 'Firewall Rule to allow SQL communication'
            }

        #------------------#
        # Monitor Services #
        #------------------#

    }
}