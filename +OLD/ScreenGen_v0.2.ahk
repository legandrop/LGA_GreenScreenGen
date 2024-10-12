; Script de AutoHotkey para generar Verde.jpg con resolución seleccionada

#NoEnv  ; Recomendado para mejorar el rendimiento y la compatibilidad
SendMode Input  ; Recomienda usar el modo de envío de entradas más rápido
SetWorkingDir %A_ScriptDir%  ; Establece el directorio de trabajo al directorio del script
#SingleInstance, Force  ; Evita múltiples instancias del script

; Ruta al archivo .ini con las resoluciones
iniFilePath := A_ScriptDir . "\ScreenGenResolutions.ini"

; Leer todas las resoluciones del archivo .ini
resolutionsList := ""
Loop, Read, %iniFilePath%
{
    ; Saltar líneas en blanco o que no contienen un '='
    If (InStr(A_LoopReadLine, "="))
    {
        StringSplit, resArray, A_LoopReadLine, =
        ; resArray1 será el nombre (HD_1080_16_9), resArray2 será la resolución (1920x1080)
        resolutionsList .= resArray1 . "|"  ; Añade el nombre al ComboBox
    }
}

; Crear la interfaz gráfica
Gui, Add, Text, x20 y20 w200 h20, Selecciona la resolución:
Gui, Add, ComboBox, vSelectedResolution x20 y50 w200 h150, %resolutionsList%
Gui, Add, Button, gGenerateImage x240 y50 w80 h30, OK

Gui, Show, w340 h100, Generador de Verde.jpg
return

; Función que se ejecuta al hacer clic en el botón OK
GenerateImage:
    ; Obtener la resolución seleccionada
    Gui, Submit, NoHide
    resolutionName := SelectedResolution

    if (resolutionName = "")
    {
        MsgBox, 48, Error, Por favor, selecciona una resolución.
        return
    }

    ; Leer la resolución desde el archivo .ini según el nombre seleccionado
    IniRead, resolution, %iniFilePath%, Resolutions, %resolutionName%

    ; Dividir la resolución en ancho y alto
    StringSplit, resArray, resolution, x
    width := resArray1
    height := resArray2

    ; Definir rutas
    scriptDir := A_ScriptDir
    ffmpegDir := scriptDir . "\FFmpeg"
    ffmpegPath := ffmpegDir . "\ffmpeg.exe"
    
    ; Verificar si FFmpeg existe
    if !FileExist(ffmpegPath)
    {
        MsgBox, 16, Error, No se encontró ffmpeg.exe en la carpeta FFmpeg.
        return
    }

    ; Definir el nombre de la carpeta con el nombre y la resolución
    folderName := resolutionName . "_" . resolution
    outputDir := scriptDir . "\" . folderName

    ; Crear la carpeta si no existe
    if !FileExist(outputDir)
    {
        FileCreateDir, %outputDir%
    }

    ; Definir el nombre del archivo de salida
    outputFile := outputDir . "\Verde.jpg"

    ; Comprobar si Verde.jpg ya existe
    if FileExist(outputFile)
    {
        MsgBox, 36, Confirmación, El archivo Verde.jpg ya existe en %folderName%. ¿Deseas sobrescribirlo?
        IfMsgBox, No
            return
    }

    ; Definir ruta para los archivos de log
    errorLog := outputDir . "\error.log"
    outputLog := outputDir . "\output.log"

    ; Construir el comando FFmpeg con la bandera -y para sobrescribir sin preguntar
    ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=green:s=" . width . "x" . height . " -frames:v 1 -update 1 """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"

    ; Crear un archivo de lote temporal para ejecutar el comando
    tempBatch := A_Temp "\run_ffmpeg.bat"
    FileDelete, %tempBatch%  ; Asegura que el archivo no exista
    FileAppend, %ffmpegCommand%`nexit, %tempBatch%  ; Añade 'exit' para cerrar cmd después de ejecutar

    ; Ejecutar el archivo de lote de manera oculta y esperar a que termine
    RunWait, %tempBatch%, , Hide

    ; Verificar si el archivo se creó correctamente
    if FileExist(outputFile)
    {
        MsgBox, 64, Éxito, Verde.jpg ha sido generado en la carpeta %folderName%.
        
        ; Eliminar archivos de log si no hubo errores
        if FileExist(errorLog)
        {
            FileDelete, %errorLog%
        }
        if FileExist(outputLog)
        {
            FileDelete, %outputLog%
        }
    }
    else
    {
        ; Leer el contenido del archivo de error
        if FileExist(errorLog)
        {
            FileRead, ffmpegError, %errorLog%
            if (ffmpegError = "")
            {
                MsgBox, 16, Error, Hubo un problema al generar Verde.jpg, pero no se encontraron detalles de error.
            }
            else
            {
                MsgBox, 16, Error, Hubo un problema al generar Verde.jpg.`n`nDetalles del Error:`n%ffmpegError%
            }
        }
        else
        {
            MsgBox, 16, Error, Hubo un problema al generar Verde.jpg, y no se pudo encontrar el archivo de registro de errores.
        }

        ; Mostrar la salida estándar de FFmpeg si existió
        if FileExist(outputLog)
        {
            FileRead, ffmpegOutput, %outputLog%
            if (ffmpegOutput != "")
            {
                MsgBox, 48, Salida de FFmpeg, Detalles de la salida:`n%ffmpegOutput%
            }
            FileDelete, %outputLog%
        }
    }

    ; Eliminar el archivo de lote temporal
    FileDelete, %tempBatch%
return

; Cerrar la ventana al presionar Esc o cerrar la ventana
GuiClose:
    ExitApp

GuiEscape:
    ExitApp
