# Hangar Orbital · Guía técnica de Godot

Estado documentado en **0.1.17**. Prototipo 2D cenital de escritorio para Windows, desarrollado con **Godot 4.5.1 estándar y GDScript**. El historial está en [releases-godot.md](releases-godot.md). Este documento cubre el proyecto de Godot.

## Arranque y exportación

1. En el gestor de proyectos de Godot, importa `NavePrototype/project.godot`. Pulsa **F5 en el editor** para ejecutar `main.tscn`. **F5 dentro del juego** guarda la partida.
2. Para distribuir en Windows, instala las plantillas de exportación de **la misma versión del motor** y usa el perfil **Windows Desktop**. Es x86_64, con el paquete integrado en el ejecutable. Conserva los filtros de inclusión de los atributos y el sector.
3. Para una nueva entrega, actualiza la versión que muestra `game.gd`, el destino de `export_presets.cfg` y los historiales de ambas ediciones, esta guía y `AI_LIGHTHOUSE.md` en la raíz del proyecto. El ejecutable vigente se genera en la raíz. Archiva la versión anterior en releases/.

Desde PowerShell, con `$godot` apuntando al ejecutable de consola de Godot y `$project` a la raíz de NavePrototype:

```powershell
& $godot --headless --path $project --editor --import
& $godot --headless --path $project --quit-after 10
& $godot --headless --path $project --export-release "Windows Desktop"
```

Revisa la salida en busca de errores de script además del código de salida. La prueba de arranque sin ventana cubre la carga de escena y recursos, pero los controles y la presentación se verifican en una sesión de juego.

## Estructura del proyecto

| Ruta relativa a `NavePrototype` | Función |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `project.godot` | Configuración de arranque, viewport de 900 × 600, escalado de canvas y renderizador Compatibility. |
| `Godot/main.tscn` | Escena principal con un `Node2D` que ejecuta `game.gd`. |
| `Godot/game.gd` | Estado y reglas del juego, entrada, simulación, NPC, interfaz dibujada y persistencia. |
| `Godot/missile.tscn`, `Godot/missile.gd` | Escena compartida por cohetes y misiles. Usa `assets/projectiles/rocket-flight.png` y `assets/projectiles/missile-flight.png` con la proa hacia arriba. La llama se dibuja en coordenadas locales debajo del sprite y cambia de longitud con la edad del proyectil. El misil sale lateralmente según el hardpoint, espera 0,24 s y luego gira hacia el objetivo fijado al disparar. Acelera durante el vuelo y la colisión de segmento detecta naves y asteroides. El misil sigue de frente si pierde el blanco y el cambio de sector limpia los proyectiles. Velocidad inicial, aceleración, daño y radio se exponen en el inspector. |
| `assets/ships/` | Sprites de las 46 naves. La proa apunta hacia arriba al dibujarse. Godot aplica la rotación indicada en el catálogo al cargar cada PNG. |
| `data/hardpoints.txt` | Puntos de anclaje de las estaciones. |
| `data/hardpoints/ship<ID>.txt` | Puntos de anclaje de un casco. El editor guarda estas fichas. |
| `shipConfigurator-1.6.exe` | Editor visual para colocar puntos sobre el PNG. Lee el catálogo y el arte de la raíz del proyecto. |
| `attributes/ship-traits.txt` | Valores de los rasgos. Cada fila contiene rasgo, parámetro y valor. La edición C# incorpora este mismo archivo. |
| `attributes/ships-godot.txt` | Catálogo completo de naves. Cada fila relaciona un ID estable con su PNG, su rotación y sus atributos. |
| `assets/` | Fondo estelar, cinco tamaños de asteroide con dos variantes cada uno, 22 sprites de restos transparentes seis sprites de estación y la lámina `ship-explosion.png`. |
| `attributes/station-attributes.txt` | Catálogo de estaciones con sprite, posición, tamaño, masa, casco y número de puertos. |
| `data/sector.txt` | Catálogo ordenado del sector inicial y base de composición de los demás sectores. |
| `export_presets.cfg` | Perfil reproducible de exportación de Windows. |
| `savegames/godot/latest.json` | Última partida local de Godot. Se crea al guardar. |
| `.godot/` | Caché regenerable del editor, ignorada por Git. |

Los recursos gráficos se organizan en assets/ships, asteroids, backgrounds, debris, effects, factions, gates, modules, projectiles, shields, stations, turrets y previews. Las fichas de estaciones personalizadas viven en data/stations. lore/factions contiene el dossier, lore/fleets la ficha e imagen de la flota y lore/maps la imagen del mapa estelar.

Los archivos `.uid` y `.import` acompañan al código y los recursos. Guarda los textos en UTF-8 para conservar las tildes.

## Controles para verificar una entrega

| Contexto | Controles |
|---|---|
| Hangar | Clic o flechas para elegir nave, **P** color, **N** motor auxiliar, **U** descargar materiales a inventario, botón **Inventario** para abrir el panel y **Esc** para cerrarlo, **Enter** o el botón **Desatracar** para despegar. El botón **Descargar bodega** equivale a U. |
| Vuelo | **W/S** empuje longitudinal, **A/D** lateral, **Q/E** orientación, **X** freno manual, **C** Coupled/Decoupled, **B** atracar en un puerto cercano. |
| Interacción | **1–5** selecciona los tipos de armamento instalados, sin huecos. **Espacio** usa el módulo seleccionado. La ametralladora dispara en ráfaga mientras se mantiene pulsado, con una recarga de 0,075 s por salva. **Rueda** ajusta el zoom. En minería, **Mayús + rueda** u **O/L** ajusta la potencia. **Tab** escanea, **T** selecciona la entidad más cercana, **Y** deselecciona y **J** abre el comercio con un trader de paso a menos de 220 unidades. Sus compras y ventas de materiales usan la bodega de la nave activa y las compras respetan su capacidad. |
| Cámara y minería | Rueda para zoom o potencia, según el modo. **O/L** ajustan potencia en Minería. |
| Navegación y partida | **M** mapa estelar, **G** cruzar puerta cercana, **H** ayuda, **F5/F9** guardar/cargar. |

## Dónde modificar cada sistema

| Sistema | Código y reglas actuales |
|---|---|
| Entrada y vuelo | `_input()` maneja acciones discretas y `_physics_process(dt)` actualiza controles mantenidos, velocidad y colisiones. `pos`, `vel` y `angle` son coordenadas del sector; la proa es `Vector2.UP.rotated(angle)`. El empuje depende de fuerza/masa. Coupled es el valor inicial y frena al soltar W/A/S/D. Decoupled conserva la velocidad. Las partidas con una preferencia guardada mantienen su elección. |
| Dibujo y cámara | `_draw()` dibuja el mundo con una transformación centrada en la nave y luego el HUD en coordenadas de pantalla. `_process()` sincroniza la capa de misiles con esa cámara. El arte se muestra con filtro de vecino más cercano. `draw_help()` agrupa controles en tres columnas. `draw_inventory()` dibuja la nave, sus ranuras y una cuadrícula de 8 × 8 celdas de 32 unidades de interfaz y un panel fijo de detalles. El ratón permite arrastrar los módulos entre celdas y ranuras de armamento, con intercambio al soltar sobre un módulo existente. `_input()` restringe ese panel al hangar y bloquea la interacción con el fondo mientras está abierto. |
| Combate y objetivos | La ametralladora usa trazadoras simuladas en `game.gd`; cada misil instancia su escena. `ray_rock()`, `ray_npc()` y `ray_wreck()` localizan el primer impacto de un segmento. `missile_impact()` aplica daño directo y de área. `cycle_target()` ordena naves y asteroides por distancia. |
| Ping y minería | Tab inicia una onda con origen fijo. Al alcanzar un asteroide revela sus recursos. `update_mining()` y `decay_mining()` gestionan la ventana de potencia móvil, la sobrecarga y la pérdida de progreso. `drop()` crea fragmentos que se recogen por proximidad si caben en la bodega. |
| Salvaging | `wreck_ship()` crea restos y registra la posición, orientación y casco de la nave destruida. `draw_explosions()` conserva el casco inmóvil y reproduce el atlas de siete fotogramas en dos estallidos internos y uno final. `update_wrecks()` devuelve al jugador al hangar al terminar la secuencia de 1,08 segundos. `update_wrecks()` usa un rayo del 55 % de la longitud de la nave y requiere entre 1 y 2,5 s de contacto según el resto. Los restos se destruyen tras tres o cuatro impactos de ametralladora y los cohetes los atraviesan. Sus explosiones respetan los restos. |
| NPC | `reset_traffic()`, `update_traffic()`, `steer_npc()`, `npc_hit()` y `fire_npc()` gestionan trader y escoltas, minero, pirata y patrulla. El trader es temporal. El minero limita su extracción al espacio restante. En sectores con estación lleva cada recogida a un puerto. En los demás, sale por una puerta al llenar 20 U. Los piratas pueden dañar el casco de ambas estaciones. La patrulla prioriza defenderlas y sigue reaccionando ante agresiones contra neutrales con línea de visión. |
| Estaciones y atraque | `load_stations()` carga el catálogo. `station_contact()` resuelve la colisión de la nave con el núcleo y los brazos de la estación. `try_dock()` valida el puerto, la alineación y la velocidad. `dock_at()` fija la posición de salida, y `draw_docked_background()` dibuja la estación suavizada detrás del hangar. |
| Sectores | `generate_links()` genera el grafo de cinco sectores y seis rutas. `generate_field()` prepara 640 asteroides por sector de 10.000 × 10.000. `cross_gate()` cambia el sector y registra la ruta. `draw_maps()` muestra solo rutas cruzadas en el mapa y puertas cruzadas del sector activo en el minimapa. |

