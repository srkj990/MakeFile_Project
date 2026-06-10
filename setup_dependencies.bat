@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo ============================================================
echo  MakeFile_Project dependency setup
echo ============================================================
echo.
echo This script installs/checks the tools needed by build\makefile:
echo   - make and Unix command-line tools
echo   - Arm GNU Toolchain for arm-none-eabi
echo   - Git Bash / MSYS2 shell utilities
echo   - OpenSSL utilities used by build\build.sh
echo.

where winget >nul 2>nul
if errorlevel 1 (
    echo ERROR: winget was not found.
    echo Install "App Installer" from Microsoft Store, then run this script again.
    echo.
    pause
    exit /b 1
)

echo [1/5] Installing Git for Windows, if missing...
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements

echo.
echo [2/5] Installing MSYS2, if missing...
winget install --id MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements

echo.
echo [3/5] Installing Arm GNU Toolchain, if available through winget...
winget install --id Arm.GnuArmEmbeddedToolchain -e --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
    echo.
    echo WARNING: winget could not install Arm.GnuArmEmbeddedToolchain automatically.
    echo Search for the current package with:
    echo   winget search "Arm GNU Toolchain"
    echo.
    echo Then install the arm-none-eabi package shown by winget.
)

echo.
echo [4/5] Installing MSYS2 build utilities...
set "MSYS2_BASH=C:\msys64\usr\bin\bash.exe"
if not exist "%MSYS2_BASH%" (
    echo ERROR: MSYS2 bash was not found at:
    echo   %MSYS2_BASH%
    echo.
    echo If MSYS2 was installed elsewhere, open an MSYS2 terminal and run:
    echo   pacman -Sy --needed --noconfirm make grep diffutils coreutils findutils sed gawk openssl
    echo.
    pause
    exit /b 1
)

"%MSYS2_BASH%" -lc "pacman -Sy --needed --noconfirm make grep diffutils coreutils findutils sed gawk openssl"
if errorlevel 1 (
    echo.
    echo WARNING: MSYS2 package installation reported an error.
    echo Open "MSYS2 MSYS" from the Start menu and run:
    echo   pacman -Syu
    echo   pacman -Sy --needed --noconfirm make grep diffutils coreutils findutils sed gawk openssl
)

echo.
echo [5/5] Checking required commands...
echo.

call :check_tool make
call :check_tool grep
call :check_tool arm-none-eabi-gcc
call :check_tool arm-none-eabi-ld
call :check_tool arm-none-eabi-objcopy
call :check_tool arm-none-eabi-nm
call :check_tool arm-none-eabi-readelf
call :check_tool arm-none-eabi-objdump
call :check_tool openssl

echo.
echo ============================================================
echo  Setup finished
echo ============================================================
echo.
echo If any tool above is marked MISSING, close and reopen Command Prompt
echo or VS Code so PATH changes are picked up, then run:
echo.
echo   cd /d %~dp0build
echo   b.bat
echo.
echo If arm-none-eabi-gcc is still missing, find it with:
echo.
echo   where /r "C:\Program Files" arm-none-eabi-gcc.exe
echo   where /r "C:\Program Files (x86)" arm-none-eabi-gcc.exe
echo.
echo Then add the folder containing arm-none-eabi-gcc.exe to your user PATH.
echo.
pause
exit /b 0

:check_tool
where %1 >nul 2>nul
if errorlevel 1 (
    echo   MISSING  %1
) else (
    for /f "delims=" %%P in ('where %1 2^>nul') do (
        echo   OK       %1  -  %%P
        goto :eof
    )
)
goto :eof
