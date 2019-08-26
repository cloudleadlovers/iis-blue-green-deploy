param (
    [string]$oldLivePath = $(throw '-oldLivePath is required'),
    [string]$backupPath = $(throw '-backupPath is required')
)

$backupDate = Get-Date -Format "yyyy-MM-dd.HH-mm-ss"
$fullBackupPath = "$backupPath\v.$backupDate"
$exists = Test-Path $fullBackupPath
if ($exists -eq $FALSE) {
    New-Item $fullBackupPath -ItemType Directory
}

RoboCopy $oldLivePath $fullBackupPath /mir /nfl /ndl

Write-Host "Old live server backed up to $fullBackupPath ..."

# reclicle backup folder, keeping only 3 backup versions
$folders = Get-ChildItem -Path $backupPath | ?{ $_.PSIsContainer } | Sort-Object -Property LastWriteTime | Select-Object FullName
if ($folders.Count -gt 3) {
    $cnt = 0
    Foreach ($folder in $folders) {
        Remove-Item -Path $folder.FullName -Recurse -Force
        $cnt++
        if ($cnt -ge $folders.Count - 3) {
            break
        }
    }
}