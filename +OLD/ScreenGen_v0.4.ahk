#Requires AutoHotkey v1.1
#NoEnv  ; Recomendado para mejorar el rendimiento y la compatibilidad
SendMode Input  ; Recomienda usar el modo de envío de entradas más rápido
SetWorkingDir %A_ScriptDir%  ; Establece el directorio de trabajo al directorio del script
#SingleInstance, Force  ; Evita múltiples instancias del script
FileEncoding, UTF-8-RAW

; Función para escapar caracteres en la línea de comandos
EscapeForCmd(str) {
    str := StrReplace(str, "&", "^&")
    str := StrReplace(str, "<", "^<")
    str := StrReplace(str, ">", "^>")
    str := StrReplace(str, "|", "^|")
    str := StrReplace(str, "%", "%%")
    str := StrReplace(str, "^", "^^")
    str := StrReplace(str, """", "\""")
    return str
}

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
        resolutionDisplay := resArray1 . " - " . resArray2  ; Combinar el nombre y la resolución
        resolutionsList .= resolutionDisplay . "|"  ; Añadir al ComboBox
    }
}

; Crear la interfaz gráfica
Gui, Add, Text, x20 y20 w200 h20, Selecciona la resolución:
Gui, Add, ComboBox, vSelectedResolution x20 y50 w200 h150, %resolutionsList%
Gui, Add, Button, gGenerateImages x240 y50 w80 h30, OK

Gui, Show, w340 h100, Generador de Imágenes
return

; Función que se ejecuta al hacer clic en el botón OK
GenerateImages:
    ; Inicializar la confirmación de sobrescritura
    overwriteConfirmed := false

    ; Obtener la resolución seleccionada
    Gui, Submit, NoHide
    resolutionDisplay := SelectedResolution

    if (resolutionDisplay = "")
    {
        MsgBox, 48, Error, Por favor, selecciona una resolución.
        return
    }

    ; Separar el nombre y la resolución
    StringSplit, resolutionParts, resolutionDisplay, -  ; Dividir por " - "
    resolutionName := Trim(resolutionParts1)  ; Nombre de la resolución (ej: HD_1080_16_9)
    resolution := Trim(resolutionParts2)  ; Resolución (ej: 1920x1080)

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

    ; **Archivo de prueba de caracteres especiales**
    commandsLog := outputDir . "\ffmpeg_commands.txt"
    FileAppend, % "Prueba de caracteres: á, é, í, ó, ú, ñ, ¿, ¡, " . Chr(9679), %commandsLog%`n

    ; Definir los tipos de imágenes a generar
    imageNames := ["Verde_100", "Verde_50", "Verde_25", "Verde_Track_5_100", "Gris", "Gris_Track_5"]
    imageColors := ["#00FF00", "#008000", "#003C00", "#00FF00", "#808080", "#808080"]
    imageTracking := [false, false, false, true, false, true]
    trackColor := "#003C00"  ; Color para los puntos de track

    ; Definir variables para el tamaño y posición de los puntos
    fontSize := Round(Min(width, height) * 0.08)  ; 8% del lado más pequeño
    margin := Round(fontSize * 0.5)  ; Margen es la mitad del tamaño de la fuente

    ; Definir el carácter de círculo directamente
    circleChar := "●"  ; Unicode U+25CF

    ; Loop para generar cada imagen
    Loop, % imageNames.MaxIndex()
    {
        idx := A_Index
        imageName := imageNames[idx]
        imageColor := imageColors[idx]
        hasTracking := imageTracking[idx]

        ; Definir el nombre del archivo de salida
        outputFile := outputDir . "\" . imageName . ".jpg"

        ; Comprobar si el archivo ya existe
        if FileExist(outputFile)
        {
            ; Preguntar una sola vez si deseas sobrescribir todos los archivos
            if (!overwriteConfirmed)
            {
                MsgBox, 36, Confirmación, Algunos archivos ya existen. ¿Deseas sobrescribir todos los archivos existentes?
                IfMsgBox, No
                    return
                overwriteConfirmed := true
            }
        }

        ; Definir ruta para los archivos de log
        errorLog := outputDir . "\" . imageName . "_error.log"
        outputLog := outputDir . "\" . imageName . "_output.log"

        ; Construir el comando FFmpeg
        ; **Cambios realizados aquí:**
        ; 1. Añadido -update 1
        ; 2. Reordenado -update 1 antes de -frames:v 1
        ; 3. Añadido -f image2 para especificar el formato de salida
        ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=" . imageColor . ":s=" . width . "x" . height . " -update 1 -frames:v 1 -f image2 """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"

        ; Si tiene tracking, añadir filtros
        if (hasTracking)
        {
            ; Añadir los comandos drawtext para los puntos de track usando el carácter Unicode directamente
            filter := ""
            ; Esquina superior izquierda
            filter .= "drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . trackColor . ":fontsize=" . fontSize . ":x=" . margin . ":y=" . margin
            ; Esquina superior derecha
            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . trackColor . ":fontsize=" . fontSize . ":x=" . (width - margin) . "-tw:y=" . margin
            ; Esquina inferior izquierda
            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . trackColor . ":fontsize=" . fontSize . ":x=" . margin . ":y=" . (height - margin) . "-th"
            ; Esquina inferior derecha
            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . trackColor . ":fontsize=" . fontSize . ":x=" . (width - margin) . "-tw:y=" . (height - margin) . "-th"
            ; Centro
            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . trackColor . ":fontsize=" . fontSize . ":x=(w-tw)/2:y=(h-th)/2"

            ; Añadir la opción de filtro al comando FFmpeg
            ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=" . imageColor . ":s=" . width . "x" . height . " -update 1 -frames:v 1 -f image2 -vf """ . filter . """ """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"
        }

        ; **Añadir el comando FFmpeg al archivo de registro**
        FileAppend, %ffmpegCommand%`n, %commandsLog%

        ; **Añadir el comando a un archivo de depuración**
        FileAppend, %ffmpegCommand%`n, %A_ScriptDir%\ffmpeg_debug.txt

        ; Mostrar el comando para depuración (opcional, puedes comentar esta línea después de verificar)
        ; MsgBox, % "Ejecutando comando:`n" . ffmpegCommand

        ; Crear un archivo de lote temporal para ejecutar el comando
        tempBatch := A_Temp "\run_ffmpeg_" . idx . ".bat"
        FileDelete, %tempBatch%  ; Asegura que el archivo no exista
        FileAppend, %ffmpegCommand%`nexit, %tempBatch%, UTF-8-RAW  ; Añade 'exit' para cerrar cmd después de ejecutar

        ; Ejecutar el archivo de lote de manera oculta y esperar a que termine
        RunWait, %tempBatch%, , Hide

        ; Verificar si el archivo se creó correctamente
        if FileExist(outputFile)
        {
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
                    MsgBox, 16, Error, Hubo un problema al generar %imageName%.jpg, pero no se encontraron detalles de error.
                }
                else
                {
                    MsgBox, 16, Error, Hubo un problema al generar %imageName%.jpg.`n`nDetalles del Error:`n%ffmpegError%
                }
            }
            else
            {
                MsgBox, 16, Error, Hubo un problema al generar %imageName%.jpg, y no se pudo encontrar el archivo de registro de errores.
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
    }

    ; Notificar al usuario que todas las imágenes se han generado
    MsgBox, 64, Éxito, Todas las imágenes han sido generadas correctamente en la carpeta %folderName%.
return

; Cerrar la ventana al presionar Esc o cerrar la ventana
GuiClose:
    ExitApp

GuiEscape:
    ExitApp
