#Imports GPOs from a foldername
#User is prompted to select the folder from which to import the GPOs

Import-Module ActiveDirectory            
Import-Module GroupPolicy  

#Opens a file browser to select the appropiate folder containing GPO backups
$app = new-object -com Shell.Application
$folder = $app.BrowseForFolder(0, "Select Folder", 0, "C:\")
$GPOFolderName = $folder.Self.Path
$import_array = get-childitem $GPOFolderName | Select name

#Loop through the array and import the GPO as laveled in the XML File
foreach ($ID in $import_array) {
    $XMLFile = $GPOFolderName + "\" + $ID.Name + "\gpreport.xml"
    $XMLData = [XML](get-content $XMLFile)
    $GPOName = $XMLData.GPO.Name
    import-gpo -BackupId $ID.Name -TargetName $GPOName -path $GPOFolderName -CreateIfNeeded
}