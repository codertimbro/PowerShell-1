<#
.SYNOPSIS
    This scripts wraps around Search-AdminAuditLog Exchange Management Shell cmdlet, which searches the audit logs 
    and output them in a simple form using my colleague's matbyrd@microsoft.com script, or display these in their
    native form like Search-AdminAudiLog does by default.

.DESCRIPTION
    This script searches the Admin audit logs, and optionnally with the use of matbyrd@microsoft.com's function, outputs the 
    results in a native Search-AdminAuditLog form or in the form simplified by matbyrd.

.PARAMETER CmdLet
    Filter the search on one or more specific cmdlets. Separate each cmdlet with a comma ","

.PARAMETER NbDaysToLookBack
    Indicates how many days from today we wish to search logs from the past (argh doesn't sound very english).
    I am using this parameter to populate the -StartDate and -EndDate of the Search-AdminAuditLog Exchange Management
    Shell cmdlet because I always mess with dates. In Canada we can write dates starting with the day first, like DD-MM-YYYY
    and some also write dates with the month first like MM-DD-YYYY. Specifying a number of days from when we want to 
    look for Audit Logs enables me to leverage (Get-Date).AddDays(-12) for example if I want the search to look at the
    Admin Audit Logs from 12 days ago to today.

.PARAMETER ResultSize
    I change the default to 5000 - feel free to change it with the script or directly with Search-AdminAuditLog -ResultSize

.PARAMETER DisableSimple
    Bypasses matbyrd@microsoft.com function to display the raw output of Search-AdminAuditLog.

.PARAMETER ExportToFile
    Exports to a CSV file named after the script's name, in the script's directory by default.

.INPUTS
    None.

.OUTPUTS
    Print results on screen or on a CSV file

.EXAMPLE
.\Get-AuditReportsSimple

This will show the audit reports

.EXAMPLE
.\Get-AuditReportSimple -CmdLet New-MoveRequest -NbDaysToLookBack 30 -ExportToFile

This will search for all the admin audit log entries for Move Mailbox operations that took have been attempted
in the last month (30 days) and store it in a CSV file

.NOTES
This "wrapper" is directly using matbyrd@microsoft.com's function.
See the Technet Gallery link in the "Related Links" part of this Get-Help comments section.

.LINK
https://docs.microsoft.com/en-us/powershell/module/exchange/policy-and-compliance-audit/search-adminauditlog?view=exchange-ps

.LINK
https://gallery.technet.microsoft.com/scriptcenter/Get-SimpleAuditLogReport-19e9e51a

.LINK
https://github.com/SammyKrosoft
#>
[CmdLetBinding(DefaultParameterSetName = "NormalRun")]
Param(
    [Parameter(Mandatory = $False, Position = 1, ParameterSetName = "NormalRun")] $Cmdlet,
    [Parameter(Mandatory = $False, Position = 2, ParameterSetName = "NormalRun")] [int]$NbDaysToLookBack = 30,
    [Parameter(Mandatory = $false, Position = 3, ParameterSetName = "NormalRun")] $ResultSize = 3000,
    [Parameter(Mandatory = $false, Position = 4, ParameterSetName = "NormalRun")] [switch]$DisableSimple,
    [Parameter(Mandatory = $false, Position = 5, ParameterSetName = "NormalRun")] [switch]$ExportToFile,
    [Parameter(Mandatory = $false, Position = 3, ParameterSetName = "CheckOnly")] [switch]$CheckVersion
)

<# ------- SCRIPT_HEADER (Only Get-Help comments and Param() above this point) ------- #>
#Initializing a $Stopwatch variable to use to measure script execution
$stopwatch = [system.diagnostics.stopwatch]::StartNew()
#Using Write-Debug and playing with $DebugPreference -> "Continue" will output whatever you put on Write-Debug "Your text/values"
# and "SilentlyContinue" will output nothing on Write-Debug "Your text/values"
$DebugPreference = "Continue"
# Set Error Action to your needs
$ErrorActionPreference = "SilentlyContinue"
#Script Version
$ScriptVersion = "0.1"
<# Version changes
v0.1 : first script version
v0.1 -> v0.5 : 
#>
$ScriptName = $MyInvocation.MyCommand.Name
If ($CheckVersion) {Write-Host "SCRIPT NAME :$ScriptName `nSCRIPT VERSION :$ScriptVersion";exit}
# Log or report file definition
# NOTE: use $PSScriptRoot in Powershell 3.0 and later or use $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition in Powershell 2.0
$OutputReport = "$PSScriptRoot\$ScriptName_$(get-date -f yyyy-MM-dd-hh-mm-ss).csv"
# Other Option for Log or report file definition (use one of these)
$ScriptLog = "$PSScriptRoot\$ScriptName-$(Get-Date -Format 'dd-MMMM-yyyy-hh-mm-ss-tt').txt"
<# ---------------------------- /SCRIPT_HEADER ---------------------------- #>
<# -------------------------- DECLARATIONS -------------------------- #>

<# /DECLARATIONS #>
<# -------------------------- FUNCTIONS -------------------------- #>
Function Get-SimpleAuditLogReport {
    <# 
    .SYNOPSIS
    Parses the output of Search-AdminAuditlog to produce more readable results.
    
    .DESCRIPTION
    Takes the output of the Search-AdminAuditlog as an input and reconstructs the
    results into a more easily read structure.
    
    Results can be stored in a variable and sent to the script with -searchresults
    or taken directly off of a pipeline and converted.
    
    Output should generally contain commands that can be copied and pasted into
    an Exchange/Exchange Online Shell and run directly with little to no
    Modification.
     
    .PARAMETER SeachResults
    Output of the Search-AdminAuditLog. Either stored in a variable or pipelined
    into the script.
    
    .PARAMETER ResolveCaller
    Attempts to resolve the alias of the person who ran the command into the 
    primary SMTP address.
    
    .PARAMETER Agree
    Verifies you have read and agree to the disclaimer at the top of the script file
    
    .OUTPUTS
    Creates an output that contains the following information:
    
    Caller         : Person who ran the command
    Cmdlet         : Cmdlet that was run
    FullCommand    : Reconstructed full command that was run
    RunDate        : Date and Time command was run
    ObjectModified : Object that was modified by the command
    
    .NOTES
    ################################################################################
    
    The sample scripts are not supported under any Microsoft standard support 
    program or service. The sample scripts are provided AS IS without warranty 
    of any kind. Microsoft further disclaims all implied warranties including, without 
    limitation, any implied warranties of merchantability or of fitness for a particular 
    purpose. The entire risk arising out of the use or performance of the sample scripts 
    and documentation remains with you. In no event shall Microsoft, its authors, or 
    anyone else involved in the creation, production, or delivery of the scripts be liable 
    for any damages whatsoever (including, without limitation, damages for loss of business 
    profits, business interruption, loss of business information, or other pecuniary loss) 
    arising out of the use of or inability to use the sample scripts or documentation, 
    even if Microsoft has been advised of the possibility of such damages.
    
    ################################################################################
    
    Author matbyrd@microsoft.com
    
    ################################################################################
    
    .EXAMPLE
    $Search = Search-AdminAuditLog
    $search | C:\Scripts\Get-SimpleAuditLogReport.ps1 -agree
    
    Converts the results of Search-AdminAuditLog and sends the output to the screen
    
    .EXAMPLE
    Search-AdminAuditLog | C:\Scripts\Get-SimpleAuditlogReport.ps1 -agree | Export-CSV -path C:\temp\auditlog.csv
    
    Converts the restuls of Search-AdminAuditLog and sends the output to a CSV file
    
    .EXAMPLE
    $MySearch = Search-AdminAuditLog -cmdlet set-mailbox
    C:\Script\C:\Scripts\Get-SimpleAuditLogReport.ps1 -agree -searchresults $MySearch
    
    Finds all instances of set-mailbox
    Converts them by passing in the results to the switch searchresults
    Outputs to the screen
    
    #>
    
    Param (
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        $SearchResults,
        [switch]$ResolveCaller,
        [switch]$Agree
    )
    
    # Setup to process incomming results
    Begin {
        
        # Statement to ensure that you have looked at the disclaimer or that you have removed this line so you don't have too
        if ($Agree -ne $true){ Write-Error "Please run the script with -Agree to indicate that you have read and agreed to the sample script disclaimer at the top of the script file" -ErrorAction Stop }
        
        # Make sure the array is null
        [array]$ResultSet = $null
        
        # Set the counter to 1
        $i = 1
        
        # If resolveCaller is called it can take much longer to run so notify the user of that
        if ($ResolveCaller){Write-Warning "ResolveCaller specified; Script will take significantly longer to run as it attemps to resolve the primary SMTP address of each calling user.  Progress updates will be provided every 25 entries."}
    }
    
    # Process thru what ever is comming into the script
    Process {
        
        # Deal with each object in the input
        $searchresults | foreach {
            
            # Reset the result object
            $Result = New-Object PSObject
            
            # Get the alias of the User that ran the command
            $user = ($_.caller.split("/"))[-1]
            
            # If we used resolve caller then try to resolve the primary SMTP address of the calling user
            if ($ResolveCaller){
                
                # attempt to resolve the recipient
                [string]$Recipient = (get-recipient $user -erroraction silentlycontinue).primarysmtpaddress
                
                # if we get a result then put that in the output otherwise do nothing
                If (!([string]::IsNullOrEmpty($Recipient))){$user = $Recipient}
                
                # Since this is going to take longer to run provide status every 25 entries
                if ($i%25 -eq 0){Write-Host "Processed 25 Results"}
                $i++
            }
            
            # Build the command that was run
            $switches = $_.cmdletparameters
            [string]$FullCommand = $_.cmdletname
            
            # Get all of the switchs and add them in "human" form to the output
            foreach ($parameter in $switches){
                                
                # Format our values depending on what they are so that they are as close
                # a match as possible for what would have been entered
                switch -regex ($parameter.value)
                {
                
                    # If we have a multi value array put in then we need to break it out and add quotes as needed
                    '[;]'	{ 
                
                        # Reset the formatted value string
                        $FormattedValue = $null
                        
                        # Split it into an array
                        $valuearray = $switch.current.split(";")
                        
                        # For each entry in the array add quotes if needed and add it to the formatted value string
                        $valuearray | foreach {
                            if ($_ -match "[ \t]"){$FormattedValue = $FormattedValue + "`"" + $_ + "`";"}
                            else {$FormattedValue = $FormattedValue + $_ + ";"}
                        }
                        
                        # Clean up the trailing ;
                        $FormattedValue = $FormattedValue.trimend(";")
                        
                        # Add our switch + cleaned up value to the command string
                        $FullCommand = $FullCommand + " -" + $parameter.name + " " + $FormattedValue
                    }
                    
                    # If we have a value with spaces add quotes
                    '[ \t]'				{$FullCommand = $FullCommand + " -" + $parameter.name + " `"" + $switch.current + "`""}
                    
                    # If we have a true or false format them with :$ in front ( -allow:$true )
                    '^True$|^False$'	{$FullCommand = $FullCommand + " -" + $parameter.name + ":`$" + $switch.current}
                    
                    # Otherwise just put the switch and the value
                    default				{$FullCommand = $FullCommand + " -" + $parameter.name + " " + $switch.current}
                
                }
            }
            
            # Format our modified object
            if ([string]::IsNullOrEmpty($_.objectModified)){$ObjModified = ""}
            else { 
                $ObjModified = ($_.objectmodified.split("/"))[-1]
                $ObjModified = ($ObjModified.split("\"))[-1]
            }
            
            # Get just the name of the cmdlet that was run
            [string]$cmdlet = $_.CmdletName
            
            # Build the result object to return our values
            $Result | Add-Member -MemberType NoteProperty -Value $user -Name Caller
            $Result | Add-Member -MemberType NoteProperty -Value $cmdlet -Name Cmdlet
            $Result | Add-Member -MemberType NoteProperty -Value $FullCommand -Name FullCommand
            $Result | Add-Member -MemberType NoteProperty -Value $_.rundate -Name RunDate
            $Result | Add-Member -MemberType NoteProperty -Value $ObjModified -Name ObjectModified
            
            # Add the object to the array to be returned
            $ResultSet = $ResultSet + $Result
            
        }
    }
    
    # Final steps
    End {
        # Return the array set
        Return $ResultSet
    }
}

Function Test-ExchTools(){
    Try
    {
        Get-command Get-mailbox -ErrorAction Stop
        $ExchInstalledStatus = $true
        $Message = "Exchange tools are present !"
        Write-Host $Message -ForegroundColor Blue -BackgroundColor Red
    }
    Catch [System.SystemException]
    {
        $ExchInstalledStatus = $false
        $Message = "Exchange Tools are not present !"
        Write-Host $Message -ForegroundColor red -BackgroundColor Blue
    }
    Return $ExchInstalledStatus
}

function IsEmpty($Param){
    If ($Param -eq "All" -or $Param -eq "" -or $Param -eq $Null -or $Param -eq 0) {
        Return $True
    } Else {
        Return $False
    }
}
<# /FUNCTIONS #>
<# -------------------------- EXECUTIONS -------------------------- #>
#If (!(Test-ExchTools)) {Exit}

#Building the Search-AdminAuditLog with the parameters from the wrapper script...
$StrCmdLetBase = "Search-AdminAuditLog"
$StrCmdLet_CmdLet = $(If (IsEmpty $CmdLet){""}Else{" -CmdLet $Cmdlet"})
$StrCmdLet_NbDaysToLookBack = $(If (IsEmpty $NbDaysToLookBack){""}Else{" -StartDate ""$((Get-Date).AddDays(-$NbDaysToLookBack))"" -EndDate ""$(Get-Date)"""})
$StrCmdLet_ResultSize = " -ResultSize $ResultSize"

#Full Command is a concatenation of the above
$StrCmdLet = $StrCmdLetBase + $StrCmdLet_CmdLet + $StrCmdLet_NbDaysToLookBack + $StrCmdLet_ResultSize

If ($DisableSimple) {
    # If we choose to see the raw Audit Log Entry as opposed to the cmdlet re-built by matbyrd@microsoft.com, we select a few properties
    # feel free to add more if you want to export more : PowerShell is very flexible !
    $StrFinalCmd = $StrCmdLet + ' | Select RunDate, caller, cmdletname, ObjectModified, @{Name=''ModifiedProps'';Expression={[string]::join(";",($_.ModifiedProperties))}}'
} Else {
    $StrFinalCmd = $StrCmdLet + ' | Get-SimpleAuditLogReport -Agree'
}

If ($ExportToFile){$StrFinalCmd = $StrFinalCmd + " | Export-CSV $OutputReport"}

Write-Host $StrFinalCmd
Invoke-Expression $StrFinalCmd

<# /EXECUTIONS #>
<# -------------------------- CLEANUP VARIABLES -------------------------- #>
$StrCmdLetBase = $null
$StrCmdLet_CmdLet = $null
$StrCmdLet_NbDaysToLookBack = $null
$StrCmdLet_ResultSize = $null
$StrCmdLet = $null
<# /CLEANUP VARIABLES#>
<# ---------------------------- SCRIPT_FOOTER ---------------------------- #>
#Stopping StopWatch and report total elapsed time (TotalSeconds, TotalMilliseconds, TotalMinutes, etc...
$stopwatch.Stop()
Write-Host "`n`nThe script took $($StopWatch.Elapsed.TotalSeconds) seconds to execute..."
$StopWatch = $null
<# ---------------- /SCRIPT_FOOTER (NOTHING BEYOND THIS POINT) ----------- #>
