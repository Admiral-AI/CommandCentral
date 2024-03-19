# Junk?:
<#
param (
    [string]$startingDirectory
)
#>

#Test updates based on this line

# Main function
function Main {

    Set-Location $PSScriptRoot

    # Import settings file and set the variable to global access (indicates that all scripts within the current PowerShell session can access it)
    Set-Variable $Global:settingsJSON
    $settingsJSON = Get-Content .\SystemD\Settings.json
    $settingsJSON = $settingsJSON | ConvertFrom-Json

    # Set transcript log path based on 
    Start-Transcript $settingsJSON.Application_Settings.Log_Paths.CommandCentral_PSScript_Log -Append -Force

    # Clear the console
    Clear-Host

    # Start the domino effect of functions
    Get-Updates

    # Reset location before exiting, prevents errors when runnning in same terminal
    Set-Location $PSScriptRoot

    # Stop Transcript when finished with script
    Stop-Transcript
}

# Function to get user credentials
function Get-UserCredentials {
    
    # Get the CIM_ComputerSystem CIM class
    $computerSystem = Get-CimInstance Win32_ComputerSystem

    # Check if the domain property is not empty
    if ($computerSystem.PartofDomain -eq $true) {
        Write-Host "Computer is in a domain: $($computerSystem.Domain)"
        
        $userFirstName = $(Get-ADUser -Identity $env:username).GivenName
        $userLastName = $(Get-ADUser -Identity $env:username).Surname
        $accountsToQuery = Get-ADUser -Filter $("(GivenName -like '*$($userFirstName)*') -and (sn -like '*$($userLastName)*') -and (Enabled -eq 'True')")

        foreach ($accountToQuery in $accountsToQuery) {
            $userCred = Get-StoredCredential -Target "CommandCentral-$($accountToQuery.SamAccountName)"
            
            if ($null -eq $userCred) {
                 $userCred = Get-Credential -UserName "$($Env:UserDomain)\$($accountToQuery.SamAccountName)" -Message "Please provide your credentials for the following account: $($Env:UserDomain)\$($accountToQuery.SamAccountName)"
                 New-StoredCredential -Target "CommandCentral-$($accountToQuery.SamAccountName)" -Credential $userCred -Persist ENTERPRISE
            }
        }

    } else {
        Write-Host "Computer is in a workgroup, credentials are assumed to not be needed (administrator running script)"
        Start-Sleep 2
    }

    # Clear the screen before heading to the next functions
    Clear-Host

    # Call the menu function
    Set-DisplayMenu

}

