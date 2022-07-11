
#Raise to Admin Rights 

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#Ask for the internet

Write-Host "Attempting to Connect to the Internet"



$connected = $null

while (!($connected -eq "Y")) {

    $connected = $null

    if (Test-Connection -IPAddress google.com -Count 1 -ErrorAction SilentlyContinue) 
        {$connected = "Y"
            Write-Host "Connection Confirmed"
        } 
        else { $connected = "N"}

    if (($connected -eq "N") -or !(($connected -eq "Y") -or ($connected -eq "N"))){


        $net = $null

        while (!(($net -eq 1) -or ($net -eq 2))) {

            $net = Read-Host "Could not connect to the Internet. Do you want to cannect via lan or wifi? 1- LAN 2-WIFI"
    

        }

        if ($net -eq 1) {

            Write-Host "Turning on Ethernet Adapter"

            Get-NetAdapter -Name Local* , Ethernet* | enable-NetAdapter -Confirm:$false
    
            Start-Sleep 10 

        } else {
            Write-Host "Checking for Available Networks"

            Start-Process ms-availablenetworks:

            Read-Host -Prompt "Press Enter to Confirm Connecton"

            Write-Host "Confiming Connection ......"

            Start-Sleep 10

        }
        
    }

}

#install Package 

Install-PackageProvider -Name NuGet -force | Out-Null



#Define Global Vars at the begining of the file

$global:powerButton = 100

#define function in the begining of the file , before the action 


#bypass OOBE

if (!(Test-Path "C:\unattend.xml")) {

    #copy file from NAS to the C:

    Write-Host "Checking For Connection to Bench NAS"

    if (Test-Connection -IPAddress "\\172.16.99.10" -Count 1 -ErrorAction SilentlyContinue ){

        Write-Host "Copying the Unattend.xml to the C: drive from Bench NAS"
        Copy-Item -path "\\172.16.99.10\Script\custom Wim\unattend.xml" -Destination "C:\" -ErrorAction Stop 
    } else {
        Write-Host "Can not bypass OOBE because you are not on bench NAS"
    }


    #turn off the network adapters

    Write-Host "Disabling the Network Before Reboot"

    Get-NetAdapter *Ethernet , *LAN , *Wi-fi | Disable-NetAdapter -Confirm:$false



    #run commannd for Sysprep

    Write-Host "Running Sysprep Commands"
    & Env:\windir\system32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\unattend.xml











}








#Exit-Program
#This function cleans up the script on the client machine and deletes the desktop shortcut

function Exit-Program {
    $global:powerButton = Read-Host -Prompt "Are you sure you wan to Delete the script and installers? Type 'Y' to keep going , Type 'N' to go back"

    if ($global:powerButton -eq 'Y') {
        $global:powerButton = $null
        Remove-Item -Path "C:\Users\Public\Desktop\script.lnk" -Force -ErrorAction SilentlyContinue

        #this refreshes the desktop using the f5 key
        
        $shell = New-Object -ComObject Shell.Application
        $shell.minimizeall()
        start-sleep 1
        $wsh = New-Object -ComObject Wscript.Shell
        $wsh.sendkeys('{#}D')
        $wsh.sendkeys('{F5}')


        Remove-Item -Path "$PSScriptRoot" -Force -Recurse
        
    }elseif ( !(($global:powerButton -eq 'Y') -or ($global:powerButton -eq 'N'))) {
        $global:powerButton = "Exit"
        Write-Host "wrong input"
    }   
}

function Test-Rename {


    $type = $null
    $Suffix = $null
    $PCST = (Get-CimInstance -ClassName Win32_ComputerSystem -Property PCSystemType).PCSystemType

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

    while (!(($type -eq 1) -or ($type -eq 2))){
        Write-Host "Examples:   Prefix-> CSG-XXXXXX-LT   CUSTOM - FIRSTLAST-LT"
        $type = Read-Host -Prompt "What type of name do you need? 1.Prefix  2.Custom"
    }


    if ($type -eq 1) {
        $serialnumber = (Get-CimInstance -ClassName Win32_SystemEnclosure -Property SerialNumber).SerialNumber
        $Prefix = Read-Host -Prompt "Input Company Prefix"
        $name = "$Prefix-$serialnumber-$suffix"
    } else {
        $check = $null
        $customName =$null
        While (!($check)){
            $customName = Read-Host -Prompt "Enter Custom Name less than 12 Characters"
            if ($customName.Length -le 12) {
                $check = $true
            } else {
                Write-Host "Name is too long. Please try again"
            }
        }
        
        $name = "$customName-$suffix"
    }



    

    


    Rename-Computer -NewName $name | Out-Null

    Write-Host "System has been renamed: $name"
}

