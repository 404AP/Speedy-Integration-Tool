
#Ask for Admin
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

            Get-NetAdapter -Name Wi-Fi* | Enable-NetAdapter -Confirm:$false

            Start-Process ms-availablenetworks:

            Read-Host -Prompt "Press Enter to Confirm Connecton"

            Write-Host "Confiming Connection ......"

            Start-Sleep 10

        }
        
    }

}

#install Package 

Install-PackageProvider -Name NuGet -force | Out-Null


#     #run this script at next logon using custom batch

if (!(Get-ScheduledTask *Speedy-Integration-Alarm*)) {
    $su = "$PSScriptRoot\test.bat"
    $sa = "$PSScriptRoot\set.bat"
    $user = $env:USERNAME

    $taskAction = New-ScheduledTaskAction -Execute $su 
    $taskAction2 = New-ScheduledTaskAction -Execute $sa
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn  
    $taskUserPrincipal = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest 
    $taskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries 
    $task = New-ScheduledTask -Action $taskAction2 , $taskAction -Principal $taskUserPrincipal -Trigger $taskTrigger -Settings $taskSettings
    Register-ScheduledTask -TaskName 'Speedy-Integration-Alarm' -InputObject $task  -Force | Out-Null
        
}


function checker {

    $global:pass = Get-Content $global:varpath
    $count = 0
    #check for Rename PC
    $checkingVar = $global:pass[1]
    if ([int]([string]($global:pass[1][-1])) -gt 0) {
        Write-Host "PC has been Renamed"
        $count++

    } else {
        Write-Host "PC has not been Renamed"
    }



    #check for OEM updates 
    $checkingVar = $global:pass[1]
    if([int]([string]($global:pass[6][-1])) -gt 0){
        Write-Host "OEM Updates have been Installed"
        $count++
    } else {
        Write-Host "Still Working on OEM Updates"
    }



    #check for Windows Updates 
    $checkingVar = $global:pass[1]
    if([int]([string]($global:pass[5][-1])) -gt 0){
        Write-Host "Windows Updates have been installed"
        $count++
    } else {
        Write-Host "Still Working on Windows Updates"
    }



    #check for Bloat Programs 
    $checkingVar = $global:pass[7]
    if([int]([string]($global:pass[7][-1])) -gt 0){
        Write-Host "Bloat Programs have been Remvoved"
        $count++
    } else {
        Write-Host "Still Working on Bloat Programs"
    }



    #check if Datto is Installed
    $checkingVar = $global:pass[8]
    if (Test-Path 'C:\Program Files (x86)\CentraStage') {
        $editvar = $global:pass[8]
        $global:pass = $global:pass -replace "$editvar", "DATTOINSTALLED:1" 
        Set-Content -Path $global:varpath $global:pass |Out-Null
    }
    if([int]([string]($global:pass[8][-1])) -gt 0){
        Write-Host "Datto is Installed"
        $count++
    } else {
        Write-Host "Still Working on Datto"
    }



    #check if Date and Time is Set 
    $checkingVar = $global:pass[10]
    if([int]([string]($global:pass[10][-1])) -gt 0){
        Write-Host "Date and Time are set"
        $count++
    } else {
        Write-Host "Still need to set date and time"
    }


    #check if #365 is install and staged 
    if(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk") {
        $editvar = $global:pass[12]
        $global:pass = $global:pass -replace "$editvar", "DOES365EXIST:1" 
        Set-Content -Path $global:varpath $global:pass |Out-Null
    }

    $checkingVar = $global:pass[12]
    if([int]([string]($global:pass[12][-1])) -gt 0){
        Write-Host "365 is Installed"
        $count++


        if (!(Test-Path "C:\users\public\desktop\excel.lnk")){

                Write-Host "Staging the Desktop"
                
                $paths = @("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk",
                    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk",
                    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk",
                    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk")
                for ($i=0; $i -lt 4 ;$i++) {
                        
                        
                        $path = $paths[$i]
                        
                        if (Test-Path -Path $path) {
                
                            Copy-Item $path -Destination "C:\users\Public\Desktop"  
                
                        } else {
                
                            Write-Host "Can't Find -$path"
                        }
                
                }

                $editvar = $global:pass[13]
                $global:pass = $global:pass -replace "$editvar", "DESKTOPSTAGED:1" 
                Set-Content -Path $global:varpath $global:pass |Out-Null

                $count++
            } else {
                 Write-Host "Desktop is Staged "
            }
             



    } else {
        Write-Host "Still Working on 365"
    }

    

    #check if this should be marked Completed

    
    
    if($count -ge 7){
        Write-Host "Integration Complete"
        $global:powerButton = $null
        Start-Process powercfg -ArgumentList "/change monitor-timeout-ac 15" -ErrorAction SilentlyContinue
        Start-Process powercfg -ArgumentList "/change monitor-timeout-dc 5" -ErrorAction SilentlyContinue
        Start-Process powercfg -ArgumentList "/change stanby-timeout-ac 30" -ErrorAction SilentlyContinue
        Start-Process powercfg -ArgumentList "/change stanby-timeout-dc 15" -ErrorAction SilentlyContinue
        Unregister-ScheduledTask *Speedy-Integration-Alarm -ErrorAction SilentlyContinue | Out-Null
        Set-ExecutionPolicy RemoteSigned | Out-Null
        #this refreshes the desktop using the f5 key
        
        $shell = New-Object -ComObject Shell.Application
        $shell.minimizeall()
        start-sleep 1
        $wsh = New-Object -ComObject Wscript.Shell
        $wsh.sendkeys('{#}D')
        $wsh.sendkeys('{F5}')


        Remove-Item -Path "$PSScriptRoot" -Force -Recurse
    }


}





#set-InstallDatto : Download Datto RMM 
#Also validates the input on three Levels 

function set-DattoCode {

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
                $editvar = $global:pass[3]
                $global:pass = $global:pass -replace "$editvar", "BITLYCODE:$url" 
                $editvar = $global:pass[1]
                $global:pass = $global:pass -replace "$editvar", "didUSRINPUT:1" 
                Set-Content -Path $global:varpath $global:pass | Out-Null
                
            } else {

                Write-Host "Invalid Link"
            }

            $HTTP_Response.close()
        } 
        
        
        if ($url -eq "https://bit.ly/skip") {
            $g2g = "True"
            $editvar = $global:pass[8]
            $global:pass = $global:pass -replace "$editvar", "DATTOINSTALLED:1" 
            Set-Content -Path $global:varpath $global:pass |Out-Null

        } 
    }

    
    $output = "$PSScriptRoot\datto.exe"
    $url = $global:pass[3]
    $url = $url -replace "BITLYCODE:" , "" 


    try {


        Start-BitsTransfer -Source $url -Destination $output -ErrorAction stop





        
        Start-Process $output -ErrorAction Stop
        Start-Sleep -Seconds 10
        Remove-Item $output -ErrorAction Stop
        

        $editvar = $global:pass[8]
        $global:pass = $global:pass -replace "$editvar", "DATTOINSTALLED:1" 
        Set-Content -Path $global:varpath $global:pass |Out-Null


    } catch {

        if (!(Test-Path 'C:\Program Files (x86)\CentraStage')){
            Write-Host "Download Unsuccesful Please check the link"
        }
        
    }
    
}


