# Define input variables
param (
    [Parameter(Mandatory=$true)] [hashtable] $CC_MainMenu_HashTable,
    [Parameter(Mandatory=$true)] [string] $inputPC
)

function Main {
    # First: Clear the junk off the console
    # Clear-Host

    # Debug
    Write-Output "The following was received:"
    Write-Output ""
    Write-Output "CC Main Menu Hashtable:"
    $CC_MainMenu_HashTable
    Write-Output ""
    Write-Output "PC Name:"
    $inputPC
    Write-Output ""
    # End Debug
}

Main
