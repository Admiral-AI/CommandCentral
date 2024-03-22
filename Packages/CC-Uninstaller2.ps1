Clear-Host

$regPaths = @()
$regPaths += "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$regPaths += "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

$allInstalledApps = @()
$appsToUninstall = @()

foreach ($regPath in $regPaths) {
    $allInstalledApps += Get-ChildItem -Path $($regPath)
}

foreach ($installedApp in $allInstalledApps) {
    $installedAppProperties = Get-ItemProperty -Path $installedApp.PSpath
    if (($installedAppProperties.WindowsInstaller -eq 1) -and ($installedAppProperties.SystemComponent -ne 1)) {
        $appsToUninstall += $installedApp
        Write-Host "$($installedApp.Name) Meets the first level matching criteria, added to uninstall array"
    } elseif (($installedAppProperties.UninstallString -ne $null) -and ($installedAppProperties.WindowsInstaller -ne 1) -and ($installedAppProperties.DisplayName -ne $null)) {
        $appsToUninstall += $installedApp
        Write-Host "$($installedApp.Name) Meets the second level matching criteria, added to uninstall array"
    } else {
        Write-Host "No match found for $($installedApp.Name)"
    }
}
