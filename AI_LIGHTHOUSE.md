# AI_LIGHTHOUSE · Hangar Orbital

Actualizado el 12 de noviembre de 2026. Estado de entrega: juego Godot y C# 0.1.6, shipConfigurator 1.5 y stationBuilder 1.3.

## Propósito y mantenimiento

Esta guía permite que otra IA continúe sin reconstruir todo el chat. Lee primero AGENTS.md, este archivo y las instrucciones superiores aplicables. Verifica el código antes de asumir que el texto sigue vigente.

Actualiza esta guía con cada entrega y cada cambio relevante de decisiones o estado. Sustituye la información obsoleta. Registra hechos comprobados, verificaciones, pendientes y el siguiente paso concreto. La conversación más reciente del usuario puede actualizar prioridades. El detalle histórico pertenece a los historiales de releases.

## Retomar el proyecto en otro equipo

1. Abre en Codex la carpeta de trabajo que contiene juntos AGENTS.md, AI_LIGHTHOUSE.md y project.godot. Esa carpeta es la raíz de NavePrototype. Lee AGENTS.md, esta guía y [la documentación de Godot](documentation/doc.md). Comprueba qué archivos y versiones tienes antes de continuar. Las rutas de esta guía son relativas a esa raíz y puedes usar cualquier ubicación local.
2. Traslada el árbol de código y recursos completo, incluidos build/, tools/, Godot/, csharp/, assets/, attributes/, data/, lore/ y documentation/. Conserva los archivos .uid, .import y .gdignore. Godot regenera .godot/ al importar. Las plantillas de exportación y el ejecutable del motor se instalan en el equipo nuevo.
3. Si vas a conservar el progreso, copia por separado savegames/godot/latest.json y savegames/csharp/latest.txt. .gitignore excluye las partidas, los ejecutables y la caché del editor. Si partes de una copia de GitHub, comprueba su alcance: la copia usada hasta ahora para GitHub Desktop se ha mantenido como copia de Godot. Para trabajar en las dos ediciones y los dos editores, parte del árbol completo de NavePrototype.
4. En Windows, instala Godot 4.5.1 estándar y sus plantillas de exportación de la misma versión. Importa project.godot desde la raíz y arranca con F5 en el editor. Para C# y las herramientas, comprueba que existe %WINDIR%/Microsoft.NET/Framework64/v4.0.30319/csc.exe. Los scripts de build/ usan ese compilador y las bibliotecas de Windows Forms.
5. Ejecuta las comprobaciones de la sección «Compilar, verificar y entregar». Si los binarios se trasladaron aparte, los vigentes en la raíz son HangarOrbital-Godot-0.1.6.exe, HangarOrbital-CSharp-0.1.6.exe, shipConfigurator-1.5.exe y stationBuilder-1.3.exe. El directorio releases/ guarda las versiones sustituidas.

**Punto de continuación.** Los cuatro ambientes nuevos están empaquetados. Cuando se añada un sector, asigna un perfil por su número visible en data/sector-backgrounds.txt. Para retomar los hangares, el editor ya guarda los puntos y el rumbo de las rampas, y sigue pendiente consumir esos datos en el juego para desplegar y recuperar cazas o drones. Sigue la siguiente petición del usuario para elegir cuál de estas líneas continuar. Al retomar la interfaz, recuérdale las barras de escudo.

**Texto para el chat nuevo.** «Continúa Hangar Orbital desde la carpeta abierta. Lee AGENTS.md y AI_LIGHTHOUSE.md, verifica la versión disponible y usa esa guía para retomar el proyecto. Mantén Godot y C# al día y conserva los guardados independientes. La siguiente tarea es: [describe aquí el cambio].»

## Objetivo y preferencias del usuario

Juego espacial cenital de escritorio para Windows, con sprites detallados de estilo pixel art, naves equipables, sectores procedurales y persistencia. El usuario quiere resultados ejecutables y explicaciones claras.

Se mantienen dos ediciones con funciones equivalentes.
- Godot 4.5.1 estándar, GDScript.
- C# con Windows Forms y compilador .NET Framework de Windows.

