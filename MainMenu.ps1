# Function to format and display text with a specified line length
function Format-Text {
    param (
        [string]$Text,
        [int]$LineLength
    )

    $textLines = $Text -split "`r`n" | Where-Object { $_ -ne '' }

    $textLines | ForEach-Object {
        $formattedLine = $_ -replace " ", "`xA"  # Replace spaces with a non-breaking space
        $formattedLine = $formattedLine -replace "`xA", " "  # Restore the spaces
        $formattedLine = $formattedLine -replace "`xA", "`xB`xA"  # Replace with a space character
        $formattedLine = $formattedLine -replace "`xB", " "  # Restore spaces after reformatting
        $formattedLine = $formattedLine -replace "`xA", " "  # Restore spaces after reformatting
        Write-Host $formattedLine
    }
}

# Start preliminary checks
function Main {

    Write-Host "Checking for updates and powershell packages..."

    # ASCII logo display with a maximum line length of 80 characters
    $logo = Get-Content -Path "C:\Temp\logo.txt" -Raw
    #Format-Text -Text $logo -LineLength 120

    # Preliminary checks go here

    # Start the menu loop
    do {
        Show-Menu -logo $logo
    } while ($true)

}

# Function to display the menu
function Show-Menu {
    param(
    [array]$logo
    )

    Format-Text -Text $logo -LineLength 120
    Write-Host "My PowerShell Launch Pad" -ForegroundColor Yellow
    Write-Host "1. Option 1"
    Write-Host "2. Option 2"
    Write-Host "3. Option 3"
    Write-Host "4. Exit"
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        1 { 
            $fileName = Read-Host "Enter a filename for Option 1 (if needed)"
            Run-Script1 -FileName $fileName
        }
        2 { Run-Script2 }
        3 { Run-Script3 }
        4 { exit }
        default { Write-Host "Invalid option. Please try again." }
    }
}

# Define your functions for each script
function Run-Script1 {
    param (
        [string]$FileName
    )
    # Your script 1 code here, using $FileName if needed
}

function Run-Script2 {
    # Your script 2 code here
}

function Run-Script3 {
    # Your script 3 code here
}

# Clear screen and run Main
clear-Host
Main