@echo off
echo.
echo =====================================================
echo    DEPLOYMENT STATUS CHECKER
echo =====================================================
echo.

set "WORKSPACE=c:\Users\naf-d\Downloads\workspace"
set "GITHUB_PATH=\\NAF-PC-01\Users\naf-d\Documents\GitHub\FINALNEWAGEFRNTENDBACKNINJA24062025"

echo Checking if files exist...
echo.

echo WORKSPACE FILES:
if exist "%WORKSPACE%\src\App.tsx" (
    echo ✅ App.tsx exists in workspace
) else (
    echo ❌ App.tsx missing in workspace
)

if exist "%WORKSPACE%\public\frontend-logo.jpg" (
    echo ✅ frontend-logo.jpg exists in workspace
) else (
    echo ❌ frontend-logo.jpg missing in workspace
)

if exist "%WORKSPACE%\public\crm-logo.png" (
    echo ✅ crm-logo.png exists in workspace
) else (
    echo ❌ crm-logo.png missing in workspace
)

echo.
echo GITHUB REPOSITORY FILES:
if exist "%GITHUB_PATH%\src\App.tsx" (
    echo ✅ App.tsx exists in GitHub repo
) else (
    echo ❌ App.tsx missing in GitHub repo - NEEDS DEPLOYMENT
)

if exist "%GITHUB_PATH%\public\frontend-logo.jpg" (
    echo ✅ frontend-logo.jpg exists in GitHub repo
) else (
    echo ❌ frontend-logo.jpg missing in GitHub repo - NEEDS DEPLOYMENT
)

if exist "%GITHUB_PATH%\public\crm-logo.png" (
    echo ✅ crm-logo.png exists in GitHub repo
) else (
    echo ❌ crm-logo.png missing in GitHub repo - NEEDS DEPLOYMENT
)

echo.
echo =====================================================
echo   DEPLOYMENT INSTRUCTIONS:
echo =====================================================
echo.
echo 1. If GitHub repo files are missing, copy manually:
echo    - Open File Explorer
echo    - Copy from: %WORKSPACE%
echo    - Paste to: %GITHUB_PATH%
echo    - PRESERVE .git folder
echo.
echo 2. Open GitHub Desktop and commit changes
echo 3. Push to main branch
echo 4. Wait for Netlify deployment
echo.

pause