Incrementa el número de release en ambas al modificar el juego, genera ambos ejecutables e informa de diferencias o problemas comprobados. Cada entrega actualiza los historiales, doc.md y esta guía. Doc.md detalla la arquitectura de Godot. Los editores shipConfigurator-1.5 y stationBuilder-1.3 tienen numeración independiente. Una entrega que sólo modifica una herramienta no requiere recompilar ni renumerar el juego.

shipConfigurator 1.4 añade la familia de hardpoints hangar: tubo lateral, rampa longitudinal y plataforma, para drones en todas las clases y para cazas en claseID 4 y 5. El editor aplica la regla a cada casco del catálogo, incluidos los futuros. Las fichas usan el CSV de seis columnas. El despliegue, la recuperación y las compuertas quedan pendientes de integración en el juego.

## Archivos principales

Las rutas siguientes son relativas a NavePrototype.

| Ruta | Uso |
|---|---|
| project.godot y Godot/main.tscn | Proyecto y escena inicial. |
| Godot/game.gd | Simulación, entrada, interfaz, NPC y persistencia. |
| Godot/missile.gd y missile.tscn | Cohetes y misiles, guiado, colisiones y explosión. |
| csharp/Game.cs | Edición C#, incluida la batería --smoke. |
| build/build-csharp.ps1 y build/resources.rsp | Compilación y recursos integrados de C#. |
| attributes/ships-godot.txt | Atributos y PNG de las naves de Godot. |
| attributes/csharp/ships-csharp.csv | Catálogo equivalente de C#. |
| attributes/ship-traits.txt | Parámetros de rasgos, compartidos con C#. |
| data/hardpoints/ship<ID>.txt y data/hardpoints.txt | Anclajes de naves y estaciones. |
| assets/ships/ | Sprites compartidos por ambas ediciones. |
| assets/modules/ | Iconos, sprites y capas del PDC. |
| documentation/doc.md | Arquitectura de Godot y controles. |
| documentation/releases-godot.md y releases-c#.md | Versión bajo título de nivel 2, pedido y trabajo realizado. |
| documentation/prompts/ | Prompts reutilizables de continuidad. |
| lore/factions/facciones-propuesta.md | Dossier editorial de las seis facciones. |
| tools/StationBuilder.cs y build/build-station-builder.ps1 | Editor independiente de estaciones; compila stationBuilder-1.3.exe. |
| documentation/stationBuilder.md | Uso, formatos exportados y verificación del editor de estaciones. |

La copia de GitHub Desktop y la carpeta de trabajo cumplen funciones distintas. Si el usuario pide actualizar GitHub, comprueba la ruta de su copia local en el equipo actual y copia allí los archivos de la edición Godot. El usuario prepara y ejecuta el commit y el push.

## Estado funcional

Hay 35 naves, IDs 0–34. Fragata es claseID 1, Crucero 2, Battleship 3 y Dreadnought 4. Cazas/drones reservan claseID 0 y Titán 5 queda pendiente. Preserva los IDs y la orientación de proa. Raptor es ID 24, Manticore 25 y Stratios 26.

Manticore tiene double_ordnance, que duplica salvas de misiles y cohetes. Rorqual tiene gimbal_miners y long_miner. Respeta los rasgos y los hardpoints definidos por el usuario.

Están operativos vuelo coupled/decoupled, minería, salvaging, bodega, inventario, mercados, Créditos, tractor, colisiones, cohetes, misiles guiados, escaneo, selección, sectores y puertas. Las estaciones son Salvia y Cénit en 4107, Nácar en 4108, Ícaro en 4109, Tríada en 4110 y Forja en 4111. Consulta doc.md y el código para los valores vigentes.

El tráfico empieza con minero y patrulla. Los NPC actuales no equipan PDC de fábrica. Las raids tienen una o dos naves. La primera oportunidad llega tras 45–120 s, las siguientes cada 60–150 s con 55 % de probabilidad y sin otra raid viva. Sus objetivos pueden ser sector/estación, mineros, traders o jugador.