### Formatos de datos

- **Catálogo de naves**. `ships-godot.txt` tiene un encabezado y una fila por nave. Los campos son `id,sprite,rotacion,masa,empuje,casco,longitud,bodega,armamento,defensa,utilidad,motores,nombre,clase,claseID,traits`. Conserva los IDs de 0 a 23 porque se usan en las partidas y en el equipamiento. Para cambiar el aspecto, coloca un PNG en `assets/ships/` y cambia el campo `sprite` de la fila. Usa `0` para un sprite con proa hacia arriba o `180` para uno con proa hacia abajo. El editor toma el cambio al volver a ejecutar el proyecto. Exporta otro ejecutable para distribuirlo.
- **Estación**, separada por comas y sin encabezado. Campos en orden: `sprite,nombre,sector,x,y,tamaño,masa,casco,puertos`. El sector es de base cero. En las estaciones originales de cuatro brazos, los puertos normales se numeran de 0 a 7, en pares norte, este, sur y oeste. Los nuevos layouts se detallan al final de esta guía. El catálogo incluye Salvia en (0, 0) de 4107 y Nácar en (0, 0) de 4108. Cada una tiene ocho puertos y su propio casco máximo, de 26.000 y 25.000 respectivamente. El ataque pirata resta 90 por ráfaga y el casco tiene un mínimo de 1. Cada puerto normal mide 164 × 58 unidades. Las naves de clase Dreadnought o superior usan el atraque exterior de 258 × 196 situado 385 unidades al norte de la estación. Sus centros están a 160 unidades en el eje de cada brazo y a 48 unidades a cada lado. Los rectángulos no se solapan. El atraque admite hasta 10° respecto al eje largo del puerto y hasta 3 unidades/s. Al menos el 90 % del rectángulo de la nave, girado con su rumbo y dimensionado según su longitud y la proporción del sprite, debe quedar dentro del puerto. Tras cinco segundos sin recibir daño, cada estación regenera el 20 % de su casco máximo por minuto, hasta completarlo. El casco se guarda y el temporizador de reparación se reinicia al cargar la partida.
- **Sector**, separado por comas y sin encabezado. Campos en orden: `x,y,radio,recurso_1,recurso_2,paso_potencia`. El segundo recurso puede ser `-1`. Los recursos se indexan según `RES`. La potencia base de minería se deriva de `0.25 + 0.05 × paso_potencia`.
- **Ranuras por clase**. El hangar lee la clase del catálogo. Los IDs son 0 para cazas y drones, 1 para Fragata, 2 para Crucero, 3 para Battleship, 4 para Dreadnought y 5 para Titán. La Fragata es el casco pilotable más pequeño y el Titán será la clase superior. Cazas y drones quedan previstos como unidades con IA básica y órdenes.

| Clase | Armamento | Defensa | Utilidad | Motores |
|---|---:|---:|---:|---:|
| Fragata | 1 | 1 | 1 | 1 |
| Crucero | 2 | 1 | 2 | 1 |
| Battleship | 4 | 2 | 2 | 2 |
| Dreadnought | 5 | 3 | 3 | 2 |
| Carrier | 5 | 3 | 3 | 2 |

La [ficha visual de la flota](../lore/fleets/flota-0.1.2.png) reúne los sprites y atributos.

## Puntos de anclaje

Ambas ediciones comparten `hardpoints.txt` para estaciones y una ficha por nave en `data/hardpoints/`. Cada fila tiene `entidad,id,tipo,indice,x,y`. Las filas que empiezan por `#` son comentarios. Los índices de cada tipo empiezan en cero.

- Para una **nave**, usa `nave`, su ID del catálogo y uno de los tipos `motor`, `ametralladora`, `cohete`, `misil`, `mineria` o `salvaging`. Las coordenadas son fracciones del ancho y largo del sprite ya orientado. `0,0` es el centro. X positiva va a estribor e Y positiva va hacia la popa. Por ejemplo, `nave,20,motor,0,-0.20,0.45` coloca una tobera del Rorqual hacia la izquierda y la popa. Define las toberas consecutivamente desde el índice 0.
- Para una **estación**, usa `estacion`, el número de sector o `*` para el valor común, `atraque` y el índice de puerto. X e Y se miden en unidades del sector desde el centro de la estación. Un punto de un sector concreto tiene prioridad sobre el valor común.

Abre `shipConfigurator-1.6.exe`, elige una nave, marca los tipos y haz clic sobre el casco. Cada tipo de arma o herramienta admite tantos puntos como ranuras de armamento tenga la nave. Los puntos de motor no tienen límite por ranuras. Solo determinan el número y el origen de las llamas al pulsar W. El empuje se calcula a partir de los atributos de la nave. **Simetría** añade una pareja por tipo fuera del eje si caben ambos puntos. Un clic en el eje añade un punto por tipo.

Selecciona un punto en la lista y haz clic sobre la nave para moverlo. Con simetría activa también se mueve su pareja si existe. **Esc** vuelve al modo de colocación. **Deshacer** y **Rehacer** están disponibles como botones y con Ctrl+Z y Ctrl+Y. **Guardar ficha** escribe `data/hardpoints/ship<ID>.txt`. El editor aplica la rotación del catálogo. **Cargar PNG** cambia la referencia visual del editor. Para cambiar el sprite del juego, actualiza su catálogo.

Al ejecutar el proyecto desde el editor de Godot se leen las fichas nuevas. Para incorporarlas a los ejecutables, reexporta Godot o compila C# con `build/build-csharp.ps1`. El misil guiado usa `misil` y el cohete usa `cohete`. El tipo `laser` queda reservado para un módulo futuro.

### Hardpoints de hangar

shipConfigurator 1.4 ofrece **Tubo lateral**, **Rampa** y **Plataforma** para drones. Desde shipConfigurator 1.6, los Carrier (claseID 5) y Titanes (claseID 6) también ofrecen esos tres tipos para cazas. Dreadnought (claseID 4) admite drones. El rasgo fighter_hangar habilita una excepción por casco si su parámetro habilita_cazas en attributes/ship-traits.txt es mayor que cero. La elegibilidad se deriva de claseID en cada casco existente o futuro. Cada hangar guarda sus propios índices y admite varios puntos sin consumir ranuras de armamento.

- **Tubo lateral**. Marca la boca del tubo en el costado, igual que el origen de un misil lateral.
- **Rampa**. Marca el centro de la trayectoria. Selecciona la rampa y haz clic derecho hacia el rumbo de despegue. La flecha discontinua muestra el aterrizaje en sentido contrario.
- **Plataforma**. Marca el centro donde se posará la unidad. Este anclaje se usará para el descenso y cierre de compuertas.

Los tipos serializados son hangar_drones_tubo, hangar_drones_rampa y hangar_drones_plataforma, con sus equivalentes hangar_cazas_*. Conservan las coordenadas normalizadas y el formato de las fichas existentes. Coloca los puntos con clic, simetría o selección múltiple de tipos y pulsa Guardar ficha. Los cascos existentes admiten esta configuración desde el editor. Las posiciones se eligen por casco. Esta entrega incorpora la edición de anclajes y deja pendiente el comportamiento de vuelo y recuperación.


Los disparos salen del punto asignado sin cambiar su dirección frontal. Los láseres convergen desde sus anclajes y el Rorqual conserva el autoapuntado. Los puntos de atraque controlan el centro de los rectángulos y la posición de salida. Las estaciones solo consumen puntos de atraque en esta entrega.

