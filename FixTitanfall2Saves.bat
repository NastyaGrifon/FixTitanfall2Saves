@echo off

:: @nastyagrifon 2023
:: OG script: https://www.elevenforum.com/t/move-or-restore-default-location-of-documents-folder-in-windows-11.8708/

:: Bug Fix 1: Add proper function call order
goto :RunFunctions

set "OldDocumentsPath="
set "CurrentUser=%USERNAME%"

:GetOldDocsPath
for /f "tokens=2*" %%i in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal" ^| find "REG_SZ"') do set "OldDocumentsPath=%%j"
echo Old Documents Path: %OldDocumentsPath%

:TerminateExplorer
echo Terminating the Explorer.exe process
taskkill /f /im explorer.exe
timeout /t 2 /nobreak >nul

:UninstallOneDrive
echo Uninstalling OneDrive using winget
echo Sometimes winget would ask for License Agreement. In that case, please press "y" key
winget uninstall onedrive

:CreateDocsFolder
echo Creating the "Documents" folder if not present
if not exist "%USERPROFILE%\Documents" (
    mkdir "%USERPROFILE%\Documents"
)

:ResetPaths
echo Resetting paths to default for Documents

:: Bug Fix 3: Add registry value checks for efficiency
for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal" ^| find "REG_SZ"') do set "CurrentPersonal=%%i"
if not "%CurrentPersonal%"=="%USERPROFILE%\Documents" (
    reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal" /t REG_SZ /d "%%USERPROFILE%%\Documents" /f
)

for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{f42ee2d3-909f-4907-8871-4c22fc0bf756}" ^| find "REG_EXPAND_SZ"') do set "CurrentUserShell=%%i"
if not "%CurrentUserShell%"=="%USERPROFILE%\Documents" (
    reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{f42ee2d3-909f-4907-8871-4c22fc0bf756}" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Documents" /f
)

for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Personal" ^| find "REG_EXPAND_SZ"') do set "CurrentUserPersonal=%%i"
if not "%CurrentUserPersonal%"=="%USERPROFILE%\Documents" (
    reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Personal" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Documents" /f
)

:SetAttributesForDocs
echo Setting attributes for "Documents"
attrib -s -h "%USERPROFILE%\Documents" /S /D
timeout /t 1 /nobreak >nul

:RestartExplorer
echo Launching Explorer.exe
start explorer.exe

:SetPermissions
echo Setting RW permissions for OneDrive Documents folder
if exist "%OldDocumentsPath%" (
    icacls "%OldDocumentsPath%" /grant %CurrentUser%:(OI)(CI)F /T
)

:MoveFiles
echo Moving files from the old directory to new one

:: Bug Fix 2: Add validation for file operations
if exist "%OldDocumentsPath%" (
    if not "%OldDocumentsPath%"=="%USERPROFILE%\Documents" (
        echo Validating source path: %OldDocumentsPath%
        robocopy "%OldDocumentsPath%" "%USERPROFILE%\Documents" /E /MOVE
        if errorlevel 8 (
            echo ERROR: Robocopy failed with error level 8 (file copy errors)
            echo Some files may not have been moved. Please check manually.
        ) else if errorlevel 1 (
            echo Robocopy completed with some files copied successfully
        ) else if errorlevel 0 (
            echo Robocopy completed successfully
        )
    ) else (
        echo Source and destination are the same. No move operation needed.
    )
) else (
    echo Warning: Old documents path does not exist: %OldDocumentsPath%
    echo No files to move.
)

:Finish
echo You're good to go! Good luck, Pilot!
echo Press any button to close the script
rem Pause to see any errors during the move
pause

:RunFunctions
call :GetOldDocsPath
call :TerminateExplorer
call :UninstallOneDrive
call :CreateDocsFolder
call :ResetPaths
call :SetAttributesForDocs
call :RestartExplorer
call :SetPermissions
call :MoveFiles
call :Finish
