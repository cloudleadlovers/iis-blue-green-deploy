param (
    [string]$serverFarmName = "leadlovers-production",
    [string]$bluePath = "C:\Home\leadlovers\production\blue",
    [string]$greenPath = "C:\Home\leadlovers\production\green",
    [string]$bluePort = 8001,
    [string]$greenPort = 8002,
    [string]$warmUpPath = "health",
    [string]$codePath = "C:\Temp\leadlovers\production" ,
    [string]$backupPath = "C:\Home\leadlovers\production\backup",
    [bool]$precompile = $true
) 

$folders = Get-ChildItem -Path $backupPath | ?{ $_.PSIsContainer } | Sort-Object -Property LastWriteTime | Select-Object FullName
if ($folders.Count -gt 0) {
    $cnt = 1
    foreach ($folder in $folders) {
        Write-Host "[$cnt] " -foreground "yellow" -NoNewLine
        Write-Host "$($folder.FullName)" -foreground "darkgray"
        $cnt++
    }
    $index = Read-Host -Prompt "Type the number of the backup version you wish to recover..."
    if (($index -lt 1) -or ($index -gt $folders.Count)) {
        Write-Error "There is no backup version with code $index"
        exit 1
    } else {
        $backupVersion = $folders[$index - 1]
        $confirm = Read-Host "Are you sure you want to rollback to version $($backupVersion.FullName)? [y|n]"
        if ($confirm -eq 'y') {
            $cmd = "C:\Home\iis-bluegreen-powershell\local-deploy.ps1"
            $cmd = $cmd + " -serverFarmName `"$serverFarmName`""
            $cmd = $cmd + " -bluePath `"$bluePath`""
            $cmd = $cmd + " -greenPath `"$greenPath`""
            $cmd = $cmd + " -bluePort `"$bluePort`""
            $cmd = $cmd + " -greenPort `"$greenPort`""
            $cmd = $cmd + " -warmUpPath `"$warmUpPath`""
            $cmd = $cmd + " -codePath `"$($backupVersion.FullName)`""
            $cmd = $cmd + " -backupPath `"$backupPath`""
            $cmd = $cmd + " -precompile `$true"
            $cmd = $cmd + " -backup `$false"
            Invoke-Expression $cmd
        }
    }
} else {
    Write-Warning "No backup versions found at $backupPath..."
    exit 0
}