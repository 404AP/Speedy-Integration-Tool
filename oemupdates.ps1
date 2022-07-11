$oemstatus = $null
while (!(($oemstatus -eq 0) -or ($oemstatus -eq 1))) {
Write-Host "If you skip you will not be prompted again for OEM updates" -BackgroundColor Black -ForegroundColor Red
$oemStatus = Read-Host -Prompt "Are you ready to run OEM updates? 
You may have to manually istall formware so pay attention to the notification pane! 
type '1' to get started and '0' to skip this step if you have already run it or the computer is not DELL or Lenovo  "                  
}
if ($oemstatus -eq 1) {

        #Dell or Lenovo

            $OEM = (Get-ComputerInfo -Property CsManufacturer).CsManufacturer

            if ( $OEM -eq "LENOVO") {
                
                $installerRan = 0

                while (!(Test-Path "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe")) {
                
                    if ($installerRan -eq 0) {
                        Write-Host "Running the Installer"
                        Start-Process -FilePath "$PSscriptroot\lenovo.exe" -Verb runAs  -ArgumentList "/verysilent /norestart"  -ErrorAction SilentlyContinue
                        $installerRan = 1
                    }
                    Write-Host "Waiting for Installer"
                    Start-Sleep -s 10
                }
                Write-Host "Waiting for files to finish installing . Running OEM updates momentarily"
        

                ##### Set SU AdminCommandLine
                $RegKey = "HKLM:\SOFTWARE\Policies\Lenovo\System Update\UserSettings\General"
                $RegName = "AdminCommandLine"
                $RegValue = "/CM -search R -action INSTALL -includerebootpackages 1,3,4,5 -noicon -nolicense"

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
                        Start-Process -FilePath "$psscriptroot\DELL.exe" -Verb runAs  -ArgumentList "/s"  -ErrorAction SilentlyContinue
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
                    Start-Process -FilePath "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -reboot=Enable" -ErrorAction SilentlyContinue
                }
                


            } else {
                Write-Host "System not Supported!"
            }

    