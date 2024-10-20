# GreenScreenGen

GreenScreenGen es una herramienta para generar imagenes verde, azul, gris y negro, con y sin puntos de track para uso pantallas.

## Características

- Genera imágenes de fondo verde, azul, gris y negro en múltiples resoluciones.
- Crea puntos de tracking en las imágenes para facilitar el seguimiento en post-producción.
- Permite personalizar las resoluciones de salida.
- Genera imágenes con dos tamaños de margen diferentes (Margin1 y Margin2).
- Produce imágenes JPG de alta calidad.
- Interfaz gráfica fácil de usar.

## Tecnología

Este programa está desarrollado con [AutoHotkey](https://www.autohotkey.com/) v1.1.

## Compilación

El ejecutable (.exe) ha sido compilado utilizando Ahk2Exe con las siguientes opciones:

- Para sistemas de 32 bits: "v1.1.36.02 U32 Unicode 32bit.bin"
- Para sistemas de 64 bits: "v1.1.36.02 U64 Unicode 64bit.bin"

Asegúrate de seleccionar la opción correcta en Base File (bin/exe) al compilar el script para garantizar el manejo adecuado de caracteres Unicode.

## Uso

1. Seleccionar una resolución de la lista desplegable.
2. Clickear en "Generate" para crear imágenes para la resolución seleccionada.
3. Utilizar "Generate All" para crear imágenes en todas las resoluciones disponibles.

Las imágenes generadas se guardarán en carpetas dentro del directorio "Exports":
- La carpeta "Margin1" contiene imágenes con un margen más pequeño.
- La carpeta "Margin2" contiene imágenes con un margen más grande.

Todas las imágenes se generan en formato JPG de alta calidad.


v1.5 | Lega | 2024