#Test-Rename
#this funtion renames the computer and  attaches an identifier based the type of computer DT or LT
function Test-Rename {
    $global:pass = Get-Content $global:varpath
    $checkingVar = $global:pass[1]

    if(([int]([string]($global:pass[1][-1])) -lt 1)){

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

        while (!(($type -eq 1) -or ($type -eq 2) -or ($type -eq 3))){
            Write-Host "Examples:   Prefix-> CSG-XXXXXX-LT   NAME - FIRSTLAST-LT   CUSTOM - SVR-TEAM"
            $type = Read-Host -Prompt "What type of name do you need? 1.Prefix  2.NAME  3.Custom"
        }


        if ($type -eq 1) {
            $serialnumber = (Get-CimInstance -ClassName Win32_SystemEnclosure -Property SerialNumber).SerialNumber
            $Prefix = Read-Host -Prompt "Input Company Prefix"
            $name = "$Prefix-$serialnumber-$suffix"


        } if($type -eq 2) {
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
        }if($type -eq 3) {
            $check = $null
            $customName =$null
            While (!($check)){
                $customName = Read-Host -Prompt "Enter Custom Name less than 15 Characters"
                if ($customName.Length -le 15) {
                    $check = $true
                } else {
                    Write-Host "Name is too long. Please try again"
                }
            }
            
            $name = $customName
        }

        Rename-Computer -NewName $name | Out-Null

        #update the pass.txt to indicate the computer has been Renamed 

        $editvar = $global:pass[4]
    
        $global:pass = $global:pass -replace $editvar, "COMPUTERNAME:$name" 
     
        Set-Content -Path $global:varpath $global:pass | Out-Null




        Write-Host "System has been renamed: $name"
    }    
}







#Creating a while loop to put the program in 

$global:powerButton = $true
$global:hostname = $null
$global:dattoCode = $null 
$global:preloaded = $null
$global:varpath = "$PSScriptRoot\pass.txt"
$global:pass = Get-Content $global:varpath

