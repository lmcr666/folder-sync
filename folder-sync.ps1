<#
.SYNOPSIS
  Copies files from a source folder to a replica folder.

.DESCRIPTION
  This script synchronizes the contents of a source folder with a replica folder. 
  You can specify a custom replica folder, log file, and optionally run the script in an infinite loop for continuous synchronization.

.PARAMETER SourceFolder
  The path to the folder to be copied from.

.PARAMETER ReplicaFolder
  The path to the folder where files will be copied to.
  [Optional] If not provided, the replica folder will be created with the same name as SourceFolder, appended with '-replica' (e.g., 'source-replica').

.PARAMETER LogFile
  The path to the file where log information will be written.
  [Optional] If not provided, the log will be saved in the current directory as 'folder-sync.log'.

.PARAMETER Infinite
  Runs the script in an infinite loop to continuously synchronize the folders.
  [Optional] Default is `$false`. If provided, the script will continuously monitor for changes.

.EXAMPLE
  C:\PS> ./folder-sync.ps1  "C:\Data" "C:\Backup" "C:\Logs\sync.log"

  This example synchronizes the 'C:\Data' folder with 'C:\Backup' and logs all actions to 'C:\Logs\sync.log'.

.EXAMPLE
  C:\PS> ./folder-sync.ps1 C:\Data -i

  This example synchronizes the 'C:\Data' folder with 'C:\Data-replica' and runs the script in an infinite loop, continuously syncing the folders untill the user manually stops it.

.EXAMPLE
  C:\PS> ./folder-sync.ps1 -SourceFolder "C:\Data"

  This example synchronizes the 'C:\Data' folder with 'C:\Data-replica' and logs the actions to 'folder-sync.log' in the current directory.

.NOTES
  Author:  Luis Rocha
  Date:    15 October 2024    
#>
param (
  [Parameter(Mandatory = $true)]
  [string]$SourceFolder, # Source folder path
  [string]$ReplicaFolder = $SourceFolder + '-replica', # Backup folder path
  [string]$LogFile = '.\folder-sync.log', # Log file path
  [Alias ('i')]
  [switch]$Infinite = $false
)

# Function to log actions
function Log {
  param (
    [string]$Message
  )
  # Log to the console
  Write-Host $Message
  # Append to the log file
  Add-Content -Path $LogFile -Value $Message
}

# Function to copy or update a single file
function Sync-File {
  param (
    [string]$SourceFile
  )
  $TargetFile = $SourceFile.Replace($SourceFolder, $ReplicaFolder)

  # Check if the file needs to be copied or updated
  if (-not (Test-Path -Path $TargetFile) -or 
      (Get-Item $SourceFile).LastWriteTime -gt (Get-Item $TargetFile).LastWriteTime) {
    Log "Copying file: $SourceFile to $TargetFile"
    Copy-Item -Path $SourceFile -Destination $TargetFile -Force
  }
}

# Function to remove a file from the replica
function Remove-File {
  param (
    [string]$ReplicaFile
  )
  Log "Removing file: $ReplicaFile"
  Remove-Item -Path $ReplicaFile -Force
}

# Check if folders exist
if (-Not (Test-Path -Path $SourceFolder)) {
  Log "Source folder does not exist: $SourceFolder"
  exit
}

