#Script name: OldUserLookup.ps1
#Created: 05/31/2023
#Author: Nic DiMarco
#Purpose: Searches Active Directory for inactive user accounts and displays the results in the CLI

#Set this variable to find users that have not logged onto the domain for this number of days
#Setting this variable to 0 will find ALL users in Active Directory
$age = "90"

#Generates a date for the last logon based on today's date minus the number of days selected
$agelimit = (Get-Date).AddDays(-$age)

#Creates a directory searcher object to begin searching for users in AD
$userslookup = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
$userslookup.Filter = "(&(objectClass=user)(objectCategory=person))"

$inactiveUsers = @()

#For each user found:
$userslookup.FindAll().GetEnumerator() | ForEach-Object {
    #Convert the username to a string
    $name = [string]$_.Properties.name

    #Convert the ticker-style date gathered by the directory searcher for last logon into a more readable date
    $lastlogondate = [string]$_.Properties.lastlogontimestamp
    $realtime = [DateTime]::FromFileTime($lastlogondate)

    #If the last logon date is older than the age in days defined by $age:
    if ($agelimit -gt $realtime) {
        #Add the user's information to the list of inactive users
        $inactiveUsers += [PSCustomObject]@{
            UserName = $name
            LastLogon = $realtime
        }
    }
}

#Check if there are inactive users
if ($inactiveUsers.Count -eq 0) {
    Write-Host "No inactive users found."
} else {
    #Display the list of inactive users in the shell
    $inactiveUsers | Format-Table -AutoSize

    #Save the results to a CSV file
    $outputPath = "\\10.1.15.21\Root$\IT\Scripts\Script Outputs\InactiveUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $inactiveUsers | Export-Csv -Path $outputPath -NoTypeInformation -Force
    Write-Host "Results saved to: $outputPath"
}

