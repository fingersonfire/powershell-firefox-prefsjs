#requires -version 4
<#
.SYNOPSIS
  Customize Firefox Settings files to your needs

.DESCRIPTION
  This script allows you to modify your user.js or prefs.js files to your needs using template files. 
  It creates a backup of your current configuration file into the profile folder and will not prompt you for writing confirmation.

  It is mandatory to run the script when Firefox is stopped. We recommend you to close the app before. 
  This script will looks for running instances and stop them also (Gently first, and with force after 5 seconds). 

  The script will modify existing user preferences and add new ones at the end of the file.

.PARAMETER ConfigModPath
  String path configuration file. Each parameter on a separate line using the exaxt same syntaxe

.PARAMETER ModifyPrefsJS
  Switch to modify prefs.js instead of user.js

.INPUTS
  The file format for the ConfigModPath file is the following :
  "network.proxy.ftp_port", 80
  "network.proxy.http", "0.0.0.0"
  "network.proxy.http_port", 80
  "network.proxy.no_proxies_on", "localhost,    127.0.0.1,10.0.0.0/8,192.0.0.0/8"

  Each line is formated the same way it is into the Pref.js file except is does not include the "user_pref(" opening statement and the ");" closing statement.

  Please leaves double quotes in place as it defines whether it defines a string value. 
  You can add comments to your Config File by adding double forward slashes (//) at the begining of each line.
  Empty lines will be skipped.
  

.OUTPUTS
  Writes modified configuration to User.js or Prefs.js file in your default Firefox profile

.NOTES
  Version:        1.1
  Author:         FingersOnFire
  Creation Date:  2020-07-19
  Purpose/Change: Add ModifyPrefsJS switch. Use double forward slash for comments instead of hash (#)

.EXAMPLE
  Set-FirefoxPreferences.ps1 -ConfigModPath C:\Temp\ConfigMod.txt  
  Reads the file in the path ConfigModPath and apply changes to your default Firefox profile User.js file

  Set-FirefoxPreferences.ps1 -ConfigModPath C:\Temp\ConfigMod.txt -ModifyPrefsJS
  Reads the file in the path ConfigModPath and apply changes to your default Firefox profile Prefs.js
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
		[Parameter(Position=0,mandatory=$true)]
        [string] $ConfigModPath,

        [Parameter(Mandatory=$false)]
        [Switch]$ModifyPrefsJS
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
Write-Host "----------------------------------"
Write-Host "|Firefox Preferences Modification|"
Write-Host "----------------------------------"

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
$FFUserJSPath = Join-Path -Path $FFProfilePath.FullName -ChildPath "user.js"
$FFSelectedPreferenceFile = ""


if($ModifyPrefsJS){
    if(-not(Test-Path($FFPrefsJSPath))){
        Write-Host "Could not find file:" $FFPrefsPath
        Write-Host "Exiting now..."
        exit
    }
    else{
        Write-Host "Selected Preference File :" $FFPrefsJSPath
        Write-Warning "Your are editing the main Prefs.js files"
        $FFSelectedPreferenceFile = $FFPrefsJSPath
    }
}
else{
    if(-not(Test-Path($FFUserJSPath))){
        Write-Host "User.js not found:" $FFUserJSPath
        New-Item -Path $FFProfilePath.FullName -Name "user.js" -ItemType "file" -Value "// Firefox User Preferences`r`n"
    }

    Write-Host "Selected Preference File :" $FFUserJSPath
    $FFSelectedPreferenceFile = $FFUserJSPath
}

# Backup of the selected configuration file
$FFPrefsBackupPath = $FFSelectedPreferenceFile + "." + (get-date).tostring(“yyyy-mm-dd-HH-mm-ss”) + ".bak"

Write-Host
Write-Host "Creating a config backup:" $FFPrefsBackupPath
Copy-Item -Path $FFSelectedPreferenceFile -Destination $FFPrefsBackupPath


Write-Host
Write-Host "Reading config file:" $FFSelectedPreferenceFile
[Array]$FFPrefs = (Get-Content $FFSelectedPreferenceFile)

Write-Host
Write-Host "Reading modification file:" $ConfigModPath
$ConfMod = (Get-Content $ConfigModPath)

Write-Host
Write-Host "Looping through modifications..."

foreach($ConfModLine in $ConfMod){

    # Skipping commented or empty lines
    if(($ConfModLine.StartsWith("//")) -or ($ConfModLine -eq "")){
        Continue
    }

    Write-Host

    $ConfID = $ConfModLine.Split(",")[0].Trim().Replace('"', '')
    $NewConfLine = 'user_pref(' + $ConfModLine + ');'

    $lineMatch = Select-String -Path $FFSelectedPreferenceFile -Pattern $ConfID

    if(($lineMatch -eq "") -or ($lineMatch -eq $null)){
        Write-Host "No Match found for" $ConfID
        Write-Host "Adding new line:" $NewConfLine
        $FFPrefs += $NewConfLine;  
    }
    else{

        Write-Host "Config match for" $ConfID "found on line" $lineMatch.LineNumber
        Write-Host "Old line:" $lineMatch.Line
        Write-Host "New line:" $NewConfLine

        $FFPrefs[$lineMatch.lineNumber - 1] = $NewConfLine
    }

}

Write-Host
Write-Host "Writing content:" $FFSelectedPreferenceFile
Set-Content $FFSelectedPreferenceFile $FFPrefs