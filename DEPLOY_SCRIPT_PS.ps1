# TogNinja CRM Deployment Script (PowerShell)
# This script copies all files from workspace to GitHub repository

param(
    [switch]$Force = $false
)

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host "   TogNinja CRM Deployment Script" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

$SourcePath = "c:\Users\naf-d\Downloads\workspace"
$DestPath = "\\NAF-PC-01\Users\naf-d\Documents\GitHub\FINALNEWAGEFRNTENDBACKNINJA24062025"

Write-Host "Deployment Plan:" -ForegroundColor Yellow
Write-Host "  FROM: $SourcePath" -ForegroundColor White
Write-Host "  TO:   $DestPath" -ForegroundColor White
Write-Host "  PRESERVE: .git folder" -ForegroundColor White
Write-Host ""

# Check if paths exist
if (-not (Test-Path $SourcePath)) {
    Write-Host "ERROR: Source path not found: $SourcePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $DestPath)) {
    Write-Host "ERROR: Destination path not found: $DestPath" -ForegroundColor Red
    exit 1
}

# Confirm deployment unless Force parameter is used
if (-not $Force) {
    $confirm = Read-Host "Ready to deploy? This will overwrite files (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Copying files..." -ForegroundColor Yellow
Write-Host ""

try {
    # Use robocopy to copy files
    $robocopyArgs = @(
        "`"$SourcePath`"",
        "`"$DestPath`"",
        "/E",           # Copy subdirectories including empty ones
        "/XD", ".git",  # Exclude .git directory
        "/XF", ".git*", # Exclude .git files
        "/R:3",         # Retry 3 times
        "/W:5",         # Wait 5 seconds between retries
        "/MT:8",        # Multi-threaded (8 threads)
        "/NFL",         # No file list
        "/NDL"          # No directory list
    )
    
    $process = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
    
    # Robocopy exit codes: 0-7 are success, 8+ are errors
    if ($process.ExitCode -ge 8) {
        Write-Host "ERROR: Copy operation failed with exit code $($process.ExitCode)" -ForegroundColor Red
        Write-Host "Please try manual copy method or check permissions." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "===================================" -ForegroundColor Green
    Write-Host "   DEPLOYMENT COMPLETED!" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Files copied successfully!" -ForegroundColor Green
    Write-Host "Exit Code: $($process.ExitCode) (Success)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Open GitHub Desktop" -ForegroundColor White
    Write-Host "2. Review changes in your repository" -ForegroundColor White
    Write-Host "3. Commit: 'Deploy logo updates and critical fixes'" -ForegroundColor White
    Write-Host "4. Push to main branch" -ForegroundColor White
    Write-Host "5. Wait for Netlify deployment" -ForegroundColor White
    Write-Host ""
    
    Write-Host "YOUR SITE WILL NOW HAVE:" -ForegroundColor Cyan
    Write-Host "  - Updated CRM and Frontend Logos" -ForegroundColor White
    Write-Host "  - Fixed New Lead Button" -ForegroundColor White
    Write-Host "  - Fixed Invoice System" -ForegroundColor White
    Write-Host "  - Database Schema Ready" -ForegroundColor White
    Write-Host "  - Environment Setup Guides" -ForegroundColor White
    Write-Host "  - All Critical Fixes Applied" -ForegroundColor White
    Write-Host ""
    
    # Check if GitHub Desktop is running
    $githubDesktop = Get-Process -Name "GitHubDesktop" -ErrorAction SilentlyContinue
    if ($githubDesktop) {
        Write-Host "✓ GitHub Desktop is running - you should see changes now!" -ForegroundColor Green
    } else {
        Write-Host "→ Open GitHub Desktop to see the changes" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "ERROR: Deployment failed with exception:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
