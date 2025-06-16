@echo off
REM This batch script launches a new instance of the Command Prompt (cmd.exe).

REM The 'start' command is used to launch programs or commands in a new window.
REM /B     : Starts application without creating a new window. (Not used here)
REM ""     : The first quoted string is the title for the new window. It's empty here.
REM cmd.exe: The executable to launch.
start "" cmd.exe

REM Optionally, you can add a pause if you want the launcher's own console window
REM (if you run it by double-clicking) to stay open briefly before closing.
REM If you run it from an existing cmd window, this line won't affect that window.
REM pause

REM The script will exit immediately after launching cmd.exe.
exit
