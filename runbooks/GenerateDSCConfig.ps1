# Define the parameters for Get-AzureRmAutomationDscOnboardingMetaconfig using PowerShell Splatting
$Params = @{
    ResourceGroupName = 'cool-resource-name'; # The name of the Resource Group that contains your Azure Automation Account
    AutomationAccountName = 'cool-account-name'; # The name of the Azure Automation Account where you want a node on-boarded to
    ComputerName = @('LOCALHOST'); # The names of the computers that the meta configuration will be generated for
    OutputFolder = "$env:UserProfile\Desktop\";
}
# Use PowerShell splatting to pass parameters to the Azure Automation cmdlet being invoked
# For more info about splatting, run: Get-Help -Name about_Splatting

Get-AzureRmAutomationDscOnboardingMetaconfig @Params