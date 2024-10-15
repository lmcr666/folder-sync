param (
  [Parameter(Mandatory = $true)]
  [string]$SourceFolder, # Source folder path
  [Parameter(Mandatory = $true)]
  [string]$ReplicaFolder, # Backup folder path
  [string]$LogFile = '.\folder-sync.log'        # Log file path
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

# Check if folders exist
if (-Not (Test-Path -Path $SourceFolder)) {
  Log "Source folder does not exist: $SourceFolder"
  exit
}

if (-Not (Test-Path -Path $ReplicaFolder)) {
  Log "Replica folder does not exist. Creating: $ReplicaFolder"
  New-Item -Path $ReplicaFolder -ItemType Directory
}


# Start synchronization
Log "Synchronization started at $(Get-Date)"



Log "Synchronization completed at $(Get-Date)"
