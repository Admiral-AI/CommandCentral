<#
.DESCRIPTION
  Provides a way to get user or pc (single or multi) information to support my other scripts

.NOTES
  Version:        1.0
  Author:         Admiral-AI
  Portfolio:      https://github.com/Admiral-AI
  Creation Date:  April 10, 2024
#>

# Input parameters for script
param (
    [Parameter(Mandatory=$false)] [bool] $multiInput
)

function Main {

    # Make sure $multiInput is set to a value (not common) and if not set it manually
    if ($multiInput -ne $false) {
        Write-Debug "The multi input variable was passed into the script with a value of: $($multiInput)"
    } else {
        $multiInput = $false
    
        Write-Debug "The multi input variable was not passed into the script. The value was set to: $($multiInput)"
    }

    $userInput_List = Get_UserInput

    return $userInput_List
}

function Get_UserInput {

    $loopControl_ObtainUserInput = $true
    
    while ($loopControl_ObtainUserInput -eq $true) {
        if ($multiInput -eq $true) {

            # If in 'multi-input' mode, prompt for a file containing a list of computer names
            $userFileName = Read-Host -Prompt "-->"
            
            if ($userFileName -eq 'q') {
                              
                # Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script (multi-PC) due to user exit ('q' option in Get_RemoteComputerNames)."
                
                # Break out of the script since the user requested to quit                
                exit
            }

            try {
                $userInput_List = Get-Content $userFileName -ErrorAction Continue
                if ($userInput_List -ne "") {
                    # Turn off loop if file reading is successful
                    $loopControl_ObtainUserInput = $false
                }
            } catch {
                Write-Host "Error reading the file. Please make sure the file exists and is accessible or enter 'quit' to exit."
            }

        } else {
            # If not in 'multi-input' mode, prompt for a single computer name
            $user_Input = Read-Host -Prompt "-->"
            
            if ($user_Input -eq 'q') {
                
                # Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script due to user exit ('q' option in Get_RemoteComputerNames)."
                
                # Break out of the script since the user requested to quit
                exit
            } elseif ($user_Input -ne "") {
                # Turn off loop since a single computer name is obtained
                $loopControl_ObtainUserInput = $false
            }
            $userInput_List = @($user_Input)
        }
    }
    return $userInput_List
}

$userInput_List = Main

return $userInput_List
