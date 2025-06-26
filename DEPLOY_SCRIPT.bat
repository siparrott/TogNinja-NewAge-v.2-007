@echo off
echo.
echo ====================================
echo    TogNinja CRM Deployment Script
echo ====================================
echo.

REM Set the correct GitHub repository path
set "GITHUB_PATH=\\NAF-PC-01\Users\naf-d\Documents\GitHub\FINALNEWAGEFRNTENDBACKNINJA24062025"

echo.
echo Deployment Plan:
echo   FROM: c:\Users\naf-d\Downloads\workspace
echo   TO:   %GITHUB_PATH%
echo   PRESERVE: .git folder
echo.

set /p "CONFIRM=Ready to deploy? This will overwrite files (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Deployment cancelled.
    pause
    exit /b
)

echo.
echo Copying files...
echo.

REM Use robocopy to copy everything except .git
robocopy "c:\Users\naf-d\Downloads\workspace" "%GITHUB_PATH%" /E /XD .git /XF .git* /R:3 /W:5

if %ERRORLEVEL% GEQ 8 (
    echo.
    echo ERROR: Copy operation failed!
    echo Please try manual copy method.
    pause
    exit /b 1
)

echo.
echo ===================================
echo   DEPLOYMENT COMPLETED!
echo ===================================
echo.
echo NEXT STEPS:
echo 1. Open GitHub Desktop
echo 2. Review changes
echo 3. Commit: "Deploy all critical fixes"
echo 4. Push to main branch
echo 5. Wait for Netlify deployment
echo.
echo YOUR SITE WILL NOW HAVE:
echo   - Full Survey Builder
echo   - TogNinja Branding
echo   - OpenAI Assistants
echo   - Invoice System Overhaul
echo   - Working Translations
echo   - Enhanced Features
echo.

pause
