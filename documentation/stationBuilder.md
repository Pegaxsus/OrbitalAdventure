# stationBuilder 1.3

Editor independiente de estaciones para Windows. Ejecuta `stationBuilder-1.3.exe` desde la raíz del proyecto. Utiliza Windows Forms y .NET Framework de Windows, sin necesitar Godot instalado. La herramienta sirve para preparar recursos para ambas ediciones del juego y tiene numeración propia.

## Crear una estación

1. Arrastra uno o varios archivos PNG desde el Explorador al lienzo, o pulsa **Añadir PNG**. Se conserva su transparencia original. Los PNG con fondo opaco conservarán ese fondo.
2. Selecciona una pieza y arrástrala para moverla. Arrastra los cuadrados amarillos de sus esquinas para cambiar tamaño y escala de forma proporcional, o el círculo amarillo exterior para girarla. Arrastra los rombos turquesa de los lados para estirar o comprimir un solo eje de la pieza, incluso cuando está girada. El recuadro muestra dimensiones, escalas X/Y y ángulo. También puedes ajustar **Rotación °**, **Escala %**, **Escala X %** y **Escala Y %** en el panel derecho. Los PNG grandes entran reducidos a un máximo inicial de 256 píxeles por lado; puedes cambiar su escala después.
3. Usa **Duplicar**, **Al frente** y **Al fondo** para componer la estación. La lista **Capas** muestra primero la pieza situada delante. Permite seleccionar piezas tapadas por otras o por un puerto.
4. Elige **Colocar puerto normal**, **Colocar puerto Dread** o **Colocar PDC** en el selector superior y pulsa sobre el lienzo. Cada colocación vuelve al modo de selección. En la pestaña **Hardpoints** puedes seleccionarlos y modificar su posición y giro. También puedes arrastrarlos directamente y, una vez seleccionados, girarlos arrastrando su círculo amarillo exterior. Los puertos conservan sus dimensiones fijas.
5. **Situar origen** permite fijar con un clic el núcleo o pivote de la estación. La cruz rosa indica ese origen.
6. Pulsa **Guardar proyecto** para conservar el diseño editable. Usa **Exportar PNG** para generar el sprite y la ficha de hardpoints del juego.

La rueda cambia el zoom del lienzo. Arrastrar con el botón derecho o central desplaza la vista sin mover las piezas. Un clic derecho sin arrastrar abre el menú. Sobre un PNG o hardpoint puedes copiar, duplicar, eliminar o girar 90° a izquierda o derecha. Haz clic derecho en el destino y elige **Pegar aquí** para colocar la copia. El portapapeles es interno al editor. **Traer al frente** y **Enviar al fondo** se aplican a los PNG. El menú aparece al soltar el botón, y un desplazamiento de cinco píxeles inicia el movimiento del plano. **Centrar vista** encuadra las piezas. Estos controles de vista no modifican la escala exportada.

| Acción | Control |
|---|---|
| Mover una pieza o hardpoint | Clic y arrastre izquierdo |
| Girar o cambiar tamaño de una pieza | Círculo de giro y esquinas del recuadro; también campos del panel derecho |
| Girar un puerto o PDC | Seleccionarlo y arrastrar su círculo de giro |
| Menú de la pieza pulsada | Clic derecho y soltar |
| Desplazar el plano | Arrastrar con botón derecho o central |
| Duplicar una pieza | Botón Duplicar o Ctrl+D |
| Eliminar selección | Botón Eliminar o Supr |
| Abrir proyecto | Ctrl+O |
| Guardar proyecto editable | Ctrl+S |
| Exportar recursos del juego | Exportar PNG |
| Deformar sólo X o Y | Rombos turquesa o campos Escala X % y Escala Y % |
| Limpiar selección y volver al modo de selección | Escape |

Al crear otro proyecto, abrir uno o cerrar la aplicación se avisa si hay cambios pendientes. Esta versión no incluye historial de deshacer.

## Selección múltiple

En el lienzo, usa **Ctrl+clic** para añadir o quitar piezas, puertos y PDC de la selección. Arrastra un objeto seleccionado para mover todo el grupo. Con las flechas, cada pulsación desplaza la selección un píxel del lienzo. Si mantienes una flecha pulsada, el movimiento se repite según el ajuste del teclado de Windows.

Haz clic derecho sobre un miembro del grupo para copiar, duplicar, girar o eliminar la selección. El giro usa el centro de cada objeto. Las órdenes de capa conservan el orden relativo de los PNG seleccionados. Los tiradores de giro y escala están disponibles al seleccionar un solo objeto.