function Test-RunUpdates {
    net stop wuauserv | Out-Null
    net Start wuauserv
    
    
    Write-Host "** Select NO for auto reboot if you want to install OEM updates before Reboot**" -BackgroundColor Black -ForegroundColor Red



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
                Start-Process -FilePath "$PSScriptRoot/lenovo.exe" -Verb runAs  -ArgumentList "/verysilent /norestart"  -ErrorAction SilentlyContinue
                $installerRan = 1
            }
            Write-Host "Waiting for Installer"
            Start-Sleep -s 10
        }
        Write-Host "Waiting for files to finish installing . Running OEM updates momentarily"
 

        ##### Set SU AdminCommandLine
        $RegKey = "HKLM:\SOFTWARE\Policies\Lenovo\System Update\UserSettings\General"
        $RegName = "AdminCommandLine"
        $RegValue = "/CM -search R -action INSTALL -includerebootpackages 1,3,4 -noicon -nolicense"

        # Create Subkeys if they don't exist
        if (!(Test-Path $RegKey)) {
            New-Item -Path $RegKey -Force | Out-Null
            New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue | Out-Null
        }
        else {
            New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue -Force | Out-Null
        }

        ##### Configure SU interface
        $ui = "HKLM:\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General"
        $values = @{

            "AskBeforeClosing"     = "NO"

            "DisplayLicenseNotice" = "NO"

            "MetricsEnabled"       = "NO"
                                    
            "DebugEnable"          = "YES"

        }

        if (Test-Path $ui) {
            foreach ($item in $values.GetEnumerator() ) {
                New-ItemProperty -Path $ui -Name $item.Key -Value $item.Value -Force |Out-Null
            }
        }


        
        $su = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Lenovo\System Update\tvsu.exe"
        &$su /CM | Out-Null
        Write-Host "****System will Restart any second now****" -ForegroundColor Yellow -BackgroundColor Black


        
    } elseif ($OEM -eq "DELL Inc.") {

        $installerRan = 0

        while (!((Test-Path "C:\Program Files (x86)\Dell\CommandUpdate\DellCommandUpdate.exe") -or (Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"))) {
        
            if ($installerRan -eq 0) {
                Write-Host "Running the Installer"
                Start-Process -FilePath "$PSScriptRoot/DELL.exe" -Verb runAs  -ArgumentList "/s"  -ErrorAction SilentlyContinue
                $installerRan = 1
            }
            Write-Host "Waiting for Installer"
            Start-Sleep -s 5
        }
        Write-Host "Waiting for files to finish installing will run OEM updates any second now"
        Start-Sleep -s 5
        if (Test-Path  "C:\Program Files (x86)\Dell\CommandUpdate\DellCommandUpdate.exe" ) {
            Start-Process -FilePath "C:\Program Files (x86)\Dell\CommandUpdate\DellCommandUpdate.exe" -ErrorAction SilentlyContinue
        } else {
            Start-Process -FilePath "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates" -ErrorAction SilentlyContinue
        }
        


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

        if (!(Test-Path 'C:\Program Files (x86)\CentraStage')){
            Write-Host "Download Unsuccesful Please check the link"
        }
        
    }
    
}




function Test-UninstallApps {

    Write-Host "Attempting to Uninstall Known Bloat Programs"
    #turn off the progress bars
    $default = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"


    Get-AppxPackage *xboxapp* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *windowsphone* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *onenote* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *zunevideo* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *zunemusic* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *skypeapp* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *officehub* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *solitaire* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *partnerpromo* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *dellpower* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *delloptim* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *mcafee* Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *spotify* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *disney* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *amazon* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *dropbox* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *netflix* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage *wallet* | Remove-AppxPackage -ErrorAction SilentlyContinue
    


    if (Test-Path "C:\Program Files\PCHealthCheck") {
        Write-Host "Running Windows PC Health Check Uninstall"
        Stop-Process -name "PCHealthCheck" -ErrorAction SilentlyContinue
        Start-Sleep 3
        wmic product where "name = 'Windows PC Health Check'" call Uninstall /nointeractive | Out-Null
        Remove-Item -Path 'C:\Program Files\PCHealthCheck' -ErrorAction SilentlyContinue
    }

    if (Test-Path "C:\Program Files (x86)\DELL\DellOptimizer") {
        Write-Host "Running Dell Optimizer Uninstall"
        wmic product where "name = 'Dell Optimizer'" call Uninstall /nointeractive 
        wmic product where "name = 'Dell OptimizerUI'" call Uninstall /nointeractive |Out-Null
        Remove-Item -Path 'C:\Program Files (x86)\DELL\DellOptimizer' -ErrorAction SilentlyContinue
    }

    if (Test-Path "C:\Program Files\DELL\CommandPowerManager") {
        Write-Host "Running Dell Power Manager Uninstall"
        wmic product where "name = 'Dell Power Manager Service'" call Uninstall /nointeractive | Out-Null
        Remove-Item -Path 'C:\Program Files\DELL\CommandPowerManager' -ErrorAction SilentlyContinue
    }


    if(Test-Path "C:\Program Files (x86)\expressvpn") {
        Write-Host "Running Expess VPN Uninstall"
        Stop-Process -name "ExpressVPNd" -ErrorAction SilentlyContinue | Out-Null
        Stop-Process -name "ExpressVPNNotificationService" -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Path 'C:\ProgramData\Package Cache\{ebd248cd-b3ef-4e14-b91a-d626fa5c392a}' | Out-Null
        Start-Sleep 3
        wmic product where "name = 'ExpressVPN'" call Uninstall /nointeractive 

        Remove-Item -Path 'C:\Program Files (x86)\expressVPN' -ErrorAction SilentlyContinue
    }


    
    if ((test-path "C:\Program Files\McAfee.com") -or (Test-Path "C:\Program Files\McAfee" )) {

        Write-Host "Running Mcafee Uninstall Protocol"
        Get-AppxPackage *mcafee* | Remove-AppxPackage -ErrorAction SilentlyContinue
        Set-Location "$psscriptroot\killmcafee"
	    .\Mccleanup.exe -p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s
        Set-Location $PSScriptRoot
        Remove-Item -Path "C:\Program Files\McAfee.com" -force -recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Program Files\McAfee" -force -recurse -ErrorAction SilentlyContinue

    
    }


    

    $ProgressPreference = $default
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
    $SourceFileLocation = "$PSCommandPath"
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