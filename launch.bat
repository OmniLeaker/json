@echo off
REM This batch script shows a GUI file selection pop-up to choose a Python script,
REM then launches the selected script using a portable Python installation.

REM --- Configuration ---
REM Define the relative path to your portable Python executable.
REM Adjust 'PortablePython\python.exe' if your portable Python structure differs.
set "PYTHON_EXE_REL_PATH=.\PortablePython\python.exe"

REM --- Script Logic ---

REM Get the directory where this batch script is located.
REM %~dp0 expands to the drive letter and path of the batch script.
set "SCRIPT_DIR=%~dp0"

REM Construct the full path to the portable Python executable.
set "FULL_PYTHON_PATH=%SCRIPT_DIR%%PYTHON_EXE_REL_PATH%"

REM --- Validation Check for Portable Python ---
if not exist "%FULL_PYTHON_PATH%" (
    echo Error: Portable Python interpreter not found!
    echo Expected path: "%FULL_PYTHON_PATH%"
    echo Please ensure the 'PortablePython' folder contains 'python.exe'
    echo and is located in the same directory as this batch script.
    pause
    exit /b 1
)

echo.
echo Opening file selection dialog...
echo.

REM --- PowerShell Script for File Selection Dialog ---
REM This inline PowerShell script will create and display an "Open File" dialog.
REM It filters for Python (.py) files but also allows all files.
REM The selected file path is written to the console, which the batch script then captures.
for /f "delims=" %%I in ('powershell.exe -NoProfile -Command ^
    "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null;" ^
    "$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog;" ^
    "$OpenFileDialog.InitialDirectory = '%SCRIPT_DIR%'; " ^
    "$OpenFileDialog.Filter = 'Python Scripts (*.py)|*.py|All Files (*.*)|*.*';" ^
    "$OpenFileDialog.Title = 'Select a Python Script to Run';" ^
    "if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {" ^
        "$OpenFileDialog.FileName" ^
    "} else { \"\" }"') do set "SELECTED_FILE=%%I"

REM --- Process User's Selection ---
if "%SELECTED_FILE%"=="" (
    echo.
    echo No file selected or dialog cancelled. Exiting.
    echo.
    pause
    exit /b 0
)

REM --- Validate Selected File Exists ---
if not exist "%SELECTED_FILE%" (
    echo.
    echo Error: The selected file does not exist: "%SELECTED_FILE%"
    echo.
    pause
    exit /b 1
)

echo.
echo Selected file: "%SELECTED_FILE%"
echo.
echo Launching script...

REM --- Launch the Python Script in a New Window ---
REM The 'start' command opens a new console window.
REM The first "" is an empty window title for the new console.
REM "%FULL_PYTHON_PATH%"    : The full path to the portable Python interpreter.
REM "%SELECTED_FILE%"       : The full path to the Python script selected by the user.
REM %* : Passes any arguments given to this batch script directly to the Python script.
start "" "%FULL_PYTHON_PATH%" "%SELECTED_FILE%" %*

echo.
echo Script launch command sent.
echo.

REM Optional: Keep the batch script's own console window open until a key is pressed.
REM This is useful if you double-click the .bat file and want to see its output.
REM If you run it from an existing cmd window, this pause won't affect that window.
pause

REM Exit the batch script's console window.
exit /b 0
