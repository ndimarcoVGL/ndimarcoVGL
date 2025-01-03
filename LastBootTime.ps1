# Get PC name
$pcName = $env:COMPUTERNAME

# Get last boot time
$lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

# Set path for Excel file
$excelPath = "\\10.1.15.21\root$\it\scripts\script outputs\PCBootTimes.xlsx"

# Load Excel COM object
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    
    # Open existing file or create new one if it doesn't exist
    if (Test-Path $excelPath) {
        $workbook = $excel.Workbooks.Open($excelPath)
        $worksheet = $workbook.Sheets(1)
    } else {
        $workbook = $excel.Workbooks.Add()
        $worksheet = $workbook.Sheets(1)
        # Add headers if new file
        $worksheet.Cells(1,1) = "Computer Name"
        $worksheet.Cells(1,2) = "Last Boot Time"
    }

    # Find if PC already exists in list
    $lastRow = $worksheet.UsedRange.Rows.Count
    $pcFound = $false
    
    for ($i = 2; $i -le $lastRow; $i++) {
        if ($worksheet.Cells($i,1).Text -eq $pcName) {
            # Update existing record
            $worksheet.Cells($i,2) = $lastBoot
            $pcFound = $true
            break
        }
    }

    # Add new record if PC not found
    if (-not $pcFound) {
        $newRow = $lastRow + 1
        $worksheet.Cells($newRow,1) = $pcName
        $worksheet.Cells($newRow,2) = $lastBoot
    }

    # Save and close
    $workbook.SaveAs($excelPath)
    $workbook.Close()
    $excel.Quit()
} catch {
    Write-Warning "Error occurred: $($_.Exception.Message)"
} finally {
    # Clean up COM objects
    if ($worksheet) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null }
    if ($workbook) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null }
    if ($excel) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
