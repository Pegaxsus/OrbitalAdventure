# Hangar Orbital · Guía técnica de Godot

Estado documentado en **0.0.23**. Prototipo 2D cenital de escritorio para Windows, desarrollado con **Godot 4.5.1 estándar y GDScript**. El historial está en [releases-godot.md](releases-godot.md). Este documento cubre el proyecto de Godot.

## Arranque y exportación

1. En el gestor de proyectos de Godot, importa `NavePrototype/Godot/project.godot`. Pulsa **F5 en el editor** para ejecutar `main.tscn`. **F5 dentro del juego** guarda la partida.
2. Para distribuir en Windows, instala las plantillas de exportación de **la misma versión del motor** y usa el perfil **Windows Desktop**. Es x86_64, con el paquete integrado en el ejecutable. Conserva los filtros de inclusión de los atributos y el sector.
3. Para una nueva entrega, actualiza la versión que muestra `game.gd`, el destino de `export_presets.cfg` y los tres documentos de la carpeta `documentation`. El ejecutable se genera en la carpeta padre del proyecto Godot.

Desde PowerShell, con `$godot` apuntando al ejecutable de consola de Godot y `$project` al directorio `Godot`:

```powershell
& $godot --headless --path $project --editor --import
& $godot --headless --path $project --quit-after 10
& $godot --headless --path $project --export-release "Windows Desktop"
```

Revisa la salida en busca de errores de script además del código de salida. La prueba de arranque sin ventana cubre la carga de escena y recursos, pero los controles y la presentación se verifican en una sesión de juego.

## Estructura del proyecto

| Ruta relativa a `NavePrototype` | Función |
|---|---|
| `Godot/project.godot` | Configuración de arranque, viewport de 900 × 600, escalado de canvas y renderizador Compatibility. |
| `Godot/main.tscn` | Escena principal con un `Node2D` que ejecuta `game.gd`. |
| `Godot/game.gd` | Estado y reglas del juego, entrada, simulación, NPC, interfaz dibujada y persistencia. |
| `Godot/missile.tscn`, `Godot/missile.gd` | Escena reutilizable del misil. Velocidad, aceleración, daño y radio se exponen en el inspector. |
| `Godot/ships/ship0.png` a `ship16.png` | Sprites de las 17 naves. La proa apunta hacia arriba en el arte base. |
| `Godot/ship-attributes/ship0.txt` a `ship16.txt` | Una línea de atributos por nave, con el mismo índice que su sprite. |
| `Godot/environment/` | Fondo estelar, cinco tamaños de asteroide con dos variantes cada uno, 22 sprites de restos transparentes y seis sprites de estación. |
| `Godot/station-attributes.txt` | Catálogo de estaciones con sprite, posición, tamaño, masa, casco y número de puertos. |
| `Godot/sector.txt` | Catálogo ordenado del sector inicial y base de composición de los demás sectores. |
| `Godot/export_presets.cfg` | Perfil reproducible de exportación de Windows. |
| `savegames/godot/latest.json` | Última partida local de Godot. Se crea al guardar. |
| `Godot/.godot/` | Caché regenerable del editor, ignorada por Git. |

Los archivos `.uid` y `.import` acompañan al código y los recursos. Guarda los textos en UTF-8 para conservar las tildes.

## Controles para verificar una entrega

| Contexto | Controles |
|---|---|
| Hangar | Clic o flechas para elegir nave, **P** color, **N** motor auxiliar, **U** descargar a inventario, **Enter** despegar. |
| Vuelo | **W/S** empuje longitudinal, **A/D** lateral, **Q/E** orientación, **X** freno manual, **C** Coupled/Decoupled, **B** atracar en un puerto cercano. |
| Interacción | Toque de **Mayús izquierda** para avanzar de modo o mantener y usar la rueda. **Espacio** activa el modo. **Tab** escanea, **T** recorre objetivos por distancia, **Y** deselecciona. |
| Cámara y minería | Rueda para zoom o potencia, según el modo. **O/L** ajustan potencia en Minería. |
| Navegación y partida | **M** mapa estelar, **G** cruzar puerta cercana, **H** ayuda, **F5/F9** guardar/cargar. |

