﻿#region Functions definition
#region Below functions from the following link:
#https://blog.pythian.com/automation-powershell-and-word-templates-let-the-technician-do-tech/

#Function to open a word document:
Function OpenWordDoc($Filename){
    $Word=NEW-Object –comobject Word.Application
    Return $Word.documents.open($Filename)
}

#Function to save a word document as:
Function SaveAsWordDoc($Document, $FileName){
    $Document.Saveas([REF]$Filename)
    $Document.close()
}

#Function to replace a text tag (<TAG_YOUR_NAME>) with something else
Function ReplaceTag($Document, $FindText, $ReplaceWithText){
    $FindReplace=$Document.ActiveWindow.Selection.Find
    $matchCase = $false;
    $matchWholeWord = $true;
    $matchWildCards = $false;
    $matchSoundsLike = $false;
    $matchAllWordForms = $false;
    $forward = $true;
    $format = $false;
    $matchKashida = $false;
    $matchDiacritics = $false;
    $matchAlefHamza = $false;
    $matchControl = $false;
    $read_only = $false;
    $visible = $true;
    $replace = 2;
    $wrap = 1;

    $FindReplace.Execute($findText, $matchCase, $matchWholeWord, $matchWildCards, $matchSoundsLike, $matchAllWordForms, $forward, $wrap, $format, $replaceWithText, $replace, $matchKashida ,$matchDiacritics, $matchAlefHamza, $matchControl) | Out-Null
}


#Add an image to a bookmark
Function AddImage($Document, $BookmarkName, $ReplaceWithImage){
    $FindReplace=$Document.ActiveWindow
    $FindReplace.Selection.GoTo(-1,0,0,$Document.Bookmarks.item(“$BookmarkName”))
    $FindReplace.Selection.InlineShapes.AddPicture(“$replacewithImage”)
}

#endregion End of Functions from link indicated.
#region Generic functions (c) Sam
Function HereStringToArray ($HereString) {
    Return $HereString -split "`n" | %{$_.trim()}
}
#endregion

#region Function from Sam to get values from Exchange 2016
Function Get-E2016ReportValues {
    <#
    .SYNOPSIS
        Get Excel table data to be updated in the Word document

    .DESCRIPTION
        Get Excel table data to be updated in the Word document

    .PARAMETER FirstNumber
        Just a parameter sample...

    .PARAMETER CheckVersion
        This parameter will just dump the script current version.

    .INPUTS
        None.

    .OUTPUTS
        CSV file

    .EXAMPLE
    .\Do-Something.ps1
    This will launch the script and do someting

    .EXAMPLE
    .\Do-Something.ps1 -CheckVersion
    This will dump the script name and current version like :
    SCRIPT NAME : Do-Something.ps1
    VERSION : v1.0

    .NOTES
    None

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6

    .LINK
        https://github.com/SammyKrosoft
    #>
    [CmdLetBinding(DefaultParameterSetName = "NormalRun")]
    Param(
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "NormalRun")][string]$ExcelInput,
        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = "NormalRun")][string]$Department = "General",
        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = "CheckOnly")][switch]$CheckVersion
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
    If ($CheckVersion) {Write-Host "SCRIPT NAME     : $ScriptName `nSCRIPT VERSION  : $ScriptVersion";exit}
    # Log or report file definition
    # NOTE: use $PSScriptRoot in Powershell 3.0 and later or use $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition in Powershell 2.0
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    $OutputReport = "$ScriptPath\$($ScriptName)_$(get-date -f yyyy-MM-dd-hh-mm-ss).csv"
    # Other Option for Log or report file definition (use one of these)
    $ScriptLog = "$ScriptPath\$($ScriptName)-$(Get-Date -Format 'dd-MMMM-yyyy-hh-mm-ss-tt').txt"
    <# ---------------------------- /SCRIPT_HEADER ---------------------------- #>

    
    #If (-Not $ExcelInput){
        $ExcelInput = "C:\Users\SammyKrosoft\OneDrive\_Boulot\How-To Procedures\Exchange 2016 docs\E2016Test.xlsx"
    #}

    $FileExists = Test-Path $ExcelInput

    If ($FileExists) {
        Write-Host "Excel file exists, continuing..."
    } Else {
        Write-Host "Excel file does not exist, existing..."
        Exit
    }

    $Excel = New-Object -ComObject Excel.Application
    $Excel.Visible = $false
    $Excel.DisplayAlerts = $false

    $Workbook = $Excel.Workbooks.Open($ExcelInput)
    $WorkSheet = $Workbook.Worksheets.item($Department)
    $Worksheet.Activate()
    $WSTable = $Worksheet.ListObjects.Item(1)

    $WSTableRows = $WSTable.ListRows

    $WSTableRows.Count
    #$Row = $WSTableRows[1]
    #$RowVals = $Row.Range