## Rasgos de nave

La columna `traits` acepta nombres separados por `|`. `ship-traits.txt` declara parámetros numéricos para los rasgos que el código reconoce. El Rorqual tiene `gimbal_miners|long_miner`. Al activar la minería, busca el asteroide disponible más cercano a la proa entre los que quedan a ±45° del eje frontal y dentro de alcance. Los rayos convergen en esa dirección. Si no encuentra un objetivo válido, apunta recto. El alcance del Rorqual es 1,25 veces el normal. Sigue siendo necesario equipar un módulo de minería.

## Mineras y módulos repetidos

| Nave | Clase | Masa | Empuje | Casco | Longitud | Bodega | Armamento | Defensa | Utilidad | Motores |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Procurer | Fragata | 12 t | 950 kN | 110 | 32 | 72 U | 1 | 1 | 1 | 1 |
| Retriever | Crucero | 48 t | 3.600 kN | 310 | 78 | 155 U | 2 | 1 | 2 | 1 |
| Covetor | Battleship | 95 t | 5.650 kN | 470 | 94 | 240 U | 4 | 2 | 2 | 2 |

Cada ametralladora dispara desde un punto lateral diferente. Los rayos de minería y salvaging convergen hacia la proa. Por cada rayo adicional que golpea el mismo asteroide, la ventana de minería aumenta 3,5 puntos porcentuales por lado. Los rayos que golpean el mismo resto suman su velocidad de recuperación.

El Tractor Beam Tier0 funciona al equiparlo. Su círculo gris pulsante marca el radio de 1,25 longitudes de nave. Atrae módulos flotantes y fragmentos minerales para que los recojan los sistemas normales de inventario y bodega. El salvaging sigue siendo necesario para procesar los restos. El primer atraque manual marca cada estación en el mapa estelar y en el minimapa de su sector. Los campos `station_discovered` y `nacar_discovered` conservan los descubrimientos.

## Dreadnoughts de mayor tamaño

| Nave | Función prevista | Masa | Empuje | Casco | Longitud | Bodega |
|---|---|---:|---:|---:|---:|---:|
| Rorqual | Industria, minería y salvaging | 760 t | 19.300 kN | 1.950 | 242 | 780 U |
| Nyx | Portadrones y cazas | 580 t | 16.200 kN | 1.730 | 224 | 290 U |
| Chimera | Portadrones y cazas | 510 t | 15.000 kN | 1.550 | 210 | 280 U |
| Phoenix | Combate con futuras torretas y misiles | 690 t | 17.800 kN | 2.210 | 232 | 305 U |

Los cuatro tienen ranuras 5/3/3/2 de armamento/defensa/utilidad/motores y aceptan los módulos actuales. El Rorqual puede combinar varias herramientas de minería y salvaging. El lanzamiento de drones y cazas y las torretas siguen pendientes. Cada estación tiene un único puerto exterior para estos cascos. El puerto exterior se guarda con el índice 8. Si se cambia de tamaño en el hangar, al despegar se elige un puerto compatible.

## Mercados y botín

Los botones del hangar abren **Mercado Minería** y **Mercado Objetos**. Cada fila tiene una cantidad editable que se aplica al comprar o vender. La operación se ejecuta por el lote completo si hay saldo, existencias y espacio. Los campos se conservan por separado en ambos mercados. Los materiales comprados van al almacén del jugador y los objetos a una celda libre del inventario. Para vender un módulo equipado, devuélvelo a la cuadrícula. **Desequipar todo** libera las ranuras de la nave activa si hay espacio para todos sus módulos.

La economía inicial usa 500 Créditos, 20 unidades por material y dos módulos de cada tipo en stock. El Tractor Beam Tier0 cuesta 220 Créditos. La venta paga la mitad del precio de compra redondeada hacia abajo. Los mineros añaden al stock el tipo de mineral entregado. Cada módulo de un NPC destruido tiene una probabilidad independiente del 50 % de caer. Se recoge al acercarse si hay una celda libre.

Los campos `credits`, `mineral_stock`, `module_stock`, `module_drops`, `mineral_quantities` y `object_quantities` guardan la cartera, las existencias, el botín pendiente por sector y las cantidades de compra y venta. Las partidas antiguas reciben los valores iniciales y la reserva minera histórica se añade al stock de hierro.

### Estaciones, traders y piratas

Salvia y Nácar mantienen existencias independientes. Los precios minerales de cada estación se definen en `MINERAL_PRICES` y `NACAR_PRICES`. Por ejemplo, comprar hierro cuesta 8 Créditos en Salvia y venderlo en Nácar da 11. El trader de paso conserva su propio stock durante la visita y permite comprar y vender materiales con J.

`update_freight()` intenta generar una expedición cada 30 segundos de vuelo cuando no hay una en tránsito. Compra hasta ocho unidades del producto con mayor margen positivo disponible en la estación de origen. `route_edge()` encuentra la siguiente puerta mediante búsqueda en anchura. Al llegar a destino se abona el lote a sus existencias. Si el mercante es destruido, se pierde el lote. La partida guarda la expedición y las existencias de Nácar.

Las oportunidades de raid pueden incorporar uno o dos piratas. El tráfico inicial sólo crea minero y patrulla. Cada pirata prioriza al último atacante vivo, incluido el jugador. Al bajar del 40 % del casco, decide una sola vez si huye, con una probabilidad del 50 %.

## Persistencia y compatibilidad

El exportado guarda junto a su ejecutable. El editor resuelve la misma carpeta relativa a la raíz del proyecto Godot. Al arrancar y con **F9**, `load_game()` busca `savegames/godot/latest.json` y, si falta, el antiguo `user://sector.json`. **F5** sobrescribe el último guardado de esta edición. Para ensayar cambios en la carga, usa una copia de la partida o una ruta de prueba.

El JSON guarda nave, pintura, modo, motor, Coupled, estado de hangar, estación y puerto de atraque, casco y reserva minera de Salvia, posición, velocidad, orientación, casco, bodega, inventario, posiciones de módulos y sector activo. `crossed` conserva la máscara de los diez enlaces anteriores; `crossed_links` guarda una lista de índices sin límite de bits. Al cargar se combinan ambos registros. `fields` guarda filas `[vida, escaneado, progreso, x, y, minado, fundido]`; `sector_loot` guarda `[x, y, recurso, cantidad]`; `wrecks` guarda `[x, y, sprite, ángulo, progreso]`. Cada uno está agrupado por sector. Los campos históricos `field` y `loot` permiten leer partidas del sector único. Los NPC, los disparos y los efectos se reinician al cargar. Las partidas antiguas guardadas en el hangar se sitúan en un puerto de Salvia en el sector inicial; una partida antigua guardada en vuelo conserva la posición.

El campo `module_locations` guarda una posición por instancia de módulo. `module_types` guarda el tipo en el mismo orden y permite varios módulos del mismo tipo. Los índices 0–63 corresponden a la cuadrícula y los siguientes identifican las ranuras por nave, con cinco índices reservados por casco. Las partidas previas reciben los cuatro módulos en la cuadrícula.

El formato todavía carece de un campo explícito de versión. Al añadir estado, define un valor por defecto para partidas anteriores y prueba guardado/carga antes de publicar. El orden de asteroides, rutas, recursos, naves y sprites de restos tiene significado en partidas existentes. Si necesitas cambiarlo, añade una migración o identificadores estables.

## Regeneración de asteroides

`update_asteroid_respawn()` acumula tiempo de vuelo en `respawn_clock`. Cada 300 segundos selecciona al azar el 25 % de los asteroides minados de cada sector, redondeado hacia arriba, e intenta ubicarlos lejos de puertas, del centro y de otros asteroides. Durante los diez segundos de fundido se dibujan con opacidad creciente y mantienen la vida en cero. Recuperan la vida completa al terminar y vuelven a admitir impactos, escaneo y minería. Los guardados anteriores a esta versión carecen del indicador que distingue minería de destrucción por armas.

El minero viaja a 48 unidades/s, espera ocho segundos para buscar otro objetivo y aplica el láser durante 18 segundos para extraer.

## Continuar el desarrollo

