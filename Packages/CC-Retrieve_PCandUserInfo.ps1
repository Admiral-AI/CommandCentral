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
    [Parameter(Mandatory=$false)] [switch] $multiInput,
    [Parameter(Mandatory=$false)] [switch] $inputRetrievalSpecifications,
    [Parameter(Mandatory=$true)] [hashtable] $CC_MainMenu_HashTable
)

function Main {
    # First: Clear the junk off the console
    Clear-Host

    # Clear the Retrieved_Inputs index of the MainMenu hashtable for error-free operation
    $CC_MainMenu_HashTable["Retrieved_Inputs"] = @{}

    # Make sure $multiInput is set to a value (not common) and if not set it manually
    if ($multiInput -ne $false) {
        Write-Debug "The multi input variable was passed into the script with a value of: $($multiInput)"
    } else {
        $multiInput = $false
    
        Write-Debug "The multi input variable was not passed into the script. The value was set to: $($multiInput)"
    }

    # Make sure $inputRetrievalSpecifications is set to a value (not common) and if not set it manually
    if ($inputRetrievalSpecifications -ne $false) {
        Write-Debug "The input specification variable was passed into the script with a value of: $($inputRetrievalSpecifications)"
    } else {
        $inputRetrievalSpecifications = "PC_plus_User"
    
        Write-Debug "The input specification variable was not passed into the script. The value was manually set to: $($inputRetrievalSpecifications)"
    }

    switch ($inputRetrievalSpecifications) {

        "PC_plus_User" {
            $retrievedComputerNames = Get_ComputerNames
            $retrievedUserNames = Get_UserNames
        }

        "User_plus_PC" { 
            $retrievedUserNames = Get_UserNames
            $retrievedComputerNames = Get_ComputerNames
        }

        "User_Only" {
            $retrievedUserNames = Get_UserNames
        }

        "PC_Only" { 
            $retrievedComputerNames = Get_ComputerNames
        }

        Default { 
            Write-Host "Something went wrong during set up, please restart or contact your administrator"
        
            Write-Debug "Check variables, switch statement for `$inputRetrievalSpecifications went into default"
        }
        
    }
    
    $CC_MainMenu_HashTable["Retrieved_Inputs"] = @{
        UserNames = $retrievedUserNames
        ComputerNames = $retrievedComputerNames
    }
}

function Get_UserNames {

    $loopControl_ObtainUserNames = $true
    
    while ($loopControl_ObtainUserNames -eq $true) {
        if ($multiInput -eq $true) {
            # If in 'multi-input' mode, prompt for a file containing a list of computer names
            Write-Host "Enter the path to the file containing user names"
            Write-Host "[e.g., C:\Path\To\ComputerNames.txt] or enter 'q' to exit:"
            $userFileName = Read-Host
            
            if ($userFileName -eq 'q') {
                              
                # Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script (multi-PC) due to user exit ('q' option in Get_RemoteComputerNames)."
                
                # Break out of the script since the user requested to quit                
                exit
            }

            try {
                $UserNames_List = Get-Content $userFileName -ErrorAction Stop
                
                # Turn off loop if file reading is successful
                $loopControl_ObtainUserNames = $false
            } catch {
                Write-Host "Error reading the file. Please make sure the file exists and is accessible or enter 'quit' to exit."
            }

        } else {
            # If not in 'domainadmin' mode, prompt for a single computer name
            $input_UserName = Read-Host "Enter the user name (or type 'q' to exit)"
            
            if ($input_UserName -eq 'q') {
                
                # Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script due to user exit ('q' option in Get_RemoteComputerNames)."
                
                # Break out of the script since the user requested to quit
                exit
            }
            $UserNames_List = @($input_UserName)
             

            # Turn off loop since a single computer name is obtained
            $loopControl_ObtainUserNames = $false
        }
    }
    return $UserNames_List

    
}

function Get_ComputerNames {

    $loopControl_ObtainPCNames = $true
    
    while ($loopControl_ObtainPCNames -eq $true) {
        if ($multiInput -eq $true) {
            # If in 'multi-input' mode, prompt for a file containing a list of computer names
            Write-Host "Enter the path to the file containing computer names"
            Write-Host "[e.g., C:\Path\To\ComputerNames.txt] or enter 'q' to exit:"
            $pcFileName = Read-Host
            
            if ($pcFileName -eq 'q') {
                              
                # Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script (multi-PC) due to user exit ('q' option in Get_RemoteComputerNames)."
                
                # Break out of the script since the user requested to quit                
                exit
            }

            try {
                $ComputerNames_List = Get-Content $pcFileName -ErrorAction Stop
                
                # Turn off loop if file reading is successful
                $loopControl_ObtainPCNames = $false
            } catch {
                Write-Host "Error reading the file. Please make sure the file exists and is accessible or enter 'quit' to exit."
            }

        } else {
            # If not in 'domainadmin' mode, prompt for a single computer name
            $input_ComputerName = Read-Host "Enter the computer name (or type 'q' to exit)"
            
            if ($input_ComputerName -eq 'q') {
                
                # Writing back to transcript for ease of troubleshooting
                Write-Information "Exiting the script due to user exit ('q' option in Get_RemoteComputerNames)."
                
                # Break out of the script since the user requested to quit
                exit
            }
            $ComputerNames_List = @($input_ComputerName)
             

            # Turn off loop since a single computer name is obtained
            $loopControl_ObtainPCNames = $false
        }
    }
    return $ComputerNames_List
}

Main

return $CC_MainMenu_HashTable