## Dónde modificar cada sistema

| Sistema | Código y reglas actuales |
|---|---|
| Entrada y vuelo | `_input()` maneja acciones discretas y `_physics_process(dt)` actualiza controles mantenidos, velocidad y colisiones. `pos`, `vel` y `angle` son coordenadas del sector; la proa es `Vector2.UP.rotated(angle)`. El empuje depende de fuerza/masa. Coupled es el valor inicial y frena al soltar W/A/S/D. Decoupled conserva la velocidad. Las partidas con una preferencia guardada mantienen su elección. |
| Dibujo y cámara | `_draw()` dibuja el mundo con una transformación centrada en la nave y luego el HUD en coordenadas de pantalla. `_process()` sincroniza la capa de misiles con esa cámara. El arte se muestra con filtro de vecino más cercano. |
| Combate y objetivos | La ametralladora usa trazadoras simuladas en `game.gd`; cada misil instancia su escena. `ray_rock()`, `ray_npc()` y `ray_wreck()` localizan el primer impacto de un segmento. `missile_impact()` aplica daño directo y de área. `cycle_target()` ordena naves y asteroides por distancia. |
| Ping y minería | Tab inicia una onda con origen fijo. Al alcanzar un asteroide revela sus recursos. `update_mining()` y `decay_mining()` gestionan la ventana de potencia móvil, la sobrecarga y la pérdida de progreso. `drop()` crea fragmentos que se recogen por proximidad si caben en la bodega. |
| Salvaging | `wreck_ship()` crea restos y una explosión visual. `update_wrecks()` usa un rayo del 55 % de la longitud de la nave y requiere entre 1 y 2,5 s de contacto según el resto. Los proyectiles y las explosiones pueden eliminar restos sin botín. |
| NPC | `reset_traffic()`, `update_traffic()`, `steer_npc()`, `npc_hit()` y `fire_npc()` gestionan trader y escoltas, minero, pirata y patrulla. El trader es temporal. El minero limita su extracción al espacio restante. En el sector inicial lleva cada recogida a la estación y, en otros sectores, sale por una puerta al llenar 20 U. Los piratas pueden dañar el casco de Salvia; la patrulla prioriza defenderla y sigue reaccionando ante agresiones contra neutrales con línea de visión. |
| Estaciones y atraque | `load_stations()` carga el catálogo. `station_contact()` resuelve la colisión de la nave con el núcleo y los brazos de la estación. `try_dock()` valida el puerto, la alineación y la velocidad. `dock_at()` fija la posición de salida, y `draw_docked_background()` dibuja la estación suavizada detrás del hangar. |
| Sectores | `generate_links()` genera el grafo de cinco sectores y seis rutas. `generate_field()` prepara 640 asteroides por sector de 10.000 × 10.000. `cross_gate()` cambia el sector y registra la ruta. `draw_maps()` muestra solo rutas cruzadas en el mapa y puertas cruzadas del sector activo en el minimapa. |

### Formatos de datos

