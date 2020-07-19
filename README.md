# powershell-firefox-prefsjs
A powershell script that modifies your default Firefox preferences file based on a modification file template.

This script allows you to modify your user.js or prefs.js files to your needs using template files. 
It creates a backup of your current configuration file into the profile folder and will not prompt you for writing confirmation.

It is mandatory to run the script when Firefox is stopped. We recommend you to close the app before. 
This script will looks for running instances and stop them also (Gently first, and with force after 5 seconds). 

The script will modify existing user preferences and add new ones at the end of the file.

## Usage
The script has two parameters
- ConfigModPath : The path to the template you want to apply
- ModifyPrefsJS : To force the update of the Prefs.js file which is usualy managed by Firefox. User.js will be used should you not add this switch paramter.

### Example
Set-FirefoxPreferences.ps1 -ConfigModPath C:\Temp\ConfigMod.txt  
Reads the file in the path ConfigModPath and apply changes to your default Firefox profile User.js file

Set-FirefoxPreferences.ps1 -ConfigModPath C:\Temp\ConfigMod.txt -ModifyPrefsJS
Reads the file in the path ConfigModPath and apply changes to your default Firefox profile Prefs.js

## Template File Format

The file format for the ConfigModPath file is the following :

´"network.proxy.ftp_port", 80
"network.proxy.http", "0.0.0.0"
"network.proxy.http_port", 80
"network.proxy.no_proxies_on", "localhost,    127.0.0.1,10.0.0.0/8,192.0.0.0/8"´

Each line is formated the same way it is into the Pref.js file except is does not include the "user_pref(" opening statement and the ");" closing statement.

Please leaves double quotes in place as it defines whether it defines a string value. 
You can add comments to your Config File by adding double forward slashes (//) at the begining of each line.
Empty lines will be skipped.

## Disclaimer
This script can modify the Prefs.js file which is not intended by Mozilla.
The creation and modification of the user.js file will be implemented later as an option.

As usual, you are using this script as your own risks (Even if a backup of your current config is made by the script ;) )

## Some more information
http://kb.mozillazine.org/User.js_file

## Interesting related projects
https://github.com/pyllyukko/user.js/
