param (
    [string]$serverFarmName = $(throw '-serverFarmName is required'),
    [string]$bluePath = $(throw '-bluePath is required'),
    [string]$greenPath = $(throw '-greenPath is required'),
    [string]$bluePort = $(throw '-bluePort is required'),
    [string]$greenPort = $(throw '-greenPort is required'),
    [string]$warmUpPath = $(throw '-warmUpPath is required'),
    [string]$codePath = $(throw '-codePath is required'),
    [string]$backupPath = $(throw '-backupPath is required'),
    [bool]$precompile = $false,
    [bool]$backup = $true
)

Try {

    Import-Module -Force "$PSScriptRoot\lib\server-farm.psm1"
    Import-Module -Force "$PSScriptRoot\lib\remote-execution.psm1"

    Write-Host "======================================================================================================="
    Write-Host "Starting deploy at local session..."

    $session = New-PsSession -ComputerName "localhost"
    Import-ModuleRemotely "server-farm" $session
    $currentConfig = Invoke-ScriptRemotely -localScriptFile "$PSScriptRoot\prepare\01_get-staging-and-live.ps1" -Session $session -ArgumentList $serverFarmName, $bluePath, $greenPath
    Write-Host "Current Blue/Green Config:"
    $currentConfig

    $deployPath = $currentConfig["StagingDeployPath"]
    $livePath = $currentConfig["LiveDeployPath"]
    $liveServer = $currentConfig["LiveServer"]
    $stagingServer = $currentConfig["StagingServer"]

    Write-Host "-------------------------------------------------------------------------------------------------------"
    Write-Host "Deploy path: $deployPath"
    Write-Host "Live path: $livePath"
    Write-Host "Live server: $liveServer"
    Write-Host "Staging server: $stagingServer"
    Write-Host "-------------------------------------------------------------------------------------------------------"

    Write-Host "======================================================================================================="
    Write-Host "Deploying new version at $deployPath ..."
    RoboCopy $codePath $deployPath /mir /nfl /ndl /xf "up.html"

    Write-Host "======================================================================================================="
    Write-Host "Warming up staging server $stagingServer ..."
    Invoke-ScriptRemotely -localScriptFile "$PSScriptRoot\swap\02_warm-up-staging.ps1" -Session $session -ArgumentList $stagingServer, $bluePort, $greenPort, $serverFarmName, $deployPath, $warmUpPath, $precompile

    Write-Host "======================================================================================================="
    Write-Host "Bringing staging server $stagingServer up..."
    Invoke-ScriptRemotely -localScriptFile "$PSScriptRoot\swap\03_bring-staging-up.ps1" -Session $session -ArgumentList $serverFarmName, $stagingServer, $deployPath

    Write-Host "======================================================================================================="
    Write-Host "Draining live server $liveServer ..."
    Invoke-ScriptRemotely -localScriptFile "$PSScriptRoot\swap\04_drain-live-instance.ps1" -Session $session -ArgumentList $serverFarmName, $liveServer, $livePath

    Write-Host "======================================================================================================="
    Write-Host "Post deploy health check..."
    Invoke-ScriptRemotely -localScriptFile "$PSScriptRoot\swap\05_post-deploy-health-check.ps1" -Session $session -ArgumentList $serverFarmName, $stagingServer, $liveServer

    if ($backup) {
        Write-Host "======================================================================================================="
        Write-Host "Backing up old live server code..."
        Invoke-ScriptRemotely -localScriptFile "$PSScriptRoot\swap\06_backup_old_live_server.ps1" -Session $session -ArgumentList $livePath, $backupPath
    }

    Write-Host "======================================================================================================="
    Write-Host "Deployment complete"
    Exit-PsSession
    Remove-PsSession -Session $session

    exit 0

}
Catch {

    Write-Error $_
    exit 1
    
}