1. Identifica el punto de entrada en la tabla anterior y reproduce el comportamiento en el editor antes de editar. Para un objeto con vida propia y parámetros ajustables, `missile.tscn` sirve de ejemplo.
2. Prueba el flujo que cambiaste y las transiciones cercanas. Para vuelo, comprueba deriva y frenado con el mismo casco. Para atraque, verifica despegue con Enter, rechazo del autoatraque fuera del puerto, alineado al mantener B desde un solape parcial y cancelación al soltar B antes de completar el segundo de confirmación. Para sectores, sal desde el inicial hacia **(0, −1250)**, cruza con **G**, guarda, vuelve a abrir y comprueba ruta y sector. Para carga, verifica un guardado anterior y uno nuevo. Para cambios visuales, revisa también el ejecutable exportado.
3. En cada release entrega los dos ejecutables numerados y actualiza `releases-godot.md`, `releases-c#.md` y esta guía. Añade un encabezado de nivel 2 con el número, el pedido y el trabajo realizado a cada historial, y registra las diferencias de verificación.

Escape cierra la pantalla superpuesta activa. El inventario tiene una cuadrícula de 8 × 8 con celdas de 38,4 unidades. El panel de Inventario ofrece cuatro módulos iniciales. La ametralladora, el cohete, el equipo de minería y el equipo de salvaging requieren una ranura de armamento de la nave activa. Los índices de utilidad empiezan en 256 con tres índices reservados por casco. El Tractor Beam Tier0 exige una ranura de utilidad. El vuelo y el giro forman parte del casco. El inventario de materiales que se descarga con U es independiente. El misil guiado usa el identificador de módulo 5 y cuesta 320 Créditos en ambas estaciones. Algunos piratas transportan uno y sueltan el módulo con un 50 % de probabilidad. Los módulos conservan el orden de sus identificadores para las partidas guardadas, mientras que las teclas se asignan en orden de ametralladora, cohete, misil, minería y salvaging. El minero lleva equipo de minería, los NPC de combate llevan ametralladora y el trader lleva las ranuras de armamento vacías. Quedan pendientes las órdenes a cazas y drones y los cascos de las clases futuras. La mayor parte de la lógica y del dibujo vive todavía en `game.gd`; al extraer un sistema a otra escena, comprueba sus coordenadas, su orden de actualización y sus efectos en la partida.



### Mejoras de motor y defensa automática

Los iconos blancos viven en `assets/modules`. Los sprites con sufijo `-world` se usan para el botín y la torreta PDC. El doble clic equipa en la primera ranura compatible libre. Thrusters (ID 6) y Gyro (ID 7) usan ranuras de motores y otorgan un 10 % aditivo por módulo. Thrusters aumenta empuje, velocidad máxima y frenada. Gyro aumenta la velocidad de giro. Cada mejora tiene una tirada independiente de botín del 20 % por NPC destruido.

PDC (ID 8) usa ranuras de defensa y se activa en vuelo. Cada estación tiene uno en cada punta. Los NPC actuales no montan PDC por defecto. Se reservan para futuras naves capitales. El PDC prioriza proyectiles entrantes, exige línea de visión y responde a atacantes recientes. Los cuatro cañones del PDC giran juntos sobre su base fija mientras hay una amenaza válida. La capa de cañones mantiene su último ángulo respecto al casco al perder el blanco. El PDC dispara hasta tres tiros por ráfaga mientras conserva un blanco válido. Dos impactos interceptan el cohete o misil sin aplicar su daño explosivo. Algunos piratas lanzan cohetes al jugador.

La persistencia conserva los rangos existentes de armamento y utilidad. Defensa empieza en 352 para las 24 naves originales y en 576 para los IDs 24 en adelante. Motores empieza en 448. Ambas categorías reservan cuatro posiciones por casco.

Raptor (ID 24) y Manticore (ID 25) son fragatas. Stratios (ID 26) es un crucero. La Manticore declara `double_ordnance` y lee `multiplicador_salva` de `ship-traits.txt`. El rasgo sólo afecta a cohetes y misiles.

### Raids, consola y selección

El tráfico inicial sólo crea minero y patrulla. La primera oportunidad de raid llega tras 45–120 segundos de vuelo. Las siguientes se evalúan cada 60–150 segundos, con un 55 % de probabilidad, sin crear otra raid mientras queden piratas vivos. Cada raid tiene una o dos naves y elige un objetivo entre sector/estación, minero, trader y jugador. Las naves responden a agresores y pueden retirarse. Tras 180 segundos, la raid se retira.

La tecla física inmediatamente sobre Tab abre la consola. `show_vectors 1` activa flechas de dirección de desplazamiento y longitud proporcional al empuje activo. `show_vectors 0` las oculta. Tab completa el comando por prefijo y las siguientes pulsaciones recorren las coincidencias. Con `show_vectors ` recorre los argumentos 0 y 1. El catálogo de comandos está en `CONSOLE_COMMANDS`. Las flechas conservan una longitud mínima visible aun sin empuje y, en reposo, toman el rumbo del casco. Los mercantes actualizan su velocidad con el desplazamiento de su ruta. La consola pausa la simulación mientras se escribe y Escape la cierra. El estado de depuración se mantiene durante la sesión.

El clic izquierdo selecciona entidades considerando el zoom. T elige la entidad más cercana entre naves, asteroides, estaciones, restos, recursos, módulos y puertas. Y quita la selección. El panel debajo del minimapa muestra nombre y clase de naves y, tras recibir el ping, casco actual/máximo, bodega y módulo instalado. En asteroides muestra casco estimado y los materiales con cantidades de extracción completa tras el escaneo.

### Escudos y panel de objetivos

El módulo Escudo tiene ID 9, ocupa defensa y cuesta 300 Créditos. Cada unidad instalada añade un 50 % del casco máximo como capacidad de escudo. El daño se enruta por `player_damage()` y `npc_hit()`, que consumen el escudo antes de aplicar el sobrante al casco. Cada impacto reinicia 10 s de espera, incluso con el escudo agotado. `update_shields()` regenera la mitad de la capacidad del escudo por minuto y limita la carga al máximo. La carga y la espera se guardan por casco. Desequipar y reequipar conserva la carga.

Los NPC tienen una tirada del 20 % de probabilidad para llevar un escudo y otra del 20 % para soltarlo al morir. Se añade al resultado del escaneo. El efecto dura 0,6 s tras absorber daño. `shield_sprite()` genera una textura a partir de la silueta alfa del sprite, con borde #2bfbf5 y un interior al 60 % de opacidad, equivalente a un 40 % de transparencia. El efecto comparte posición, escala y giro con la nave.

El panel de objetivo usa Segoe UI en negrita para encabezados y Consolas para datos.

### Continuidad del proyecto

Lee `../AI_LIGHTHOUSE.md` al comenzar una sesión y actualízalo con cada entrega o cambio de estado relevante. `../AGENTS.md` incorpora esta instrucción al flujo de trabajo. Los prompts reutilizables están en `prompts/crear-y-mantener-ai-lighthouse.md` y `prompts/usar-ai-lighthouse.md`. `facciones-propuesta.md` contiene una propuesta editorial pendiente de aprobación para su integración.

Cuando un impacto agota el escudo, un pulso blanco sobre la silueta indica la rotura durante 0,28 segundos. Es un estado transitorio. Se reinicia al cargar la partida y no se activa con impactos posteriores que sólo dañan casco.

### Módulo FTL

FTL usa ID 10 y ranura de utilidad. Cuesta 5.000 Créditos y alcanza tres enlaces por el camino mínimo del grafo, o nueve para Carrier con el rasgo long_ftl. El jugador debe estar en vuelo y abrir M. Un clic en un destino conocido solicita confirmación. Cancelar o Escape no consume carga. Confirmar inicia la salida, pone el cooldown a 300 s y vacía y bloquea el escudo durante 60 s. Tras el bloqueo vuelve la regeneración normal desde cero. El bloqueo se conserva al equipar otro escudo en ese casco. El cooldown es común al jugador y cambiar de módulo o nave no lo evita.

update_ftl() administra los tiempos y commit_ftl() cambia de sector al terminar la animación de salida. Se limpia el estado transitorio de combate y se elige una posición de llegada evitando estaciones y asteroides. Los enlaces de puertas no se marcan como cruzados por usar FTL. El guardado incorpora ftl_cooldown y lock en los estados de escudo. La entrada se bloquea durante la breve transición para evitar guardar un salto a medias.

Los traders de paso y los mercantes de ruta llevan FTL por defecto y lo sueltan con un 10 % de probabilidad al morir. Sus visitas y esperas respetan el cooldown. Las escoltas comparten la representación visual de la salida del trader. La animación usa una copia visual del modelo para representar su aceleración al abandonar el sector. La llegada usa un desplazamiento visual que se reduce rápidamente.

assets/effects/ftl-arrival-v2.png contiene seis celdas de 362 × 362 px. Es un recurso generado por IA e integrado con transparencia. El icono de inventario muestra FTL. El mapa continúa limitado a los sectores descubiertos.

