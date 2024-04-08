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

    # Import settings file and set the variable to script access (indicates that all scripts run from this one can access the variable when passed)
    Set-Variable -Name settingsJSON -Scope script
    $settingsJSON = Get-Content .\SystemD\Settings.json
    $settingsJSON = $settingsJSON | ConvertFrom-Json

    # Set transcript log path based on 
    Start-Transcript $settingsJSON.Application_Settings.Log_Paths.CommandCentral_PSScript_Log -Append -Force

    # Clear the console
    Clear-Host

    # Start the domino effect of functions based on setting file update parameter
    if (($settingsJSON.Application_Settings.Updates.UpdatesOptIn) -eq $true) {
        Get-Updates
    } elseif (($settingsJSON.Application_Settings.Updates.UpdatesOptIn) -eq $false) {
        Get-UserCredentials
    } else {
        Write-Host "Setting file is unreadable or missing the update opt in parameter, please re-download or fix your setting file"
    }

    # Reset location before exiting, prevents errors when runnning in same terminal
    Set-Location $PSScriptRoot

    # Stop Transcript when finished with script
    Stop-Transcript
}

# Function to get user credentials
function Get-UserCredentials {

    # Load nested functions
    function Prompt_UserCredentials {
        param (
            [Parameter(Mandatory=$true)] [Object[]] $accountToQuery
        )

        $loopControl_UserCredentialPrompt = $true

        while ($loopControl_UserCredentialPrompt -eq $true) {
            # Collect the username and password and store in credential object.
            $userCred = Get-Credential -UserName "$($Env:UserDomain)\$($accountToQuery.SamAccountName)" -Message "Please provide your credentials for the following account: $($Env:UserDomain)\$($accountToQuery.SamAccountName)"

            if ($null -ne $userCred) {
                $nullCredentialTest = (($null -ne ($userCred.GetNetworkCredential().Password)) -and (($userCred.GetNetworkCredential().Password) -ne ""))
            }

            if ($nullCredentialTest -eq $true) {
                $loopControl_UserCredentialPrompt = $false
            } else {
                Write-Host "The supplied credntial was empty, please input a value"
            }

        }

        return $userCred
    }

    function Validate_UserCredentials {
        param (
            [Parameter(Mandatory=$true)] [pscredential] $userCred,
            [Parameter(Mandatory=$true)] [Object[]] $accountToQuery,
            [Parameter(Mandatory=$true)] [AllowEmptyCollection()] [array] $userCredArray
        )

        try {
            # Build the current domain
            $currentDomain = "LDAP://$($userCred.GetNetworkCredential().Domain)"

            # Get the user\password. The GetNetworkCredential only works for the passwrod because the current user
            # is the one who entered it.  Shouldn't be accessible to anything\one else.
            $username = $userCred.GetNetworkCredential().Username
            $password = $userCred.GetNetworkCredential().Password
        } catch {
            Write-Warning -Message ("There was a problem with what you entered: $($_.exception.message)")
            continue
        }

        # Do a quick query against the domain to authenticate the user.
        $domainQuery = New-Object System.DirectoryServices.DirectoryEntry($currentDomain,$username,$password)
        # If we get a result back with a name property then we're good to go and we can store the credential.
        if ($domainQuery.name) {
            Write-Host "Credential for: $($userCred.Username) was succesfully validated! Adding to storage..."
            New-StoredCredential -Target "CommandCentral-$($accountToQuery.SamAccountName)" -Credential $userCred -Persist ENTERPRISE
            $userCred = Get-StoredCredential -Target "CommandCentral-$($accountToQuery.SamAccountName)"
            $userCredArray += $userCred

            $loopControl_userCredCheck = $false
            $loopCounter_userCredCheck = 0
            Remove-Variable password -Force
        } else {
            $loopCounter_userCredCheck++
            Write-Warning -Message ("The password you entered for $($username) was incorrect.  Attempt(s) $($loopCounter_userCredCheck). Please try again.")
        }

        $validationFunction_ReturnHashtable = @{
            UserCredArray = $userCredArray
            LoopCounter_UserCredCheck = $loopCounter_userCredCheck
            LoopControl_UserCredCheck = $loopControl_userCredCheck
        }

        return $validationFunction_ReturnHashtable

    }

    # Set the userCredArray variable to script to allow all scripts that are run from this script to access the credentials when passed
    Set-Variable -Name userCredArray -Scope script
    $userCredArray = @()

    # Get the CIM_ComputerSystem CIM class
    $computerSystem = Get-CimInstance Win32_ComputerSystem

    # Check if the domain property is not empty
    if ($computerSystem.PartofDomain -eq $true) {
        Write-Host "Computer is in a domain: $($computerSystem.Domain)"
        
        $userFirstName = $(Get-ADUser -Identity $env:username).GivenName
        $userLastName = $(Get-ADUser -Identity $env:username).Surname
        $accountsToQuery = Get-ADUser -Filter $("(GivenName -like '*$($userFirstName)*') -and (sn -like '*$($userLastName)*') -and (Enabled -eq 'True')")

        foreach ($accountToQuery in $accountsToQuery) {

            # Set the loop control starting values
            $loopCounter_userCredCheck = 0
            $loopControl_userCredCheck = $true

            try {
                $userCred = Get-StoredCredential -Target "CommandCentral-$($accountToQuery.SamAccountName)"
            } catch {
                Write-Host "Retrieving stored credential failed, check the runtime log, re-install/run the script or contact your administrator"
                Write-Host "Proper error handling was not added here, exiting script"
                break
            }

            if ($null -eq $userCred) {

                while ($loopControl_userCredCheck -eq $true) {

                    if ($loopCounter_userCredCheck -ge 3) {
                        Write-Warning -Message ("Take a deep breath and perhaps a break. You have entered your password $($loopCounter_userCredCheck) times incorrectly")
                        Write-Host "We will now take a 30 second break to slow down"
                        Start-Sleep -Seconds 30
                    }

                    $userCred = Prompt_UserCredentials -accountToQuery $accountToQuery

                    $validationFunction_ReturnHashtable = Validate_UserCredentials -userCred $userCred -accountToQuery $accountToQuery -userCredArray $userCredArray

                    $loopCounter_userCredCheck = $validationFunction_ReturnHashtable.LoopCounter_UserCredCheck
                    $loopControl_userCredCheck = $validationFunction_ReturnHashtable.LoopControl_UserCredCheck
                    $userCredArray = $validationFunction_ReturnHashtable.UserCredArray
                    
                }

            } elseif ($null -ne $userCred) {

                # One time credential check since credentials are stored, if they are good then the while block should be skipped
                $validationFunction_ReturnHashtable = Validate_UserCredentials -userCred $userCred -accountToQuery $accountToQuery -userCredArray $userCredArray

                $loopCounter_userCredCheck = $validationFunction_ReturnHashtable.LoopCounter_UserCredCheck
                $loopControl_userCredCheck = $validationFunction_ReturnHashtable.LoopControl_UserCredCheck
                $userCredArray = $validationFunction_ReturnHashtable.UserCredArray

                while ($loopControl_userCredCheck -eq $true) {

                    if ($loopCounter_userCredCheck -ge 3) {
                        Write-Warning -Message ("Take a deep breath and perhaps a break. You have entered your password $($loopCounter_userCredCheck) times incorrectly")
                        Write-Host "We will now take a 30 second break to slow down"
                        Start-Sleep -Seconds 30
                    }

                    $userCred = Prompt_UserCredentials -accountToQuery $accountToQuery

                    $validationFunction_ReturnHashtable = Validate_UserCredentials -userCred $userCred -accountToQuery $accountToQuery -userCredArray $userCredArray

                    $loopCounter_userCredCheck = $validationFunction_ReturnHashtable.LoopCounter_UserCredCheck
                    $loopControl_userCredCheck = $validationFunction_ReturnHashtable.LoopControl_UserCredCheck
                    $userCredArray = $validationFunction_ReturnHashtable.UserCredArray
                    
                }

            } else {

                Write-Host "Something happened...try restarting the script, redownload, or contact your administrator"
                Start-Sleep 5

            }

            # Clear variable to ensure it can't be misused or run into errors
            Clear-Variable -Name userCred -Force

        }
    } else {

        Write-Host "Computer is in a workgroup, credentials are assumed to not be needed (administrator running script)"
        Start-Sleep 2

    }

    Write-Host "Finished credential validation, proceeding to menu..."

    # Clear the screen before heading to the next functions
    Clear-Host

    # Call the menu function
    Set-DisplayMenu

}

# Function to check for module and script updates
function Get-Updates {

    <# Need to add check for RSAT install
    # Get the CIM_ComputerSystem CIM class and set variable to global
    $computerSystem = Get-CimInstance Win32_ComputerSystem

     Check if the domain property is not empty
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
    $CC_MenuHashTable = @{
        UserCredArray = $userCredArray
        SettingsJSON = $settingsJSON
    }

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
            . $scriptPath -CC_MenuHashTable $CC_MenuHashTable
            
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
