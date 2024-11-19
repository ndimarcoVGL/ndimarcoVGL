#Name of Script: SoftwareInstalls.ps1
#Created: 6/6/2023
#Author: Nic DiMarco
#Purpose: Auto-install common software used by all employees,(Spiceworks Collection Agent, Google Chrome, Adobe reader)

#set time zone to EST
Set-TimeZone -id "Eastern Standard Time"

#Check if there is anything being installed
$installingPrograms = Get-WmiObject -Class Win32_Process | Where-Object { $_.Name -eq "msiexec.exe" }

if ($installingPrograms){
    Write-Host "Program installation in progress. Waiting for installations to complete before continuing"
    do {
        Start-Sleep -Seconds 5
        $installingPrograms = Get-WmiObject -Class Win32_Process | Where-Object { $_.Name -eq "msiexec.exe" }
    } until (-not $installingPrograms)
    Write-Host "Program installations completed. Proceeding..."
}
else {
    Write-Host "No program installations detected. Proceeding..."
}

#Check if Chocolatey is installed (and install it if it isn't)
if (!(Test-Path "C:\ProgramData\chocolatey\choco.exe")){
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

#Check if PC name matches the pattern VGL-***-ST
$pcName = $env:COMPUTERNAME
$pattern = "VGL-\d{3}-ST"

#If the PC is a shop tablet, install Barcode Font 128
if($pcName -match $pattern){
    Write-Host "This PC is a shop tablet"
    #Define the source directory of the Barcode Font 128
    $fontDirectory = "\\10.1.15.21\d`$\Root\IT\Software\Barcode\LibreBarcode128-Regular.ttf"

    #Check if the font file exists
    if (Test-Path $fontDirectory){
    #Install the Barcode font 128
    Write-Host "Installing Barcode Font 128..."
    $fontDestination = "C:\Windows\Fonts\LibreBarcode128-Regular.ttf"
    Copy-Item -Path $fontDirectory -Destination $fontDestination -Force
    
    #Refresh the font cache
    Write-Host "Refreshing font cache..."
    $shell = New-Object -ComObject Shell.Application
    $fontFolder = $shell.Namespace(0x14)
    $fontItem = $fontFolder.ParseName("LibreBarcode128-Regular.ttf")
    $fontItem.InvokeVerb("Install")

    Write-Host "Barcode Font 128 Installed Successfully."
    }else{
        Write-Host "Error: The Barcode Font File was not found in the specified location"
    }else{
    Write-Host "This PC is not a shop tablet, skipping Barcode Font 128 installation"
    }
}
#Check if Adobe Reader is installed
$adobeInstalled = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Adobe Reader%'" | Measure-Object | Select-Object -ExpandProperty Count

#Install Adobe Reader if it is not installed
if ($adobeInstalled -eq 0){
    choco install adobereader --ignore-checksums -y
}else{
    Write-Host "Adobe Reader is already installed."
}

#Check if Google Chrome is installed
$chromeInstalled = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Google Chrome%'" | Measure-Object | Select-Object -ExpandProperty Count

#Install Google Chrome if it is not installed
if($chromeInstalled -eq 0){
    choco install googlechrome --ignore-checksums -y
}else{
    Write-Host "Google Chrome is already installed."
}

msiexec.exe /i "\\10.1.15.21\D$\Root\IT\Software\Spiceworks\SpiceworksSilentInstall.msi" SPICEWORKS_AUTH_KEY="iCJImm8nvHtJ8JGI2eIu"

#Check if Vonage is installed
$vonageInstalled = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Vonage%'" | Measure-Object | Select-Object -ExpandProperty Count

#Install Vonage app if it is not installed
if($vonageInstalled -eq 0){
    #Define the source Path of the Vonage app msi
    $vonageInstaller = & '\\10.1.15.21\d$\Root\IT\Software\Vonage\Vonage+Business+2.11.0.msi'
    msiexec.exe /i $vonageInstaller
}else{
    Write-host "Vonage app is already installed"
}

#Install Premium Microsoft 365 apps
$ms365Installed = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Microsoft Office%'" | Measure-Object | Select-Object -ExpandProperty Count

#Install Premium Microsoft 365 apps if they are not installed
if ($ms365Installed -eq 0){
    Write-Host "Installing 365 Apps..."
    choco install office365business --ignore-checksums -y
}

#Uninstall bloatware
Get-AppxPackage Microsoft.XboxGameOverlay -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxSpeechToTextOverlay -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.ZuneVideo -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.ZuneMusic -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.YourPhone -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.PowerAutomateDesktop -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.BingWeather -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.MicrosoftStickyNotes -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.BingNews -AllUsers | Remove-AppxPackage



#Check if computer name includes "LT" and install OpenVPN client if it does
if ($computerName -like "*LT*") {
    $openvpnInstallerPath = "\\10.1.15.21\d$\Root\IT\Software\pfSense\OpenVPN Client\openvpn-VGL-pfSense-UDP4-1194-install-2.5.2-I601-amd64.exe"
    Start-Process -FilePath $openvpnInstallerPath -Wait
    Write-Host "OpenVPN client installed."
}