La versión 0.0.54 usa ftl_frame() para suavizar el alfa de cada celda con una máscara radial antes de dibujarla. Los bordes quedan totalmente transparentes y los seis resultados se conservan en caché. El humo se desvanece progresivamente durante los últimos 0,25 s.

### Estaciones adicionales y autoatraque

station-attributes.txt admite campos adicionales al final de cada fila, layout y pivote X/Y normalizados. Las estaciones antiguas usan cross y pivote 0,5/0,5. BI usa bi y TRI usa tri. El astillero usa shipyard. El origen se sitúa en el núcleo visible del PNG para que los pares de la TRI sigan, en paralelo, el eje de cada ala. Los IDs de puerto normales empiezan en 0 y los Dread en 8.

Ícaro, sector 4109, tiene dos puertos normales y dos Dread. Tríada, sector 4110, tiene seis y tres respectivamente. Forja, sector 4111, tiene un puerto universal compartido por naves normales y Dread. Sus tamaños son 300, 340 y 420 unidades, con cascos 30.000, 36.000 y 55.000. Sus stocks y descubrimiento se guardan de forma independiente. El astillero queda preparado como localización para una futura compra de naves.

La colisión de las estaciones nuevas utiliza el alfa del sprite. clear_station_approaches() despeja los asteroides que ocuparían el espacio de estas nuevas estaciones y sus zonas de acceso, también al cargar una partida anterior.

update_auto_dock() busca un puerto compatible con solape real del casco, fija ese objetivo y dirige rumbo, frenada y centrado mientras B siga pulsada. La condición final conserva 90 % de cobertura, desviación máxima de 10° y velocidad de hasta 3. Requiere un segundo continuo dentro de esos márgenes. Soltar B cancela y reinicia la cuenta. Pulsar B con las condiciones ya cumplidas atraca inmediatamente. La cuenta de un segundo se aplica a la maniobra asistida al mantener B. El astillero tiene atraque operativo y la compra de cascos queda pendiente.

Los puertos capitales se seleccionan por claseID 4 o superior, incluidos los Dreadnought antiguos de menor longitud. En C# el estado adicional de las estaciones se conserva mediante SaveExtraStations/LoadExtraStations dentro de la economía guardada. En Godot se usa extra_stations.

### Editor independiente de estaciones · stationBuilder 1.3

`../tools/StationBuilder.cs` y `../build/build-station-builder.ps1` generan `stationBuilder-1.3.exe`, una herramienta Windows Forms para preparar recursos de estaciones destinados a Godot y C#. Consulta [stationBuilder.md](stationBuilder.md) para uso y formato.

Admite arrastrar PNG al lienzo, mover, girar, escalar, duplicar y ordenar capas. Permite situar un pivote y hardpoints de atraque normal, Dread y PDC. Los puertos miden 164 × 58 y 258 × 196 unidades respectivamente. Exportar PNG genera el sprite transparente y la ficha `.hardpoints.csv`. Guardar proyecto escribe por separado el diseño portátil `.station.json`. Las guías no forman parte del PNG.

Para integrar posteriormente una composición en Godot, utiliza el PNG y los datos de hardpoints, asigna ID y atributos de estación y adapta sus coordenadas al tamaño y pivote del juego. El CSV ampliado del editor no es una entrada directa del cargador actual. El proyecto JSON incorpora recursos originales y permite seguir editando sin depender de sus rutas. La compilación y `--smoke` pasaron con código 0; se revisó una imagen renderizada del editor con TRI. No se modificaron las estaciones ni las partidas actuales.

Desde 0.0.56, el doble clic izquierdo en un punto sin entidades limpia el objetivo. Un clic simple vacío conserva la selección. Los pares de puertos de la TRI son paralelos al eje de su ala. BI conserva sus centros y usa ejes norte/sur. Los atraques originales de Salvia y Nácar se conservan. El puerto universal de Forja usa ID 8 para ambas clases de nave.


Desde stationBuilder 1.1, la selección muestra esquinas para escala proporcional y un círculo exterior para giro. Los puertos y PDC seleccionados disponen del mismo control de giro. Un clic derecho abre al soltar un menú de eliminar y orden de capas; arrastrar con botón derecho mueve el plano con un umbral de cinco píxeles y no abre el menú. Se conserva el movimiento con botón central. Desde 1.2, el menú contextual ofrece copiar, pegar, duplicar y girar 90° para PNG y hardpoints. Los rombos permiten deformar los PNG en los ejes locales X e Y. El formato 2 guarda ambas escalas y el editor admite abrir el formato 1. La compilación y --smoke verifican las interacciones y los dos modos de guardado.

StationBuilder 1.3 admite grupos de PNG y hardpoints con Ctrl+clic. El arrastre, las flechas, el portapapeles interno y las operaciones del menú actúan sobre la selección. El formato editable sigue siendo el 2.

### Estación Cénit y sectores con varias estaciones

Cénit ocupa la fila de índice 5 de `station-attributes.txt` y pertenece al sector de índice 0 (4107). Está en (1.850, 1.250), tiene 42.000 puntos de casco, una masa de 22.000 t y un lienzo de 860 × 860 unidades con pivote central. Al incorporar nuevas estaciones, añade filas al final para conservar los índices que usan las partidas guardadas. El sector de una estación es un campo independiente de su índice.

El layout `custom` lee `estacion0.hardpoints.txt`, copia del CSV exportado por stationBuilder con extensión de texto para evitar que Godot lo importe como traducción. La ficha usa offsets del pivote, un píxel por unidad, y ángulos en grados horarios desde X positivo. Los puertos normales empiezan en 0 y los Dread en 8. Las dimensiones del CSV se aplican al dibujo y a las comprobaciones de atraque. Cada PDC conserva su posición y rotación y usa un identificador de estado que incluye el índice de estación.

Cénit tiene inventarios de minerales y módulos, precios de minerales, casco y descubrimiento propios. El estado usa la entrada correspondiente de `extra_stations`. Las partidas anteriores cargan la estación con el stock inicial. Los mercados adicionales admiten las once referencias de módulos, incluido FTL. En el minimapa se proyecta la posición de cada estación descubierta. En el mapa estelar los nombres se agrupan bajo su sector. El tráfico local elige estación por proximidad. Las comprobaciones de colisión por silueta descartan muestras que quedan más allá de la proa o la popa.

La flota 0.0.57 documenta las 27 naves a partir del catálogo. La imagen del mapa muestra los seis enlaces de la semilla 4107 y las posiciones iniciales de Salvia y Cénit.

### Catálogo de flota 0.0.58

Las naves 09 a 17 se llaman Leviatán, Mastodonte, Coloso, Alción, Azor, Centella, Bastión, Baluarte y Tempestad. Las tres últimas son Battleship (claseID 3) y usan 4 ranuras de armamento, 2 de defensa, 2 de utilidad y 2 de motores. Nyx y Chimera son las naves 22 y 23. Se conservan los IDs del catálogo y las posiciones de equipamiento ya existentes. Consulta la ficha de flota actualizada.

### Constelación del Imperio de Asterión

La región anterior contiene nueve sectores y diez conexiones; desde 0.1.9 forma parte de una red de 100 sectores y 116 conexiones. Los seis enlaces originales conservan su orden para mantener los bits de descubrimiento de partidas anteriores. Se añaden, en este orden, 4111–4112, 4112–4113, 4113–4115 y 4115–4114. La única puerta entre ambas regiones es 4111–4112. El FTL conserva sus requisitos de destino descubierto y distancia máxima. El escudo `assets/factions/asterion-crest.png` sustituye a los puntos de los cuatro sectores imperiales en el mapa de vuelo.

| Sector | Estación | Tráfico destacado |
|---|---|---|
| 4112 | Ciudadela Asterión, con astillero integrado | Tres guardias Stratios reforzados |
| 4113 | Meridiano, tipo BI | Patrulla Stratios y mercado |
| 4114 | Linde, tipo TRI | Patrulla Stratios y mercado |
| 4115 · Vesper | — | Patrulla Stratios, mercantes de tránsito y mayor actividad pirata |

La Ciudadela usa `station1.png` y `station1.hardpoints.txt` con los datos originales de stationBuilder. Tiene dos puertos normales, un Dread, cuatro PDC y 56.000 puntos de casco. El campo adicional `shipyard` del catálogo permite identificar el astillero integrado en el hangar. Los tres mercados de la constelación guardan sus existencias de forma independiente.

