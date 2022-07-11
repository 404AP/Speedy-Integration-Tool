
#Raise to Admin Rights 

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


#Ask for the internet

$connected = $null

while (!($connected -eq "Y")) {

    $connected = $null

    if (Test-Connection -IPAddress google.com -Count 1 -ErrorAction SilentlyContinue) 
        {$connected = "Y"} 
        else { $connected = "N"}

    if (($connected -eq "N") -or !(($connected -eq "Y") -or ($connected -eq "N"))){

        Start-Process ms-availablenetworks:

        $connected = Read-Host - Prompt "Did you connect to the internet? (Y/N)"

        if ( !(($connected -eq "Y") -or ($connected -eq "N"))) {
            Write-Host "wrong input"
        } 
    }

}

#install Package 

Install-PackageProvider -Name NuGet -force | Out-Null



#Define Global Vars at the begining of the file

$global:powerButton = 100

#define function in the begining of the file , before the action 

function Exit-Program {
    $global:powerButton = Read-Host -Prompt "Are you shure you wan to Delete the script and installers? Type 'Y' to keep going , Type 'N' to go back"

    if ($global:powerButton -eq 'Y') {
        $global:powerButton = $null
        Remove-Item -Path "C:\Users\Public\Desktop\script.lnk" -Force
        Remove-Item -Path "$PSScriptRoot" -Force -Recurse
        
    }elseif ( !(($global:powerButton -eq 'Y') -or ($global:powerButton -eq 'N'))) {
        $global:powerButton = "Exit"
        Write-Host "wrong input"
    }   
}

function Test-Rename {

    $serialnumber = (Get-CimInstance -ClassName Win32_SystemEnclosure -Property SerialNumber).SerialNumber
    $PCST = (Get-CimInstance -ClassName Win32_ComputerSystem -Property PCSystemType).PCSystemType
    $Prefix = Read-Host -Prompt "Input Company Prefix"
    $Suffix = $null


    
    while (!($Suffix)) {
        if ($PCST -eq 2) {
            $Suffix = "LT"
        } elseif (($PCST -eq 1) -or ($PCST -eq 3)) {
            $Suffix = "DT"
        }elseif ( !(($PCST -eq 1) -or ($PCST -eq 2) -or ($PCST-eq 3))) {
            Write-Host "The Bios couldnt tell us if this was a Desktop or Laptop"
            While (!(($PCST -eq 1) -or ($PCST -eq 2))) {
            $PCST = Read-Host -Prompt "Type 1 for Desktop or 2 for Laptop"
            }
        } 
    }


    $name = "$Prefix-$serialnumber-$suffix"

    1


    Rename-Computer -NewName $name | Out-Null

    Write-Host "System has been renamed: $name"
}

function Test-RunUpdates {
    Write-Host "** This computer will AUTO REBOOT after installing these updates if Required**" -BackgroundColor Black -ForegroundColor Red

    Install-Module PSWindowsUpdate -Force -Scope CurrentUser | Out-Null
    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll 
    
    #Write-Host "Ran Updates"
}


function  Test-RunOEMUpdates {

    #Dell or Lenovo

    $OEM = (Get-ComputerInfo -Property CsManufacturer).CsManufacturer

    if ( $OEM -eq "LENOVO") {
        
        $installerRan = 0

        while (!(Test-Path "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe")) {
        
            if ($installerRan -eq 0) {
                Write-Host "Running the Installer"
                Start-Process -FilePath "$PSScriptRoot/lenovo.exe" -Verb runAs  -ArgumentList "/s /qs"  -ErrorAction SilentlyContinue
                $installerRan = 1
            }
            Write-Host "Waiting for Installer"
            Start-Sleep -s 10
        }
        Write-Host "Waiting for files to finish installing will run OEM updates any second now"
        Start-Sleep -s 15
        Start-Process -FilePath "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe" -ErrorAction SilentlyContinue

    } elseif ($OEM -eq "DELL") {

        Start-Process -FilePath "$PSScriptRoot/dell.exe" -Verb runAs  -ArgumentList "/s /qs"  -ErrorAction SilentlyContinue
        Start-Process -FilePath "C:\Program Files (x86)\Dell\CommandUpdate\DellCommandUpdate.exe" -verb runas -ErrorAction SilentlyContinue

    } else {
        Write-Host "System not Supported!"
    }    
    
}


