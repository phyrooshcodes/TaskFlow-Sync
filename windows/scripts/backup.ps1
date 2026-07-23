# TaskFlow PowerShell Auto-Backup Script
$RepoDir = "$env:USERPROFILE\TaskFlow-Sync"

if (Test-Path "$RepoDir\todo.json") {
    Set-Location $RepoDir
    $Status = git status --porcelain todo.json
    if ($Status) {
        git add todo.json
        $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "Auto-backup $Date"
        git push origin main
    }
}
