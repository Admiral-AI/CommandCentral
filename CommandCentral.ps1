<#
.DESCRIPTION
  Provides a easy to use and customizable menu to launch scripts with shared parameters (i.e. passwords)

.NOTES
  Version:        1.0
  Author:         Admiral-AI
  Portfolio:      https://github.com/Admiral-AI
  Creation Date:  January 4, 2024
#>

# Main function
function Main {

    Set-Location $PSScriptRoot

    # Import settings file and set the variable to script access (indicates that all scripts run from this one can access the variable when passed)
    Set-Variable -Name settingsJSON -Scope script
    $settingsJSON = Get-Content .\SystemD\Settings.json | ConvertFrom-Json

    # Set transcript log path based on 
    Start-Transcript $settingsJSON.Application_Settings.Log_Paths.CommandCentral_PSScript_Log -Append -Force

    # Clear the console
    Clear-Host

    # Start the domino effect of functions based on setting file update parameter
    if (($settingsJSON.Application_Settings.Updates.UpdatesOptIn) -eq $true) {
        Get-Updates
    } elseif (($settingsJSON.Application_Settings.Updates.UpdatesOptIn) -eq $false) {
        Set-DisplayMenu
    } else {
        Write-Host "Settings file is unreadable or is missing the update opt in parameter, please re-download the script or fix your setting file"
    }

    # Reset location before exiting, prevents errors and allows you to re-run the script in same terminal window
    Set-Location $PSScriptRoot

    # Stop Transcript when finished with script
    Stop-Transcript
}

# Function to check for module and script updates
function Get-Updates {

    $providedJSONUpdateLocation = $settingsJSON.Application_Settings.Updates.UpdateRetrievalLocation

    switch ($providedJSONUpdateLocation) {
        "Main_Repo" {$repoToPullFrom = $settingsJSON.Application_Settings.Updates.Main_Repo.CommandCentral_Script_mainGitRepo ; break}
        "Dev_Repo" {$repoToPullFrom = $settingsJSON.Application_Settings.Updates.Dev_Repo.CommandCentral_Script_devGitRepo ; break}
        "Local_Repo" {$repoToPullFrom = $settingsJSON.Application_Settings.Updates.Local_Repo.CommandCentral_Script_localRepo ; break}
    }

    if ((Invoke-WebRequest $repoToPullFrom -DisableKeepAlive -UseBasicParsing -Method Head).StatusDescription -eq "OK") {
        $scriptPulledfromRepo = $(Invoke-RestMethod -Uri $repoToPullFrom)
    } elseif ((Test-Path $repoToPullFrom) -eq $true) {
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
                Write-Host "Module: $($module) exists, no need to import or install"
            } 
            else {
                Write-Host "Module: $($module) does not exist. Installing..."
                Install-Module -Name $module -Scope CurrentUser -Force
                Write-Host "Importing $($module) module..."
                Import-Module -Name $module -Force
            }
        }
        
        # Clear the screen before heading to the next functions
        Clear-Host
        
        # Call the Get-UserCredentials function
        Get-UserCredentials

    } else { 
        $scriptPulledfromRepo | Out-File -FilePath $($PSCommandPath) -NoNewline

        Write-Host "Attempted to write updates, now opening script again..."
        Start-Sleep 2
        Start-Process powershell.exe -ArgumentList "-File `"$($PSCommandPath)`""
        Write-Host "Exiting CommandCentral..."
        Start-Sleep .75
    }
}

# Function to display a menu and handle user input
function Set-DisplayMenu {

    # Package important variables in a hashtable in preparation to pass to scripts
    $CC_MainMenu_HashTable = @{
        CCScriptRoot = $($PSScriptRoot)
        UserCreds_HashTable = $userCreds_HashTable
        SettingsJSON = $settingsJSON
    }

    # Define the directories where the PowerShell scripts, 'menus', and settings are located
    $rootScriptDirectory = $PSScriptroot
    $systemDDirectory = Join-Path -Path $PSScriptroot -ChildPath $settingsJSON.Application_Settings.SystemD_Path
    $workingDirectory = Join-Path -Path $rootScriptDirectory -ChildPath $settingsJSON.Application_Settings.Functions_Path

    # Set the starting directory to the location of the 'Functions' directory
    $startingDirectory = $workingDirectory
    Set-Location $workingDirectory

    # Using SystemD location setting, pull logo file
    $logoFileLocation = Join-Path -Path $($systemDDirectory) -ChildPath \Logo.txt
    $logoForMenu = Get-Content $logoFileLocation -Raw

    # Loop to display menus until the user chooses to quit
    while ($userChoice -ne 'quit') {

        Write-Host $logoForMenu -ForegroundColor DarkYellow

        # Check if the starting and working directories match and provide option to quit accordingly
        if ($startingDirectory -eq $workingDirectory) {
            $optionToQuit = 1
        } else {
            $optionToQuit = 0
        }

        # List .ps1 files in the working directory
        $ps1FilesArray = Get-ChildItem -Path $workingDirectory -Filter "*.ps1"
        $ps1Options = @()
        Foreach ($ps1File in $ps1FilesArray) {
            $ps1Options += ($ps1File.BaseName)
        }

        # List subdirectories in the working directory
        $subdirectories = Get-ChildItem -Path $workingDirectory -Directory
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
            $scriptPath = Join-Path $workingDirectory $scriptSelected #.FullName
            Write-Host "Running script: $($ps1Options[$userChoice - 1])" -ForegroundColor Green
            Start-Sleep .75

            # Unblock the file on Windows as windows will block downloaded scripts.
            # Any PowerShell version less than 6 is Windows as it was not cross platform then. 
            # Any version above 6 will have the "IsWindows" variable.
            if (($PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows -eq $true)) {
                Unblock-File $scriptPath
            }
            . $scriptPath -CC_MainMenu_HashTable $CC_MainMenu_HashTable
            
        } elseif ($userChoice -le ($ps1Options.Count + $subOptions.Count)) {
            # Enter the selected subdirectory
            $selectedDir = $subdirectories[$userChoice - $ps1Options.Count - 1]
            if ((Get-ChildItem -Path $selectedDir.FullName).Count -eq 0) {
                Write-Host "Selected subdirectory is empty." -ForegroundColor Red
                Start-Sleep .75
            } else {
                $workingDirectory = Join-Path $workingDirectory $selectedDir.BaseName
                Write-Host "Entered the selected subdirectory." -ForegroundColor Blue
                Start-Sleep .75
            }
        } elseif (($userChoice -eq $($($ps1Options.Count) + $($subOptions.Count) + 1) -and ($optionToQuit -eq 0))) {
            # Go back one directory if not in the starting directory
            $workingDirectory = Split-Path -Path $workingDirectory -Parent
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
