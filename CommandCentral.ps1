# Main function
function Main {

    # Clear the console
    Clear-Host

    Get-UserCredentials

}

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
        
        # Will further expand on this section to query AD to try to find all admin account associated with the current user
        # But for the time being I will statically program 3 credential sets: Regular, Sprt, ADM

        # Try to get stored credentials, and if any of them are null, prompt for credentials
        $regUserCred = Get-StoredCredential -Target CommandCentral-User -AsCredentialObject
        $sprtUserCred = Get-StoredCredential -Target CommandCentral-Sprt -AsCredentialObject
        $admUserCred = Get-StoredCredential -Target CommandCentral-ADM -AsCredentialObject

        # Check if any of the stored credentials are null, and prompt for credentials if needed
        if ($null -eq $regUserCred) {
            $regUserCred = Get-Credential -UserName $env:USERNAME -Message "Please provide your credentials for the following account: $($env:USERNAME)"
            $regUserCred = New-StoredCredential -Target CommandCentral-User -Credential $regUserCred -Persist ENTERPRISE
        }

        if ($null -eq $sprtUserCred) {
            $sprtUsername = "$($env:USERNAME)_sprt"
            $sprtUserCred = Get-Credential -UserName $sprtUsername -Message "Please provide your credentials for the following account: $($env:USERNAME)_sprt"
            $sprtUserCred = New-StoredCredential -Target CommandCentral-Sprt -Credential $sprtUserCred -Persist ENTERPRISE
        }

        if ($null -eq $admUserCred) {
            $admUsername = "$($env:USERNAME)_adm"
            $admUserCred = Get-Credential -UserName $admUsername -Message "Please provide your credentials for the following account: $($env:USERNAME)_adm"
            $admUserCred = New-StoredCredential -Target CommandCentral-ADM -Credential $admUserCred -Persist ENTERPRISE
        }

    } else {
        Write-Host "Computer is in a workgroup, credentials are assumed to not be needed (administrator running script)"
    }

    # Clear the screen before heading to the next functions
    Clear-Host

    # Call the Set-DisplayMenu function and pass the starting directory from Main
    Set-DisplayMenu -startingDirectory $startingDirectory

}

# Function to display a menu and handle user input
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
            Unblock-File $scriptPath
        
            . $scriptPath
        } elseif ($userChoice -le ($ps1Options.Count + $subOptions.Count)) {
            # Enter the selected subdirectory
            $selectedDir = $subdirectories[$userChoice - $ps1Options.Count - 1]
            if ((Get-ChildItem -Path $selectedDir.FullName).Count -eq 0) {
                Write-Host "Selected subdirectory is empty." -ForegroundColor Red
            } else {
                $workingDirectory = Join-Path $workingDirectory $selectedDir
                Write-Host "Entered the selected subdirectory." -ForegroundColor Blue
            }
        } elseif (($userChoice -eq $($($ps1Options.Count) + $($subOptions.Count) + 1) -and ($optionToQuit -eq 0))) {
            # Go back one directory if not in the starting directory
            $workingDirectory = Split-Path -Path $workingDirectory -Parent
            Clear-Host
            Write-Host "Went back one directory." -ForegroundColor Cyan
        } elseif ((($userChoice -eq $($($ps1Options.Count) + $($subOptions.Count) + 1) -or ($userChoice -eq 'q') -or ($userChoice -eq 'quit'))-and ($optionToQuit -eq 1))) {
            $userChoice = 'quit'
            Write-Host "Exiting CommandCentral..."
            Start-Sleep .5
        } else {
            $userChoice = $null
            Write-Host "Invalid entry, please enter an option from the list" -ForegroundColor Red
            Start-Sleep .5
        }
        # Clear the console
        # Clear-Host
    }
 
    # Clear the console
    Clear-Host

}

# Call the Main function
Main