## Módulos y persistencia

IDs de módulos estables.
- 0 ametralladora, 1 cohete, 2 minería, 3 salvaging.
- 4 tractor, 5 misil, 6 Thrusters, 7 Gyro, 8 PDC, 9 Escudo, 10 FTL.

Se equipa por arrastre o doble clic. Thrusters añade 10 % de empuje, velocidad máxima y frenada por módulo. Gyro añade 10 % de giro. PDC intercepta con dos impactos y usa ráfagas de tres tiros. Sólo articula sus cañones cuando se defiende. Cada estación lleva cuatro PDC.

Escudo añade 50 % del casco máximo por módulo de defensa. El daño consume escudo y el sobrante afecta al casco. Regenera 50 % de su capacidad por minuto tras 10 s sin daño. El efecto sigue la silueta alfa y usa #2bfbf5, con 40 % de transparencia interior. Al agotarse activa un pulso blanco de 0,28 s. Carga y espera se guardan por casco. El destello es transitorio. Los NPC tienen 20 % de probabilidad de llevar escudo y, si lo llevan, 20 % de soltarlo.

Las partidas son independientes.
- savegames/godot/latest.json.
- savegames/csharp/latest.txt.

Ambas ediciones cargan su último guardado. Conserva la compatibilidad. Los índices de equipamiento codifican nave, categoría y hueco. Armamento empieza en 64, utilidad en 256, motores en 448. Defensa usa 352 para los IDs 0–23 y 576 para los IDs 24–26. Para los IDs 27 en adelante se reservan 16 posiciones por casco desde 1024, con offsets de categoría 0, 5, 9 y 12. Cambiar rangos puede corromper equipamiento guardado.

## Controles que se deben preservar

W/S empuje/freno longitudinal, A/D lateral, Q/E giro, X frenada y C coupled/decoupled. Rueda para zoom. Mayús + rueda u O/L ajusta minería. Las teclas numéricas asignan los tipos de armamento equipados sin huecos. Espacio usa el tipo seleccionado.

T elige la entidad más cercana. Clic izquierdo selecciona, Y deselecciona y TAB emite ping. M abre mapa, H ayuda y Escape cierra pantallas. B atraque, Enter despega. Inventario y mercados usan botones del hangar. El trader sólo comercia con materiales de la bodega activa.

La tecla física sobre Tab, º en el teclado del usuario, abre la consola. show_vectors 0/1 controla las flechas de todas las naves. Tab completa y recorre coincidencias y valores. Con un solo comando registrado, el nombre completado se repite. La consola pausa la simulación. Las flechas conservan una longitud mínima y siguen el rumbo del casco en reposo.

## Compilar, verificar y entregar

Desde la raíz del proyecto, en PowerShell.

~~~powershell
& ./build/build-csharp.ps1 -Version 0.1.6
Start-Process -FilePath (Resolve-Path 'HangarOrbital-CSharp-0.1.6.exe') -ArgumentList '--smoke' -WindowStyle Hidden -Wait -PassThru
~~~

Sustituye la versión en próximas entregas y comprueba el ExitCode. Se usa el csc.exe de Microsoft.NET/Framework64/v4.0.30319. Las pruebas que exigen resultados deterministas deben controlar los atributos aleatorios.

Para Godot, configura la variable $godot con la ruta del ejecutable de consola de Godot 4.5.1 en el equipo actual. Desde la raíz:

~~~powershell
& $godot --headless --path . --editor --import
& $godot --headless --path . --quit-after 15
& $godot --headless --path . --export-release "Windows Desktop"
~~~

Comprueba $LASTEXITCODE y revisa la salida en busca de ERROR o SCRIPT ERROR. Actualiza la versión visible en csharp/Game.cs y Godot/game.gd y el destino de export_presets.cfg al preparar otra entrega. Para recompilar los editores, usa ./build/build-ship-configurator.ps1 y ./build/build-station-builder.ps1. Los binarios, motores y registros de verificación que quedaron en rutas temporales del equipo anterior se pueden regenerar localmente.