write-host "IN THE FUNCTION EXCEL !"
    $WholeInputCollection = @()
    ForEach ($Row in $WSTableRows){
        $ValTrio = @() #Init & Re-init variable as we just want to store the values from each Row
        # there will be 3 columns that is 3 values for each Row
        Foreach ($Val in $($Row.Range)){
            Write-Host $($Val.Text)
            $ValTrio += $Val.Text
        }
        #Write-Host "Trio is : $($ValTrio[0]),$($ValTrio[1]),$($ValTrio[2]) "
        $CustomObj = [PSCustomObject]@{
            Description = $($ValTrio[0])
            Value = $($ValTrio[1])
            BookMark = $($ValTrio[2])
        }
        $WholeInputCollection += $CustomObj
    }

    $WholeInputCollection | Out-Host

    Write-Host "Closing workbook..." -ForegroundColor Green
    $Workbook.Close()
    Write-Host "Releasing Workbook Com Object..." -ForegroundColor Green
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook)
    Write-Host "Closing Excel..." -ForegroundColor Green
    $Excel.Quit()
    Write-Host "Releasing Excel Com Object..." -ForegroundColor Green
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
    Write-Host "Cleaning Excel variable..." -ForegroundColor Green
    Remove-Variable excel
    Write-Host "Garbage Collection..." -ForegroundColor Green
    [System.GC]::Collect()
    Write-Host "WaitForPendingFinalizers..." -ForegroundColor Green
    [System.GC]::WaitForPendingFinalizers()

   <# ---------------------------- SCRIPT_FOOTER ---------------------------- #>
    #Stopping StopWatch and report total elapsed time (TotalSeconds, TotalMilliseconds, TotalMinutes, etc...
    $stopwatch.Stop()
    $msg = "`n`nThe script took $([math]::round($($StopWatch.Elapsed.TotalSeconds),2)) seconds to execute..."
    Write-Host $msg
    $msg = $null
    $StopWatch = $null
    <# ---------------- /SCRIPT_FOOTER (NOTHING BEYOND THIS POINT) ----------- #>

    Return $WholeInputCollection
}

#endregion

#region Execution
<#SAmple using the above functions:

$TemplateFile = “C:\reports\Template_Report.docx”
$FinalFile = “C:\reports\FinalReport.docx”

# Open template file
$Doc=OpenWordDoc -Filename $TemplateFile

# Replace text tags
ReplaceTag –Document $Doc -FindText ‘<client_name>’ -replacewithtext “Pythian”
ReplaceTag –Document $Doc -FindText ‘<server_name>’ -replacewithtext “WINSRV001”

# Add image
AddImage –Document $Doc -BookmarkName ‘img_SomeBookmark’ -ReplaceWithImage “C:\reports\img.png”

# Save FInal Report
SaveAsWordDoc –document $Doc –Filename $FinalFile
#>
#endregion


#region Prerequisites

#Loading Presentation Framework assembly for inputbox
Add-Type -AssemblyName PresentationFramework


#endregion

#region Execution

cls

$DocNAme = "E2016BuildTest.docx"
$Docfile = "C:\Users\SammyKrosoft\OneDrive\_Boulot\How-To Procedures\Exchange 2016 docs\" + ($DocName)
$TextFormFieldsList = @"
Partner_Nickname
Partner_FullName
EXCH_Source_Dir
E2016Extras_DIR
EXCH_INST_DIR
Client_Endpoint
Internal_Url
External_Url
Autodiscover
E2016_Org_Unit
NIC_MAPI_NAme
NIC_MAPI_HW_NAme
NIC_REP_Name
NIC_REP_HW_Model
DEFAULT_GATEWAY
DNS1
DNS2
DOMAIN_NAME
EXTRAS_CD
FQDN_DOMAIN
CASARRAY
IP_ADDRESS
FIRST_SERVER_NAME
SUBNET_MASK
IPADDRESS1
SECOND_SERVER_NAME
SUBNET_MASK1
DB_First_Server
DB_Second_Server
Dag_Name
Witness_Server
Witness_DIR
PageFile
Prod_Key
Cas_Name
DB_Prefix
DB_Prefix1
"@

$FieldsArray = HereStringToArray $TextFormFieldsList

#$MSWord = New-Object -ComObject Word.Application
Try {
    $MSWord = [Runtime.Interopservices.Marshal]::GetActiveObject('Word.Application')
    $DocCount = $MSWord.Documents.count
    write-host "Currently $DocCount Word docs opened... checking if a doc named $DocName already exists..." -BackgroundColor yellow -ForegroundColor red
    $CountDocs = 0
    Foreach ($Doc in $MSWord.Documents) {
        $COuntDocs++
        If ($($Doc.Name) -eq $DocNAme) {
           Write-Host "A document with the same name is already opened ... please close it first" -ForegroundColor Red -BackgroundColor Yellow
           Exit
        }
    }
    Write-Host "Found $CountDocs currently opened, no docs with name $DocName opened. Creating a new Word instance !"
    Write-Host "Cleaning variables..."
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$MSword)
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    Remove-Variable MSword
}
Catch {
    Write-Host "No Word instance opened. Creating a new Word Instance"
}


