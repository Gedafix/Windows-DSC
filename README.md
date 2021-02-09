## WHAT IS THIS CODE REPOSITORY?
This repo contains a baseline configuration for an Enhanced Security Administrative Forest presented in an Infrastructure-As-Code format. This Repository utilizes the built-in Configuration Management capabilities native to Windows called PowerShell Desired State Configuration. 

The environment assumes you are hosting DSC on the Windows Azure Automation platform and requires Windows Server 2019 as a minimum supported operating system. The environment is Microsoft Windows Server native and assumes an aggressive security posture typically only seen in Bastion or Administrative Environments. Extensive use of Reverse Proxy agents limit required ingress firewall to DNS Forwarding. The code also contains a baseline for a Host Guardian Service as this environment is intended to be hosted on Windows Shielded Virtual Machines in a trusted Guarded Fabric. I've also included some baseline configurations for Hypervisor-Protected Code Integrity (HVCI) but it is likely unnecessary for most organizations.

This environment supports all the following advanced Windows features:
| | | | |
|:---------------------|----------------------|----------------------|----------------------|
| Passwordless Single-Sign On | Azure AD Internet SSO | Azure Conditional Access | Cloud Managed Configuration Management |
| Remote Desktop SSO | Virtual TPM Smartcards | Hyperconverged Infrastructure |  Software Defined Storage |
| Windows Infrastructure as Code | Declarative Configuration Management | CI/CD Pipeline Deployment  | Modern Group Policy Baselines |

## WHAT IS AZURE AUTOMATION?
Azure Automation is an offering which delivers a cloud-based automation and configuration service that provides consistent management across your Azure and non-Azure environments. It consists of process automation, update management, and configuration features. Azure Automation provides complete control during deployment, operations, and decommissioning of workloads and resources.  

Azure Automation desired state configuration is a cloud-based solution for PowerShell DSC that provides services required for enterprise environments. Manage your DSC resources in Azure Automation and apply configurations to virtual or physical machines from a DSC Pull Server in the Azure cloud. It provides rich reports that inform you of important events such as when nodes have deviated from their assigned configuration. You can monitor and automatically update machine configuration across physical and virtual machines, Windows, or Linux, in the cloud or on-premises.

You can get inventory about in-guest resources for visibility into installed applications and other configuration items. A rich reporting and search capabilities are available to quickly find detailed information to help understand what is configured within the operating system. You can track changes across services, daemons, software, registry, and files to quickly identify what might be causing issues. Additionally, DSC can help you diagnose and alert when unwanted changes occur in your environment.

## WHAT ARE THE REQUIREMENTS TO GET STARTED?
To get your team started running Infrastructure-as-Code you’ll want to educate yourself on the topic on MSDN. Getting started with Desired State Configuration is simple, but the process has a steep learning curve if you are not familiar with Infrastructure-as-Code Configuration Management. 

## WE’RE ONBOARD, HOW DO I TEST IT OUT?
For most teams, I recommend creating and configuring the following Variables and PS Credentials to help get you started. Please remember that this is a high-security environment, and you should be choosing complex randomly generated passwords at least 30 digits in length for all PS Credential objects stored in your Azure Vault. These examples assume a Windows Domain Environment.

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
|DEFAULT_DC_CRED	|ADMINISTATOR *PASSWORD*	|Default Credential used to Build a new Forest; a password manager should manage this password once the Forest exists. Do not change this value once set as it is used in disaster recovery procedures. This is only required for Net-New Forest scenarios.
|DOMAIN_CONTROLLER_JOIN	|DOMAIN\DC-Domain-Join *PASSWORD*	|Domain Admin account used to promote new domain controllers. This account should be removed from the Domain Admins group when not in use. Change Control should be followed to ensure this account only has permission when required.
|DOMAIN_JOIN	|DOMAIN\AD-Domain-Join *PASSWORD*	|Default credential with rights to join machines to the domain. The Sanctuary Team recommends this account only have rights to create objects in a specific OU.
|TEMP_PASSWORD |Not Used *PASSWORD*	|Generic Variable used for processes that require a full PS Credential object, but do not use the password itself. A good example of this is a gMSA Object that has no password.

### WHAT ARE SOME PITFALLS TO WATCH OUT FOR?
While Desired State Configuration is a very mature technology, the DSC Resource modules included above change FREQUENTLY. This means that the systems, spelling, functions, and routines contained within the modules are subject to change unless you pin the module version in your code. As always, reference code is not production ready, and if you deploy this configuration as-is you are an idiot.

### WHERE DO I GO FOR MORE INFORMATION OR IF I'M STUCK?
If you would like to geek out over the repo contained above, please reach out to me on my linked-in at /michael-m-freeman/. 
