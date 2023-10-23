function Main {

    $startVariableArray = Start_Variables
    
    $registryDataForUninstall = Get_InstalledApps

    $appApprovalStatus = Get_AppApproval -preApprovedAppsList $startVariableArray.preApprovedAppsList -registryDataForUninstall $registryDataForUninstall -logFilePath $startVariableArray.logFilePath

    $uninstallDatabaseResults = Check_UninstallDatabase -unapprovedApps $appApprovalStatus.appsForUninstall -logFilePath $startVariableArray.logFilePath -uninstallOptionsDBPath $startVariableArray.uninstallOptionsDBPath

    $sortedAppsByMethod = Sort_InstallMethod -appsToSort $uninstallDatabaseResults.UnapprovedAppsWithoutOptions -logFilePath $startVariableArray.logFilePath          

    $bruteUninstallResults = Start_UninstallApps_via_Brute -appsInstalledWithMSI $sortedAppsByMethod.appsInstalledWithMSI -appsInstalledWithOther $sortedAppsByMethod.appsInstalledWithOther -logFilePath $startVariableArray.logFilePath

    
}

<#

#>

#$registryDataForUninstall[0] | Set-ItemProperty -Name UninstallPosition -Value "1"

function Start_Variables {
    # List of apps to exclude from uninstallation
    $preApprovedAppsList = @(	
	#Test on VM
	"Red Hat QXL controller",
	"Update for Windows 10 for x64-based Systems (KB5001716)",
	"ViGEm Bus Driver",
	"Virtio-win-driver-installer",
  	"QEMU guest agent",
	"Spice Agent 0.10.0-5 (64-bit)",
	"TeamViewer",
	"Virtio-win-guest-tools"
    )

    $logFilePath = "C:\Temp\Log\"

    $uninstallOptionsDBPath = "C:\Temp\Critical\uninstallOptionsDB.csv"

    $startVariableArray = [ordered]@{
        preApprovedAppsList = $preApprovedAppsList
        logFilePath = $logFilePath
        uninstallOptionsDBPath = $uninstallOptionsDBPath
    }

    return $startVariableArray
}

function Get_InstalledApps {
    # Get a list of all apps & uninstall strings from the Registry
    $registryDataForUninstall = Get-ChildItem -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -and $_.UninstallString }

    return $registryDataForUninstall
}

function Get_AppApproval {
    param (
        [array]$preApprovedAppsList,
        [array]$registryDataForUninstall,
        [string]$logFilePath
    )
    
    # Arrays for approved/unapproved apps
    $appsForBypass = @()
    $appsForUninstall = @()
  
    foreach ($app in $registryDataForUninstall) {

        $isApproved = $false

        foreach ($preApprovedApp in $preApprovedAppsList) {
            if ($app.DisplayName -like "$preApprovedApp*") {

                # Set file name in path using global log location
                $logApprovedFilePath = ($($logFilePath + "ApprovedApps.txt"))
                
                $app | Out-File -FilePath $logApprovedFilePath -Append
                $appsForBypass += $app
                $isApproved = $true
                break
            }
        }

        if (-not $isApproved) {
            
            # Set file name in path using global log location
            $logUnapprovedFilePath = ($($logFilePath + "UnapprovedApps.txt"))

            $app | Out-File -FilePath $logUnapprovedFilePath -Append
            $appsForUninstall += $app                        
        }
    }

    $appApprovalStatus = [ordered]@{
        appsForUninstall = $appsForUninstall 
        appsForBypass = $appsForBypass
        }

    return $appApprovalStatus
}

function Check_UninstallDatabase {
    param (
        [array]$unapprovedApps,
        [string]$logFilePath,
        [string]$uninstallOptionsDBPath
    )
    
    # Initialize arrays to hold uninstall options and unapproved apps without options.
    $uninstallOptions = @()
    $unapprovedAppsWithoutOptions = @()

    # Read the CSV file into a variable.
    $uninstallOptionsData = Import-Csv -Path $uninstallOptionsDBPath

    # Iterate through the unapproved apps.
    foreach ($app in $unapprovedApps) {
        $matchedEntry = $uninstallOptionsData | Where-Object { $_.DisplayName -like "*$app*" }

        if ($matchedEntry) {
            # If a matching entry is found, add it to the uninstall options array.
            $uninstallOptions += $matchedEntry

            # Logging
            $logMatchedFilePath = ($($logFilePath + "UninstallOptions.txt"))
            $app | Out-File -FilePath $logMatchedFilePath -Append

        } else {
            # If no matching entry is found, add the app to the unapproved apps without options array.
            $unapprovedAppsWithoutOptions += $app

            # Logging
            $logUnmatchedFilePath = ($($logFilePath + "UnapprovedAppsWithoutOptions.txt"))
            $app | Out-File -FilePath $logUnmatchedFilePath -Append
        }
    }

    # Return the results.
    $uninstallDatabaseResults = [ordered]@{
        UninstallOptions = $uninstallOptions
        UnapprovedAppsWithoutOptions = $unapprovedAppsWithoutOptions
    }

    return $uninstallDatabaseResults
}

