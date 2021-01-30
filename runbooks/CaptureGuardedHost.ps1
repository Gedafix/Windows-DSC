#Initialize Script Variables
$ComputerName = get-childitem -path env:computername
$TPMPath = "\\share\Admin\" + $ComputerName.Value + ".xml"
#$TCGPath = "\\share\Admin\" + $ComputerName.Value + ".tcglog"

#Pull the TPM EKPub and write to a file under C:\Admin\HostnameVariable.log
(Get-PlatformIdentifier –Name $ComputerName.value).InnerXml | Out-file $TPMPath

#Pull the TPM baseline and write to a file under C:\Admin\HostnameVariable.tcglog
#Get-HgsAttestationBaselinePolicy –Path $TCGPath

#Register the server with the HostGuardianService at timelord.cool-name.net
#Set-HgsClientConfiguration -AttestationServerURL 'http://cool-name.net/Attestation' -KeyProtectionServerURL 'http://cool-name.net/KeyProtection'