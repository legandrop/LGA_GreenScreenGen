@echo off
setlocal enabledelayedexpansion

rem Cambiar directorio a la carpeta donde se encuentra el archivo .bat
cd /d "%~dp0"

rem Definir el nombre base del archivo zip
set "ZIPNAME=GreenScreenGen"

rem Inicializar el número de versión máximo
set "maxver=0"
set "version_exists=false"

rem Buscar archivos que coincidan con el patrón ZIPNAME_v*.zip
for %%F in ("%ZIPNAME%_v*.zip") do (
    set "version_exists=true"
    set "verstr=%%~nF"
    set "verstr=!verstr:%ZIPNAME%_v=!"
    for /f "tokens=1 delims=_" %%G in ("!verstr!") do (
        set "ver=%%G"
        set "vernum=!ver:.=!"
        if !vernum! GTR !maxver! (
            set "maxver=!vernum!"
        )
    )
)

rem Calcular el nuevo número de versión
if "!version_exists!"=="false" (
    set "newver=1.0"
) else (
    set /a newvernum=maxver+1
    set /a newverint=newvernum / 10
    set /a newverdec=newvernum %% 10
    set "newver=!newverint!.!newverdec!"
)

rem Definir el nombre completo del nuevo archivo zip
set "NEWZIPNAME=%ZIPNAME%_v!newver!.zip"

rem Crear el archivo zip con las exclusiones especificadas
"C:\Program Files\7-Zip\7z.exe" a -tzip "!NEWZIPNAME!" * -xr@.exclude.lst

echo Se ha creado el archivo !NEWZIPNAME!

rem Pausar el script para ver cualquier mensaje de error
pause

endlocal
