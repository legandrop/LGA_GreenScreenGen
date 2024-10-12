#Requires AutoHotkey v1.1
#NoEnv  ; Recomendado para mejorar el rendimiento y la compatibilidad
SendMode Input  ; Recomienda usar el modo de envío de entradas más rápido
SetWorkingDir %A_ScriptDir%  ; Establece el directorio de trabajo al directorio del script
#SingleInstance, Force  ; Evita múltiples instancias del script
FileEncoding, UTF-8-RAW  ; Asegura que los archivos se escriban en UTF-8 sin BOM

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
iniFilePath := A_ScriptDir . "\resources\ScreenGenResolutions.ini"

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

; Crear la interfaz gráfica principal
Gui, Main:New, +LabelMainGui
Gui, Main:Add, Text, x20 y20 w200 h20, Selecciona la resolución:
Gui, Main:Add, ComboBox, vSelectedResolution x20 y50 w200 h150, %resolutionsList%
Gui, Main:Add, Button, gGenerateImages x240 y50 w80 h30, OK

; Crear la interfaz gráfica de progreso (inicialmente oculta)
Gui, Progress:New, +LabelProgressGui
Gui, Progress:Add, Text, vProgressText x20 y20 w300 h20, Iniciando generación de imágenes...
Gui, Progress:Add, Progress, vProgressBar x20 y50 w300 h20 Range0-100, 0

; Mostrar la interfaz principal
Gui, Main:Show, w340 h100, GreenScreenGen
return

