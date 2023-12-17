<#
script description
#>

#variables for script

#user runnig the script
$sprtUser = $env:USERPROFILE

#list of 'user' profiles to keep on pc
$defaultProfiles = @(
    $sprtUser,
    'C:\Users\defaultuser0'
    'C:\Users\lansweep-pc',
    'C:\Users\pdqdeploy',
    'C:\Windows\ServiceProfiles\NetworkService',
    'C:\Windows\ServiceProfiles\LocalService',
    'C:\Windows\system32\config\systemprofile'
)

#start logging
Start-Transcript -Append -path "C:\Temp\PCResetlog.txt"
write-host "`n`n`n`n`n`n`n`n`n`n"

#get sprt credentials
$creds = Get-Credential -Message "Enter your SPRT account credentials" -UserName $env:USERNAME"_sprt"
Try{Unlock-ADAccount -Credential $creds -Identity $env:USERNAME}
Catch [Microsoft.ActiveDirectory.Management.ADException]{""}
Catch [System.Security.Authentication.AuthenticationException] {Write-Host -ForegroundColor Red "The credentials entered are invalid. Please try again.";exit}
Catch [System.Management.Automation.RemoteException] {Write-Host -ForegroundColor Red "The credentials entered are invalid. Please try again.";exit}

#flush dns
Try{Clear-DnsClientCache}
Catch{"Error flushing DNS. Continuing..."}

#get pc to run script on
$PC = Read-host "What is the user's computer number?"
Write-Host pc to be reset: $PC

#restarts pc and waits for it to come back online
get-date | write-host
try{ Restart-Computer -ComputerName $PC -Wait -Timeout 600 }
catch{"stuff didn't happen"}
get-date | write-host

# get a list of profiles from pc
$allProfiles = Get-CimInstance -Class Win32_UserProfile -ComputerName $PC
Write-Host '
--------------------------------------------------------------------------------------------------------------------------

list of user profiles on $PC
'
$allProfiles.localpath | Write-Host

#compare to defaults list including user sprt (will clean this up just for testing)
$delprofiles = $allProfiles | Where-Object { $_.localpath -notin $defaultProfiles}
Write-Host '
--------------------------------------------------------------------------------------------------------------------------

list of user profiles to be deleted on $PC
'
$delProfiles.localpath | Write-Host

#delete profiles
$delProfiles | Remove-CimInstance -verbose

#stop logging
Stop-Transcript