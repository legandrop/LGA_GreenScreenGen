@echo off
rem Change directory to the desired folder
cd /d "C:\Portable\LGA_GreenScreenGen"

rem Check if the .zip file exists and delete it if it does
if exist GreenScreenGen.zip (
    del GreenScreenGen.zip
)

rem Create the zip file with exclusions from the specified folder
"C:\Program Files\7-Zip\7z.exe" a -tzip GreenScreenGen.zip * -xr@.exclude.lst

rem Pause the script to see any error messages
pause
