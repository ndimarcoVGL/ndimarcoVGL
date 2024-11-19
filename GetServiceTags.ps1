# Get Dell service tag (serial number)
$serviceTag = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber

# Get PC name
$pcName = $env:COMPUTERNAME

# Get last logged on user
$lastUser = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName

# Create a hashtable to store the collected information
$info = @{
    "ServiceTag" = $serviceTag
    "PCName" = $pcName
    "LastLoggedOnUser" = $lastUser
}

# Convert hashtable to JSON format
$jsonInfo = $info | ConvertTo-Json

# Set the path where the text file will be saved
$filePath = "\\10.1.15.21\Root$\IT\Scripts\Script outputs\servicetags\$PCName.txt"

# Check if the file already exists
if (-not (Test-Path -Path $filePath)) {
    # Write JSON data to the text file
    $jsonInfo | Out-File -FilePath $filePath -Force
    Write-Host "Computer information saved to $filePath"
} else {
    
}
