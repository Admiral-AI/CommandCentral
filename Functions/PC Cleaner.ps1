# Define input variables
param (
    [Parameter(Mandatory=$true)] [hashtable] $CC_MainMenu_HashTable
)

function Main {
    # First: Clear the junk off the console
    Clear-Host

    # Build a path to the packages directory using the datat stored in CC_MainMenu_HashTable
    $packageLocal = $CC_MainMenu_HashTable.SettingsJSON.Application_Settings.Packages_Path
    $commandCentralLocal = $CC_MainMenu_HashTable.CCScriptRoot
    $packageLocal = Join-Path $commandCentralLocal $packageLocal

    # Build amd call the CC-Retrieve_PCandUserInfo script from the Packages directory
    $CC_Retrieve_PCandUserInfoLocal = "CC-Retrieve_PCandUserInfo.ps1"
    $CC_Retrieve_PCandUserInfoLocal = Join-Path $packageLocal $CC_Retrieve_PCandUserInfoLocal
    
    # use "-multiInput $true" as a parameter if you want to specify multiple PCs via a file
    Write-Host "Please provide a PC list (.txt) to clean"
    $userInput_ListofPCs = . $CC_Retrieve_PCandUserInfoLocal -multiInput $true

    # Build amd call the CC-AppUnintallerviaControlPanel script from the Packages directory
    $CC_AppUnintallerviaControlPanelLocal = "CC-AppUnintallerviaControlPanel.ps1"
    $CC_AppUnintallerviaControlPanelLocal = Join-Path $packageLocal $CC_AppUnintallerviaControlPanelLocal

    # Find and set admin credential location
    $credList = ($CC_MainMenu_HashTable.UserCreds_HashTable).GetEnumerator() #| Where-Object { $_ -like "*_sprt" }
    foreach ($cred in $credList) {
        if ($cred.Name | Where-Object { $_ -like "*_sprt" }) {
            $sprtCred = $cred.Name
        }
    }

    Write-Host ""

    if ($PSVersionTable.PSVersion.Major -ge 6) {

        Write-Host "Your powershell version (major) is 6 or above, seqeuntial processing capabilities are enabled for this script."

        Write-Host "Press any key to acknowledge and continue:" -NoNewline
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

        $userInput_ListofPCs | Foreach-Object -ThrottleLimit 100000 -Parallel {
            # Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname

            $CC_AppUnintallerviaControlPanelLocal = $Using:CC_AppUnintallerviaControlPanelLocal
            $CC_MainMenu_HashTable = $Using:CC_MainMenu_HashTable
            $sprtCred = $Using:sprtCred

            $scriptBlock = {
                . $args[0] -CC_MainMenu_HashTable $args[1] -inputPC $args[2]
            }

            # Notify and reboot the PCs; Wait and reconnect
            try { 
                Restart-Computer $_ -Credential $CC_MainMenu_HashTable.UserCreds_HashTable.$($sprtCred) -Force -Wait -Timeout 3 -ErrorAction Stop
                $rebootConfirmed = $true
            } catch { 
                Write-Host "Reboot failed to complete within 15 minutes, please check on the PC and rerun the script"
                $rebootConfirmed = $false
            }
            
            if ($rebootConfirmed -eq $true) {
                # Notify and start the uninstall job
                Write-Host "Starting uninstaller for $($_)"
                Start-Job -ScriptBlock $scriptBlock -ArgumentList $CC_AppUnintallerviaControlPanelLocal, $CC_MainMenu_HashTable, $_ | Receive-Job -Wait -AutoRemoveJob
            }

        }

        Write-Host "Press any key to acknowledge and continue:" -NoNewline
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

    } elseif ($PSVersionTable.PSVersion.Major -le 5) {
        Write-Host "Your powershell version (major) is not above 5, seqeuntial processing capabilities are disabled for this script. Please update your powershell version to unlock."
        Write-Host "Press any key to acknowledge and continue:" -NoNewline
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
}

Main
