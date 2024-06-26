# Define input variables
param (
    [Parameter(Mandatory=$false)] [hashtable] $CC_MainMenu_HashTable,
    [Parameter(Mandatory=$false)] [bool] $CC_Automation
)

function Main {
    Clear-Host

    Show-StoreMenu
}

function Show-StoreMenu {
    while ($storeMenuLoop = $true) {
        Write-Output @"
    .------..------..------..------..------..------..------..------.
    |P.--. ||A.--. ||S.--. ||S.--. ||W.--. ||O.--. ||R.--. ||D.--. |
    | :/\: || (\/) || :/\: || :/\: || :/\: || :/\: || :(): || :/\: |
    | (__) || :\/: || :\/: || :\/: || :\/: || :\/: || ()() || (__) |
    | '--'P|| '--'A|| '--'S|| '--'S|| '--'W|| '--'O|| '--'R|| '--'D|
    '------''------''------''------''------''------''------''------'
    .------..------..------..------..------..------..------..------.
    |S.--. ||T.--. ||O.--. ||R.--. ||E.--. ||*.--. ||*.--. ||*.--. |
    | :/\: || :/\: || :/\: || :(): || (\/) || :<>: || :<>: || :<>: |
    | :\/: || (__) || :\/: || ()() || :\/: || :<>: || :<>: || :<>: |
    | '--'S|| '--'T|| '--'O|| '--'R|| '--'E|| '--'*|| '--'*|| '--'*|
    '------''------''------''------''------''------''------''------'
"@
        Write-Output ""
        Write-Output "Please choose an option:"
        Write-Output "1) Add New Store"
        Write-Output "2) Remove Store"
        Write-Output "3) Search in Store"
        Write-Output "4) Verify Credentials"
        Write-Output "5) Import Store Data"
        Write-Output "Q) Quit"
        Write-Output ""
        $storeMenuChoice = Read-Host "-->"

        switch ($storeMenuChoice) {
            1 {
                Write-Output "1 was selected"
            }
            2 {
                Write-Output "2 was selected"
            }
            3 {
                Write-Output "3 was selected"
            }
            4 {
                Write-Output "4 was selected"
            }
            5 {
                Write-Output "5 was selected"
            }
            q {
                Write-Output "Quit was selected"
                Start-Sleep 3
                Exit
            }
            Default {
                Write-Output "The input was not valid"
            }
        }
        Start-Sleep 3
    }
}

Main