while ($global:powerButton) {

    checker
    #check pass.txt for status 

    #check if we got usr input 
    #this means that if didUserInput: is set to greater less than one then we should get the initial
    #user info we need to integrate the computer
    
    if (([int]([string]($global:pass[1][-1])) -lt 1) -or ([int]([string]($global:pass[8][-1])) -lt 1)) {
        #get user input 
        
        Test-Rename
        set-DattoCode
        Write-Host "Setting Date and Time to Eastern Standard Time"
        Set-TimeZone -Name "Eastern Standard Time"
        $editvar = $global:pass[10]
        $global:pass = $global:pass -replace "$editvar", "DATE/TIMESET:1" 
        Set-Content -Path $global:varpath $global:pass |Out-Null


        
    
    
        Write-Host "Adjusting Sleep wake settings to Never Sleep"
        Start-Process powercfg -ArgumentList "/change monitor-timeout-ac 0" -ErrorAction SilentlyContinue
        Start-Process powercfg -ArgumentList "/change monitor-timeout-dc 0" -ErrorAction SilentlyContinue
        Start-Process powercfg -ArgumentList "/change stanby-timeout-ac 0" -ErrorAction SilentlyContinue
        Start-Process powercfg -ArgumentList "/change stanby-timeout-dc 0" -ErrorAction SilentlyContinue

        
    }

    #Check if windows updates are done and run OEM
    if([int]([string]($global:pass[5][-1])) -lt 1) {
        
 
        # $powershellPath = "$env:windir\system32\windowspowershell\v1.0\powershell.exe"
        # $process = Start-Process $powershellPath  -ArgumentList ("-ExecutionPolicy Bypass -noninteractive -noprofile " + $scriptBlock) -PassThru
        
        #opening up new window for winupdates 
        Start-Process powershell "$PSscriptroot\runwinupdate.ps1" -WindowStyle Minimized 
    }
     #Run OEM Updates 
    if([int]([string]($global:pass[6][-1])) -lt 1) {

        $oemstatus = $null
        while (!(($oemstatus -eq 0) -or ($oemstatus -eq 1))) {
        Write-Host "If you skip you will not be prompted again for OEM updates" -BackgroundColor Black -ForegroundColor Red
        Write-Host "Are you ready to run OEM updates?"
        Start-Sleep -Milliseconds 300
        $oemstatus = Read-Host " Type '1' to get started and '0' to skip this step if you have already run it OR if the computer is not supported"                  
        }
        if ($oemstatus -eq 1) {
            Start-Process powershell "$PSscriptroot\oemupdates.ps1" -WindowStyle Minimized
        } else {
            $editvar = $global:pass[6]
            $global:pass = $global:pass -replace "$editvar", "OEM UPDATES:1" 
            Set-Content -Path $global:varpath $global:pass |Out-Null
        }
    }
    #remove bloat programs after windows updates 
    if([int]([string]($global:pass[5][-1])) -gt 0) {
       
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
        
        
            if (Test-Path "C:\Program Files (x86)\Lenovo\Lenovo Quick Clean\") {
                Write-Host "Running Lenovo Quick Clean Uninstall Process"
                start-process -filepath "C:\Program Files (x86)\Lenovo\Lenovo Quick Clean\unins000.exe"  -ArgumentList "/silent" -ErrorAction SilentlyContinue| Out-Null
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

            #change resgistry values to prevent Microsoft Store from reinstalling removed apps 
            ##### Set SU AdminCommandLine
            $RegKey = "\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore"
            $RegName = "AutoDownload"
            $RegValue = "2"

            # Create Subkeys if they don't exist
            if (!(Test-Path $RegKey)) {
                New-Item -Path $RegKey -Force | Out-Null
                New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue | Out-Null
            }
            else {
                New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue -Force | Out-Null
            }
        
        
            
        
            $ProgressPreference = $default
            
        
            
            #Test-UninstallApps
        
        
        $editvar = $global:pass[7]
        $global:pass = $global:pass -replace "$editvar", "BLOATPROGRAMS:1" 
        Set-Content -Path $global:varpath $global:pass |Out-Null

    }


     


    #wait for windows updates to finish 
    $loading = ""

    if ($modInstalledCount -lt 1) {

        Install-Module PSWindowsUpdate -Force -Scope CurrentUser | Out-Null
    }
    
    

    while ([int]([string]($global:pass[5][-1])) -lt 1) {
        
        if ($loading.Length -gt 5 ){
            $loading = ""
        }

        $loading = $loading + "."
        Write-Host $loading -NoNewline
        Start-Sleep 300
        $global:pass = Get-Content -Path $global:varpath
        
    }

























}
    