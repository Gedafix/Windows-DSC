Function Get-TrueURL {
   Param (
      [parameter(Mandatory)]
      $Url
   )
   $req = [System.Net.WebRequest]::Create($url)
   $req.AllowAutoRedirect=$false
   $req.Method="GET"
 
   $resp=$req.GetResponse()
   if ($resp.StatusCode -eq "Found") {
      return $resp.GetResponseHeader("Location")
   }
   else {
      return $resp.responseURI
   }
}
$TrueUrl = Get-TrueUrl -Url "annoying-url-here"
$TrueUrl