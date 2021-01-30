#Get All Windows Features and output them in a format compatible with DSC
Get-WindowsFeature | Where-Object {$_.Installed -match “True”} | Select-Object -Property Name