$MSWord = New-Object -ComObject Word.Application

<# ROUTINE TO END WORD PROCESS AND CLEAN THE COM OBJ AND THE VARIABLE
$MSWord.Quit()
$null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$MSword)
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
Remove-Variable MSword
Exit
#>

$MSWord.Visible = $true
$Doc = $MSWord.Documents.Open($Docfile)

#Text FormFields are also referred to as text Bookmarks in Word
#The advantage of BookMarks is that it's quicker to find and to update, and you can sort by name and by position
#in the word document.
#
#$Bookmarks = $Doc.Bookmarks | Sort Start

#Foreach ($BM in $Bookmarks) {
#    #$BM.Name | Out-Host
#    $BM | fl * | out-host
#}
#
#Using FormFields for now until I get what's the best to use in Word automation...

$FormFields = $Doc.FormFields
$FormFieldsCollection = @()

Foreach ($FF in $FormFields){
    #$ff | out-host
    #$FF | Select Name,Type,Result | ft | Out-host
    $FFType = Switch ($FF.Type) {
        70 {"Text"}
        Default {"Other"}

    }
    $FFPSObj = [PSCustomObject]@{
        "FormField Name"   =   $FF.Name
        "FormField Type"   =   $FFType
        "FormField Value"  =   $FF.Result
    }
    $FormFieldsCollection += $FFPSObj
}

#comparing each formfield in the doc with the form field names defined to check if no one is missing
Write-Host "There are $($FieldsArray.count) text fields to check, the word document contains $($FormFieldsCollection.count) Text Formfields"

If ($($FieldsArray.count) -ne $($FormFieldsCollection.count)){
    Write-host "There is mismatch in the number of fields" -BackgroundColor yellow -ForegroundColor red
}

$NbMatches = 0
$MissingField = @()
$found = $false
$AtLeastOneMissing = $false
Foreach ($chkitem in $FieldsArray) {
    Foreach ($docitem in $FormFieldsCollection){
        If ($chkItem -eq $($DocItem.'FormField Name')){
            $found = $true
            $NbMatches += 1
        }
    }
    If (-not $found){
        $MissingField += $chkitem
        $AtLeastOneMissing = $True
    }
    $found = $false

}

If ($AtLeastOneMissing){
    Write-Host "At least one field is missing in the Doc" -ForegroundColor red -BackgroundColor yellow
    Write-Host "There are $($MissingField.count) fields missing in the doc"
    $MissingField | Out-Host
} Else {
    Write-Host "All fields there !"
}

$Department = "JUSTICE"
$FormFieldsFromExcel = Get-E2016ReportValues -Department $Department

# $FormFieldsFromExcel

# $Doc.Close()
# $MSWord.Quit()
# $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$MSword)
# [gc]::Collect()
# [gc]::WaitForPendingFinalizers()
# Remove-Variable MSword
# exit

$TotalElementsInFormFields = $FormFields.count
$TotalElementsInFormFields | Out-Host


Foreach ($FF in $FormFieldsFromExcel){
    #$Doc.FormFields.Item($($FF.Bookmark)).TextInput.Default = $($FF.Value)
    $Doc.FormFields($($FF.Bookmark)).TextInput.Default = $($FF.Value)
    $FF.Bookmark | out-host
}

#To update all fields :
$MSWord.ActiveDocument.Fields.Update()

$outputFile = "c:\temp\" + $Department + " - E2016BuildTest - " + (Get-Date -Format "dd-mm-yyyy-HH-MM-ss") + ".docx"
$Doc.SaveAs([REF]$outputFile)


$Action = [System.Windows.MessageBox]::Show("Do you want to close the $($Doc.Name) Word doc ?","$($Doc.Name)",'YesNo','Warning')

Switch ($Action){
    "Yes" {"Closing the doc and closing Word..."
            $Doc.Close()
            $MSWord.Quit()
            $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$MSword)
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            Remove-Variable MSword
            }
    "No" {
            "Leaving the doc opened"
            $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$MSword)
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            Remove-Variable MSword
         }
}






<# 

To update a bookmark:

If ($Doc.Bookmarks.Exists){
    $doc.FormFields.Item($bookmark).Result = "Something"
}


#>

<# CHANGES TO DO ON E2016 BUILD DOC

1- Update Header with <Partner Full Name> cross reference => done
2- On Base Server Configuration table, E2016Extras -> put text on asterix to leave value only => Done
3- On TITLE page, add SSC/<Partner Acronym field> => Done
4- P.50 - remove  > sign after SetSpn cmd line => done
4bis - p.50 - BOLD for whole mail.canada.ca => done (no change)
4 ter - p.50 - Change mail.canada.ca with cross reference (Output sample) => Done
5- p.64 - Set-VirtualDirectories mail.canada.ca
5bis - Page Break for table Set-Vdirs
#>