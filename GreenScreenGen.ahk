#Requires AutoHotkey v1.1
#NoEnv  ; Recomendado para mejorar el rendimiento y la compatibilidad
SendMode Input  ; Recomienda usar el modo de envío de entradas más rápido
SetWorkingDir %A_ScriptDir%  ; Establece el directorio de trabajo al directorio del script
#SingleInstance, Force  ; Evita múltiples instancias del script
FileEncoding, UTF-8-RAW  ; Asegura que los archivos se escriban en UTF-8 sin BOM

; Variables globales
global isCancelled := false
global showCompletionMessages := true

; Definir la variable del tooltip
versionTooltip := "Lega | 2024 | www.wanka.tv"

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
; Eliminar el último carácter |
resolutionsList := RTrim(resolutionsList, "|")

; Crear la interfaz gráfica principal
Gui, Main:New, +LabelMainGui
Gui, Main:Add, Text, x20 y30 w200 h20, Select resolution:
Gui, Main:Add, ComboBox, vSelectedResolution x20 y50 w210 h21 r10, %resolutionsList%
Gui, Main:Add, Button, gAddResolution x18 y80 w95 h24, Add Resolution
Gui, Main:Add, Button, gRemoveResolution x122 y80 w110 h24, Remove Resolution
Gui, Main:Add, Button, gGenerateImages x240 y47 w80 h26, Generate
Gui, Main:Add, Button, gGenerateAll x240 y80 w80 h24, Generate All
; Agregar el texto de la versión sin el gLabel
Gui, Main:Add, Text, x310 y130 w40 h20 vVersionText gShowVersionTooltip, v1.1

; Obtener el handle del control VersionText
Gui, Main: +LastFound
GuiControlGet, hVersionText, Hwnd, VersionText

; Crear la interfaz gráfica de progreso (inicialmente oculta)
Gui, Progress:New, +LabelProgressGui
Gui, Progress:Add, Text, vProgressText x20 y20 w300 h20, Starting image generation...
Gui, Progress:Add, Progress, vProgressBar x20 y50 w300 h20 Range0-100, 0
Gui, Progress:Add, Button, gCancelGeneration x130 y80 w80 h30, Cancel

; Mostrar la interfaz principal
Gui, Main:Show, w340 h150, GreenScreenGen

; Agregar estas líneas después de crear la GUI principal
OnMessage(0x200, "WM_MOUSEMOVE")
OnMessage(0x2A3, "WM_MOUSELEAVE")

; Función para manejar el evento de mover el mouse
WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    static hoveredControl := 0
    if (A_GuiControl = "VersionText") {
        if (hoveredControl != hwnd) {
            hoveredControl := hwnd
            SetTimer, ShowVersionTooltip, -1
        }
    } else if (hoveredControl) {
        SetTimer, RemoveToolTip, -1
        hoveredControl := 0
    }
}

; Función para manejar el evento de salir del control con el mouse
WM_MOUSELEAVE(wParam, lParam, msg, hwnd) {
    SetTimer, RemoveToolTip, -1
}

; Función para ocultar el tooltip
HideVersionTooltip:
    ToolTip
return

; Función para mostrar el tooltip de la versión
ShowVersionTooltip:
    ToolTip, %versionTooltip%
    SetTimer, RemoveToolTip, -3000
return

AddResolution:
    Gui, NewRes:New, +LabelNewResGui
    Gui, NewRes:Add, Text, x20 y20 w100 h20, Name:
    Gui, NewRes:Add, Edit, vNewResName x130 y20 w180 h20
    Gui, NewRes:Add, Text, x20 y50 w100 h20, Width (X):
    Gui, NewRes:Add, Edit, vNewResWidth x130 y50 w180 h20 Number
    Gui, NewRes:Add, Text, x20 y80 w100 h20, Height (Y):
    Gui, NewRes:Add, Edit, vNewResHeight x130 y80 w180 h20 Number
    Gui, NewRes:Add, Button, gSaveNewResolution x130 y110 w80 h30, Save
    Gui, NewRes:Add, Button, gCancelNewResolution x220 y110 w80 h30, Cancel
    Gui, NewRes:Show, w330 h150, Add New Resolution
return

