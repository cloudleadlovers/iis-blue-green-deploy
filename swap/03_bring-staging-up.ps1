param (
    [string]$serverFarmName = $(throw '-serverFarmName is required'),
    [string]$stagingInstance = $(throw '-stagingInstance is required'),
    [string]$stagingPath = $(throw '-stagingPath is required')
)

# Make sure it is set to state=Available
Set-InstanceState $serverFarmName $stagingInstance 0
# Bring it online if its down
$isOnline = Get-ServerOnLine $serverFarmName $stagingInstance
if ($isOnline -eq $false) {
    Set-ServerOnline $serverFarmName $stagingInstance
}
# Update health check file
Set-HealthCheckFile $stagingPath "up"

Write-Host "Staging brought up"
