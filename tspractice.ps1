

$su = "C:\Users\AP\Documents\Practice_Scripts\test.bat"

$user = "NT AUTHORITY\SYSTEM"

$taskAction = New-ScheduledTaskAction -Execute $su 
$taskTrigger = New-ScheduledTaskTrigger -AtLogOn
$taskUserPrincipal = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest 
$taskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries 
$task = New-ScheduledTask -Action $taskAction -Principal $taskUserPrincipal -Trigger $taskTrigger -Settings $taskSettings
Register-ScheduledTask -TaskName 'Speedy-Integration-Alarm' -InputObject $task -Force