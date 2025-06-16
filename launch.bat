@echo off
REM This batch script launches a Python script using a portable Python installation.

REM --- Configuration ---
REM Define the relative path to your portable Python executable.
REM Adjust 'PortablePython\python.exe' if your portable Python structure differs.
set "PYTHON_EXE_REL_PATH=.\PortablePython\python.exe"

REM Define the relative path to your Python script.
REM Adjust 'my_script.py' if your script has a different name or location.
set "PYTHON_SCRIPT_REL_PATH=.\my_script.py"

REM --- Script Logic ---

REM Get the directory where this batch script is located.
REM %~dp0 expands to the drive letter and path of the batch script.
set "SCRIPT_DIR=%~dp0"

REM Construct the full path to the portable Python executable.
set "FULL_PYTHON_PATH=%SCRIPT_DIR%%PYTHON_EXE_REL_PATH%"

REM Construct the full path to the Python script.
set "FULL_SCRIPT_PATH=%SCRIPT_DIR%%PYTHON_SCRIPT_REL_PATH%"

REM Optional: Create a dummy Python script for testing if it doesn't exist.
REM This is just to make the example runnable out-of-the-box.
if not exist "%FULL_SCRIPT_PATH%" (
    echo.import time > "%FULL_SCRIPT_PATH%"
    echo.print("Hello from Portable Python script!") >> "%FULL_SCRIPT_PATH%"
    echo.print("This window will close in 5 seconds...") >> "%FULL_SCRIPT_PATH%"
    echo.time.sleep(5) >> "%FULL_SCRIPT_PATH%"
)

REM --- Validation Checks ---
if not exist "%FULL_PYTHON_PATH%" (
    echo Error: Portable Python executable not found at "%FULL_PYTHON_PATH%"
    echo Please ensure the 'PortablePython' folder and 'python.exe' are in the correct place.
    pause
    exit /b 1
)

if not exist "%FULL_SCRIPT_PATH%" (
    echo Error: Python script not found at "%FULL_SCRIPT_PATH%"
    pause
    exit /b 1
)

echo.
echo Launching Python script: "%FULL_SCRIPT_PATH%"
echo Using Python interpreter: "%FULL_PYTHON_PATH%"
echo.

REM Use 'start' to launch the Python script in a new console window.
REM The first "" is for the window title (empty in this case).
REM "%FULL_PYTHON_PATH%"    : The path to the Python interpreter.
REM "%FULL_SCRIPT_PATH%"    : The path to your Python script (passed as an argument to python.exe).
REM %* : Passes any arguments given to this batch script directly to the Python script.
start "" "%FULL_PYTHON_PATH%" "%FULL_SCRIPT_PATH%" %*

echo Python script launch command sent.
REM Optional: Keep the batch script's own window open until a key is pressed.
REM This is useful if you double-click the .bat file and want to see its own output.
REM If you run it from an existing cmd window, this pause won't affect that window.
pause

REM Exit the batch script's console window.
exit /b 0
