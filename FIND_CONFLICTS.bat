@echo off
echo.
echo ================================================
echo    FINDING MERGE CONFLICTS IN YOUR NEW REPO
echo ================================================
echo.

set /p "REPO_PATH=Enter the path to your new GitHub repository folder: "

echo.
echo Searching for merge conflict markers in: %REPO_PATH%
echo.

findstr /S /N /C:"<<<<<<< HEAD" "%REPO_PATH%\*"
findstr /S /N /C:"=======" "%REPO_PATH%\*"  
findstr /S /N /C:">>>>>>> " "%REPO_PATH%\*"

echo.
echo ================================================
echo If any files show above, they contain conflicts!
echo You need to edit those files and remove the 
echo conflict markers before committing again.
echo ================================================
echo.
pause
