# PsGetPubIP
PowerShell script - List all used Public IP addresses using authenticated user

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