# Function to check for module and script updates
function Get-Updates {
    
    #Need to add check for RSAT install
    <#
    # Get the CIM_ComputerSystem CIM class and set variable to global
    $computerSystem = Get-CimInstance Win32_ComputerSystem

    # Check if the domain property is not empty
    if ($computerSystem.PartofDomain -eq $true) {
        if($null -eq (Get-Module -ListAvailable -Name ActiveDirectory))
        {
            Write-Host -ForegroundColor Red "Remote Server Administration Tools isn't installed!"
            Try{
                Start-Process powershell -Verb runas -PassThru -ArgumentList `
                "'Installing RSAT...'; Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Add-WindowsCapability -Online; Read-Host 'Please reboot your computer to complete installation'"
                }
            Catch{Write-Host -ForegroundColor Red "Installation failed. Please install manually and run this tool again";exit}
        }
    }
    #>

    $providedJSONUpdateLocation = $settingsJSON.Application_Settings.Updates.UpdateRetrievalLocation

    switch ($providedJSONUpdateLocation) {
        "Main_Repo" {$repoToPullFrom = $settingsJSON.Application_Settings.Updates.Main_Repo.CommandCentral_Script_mainGitRepo ; break}
        "Dev_Repo" {$repoToPullFrom = $settingsJSON.Application_Settings.Updates.Dev_Repo.CommandCentral_Script_devGitRepo ; break}
        "Local_Repo" {$repoToPullFrom = $settingsJSON.Application_Settings.Updates.Local_Repo.CommandCentral_Script_localRepo ; break}
    }

    if ((Invoke-WebRequest $repoToPullFrom -DisableKeepAlive -UseBasicParsing -Method Head).StatusDescription -eq "OK") {
        $scriptLocationType = "WebURL"
        $scriptPulledfromRepo = $(Invoke-RestMethod -Uri $repoToPullFrom)
    } elseif ((Test-Path $repoToPullFrom) -eq $true) {
        $scriptLocationType = "FilePath"
        $scriptPulledfromRepo = Get-Content -Path $($repoToPullFrom) -Raw
    } else {
        Write-Host "General failure when pulling information from repository, please re-run script again or redownload the files."
        if ($repoToPullFrom -eq "Local_Repo") {
            Write-Host "Alternatively contact your administrator since this is a locally run repository"
        }
    }

    $scriptOnLocalDisk = Get-Content -Path $($PSCommandPath) -Raw

    # Use Compare-Object to compare the contents of the two files
    $fileComparison = Compare-Object -ReferenceObject ($scriptPulledfromRepo) -DifferenceObject ($scriptOnLocalDisk)

    # Check the result
    if ($fileComparison.Count -eq 0) {
        Write-Output "No updates found, proceeding to update modules."
        $updateAndRestartScriptBoolean = $false
    } else {
        Write-Output "Update found! Updating local script and restarting."
        $updateAndRestartScriptBoolean = $true
    }

    if ($updateAndRestartScriptBoolean -ne $true) {
        $moduleList = @(
            'TUN.CredentialManager'
        )

        foreach ($module in $moduleList) {
            if (Get-Module -ListAvailable -Name $module) {
                Write-Host "Module: $($module) exists"
            } 
            else {
                Write-Host "Module: $($module) does not exist. Installing..."
                Install-Module -Name $module -Scope CurrentUser -Force
            }
        }
        
        # Clear the screen before heading to the next functions
        Clear-Host
        
        # Call the Set-DisplayMenu function
        Get-UserCredentials

    } else {
        
        $scriptPulledfromRepo | Out-File -FilePath $($PSCommandPath)

        Write-Host "Attempted to write updates, now opening script again..."
        Start-Sleep 2
        Start-Process powershell.exe -ArgumentList "-File `"$($PSCommandPath)`""
        Write-Host "Exiting CommandCentral..."
        Start-Sleep .75

    }
}

# Function to display a menu and handle user input
function Set-DisplayMenu {

    # Define the directories where the PowerShell scripts, 'menus', and settings are located
    $rootScriptDirectory = $PSScriptroot
    $systemDDirectory = Join-Path -Path $PSScriptroot -ChildPath $settingsJSON.Application_Settings.SystemD_Path
    $functionsDirectory = Join-Path -Path $rootScriptDirectory -ChildPath $settingsJSON.Application_Settings.Functions_Path

    # Set the starting directory to the location of the 'Functions' directory
    $startingDirectory = $functionsDirectory
    Set-Location $functionsDirectory

    # Using SystemD location setting, pull logo file
    $logoFileLocation = Join-Path -Path $($systemDDirectory) -ChildPath \Logo.txt
    $logoForMenu = Get-Content $logoFileLocation -Raw

    # Loop to display menus until the user chooses to quit
    while ($userChoice -ne 'quit') {

        Write-Host $logoForMenu -ForegroundColor DarkYellow

        # Check if the starting and working directories match and provide option to quit accordingly
        if ($startingDirectory -eq $functionsDirectory) {
            $optionToQuit = 1
        } else {
            $optionToQuit = 0
        }

        # List .ps1 files in the working directory
        $ps1FilesArray = Get-ChildItem -Path $functionsDirectory -Filter "*.ps1"
        $ps1Options = @()
        Foreach ($ps1File in $ps1FilesArray) {
            $ps1Options += ($ps1File.BaseName)
        }

        # List subdirectories in the working directory
        $subdirectories = Get-ChildItem -Path $functionsDirectory -Directory
        $subOptions = @()
        Foreach ($subDirectory in $subdirectories) { 
            $subOptions += ($subDirectory.BaseName)
        }


        # Display options to the user
        Write-Host "Options:"
        # Display .ps1 files in green
        for ($displayScriptsLoop = 1; $displayScriptsLoop -le $ps1Options.Count; $displayScriptsLoop++) {
                Write-Host "$displayScriptsLoop. $($ps1Options[$displayScriptsLoop-1])" -ForegroundColor Green
        }
        # Display subdirectories in blue
        for ($displayDirectoriesLoop = 1; $displayDirectoriesLoop -le $subOptions.Count; $displayDirectoriesLoop++) {
                Write-Host "$($displayDirectoriesLoop + $ps1Options.Count). $($subOptions[$displayDirectoriesLoop-1])" -ForegroundColor Blue
        }
        # Display option to go back one directory or quit
        if ($optionToQuit -eq 0) {
            Write-Host "$($($ps1Options.Count) + $($subOptions.Count) + 1). Go back one directory" -ForegroundColor Cyan 
        } else {
            Write-Host "$($($ps1Options.Count) + $($subOptions.Count) + 1). Quit ('q' or 'quit')" -ForegroundColor Cyan
        }

        # Get user input
        $userChoice = Read-Host "Enter the number corresponding to your choice"
        
        # Process user choice
        if ($userChoice -le $ps1Options.Count) {
            # Run the selected PowerShell script
            $scriptSelected = $ps1Options[$userChoice - 1] + ".ps1"
            $scriptPath = Join-Path $functionsDirectory $scriptSelected #.FullName
            Write-Host "Running script: $($ps1Options[$userChoice - 1])" -ForegroundColor Green
            Start-Sleep .75
            Unblock-File $scriptPath
        
            . $scriptPath
        } elseif ($userChoice -le ($ps1Options.Count + $subOptions.Count)) {
            # Enter the selected subdirectory
            $selectedDir = $subdirectories[$userChoice - $ps1Options.Count - 1]
            if ((Get-ChildItem -Path $selectedDir.FullName).Count -eq 0) {
                Write-Host "Selected subdirectory is empty." -ForegroundColor Red
                Start-Sleep .75
            } else {
                $functionsDirectory = Join-Path $functionsDirectory $selectedDir
                Write-Host "Entered the selected subdirectory." -ForegroundColor Blue
                Start-Sleep .75
            }
        } elseif (($userChoice -eq $($($ps1Options.Count) + $($subOptions.Count) + 1) -and ($optionToQuit -eq 0))) {
            # Go back one directory if not in the starting directory
            $functionsDirectory = Split-Path -Path $functionsDirectory -Parent
            Clear-Host
            Write-Host "Went back one directory." -ForegroundColor Cyan
        } elseif ((($userChoice -eq $($($ps1Options.Count) + $($subOptions.Count) + 1) -or ($userChoice -eq 'q') -or ($userChoice -eq 'quit'))-and ($optionToQuit -eq 1))) {
            $userChoice = 'quit'
            Write-Host "Exiting CommandCentral..."
            Start-Sleep .75
        } else {
            $userChoice = $null
            Write-Host "Invalid entry, please enter an option from the list" -ForegroundColor Red
            Start-Sleep .75
        }

        # Clear the console
        Clear-Host

    }
 
    # Clear the console
    Clear-Host

}

# Call the Main function
Main
