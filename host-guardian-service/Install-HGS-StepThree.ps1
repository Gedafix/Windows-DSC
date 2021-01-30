Import-Module HgsServer

# Ensure Step One and Two is completed and the machine has been rebooted prior to starting this step
$PFXPassword = Read-Host "Please Enter PFX Password" -AsSecureString
Initialize-HgsServer -LogDirectory C:\Admin -HgsServiceName cool-name-here -Http -TrustTpm -SigningCertificatePath C:\Admin\host-guardian-service\HGS-Certificate.pfx -SigningCertificatepassword $PFXPassword -EncryptionCertificatePath C:\Admin\host-guardian-service\HGS-Certificate.pfx -EncryptionCertificatePassword $PFXPassword

Get-HGSTrace -RunDiagnostics