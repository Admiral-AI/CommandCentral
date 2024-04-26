<#
.DESCRIPTION
    This script uninstalls apps based on approval factors thereby "resetting" machines to a orginal baseline.

.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>

.INPUTS
    <Inputs if any, otherwise state None>

.OUTPUTS
    <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
    Version:        1.0
    Author:         Admiral-AI (https://github.com/Admiral-AI)
    Creation Date:  2023-12-17
    Purpose/Change: App Removal
  
.EXAMPLE
    <Example goes here. Repeat this attribute for more than one example>
#>

<#
param (
    [Parameter(Mandatory=$true)] [hashtable]$CC_MainMenu_Dictionary
)
#>

function Startup_Parameters {
    if ($DebugPreference = "Continue") {
        Clear-Host
    }

    $appsToUninstall = Get_InstalledApps

    return $appsToUninstall
}

function Get_InstalledApps {
    $regPaths = @()
    $regPaths += "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $regPaths += "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

    $allInstalledApps = @()
    $appsToUninstall = @()

    try {
        foreach ($regPath in $regPaths) {
            $allInstalledApps += Get-ChildItem -Path $($regPath)
        }
    } catch {
        Write-Host "Retrieving installed apps failed..."
    }

    if ($null -ne $allInstalledApps) {
        foreach ($installedApp in $allInstalledApps) {
            $installedAppProperties = Get-ItemProperty -Path $installedApp.PSpath
            if (($installedAppProperties.WindowsInstaller -eq 1) -and ($installedAppProperties.SystemComponent -ne 1)) {
                $appsToUninstall += $installedApp
                Write-Debug "$($installedApp.Name) Meets the first level matching criteria, added to uninstall array"
            } elseif ((($null -ne $installedAppProperties.DisplayName) -or ($null -ne $installedAppProperties.DisplayName_Localized)) -and ($null -ne $installedAppProperties.UninstallString) -and ($installedAppProperties.WindowsInstaller -ne 1)) {
                $appsToUninstall += $installedApp
                Write-Debug "$($installedApp.Name) Meets the second level matching criteria, added to uninstall array"
            } else {
                Write-Debug "No match found for $($installedApp.Name)"
            }
        }
    }
    return $appsToUninstall
}

function Approve_InstalledApps {
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

    $appsForBypass = @()
    $appsForUninstall = @()

    foreach ($computerName in $InstalledAppsData.Keys) {

        $registryDataForUninstall = $InstalledAppsData[$computerName]

        foreach ($app in $registryDataForUninstall) {
            $isApproved = $false

            foreach ($preApprovedApp in $PreApprovedAppsList) {
                if ($app.DisplayName -like "$preApprovedApp*") {
                    $appsForBypass += $app
                    $isApproved = $true
                    break
                }
            }

            if (-not $isApproved) {
                $appsForUninstall += $app
            }
        }
    }
}

function Sort_InstalledApps {
    $appToUninstallProperties = @()
    $appsWithQuietUninstallParam = @()

    foreach ($appToUninstall in $appsToUninstall) {
        $appToUninstallProperties += $appToUninstall | Get-ItemProperty
    }

    foreach ($appToUninstallProperty in $appToUninstallProperties) {
        $appsWithQuietUninstallParam += $appToUninstallProperty | where-object { ($appToUninstallProperty).QuietUninstallString -ne $null }
    }
}

Startup_Parameters
