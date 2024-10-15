$SourceFolder = "./test"

# Create FileSystemWatcher object and configure properties
$Watcher = New-Object IO.FileSystemWatcher $SourceFolder -Property @{ 
  IncludeSubdirectories = $true
  NotifyFilter          = [IO.NotifyFilters]'FileName, LastWrite, DirectoryName'
}

# Enable event raising
$Watcher.EnableRaisingEvents = $true

# Event handling for file system changes
$action = {
  $changeType = $EventArgs.ChangeType
  $fullPath = $EventArgs.FullPath

  Write-Host "Change detected: $changeType at $fullPath"
}

# Register events for creation, change, deletion, and renaming
Register-ObjectEvent -InputObject $Watcher -EventName Created -Action $action
Register-ObjectEvent -InputObject $Watcher -EventName Changed -Action $action
Register-ObjectEvent -InputObject $Watcher -EventName Deleted -Action $action
Register-ObjectEvent -InputObject $Watcher -EventName Renamed -Action $action

# Keep the script running
while ($true) {
  Start-Sleep -Seconds 1
}