Cada puesto de guardia usa un índice estable de 0 a 2 y un contador de 1.800 segundos de simulación desde que su nave es destruida. El contador avanza aunque el jugador se traslade a otro sector o atraque. Godot persiste estos valores en `guard_wait` y C# los agrega al final de la economía. La capital vuelve a crear sólo las patrullas disponibles al cargar o entrar. Los refuerzos de las tres guardias son escudo de 75 % del casco y un 25 % más de velocidad y aceleración de patrulla. Desde 0.1.0, Vesper genera 3–4 piratas al entrar y revisa cada 10–18 s si debe enviar otra patrulla. Las naves en retirada permiten el relevo.

El destino de un mercante es un índice de estación. La búsqueda de ruta usa el sector que figura en esa estación. Los guardados anteriores que contienen cinco campos de asteroides, pecios y botín se leen por prefijo y los cuatro campos nuevos se inicializan normalmente. Consulta el [mapa 0.1.9](../lore/maps/mapa-estelar-0.1.9.png) para ver todos los enlaces.

### Flota del Imperio de Asterión

El catálogo tiene 35 naves (IDs 0–34). Su última columna, `faccion`, usa el valor `asterion` para Stratios (ID 26) y los ocho cascos nuevos. El PNG de cada casco se recortó al área visible con un píxel de margen transparente. Usa esos PNG desde shipConfigurator para editar anclajes. La ficha de flota detalla nombres, atributos, ranuras e IDs de hardpoints.

Ciudadela Asterión tiene seis puestos de patrulla. Los tres primeros mantienen las Stratios con refuerzos de escudo y propulsión. Los puestos 3 y 4 usan Alidada (ID 29, crucero1) y el 5 usa Eclíptica (ID 32, battleship1). Los tres refuerzos mantienen sus órbitas desarmados hasta cargar `nave,29,ametralladora,0,…` o `nave,32,ametralladora,0,…` respectivamente. Los tres contadores nuevos se inicializan a cero si se carga un guardado que sólo contiene los puestos de Stratios.

Los IDs de ranuras de las naves 0–26 se conservan. Desde el ID 27, la base es 1024 y cada casco reserva 16 posiciones. Los offsets de armamento, defensa, utilidad y motores son 0, 5, 9 y 12. La carga valida categoría, casco y ranura para ambos esquemas.

### Mercado y puertas desde 0.1.0

El FTL cuesta 5.000 Créditos por unidad y se vende por 2.500. Los botones de compra y venta ajustan la fuente al ancho disponible y muestran el precio unitario. Si no hay saldo, el mensaje de compra muestra el coste total de la cantidad solicitada y cuánto falta. Si no hay stock, muestra cuántas unidades quedan. En el caso reportado en Linde, la compra de un FTL con 713 Créditos falla por una diferencia de 4.287.

`assets/gates/jump-gate.png` es el sprite transparente de las puertas. Se dibuja a 134 × 134 unidades, centrado en su posición. El alcance de salto es 110 unidades desde el centro. La etiqueta en vuelo consulta el registro del enlace mediante `crossed_link` y resuelve el sector opuesto, por lo que indica un destino distinto según el extremo. El panel de objetivo muestra el destino incluso al seleccionar una puerta aún sin cruzar. Seleccionarla no cambia el descubrimiento del mapa.

Desde 0.1.1, el sprite de puerta es un anillo pixel art frontal con transparencia interior y exterior. Los catálogos marcan a Procurer, Retriever, Covetor y Rorqual con `no_ordnance`. Se comprueba al instalar módulos y al contar armas activas. Los guardados conservan los módulos ya montados para que el jugador pueda retirarlos.

Desde 0.1.2, Leviatán, Nyx, Chimera y Firmamento tienen el rasgo `no_direct_tools`. Carecen de anclajes de láser, ametralladora, minería y salvaging. El editor impide añadirlos y el juego bloquea el equipamiento y uso de los módulos correspondientes. La nave 24 se llama Phoenix y mantiene el ID 23. La [tabla actual](../lore/fleets/flota-0.1.9.md) recoge la flota completa. La imagen histórica 0.1.2 está en lore/fleets/.

Desde 0.1.3, el vuelo en el sector 4108 muestra `assets/backgrounds/nebula-4108.png` encima del campo de estrellas y debajo de la escena. La textura de 704 × 448 tiene una máscara irregular con alfa cero en el perímetro. Se dibuja sin repetición. Su ancla es (450, −320) y su desplazamiento toma el 18 % del movimiento de cámara. La posición en pantalla y el tamaño usan la raíz cuadrada del zoom para que la capa lejana cambie con suavidad.

Desde 0.1.4, el sector 4115 usa `nebula-4115.png`, una nube roja más intensa que comparte la proyección con el fondo de 4108. En la consola, `tp 4115` lleva a Vesper y `tp 4108` a Nácar. El comando reutiliza la entrada de sector del FTL para recolocar la nave y reconstruir la escena. La nave queda en vuelo, la consola sigue abierta y los destinos inexistentes no alteran el estado. Se conservan la recarga del FTL y el registro de puertas cruzadas.

## Distribución 0.1.5

Abre project.godot en la raíz. Godot guarda en savegames/godot/latest.json tanto desde el editor como desde el ejecutable en la raíz. Una copia independiente del ejecutable usa savegames/ junto al exe. Los textos de attributes/ y data/ se incluyen en la exportación mediante el perfil Windows Desktop.

## Fondos por sector desde 0.1.6

data/background-profiles.txt define ID, PNG, ancho, alto, ancla X, ancla Y y factor de paralaje. data/sector-backgrounds.txt asigna un perfil al número visible del sector. El perfil se dibuja en vuelo encima del campo estelar sin repetición y con bordes transparentes. Godot carga los dos catálogos en _ready y los incorpora al export mediante export_presets.cfg. Los sectores sin asignación usan sólo estrellas. Consulta [ambientes para futuros sectores](../lore/maps/ambientes.md) para ver los cuatro perfiles listos y las dos ideas pendientes.

En shipConfigurator 1.5, Ctrl o Mayús en Puntos colocados permite seleccionar varios y borrarlos con Supr o Borrar selección. La casilla Simular módulo de plataforma equipado muestra la huella de las plataformas en el editor. El rumbo de despegue se guarda como comentario CSV antes de la fila de la rampa, en grados horarios desde proa. Las rampas anteriores usan 0 grados hasta que se editen.

## Clases y compatibilidad de hangar desde 0.1.7

| Clase | claseID | Drones | Cazas de serie |
| --- | ---: | --- | --- |
| Fragata | 1 | Sí | No |
| Crucero | 2 | Sí | No |
| Battleship | 3 | Sí | No |
| Dreadnought | 4 | Sí | No |
| Carrier | 5 | Sí | Sí |
| Titán, futuro | 6 | Sí | Sí |

Carrier ocupa el mismo tramo de tamaño capital que Dreadnought y queda por debajo de Titán. La numeración visible y los IDs de nave siguen siendo independientes de claseID. Los IDs 8,21,22 y 33 pasan a Carrier. Sus IDs persistentes conservan el equipo y la bodega de partidas anteriores.

ship_allows_hangar controla los tipos hangar_cazas_* durante la lectura de fichas. El catálogo y los rasgos se cargan antes de los hardpoints. Los puntos incompatibles quedan en el archivo y el configurador los muestra como no compatibles, permitiendo conservarlos o borrarlos. El rasgo fighter_hangar, definido en attributes/ship-traits.txt con habilita_cazas=1, permite preparar una nave menor que admita cazas. Su asignación usa la columna traits del catálogo. La mecánica de lanzamiento, vuelo y recuperación está pendiente.

## Flota de Helión desde 0.1.8

SHIP_COUNT pasa a 46. Los IDs 35–45 añaden once sprites con prefijo helion- y facción helion en ambos catálogos. El nombre de facción aparece en el hangar y en el panel de objetivo. Las reglas de selección y persistencia se basan en el ID estable del casco. El direccionamiento por bloques de 16 desde el casco 27 admite los nuevos equipos y load_shields amplía los guardados anteriores con estados vacíos.

La [ficha de Helión](../lore/fleets/helion-0.1.8.md) relaciona los archivos originales, nombres, clases, atributos e IDs para shipConfigurator. Los hardpoints se configuran más adelante desde el editor vigente. Los sectores y los spawns existentes siguen definidos por la red y los roles actuales. El permiso de cazas de serie se limita a claseID 5 y 6, y fighter_hangar permite excepciones individuales.

## Cluster01 y mapa ampliado desde 0.1.9

