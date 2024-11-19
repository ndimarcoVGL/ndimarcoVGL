#Script name: OldComputerLookup.ps1
#Date: 2/23/2024
#Purpose: Check all PCs and output which haven't been signed into for 30 days
#Author: Nic DiMarco


$inactiveDays = 30
$currentTime = Get-Date
$inactiveComputers = @()

#Get a list of all Active Directory computers with LastLogonTimestamp property
$computers = Get-ADComputer -Filter * -Properties LastLogonTimestamp

foreach ($computer in $computers) {
    #Get the last logon timestamp for the computer
    $lastLogon = $computer.LastLogonTimestamp

    #Check if the LastLogonTimestamp property is not null
    if ($lastLogon) {
        #Convert the LastLogonTimestamp to a DateTime object
        $lastLogonDateTime = [DateTime]::FromFileTime($lastLogon)

        #Calculate the number of days since the last logon
        $daysSinceLastLogon = ($currentTime - $lastLogonDateTime).Days

        if ($daysSinceLastLogon -gt $inactiveDays) {
            $inactiveComputers += [PSCustomObject]@{
                ComputerName = $computer.Name
                LastLogon = $lastLogonDateTime
                DaysSinceLastLogon = $daysSinceLastLogon
            }
        }
    }
}

#Check if there are inactive computers
if ($inactiveComputers.Count -eq 0) {
    Write-Host "No inactive computers found."
} else {
    #Display the list of inactive computers in the shell
    $inactiveComputers | Format-Table -AutoSize

    #Save the results to a CSV file
    $outputPath = "\\10.1.15.21\Root$\IT\Scripts\Script Outputs\OldComputerLookup\OldComputerLookup_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $inactiveComputers | Export-Csv -Path $outputPath -NoTypeInformation -Force
    Write-Host "Results saved to: $outputPath"
}