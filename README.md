## WHAT IS THIS REPOSITORY USED FOR?
This repo contains a baseline configuration for an Enhanced Security Administrative environment presented in an Infrastructure-As-Code format. This Repository utilizes the built-in Configuration Management capabilities native to Windows called PowerShell Desired State Configuration. The README.md below assumes you are hosting DSC on the Windows Azure Automation platform and requires Windows Server 2019 as a minumum supported operating system.

This environment is Microsoft Windows Server native and assumes an aggressive security posture typically only seen in Bastion or Administrative Forests. 

This environment supports the following advanced Windows features: 
| Passwordless Single-Sign On | RDMA Capable Software Defined Storage |

This environment requires familiarity in the following services:


## WHAT IS AZURE AUTOMATION?
Azure Automation is a offering which delivers a cloud-based automation and configuration service that provides consistent management across your Azure and non-Azure environments. It consists of process automation, update management, and configuration features. Azure Automation provides complete control during deployment, operations, and decommissioning of workloads and resources.  

Azure Automation desired state configuration is a cloud-based solution for PowerShell DSC that provides services required for enterprise environments. Manage your DSC resources in Azure Automation and apply configurations to virtual or physical machines from a DSC Pull Server in the Azure cloud. It provides rich reports that inform you of important events such as when nodes have deviated from their assigned configuration. You can monitor and automatically update machine configuration across physical and virtual machines, Windows or Linux, in the cloud or on-premises.

You can get inventory about in-guest resources for visibility into installed applications and other configuration items. A rich reporting and search capabilities are available to quickly find detailed information to help understand what is configured within the operating system. You can track changes across services, daemons, software, registry, and files to quickly identify what might be causing issues. Additionally, DSC can help you diagnose and alert when unwanted changes occur in your environment.

## WHAT ARE THE REQUIREMENTS TO GET STARTED?
In order to get your team started running Infrastructure-as-Code you’ll want to educate yourself on the topice on MSDN. Getting started with Desired State Configuration is simple, but the process has a steep learning curve if you are not familiar with Infrastructure-as-Code Configuration Management. 

## WE’RE ONBOARD, HOW DO I TEST IT OUT?
For most teams, I recommend creating and configuring the following Variables and Credentials to help get you started. Please remember that this is a high-security environment and you should be choosing complex randomly generated passwords at least 30 digits in length for all PS Credential objects stored in your Azure Vault. These examples assume a Windows Domain Environment.

### RECOMMENDED STARTING VARIABLES
| Variable Name | Example Value | Description |
|:---------------------|:---------------------|:---------------------|
| ADMIN_PATH | C:\Admin | This is the folder where you will keep your Binaries or PowerShell scripts used to on-board and install services |
| BASE_DN	| DC=cool-name,DC=net|Base Distinguished Name for your environment
|API_FOLDER_PATH	|C:\Admin\One-Time-Config\DscMetaConfigs-Live	|This is the folder where the On-boarding script will live. This is where your API key will sit to register against DSC and lets the system know which folder to delete when finished so you don’t expose your API keys after registration.|
| DOMAIN_NAME	| Cool-Name.Net	| Active Directory FQDN

### RECOMMENDED PS CREDENTIALS
| Azure Credential | Example Value | Description |
|:---------------------|:---------------------|:---------------------|
|DEFAULT_DC_CRED	|ADMINISTATOR *PASSWORD*	|Default Credential used to Build a new Forest; a password manager should manage this password once the Forest exists. Do not change this, it's used in disaster recovery procedures. This is only required for Net-New Forest scenarios.
|DOMAIN_CONTROLLER_JOIN	|DOMAIN\DC-Domain-Join *PASSWORD*	|Domain Admin account used to promote new domain controllers. This account should be removed from the Domain Admins group when not in use. Change Control should be followed to ensure this account only has permission when required.
|DOMAIN_JOIN	|DOMAIN\AD-Domain-Join *PASSWORD*	|Default credential with rights to join machines to the domain. The Sanctuary Team recommends this account only have rights to create objects in a specific OU.
|TEMP_PASSWORD |Not Used *PASSWORD*	|Generic Variable used for processes that require a full PS Credential object, but don’t use the password itself. A good example of this is a gMSA Object.