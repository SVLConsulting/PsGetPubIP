<#
-- Pre-requisites
    $PSVersionTable.PSVersion must give version 7 or higher

    Set Execution Policy to RemoteSigned, otherwise script with AZ module won't work
    Execute: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

    AZ module must be installed, if not, run command below
    Execute: Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

-- Authentication
    To authenticate to Azure using a User and not a Service Principle, use the command Connect-AzAccount
    Should you have access to register application, do this, it provides more granular control.

-- Run
    Run program: 'C:\Program Files\PowerShell\7\pwsh.exe' .\GetAllPubIP.ps1
#>

# Defining global variables

$Today = Get-Date -UFormat "%d/%m/%Y"
$Time = Get-Date -UFormat "%R"
$TimeZone = Get-Date -UFormat "UTC%Z"

# Function definitions

function createIfNotExist($file)
{
    #If the file does not exist, create it.
    if (-not(Test-Path -Path $file -PathType Leaf)) {
        try {
            $null = New-Item -ItemType File -Path $file -Force -ErrorAction Stop
            #Write-Host "The file [$file] has been created."
        }
        catch {
            throw $_.Exception.Message
        }
    }
}

function readSettingsFile()
{
    foreach($line in [System.IO.File]::ReadLines(".\settings.txt"))
    {
        $settings += $line
    }
    
    return $settings
}

function localSettings($settings)
{
    foreach($setting in $settings)
    {
        if($setting -like "Path *")
        {
            $Path = $setting
        }
        if($setting -like "Filename *")
        {
            $FileName = $setting
        }
        if($setting -like "LastTimeChecked *")
        {
            $lastTimeChecked = $setting
        }
    }
    
    return $Path,$FileName,$lastTimeChecked
}

function verifyPSVer() # Verify PowerShell version 7 or higher
{
    $PSVer = $PSVersionTable.PSVersion.ToString()

    If($PSVer -lt 7)
    {
        Throw "Powershell Version is too low, please install new version that supports AZ module."
    }
    else {
        Write-Debug "Powershell version is compatible."
    }
}

function verifyAZMod()
{
    Write-Debug "Checking if AZ module is installed"

    $installed = Get-InstalledModule -Name Az

    If ($installed) # Verify AZ module is installed
    {
        # AZ mod is installed
        Write-Debug "AZ mod installed"

        # Verify AZ module is up-to-date
        # Update-Module Az -Force -Verbose # -Verbose for detailed information
        Write-Debug "Verifying AZ mod is up-to-date"
    }
    else {
        Write-Debug "Installing AZ mod"
        try {
            $null = Install-Module -Name Az -Force -Verbose
        }
        catch {
            throw $_.Exception.Message
        }
    }

    # Write to settings file, the timestamp and version
}

function Login()
{
    $context = Get-AzContext
   
    if (!$context) 
    {
        Connect-AzAccount
    } 
    else 
    {
        Write-Debug "Already authenticated with Azure"
    }
}

function Subs()
{
    $subList = Get-AzSubscription | Select-Object -ExpandProperty Id #ExpandProperty gives the Id in a parsable format

    if(!$subList)
    {
        Write-Debug "No subscriptions found"
    }
    else {
        Write-Debug "Listing all subscriptions"
    }

    return $subList
}

function setAzContext($sub)
{
    $outputAzContext = Set-AzContext $sub
    return $outputAzContext
}

function printPubIPs($subList)
{
    foreach ($sub in $subList)
    {
        Write-Debug "Setting Subscription to" #$sub
        setAzContext($sub) #| Select-Object -Property Name,TenantId | Out-File $file -Append

        Write-Debug "Listing the Public IP addresses used in this subscription" 
        Write-Debug "------------------------------"
        $PubIP = Get-AzPublicIpAddress | Select-Object -Property IpAddress,Name,ResourceGroupName,Id

        foreach ($IP in $PubIP)
        {
            If ($IP -eq "Not Assigned")
            {
                Write-Debug "This sub has unassigned public IP addresses"
                $IP | Out-File $file -Append
            }
            else {
                Write-Debug "This sub has one or more Pub IPs"
                $IP | Out-File $file -Append
            }
        }
    }
}

# The Run:

## LocalSettings check - path and filename
$file = '.\settings.txt'
createIfNotExist($file)
$settings = readSettingsFile
localSettings($settings)

## Verification - verifies PowerShell version and Az Module version
verifyPSVer
verifyAZMod

## Login check - checking if Logged In into Azure, if not, then login
Login

## Requesting all subscriptions
$subList = Subs

## Printing all public IP addresses within subscriptions
$file = ".\output.txt"
"Script is being run at systemdate $Today $Time $TimeZone" | Out-File $file -Append
createIfNotExist($file)
printPubIPs($subList)