#Download Datto RMM and delete the installer once it is installed 
#Also validates the input on three Levels 
function Test-InstallDatto {

    $g2g = $null

    
    while (!($g2g)) {
        Write-Host "Shorten the Link from Datto using Bit.ly on another Computer"
        $url = Read-Host -Prompt "What is the Bit Code after shortening? https://bit.ly/"
        $url = "https://bit.ly/" + $url
        if ($url -like "*bit.ly*"){
            try {

                $HTTP_Request = [System.Net.WebRequest]::Create($url)

                $HTTP_Response = $HTTP_Request.GetResponse()

                $HTTP_Status = [int]$HTTP_Response.StatusCode

            }

            catch {

                Write-Host "Is this a real site?"
            }

            if ($HTTP_Status -eq 200) {

                $g2g = "True"
                
            } else {

                Write-Host "Invalid Link"
            }

            $HTTP_Response.close()
        } else { 
            Write-Host "Link Not Shortened Correctly"
        }
    }


    $output = "$PSScriptRoot\datto.exe"


    try {


        Start-BitsTransfer -Source $url -Destination $output -ErrorAction stop

        Start-Process $output -ErrorAction Stop
        Start-Sleep -Seconds 10
        Remove-Item $output -ErrorAction Stop
        


    } catch {
        Write-Host "Download Unsuccesful Please check the link"
    }


    Start-Sleep -Seconds 15
    
    Remove-Item $output
        
    
}




function Test-UninstallApps {
    Start-Process appwiz.cpl
    Start-Process ms-settings:appsfeatures
}

function Test-MoveIcons {

    $paths = @("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk",
     "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk",
     "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk",
     "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk")
    for ($i=0; $i -lt 4 ;$i++) {
        
        
        $path = $paths[$i]
        
        if (Test-Path -Path $path) {

            Copy-Item $path -Destination C:\users\Public\Desktop  

        } else {

            Write-Host "Can't Find -$path"
        }

    }
}

function Shortcut {

    # Create a Shortcut with Windows PowerShell
    $SourceFileLocation = "$PSScriptRoot\testV4-7.ps1"
    $ShortcutLocation = "C:\Users\Public\Desktop\script.lnk"
    #New-Object : Creates an instance of a Microsoft .NET Framework or COM object.
    #-ComObject WScript.Shell: This creates an instance of the COM object that represents the WScript.Shell for invoke CreateShortCut
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    $Shortcut.TargetPath = $SourceFileLocation
    $Shortcut.Arguments = 'powershell -ExecutionPolicy Bypass -File'
    #Save the Shortcut to the TargetPath
    $Shortcut.Save()
}

function Test-ListSystemInfo {
    systeminfo
}

#Creating a while Loop to put the program in 

Write-Host "
   ____                __       ____     __                    __  _             ______          __
  / __/__  ___ ___ ___/ /_ __  /  _/__  / /____ ___ ________ _/ /_(_)__  ___    /_  __/__  ___  / /
 _\ \/ _ \/ -_) -_) _  / // / _/ // _ \/ __/ -_) _  / __/ _  / __/ / _ \/ _ \    / / / _ \/ _ \/ /
/___/ .__/\__/\__/\_,_/\_, / /___/_//_/\__/\__/\_, /_/  \_,_/\__/_/\___/_//_/   /_/  \___/\___/_/  
   /_/                /___/                   /___/"
Write-Host "by AP"





While ($global:powerButton) {

    #if power button is not equal to case sensitive 

    if ($global:powerButton -cne "IDK"){
        Write-Host "
        Main Menu:
        |0 - Create Desktop Shortcut
        |1 - Rename Computer
        |2 - Run Windows Updates
        |3 - Run OEM Updates 
        |4 - Uninstall Bloat Programs/Apps
        |5 - Install Datto
        |6 - Move Icons the Desktop
        |7 - List Computer Info 

    
         [To Self Destruct type 'Clean Up'] "
        
        $global:powerbutton = Read-Host -Prompt "Selection(1-6)"
    }


    if ($global:powerButton -eq "") {
        Break
    } elseif ($global:powerButton -eq 0) {
        Shortcut 
    } elseif ($global:powerButton -eq 1) {
        Test-Rename 
    } elseif ($global:powerButton -eq 2) {
        Test-RunUpdates
    } elseif ($global:powerButton -eq 3) {
        Test-RunOEMUpdates
    } elseif ($global:powerButton -eq 4) {
        Test-UninstallApps
    } elseif ($global:powerButton -eq 5) {
        Test-InstallDatto  
    } elseif ($global:powerButton -eq 6) {
        Test-MoveIcons   
    } elseif ($global:powerButton -eq 7) {
        Test-ListSystemInfo   
    } elseif ($global:powerButton -eq "Clean Up") {
        Exit-Program   
    }
    
}



Start-Sleep -seconds 1

Write-Host "Exiting the Program"