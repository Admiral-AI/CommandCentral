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

    Write-Host ""

    if ($PSVersionTable.PSVersion.Major -ge 6) {

        Write-Host "Your powershell version (major) is 6 or above, seqeuntial processing capabilities are enabled for this script."

        Write-Host "Press any key to acknowledge and continue:" -NoNewline
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

        $userInput_ListofPCs | Foreach-Object -ThrottleLimit 5 -Parallel {
            #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname
            $CC_AppUnintallerviaControlPanelLocal = $Using:CC_AppUnintallerviaControlPanelLocal
            $CC_MainMenu_HashTable = $Using:CC_MainMenu_HashTable

            function Invoke_UninstallviaControlPanelScript {
                . $CC_AppUnintallerviaControlPanelLocal -CC_MainMenu_HashTable $CC_MainMenu_HashTable -inputPC $_
            }

            # Start-Job -ScriptBlock ${Function:Invoke_UninstallviaControlPanelScript} | Receive-Job -Wait -AutoRemoveJob

            Write-Host "The path is: $CC_AppUnintallerviaControlPanelLocal"
            Write-Host "The hashtable is:"
            $CC_MainMenu_HashTable.UserCreds_HashTable
            Write-Host "The current PC is: $_"
        }

        Write-Host "Press any key to acknowledge and continue:" -NoNewline
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

        <#
            $userInput_ListofPCs | ForEach-Object -ThrottleLimit 2 -Parallel  {
                . $Using:CC_AppUnintallerviaControlPanelLocal -$CC_MainMenu_HashTable $Using:CC_MainMenu_HashTable -inputPC $_
            }

            # Call the path for each PC provided (extremely dangerous if misused, use -multiInput parameter above to control this)
            foreach ($inputPC in $userInput_ListofPCs) {
                Start-Process powershell.exe -ArgumentList "-File `"$($CC_AppUnintallerviaControlPanelLocal)`"  -CC_MainMenu_HashTable $($CC_MainMenu_HashTable) -inputPC $($inputPC)"
                # -CC_MainMenu_HashTable `"$($CC_MainMenu_HashTable)`" -inputPC `"$($inputPC)`"
            }
        #>
    } elseif ($PSVersionTable.PSVersion.Major -le 5) {
        Write-Host "Your powershell version (major) is not above 5, seqeuntial processing capabilities are disabled for this script. Please update your powershell version to unlock."
        Write-Host "Press any key to acknowledge and continue:" -NoNewline
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
}

Main