**Ctrl+C** copia y **Ctrl+V** pega la selección con un desplazamiento inicial de 24 píxeles en X e Y. **Pegar aquí** sitúa el primer elemento de la copia en el punto pulsado. Ambos conservan la disposición del grupo y respetan los límites del lienzo. Los campos de texto y números conservan sus atajos de edición.

## Puertos y PDC

| Tipo | Longitud × anchura | Representación en el editor |
|---|---|---|
| Puerto normal | 164 × 58 | Rectángulo verde |
| Puerto Dread | 258 × 196 | Rectángulo turquesa |
| PDC | Marcador de 20 × 20 | Círculo naranja |

Los puertos conservan las medidas vigentes del juego y sólo admiten cambio de posición y orientación. La flecha sigue el eje longitudinal del puerto. El PDC define un punto y una orientación; su círculo es una guía, no el tamaño definitivo de la torreta. No hay límite por atributos de estación en este editor; permite hasta 512 hardpoints.

## Guardado y exportación

**Exportar PNG** escribe los archivos `.png` y `.hardpoints.csv`. **Guardar proyecto** escribe por separado el archivo editable `.station.json`. Por ejemplo:

- `mi-estacion.png`: composición final con transparencia, sin cuadrícula, marcadores, rectángulos de atraque ni selección. Es una imagen cuadrada centrada en el origen elegido, con 16 píxeles de margen y un máximo de 4096 × 4096.
- `mi-estacion.station.json`: proyecto editable. Incorpora los PNG originales en base64, las capas en orden, sus posiciones, rotaciones y escalas, el origen y los hardpoints. **Abrir proyecto** lee este archivo.
- `mi-estacion.hardpoints.csv`: ficha de puntos con posición relativa al origen, giro y dimensiones de los puertos. Sus columnas son `entidad,id,tipo,indice,x,y,rotacion_grados,longitud,anchura`. El ID `*` queda pendiente de asignación al incorporar la estación al juego. Los índices empiezan en cero por cada tipo.

Para incorporar una estación posteriormente, entrega el PNG y el JSON o el CSV. El PNG por sí solo no contiene los puertos ni PDC. El editor prepara recursos; no añade automáticamente estaciones a sectores ni asigna casco, mercados o atributos. El CSV ampliado de esta herramienta requiere conversión para el cargador actual del juego y no debe copiarse directamente sobre `hardpoints.txt`.

Las posiciones de capas y hardpoints del JSON usan coordenadas del lienzo; `OriginX/Y` identifica su pivote. Para convertirlas a coordenadas del PNG: `puntoPNG = puntoLienzo - origenLienzo + ExportOrigin`. `ExportOriginX/Y` es el centro de la imagen exportada. El CSV ya resta el origen. El eje X apunta a la derecha, Y hacia abajo y los ángulos positivos giran en sentido horario desde X. La escala es una unidad del juego por píxel exportado; cambiar después el tamaño de la estación exige aplicar el mismo factor a puertos y puntos.

El guardado escribe primero archivos temporales y restaura los originales si falla la sustitución de alguno. Se solicita confirmación al sobrescribir archivos existentes. Los PNG de entrada pueden medir hasta 8192 por lado y 32 millones de píxeles, con un límite de 32 MB por archivo. El proyecto admite hasta 256 capas.

## Desarrollo y comprobación

Fuente `tools/StationBuilder.cs`. Compilación desde la raíz:

```powershell
& ./build/build-station-builder.ps1
$test = Start-Process -FilePath (Resolve-Path stationBuilder-1.3.exe) -ArgumentList '--smoke' -WindowStyle Hidden -Wait -PassThru
$test.ExitCode
```

La prueba abre brevemente la ventana y usa archivos temporales aislados. Comprueba arrastre, duplicación, orden y selección de capas, escala con esquina, giro directo de PNG y de los tres tipos de hardpoint, separación de clic derecho y arrastre, acciones del menú contextual, dimensiones de puertos, PNG transparente, CSV y reapertura portátil sin los PNG originales. El formato de proyecto 2 conserva la escala de cada eje. Los proyectos de stationBuilder 1.0 y 1.1 se abren con su escala original en ambos ejes. La prueba de 1.2 terminó con código 0 y cubrió también los rombos en una pieza girada, los giros de 90°, la copia, el pegado, la duplicación y la separación de guardado y exportación. Si falla, escribe el detalle en `%TEMP%/stationBuilder-smoke-error.txt`. Se revisó además una vista renderizada con el sprite de la estación TRI. No se modifican guardados ni ejecutables del juego.

La prueba de 1.3 terminó con código 0 y cubrió selección mixta, copia y pegado con atajos, flechas repetidas, giro y borrado de grupos.