; Función que se ejecuta al hacer clic en el botón OK
GenerateImages:
    Gui, Main:Submit, NoHide
    resolutionDisplay := SelectedResolution

    if (resolutionDisplay = "")
    {
        MsgBox, 48, Error, Por favor, selecciona una resolución.
        return
    }

    ; Ocultar la interfaz principal y mostrar la de progreso
    Gui, Main:Hide
    Gui, Progress:Show, w340 h100, GreenScreenGen - Generando Imágenes

    ; Inicializar la confirmación de sobrescritura
    overwriteConfirmed := false

    ; Separar el nombre y la resolución
    StringSplit, resolutionParts, resolutionDisplay, -  ; Dividir por " - "
    resolutionName := Trim(resolutionParts1)  ; Nombre de la resolución (ej: HD_1080_16_9)
    resolution := Trim(resolutionParts2)  ; Resolución (ej: 1920x1080)

    ; Dividir la resolución en ancho y alto
    StringSplit, resArray, resolution, x
    width := resArray1
    height := resArray2

    ; Calcular la diagonal de referencia (HD)
    diagonalReferencia := Sqrt(1920*1920 + 1080*1080)

    ; Calcular la diagonal de la resolución actual
    diagonalActual := Sqrt(width*width + height*height)

    ; Calcular el factor de escala
    factorEscala := diagonalActual / diagonalReferencia

    ; Definir rutas
    scriptDir := A_ScriptDir
    resourcesDir := scriptDir . "\resources"
    ffmpegDir := resourcesDir . "\FFmpeg"
    ffmpegPath := ffmpegDir . "\ffmpeg.exe"
    logsDir := resourcesDir . "\logs"
    exportsDir := scriptDir . "\Exports"

    ; Crear la carpeta de logs si no existe
    if !FileExist(logsDir) {
        FileCreateDir, %logsDir%
    }

    ; Verificar si FFmpeg existe
    if !FileExist(ffmpegPath)
    {
        MsgBox, 16, Error, No se encontró ffmpeg.exe en la carpeta FFmpeg.
        return
    }

    ; Crear la carpeta de exports si no existe
    if !FileExist(exportsDir) {
        FileCreateDir, %exportsDir%
    }

    ; Definir el nombre de la carpeta con el nombre y la resolución
    folderName := resolutionName . "_" . resolution
    outputDir := exportsDir . "\" . folderName ; Cambiado para usar la carpeta Exports

    ; Crear la carpeta si no existe
    if !FileExist(outputDir)
    {
        FileCreateDir, %outputDir%
    }

    ; Definir los nombres de las carpetas para Margin1 y Margin2
    outputDirMargin1 := exportsDir . "\" . folderName . "-Margin1"
    outputDirMargin2 := exportsDir . "\" . folderName . "-Margin2"

    ; Crear las carpetas si no existen
    if !FileExist(outputDirMargin1)
    {
        FileCreateDir, %outputDirMargin1%
    }
    if !FileExist(outputDirMargin2)
    {
        FileCreateDir, %outputDirMargin2%
    }

    ; **Archivo de prueba de caracteres especiales**
    commandsLog := logsDir . "\ffmpeg_commands.txt" ; Cambiado para usar la carpeta de logs

    ; Definir los tipos de imágenes a generar
    imageNames := ["Verde_100", "Verde_50", "Verde_25", "Verde_100_Track_4", "Verde_50_Track_4", "Verde_25_Track_4", "Verde_100_Track_5", "Verde_50_Track_5", "Verde_25_Track_5", "Verde_100_Track_9", "Verde_50_Track_9", "Verde_25_Track_9", "Azul_100", "Azul_50", "Azul_25", "Azul_100_Track_4", "Azul_50_Track_4", "Azul_25_Track_4", "Azul_100_Track_5", "Azul_50_Track_5", "Azul_25_Track_5", "Azul_100_Track_9", "Azul_50_Track_9", "Azul_25_Track_9", "Gris", "Gris_Track_4", "Gris_Track_5", "Gris_Track_9"]

    imageColors := ["#00FF00", "#008000", "#003C00", "#00FF00", "#008000", "#003C00", "#00FF00", "#008000", "#003C00", "#00FF00", "#008000", "#003C00", "#0000FF", "#000080", "#00003C", "#0000FF", "#000080", "#00003C", "#0000FF", "#000080", "#00003C", "#0000FF", "#000080", "#00003C", "#808080", "#808080", "#808080", "#808080"]

    imageTracking := [false, false, false, true, true, true, true, true, true, true, true, true, false, false, false, true, true, true, true, true, true, true, true, true, false, true, true, true]

    trackColors := ["#008000", "#003C00", "#008000", "#008000", "#003C00", "#008000", "#008000", "#003C00", "#008000", "#008000", "#003C00", "#008000", "#000080", "#00003C", "#000080", "#000080", "#00003C", "#000080", "#000080", "#00003C", "#000080", "#000080", "#00003C", "#000080", "#003C00", "#003C00", "#003C00", "#003C00"]

    ; Definir el color azul para los puntos de track alternativos (para imágenes verdes y grises)
    blueTrackColor := "#000080"

    ; Definir el color verde para los puntos de track alternativos
    greenTrackColor := "#008000"

    ; Definir variables para el tamaño y posición de los puntos
    fontSizeBase := Round(Min(1920, 1080) * 0.08)  ; 8% del lado más pequeño de HD
    fontSize := Round(fontSizeBase * factorEscala)  ; Escalar el tamaño de la fuente
    margin := Round(fontSize * 0.5)  ; Margen es la mitad del tamaño de la fuente

    ; Definir el carácter de círculo directamente
    circleChar := "●"  ; Unicode U+25CF

    ; Calcular el número total de imágenes a generar
    totalImages := imageNames.Length()
    currentImage := 0

    ; Loop para generar cada imagen
    Loop, % totalImages
    {
        idx := A_Index
        imageName := imageNames[idx]
        imageColor := imageColors[idx]
        hasTracking := imageTracking[idx]
        trackColor := trackColors[idx]

        ; Actualizar el texto de progreso
        currentImage++
        progressText := "Generando: " . imageName . " (" . currentImage . "/" . totalImages . ")"
        GuiControl, Progress:, ProgressText, %progressText%
        GuiControl, Progress:, ProgressBar, % (currentImage / totalImages) * 100

        ; Si la imagen tiene tracking, generar versiones con puntos de colores
        if (hasTracking)
        {
            ; Calcular el margen fijo basado en el Size 2
            fixedMargin := Round(fontSize * 0.5)

            ; Array para almacenar los colores de track
            if (InStr(imageName, "Verde") || InStr(imageName, "Gris"))
            {
                trackColorArray := [trackColor, blueTrackColor]
                colorSuffixArray := ["-G", "-B"]
            }
            else if (InStr(imageName, "Azul"))
            {
                if (InStr(imageName, "Azul_100"))
                    trackColorArray := ["#000080", greenTrackColor]  ; Azul 50% y Verde 50%
                else if (InStr(imageName, "Azul_50"))
                    trackColorArray := ["#00003C", greenTrackColor]  ; Azul 25% y Verde 50%
                else if (InStr(imageName, "Azul_25"))
                    trackColorArray := ["#000080", greenTrackColor]  ; Azul 50% y Verde 50%
                colorSuffixArray := ["-B", "-G"]
            }

            ; Loop para generar versiones con puntos de diferentes colores
            Loop, 2
            {
                currentTrackColor := trackColorArray[A_Index]
                colorSuffix := colorSuffixArray[A_Index]

                Loop, 2
                {
                    marginIdx := A_Index
                    currentMargin := fixedMargin * (marginIdx == 1 ? 1 : 3)
                    currentOutputDir := marginIdx == 1 ? outputDirMargin1 : outputDirMargin2

                    Loop, 3
                    {
                        sizeIdx := A_Index
                        currentFontSize := fontSize * (sizeIdx == 1 ? 0.5 : (sizeIdx == 2 ? 1 : 2))
                        
                        ; Extraer la cantidad de puntos de track del nombre de la imagen
                        trackCount := RegExReplace(imageName, ".*Track_(\d+).*", "$1")

                        ; Definir el nombre del archivo de salida con el nuevo orden
                        outputFile := currentOutputDir . "\" . RegExReplace(imageName, "_Track_\d+", "_Track") . "-" . trackCount . "-Size" . sizeIdx . colorSuffix . ".jpg"

                        ; Definir ruta para los archivos de log con el nuevo orden de nombres
                        errorLog := logsDir . "\" . RegExReplace(imageName, "_Track_\d+", "_Track") . "-Margin" . marginIdx . "-" . trackCount . "-Size" . sizeIdx . colorSuffix . "_error.log"
                        outputLog := logsDir . "\" . RegExReplace(imageName, "_Track_\d+", "_Track") . "-Margin" . marginIdx . "-" . trackCount . "-Size" . sizeIdx . colorSuffix . "_output.log"

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

                        ; Añadir los comandos drawtext para los puntos de track
                        filter := ""
                        ; Esquina superior izquierda
                        filter .= "drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=" . currentMargin . ":y=" . currentMargin
                        ; Esquina superior derecha
                        filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=" . (width - currentMargin) . "-tw:y=" . currentMargin
                        ; Esquina inferior izquierda
                        filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=" . currentMargin . ":y=" . (height - currentMargin) . "-th"
                        ; Esquina inferior derecha
                        filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=" . (width - currentMargin) . "-tw:y=" . (height - currentMargin) . "-th"
                        
                        ; Añadir puntos adicionales para imágenes con 5 o 9 puntos de track
                        if (InStr(imageName, "Track_5") || InStr(imageName, "Track_9"))
                        {
                            ; Centro
                            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=(w-tw)/2:y=(h-th)/2"
                        }
                        
                        ; Añadir puntos adicionales solo para imágenes con 9 puntos de track
                        if (InStr(imageName, "Track_9"))
                        {
                            ; Arriba centro
                            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=(w-tw)/2:y=" . currentMargin
                            ; Izquierda centro
                            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=" . currentMargin . ":y=(h-th)/2"
                            ; Derecha centro
                            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=" . (width - currentMargin) . "-tw:y=(h-th)/2"
                            ; Abajo centro
                            filter .= ",drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text='" . circleChar . "':fontcolor=" . currentTrackColor . ":fontsize=" . currentFontSize . ":x=(w-tw)/2:y=" . (height - currentMargin) . "-th"
                        }

                        ; Construir el comando FFmpeg con el filtro
                        ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=" . imageColor . ":s=" . width . "x" . height . " -vf """ . filter . """ -update 1 -frames:v 1 -f image2 """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"

                        ; **Añadir el comando FFmpeg al archivo de registro**
                        FileAppend, %ffmpegCommand%`n, %commandsLog%

                        ; **Añadir el comando a un archivo de depuración**
                        FileAppend, %ffmpegCommand%`n, %logsDir%\ffmpeg_debug.txt

                        ; Crear un archivo de lote temporal para ejecutar el comando
                        tempBatch := A_Temp "\run_ffmpeg_" . idx . ".bat"
                        FileDelete, %tempBatch%  ; Asegura que el archivo no exista

                        ; **Añadir 'chcp 65001' al inicio del archivo de lote para establecer la página de código a UTF-8**
                        FileAppend, % "chcp 65001`n" . ffmpegCommand . "`nexit", %tempBatch%, UTF-8-RAW  ; Añade 'exit' para cerrar cmd después de ejecutar

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
                }
            }
        }
        else
        {
            ; Para imágenes sin tracking, generar una vez en cada carpeta
            Loop, 2
            {
                marginIdx := A_Index
                currentOutputDir := marginIdx == 1 ? outputDirMargin1 : outputDirMargin2
                outputFile := currentOutputDir . "\" . imageName . ".jpg"
                
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
                errorLog := logsDir . "\" . imageName . "_error.log"
                outputLog := logsDir . "\" . imageName . "_output.log"

                ; Construir el comando FFmpeg sin el filtro
                ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=" . imageColor . ":s=" . width . "x" . height . " -update 1 -frames:v 1 -f image2 """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"

                ; **Añadir el comando FFmpeg al archivo de registro**
                FileAppend, %ffmpegCommand%`n, %commandsLog%

                ; **Añadir el comando a un archivo de depuración**
                FileAppend, %ffmpegCommand%`n, %logsDir%\ffmpeg_debug.txt

                ; Crear un archivo de lote temporal para ejecutar el comando
                tempBatch := A_Temp "\run_ffmpeg_" . idx . ".bat"
                FileDelete, %tempBatch%  ; Asegura que el archivo no exista

                ; **Añadir 'chcp 65001' al inicio del archivo de lote para establecer la página de código a UTF-8**
                FileAppend, % "chcp 65001`n" . ffmpegCommand . "`nexit", %tempBatch%, UTF-8-RAW  ; Añade 'exit' para cerrar cmd después de ejecutar

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
        }
    }

    ; Mostrar mensaje de finalización
    MsgBox, 64, Éxito, Todas las imágenes han sido generadas correctamente en las carpetas:`n%folderName%-Margin1`n%folderName%-Margin2

    ; Ocultar la interfaz de progreso y mostrar la principal
    Gui, Progress:Hide
    Gui, Main:Show
return

; Manejadores de eventos para cerrar las ventanas
MainGuiClose:
MainGuiEscape:
    ExitApp

ProgressGuiClose:
ProgressGuiEscape:
    ; No hacer nada, evitar que el usuario cierre la ventana de progreso
return