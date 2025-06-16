@echo off
REM This batch script launches a new instance of the Command Prompt (cmd.exe).

start "" cmd.exe

REM Optionally, you can add a pause if you want the launcher's own console window
REM (if you run it by double-clicking) to stay open briefly before closing.
REM If you run it from an existing cmd window, this line won't affect that window.
REM pause

REM exit after launching cmd.exe.
exit
