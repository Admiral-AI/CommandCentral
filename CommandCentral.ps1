# Main function
function Main {
    
    # testing Updates using this line

    # Set transcript log path based on 
    $tramscriptLogPath = Join-Path -Path $PSScriptRoot -ChildPath "\SystemD\Log\transcriptLog.txt"
    Start-Transcript $tramscriptLogPath

    # Set the github repository location
    $scriptGithubUri = "https://github.com/Admiral-AI/CommandCentral/raw/main/CommandCentral.ps1"

    # Clear the console
    Clear-Host

    Get-UserCredentials

    Stop-Transcript
}

# Function to get user credentials
function Get-UserCredentials {
    <#
    param (
        [string]$startingDirectory
    )
    #>
    
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
        Sleep 2
    }

    # Clear the screen before heading to the next functions
    Clear-Host

    # Call the Check-Updates function
    Check-Updates

}

# Function to check for module and script updates
function Check-Updates {
    
    #Need to add check for RSAT install
    <#if($null -eq (Get-Module -ListAvailable -Name ActiveDirectory))
    {
        Write-Host -ForegroundColor Red "Remote Server Administration Tools isn't installed!"
        Try{
            Start-Process powershell -Verb runas -PassThru -ArgumentList `
            "'Installing RSAT...'; Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Add-WindowsCapability -Online; Read-Host 'Please reboot your computer to complete installation'"
            }
        Catch{Write-Host -ForegroundColor Red "Installation failed. Please install manually and run this tool again";exit}
    }#>

    $scriptOnGithub = $(Invoke-RestMethod -Uri $scriptGithubUri).Trim()
    $scriptOnLocalDisk = Get-Content -Path $($PSCommandPath) -Raw

    # Use Compare-Object to compare the contents of the two files
    $fileComparison = Compare-Object -ReferenceObject ($scriptOnGithub) -DifferenceObject ($scriptOnLocalDisk)

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
        Set-DisplayMenu
    } else {
        Invoke-WebRequest -Uri $scriptGithubUri -OutFile $PSCommandPath
        Start-Sleep .75
        Write-Host "Attempted to pull update, now opening script again..."
        Start-Process powershell.exe -ArgumentList "-File `"$($scriptPath)`""
        Write-Host "Exiting CommandCentral..."
        Start-Sleep .75
    }
}

# Function to display a menu and handle user inpu
function Set-DisplayMenu {
    <# Parameters from Main function
    param (
        [string]$startingDirectory
    )
    #>

    # Define the directory where the PowerShell scripts and 'menus' are located
    $functionDirectory = "Functions"
    # Combine the root directory with the script directory
    $startingDirectory = Join-Path $PSScriptRoot $functionDirectory
    
    # Set the working directory to the starting directory
    $workingDirectory = $startingDirectory
    Set-Location $workingDirectory

    $logoForMenu =  @"
     _   _   _   _   _   _   _     _   _   _   _   _   _   _            
    / \ / \ / \ / \ / \ / \ / \ | / \ / \ / \ / \ / \ / \ / \ 
   ( C | o | m | m | a | n | d  |  C | e | n | t | r | a | l )
    \_/ \_/ \_/ \_/ \_/ \_/ \_/ | \_/ \_/ \_/ \_/ \_/ \_/ \_/                                                             
                                         By Admiral-AI
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
         Making the simple complicated is commonplace;            
Making the complicated simple, awesomely simple, that's creativity

"@

    # Loop until the user chooses to quit
    while ($userChoice -ne 'quit') {

        Write-Host $logoForMenu -ForegroundColor DarkYellow

        # Check if the starting and working directories match
        if ($startingDirectory -eq $workingDirectory) {
            $optionToQuit = 1
            # Debug: Provide information about the option to quit
        } else {
            $optionToQuit = 0
            # Debug: Provide information about the option to go back one directory
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
            Unblock-File $scriptPath
        
            . $scriptPath
        } elseif ($userChoice -le ($ps1Options.Count + $subOptions.Count)) {
            # Enter the selected subdirectory
            $selectedDir = $subdirectories[$userChoice - $ps1Options.Count - 1]
            if ((Get-ChildItem -Path $selectedDir.FullName).Count -eq 0) {
                Write-Host "Selected subdirectory is empty." -ForegroundColor Red
                Start-Sleep .75
            } else {
                $workingDirectory = Join-Path $workingDirectory $selectedDir
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