RemoveResolution:
    Gui, Main:Submit, NoHide
    if (SelectedResolution != "")
    {
        MsgBox, 4, Confirm Deletion, Are you sure you want to delete the resolution "%SelectedResolution%"?
        IfMsgBox, Yes
        {
            FileRead, content, %iniFilePath%
            ; Separar el nombre y la resolución
            StringSplit, parts, SelectedResolution, -
            resolutionName := Trim(parts1)
            
            ; Crear una expresión regular para buscar la línea completa
            needle := "m)^" . resolutionName . "=.*\R?"
            
            ; Reemplazar la línea encontrada con una cadena vacía
            newContent := RegExReplace(content, needle, "")
            
            ; Eliminar líneas en blanco adicionales que puedan quedar
            newContent := RegExReplace(newContent, "m)^\s*$\R?", "")
            
            ; Escribir el nuevo contenido al archivo
            FileDelete, %iniFilePath%
            FileAppend, %newContent%, %iniFilePath%
            
            ; Recargar el script para actualizar la lista de resoluciones
            Reload
        }
    }
    else
    {
        MsgBox, 48, Error, Please select a resolution to delete.
    }
return

HandleSelection:
    Gui, Main:Submit, NoHide
    if (SelectedResolution = "Add a new resolution")
    {
        Gui, NewRes:New, +LabelNewResGui
        Gui, NewRes:Add, Text, x20 y20 w100 h20, Name:
        Gui, NewRes:Add, Edit, vNewResName x130 y20 w180 h20
        Gui, NewRes:Add, Text, x20 y50 w100 h20, Width (X):
        Gui, NewRes:Add, Edit, vNewResWidth x130 y50 w180 h20 Number
        Gui, NewRes:Add, Text, x20 y80 w100 h20, Height (Y):
        Gui, NewRes:Add, Edit, vNewResHeight x130 y80 w180 h20 Number
        Gui, NewRes:Add, Button, gSaveNewResolution x130 y110 w80 h30, Save
        Gui, NewRes:Add, Button, gCancelNewResolution x220 y110 w80 h30, Cancel
        Gui, NewRes:Show, w330 h150, Add New Resolution
    }
    else
    {
        Gosub, GenerateImages
    }
return

