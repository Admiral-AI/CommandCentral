<#
.SYNOPSIS
   This script uninstalls apps based on approval factors thereby "resetting" machines to their orginal posture.

.DESCRIPTION
   TBD 

.AUTHOR
   Admiral-AI (https://github.com/Admiral-AI)

.DATE
   2023-12-17

.VERSION
   1.0

.LICENSE
   This script is licensed under the GNU GENERAL PUBLIC LICENSE v3.0

#>

function Main {
    # Initialize variables
    $startVariables = Start-Variables

    # Example: Assuming $DomainAdminMode is a boolean variable passed from another script
    $domainAdminMode = $DomainAdminMode

    # Get remote computer names
    $computerNames = Get-RemoteComputerNames -DomainAdminMode $domainAdminMode -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

    # Get installed apps data
    $installedAppsData = Get-InstalledAppsData -ComputerNames $computerNames -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource -LogFilePath $startVariables.LogFilePath

    Write-Host $installedAppsData

    # Get app approval for each computer
    $appApprovalResult = Get-AppApproval -PreApprovedAppsList $startVariables.PreApprovedAppsList -InstalledAppsData $installedAppsData -LogFilePath $startVariables.LogFilePath -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

    # Check for quiet uninstall for each computer (only for unapproved apps)
    $checkQuietUninstallResult = Check-QuietUninstall -InstalledAppsData $installedAppsData -LogFilePath $startVariables.LogFilePath -UnapprovedApps $appApprovalResult.AppsForUninstall -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

    # Search CSV for uninstall options for apps without quiet uninstall key
    $searchCSVResult = Search-CSVForUninstallOptions -NonQuietKeyApps $checkQuietUninstallResult.NonQuietUninstallApps -UninstallOptionsDBPath $startVariables.UninstallOptionsDBPath -LogFilePath $startVariables.LogFilePath -AppsForQuietUninstall $checkQuietUninstallResult.QuietUninstallApps -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

    # Sort apps by installer type
    $sortedApps = Sort-AppsByInstallerType -AppsNotFoundInDatabase $searchCSVResult.notFoundApps -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource
    
    # Begin Brute force uninstall
    Uninstall-Launcher -QuietUninstallApps $searchCSVResult.foundApps -MsiInstallerApps $sortedApps.MSIInstallerApps -ExeInstallerApps $sortedApps.OtherInstallerApps -CSVFilePath $startVariables.UninstallOptionsDBPath -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource
}

function Start-Variables {

    #Define event log identifiers
    $windowsEventLogName = "Application"
    $windowsEventLogSource = "CC-Uninstaller"

    # Create the event log if it doesn't exist
    if (-not (Get-EventLog -LogName $windowsEventLogName -Source $windowsEventLogSource -ErrorAction SilentlyContinue)) {
        New-EventLog -LogName $windowsEventLogName -Source $windowsEventLogSource -ErrorAction SilentlyContinue
    }

    # List of apps to exclude from uninstallation
    $preApprovedAppsList = @(
		
		# Critical apps for test on VM
		"Red Hat QXL controller",
		"Update for Windows 10 for x64-based Systems (KB5001716)",
		"ViGEm Bus Driver",
		"Virtio-win-driver-installer",
		"QEMU guest agent",
		"Spice Agent 0.10.0-5 (64-bit)",
		"TeamViewer",
		"Virtio-win-guest-tools"
        
    )

    # Set global log location and ensure the log directory exists
    $logFilePath = "C:\ProgramData\CommandCentral\CC-Uninstaller\Log\"
    if (-not (Test-Path $logFilePath)) {
        New-Item -ItemType Directory -Path $logFilePath | Out-Null
    }
    

    # Set uninstall CSV location
    $uninstallOptionsDBPath = "C:\ProgramData\CommandCentral\CC-Uninstaller\Uninstall.csv"

    $startVariables = @{
        PreApprovedAppsList = $preApprovedAppsList
        LogFilePath = $logFilePath
        UninstallOptionsDBPath = $uninstallOptionsDBPath
        WindowsEventLogName = $windowsEventLogName
        WindowsEventLogSource = $windowsEventLogSource
    }

    return $startVariables
}

function Get-RemoteComputerNames {
    param (
        [bool]$DomainAdminMode,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    #Event log signifying startup of script
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1910 -Message "$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) began CC-Uninstaller script"
    
    #Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Get-RemoteComputerNames function"

    while ($true) {
        if ($DomainAdminMode) {
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1030 -Message "Script entered automation mode as DomainAdminMode was set to true"
            # If in 'domainadmin' mode, prompt for a file containing a list of computer names
            Write-Host "Enter the path to the file containing computer names"
            Write-Host "[e.g., C:\Path\To\ComputerNames.txt] or enter 'q' to exit:"
            $fileName = Read-Host 
            
            if ($fileName -eq 'q') {
                
                #Event log signifying stopping of script
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1911 -Message "$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) exited script (multi-PC) via option 'q'"
                
                #Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script (multi-PC) due to user exit ('q' option in Get-RemoteComputerNames)."
                
                exit
            }

            try {
                $computerNames = Get-Content $fileName -ErrorAction Stop
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1200 -Message "$($fileName) was validated. File was provided by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
                break  # Break out of the loop if file reading is successful
            } catch {
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 2030 -Message "The hostnames file provided was not valid"
                Write-Host "Error reading the file. Please make sure the file exists and is accessible or enter 'quit' to exit."
            }
        } else {
            # If not in 'domainadmin' mode, prompt for a single computer name
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1031 -Message "Script entered single mode as DomainAdminMode was set to false"
            $computerName = Read-Host "Enter the computer name (or type 'q' to exit)"
            
            if ($computerName -eq 'q') {
                #Event log signifying stopping of script
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1911 -Message "$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) exited script (single-PC) via option 'q'"
                
                #Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script due to user exit ('q' option in Get-RemoteComputerNames)."
                
                exit
            }

            $computerNames = @($computerName)
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1200 -Message "$($computerName) was provided by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
            break  # Break out of the loop since a single computer name is obtained
        }
    }

    Write-Information "$($computerNames) was provided by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    Write-Information "End of function"

    #Event log signifying script is exiting current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exited Get-RemoteComputerNames function"

    return $computerNames
}

function Get-InstalledAppsData {
    param (
        [string[]]$ComputerNames,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource,
        [string]$LogFilePath
    )

    # Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Get-InstalledAppsData function"

    $installedAppsData = @{}

    foreach ($computerName in $ComputerNames) {
        
        # Event log and write back to console informing of script processing provided hostnames
        Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Script attempting to reach $($computerName)"
        Write-Host "Processing computer: $computerName"

        try {
            
            # Use Invoke-Command to run the Get-InstalledApps logic remotely
            $apps = Invoke-Command -ComputerName $computerName -ScriptBlock {
                Get-ChildItem -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -and $_.UninstallString }
            } -ErrorAction Stop

            $installedAppsData[$computerName] = $apps

            # Event log and write back to console informing of script processing provided hostnames
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Script managed to get registry data from $($computerName)"
            Write-Host "Completed processing computer: $computerName"

        } catch {

            $errorMessage = $_.Exception.Message
            
            # Event log and write back to console informing of script processing provided hostnames
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1051 -Message "Script failed to get registry data from $($computerName). Script returned: $($errorMessage)"
            Write-Host "Failed to retrieve installed apps on $computerName. Error: $errorMessage"

            # Log the error to a file or other logging mechanism if needed
            $childLogFilePath = "ErrorLog.txt"
            $fullPath = Join-Path -Path $LogFilePath -ChildPath $childLogFilePath
            $errorMessage | Out-File -Append -FilePath $fullPath -Force

        }
    }

    Write-Information "End of function"

    #Event log signifying script is exiting current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exited Get-InstalledAppsData function"

    return $installedAppsData
}

function Get-AppApproval {
    param (
        [array]$PreApprovedAppsList,
        [hashtable]$InstalledAppsData,
        [string]$LogFilePath,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    # Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Get-AppApproval function"


    $appsForBypass = @()
    $appsForUninstall = @()

    foreach ($computerName in $InstalledAppsData.Keys) {

        $registryDataForUninstall = $InstalledAppsData[$computerName]

        foreach ($app in $registryDataForUninstall) {
            $isApproved = $false

            foreach ($preApprovedApp in $PreApprovedAppsList) {
                if ($app.DisplayName -like "$preApprovedApp*") {
                    $logApprovedFilePath = Join-Path $LogFilePath "ApprovedApps.txt"
                    $app | Out-File -FilePath $logApprovedFilePath
                    $appsForBypass += $app
                    $isApproved = $true

                    # Logging approved app to make sure no false positives happen
                    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "$($app.DisplayName) approved on $($app.PSComputerName), script will bypass app"

                    break
                }
            }

            if (-not $isApproved) {
                $logUnapprovedFilePath = Join-Path $LogFilePath "UnapprovedApps.txt"
                $app | Out-File -FilePath $logUnapprovedFilePath
                $appsForUninstall += $app

                # Logging unapproved app to make sure no false positives happen
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1051 -Message "$($app.DisplayName) not approved on $($app.PSComputerName), script will attempt to uninstall app"

            }
        }
    }

    $appApprovalStatus = @{
        AppsForUninstall = $appsForUninstall
        AppsForBypass = $appsForBypass
    }

    Write-Information "End of function"

    # Event log signifying script is exiting current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exiting Get-AppApproval function"

    return $appApprovalStatus
}

function Check-QuietUninstall {
    param (
        [hashtable]$InstalledAppsData,
        [string]$LogFilePath,
        [array]$UnapprovedApps,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    # Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Check-QuietUninstall function"

    $quietUninstallApps = @()
    $nonQuietUninstallApps = @()

    $logQuietUninstallFilePath = Join-Path $LogFilePath "QuietUninstallApps.txt"
    $logNonQuietUninstallFilePath = Join-Path $LogFilePath "NonQuietUninstallApps.txt"

    foreach ($computerName in $InstalledAppsData.Keys) {
        Write-Host "Checking for quiet uninstall apps on computer: $computerName"

        $registryDataForCheck = $InstalledAppsData[$computerName]

        foreach ($app in $registryDataForCheck) {
            if ($UnapprovedApps -contains $app) {
                if ($app.QuietUninstallString) {
                    # Use the Parse-QuietUninstallOptions function
                    $quietOptionsResult = Parse-QuietUninstallOptions -QuietUninstallString $app.QuietUninstallString

                    # Add properties to the existing app object
                    $app | Add-Member -MemberType NoteProperty -Name ParsedQuietOptions -Value $quietOptionsResult.ParsedQuietOptions

                    # Event log to output the current app details
                    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Quiet uninstall options found for: $($app.DisplayName)"

                    # Store the app details in the array for quiet uninstall apps
                    $quietUninstallApps += $app
                } else {
                    
                    # Event log to output the current app details
                    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1051 -Message "Quiet uninstall options not found for: $($app.DisplayName)"
                    
                    # Store the app details in the array for non-quiet uninstall apps
                    $nonQuietUninstallApps += $app
                    $app | Out-File -FilePath $logNonQuietUninstallFilePath
                }
            }
        }
    }

    $checkQuietUninstallResult = @{
        QuietUninstallApps = $quietUninstallApps
        NonQuietUninstallApps = $nonQuietUninstallApps
    }

    Write-Information "End of function"

    # Event log signifying script is exiting current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exiting Check-QuietUninstall function"

    return $checkQuietUninstallResult
}

function Parse-QuietUninstallOptions {
    param (
        [string]$QuietUninstallString
    )

    # Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Parse-QuietUninstallOptions function"


    # Use regular expression to extract options after ".exe"
    $matches = [regex]::Matches($QuietUninstallString, '\.exe\s*(.*)')

    if ($matches.Success) {
        # Extract the options after ".exe"
        $wildcardOptions = $matches.Groups[1].Value

        # Remove leading space and double quotes
        $quietOptions = $wildcardOptions.TrimStart() -replace '^\s*["]+', '' -replace '\s*$', ''
        $quietOptions = $quietOptions -replace '^\s+', ''

        Write-Host "The quiet options are: $($quietOptions)"
        Sleep 2

        # Return both parsed quiet options and the original uninstall string
        return @{
            OriginalUninstallString = $QuietUninstallString
            ParsedQuietOptions = $quietOptions
        }
    } else {
        Write-Information "No quiet options found in the QuietUninstallString: $QuietUninstallString"
        return @{}
    }

    Write-Information "End of function"

    # Event log signifying script is in exiting function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exiting Parse-QuietUninstallOptions function"

}

function Search-CSVForUninstallOptions {
    param (
        [array]$NonQuietKeyApps,
        [string]$UninstallOptionsDBPath,
        [string]$LogFilePath,
        [array]$AppsForQuietUninstall,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    $foundApps = @()
    $notFoundApps = @()

    # Loop through apps without quiet uninstall key
    foreach ($app in $NonQuietKeyApps) {
        Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Searching CSV for uninstall options for $($app.DisplayName)"

        try {
            # Search for the app in the CSV file
            $csvEntry = Import-Csv $UninstallOptionsDBPath | Where-Object {
                $_.AppName -eq $app.DisplayName -and
                $_.Version -eq $app.DisplayVersion
            }

            if ($csvEntry) {
                # Add properties to the existing app object
                $app | Add-Member -MemberType NoteProperty -Name ParsedQuietOptions -Value $csvEntry.QuietOptions -split '\s+' | ForEach-Object { $_.Trim('"') }

                # Event log and write-back to transcript for found app details
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Found uninstall options for: $($app.DisplayName)"
                Write-Output "App Name: $($app.DisplayName), Version: $($app.DisplayVersion), Quiet Options: $($app.ParsedQuietOptions -join ' | ')"
                
                # If entry found, add to $foundApps
                $AppsForQuietUninstall += $app
            } else {
                # Event log and write-back to transcript for not found app details
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1051 -Message "No uninstall options found for: $($app.DisplayName)"
                Write-Output "App Name: $($app.DisplayName), Version: $($app.DisplayVersion) - No uninstall options found."

                # If no entry found, add to $notFoundApps
                $notFoundApps += $app
            }
        } catch {
            $errorMessage = $_.Exception.Message
            
            # Event log and write-back to transcript for error details
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 1051 -Message "Error searching CSV for $($app.DisplayName): $($errorMessage)"
            Write-Output "Error searching CSV for $($app.DisplayName): $($errorMessage)"
        }
    }
    
    # Combine found and not found apps into a single array named $csvSearchResult
    $csvSearchResult = @{
        foundApps = $AppsForQuietUninstall 
        notFoundApps = $notFoundApps
    }

    Write-Information "End of function"

    # Event log signifying script is exiting current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exited Search-CSVForUninstallOptions function"

    return $csvSearchResult
}

function Sort-AppsByInstallerType {
    param (
        [array]$AppsNotFoundInDatabase,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    $msiInstallerApps = @()
    $otherInstallerApps = @()

    # Event log signifying script is in the current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Sort-AppsByInstallerType function"

    foreach ($app in $AppsNotFoundInDatabase) {
        try {
            if ($app.UninstallString -match 'msiexec.*') {
                # Extract product code from the uninstall string
                $productCode = $app.UninstallString | Select-String -Pattern '{.*}' | ForEach-Object { $_.Matches.Value }

                <# Check if 'I' is present after 'msiexec' indicating a retard developer
                if ($app.UninstallString -match 'msiexec*/I*') {
                    # Replace 'I' with 'X'
                    $productCode = $productCode -replace '/I', '/X'
                }
                #>

                # Update uninstall string with quotes and modified product code
                $uninstallString = "MsiExec.exe /X `"$productCode`""

                # Set the uninstall string key to the cleaned data
                $app.UninstallString = $uninstallString            

                $app | Add-Member -MemberType NoteProperty -Name singleUninstallProductCode -Value $productCode
                Write-Host "Product code for $($app.DisplayName) is $($app.singleUninstallProductCode)"
                Write-Host "Full app: $($app)"

                $msiInstallerApps += $app
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "MSI installer type found for: $($app.DisplayName)"
            } else {
                $otherInstallerApps += $app
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1051 -Message "Other installer type found for: $($app.DisplayName)"
            }
        } catch {
            $errorMessage = $_.Exception.Message
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 1051 -Message "Failed to check installer type for $($app.DisplayName). Error: $($errorMessage)"

            # Log the error to a file or other logging mechanism if needed
            $logFilePath = "C:\ProgramData\CommandCentral\CC-Uninstaller\Log\ErrorLog.txt"
            $errorMessage | Out-File -Append -FilePath $logFilePath
        }
    }

    $sortedApps = @{
        MSIInstallerApps = $msiInstallerApps
        OtherInstallerApps = $otherInstallerApps
    }

    Write-Information "End of function"

    # Event log signifying script is exiting the current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exited Sort-AppsByInstallerType function"

    return $sortedApps
}

function Uninstall-Launcher {
    param (
        [array]$QuietUninstallApps,
        [array]$MsiInstallerApps,
        [array]$ExeInstallerApps,
        [string]$CSVFilePath,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    # Define common quiet uninstall switches for EXE installer array
    $commonExeQuietUninstallSwitches = @("/S", "/VERYSILENT", "/quiet", "/7")

    # Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Uninstall-Launcher function"

    # Uninstall QuietUninstallApps
    foreach ($quietUninstallApp in $QuietUninstallApps) {
        Write-Host "Attempting to uninstall (quiet) $($quietUninstallApp.DisplayName)"

        $exitCode = Uninstall-App -DisplayName $quietUninstallApp.DisplayName -UninstallString $quietUninstallApp.UninstallString -ParsedQuietOptions $quietUninstallApp.ParsedQuietOptions -ComputerName $quietUninstallApp.PSComputerName -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

        Write-Information "Exit code: $($exitCode) for $($quietUninstallApp) "

        if ($exitCode -eq 0) {
            Write-Host "Uninstall successful for $($quietUninstallApp.DisplayName)"
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Uninstall successful (quiet) for $($quietUninstallApp.DisplayName)"

            Export-AppDataToCsv -Apps $quietUninstallApp -CsvFilePath $CSVFilePath
        } else {
            Write-Host "Uninstall failed for $($quietUninstallApp.DisplayName) with exit code: $exitCode."
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 1051 -Message "Uninstall failed (quiet) for $($quietUninstallApp.DisplayName) with exit code $exitCode. Handling errors for this app."
            # Add your error handling logic for this app here
        }
    }

    # Uninstall MSI apps
    foreach ($msiApp in $MsiInstallerApps) {
        Write-Host "Attempting to uninstall MSI app: $($msiApp.DisplayName)"
        Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Attempting to uninstall MSI app: $($msiApp.DisplayName)"

        Write-Host $MsiInstallerApps
        Write-Host "app product code is: $($app.singleUninstallProductCode)"
        Write-Host $app.singleUninstallProductCode

        $exitCode = Uninstall-App -DisplayName $msiApp.DisplayName -UninstallString 'MsiExec.exe' -ParsedQuietOptions "/X $($msiApp.singleUninstallProductCode) /qn /norestart" -ComputerName $msiApp.PSComputerName -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource
        # $exitCode = Uninstall-App -DisplayName $msiApp.DisplayName -UninstallString $msiApp.UninstallString -ParsedQuietOptions "/qn /norestart" -ComputerName $msiApp.PSComputerName -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

        if ($exitCode -eq 0) {
            Write-Host "Uninstall successful for $($msiApp.DisplayName)"
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Uninstall successful for $($msiApp.DisplayName)"
        
            Export-AppDataToCsv -Apps $msiApp -CsvFilePath $CSVFilePath
        } else {
            Write-Host "Uninstall failed for $($msiApp.DisplayName) with exit code: $exitCode."
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 1051 -Message "Uninstall failed for $($msiApp.DisplayName) with exit code $exitCode. Handling errors for MSI apps."
            # Add your error handling logic for MSI apps here
        }
    }

    # Uninstall EXE apps
    foreach ($exeApp in $ExeInstallerApps) {
        Write-Host "Attempting to uninstall EXE app: $($exeApp.DisplayName)"
        Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Attempting to uninstall EXE app: $($exeApp.DisplayName)"

        # Attempt to uninstall with each quiet switch
        $uninstallSuccess = $false
        foreach ($quietSwitch in $commonExeQuietUninstallSwitches) {
            Write-Host "Trying uninstall with switch: $quietSwitch"
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Trying uninstall with switch: $quietSwitch"

            $exitCode = Uninstall-App -DisplayName $exeApp.DisplayName -UninstallString $exeApp.UninstallString -ParsedQuietOptions @($quietSwitch) -ComputerName $exeApp.PSComputerName -WindowsEventLogName $startVariables.WindowsEventLogName -WindowsEventLogSource $startVariables.WindowsEventLogSource

            if ($exitCode -eq 0) {
                Write-Host "Uninstall successful for $($exeApp.DisplayName)"
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1050 -Message "Uninstall successful for $($exeApp.DisplayName)"
                
                Export-AppDataToCsv -Apps $exeApp -Apps $quietUninstallApp -CsvFilePath $CSVFilePath -CsvFilePath $CSVFilePath
                break  # Exit the loop if uninstall is successful
            } else {
                Write-Host "Uninstall failed for $($exeApp.DisplayName) with exit code $exitCode. Retrying with a different switch."
                Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 1051 -Message "Uninstall failed for $($exeApp.DisplayName) with exit code: $exitCode. Retrying with a different switch."
                # Add your logic to retry with a different switch if necessary
                # For example, you can continue the loop and try the next switch
            }
        }

        if (-not $uninstallSuccess) {
            Write-Host "Uninstall failed for all attempts."
            Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Warning -EventID 1051 -Message "Uninstall failed for all attempts on all apps."
            # Add your error handling logic for EXE apps here
        }
    }

    # Event log signifying script is exiting current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Script exited Uninstall-Launcher function"

    Write-Information "End of function"

}

function Uninstall-App {
    param (
        [string]$DisplayName,
        [string]$UninstallString,
        [string[]]$ParsedQuietOptions,
        [string]$ComputerName,
        [string]$WindowsEventLogName,
        [string]$WindowsEventLogSource
    )

    # Event log signifying script is in current function
    Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1010 -Message "Script entered Uninstall-App function for $DisplayName"

    Write-Host "Attempting to uninstall $DisplayName on $ComputerName"
    Write-Host "Using $($UninstallString) with $($ParsedQuietOptions) as options"

    try {
        
        $scriptBlock = {
            
            Write-Host "**On $($env:ComputerName): Attempting to uninstall $($Using:DisplayName) on $($Using:ComputerName)"
            Write-Host "**On $($env:ComputerName): Using $($Using:UninstallString) with $($Using:ParsedQuietOptions) as options"
            Write-Host "**On $($env:ComputerName): $($PWD)"
            
            # Start the uninstall process
            $process = Start-Process -FilePath $($Using:UninstallString) -ArgumentList $($Using:ParsedQuietOptions) -PassThru
            $handle = $proc.Handle
            Write-Host "**On $($env:ComputerName): $($process)"

            # Set a timeout of 5 minutes (300 seconds)
            $timeout = (Get-Date).AddSeconds(15)

            # Check the process status every 10 seconds
            while ($process.HasExited -eq $false -and (Get-Date) -lt $timeout) {
                Start-Sleep -Seconds 10
                $process.Refresh()
            }

            if ($process.HasExited) {
                # Placeholder for possible error handling
            } else {
                # Placeholder for possible error handling
                Write-Host "The app has not exited"
            }

            # Return the exit code
            return $process.ExitCode
        }

        $exitCode = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock

        Write-Host "The exit code returned is: $($exitCode)"

        # Event log signifying script is exiting current function
        Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Information -EventID 1011 -Message "Exiting Uninstall-App function for $DisplayName"

        return $exitCode

    } catch {
        # Event log and information for any errors during uninstallation
        Write-EventLog -LogName $WindowsEventLogName -Source $WindowsEventLogSource -EntryType Error -EventID 1051 -Message "An error occurred during uninstallation of $DisplayName on $ComputerName. Error: $_"
        Write-Information "An error occurred during uninstallation of $DisplayName on $ComputerName. Error: $_"
        # Add your error handling logic here
        return 1  # Return a non-zero exit code to indicate failure
    }
}

function Export-AppDataToCsv {
    param (
        [array]$Apps,
        [string]$CsvFilePath
    )

    function Export-AppDataToCsv {
    param (
        [array]$Apps,
        [string]$CsvFilePath
    )

    # Check if the Apps array is not empty
    if ($Apps.Count -eq 0) {
        Write-Host "Error: The array of apps is empty."
        return
    }

    # Extract property names from the first app in the array
    $propertyNames = $Apps[0].PSObject.Properties | Select-Object -ExpandProperty Name

    # Create a CSV header using property names
    $csvHeader = $propertyNames -join ','

    # Write the header to the CSV file
    $csvHeader | Out-File -FilePath $CsvFilePath -Encoding UTF8

    # Append data for each app to the CSV file
    foreach ($app in $Apps) {
        $rowData = $propertyNames | ForEach-Object { $app.$_ }
        $rowData -join ',' | Add-Content -Path $CsvFilePath
    }

    Write-Host "CSV file created successfully at $CsvFilePath"
}

    <#

    # Create an array to store data for CSV export
    $csvData = @()

    # Iterate through each app
    foreach ($app in $Apps) {
        $appData = [ordered]@{}  # Using an ordered hashtable to maintain the property order

        # Add properties dynamically to the hashtable
        foreach ($property in $app.PSObject.Properties) {
            #$appData[$property.Name] = $property.Value
            # Add the app data to the CSV data array
            $csvData += New-Object $appData[$property.Name] -Property $property.Value
        }
    }

    # Export data to CSV file
    $csvData | Export-Csv -Path $CsvFilePath -NoTypeInformation -Force -Append

    #>

    Write-Host "Data exported to CSV file: $CsvFilePath"
}

# Start Logging
Start-Transcript -Path "C:\ProgramData\CommandCentral\CC-Uninstaller\Log\main.log" -Force

# Clear the console screen
Clear-Host

# Example: Set $DomainAdminMode as a boolean variable (true or false)
$DomainAdminMode = $false

# Execute Main, starting the script
Main

# Stopping Logging
Stop-Transcript

# Clear the console screen
Clear-Host