Los entregables son HangarOrbital-Godot-<versión>.exe y HangarOrbital-CSharp-<versión>.exe, en la raíz, junto con las versiones vigentes de shipConfigurator y stationBuilder. Cuando se sustituya uno de los cuatro ejecutables, mueve su versión anterior a releases/. Preserva los guardados reales. Las comprobaciones de Godot de sesiones anteriores viven en carpetas temporales y pueden faltar. Usa partidas aisladas para pruebas y distingue verificación de lógica de revisión visual.

## Última entrega y verificación

0.1.6 comparte los perfiles de cielo entre Godot y C# en data/background-profiles.txt. data/sector-backgrounds.txt los asigna por número visible. Los perfiles nuevos gas-arc, dust-veil, planet-limb y supernova-remnant están listos para futuros sectores. Nácar y Vesper mantienen sus perfiles. lore/maps/ambientes.md documenta los seis conceptos y deja Vacío profundo y Aurora solar pendientes. C# superó --smoke. Godot exportó, arrancó en headless y comprobó los seis enlaces de sector y perfil con una asignación temporal de los cuatro fondos nuevos. Los PNG nuevos tienen el perímetro transparente.

0.1.5 abre el proyecto Godot desde la raíz de NavePrototype. Los gráficos de ambas ediciones comparten assets/, los catálogos viven en attributes/, los hardpoints y sectores en data/ y los documentos de ambientación en lore/. Los cuatro ejecutables vigentes están en la raíz y los dos juegos mantienen sus guardados en savegames/ en la raíz. shipConfigurator 1.3 lee assets/ships y attributes/ships-godot.txt y escribe en data/hardpoints/. C# superó --smoke, Godot exportó y arrancó en modo headless, y ambos editores superaron sus pruebas internas.

0.1.4 añade nebula-4115.png para Vesper. La consola acepta tp seguido del número visible de sector. La nave entra en vuelo y el comando mantiene la recarga FTL y el historial de puertas. Un destino inexistente no modifica la escena.

0.1.3 añade un fondo piloto en vuelo sólo para 4108 (Nácar). nebula-4108.png es una nube azul de alfa gradual que se dibuja encima de las estrellas en ambas ediciones, con paralaje y sin repetir la textura. La inspección visual comparó tres posiciones y dos niveles de zoom.

0.1.2 añade no_direct_tools a Leviatán, Nyx, Chimera y Firmamento. Sus fichas activas carecen de láser, ametralladora, minería y salvaging, y shipConfigurator 1.2 impide añadir esos tipos. La nave 24 ahora se llama Phoenix (ID 23). Ficha e imagen en lore/fleets/.

0.1.1 sustituye la puerta por un anillo pixel art frontal. shipConfigurator 1.1 muestra los motores como puntos sin límite y su prueba coloca, guarda y recarga seis motores en un casco con dos ranuras de armamento. El rasgo no_ordnance impide instalar y disparar cohetes y misiles en Procurer, Retriever, Covetor y Rorqual. El equipo anterior incompatible sigue disponible para desmontarlo.

0.1.0 corrige el recorte de precio del FTL. El coste es 5.000 Créditos y con 713 faltan 4.287. Las compras avisan por separado de falta de stock o saldo. Vesper tiene 3–4 piratas desde la entrada y repone la patrulla en el siguiente control de 10–18 s si quedan sólo piratas en retirada o ninguna nave. Las puertas usan jump-gate.png y muestran su destino en el panel de objetivo al seleccionarlas. Una vez cruzadas, su etiqueta en vuelo muestra el sector opuesto. Se preserva el bit de descubrimiento del enlace.

0.0.60 añade ocho cascos imperiales con transparencia y afilia Stratios a Asterión. Ciudadela Asterión recibe dos Alidada (ID 29) y una Eclíptica (ID 32). Los refuerzos quedan desarmados hasta definir el hardpoint de ametralladora 0 en sus fichas. Los IDs nuevos 27–34 usan direcciones de equipo independientes del esquema antiguo. La tabla flota-0.0.60.md indica los nombres e IDs para editar hardpoints en shipConfigurator. Se comprobaron ambas ediciones y se verificó que Godot activa el arma cuando existe su anclaje.

