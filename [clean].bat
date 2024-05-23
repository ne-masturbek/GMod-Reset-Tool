@echo off
setlocal enabledelayedexpansion

:menu
cls
echo [ne_masturbek] Hello, which files would you like to reinstall?
echo Write the number or the name of the option. Example:
echo If you want to clean gamemodes base, write 6 or base
echo [ne_masturbek] 1. lua
echo [ne_masturbek] 2. addons
echo [ne_masturbek] 3. gamemodes
echo [ne_masturbek] 4. gamemodes  sandbox
echo [ne_masturbek] 5. gamemodes  base
echo [ne_masturbek] 6. All (all folders)
set /p choice="[User]: "

set "target="
set "clean_path="
set "root_path=%~dp0"

if "%choice%"=="1" set target=lua
if "%choice%"=="lua" set target=lua
if "%choice%"=="2" set target=addons
if "%choice%"=="addons" set target=addons
if "%choice%"=="3" set target=gamemodes
if "%choice%"=="gamemodes" set target=gamemodes
if "%choice%"=="4" set target=gamemodes\sandbox
if "%choice%"=="sandbox" set target=gamemodes\sandbox
if "%choice%"=="5" set target=gamemodes\base
if "%choice%"=="base" set target=gamemodes\base
if "%choice%"=="6" set target=All
if "%choice%"=="all" set target=All

if "%target%"=="" (
    echo Invalid choice. Please try again.
    pause
    goto menu
)

if "%target%"=="All" (
    call :clean "lua"
    call :clean "addons"
    call :clean "gamemodes"
    call :clean "gamemodes\sandbox"
    call :clean "gamemodes\base"
) else (
    call :clean "%target%"
)

echo Reinstallation completed.
pause
goto :eof

:clean
set "folder=%~1"
set "clean_path=%root_path%clean\%folder%"

echo Cleaning %folder%...

if exist "%root_path%%folder%" (
    rd /s /q "%root_path%%folder%"
)

if exist "%clean_path%" (
    xcopy /e /i "%clean_path%" "%root_path%%folder%"
)

call :show_progress %folder%

goto :eof

:show_progress
set /a total=5
set /a completed=0

for %%A in (lua addons gamemodes "gamemodes\sandbox" "gamemodes\base") do (
    if "%~1"=="%%A" (
        set /a completed+=1
    )
)

set /a percent=(completed*100)/total
echo Progress: !percent!%%

goto :eof
