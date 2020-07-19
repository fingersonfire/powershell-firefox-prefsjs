#requires -version 4
<#
.SYNOPSIS
  Customize Firefox Pref.js file to your needs

.DESCRIPTION
  This script allows you to modify you pref.js file to your needs at once using a preset files. 
  It creates a backup of your current configuration file into the profile folder and will not prompt you for writing confirmation.

  It is recommended to stop Firefox before running this script, otherwise the script will take care of that (Gently first, and with force after 5 seconds). 


.PARAMETER ConfigModPath
  You configuration file. Each parameter on a separate line using the exaxt same syntaxe

.INPUTS
  The file format for the ConfigModPath file is the following :
  "network.proxy.ftp_port", 80
  "network.proxy.http", "0.0.0.0"
  "network.proxy.http_port", 80
  "network.proxy.no_proxies_on", "localhost,    127.0.0.1,10.0.0.0/8,192.0.0.0/8"

  Each line is formated the same way it is into the Pref.js file except is does not include the "user_pref(" opening statement and the ");" closing statement.
  Existing paramters will be modified, other modification will be added at the end of the file.

  Please leaves double quotes where they are. 
  You can add comments to your Config File by adding the hash (#) character at the begining of each line.
  Empty lines will be skipped.
  

.OUTPUTS
  Writes modified configuration to Prefs.js file in your default Firefox profile

.NOTES
  Version:        1.0
  Author:         FingersOnFire
  Creation Date:  2020-07-19
  Purpose/Change: Initial script development

.EXAMPLE
  Set-FirefoxPreferences.ps1 -ConfigModPath C:\Temp\ConfigMod.txt
  
  Reads the file in the path ConfigModPath and apply changes to your default Firefox profile
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
		[Parameter(Position=0,mandatory=$true)]
        [string] $ConfigModPath
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------



#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Stop-Firefox {

    $firefox = Get-Process firefox -ErrorAction SilentlyContinue
    
    if ($firefox) {
        # try gracefully first
        $firefox.CloseMainWindow()
        # kill after five seconds
        Start-Sleep -s 5
        if (!$firefox.HasExited) {
            $firefox | Stop-Process -Force
        }
    }

    Remove-Variable firefox

}



#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host
Write-Host "-------------------------------"
Write-Host "|Firefox Prefs.js Modification|"
Write-Host "-------------------------------"

Write-Host
Write-Host "Testing Modification File"
if(-not(Test-Path($ConfigModPath))){
    Write-Host "Could not find modification file"
    Write-Host "Exiting now..."
    exit
}

Write-Host
Write-Host "Stopping Firefox"
Stop-Firefox

Write-Host
Write-Host "Looking for Firefox Profile"
$FFProfilePath = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object {$_.PSIsContainer -and $_.Name -match "\.default"}

if(-not(Test-Path($FFProfilePath.FullName))){
    Write-Host "Could not find a Firefox profile"
    Write-Host "Exiting now..."
    exit
}
else{
    Write-Host "Selected Profile :" $FFProfilePath.FullName
}

Write-Host
Write-Host "Looking for Firefox Preference File"
$FFPrefsJSPath = Join-Path -Path $FFProfilePath.FullName -ChildPath "prefs.js"

if(-not(Test-Path($FFPrefsJSPath))){
    Write-Host "Could not find file:" $FFPrefsJSPath
    Write-Host "Exiting now..."
    exit
}
else{
    Write-Host "Selected Preference File :" $FFPrefsJSPath
}

# 
$FFPrefsJSBackupFilename = "prefs" + (get-date).tostring(“yyyy-mm-dd-HH-mm-ss”) + ".js"
$FFPrefsJSBackupPath = Join-Path -Path $FFProfilePath.Fullname -ChildPath $FFPrefsJSBackupFilename

Write-Host
Write-Host "Creating a config backup:" $FFPrefsJSBackupPath
Copy-Item -Path $FFPrefsJSPath -Destination $FFPrefsJSBackupPath


Write-Host
Write-Host "Reading Firefox config file:" $FFPrefsJSPath
$FFPrefsJS = (Get-Content $FFPrefsJSPath)

Write-Host
Write-Host "Reading modification file:" $ConfigModPath
$ConfMod = (Get-Content $ConfigModPath)

Write-Host
Write-Host "Looping through modifications..."

foreach($ConfModLine in $ConfMod){

    # Skipping commented or empty lines
    if(($ConfModLine.StartsWith("#")) -or ($ConfModLine -eq "")){
        Continue
    }

    Write-Host

    $ConfID = $ConfModLine.Split(",")[0].Trim().Replace('"', '')
    $NewConfLine = 'user_pref(' + $ConfModLine + ');'

    $lineMatch = Select-String -Path $FFPrefsJSPath -Pattern $ConfID

    if(($lineMatch -eq "") -or ($lineMatch -eq $null)){
        Write-Host "No Match found for" $ConfID
        Write-Host "Adding new line:" $NewConfLine
        $FFPrefsJS += $NewConfLine;  
    }
    else{

        Write-Host "Config match for" $ConfID "found on line" $lineMatch.LineNumber
        Write-Host "Old line:" $lineMatch.Line
        Write-Host "New line:" $NewConfLine

        $FFPrefsJS[$lineMatch.lineNumber - 1] = $NewConfLine
    }

}

Write-Host
Write-Host "Writing content:" $FFPrefsJSPath
Set-Content $FFPrefsJSPath $FFPrefsJS