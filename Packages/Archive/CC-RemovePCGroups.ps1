Clear-Host

# Specify the computer name and approved groups
$computerName = "wintest-2"
$approvedGroups = @("ApprovedGroup1", "ApprovedGroup2")

# Get the computer object from Active Directory
$computer = Get-ADComputer -Identity $computerName -Properties MemberOf

# Get the current group memberships of the computer object
$currentGroups = $computer.MemberOf | Get-ADGroup

Write-Host $currentGroups

# Determine groups to remove
$groupsToRemove = $currentGroups | Where-Object { $_.Name -notin $approvedGroups }

# Remove the unwanted groups
foreach ($group in $groupsToRemove) {
    Write-Host "Removing group: $($group.Name)"
    Remove-ADGroupMember -Identity $group -Members $computer -Confirm:$false
}

Write-Host "Script execution completed."