`data/sectors.txt` contiene 100 filas ordenadas por ID: `id,name,map_x,map_y,ice,station,cluster,faction`. `data/sector-links.txt` define 116 parejas `from,to`. Las coordenadas son del diagrama, no posiciones de vuelo. Se exportan como datos de Godot y se integran como recursos de C#. La correspondencia de los 91 códigos nuevos está en [Cluster01](../lore/maps/cluster01.md).

Sólo 4110 conecta la red anterior con el clúster, mediante dos puertas nuevas. Conserva sus conexiones con 4107 y 4109. Los 17 sectores de hielo generan exactamente 512/640 asteroides con recursos 0/1, agua y metano; el resto contiene recursos 2–9. Las seis estaciones añadidas ocupan índices 9–14, tienen mercados propios y guardan su estado mediante extra_stations. Se conservan los índices anteriores, los guardados de nueve sectores y los diez primeros enlaces. Los nuevos sectores usan patrullas ordinarias sin asignación de facción; no heredan Stratios por tener un ID alto. Los mercantes pueden dirigirse a la estación del clúster más cercana por puertas, incluso en sectores sin estación.

Con M se centra el mapa en el sector actual. La rueda cambia el zoom alrededor del cursor y arrastrar con botón derecho desplaza el plano. Las estaciones se señalan con cuadrado, hielo con contorno azul y Asterión con su escudo. Se mantiene el descubrimiento progresivo. `tp CODIGO` y la dirección alternativa `tp 4116` son válidos; un destino inexistente no hace nada. Los códigos no muestran seguridad cero ni una facción inventada.

Carrier usa `long_ftl,multiplicador_alcance,3` en ship-traits.txt y el rasgo se asigna a los seis cascos de clase 5. El alcance se calcula a partir del módulo actual (3 × 3 = 9), conserva destino conocido, módulo de utilidad equipado, confirmación, cooldown y consecuencias de escudo. Titán y otras clases mantienen 3 salvo un rasgo explícito futuro.

La búsqueda de rutas y el registro de sectores conocidos usan conjuntos/diccionarios, sin máscaras de sector. Godot añade crossed_links al JSON; C# añade una línea 26 con los índices cruzados, sin desplazar las 25 líneas anteriores. Las partidas antiguas inicializan los campos y mercados nuevos. Pruebas: `--smoke` en C# y `--headless --path . --script build/test-cluster.gd` en Godot con un APPDATA temporal; el test usa user://cluster-regression.json y no toca savegames/. El [PNG del mapa](../lore/maps/mapa-estelar-0.1.9.png) se regenera con build/render-star-map.ps1.

## Materiales e industria desde 0.1.10

El catálogo compartido está en data/materials.txt (CSV: id,key,name,category,stage,price). IDs 0–9 se mantienen. Tungsteno, cromo, cobalto, magnesio y molibdeno usan 10–14; seis especiales ficticios, 15–20. Tierras raras sigue ID 9 y pasa a especial. IDs 21–41 son los refinados; 42–70, gases y componentes de procesamiento/fabricación. Hay 71 materiales y 50 recetas en data/recipes.txt (id,key,name,stage,inputs,outputs). Cada lista usa id:cantidad separada por |. Las recetas secundarias sólo consumen productos procesados. Las cantidades son unidades abstractas y las pérdidas no crean residuos todavía.

Godot/industry.gd carga el catálogo y la pantalla; game.gd consume sus nombres/precios y funciones. csharp/Industry.cs forma una clase parcial con Game.cs y build/build-csharp.ps1 compila ambas. Los dos txt se incluyen en los exportadores. No usar extensión csv aquí: el importador predeterminado de Godot la interpreta como traducciones.

En estación, botón Industria o F abre recetas y materiales. U descarga la bodega. Selecciona receta y fabrica 1/10 lotes. Hay paginación y rueda. Se validan ingredientes y límites de salida antes de consumir, usando el inventario descargado y sin coste/tiempo por ahora. Chips, casco, motores, sensores, matrices y núcleos son componentes de inventario para ensamblaje futuro; no producen naves ni módulos equipables. Agua y gases tampoco activan aún sistemas de combustible o soporte vital.

Cada inicio/carga redistribuye 3–7 trazas en asteroides vivos por sector, con 1–3 U de un especial. Si quedan menos asteroides, se limita a los disponibles. No se persisten las trazas ni su revelación, pero sí lo recogido y los fragmentos. TAB normal no muestra el especial; al minar sale un fragmento adicional y se vacía la traza. El respawn no repone trazas, ni cambiar de sector/usar FTL/guardar. NPC mineros pueden agotar la traza de su asteroide sin premiar al jugador. El módulo raro Detector de trazas ID 11, de utilidad, habilita la revelación de la traza con TAB incluso si el asteroide ya estaba escaneado. Su stock y distribución son cero; no está disponible en juego normal todavía.

Las composiciones ordinarias excluyen todos los especiales y productos industriales. Los campos de hielo conservan exactamente 512/640 asteroides de agua/metano; las trazas son adicionales. Salvaging mantiene IDs 5,2,4,3 (cobre,hierro,titanio,aluminio), 3/5/7 U por resto. Los mercados de materiales y módulos se paginan en once filas para mantener accesibles todos los recursos y el módulo nuevo.

Los inventarios, bodegas, stocks y cantidades se amplían conservando los prefijos antiguos de diez materiales. El módulo detector se añade al final con stock cero, también al cargar partidas antiguas. C# acepta ahora las 26 líneas de 0.1.9 y conserva los índices de las 25 previas. Su --smoke usa un archivo temporal al comprobar guardado/carga, sin tocar partidas reales.

La [guía industrial](../lore/industry/materiales-y-crafting.md) incluye categorías, lore de los especiales, las 50 recetas, límites de realismo y pendientes. [Tabla PNG](../lore/industry/crafting-0.1.10.png), regenerable con build/render-crafting.ps1. Pruebas: build/test-industry.gd, build/test-cluster.gd y --smoke en C#. build/preview-industry.gd permite revisar la interfaz con una partida temporal user://.

## Etapas y eficiencia desde 0.1.11

El estado vigente del catálogo es 23 brutos / 36 procesados / 29 componentes, 88 IDs y 65 recetas. «Refinado» es el primer tratamiento; el resultado es un material «procesado», que puede transformarse otra vez o entrar en fabricación. Gases, aleaciones, vidrio, cerámica, barras, cables y refrigerante dejan de compartir la etiqueta de componente. El ID 60 se llama Piezas de construcción. Se preservan todos los IDs previos. 71/72 son tritio/xenón; 73/74, los purificados; 75–87 añaden los componentes del esquema acordado.

La generación añade combustibles escasos en un 1 % de asteroides elegibles, equiprobables entre tritio y xenón; en campos de hielo sólo participa el 20 % no reservado a agua/metano. Por ello siguen siendo escasos en hielo y no se rompe el 512/640 de agua/metano. Son composición ordinaria visible por TAB, distinta de los especiales ocultos. La composición es determinista por sector, sin stock inicial. rarity, séptima columna de materials.txt, permite distinguir comun/escaso/oculto al inicializar mercados.

Las recetas especifican producción de diseño, sin porcentajes de máquina. El refinado aplica 95 % de recuperación general y después la eficiencia de refinería; los otros procesos sólo aplican la eficiencia de fabricación. attributes/station-industry.txt define station,refining_percent,fabrication_percent por índice de estación; todas usan 80/80. Si falta una fila, se usa 80/80, y los valores se limitan a 0–100. Servicio a 0 % no consume ingredientes. La mejora por módulos será futura. Diez U de cobre: 10×0,95×0,80=7,6 U; al 100 %, 9,5 U.

La producción usa enteros con escala 10000 para evitar pérdida de decimales. El saldo fraccionario del jugador es por material y global, como el inventario actual. Las unidades completas van al inventario; el resto queda en industry.remainders/industryRemainders. Se muestra el total en Materiales y se indica que sólo unidades completas se consumen o venden. Para componentes, 0,8 representa progreso parcial de un lote. Agrupar o dividir lotes no cambia el rendimiento. Los ingredientes y el límite de inventario se validan antes de alterar inventario/saldos.

Godot añade industry_remainders al JSON. C# añade una línea 27 de saldos, conserva las 26 anteriores y acepta los formatos previos. ReadAmounts admite el prefijo histórico de 71 materiales, además del de diez. Los productos/saldos nuevos empiezan a cero. El módulo detector y el salvaging conservan su comportamiento. Ambos exportadores incluyen station-industry.txt.