SaveNewResolution:
    Gui, NewRes:Submit
    if (NewResName != "" && NewResWidth > 0 && NewResHeight > 0)
    {
        newEntry := NewResName . "=" . NewResWidth . "x" . NewResHeight
        FileAppend, %newEntry%`n, %iniFilePath%
        Gui, NewRes:Destroy
        Reload
    }
    else
    {
        MsgBox, 48, Error, Please fill in all fields correctly.
    }
return

CancelNewResolution:
    Gui, NewRes:Destroy
return

GenerateImages:
    Gui, Main:Submit, NoHide
    resolutionDisplay := SelectedResolution

    if (resolutionDisplay = "")
    {
        if (A_ThisLabel != "GenerateAll")
            MsgBox, 48, Error, Please select a resolution.
        return
    }

    ; Ocultar la interfaz principal y mostrar la de progreso
    Gui, Main:Hide
    Gui, Progress:Show, w340 h120, GreenScreenGen - Generating Images for %resolutionDisplay%

    ; Reiniciar la variable de cancelación
    isCancelled := false

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
        MsgBox, 16, Error, ffmpeg.exe was not found in the FFmpeg folder.
        return
    }

    ; Crear la carpeta de exports si no existe
    if !FileExist(exportsDir) {
        FileCreateDir, %exportsDir%
    }

    ; Definir el nombre de la carpeta con el nombre y la resolución
    folderName := resolutionName . "_" . resolution

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
    imageNames := ["Green_100", "Green_50", "Green_25", "Green_100_Track_4", "Green_50_Track_4", "Green_25_Track_4", "Green_100_Track_5", "Green_50_Track_5", "Green_25_Track_5", "Green_100_Track_9", "Green_50_Track_9", "Green_25_Track_9", "Blue_100", "Blue_50", "Blue_25", "Blue_100_Track_4", "Blue_50_Track_4", "Blue_25_Track_4", "Blue_100_Track_5", "Blue_50_Track_5", "Blue_25_Track_5", "Blue_100_Track_9", "Blue_50_Track_9", "Blue_25_Track_9", "Gray", "Gray_Track_4", "Gray_Track_5", "Gray_Track_9", "Black", "Black_Track_4", "Black_Track_5", "Black_Track_9"]

    imageColors := ["#00FF00", "#008000", "#003C00", "#00FF00", "#008000", "#003C00", "#00FF00", "#008000", "#003C00", "#00FF00", "#008000", "#003C00", "#0000FF", "#000080", "#00003C", "#0000FF", "#000080", "#00003C", "#0000FF", "#000080", "#00003C", "#0000FF", "#000080", "#00003C", "#808080", "#808080", "#808080", "#808080", "#000000", "#000000", "#000000", "#000000"]

    imageTracking := [false, false, false, true, true, true, true, true, true, true, true, true, false, false, false, true, true, true, true, true, true, true, true, true, false, true, true, true, false, true, true, true]

    trackColors := ["#008000", "#003C00", "#008000", "#008000", "#003C00", "#008000", "#008000", "#003C00", "#008000", "#008000", "#003C00", "#008000", "#000080", "#00003C", "#000080", "#000080", "#00003C", "#000080", "#000080", "#00003C", "#000080", "#000080", "#00003C", "#000080", "#003C00", "#003C00", "#003C00", "#003C00", "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF"]

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
        ; Verificar si se ha cancelado la generación
        if (isCancelled)
        {
            MsgBox, 48, Cancelled, Image generation was cancelled.
            break
        }

        idx := A_Index
        imageName := imageNames[idx]
        imageColor := imageColors[idx]
        hasTracking := imageTracking[idx]
        trackColor := trackColors[idx]

        ; Actualizar el texto de progreso y la barra de progreso
        currentImage++
        progressText := "Generating: " . imageName . " (" . currentImage . "/" . totalImages . ")"
        GuiControl, Progress:, ProgressText, %progressText%
        GuiControl, Progress:, ProgressBar, % (currentImage / totalImages) * 100

        ; Si la imagen tiene tracking, generar versiones con puntos de colores
        if (hasTracking)
        {
            ; Calcular el margen fijo basado en el Size 2
            fixedMargin := Round(fontSize * 0.5)

            ; Array para almacenar los colores de track
            if (InStr(imageName, "Green") || InStr(imageName, "Gray"))
            {
                trackColorArray := [trackColor, blueTrackColor]
                colorSuffixArray := ["-G", "-B"]
            }
            else if (InStr(imageName, "Blue"))
            {
                if (InStr(imageName, "Blue_100"))
                    trackColorArray := ["#000080", greenTrackColor]  ; Azul 50% y Verde 50%
                else if (InStr(imageName, "Blue_50"))
                    trackColorArray := ["#00003C", greenTrackColor]  ; Azul 25% y Verde 50%
                else if (InStr(imageName, "Blue_25"))
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
                    currentMargin := fixedMargin * (marginIdx == 1 ? 0.5 : 3)
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
                                MsgBox, 36, Confirmation, Some files already exist. Do you want to overwrite all existing files?
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
                        ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=" . imageColor . ":s=" . width . "x" . height . " -vf """ . filter . """ -update 1 -frames:v 1 -q:v 1 -f image2 """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"

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
                                    MsgBox, 16, Error, There was a problem generating %imageName%.jpg, but no error details were found.
                                }
                                else
                                {
                                    MsgBox, 16, Error, There was a problem generating %imageName%.jpg.`n`nError Details:`n%ffmpegError%
                                }
                            }
                            else
                            {
                                MsgBox, 16, Error, There was a problem generating %imageName%.jpg, and the error log file could not be found.
                            }

                            ; Mostrar la salida estándar de FFmpeg si existió
                            if FileExist(outputLog)
                            {
                                FileRead, ffmpegOutput, %outputLog%
                                if (ffmpegOutput != "")
                                {
                                    MsgBox, 48, FFmpeg Output, Output details:`n%ffmpegOutput%
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
                        MsgBox, 36, Confirmation, Some files already exist. Do you want to overwrite all existing files?
                        IfMsgBox, No
                            return
                        overwriteConfirmed := true
                    }
                }

                ; Definir ruta para los archivos de log
                errorLog := logsDir . "\" . imageName . "_error.log"
                outputLog := logsDir . "\" . imageName . "_output.log"

                ; Construir el comando FFmpeg sin el filtro
                ffmpegCommand := """" . ffmpegPath . """ -y -f lavfi -i color=c=" . imageColor . ":s=" . width . "x" . height . " -update 1 -frames:v 1 -q:v 1 -f image2 """ . outputFile . """ >""" . outputLog . """ 2>""" . errorLog . """"

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
                            MsgBox, 16, Error, There was a problem generating %imageName%.jpg, but no error details were found.
                        }
                        else
                        {
                            MsgBox, 16, Error, There was a problem generating %imageName%.jpg.`n`nError Details:`n%ffmpegError%
                        }
                    }
                    else
                    {
                        MsgBox, 16, Error, There was a problem generating %imageName%.jpg, and the error log file could not be found.
                    }

                    ; Mostrar la salida estándar de FFmpeg si existió
                    if FileExist(outputLog)
                    {
                        FileRead, ffmpegOutput, %outputLog%
                        if (ffmpegOutput != "")
                        {
                            MsgBox, 48, FFmpeg Output, Output details:`n%ffmpegOutput%
                        }
                        FileDelete, %outputLog%
                    }
                }

                ; Eliminar el archivo de lote temporal
                FileDelete, %tempBatch%
            }
        }
    }

    ; Modificar el final de la función para que no muestre el mensaje de éxito
    ; si está siendo llamada desde GenerateAll
    if (!isCancelled && showCompletionMessages)
    {
        MsgBox, 64, Success, All images have been successfully generated in the folders:`n%folderName%-Margin1`n%folderName%-Margin2
    }

    ; Ocultar la interfaz de progreso
    Gui, Progress:Hide

    ; Mostrar la interfaz principal solo si no fue llamada desde GenerateAll
    if (A_ThisLabel != "GenerateAll")
        Gui, Main:Show
return

GenerateAll:
    MsgBox, 4, Confirm Generation, Are you sure you want to generate images for all resolutions? This may take a long time.
    IfMsgBox, No
        return

    ; Guardar el valor original de showCompletionMessages
    originalShowCompletionMessages := showCompletionMessages
    ; Desactivar los mensajes de finalización para cada resolución
    showCompletionMessages := false

    ; Declarar variables globales
    global resolutionsList, SelectedResolution, isCancelled

    ; Obtener todas las resoluciones de la lista
    allResolutions := []
    Loop, Parse, resolutionsList, |
    {
        if (A_LoopField != "Add a new resolution")
            allResolutions.Push(A_LoopField)
    }

    ; Guardar la selección original
    originalSelection := SelectedResolution

    ; Generar imágenes para cada resolución
    for index, resolution in allResolutions
    {
        ; Establecer la resolución actual en el dropdown
        GuiControl, Choose, SelectedResolution, %resolution%
        
        ; Llamar a GenerateImages
        Gosub, GenerateImages
        
        if (isCancelled)
        {
            MsgBox, 48, Cancelled, Image generation was cancelled. Some resolutions may not have been processed.
            break
        }
    }

    ; Restaurar la selección original
    GuiControl, Choose, SelectedResolution, %originalSelection%

    ; Restaurar el valor original de showCompletionMessages
    showCompletionMessages := originalShowCompletionMessages

    ; Mostrar mensaje de finalización si no se canceló
    if (!isCancelled)
    {
        MsgBox, 64, Success, All images for all resolutions have been successfully generated.
    }

    ; Volver a mostrar la interfaz principal
    Gui, Main:Show
return

CancelGeneration:
    isCancelled := true
    MsgBox, 48, Cancelling, Cancelling current and remaining resolutions...
return

; Manejadores de eventos para cerrar las ventanas
MainGuiClose:
MainGuiEscape:
    ExitApp

ProgressGuiClose:
ProgressGuiEscape:
    ; Preguntar al usuario si realmente quiere cancelar
    MsgBox, 4, Confirm Cancellation, Are you sure you want to cancel the image generation?
    IfMsgBox, Yes
    {
        isCancelled := true
    }
return

; Función para remover el tooltip
RemoveToolTip:
    ToolTip
return