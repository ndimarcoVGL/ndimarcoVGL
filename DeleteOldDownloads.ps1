#Get current user's home directory
$userDir = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"

#Get current date
$date = Get-Date

#Get all items in user directory that are older than 30 days
$oldItems = Get-ChildItem -Path $userDir -Recurse | Where-Object {
    $_.LastWriteTime -lt $date.AddDays(-30)
}

#Delete old items
foreach ($item in $oldItems) {
    try {
        Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
        Write-Host "Deleted: $($item.FullName)"
    }
    catch {
        Write-Warning "Failed to delete: $($item.FullName). Error: $($_.Exception.Message)"
    }
}

Write-Host "Cleanup complete. Removed items older than 30 days from $userDir"