- **Ficha de nave**, separada por comas y sin encabezado. Campos en orden: `masa,fuerza,casco,longitud,capacidad,slots_armamento,slots_defensa,slots_utilidad,slots_motores`. Las naves se seleccionan por índice de base cero. La UI muestra números de base uno.
- **Estación**, separada por comas y sin encabezado. Campos en orden: `sprite,nombre,sector,x,y,tamaño,masa,casco,puertos`. El sector es de base cero. Los puertos se numeran internamente de 0 a 7, en pares norte, este, sur y oeste. El catálogo activo contiene solo la Estación Salvia, en (0, 0) del sector 4107. Tiene ocho puertos y 26.000 puntos de casco. El ataque pirata resta 90 por ráfaga y el casco tiene un mínimo de 1. Cada puerto mide 190 × 56 unidades. La tolerancia de orientación es de 12° respecto al eje del puerto y la velocidad máxima de atraque es 28 unidades/s.
- **Sector**, separado por comas y sin encabezado. Campos en orden: `x,y,radio,recurso_1,recurso_2,paso_potencia`. El segundo recurso puede ser `-1`. Los recursos se indexan según `RES`. La potencia base de minería se deriva de `0.25 + 0.05 × paso_potencia`.
- **Ranuras actuales**, en orden armamento/defensa/utilidad/motores. Mediana `3/1/2/1`, grande `4/2/2/2`, muy grande `5/3/3/2`. La clase que muestra el hangar usa cortes de longitud en 90 y 125. El mínimo previsto para pequeñas es `2/1/1/1`.

La [ficha visual de la flota](../flota-0.0.21.png) reúne los sprites y atributos de esta versión.

## Persistencia y compatibilidad

El exportado guarda junto a su ejecutable. El editor resuelve la misma carpeta relativa a la raíz del proyecto Godot. Al arrancar y con **F9**, `load_game()` busca `savegames/godot/latest.json` y, si falta, el antiguo `user://sector.json`. **F5** sobrescribe el último guardado de esta edición. Para ensayar cambios en la carga, usa una copia de la partida o una ruta de prueba.

El JSON guarda nave, pintura, modo, motor, Coupled, estado de hangar, estación y puerto de atraque, casco y reserva minera de Salvia, posición, velocidad, orientación, casco, bodega, inventario y sector activo. `crossed` es una máscara de bits por índice de ruta. `fields` guarda filas `[vida, escaneado, progreso]`; `sector_loot` guarda `[x, y, recurso, cantidad]`; `wrecks` guarda `[x, y, sprite, ángulo, progreso]`. Cada uno está agrupado por sector. Los campos históricos `field` y `loot` permiten leer partidas del sector único. Los NPC, los disparos y los efectos se reinician al cargar. Las partidas antiguas guardadas en el hangar se sitúan en un puerto de Salvia en el sector inicial; una partida antigua guardada en vuelo conserva la posición.

El formato todavía carece de un campo explícito de versión. Al añadir estado, define un valor por defecto para partidas anteriores y prueba guardado/carga antes de publicar. El orden de asteroides, rutas, recursos, naves y sprites de restos tiene significado en partidas existentes. Si necesitas cambiarlo, añade una migración o identificadores estables.

## Continuar el desarrollo

1. Identifica el punto de entrada en la tabla anterior y reproduce el comportamiento en el editor antes de editar. Para un objeto con vida propia y parámetros ajustables, `missile.tscn` sirve de ejemplo.
2. Prueba el flujo que cambiaste y las transiciones cercanas. Para vuelo, comprueba deriva y frenado con el mismo casco. Para atraque, verifica despegue con Enter, rechazo con B fuera del puerto o desalineado, y regreso con B a baja velocidad dentro de un puerto. Para sectores, sal desde el inicial hacia **(0, −1250)**, cruza con **G**, guarda, vuelve a abrir y comprueba ruta y sector. Para carga, verifica un guardado anterior y uno nuevo. Para cambios visuales, revisa también el ejecutable exportado.
3. En cada release entrega los dos ejecutables numerados y actualiza `releases-godot.md`, `releases-c#.md` y esta guía. Añade un encabezado de nivel 2 con el número, el pedido y el trabajo realizado a cada historial, y registra las diferencias de verificación.

Las ranuras representan capacidad visible en el hangar. Quedan por implementar montaje y restricciones de equipamiento, defensas y mejoras, drones, comercio y las clases futuras. Los modos de combate y trabajo actuales se seleccionan directamente. La mayor parte de la lógica y del dibujo vive todavía en `game.gd`; al extraer un sistema a otra escena, comprueba sus coordenadas, su orden de actualización y sus efectos en la partida.