function Sort_InstallMethod {
    param (
        [array]$appsToSort,
        [string]$logFilePath
    )

    # Initialize arrays to hold apps installed with MSI and other apps.
    $appsInstalledWithMSI = @()
    $appsInstalledWithOther = @()

    foreach ($app in $appsToSort) {
        if ($app.UninstallString -like "msiexec.exe*") {
            # If "msiexec.exe" is present in the uninstall string, consider it an MSI installation.
            $appsInstalledWithMSI += $app

            # Logging
            $logInstalledWithMSI = ($($logFilePath + "AppsInstalledWithMSI.txt"))
            $app | Out-File -FilePath $logInstalledWithMSI -Append
        } else {
            # Otherwise, categorize it as an app installed by other means.
            $appsInstalledWithOther += $app

            # Logging
            $logInstalledWithOther = ($($logFilePath + "AppsInstalledWithOther.txt"))
            $app | Out-File -FilePath $logInstalledWithOther -Append
        }
    }

    # Return the results.
    $sortedAppsByMethod = @{
        AppsInstalledWithMSI = $appsInstalledWithMSI
        AppsInstalledWithOther = $appsInstalledWithOther
    }

    return $sortedAppsByMethod
}

# Additional work on logging needed:
function Start_UninstallApps_via_Brute {
    param (
        [array]$appsInstalledWithMSI,
        [array]$appsInstalledWithOther,
        [string]$logFilePath
    )

    # Define common silent uninstall switches for MSI-installed apps and apps installed by other means.
    $msiUninstallSwitches = "/qn /norestart"
    $otherUninstallSwitches = "/S"

    # Initialize arrays to hold successfully uninstalled apps and failed uninstallations.
    $successfullyUninstalled = @()
    $uninstallFailures = @()

    foreach ($app in $appsInstalledWithMSI) {

        # Attempt to uninstall the MSI-installed app with the common switches.
        $uninstallResult = Try {

            $appDisplayName = $app.DisplayName
            Start-Process -FilePath $app.UninstallString -ArgumentList $msiUninstallSwitches -Wait -ErrorAction Stop
            
            # Logging
            $logUninstalledMSIviaBrute = ($($logFilePath + "UninstalledMSIviaBrute.txt"))
            $app | Out-File -FilePath $logUninstalledMSIviaBrute -Append

            $app
        } Catch {
            $uninstallFailures += $app.DisplayName
            $null
        }

        if ($uninstallResult) {
            $successfullyUninstalled += $uninstallResult
            # Log the successful result in a CSV database.
            $resultData = [PSCustomObject]@{
                AppName = $app.DisplayName
                AppVersion = $app.DisplayVersion
                AppPublisher = $app.Publisher
                SwitchesUsed = $msiUninstallSwitches
                UninstallMethod = "MSI"
                Timestamp = (Get-Date)
                Amount = +1 # Fix: Needs to increment
            }

            $resultData | Export-Csv -Path "C:\Temp\Critical\uninstallOptionsDB.csv" -Append -NoTypeInformation
        }
    }

    foreach ($app in $appsInstalledWithOther) {

        # Attempt to uninstall the app installed by other means with the common switches.
        $uninstallResult = Try {

            $appDisplayName = $app.DisplayName
            Start-Process -FilePath $app.UninstallString -ArgumentList $otherUninstallSwitches -Wait -ErrorAction Stop

            # Logging
            $logUninstalledOTHERviaBrute = ($($logFilePath + "UninstalledOTHERviaBrute.txt"))
            $app | Out-File -FilePath $logUninstalledOTHERviaBrute -Append

            $app
        } Catch {
            $uninstallFailures += $app.DisplayName
            $null
        }

        if ($uninstallResult) {
            $successfullyUninstalled += $uninstallResult
            # Log the successful result in a CSV database.
            $resultData = [PSCustomObject]@{
                AppName = $app.DisplayName
                AppVersion = $app.DisplayVersion
                AppPublisher = $app.Publisher
                SwitchesUsed = $otherUninstallSwitches
                UninstallMethod = "Other"
                Timestamp = (Get-Date)
                Amount = +1 # Fix: Needs to increment
            }
            $resultData | Export-Csv -Path "C:\Temp\Critical\uninstallOptionsDB.csv" -Append -NoTypeInformation
        }
    }

    # Return the results.
    $bruteUninstallResults = @{
        SuccessfullyUninstalled = $successfullyUninstalled
        UninstallFailures = $uninstallFailures
    }

    return $bruteUninstallResults
}



# Clear the console screen
Clear-Host

# Execute Main, starting the script
Main
