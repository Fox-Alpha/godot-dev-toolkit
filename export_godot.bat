@echo off
chcp 65001

cls

:: #####
:: GODOT EXPORT BUILDER - Unified Build Script
:: Consolidated version from cli.cmd, cli_work.cmd, and cli_work_44b4.bat
:: #####

:: #####
:: CONFIGURATION - Select your Godot version below
:: Uncomment ONE of the following blocks and comment out the others
:: #####

:: ===== GODOT 4.3-rc3 =====
REM set "gdpath=C:\Proggen\Godot\Godot_v4.3-rc"
REM set "godotexe=Godot_v4.3-rc3_win64.exe"
REM set "godotver=Godot_v4.3-rc3_win64.exe --version"
REM set "build_version=_alpha7"
REM set "build_path=C:\Proggen\Godot\Projekte\Just4Fun_Mini_Shootergame\export\gd-4-3\"

:: ===== GODOT 4.4-dev6 =====
REM set "gdpath=C:\Proggen\Godot\Godot_v4.4-dev"
REM set "godotexe=Godot_v4.4-dev6_win64.exe"
REM set "godotver=Godot_v4.4-dev6_win64.exe --version"
REM set "build_version=_alpha7"
REM set "build_path=C:\Proggen\Godot\Projekte\Just4Fun_Mini_Shootergame\export\gd-4-4\"

:: ===== GODOT 4.4-beta4 (DEFAULT - LATEST) =====
set "gdpath=C:\Proggen\Godot\Godot_v4.4-beta"
set "godotexe=Godot_v4.4-beta4_win64.exe"
set "godotver=Godot_v4.4-beta4_win64.exe --version"
set "build_version=_alpha9"

:: #####
:: COMMON VARIABLES - Adjust if needed
:: #####

REM Full Project Path
set "project=%~dp0"

REM Full Engine Path
set "build_godot=%gdpath%\%godotexe%"

REM Profilename in export_presets.cfg
REM set "build_profile=Windows Desktop"
set "build_profile=Windows"

REM export Type: export-debug, export-release, or export-pack (must be .pck or .zip)
REM set "build_type=export-debug"
set "build_type=export-release"
REM set "build_type=export-pack"

REM Project name for directory structure and naming
set "build_project_name=MiniShooterGame"

REM Version suffix for Engine Version (will be extracted automatically)
set "build_gdversion="
FOR /F %%I IN ('=%gdpath%\%godotver%') DO @SET "build_gdversion=%%I"

REM For older versions with static paths, use this instead:
REM REM For 4.3-rc: set "build_path=C:\Proggen\Godot\Projekte\Just4Fun_Mini_Shootergame\export\gd-4-3\"
REM REM For 4.4-dev: set "build_path=C:\Proggen\Godot\Projekte\Just4Fun_Mini_Shootergame\export\gd-4-4\"

REM If build_path not set, use dynamic path (for 4.4-beta4 and newer):
if not defined build_path (
	set "build_path=C:\Proggen\Godot\Projekte\export\%build_gdversion%\%build_project_name%"
)

REM Subfolder for Export Profile
set "build_folder=%build_path%\%build_profile%"

REM Output binary name
set "build_bin=%build_project_name%_%build_version%_%build_gdversion%.exe"

REM Full Build Path+Name
set "build_project=%build_folder%\%build_bin%"

REM Full Build Log output
set "build_log=%build_folder%\%build_project_name%_export.log.txt"

:: #####
:: execute
:: #####

echo #####
call :check_engine || echo check_engine Failed && exit /b -99
echo #####

call :check_folder || echo check_folder Failed && exit /b -99
echo #####

if exist "%build_project%" (
    echo Existing Binary Exports will deleted first
	del "%build_project%" /F
)
echo #####

echo #####
echo Execute Engine for import all resources
"%build_godot%" --verbose --import --headless > "%build_log%" 2>&1
echo #####

echo Execute Build Process overwrite export_presets.cfg export path
"%build_godot%" --verbose --headless  --%build_type% "%build_profile%" --path %project% "%build_project%" >> "%build_log%" 2>&1
echo #####

echo ERRORLEVEL: %ERRORLEVEL%
if %ERRORLEVEL% EQU 0 (
	call :check_export_output || echo Export Failed && exit /b -99
)
exit /b 0

:: #####
:: checks before execute project export
:: #####
:check_engine
echo checking Engine Settings
echo PATH: "%build_godot%"
echo Version: "%build_gdversion%"

if NOT exist "%build_godot%" (
    echo path to engine or engine executabele does not exist
	exit /b -1
)

exit /b 0

:check_folder
echo checking project and export Settings
echo ProjectFile: "%project%project.godot"
if NOT exist "%project%project.godot" (
    echo the project file does not exist
	exit /b -1
)

echo ExportFolder: "%build_folder%"
if NOT exist "%build_folder%\." (
    echo the build folder does not exist
	echo creating ...
	mkdir "%build_folder%"
	call :check_folder || echo check_folder Failed && exit /b -99
)

exit /b 0

:check_export_output
echo checking export success
echo Export Binary: %build_project%
if NOT exist "%build_project%" (
    echo the Exported Binary does not exist
	exit /b -1
)
echo the export was successfull
CHOICE /C XN /M "Start the exported binary [X] Execute or [N] do not" /N /D N /T 10
IF %ERRORLEVEL% EQU 1 (
    call "%build_project%"
) else (
    exit /b 0
)
exit /b 0
:: #####