Los componentes fabricados no alteran hardpoints, ranuras ni capacidad de cazas. Las futuras recetas de fragatas no pedirán Bahía de hangar. Ensamblaje final de naves/estaciones/módulos y artefactos siguen pendientes. Servicio sin tarifas, tiempos ni consumo de energía en esta fase. [Tabla PNG vigente](../lore/industry/crafting-0.1.11.png); guía completa y tablas en lore/industry/materiales-y-crafting.md. La imagen muestra producción teórica tras recuperación y producción efectiva al 80 %.

## Corrección de eficiencia desde 0.1.12

Sólo Refinado aplica recuperación95 % y eficiencia de refinería (80 % inicial). Procesado/fabricación y cualquier futura etapa Ensamblaje devuelven100 % de su producción de diseño, sin consultar la eficiencia de fabricación de estación. La columna histórica fabrication_percent se conserva a100 en atributos; el código también ignora valores antiguos80/0 para estas etapas. La refinería a0 no bloquea fabricar. No se eliminan ni redondean saldos anteriores de materiales o componentes. Las fracciones nuevas se generan sólo al refinar. Las tablas de ensamblaje final siguen pendientes, sujetas a la regla100 %. Imagen vigente: lore/industry/crafting-0.1.12.png. Pruebas actualizadas con componentes enteros y electrólisis sin pérdidas después del refinado.

## Salvaging futuro vinculado a cada nave

Decisión confirmada, pendiente de implementación: recuperar componentes o materiales refinados según los componentes de la nave destruida y los requeridos para su construcción. Se definirá al asignar componentes a cada nave. No hay cantidades/probabilidades acordadas. El salvaging actual de 0.1.12 permanece operativo hasta esa tarea; no cambia el botín directo de módulos.

## Ambientes completos desde 0.1.13

Hay ocho familias de ambiente y 100 asignaciones: Arco de gas16, Velo de polvo11, Límite planetario5, Remanente de supernova10, Aurora solar18, Vacío profundo19, Nube criogénica17 y Tormenta iónica4. Esos totales incluyen Nácar y Vesper como variantes históricas; técnicamente hay diez perfiles. Los cuatro PNG nuevos generados con imagegen están en assets/backgrounds, con revisiones v2 para solar/cryo y borradores ignorados en drafts. No cambia la simulación ni el progreso guardado.

background-profiles.txt acepta siete u ocho columnas. La octava es opacity (0–1); el valor por defecto de perfiles anteriores es1. Godot aplica modulación alfa y C# una ColorMatrix a la imagen. Las dimensiones/anclas, paralaje y sqrt(zoom) permanecen. Se superpone una única imagen transparente al campo estelar, sin tiling de nubes. sector-backgrounds.txt usa direcciones4107+ID, incluso para sectores con código alfanumérico. Los cien sectores tienen una fila estable; las partidas antiguas toman las nuevas asignaciones al cargar.

background-types.txt es metadato editorial de nombres/familias/colores para el mapa y el catálogo, no añade reglas de juego. render-ambiences.ps1 dibuja la lámina con estrellas/opacidad; render-star-map.ps1 añade la leyenda y banda de color por sector. Ver lore/maps/ambientes.md, mapa-estelar.md, bocetos-ambientes-0.1.13.png y mapa-estelar-0.1.13.png. Prompts completos en lore/maps/prompts-ambientes-0.1.13.md.

Pruebas: test-backgrounds.gd comprueba todas las asignaciones, los ocho tipos, los campos de hielo, Nácar/Vesper y alfa de bordes. preview-backgrounds.gd renderiza escenas reales para los ocho tipos; C# --smoke también renderiza ocho perfiles. Para no tocar partidas, los scripts Godot usan save_path temporal y APPDATA/LOCALAPPDATA aislados. Al exportar, conservar los recursos de fondos en resources.rsp de C# y los txt incluidos por Godot.

## Compatibilidad de atraques desde 0.1.16

docking_ports/DockingPorts ofrece únicamente puertos con cobertura centrada≥90 % y sin colisión en casco/pasillo exterior. Las clases menores que Dread prefieren normales y recurren a capitales compatibles si es necesario. Las capitales mantienen su categoría. uses_capital_port/UsesCapitalPort considera también la envolvente real para puertos estándar. Ocaso (Battleship,ID41) necesita puerto capital en las estaciones actuales porque mide67deancho, frente a58normal:86,57 % máximo. Un normal personalizado más ancho puede admitirla. No se cambian clase/atributos ni dimensiones del puerto.

La selección, visualización, pulsaciónB y autoatraque comparten la lista. Se conserva velocidad3,alineación10°,cobertura90 % y el funcionamiento al mantener/soltarB. dock_at/DockAt remapea puertos guardados incompatibles y protege listas vacías. Compatibilidad en caché por nave/estación, transitoria; invalidarla si se implementa recarga/edición de geometría durante el vuelo.

ship_overlaps_station/ShipOverlapsStation se comparte entre colisión y comprobación de puerto. Los cinco puntos longitudinales del pasillo se comprueban con la envolvente alineada y la colisión de estación. En Godot, get_image().duplicate() antes de redimensionar/rotar evita modificar la imagen compartida. Cénit conserva máscara860×860 en lugar de la copia256×256 usada para el hangar, eliminando colisiones falsas. Se aplica también a cielo, rotación de casco y escudo.

La batería de C# compila Game.cs,Industry.cs y DockingChecks.cs. test-docking.gd y --smoke cubren46×15combinaciones,5.300atraques manuales en ambos sentidos y690automáticos, además de puertos personalizados, remapeo y lista vacía. Ver lore/fleets/atraques-0.1.16.md para la tabla de flota y causas. audit-docking.gd genera un informe de incompatibilidades actuales. Se usan partidas temporales para pruebas.

## Estadísticas del sector · 0.1.16

En la consola (º), `sector_stats 1` activa un panel en la parte superior derecha, a la izquierda del minimapa. `sector_stats 0` lo oculta. Tab completa el comando y alterna 0/1. El panel muestra el nombre del sector actual, el número y los nombres de todas sus conexiones (incluidas las no exploradas), los NPC vivos presentes y el identificador exacto del perfil de fondo asignado. Se actualiza al cambiar de sector o cambiar el tráfico. Incluye los mercantes presentes en la lista de NPC; excluye jugador, estaciones y restos. Es una opción de depuración desactivada al arrancar y no se guarda en la partida.

## Criogenia · 0.1.16

Consulta lore/maps/criogenia.md: 17 sistemas de hielo, ralentización de velocidad 10–80 %, exposición por nave/visita y utilidad Boreal ID 12. Guardado Godot añade cryo_seconds al JSON; C# añade línea 28 opcional y noveno campo a la ruta mercante, aceptando formatos anteriores. Catálogos de módulos crecen de 12 a 13 sin desplazar IDs. Icono boreal.svg en Godot y equivalente C# nativo. C# compila también csharp/Cryogenic.cs. Las máscaras de escarcha se generan una vez por sprite y se modulan al dibujar, sin alterar colisiones. build/test-cryogenic.gd, build/preview-cryogenic.gd y C# --smoke cubren la funcionalidad. documentation/pendientes.md registra las seis fichas añadidas a In progress.

## Exploración y prospección · 0.1.17

Nueva implementación compartida en Godot/survey.gd y csharp/Survey.cs, compilado con los otros cuatro archivos de C#. Datos: background-layers.txt y asteroid-materials.txt. Estación Umbral índice 15/sector 29; 16 estaciones. Módulo de utilidad espectrómetro ID 13, 2.600 créditos; se activa al completar TAB y muestra snapshot de reservas sin ubicaciones. El informe pausa el juego y queda por encima del HUD debug. Gigantes en los índices 620,624,628,632 según sector%3: 2–4 por sector; radio 150–240 y piezas de mineral por tamaño. El resto de materiales y el ciclo de especiales no se alteran.

Persistencia: geology_version=1 en JSON Godot y línea 29 opcional en C#. Al leer guardados anteriores, se conserva el estado minado/salud, pero no se reutiliza una posición de asteroide pequeño para un índice promovido a gigante. En versiones nuevas se conserva su posición. Espectrómetro aumenta catálogos de módulos de 13 a 14; lectores admiten prefijos anteriores. Nuevos datos y sprites se incluyen en ambos ejecutables. Ver build/test-survey.gd, build/preview-survey.gd y C# RunSurveySmoke; regenerar mapa con build/render-star-map.ps1 -Version 0.1.17. Reglas, láminas y notas en lore/maps/exploracion-0.1.17.md.

El perfil de exportación incluye explícitamente data/background-layers.txt y data/asteroid-materials.txt. _ready verifica sus diez perfiles de capas y los 23 sprites para detectar catálogos ausentes en una distribución.
