@echo off
echo.
echo =====================================
echo   CRITICAL FILES VERIFICATION
echo =====================================
echo.

echo Checking critical files in workspace...
echo.

REM Check App.tsx
if exist "src\App.tsx" (
    echo ✅ src\App.tsx EXISTS
) else (
    echo ❌ src\App.tsx MISSING
)

REM Check TogNinja Logo
if exist "public\togninja-logo.svg" (
    echo ✅ public\togninja-logo.svg EXISTS
) else (
    echo ❌ public\togninja-logo.svg MISSING
)

REM Check Favicon
if exist "public\favicon.svg" (
    echo ✅ public\favicon.svg EXISTS
) else (
    echo ❌ public\favicon.svg MISSING
)

REM Check Survey Builder
if exist "src\pages\admin\QuestionnairesPageV2.tsx" (
    echo ✅ src\pages\admin\QuestionnairesPageV2.tsx EXISTS
) else (
    echo ❌ src\pages\admin\QuestionnairesPageV2.tsx MISSING
)

REM Check CRM Assistant
if exist "src\components\chat\CRMOperationsAssistant.tsx" (
    echo ✅ src\components\chat\CRMOperationsAssistant.tsx EXISTS
) else (
    echo ❌ src\components\chat\CRMOperationsAssistant.tsx MISSING
)

REM Check OpenAI Assistant
if exist "src\components\chat\OpenAIAssistantChat.tsx" (
    echo ✅ src\components\chat\OpenAIAssistantChat.tsx EXISTS
) else (
    echo ❌ src\components\chat\OpenAIAssistantChat.tsx MISSING
)

REM Check Footer
if exist "src\components\layout\Footer.tsx" (
    echo ✅ src\components\layout\Footer.tsx EXISTS
) else (
    echo ❌ src\components\layout\Footer.tsx MISSING
)

REM Check Language Context
if exist "src\context\LanguageContext.tsx" (
    echo ✅ src\context\LanguageContext.tsx EXISTS
) else (
    echo ❌ src\context\LanguageContext.tsx MISSING
)

REM Check Forms lib
if exist "src\lib\forms.ts" (
    echo ✅ src\lib\forms.ts EXISTS
) else (
    echo ❌ src\lib\forms.ts MISSING
)

REM Check OpenAI Edge Functions
if exist "supabase\functions\openai-send-crm-message\index.ts" (
    echo ✅ supabase\functions\openai-send-crm-message\index.ts EXISTS
) else (
    echo ❌ supabase\functions\openai-send-crm-message\index.ts MISSING
)

echo.
echo =====================================
echo   VERIFICATION COMPLETE
echo =====================================
echo.
echo If all files show ✅, your workspace is ready for deployment!
echo If any files show ❌, they need to be created/updated.
echo.

pause
