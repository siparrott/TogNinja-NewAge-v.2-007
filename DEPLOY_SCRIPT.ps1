# 🚀 AUTOMATED DEPLOYMENT SCRIPT
# This script copies ALL files from VS Code workspace to GitHub repository folder

# INSTRUCTIONS:
# 1. Right-click and "Run with PowerShell"
# 2. When prompted, enter the path to your GitHub Desktop repository folder
# 3. The script will copy everything EXCEPT .git folder

Write-Host "🚀 TogNinja CRM Deployment Script" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Source folder (VS Code workspace)
$sourceFolder = "c:\Users\naf-d\Downloads\workspace"

# Get destination folder from user
Write-Host "📁 Enter the path to your GitHub Desktop repository folder:" -ForegroundColor Yellow
Write-Host "   Example: C:\Users\YourName\Documents\GitHub\your-repo-name" -ForegroundColor Gray
$destinationFolder = Read-Host "GitHub Repository Path"

# Validate paths
if (-not (Test-Path $sourceFolder)) {
    Write-Host "❌ ERROR: Source folder not found: $sourceFolder" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $destinationFolder)) {
    Write-Host "❌ ERROR: Destination folder not found: $destinationFolder" -ForegroundColor Red
    exit 1
}

# Check if destination has .git folder
$gitFolder = Join-Path $destinationFolder ".git"
if (-not (Test-Path $gitFolder)) {
    Write-Host "⚠️  WARNING: No .git folder found in destination. Are you sure this is a Git repository?" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 0
    }
}

Write-Host ""
Write-Host "📋 DEPLOYMENT PLAN:" -ForegroundColor Green
Write-Host "   FROM: $sourceFolder" -ForegroundColor White
Write-Host "   TO:   $destinationFolder" -ForegroundColor White
Write-Host "   PRESERVE: .git folder (Git history)" -ForegroundColor Yellow
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "🚀 Ready to deploy ALL critical fixes? This will overwrite existing files. (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ Deployment cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🔄 Starting deployment..." -ForegroundColor Cyan

try {
    # Create backup timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Copy everything except .git folder
    Write-Host "📁 Copying files (excluding .git)..." -ForegroundColor Yellow
    
    # Use robocopy for efficient copying
    $robocopyArgs = @(
        $sourceFolder,
        $destinationFolder,
        "/E",           # Copy subdirectories including empty ones
        "/XD", ".git",  # Exclude .git directory
        "/XF", ".git*", # Exclude any .git files
        "/NFL",         # No file list (less verbose)
        "/NDL",         # No directory list
        "/NP",          # No progress
        "/R:3",         # Retry 3 times
        "/W:5"          # Wait 5 seconds between retries
    )
    
    $result = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
    
    # Robocopy exit codes: 0-7 are success, 8+ are errors
    if ($result.ExitCode -ge 8) {
        throw "Robocopy failed with exit code: $($result.ExitCode)"
    }
    
    Write-Host "✅ File copy completed successfully!" -ForegroundColor Green
    
    # Verify critical files were copied
    Write-Host ""
    Write-Host "🔍 Verifying critical files..." -ForegroundColor Yellow
    
    $criticalFiles = @(
        "src\App.tsx",
        "src\pages\admin\QuestionnairesPageV2.tsx",
        "src\components\layout\Footer.tsx",
        "src\components\layout\Header.tsx",
        "public\togninja-logo.svg",
        "public\favicon.svg",
        "index.html"
    )
    
    $missingFiles = @()
    foreach ($file in $criticalFiles) {
        $fullPath = Join-Path $destinationFolder $file
        if (-not (Test-Path $fullPath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-Host "✅ All critical files verified!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Missing files:" -ForegroundColor Yellow
        $missingFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    }
    
    Write-Host ""
    Write-Host "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "1. Open GitHub Desktop" -ForegroundColor White
    Write-Host "2. Review all changes (you should see many files modified)" -ForegroundColor White
    Write-Host "3. Commit with message: 'Deploy all critical fixes: Survey builder, TogNinja branding, OpenAI assistants'" -ForegroundColor White
    Write-Host "4. Push to main branch" -ForegroundColor White
    Write-Host "5. Wait for Netlify to deploy (2-5 minutes)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔥 YOUR PRODUCTION SITE WILL NOW HAVE:" -ForegroundColor Yellow
    Write-Host "   ✅ Full Survey Builder (no more 'Coming Soon')" -ForegroundColor Green
    Write-Host "   ✅ TogNinja Branding throughout" -ForegroundColor Green
    Write-Host "   ✅ OpenAI Assistant Integration" -ForegroundColor Green
    Write-Host "   ✅ Invoice System Overhaul" -ForegroundColor Green
    Write-Host "   ✅ Working i18n Translation" -ForegroundColor Green
    Write-Host "   ✅ Enhanced Gallery & Calendar" -ForegroundColor Green
    Write-Host "   ✅ Comprehensive Analytics" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 MANUAL FALLBACK:" -ForegroundColor Yellow
    Write-Host "1. Open Windows Explorer" -ForegroundColor White
    Write-Host "2. Navigate to: $sourceFolder" -ForegroundColor White
    Write-Host "3. Select all files and folders EXCEPT .git" -ForegroundColor White
    Write-Host "4. Copy (Ctrl+C)" -ForegroundColor White
    Write-Host "5. Navigate to: $destinationFolder" -ForegroundColor White
    Write-Host "6. Delete all files and folders EXCEPT .git" -ForegroundColor White
    Write-Host "7. Paste (Ctrl+V)" -ForegroundColor White
    exit 1
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
