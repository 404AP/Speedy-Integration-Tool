#run windows updates 



$id = (Get-WmiObject win32_service | where {$_.name -eq 'wuauserv'}).processID
taskkill /f /pid $id | Out-Null
Start-Sleep -Seconds 5 
net Start wuauserv


Write-Host "** Windows will Auto Reboot if it needs to**" -BackgroundColor Black -ForegroundColor Red



    
$modInstalled = Get-Module *windowsupdate*
$modInstalledCount = $modInstalled.count

if ($modInstalledCount -lt 1){
Install-Module PSWindowsUpdate -Force -Scope CurrentUser | Out-Null
}

$count = Get-WindowsUpdate
$retrys = 0

while ($count.count -gt 0) {
    if($retrys -gt 5) {
        shutdown -r -t 00
    }
    try {
        Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Windows Updates Will Try Again"
    }
    $retrys++
    $count = Get-WindowsUpdate
}



#Write-Host "Ran Updates"
<#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this workflow
.EXAMPLE
    Another example of how to use this workflow
.INPUTS
    Inputs to this workflow (if any)
.OUTPUTS
    Output from this workflow (if any)
.NOTES
    General notes
.FUNCTIONALITY
    The functionality that best describes this workflow
#>
workflow Verb-Noun {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   HelpUri = 'http://www.microsoft.com/',
                   ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    param (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [Alias("p1")] 
        $Param1,

        # Param2 help description
        [int]
        $Param2
    )

    # Saves (persists) the current workflow state and output
    # Checkpoint-Workflow
    # Suspends the workflow
    # Suspend-Workflow

    # Workflow common parameters are available as variables such as:
    $PSPersist 
    $PSComputerName
    $PSCredential
    $PSUseSsl
    $PSAuthentication

    # Workflow runtime information can be accessed by using the following variables:
    $Input
    $PSSenderInfo
    $PSWorkflowRoot
    $JobCommandName
    $ParentCommandName
    $JobId
    $ParentJobId
    $WorkflowInstanceId
    $JobInstanceId
    $ParentJobInstanceId
    $JobName
    $ParentJobName

    # Set the progress message ParentActivityId
    $PSParentActivityId

    # Preference variables that control runtime behavior
    $PSRunInProcessPreference
    $PSPersistPreference
}