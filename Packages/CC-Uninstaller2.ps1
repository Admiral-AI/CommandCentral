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

    # Not using this path as this script is targeting system level installations
    # $regPaths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

    $allAppRegKeys = @()
    $garbageAppKeys = @()
    $appsInControlPanel = @()

    try {
        foreach ($regPath in $regPaths) {
            $allAppRegKeys += Get-ChildItem -Path $($regPath)
        }
    } catch {
        Write-Host "Retrieving installed apps failed..."
    }


    if ($null -ne $allAppRegKeys) {
        foreach ($appRegKey in $allAppRegKeys) {
            $appRegKey_Properties = Get-ItemProperty -Path $appRegKey.PSpath
            if (($appRegKey_Properties.SystemComponent -eq 1)) {
                # This if statement removes some of the trash registry keys that are cluttering the data
                $garbageAppKeys += $appRegKey
                Write-Debug "$($appRegKey.Name) is designated as uninstallable."
            } elseif (($appRegKey_Properties.WindowsInstaller -eq 1) -and ($appRegKey_Properties.SystemComponent -ne 1)) {
	    	# This if statement sorts out apps that were installed by MSIs and saves them in a variable
                $appsInControlPanel += $appRegKey
                Write-Debug "$($appRegKey.Name) Meets the first level matching criteria, added to uninstall array"
            } elseif ((($null -ne $appRegKey_Properties.DisplayName) -or ($null -ne $appRegKey_Properties.DisplayName_Localized)) -and ($null -ne $appRegKey_Properties.UninstallString) -and ($appRegKey_Properties.WindowsInstaller -ne 1)) {
                # This if statement sorts out apps that were installed by EXEs and saves them in a variable
		$appsInControlPanel += $appRegKey
                Write-Debug "$($appRegKey.Name) Meets the second level matching criteria, added to uninstall array"
            } else {
                # This statement is a fallback
		$garbageAppKeys += $appRegKey
		Write-Debug "No match found for $($appRegKey.Name)"
            }
        }
    }
    return $appsInControlPanel
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
