@echo off
echo.
echo =====================================================
echo    NETLIFY DEPLOYMENT FIX - MERGE CONFLICT RESOLVER
echo =====================================================
echo.

set "WORKSPACE=c:\Users\naf-d\Downloads\workspace"
set "GITHUB_PATH=\\NAF-PC-01\Users\naf-d\Documents\GitHub\FINALNEWAGEFRNTENDBACKNINJA24062025"

echo THE PROBLEM:
echo Your Netlify deployment failed due to Git merge conflicts.
echo Error: "Unexpected <<<<<<< HEAD" in AdminLoginPage.tsx
echo.

echo SOLUTION OPTIONS:
echo.
echo [1] QUICK FIX - Copy clean files over conflicted ones
echo [2] NUCLEAR OPTION - Delete repo and start fresh  
echo [3] MANUAL FIX - Instructions only
echo.

set /p "CHOICE=Choose option (1/2/3): "

if "%CHOICE%"=="1" goto :quickfix
if "%CHOICE%"=="2" goto :nuclear
if "%CHOICE%"=="3" goto :manual
echo Invalid choice. Exiting.
pause
exit /b

:quickfix
echo.
echo === QUICK FIX: Copying clean files ===
echo.
echo Copying clean workspace files to GitHub repository...

robocopy "%WORKSPACE%" "%GITHUB_PATH%" /E /XD .git /XF .git* /R:3 /W:5

if %ERRORLEVEL% GEQ 8 (
    echo.
    echo ERROR: Copy failed. Try the nuclear option.
    goto :end
)

echo.
echo ✅ Files copied successfully!
echo.
echo NEXT STEPS:
echo 1. Open GitHub Desktop
echo 2. You should see file changes
echo 3. Commit: "Fix merge conflicts - deploy clean version"
echo 4. Push to main branch
echo 5. Check Netlify - should deploy successfully now
echo.
goto :end

:nuclear
echo.
echo === NUCLEAR OPTION: Fresh start ===
echo.
echo WARNING: This will delete your GitHub repository folder
echo and require you to re-clone from GitHub.
echo.
set /p "CONFIRM=Are you sure? This will delete %GITHUB_PATH% (Y/N): "
if /i not "%CONFIRM%"=="Y" goto :end

echo.
echo Step 1: Deleting repository folder...
rmdir /s /q "%GITHUB_PATH%"

echo.
echo Step 2: You need to clone fresh repository
echo Run this command:
echo.
echo cd "\\NAF-PC-01\Users\naf-d\Documents\GitHub"
echo git clone https://github.com/YOUR-USERNAME/FINALNEWAGEFRNTENDBACKNINJA24062025.git
echo.
echo Step 3: After cloning, copy workspace files:
echo robocopy "%WORKSPACE%" "%GITHUB_PATH%" /E /XD .git /XF .git* /R:3 /W:5
echo.
echo Step 4: Commit and push with GitHub Desktop
echo.
goto :end

:manual
echo.
echo === MANUAL FIX INSTRUCTIONS ===
echo.
echo 1. Go to: %GITHUB_PATH%
echo 2. Open: src\pages\admin\AdminLoginPage.tsx
echo 3. Look for these lines and DELETE them:
echo    <<<<<<< HEAD
echo    =======  
echo    >>>>>>> branch-name
echo.
echo 4. Keep only the clean code (no conflict markers)
echo 5. Save the file
echo 6. Use GitHub Desktop to commit: "Fix merge conflicts"
echo 7. Push to main branch
echo.
echo The conflict is around line 126 where the logo image is defined.
echo Keep this version:
echo.
echo   ^<img 
echo     src="/crm-logo.png"
echo     alt="TogNinja CRM"
echo     className="h-24 w-auto object-contain"
echo   /^>
echo.

:end
echo.
echo =====================================================
echo After fixing, your deployment should succeed and 
echo your site will show the new TogNinja logo!
echo =====================================================
echo.
pause