0.0.59 incorpora Asterión (sectores 4112–4115), con una única puerta exterior entre 4111 y 4112. El FTL usa las reglas habituales. Se conservan los seis índices de enlace originales y se amplían los datos por sector a nueve. Ciudadela Asterión (índice de estación 6, sector 4112) tiene astillero, dos atraques normales, uno Dread y cuatro PDC. Meridiano y Linde tienen estaciones y Vesper tiene oleadas más frecuentes y numerosas, con tráfico mercante de paso. Las patrullas son Stratios. Las tres guardias de la capital reaparecen tras 1.800 segundos de simulación guardados por puesto. Escudo de 75 % del casco y propulsión +25 %. Se probó la entrada, el atraque, el respawn persistente y el tránsito mercante en ambas ediciones. Godot comprobó también la migración de un guardado de cinco sectores. Arte de mapa en lore/maps/mapa-estelar-0.0.59.png y assets/factions/asterion-crest.png.

0.0.58 actualiza los nombres de las naves 09 a 17 y renombra los portanaves 22 y 23 como Nyx y Chimera. Bastión, Baluarte y Tempestad (IDs 14–16) pasan a Battleship con ranuras 4 / 2 / 2 / 2. Los IDs y rangos de equipamiento siguen vigentes. Catálogos equivalentes y ficha en flota-0.0.58.md y flota-0.0.58.png. C# superó --smoke y el exportado de Godot arrancó sin errores.

0.0.57 incorpora Cénit en 4107, posición (1850,1250), índice persistente 5. `data/stations/estacion0.hardpoints.txt` contiene los datos CSV de stationBuilder usados por ambas ediciones. No deduzcas el índice de estación a partir del sector. Los mapas y la descarga de mineros contemplan las dos estaciones de 4107. Cénit tiene cuatro puertos normales, uno Dread, cuatro PDC, 42.000 de casco, mercados independientes y guardado mediante el mecanismo de estaciones adicionales. C# superó --smoke. Godot verificó atraque en los cinco puertos, compra independiente y guardado/carga con una partida temporal. La flota y el mapa están en flota-0.0.57.png, flota-0.0.57.md y mapa-estelar-0.0.57.png.

stationBuilder 1.3 añade selección mixta con Ctrl+clic en el lienzo, operaciones contextuales sobre el grupo, Ctrl+C/Ctrl+V y desplazamiento con flechas de un píxel por pulsación o repetición. El pegado conserva la disposición y el giro de 90° usa el centro de cada objeto. Prueba --smoke con código 0.

stationBuilder 1.2 añade copiar, pegar en el punto pulsado, duplicar y girar 90° para PNG y hardpoints desde el menú contextual. Los rombos y campos X/Y deforman cada eje local del PNG. Las esquinas conservan la proporción actual. Guardar proyecto escribe un JSON portátil de formato 2 y admite cargar el formato 1. Exportar PNG escribe el sprite y la ficha de hardpoints. El CSV requiere adaptación al integrar la estación en el juego. Compilación y --smoke con código 0 para edición, exportación, guardado independiente y reapertura.

0.0.56 corrige los ejes de los puertos, añade un atraque universal en Forja, restaura B directo cuando la nave ya está lista y permite deseleccionar con doble clic vacío. C# compilado y --smoke finalizado con código 0. Godot comprobó ejes paralelos, conteos de puertos, atraque directo con B, autoatraque desde solape parcial, cancelación y doble clic en vacío y sobre entidad. Ambas ediciones exportadas.

FTL cuesta 5.000 Créditos, usa utilidad y tiene alcance de tres enlaces por el camino mínimo. Se activa en vuelo con M y clic en un destino descubierto, seguido de confirmación. Vacía el escudo y lo bloquea 60 s. El cooldown de 300 s es del jugador y se guarda, al igual que el bloqueo por casco. La entrada se bloquea durante la transición de salida/llegada. Los traders de paso y mercantes de ruta llevan FTL y tienen 10 % de probabilidad de soltarlo. Las visitas comerciales ahora duran más de cinco minutos para permitir su salida.