# Check if source folder was passed with a / or \ to remove them from the replica folder
if ($SourceFolder.EndsWith('\') -or $SourceFolder.EndsWith('/')) {
  $ReplicaFolder = ($SourceFolder.Substring(0, $SourceFolder.Length - 1) + '-replica')
  Log "replica folder = $($ReplicaFolder)"
  exit
}

# Create replica folder if it doesn't exist
if (-Not (Test-Path -Path $ReplicaFolder)) {
  Log "Replica folder does not exist. Creating: $ReplicaFolder"
  New-Item -Path $ReplicaFolder -ItemType Directory
}

# Remove all files from replica folder
Get-ChildItem -Path $ReplicaFolder | ForEach-Object {
  Log "Removing file: $($_.FullName)"
  Remove-Item -Path $_.FullName -Force -Recurse
}

# Copy files from source folder to replica folder
# Log "Synchronizing contents from $SourceFolder to $ReplicaFolder"
# Get-ChildItem -Path $SourceFolder | ForEach-Object {
#   Log "Copying new file: $($_.FullName)"
#   Copy-Item -Path $_.FullName -Destination $ReplicaFolder -Recurse
# }

if ($Infinite) {
  Log "Running in infinite mode. Monitoring $SourceFolder for changes..."

  # Create the FileSystemWatcher to monitor the source folder
  $watcher = New-Object IO.FileSystemWatcher $SourceFolder -Property @{ 
    IncludeSubdirectories = $true
    NotifyFilter          = [IO.NotifyFilters]'FileName, LastWrite, DirectoryName'
  }
  $watcher.EnableRaisingEvents = $true

  # Define event handlers for changes in the source folder
  $action = {
    $changeType = $EventArgs.ChangeType
    $fullPath = $EventArgs.FullPath
    $type = $changeType -eq [System.IO.WatcherChangeTypes]::Created
    
    if ($type) {
      Write-Host "Change detected: $changeType at $fullPath | $type"
      Log "New file detected: $fullPath. Copying..."
      # Sync-File $fullPath 
    }

    # tried this with swich but not working and i dont understand why
    # events are being detected but the actions after are not being executed

    # if ($changeType -eq [System.IO.WatcherChangeTypes]::Created) {
    #   Log "New file detected: $fullPath. Copying..."
    #   Sync-File $fullPath  
    # }
    # elseif ($changeType -eq [System.IO.WatcherChangeTypes]::Renamed) {
    #   $oldPath = $event.SourceEventArgs.OldFullPath
    #   $newPath = $event.SourceEventArgs.FullPath
    #   $oldReplica = $oldPath.Replace($SourceFolder, $ReplicaFolder)
    #   $newReplica = $newPath.Replace($SourceFolder, $ReplicaFolder)
    #   Log "File renamed from $oldPath to $newPath. Updating replica..."
    #   Rename-Item -Path $oldReplica -NewName $newReplica
    # }
    # elseif ($changeType -eq [System.IO.WatcherChangeTypes]::Deleted) {
    #   $targetFile = $fullPath.Replace($SourceFolder, $ReplicaFolder)
    #   Log "File deleted: $fullPath. Removing from replica..."
    #   Remove-File $targetFile
    # }
    # elseif ($changeType -eq [System.IO.WatcherChangeTypes]::Changed) {
    #   Log "File changed: $fullPath. Updating..."
    #   Sync-File $fullPath
    # }
    # else {
    #   Log "Unknown change detected: $changeType"
    # }
  }

  # Register for events
  Register-ObjectEvent -InputObject $Watcher -EventName Created -Action $action -SourceIdentifier "folder-sync.Created"
  Register-ObjectEvent -InputObject $Watcher -EventName Changed -Action $action -SourceIdentifier "folder-sync.Changed"
  Register-ObjectEvent -InputObject $Watcher -EventName Deleted -Action $action -SourceIdentifier "folder-sync.Deleted"
  Register-ObjectEvent -InputObject $Watcher -EventName Renamed -Action $action -SourceIdentifier "folder-sync.Renamed"

  $Flag = $true
  Write-Host "Press any key to stop..."
  while ($Flag) {
    if ([System.Console]::KeyAvailable) {
      $Flag = $false
    }
    Start-Sleep 1
  }

  # Unregister events
  Log "Unregistering events and quiting..."
  Unregister-Event -SourceIdentifier "folder-sync.Created"
  Unregister-Event -SourceIdentifier "folder-sync.Changed"
  Unregister-Event -SourceIdentifier "folder-sync.Deleted"
  Unregister-Event -SourceIdentifier "folder-sync.Renamed"
}
