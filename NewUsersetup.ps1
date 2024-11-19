#Script name: NewUsersetup.ps1
#created: 6/1/2023
#Author: Nic DiMarco
#Purpose: Streamline the user creation process

Import-Module Microsoft365DSC

#Prompt for required information
$firstName = Read-Host "Enter first name: "
$lastName = Read-Host "Enter last name: "
$originalUsername = ($firstName.Substring(0,1) + $lastName).ToLower() #Sets the username to (firstinitial)lastname: ex. ndimarco
$username = $originalUsername
$defaultPassword = ConvertTo-SecureString "VGLt3mp!" -AsPlainText -Force #Sets default account password as VGLt3mp!

#Connect to the domain controller
$domainController = "10.1.15.21"
Import-Module ActiveDirectory

#Prompt to enter department
$departmentChoice = Read-Host "Enter your department choice `n1. Accounting `n2. Engineering `n3. HR `n4. GM `n5. IT `n6. Purchasing `n7. Sales `n8. Shop `n9. Production `nChoice"
$department = ""

#Use switch case to set the department and OU based on input
switch ($departmentChoice) {
    "1" { $department = "Accounting"; $ouPath = "OU=Accounting,OU=Administration,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "2" { $department = "Engineering"; $ouPath = "OU=Engineering,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "3" { $department = "HR"; $ouPath = "OU=HR,OU=Administration,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "4" { $department = "GM"; $ouPath = "OU=GM,OU=Administration,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "5" { $department = "IT"; $ouPath = "OU=IT,OU=Administration,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "6" { $department = "Purchasing"; $ouPath = "OU=Purchasing,OU=Administration,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "7" { 
        $salesChoice = Read-Host "Is it Inside Sales or Outside Sales? (1. Inside Sales, 2. Outside Sales)"
        switch ($salesChoice) {
            "1" { $department = "Inside Sales"; $ouPath = "OU=Inside Sales,OU=Sales,OU=Standard Users,DC=GreatLakes,DC=cives" }
            "2" { $department = "Outside Sales"; $ouPath = "OU=Outside Sales,OU=Sales,OU=Standard Users,DC=GreatLakes,DC=cives" }
            default {
                Write-Host "Invalid sales choice entered."
                Exit
            }
        }
    }
    "8" { $department = "Shop"; $ouPath = "OU=Shop,OU=Standard Users,DC=GreatLakes,DC=cives" }
    "9" { $department = "Production"; $ouPath = "OU=Production,OU=Standard Users,DC=GreatLakes,DC=cives" }
    default {
        Write-Host "Invalid department choice entered."
        Exit
    }
}

#Check if the username already exists
$existingUser = Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue

#Generate a new username if it already exists
if($existingUser){
    $username = ($firstName.Substring(0,2) + $lastName).ToLower() #If the username (firstinitial)lastname already exists, sets the username to (firstinitalsecondinital)lastname ex. ndimarco becomes nidimarco
}

#Prompt for VPN access
$vpnAccess = Read-Host "Does the User need VPN Access? (Yes/No):" #If yes, runs below
$vpnAccess.ToLower()
if ($vpnAccess -eq "yes" -or $vpnAccess -eq "y"){
    $description = "VPN"
    $groupToAdd = "VPN_Access" #Define the security group to add the user to if they need VPN access
}else{ #If no
    $description = $null
    $groupToAdd = $null
}

#Prompt for job title
$jobTitle = Read-Host "Enter the job title:"

#Create a new user
$newUserParams = @{
    GivenName = $firstName
    Surname = $lastName
    SamAccountName = $username
    UserPrincipalName = "$username@vikingcives.com"
    Name = "$firstName $lastName"
    DisplayName = "$firstName $lastName"
    Title = $jobTitle
    Department = "$department"
    Company = "Viking-Cives Great Lakes"
    AccountPassword = $defaultPassword
    PasswordNeverExpires = $false
    Enabled = $true
    Path = $ouPath
    Description = "$description"
    Office = "VGL"
    Street = "1405 Shiga Dr"
    City = "Battle Creek"
    State = "MI"
    PostalCode = "49037"
    EmailAddress = "$username@vikingcives.com"
}

#Create the new user with the declared parameters 
$newUser = New-ADUser @newUserParams -PassThru

# Output the OU the user is added to
$selectedOU = $ouPath -replace '^OU=(.+?),OU=.+$','$1'
Write-Host "User $username created successfully and added to the '$selectedOU' OU."

#Add the user to the VPN Access security group
if($groupToAdd){
    Add-ADGroupMember -Identity $groupToAdd -Members $newUser
}

#Add to Department security group
Add-ADGroupMember -Identity $department -Members $username

#Prompt for TeamViewer Installer Secure GPO
$teamViewerGPO = Read-Host "Does the user need to be added to the TeamViewer Secure Group? (Yes/No):"
$teamViewerGPO.ToLower()
if($teamViewerGPO -eq "yes" -or $teamViewerGPO -eq "y"){
    $teamViewerGPOName = "TeamViewer Installer Secure"

    #Add the user to the TeamViewer Installer Secure GPO
    try{
        $GPO = Get-GPO -Name $teamViewerGPOName -Domain "GreatLakes.Cives"
        #$userSID = (Get-ADUser -Identity $newUser.SamAccountName).SID.Value
        $GPO | Set-GPPermissions -PermissionLevel GpoApply -TargetType User -TargetName $username
        Write-Host "User added to the TeamViewer Secure GPO successfully"
    }catch{
        Write-Host "Failed to add user to the TeamViewer Installer Secure GPO"
    }
}else{
    $teamViewerGPOName = $null
}

#Force password change at first log
#After creating the user and creating the department folder
#Check if the department is Engineering
if ($department -eq "Engineering") {
    $departmentFolderPath = "\\10.1.15.21\Root$\Engineering\Employees"
} else {
    $departmentFolderPath = "\\10.1.15.21\Root$\$department"
}

# Check if the department folder already exists
if (!(Test-Path $departmentFolderPath)) {
    # Create the department folder if it doesn't exist
    New-Item -Path $departmentFolderPath -ItemType Directory -ErrorAction SilentlyContinue
}

# Create the user's folder
$userFolderPath = Join-Path -Path $departmentFolderPath -ChildPath $username
if (!(Test-Path $userFolderPath)) {
    # Create the user folder if it doesn't exist
    New-Item -Path $userFolderPath -ItemType Directory -ErrorAction SilentlyContinue
}

# Create Private and Scans folders under the user folder
$privateFolderPath = Join-Path -Path $userFolderPath -ChildPath "Private"
if (!(Test-Path $privateFolderPath)) {
    # Create the Private folder if it doesn't exist
    New-Item -Path $privateFolderPath -ItemType Directory -ErrorAction SilentlyContinue
}

$scansFolderPath = Join-Path -Path $userFolderPath -ChildPath "Scans"
if (!(Test-Path $scansFolderPath)) {
    # Create the Scans folder if it doesn't exist
    New-Item -Path $scansFolderPath -ItemType Directory -ErrorAction SilentlyContinue
}

Write-Host "Private and Scans folders created under user $username folder."