El atlas generado assets/ftl-arrival-v2.png tiene seis celdas de 362 × 362. La llegada combina estallido con desaceleración visual del modelo. La salida acelera una copia visual del modelo. Se conserva la geometría de física durante las animaciones. El salto FTL no marca puertas como cruzadas. Las barras de escudo se recordaron de nuevo en 0.1.0 y siguen esperando su decisión.

## Próximos pasos y recordatorios

1. Al retomar la interfaz, recordar la propuesta de barras de escudo separadas del casco. El usuario eligió expresamente ese momento. La implementación espera su decisión.
2. Mantener las demás facciones del dosier como propuesta hasta que el usuario pida incorporarlas.
3. Continuar la siguiente petición del usuario conservando la equivalencia de ambas ediciones.

## Límites y atención al continuar

La mayor parte de cada edición vive en un archivo grande. El daño debe pasar por player_damage/npc_hit en Godot y PlayerDamage/DamageNpc en C# para respetar escudos. Explosiones y PDC también usan esas rutas.

Hay recursos duplicados entre ediciones. Comprueba referencias y recursos integrados. El número de naves sigue declarado en código. Añadir un casco requiere revisar selector, rangos de ranuras, guardados y recursos.

Asterión está implementado como propietario de cuatro sectores y usa patrullas Stratios. El resto de facciones, la reputación y la diplomacia siguen pendientes. PDC de capitales, cazas y drones dirigidos, torpedos y reparadores siguen sujetos a futuras peticiones.


## Estaciones y atraque desde 0.0.56

station-attributes.txt ahora admite layout y pivote normalizado del PNG tras los campos antiguos. BI tiene dos atraques normales y dos Dread. TRI tiene seis normales y tres Dread. Forja es un astillero con un único puerto universal para naves normales y Dread, reservado para compra futura de naves. Desde 0.0.57, 4107 tiene dos estaciones. Los índices 0/1 de Salvia y Nácar se conservan. Las estaciones nuevas usan silueta alfa para colisión y estado propio para mercados, casco y descubrimiento.

Pulsar B con todas las condiciones cumplidas atraca inmediatamente. Mantener B desde cualquier intersección con una zona verde compatible activa el alineado, centrado y frenado. El atraque se ejecuta tras un segundo continuo con cobertura de al menos 90 %, orientación a 10° y velocidad de hasta 3. Soltar B cancela la maniobra y reinicia la cuenta. Los puertos Dread usan IDs desde 8 y pueden ser varios por estación. Respeta las conversiones radiales y evita volver a limitar el ID de puerto a 8.

El uso de puerto Dread se decide por claseID >= 4. Los guardados de las nuevas estaciones usan extra_stations en Godot y SaveExtraStations/LoadExtraStations en la economía de C#.

Los pares de puertos TRI comparten el eje del ala y son paralelos. BI usa ejes norte/sur con sus centros anteriores. El puerto de Forja es el ID 8 para todas las clases. Doble clic en vacío deselecciona cualquier objetivo; el clic simple vacío mantiene la selección.

shipConfigurator 1.5 permite borrado múltiple, rumbo de rampa con clic derecho y vista previa de plataforma bajo simulación de módulo equipado. El rumbo se persiste como comentario CSV compatible con los lectores del juego. La prueba interna verificó Supr, deshacer y guardar y recargar el rumbo.

## Copia local de GitHub Desktop · 18 de noviembre de 2026

Se actualizó la copia local OrbitalAdventure/OrbitalAdventure con Godot 0.1.6 y la estructura de recursos compartidos. project.godot se abre desde la raíz. Se copiaron los catálogos, datos, assets, lore, documentación y código de ambos editores. La copia de publicación omite el catálogo y el código del juego C#, las partidas, los ejecutables y las cachés. Su README explica ese alcance. La siguiente acción de publicación corresponde al usuario desde GitHub Desktop, mediante revisión, commit y push.