@echo off

:: @nastyagrifon 2023
:: OG script: https://www.elevenforum.com/t/move-or-restore-default-location-of-documents-folder-in-windows-11.8708/

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
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal" /t REG_SZ /d "%%USERPROFILE%%\Documents" /f
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{f42ee2d3-909f-4907-8871-4c22fc0bf756}" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Documents" /f
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Personal" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Documents" /f

:SetAttributesForDocs
echo Setting attributes for "Documents"
attrib -s -h "%USERPROFILE%\Documents" /S /D
timeout /t 1 /nobreak >nul

:RestartExplorer
echo Launching Explorer.exe
start explorer.exe

:SetPermissions
echo Setting RW permissions for OneDrive Documents folder
icacls "%OldDocumentsPath%" /grant %CurrentUser%:(OI)(CI)F /T

:MoveFiles
echo Moving files from the old directory to new one
robocopy "%OldDocumentsPath%" "%USERPROFILE%\Documents" /E /MOVE

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
