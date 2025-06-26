@echo off
echo.
echo ===============================================
echo    EMERGENCY FIX FOR NEW REPOSITORY
echo ===============================================
echo.

echo The problem: Your new repository still has merge conflicts!
echo This means when you copied files, you copied a conflicted file.
echo.

set /p "NEW_REPO_PATH=Enter the full path to your NEW GitHub repository folder: "

if not exist "%NEW_REPO_PATH%" (
    echo ERROR: Path does not exist!
    pause
    exit /b
)

echo.
echo Step 1: Replacing the conflicted AdminLoginPage.tsx with clean version...

copy "CLEAN_AdminLoginPage.tsx" "%NEW_REPO_PATH%\src\pages\admin\AdminLoginPage.tsx" /Y

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not copy clean file!
    echo.
    echo MANUAL SOLUTION:
    echo 1. Go to: %NEW_REPO_PATH%\src\pages\admin\
    echo 2. Open AdminLoginPage.tsx in a text editor
    echo 3. Find and DELETE any lines with:
    echo    <<<<<<< HEAD
    echo    =======
    echo    >>>>>>> 
    echo 4. Save the file
    echo.
    pause
    exit /b
)

echo ✅ Clean file copied successfully!
echo.

echo Step 2: Checking for other conflict markers...
findstr /S /N /C:"<<<<<<< HEAD" "%NEW_REPO_PATH%\*" 2>nul
findstr /S /N /C:"=======" "%NEW_REPO_PATH%\*" 2>nul
findstr /S /N /C:">>>>>>> " "%NEW_REPO_PATH%\*" 2>nul

echo.
echo ===============================================
echo   NEXT STEPS:
echo ===============================================
echo.
echo 1. Open GitHub Desktop
echo 2. Select your NEW repository 
echo 3. You should see AdminLoginPage.tsx changed
echo 4. Commit: "Fix merge conflicts in AdminLoginPage"
echo 5. Push to GitHub
echo 6. Wait for Netlify to rebuild (2-3 minutes)
echo 7. Check your site - should work now!
echo.
echo ===============================================

pause
