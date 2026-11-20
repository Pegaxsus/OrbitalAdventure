# AI_LIGHTHOUSE · Hangar Orbital

Actualizado el 20 de noviembre de 2026. Estado de entrega: juego Godot y C# 0.1.17, shipConfigurator 1.6 y stationBuilder 1.3.

## Propósito y mantenimiento

Esta guía permite que otra IA continúe sin reconstruir todo el chat. Lee primero AGENTS.md, este archivo y las instrucciones superiores aplicables. Verifica el código antes de asumir que el texto sigue vigente.

Actualiza esta guía con cada entrega y cada cambio relevante de decisiones o estado. Sustituye la información obsoleta. Registra hechos comprobados, verificaciones, pendientes y el siguiente paso concreto. La conversación más reciente del usuario puede actualizar prioridades. El detalle histórico pertenece a los historiales de releases.

## Retomar el proyecto en otro equipo

1. Abre en Codex la carpeta de trabajo que contiene juntos AGENTS.md, AI_LIGHTHOUSE.md y project.godot. Esa carpeta es la raíz de NavePrototype. Lee AGENTS.md, esta guía y [la documentación de Godot](documentation/doc.md). Comprueba qué archivos y versiones tienes antes de continuar. Las rutas de esta guía son relativas a esa raíz y puedes usar cualquier ubicación local.
2. Traslada el árbol de código y recursos completo, incluidos build/, tools/, Godot/, csharp/, assets/, attributes/, data/, lore/ y documentation/. Conserva los archivos .uid, .import y .gdignore. Godot regenera .godot/ al importar. Las plantillas de exportación y el ejecutable del motor se instalan en el equipo nuevo.
3. Si vas a conservar el progreso, copia por separado savegames/godot/latest.json y savegames/csharp/latest.txt. .gitignore excluye las partidas, los ejecutables y la caché del editor. Si partes de una copia de GitHub, comprueba su alcance: la copia usada hasta ahora para GitHub Desktop se ha mantenido como copia de Godot. Para trabajar en las dos ediciones y los dos editores, parte del árbol completo de NavePrototype.
4. En Windows, instala Godot 4.5.1 estándar y sus plantillas de exportación de la misma versión. Importa project.godot desde la raíz y arranca con F5 en el editor. Para C# y las herramientas, comprueba que existe %WINDIR%/Microsoft.NET/Framework64/v4.0.30319/csc.exe. Los scripts de build/ usan ese compilador y las bibliotecas de Windows Forms.
5. Ejecuta las comprobaciones de la sección «Compilar, verificar y entregar». Si los binarios se trasladaron aparte, los vigentes en la raíz son HangarOrbital-Godot-0.1.17.exe, HangarOrbital-CSharp-0.1.17.exe, shipConfigurator-1.6.exe y stationBuilder-1.3.exe. El directorio releases/ guarda las versiones sustituidas.

**Punto de continuación.** Industria está implementada hasta componentes, con catálogo y decisiones en lore/industry/materiales-y-crafting.md. Faltan ensamblajes finales de naves/estaciones/módulos, costes/tiempos y balance. Detector raro definido pero sin distribución.  Cluster01 está implementado con 91 sectores nuevos; faltan las decisiones del usuario sobre facción y atributos de sus sistemas. Consulta lore/maps/cluster01.md antes de asignarlos.  El usuario configurará los hardpoints de Helión (IDs 35–45) con shipConfigurator 1.6. Consulta lore/fleets/helion-0.1.8.md para relacionar los PNG entregados con los nombres, clases e IDs.  Los ocho ambientes están asignados a los 100 sectores. Cuando se añada un sector, asigna un perfil por su dirección4107+ID en data/sector-backgrounds.txt; consulta lore/maps/ambientes.md. Para retomar los hangares, el editor ya guarda los puntos y el rumbo de las rampas, y sigue pendiente consumir esos datos en el juego para desplegar y recuperar cazas o drones. Sigue la siguiente petición del usuario para elegir cuál de estas líneas continuar. Al retomar la interfaz, recuérdale las barras de escudo.

**Texto para el chat nuevo.** «Continúa Hangar Orbital desde la carpeta abierta. Lee AGENTS.md y AI_LIGHTHOUSE.md, verifica la versión disponible y usa esa guía para retomar el proyecto. Mantén Godot y C# al día y conserva los guardados independientes. La siguiente tarea es: [describe aquí el cambio].»

## Objetivo y preferencias del usuario

Juego espacial cenital de escritorio para Windows, con sprites detallados de estilo pixel art, naves equipables, sectores procedurales y persistencia. El usuario quiere resultados ejecutables y explicaciones claras.

Se mantienen dos ediciones con funciones equivalentes.
- Godot 4.5.1 estándar, GDScript.
- C# con Windows Forms y compilador .NET Framework de Windows.

Incrementa el número de release en ambas al modificar el juego, genera ambos ejecutables e informa de diferencias o problemas comprobados. Cada entrega actualiza los historiales, doc.md y esta guía. Doc.md detalla la arquitectura de Godot. Los editores shipConfigurator-1.6 y stationBuilder-1.3 tienen numeración independiente. Una entrega que sólo modifica una herramienta no requiere recompilar ni renumerar el juego.

shipConfigurator 1.4 añade la familia de hardpoints hangar: tubo lateral, rampa longitudinal y plataforma, para drones en todas las clases. Desde 1.6, los cazas requieren Carrier (5), Titán (6) o el rasgo fighter_hangar con habilita_cazas > 0. El editor aplica la regla a cada casco del catálogo, incluidos los futuros. Las fichas usan el CSV de seis columnas. El despliegue, la recuperación y las compuertas quedan pendientes de integración en el juego.

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

Hay 46 naves, IDs 0–45. Fragata es claseID 1, Crucero 2, Battleship 3, Dreadnought 4 y Carrier 5. Cazas/drones reservan claseID 0 y Titán 6 queda pendiente. Preserva los IDs y la orientación de proa. Raptor es ID 24, Manticore 25 y Stratios 26.

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
& ./build/build-csharp.ps1 -Version 0.1.17
Start-Process -FilePath (Resolve-Path 'HangarOrbital-CSharp-0.1.17.exe') -ArgumentList '--smoke' -WindowStyle Hidden -Wait -PassThru
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

0.1.8 añade la flota de Helión, con los IDs 35–45. Los IDs persistentes 0–34 conservan sus posiciones. Las clases nuevas son 1,1,2,2,2,3,3,3,4,5,5. Sólo los dos Carrier nuevos (44 y 45) admiten cazas de serie. Fragatas, Cruceros, Battleships y Dreadnought requieren fighter_hangar/habilita_cazas > 0. Los once cascos llegan sin fichas de hardpoints y el usuario las definirá. El mecanismo genérico de orígenes sigue operativo hasta guardarlas. Las fichas de flota actuales son lore/fleets/flota-0.1.9.md y lore/fleets/helion-0.1.8.md.

Los PNG originales se copiaron a assets/ships con prefijo helion-. Las dos ediciones muestran Helión en los nombres y paneles de objetivos. C# superó --smoke ampliado, con dibujo de los once cascos y validación de las direcciones de todas las ranuras. shipConfigurator 1.6 superó su prueba con el nuevo Crucero Aurora. Godot verificó los 46 catálogos, las reglas de cazas, la ausencia de hardpoints nuevos, los equipos del último casco y la migración de una lista de 35 escudos a 46. El PNG original del Dreadnought incluye una mancha blanca lateral que está anotada en la ficha. Godot exportó los once sprites nuevos y el ejecutable 0.1.8 arrancó en modo headless sin errores. Se verificaron hashes de las partidas y los hardpoints originales al terminar.

0.1.7 añade Carrier (claseID 5) y mueve la reserva de Titán a 6. Los números visibles 09 Leviatán, 22 Nyx, 23 Chimera y 34 Firmamento corresponden a IDs persistentes 8,21,22,33. Mantienen sus atributos de casco, carga, propulsión y ranuras. La compatibilidad de anclajes se comprueba en ambos juegos y en shipConfigurator 1.6. Los Dreadnought admiten drones y los Carrier y Titanes también cazas. fighter_hangar/habilita_cazas permite futuras excepciones individuales y ninguna nave menor lo equipa todavía. Los archivos de hardpoints del usuario se conservan. La tabla actual de flota está en lore/fleets/flota-0.1.7.md.

C# y shipConfigurator superaron sus pruebas --smoke. Godot verificó los cuatro catálogos Carrier, los permisos de los 35 cascos, las seis clases pilotables, el rasgo de excepción y los anclajes antiguos incompatibles. Los lectores de hardpoints se ejecutan después de cargar catálogo y rasgos. Godot exportó y su ejecutable 0.1.7 arrancó en modo headless sin errores. Se verificaron hashes de ambas partidas antes y después del trabajo. El despliegue y la recuperación de cazas y drones siguen pendientes. La importación remota de GitHub Project llega hasta 0.1.6 y su ampliación puede hacerse cuando el usuario la solicite.

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

FTL cuesta 5.000 Créditos, usa utilidad y tiene alcance de tres enlaces por el camino mínimo, o nueve para los seis Carrier con long_ftl. Se activa en vuelo con M y clic en un destino descubierto, seguido de confirmación. Vacía el escudo y lo bloquea 60 s. El cooldown de 300 s es del jugador y se guarda, al igual que el bloqueo por casco. La entrada se bloquea durante la transición de salida/llegada. Los traders de paso y mercantes de ruta llevan FTL y tienen 10 % de probabilidad de soltarlo. Las visitas comerciales ahora duran más de cinco minutos para permitir su salida.

El atlas generado assets/ftl-arrival-v2.png tiene seis celdas de 362 × 362. La llegada combina estallido con desaceleración visual del modelo. La salida acelera una copia visual del modelo. Se conserva la geometría de física durante las animaciones. El salto FTL no marca puertas como cruzadas. Las barras de escudo se recordaron de nuevo en 0.1.0 y siguen esperando su decisión.

## Próximos pasos y recordatorios

1. Al retomar la interfaz, recordar la propuesta de barras de escudo separadas del casco. El usuario eligió expresamente ese momento. La implementación espera su decisión.
2. Mantener las demás facciones del dosier como propuesta hasta que el usuario pida incorporarlas.
3. Continuar la siguiente petición del usuario conservando la equivalencia de ambas ediciones.

## Límites y atención al continuar

La mayor parte de cada edición vive en un archivo grande. El daño debe pasar por player_damage/npc_hit en Godot y PlayerDamage/DamageNpc en C# para respetar escudos. Explosiones y PDC también usan esas rutas.

Ambas ediciones comparten los PNG de assets/. Comprueba las referencias de Godot y los recursos integrados de C#. El número de naves sigue declarado en código. Añadir un casco requiere revisar selector, rangos de ranuras, guardados y recursos.

Asterión está implementado como propietario de cuatro sectores y usa patrullas Stratios. Helión tiene once cascos catalogados desde 0.1.8. Sus territorios y patrullas, las demás facciones, la reputación y la diplomacia siguen pendientes. PDC de capitales, cazas y drones dirigidos, torpedos y reparadores siguen sujetos a futuras peticiones.


## Estaciones y atraque desde 0.0.56

station-attributes.txt ahora admite layout y pivote normalizado del PNG tras los campos antiguos. BI tiene dos atraques normales y dos Dread. TRI tiene seis normales y tres Dread. Forja es un astillero con un único puerto universal para naves normales y Dread, reservado para compra futura de naves. Desde 0.0.57, 4107 tiene dos estaciones. Los índices 0/1 de Salvia y Nácar se conservan. Las estaciones nuevas usan silueta alfa para colisión y estado propio para mercados, casco y descubrimiento.

Pulsar B con todas las condiciones cumplidas atraca inmediatamente. Mantener B desde cualquier intersección con una zona verde compatible activa el alineado, centrado y frenado. El atraque se ejecuta tras un segundo continuo con cobertura de al menos 90 %, orientación a 10° y velocidad de hasta 3. Soltar B cancela la maniobra y reinicia la cuenta. Los puertos Dread usan IDs desde 8 y pueden ser varios por estación. Respeta las conversiones radiales y evita volver a limitar el ID de puerto a 8.

El uso de puerto Dread se decide por claseID >= 4. Los guardados de las nuevas estaciones usan extra_stations en Godot y SaveExtraStations/LoadExtraStations en la economía de C#.

Los pares de puertos TRI comparten el eje del ala y son paralelos. BI usa ejes norte/sur con sus centros anteriores. El puerto de Forja es el ID 8 para todas las clases. Doble clic en vacío deselecciona cualquier objetivo; el clic simple vacío mantiene la selección.

shipConfigurator 1.5 permite borrado múltiple, rumbo de rampa con clic derecho y vista previa de plataforma bajo simulación de módulo equipado. El rumbo se persiste como comentario CSV compatible con los lectores del juego. La prueba interna verificó Supr, deshacer y guardar y recargar el rumbo.

## Copia local de GitHub Desktop · 18 de noviembre de 2026

Se actualizó la copia local OrbitalAdventure/OrbitalAdventure con Godot 0.1.6 y la estructura de recursos compartidos. project.godot se abre desde la raíz. Se copiaron los catálogos, datos, assets, lore, documentación y código de ambos editores. La copia de publicación omite el catálogo y el código del juego C#, las partidas, los ejecutables y las cachés. Su README explica ese alcance. La siguiente acción de publicación corresponde al usuario desde GitHub Desktop, mediante revisión, commit y push.
## GitHub Project · Importación del 19 de noviembre de 2026

Project del usuario: https://github.com/users/Pegaxsus/projects/3 . Se importaron 71 elementos activos de tipo Draft issue con estado Done. Incluyen las 67 versiones numeradas del juego (0.0.1–0.0.60 y 0.1.0–0.1.6) y stationBuilder 1.0–1.3. Cada versión reúne lo pedido y realizado en Godot y C# según sus historiales. Las notas sin versión de migración y las pruebas iniciales se incorporaron a 0.0.10 y 0.0.11.

La importación se verificó recargando el Project y comprobando Done = 71, además del contenido de la ficha 0.1.6. Dos borradores vacíos duplicados de 0.0.45 y 0.0.53 quedaron archivados de forma reversible. Las fichas completas de esas versiones permanecen activas. La operación fue autorizada por el usuario y se realizó desde la interfaz de Projects.

Es una importación puntual. La actualización automática entre los Markdown y Projects sigue pendiente. Para futuras importaciones, comprueba los elementos existentes por versión y actualiza sus descripciones para evitar duplicados. El permiso de publicar elementos en el Project es independiente del flujo de código, donde el usuario realiza el commit y el push.

## Corrección de Luminaria dentro de 0.1.8

Por petición del usuario, el sprite assets/ships/helion-crucero03.png se sustituye por el archivo «Portaaviones espacial industrial desde arriba.png». Luminaria conserva ID 39, clase Crucero (2) y sus atributos. Ambas ediciones se recompilan como 0.1.8. shipConfigurator lee el nuevo PNG al abrir la nave.

## Estado vigente 0.1.9 · Cluster01

La red vigente tiene 100 sectores, 116 enlaces, 15 estaciones repartidas en 14 sectores. Se incorporan 91 sectores con códigos nuevos siguiendo la nomenclatura de la referencia; 17 son de hielo, seis contienen estación. Todos quedan sin facción hasta que el usuario la indique. No mostrar el cero de seguridad de la referencia. Acceso exclusivo a través de 4110, con dos puertas nuevas y conservación de 4107/4109. Asterión mantiene únicamente 4112–4115. Las patrullas de la nueva región son ordinarias; no extender la pertenencia Asterión por comparación de ID.

Fuentes compartidas: data/sectors.txt y data/sector-links.txt. No reordenar los nueve primeros sectores, los diez primeros enlaces ni las nueve estaciones anteriores. Las estaciones nuevas ocupan índices 9–14 en attributes/station-attributes.txt y tienen mercados y guardado propios. El código deja hasta cuatro puertas por sector, máximo real del grafo. Para futuras redes con más puertas hay que ampliar gate_position/GatePosition.

Arte y documentación: lore/maps/mapa-estelar-0.1.9.png, mapa-estelar.md, cluster01.md, cluster01-mapping.json y cluster01-reference.png. build/render-star-map.ps1 regenera el PNG claro desde los datos. El mapa en vuelo conserva exploración, acepta rueda para zoom y botón derecho para desplazar, y diferencia hielo y estaciones. Consola tp admite código o dirección numérica alternativa 4107+ID, documentada en la tabla. La facción y seguridad del nuevo clúster quedan pendientes, sin crear territorio de Helión.

Hielo significa exactamente 512 de 640 asteroides de agua/metano; los otros 128 tienen minerales. La generación determinista por sector conserva la composición al cargar y reaparecer. El rasgo long_ftl,multiplicador_alcance,3 se añade a los Carrier IDs 8,21,22,33,44,45 en ambos catálogos. El módulo sigue costando 5.000, usa utilidad, cooldown 300 s y bloqueo de escudo 60 s, pero alcanza 9 enlaces; otras clases 3.

Descubrimiento y rutas usan conjuntos/diccionarios. crossed conserva los diez bits anteriores. Godot añade crossed_links en JSON; C# añade una línea 26 con índices de enlace sin desplazar las 25 anteriores. Evitar máscaras de bits para IDs del nuevo mapa. Guardados antiguos generan los sectores y estaciones adicionales; los índices altos persisten correctamente. Los mercantes de ruta eligen la estación del clúster más próxima por puertas en lugar de reutilizar Linde para todos los IDs altos.

Verificación: C# compila y supera --smoke, incluida conectividad de 100 sectores, 17 campos de hielo, seis estaciones, frontera FTL 9/10, consecuencias de escudo, descubrimiento de enlace 115 y rutas de mercantes. Godot importa y supera build/test-cluster.gd, incluyendo guardado/carga del sector 99 y migración de nueve campos sin crossed_links. El test usa guardado temporal user:// y no savegames/. Godot exporta y su ejecutable 0.1.9 arranca en headless con código 0 y sin errores. Se comprobaron sin cambios los hashes de 34 archivos de partidas y hardpoints originales. Los binarios 0.1.8 están archivados en releases/0.1.8. Los binarios 0.1.9 se entregan en raíz; editores siguen 1.6/1.3. La flota vigente en texto es lore/fleets/flota-0.1.9.md. No se publica ni copia a GitHub sin petición nueva.

## Estado vigente 0.1.10 · industria y materiales

Se entregan Godot/C# 0.1.10; editores siguen 1.6/1.3. Red sigue en 100 sectores/116 enlaces/15 estaciones, sin nuevas afiliaciones. Son 21 recursos brutos: combustible (agua/metano), 12 de construcción y 7 especiales. IDs antiguos 0–9 conservados; 9 tierras raras pasa a especial. Nuevos 10–14 tungsteno/cromo/cobalto/magnesio/molibdeno; 15–20 veltrita/naurita/oraxita/silexio/terina/cuarión. Refinería produce IDs 21–41; gases/componentes hasta 70. Las composiciones ordinarias excluyen especiales y procesados; 512/640 asteroides de hielo se mantienen. Salvaging no cambia.

Cada iniciar/cargar: 3–7 asteroides vivos por sector reciben 1–3 U aleatorias de un especial, limitados a los disponibles. Las trazas no se guardan. No se muestran por TAB normal. Minar suelta fragmento especial y vacía la traza; NPC minero la consume sin generar botín especial. El respawn normal nunca repone trazas, ni el FTL/cambio de sector/guardado; cargar sí. Se eligen después de restaurar las rocas y limpiar accesos. El detector ID 11 usa utilidad y permite revelar con TAB incluso asteroides ya escaneados. No hay stock, portadores, equipo inicial, drops ni receta para ensamblarlo. El sensor de trazas fabricable es sólo un componente, distinto del módulo detector.

Datos fuente compartidos data/materials.txt y data/recipes.txt, con formato CSV en txt para evitar el importador de traducciones. Godot/industry.gd gestiona catálogo/UI; csharp/Industry.cs amplía la clase parcial Game y debe compilarse junto a Game.cs. Exportadores actualizados. Mantener el orden y los IDs. 71 materiales/productos y 50 recetas accesibles desde estación con F o botón Industria; lotes 1/10, validación completa antes de consumir, almacén del jugador y persistencia. U descarga bodega. Mercados paginados; pestaña Materiales enumera el inventario completo. Los guardados de diez recursos se amplían por prefijo sin perder cantidades. Detector añadido al final con stock cero al cargar.

Alcance real: refinado, electrólisis/pirólisis, aleaciones y componentes, incluidos secciones de casco, conjuntos de motor, matrices, sensores, núcleo FTL, hábitat y vigas. No hay ensamblaje de naves/estaciones/módulos equipables, combustible consumido, energía/costes/tiempos/colas ni uso activo de soporte vital todavía. Servicio de estación gratuito e instantáneo por ahora. Las recetas y proporciones son simplificaciones de juego; los seis minerales y sus propiedades son ficticios. Tabla/lore en lore/industry/materiales-y-crafting.md y crafting-0.1.10.png. build/render-crafting.ps1 regenera el PNG directamente de los datos.

Corrección adicional: la validación C# previa rechazaba los guardados de 26 líneas generados desde 0.1.9. Ahora acepta 26 y todos los formatos anteriores. --smoke prueba guardados y migración en un archivo temporal propio en vez de savegames/.

Verificación: Godot test-industry.gd comprueba las 50 recetas, fallos atómicos, cadena del agua, trazas, escaneo normal/detector, extracción única, ausencia de reposición, carga y migración de diez materiales/módulos antiguos. test-cluster.gd conserva sus comprobaciones. C# --smoke añade equivalentes, guardado de 26 líneas y lectura de 25, todas las recetas y vista renderizada. Se revisan renderizados reales de Godot y PNG de recetas. No modificar datos de hardpoints ni partidas del usuario. Siguiente trabajo: seguir decisiones del usuario sobre fabricación final, balance y territorios del clúster. Mantener el recordatorio de barras de escudo; no se han implementado en esta entrega.

Entrega 0.1.10 verificada: importación/exportación de Godot sin errores, ambos txt y industry.gd incluidos, ejecutable exportado arrancado con código 0. C# --smoke y los dos scripts de regresión Godot pasan. Hashes sin cambios de 34 archivos originales de partidas y hardpoints. Las ediciones 0.1.9 se archivan en releases/0.1.9; la raíz conserva 0.1.10 y los editores vigentes. La previsualización de recetas y la última página de materiales de Godot se renderizaron a 900 × 600 y se revisaron; el PNG de recetas tiene 3000 × 4900 sin cortar sus filas largas.

## Estado vigente 0.1.11 · esquema industrial y estaciones

Decisiones confirmadas por el usuario: primer tratamiento = refinado; después procesado/fabricación. Productos deben distinguir materiales procesados y componentes. Ensamblaje final de naves/estaciones/módulos se definirá más adelante; artefactos y sus eventos quedan para futuro lejano. La lista de componentes es abierta. Los componentes de construcción no tienen relación con hardpoints; una fragata no requerirá Bahía de hangar. No introducir mejoras de slots, cazas u otras capacidades por fabricar componentes.

Catálogo vigente: 88 materiales (23 brutos,36 procesados,29 componentes),65 recetas. IDs 0–70 preservados; ID60 pasa a Piezas de construcción. IDs71/72 tritio/xenón brutos escasos;73/74 purificados;75–87 trece componentes nuevos que, junto a piezas de construcción, cubren los catorce conceptos del dibujo: blindaje, condensadores, bodega, informática, piezas, hangar, montaje de armas, regulador térmico, reactor, drones, sensores, mantenimiento, piezas de armamento y propulsión. Barcos, estaciones, módulos equipables y artefactos no se producen aún.

materials.txt tiene séptima columna rarity (comun/escaso/oculto). Refinados y gases/aleaciones/semielaborados usan stage procesado; las piezas/conjuntos stage componente. El refinado no es una cuarta etapa de objeto, sino una operación. Ver lore/industry/materiales-y-crafting.md para tabla completa; PNG vigente crafting-0.1.11.png, regenerable con build/render-crafting.ps1.

Eficiencia: la receta guarda producción de diseño. La recuperación del refinado es una regla general de 95 %, fuera de recetas. Se multiplica por la eficiencia de la estación. Procesado/fabricación aplica sólo la eficiencia de fabricación. Todas las estaciones parten de80/80, definidas en attributes/station-industry.txt por índice de estación; ambos exportadores lo empaquetan. Valores0–100, fallback80/80 para estaciones nuevas y0 deshabilita el servicio. No hay módulos de mejora todavía, ni tarifas/tiempos/energía. Ejemplo confirmado por la implementación:10cobre→9,5recuperables→7,6 a80 %. Las aleaciones ya no incorporan pérdidas fijas en receta. Las cantidades diseñadas de componentes son necesidades de fabricación, no eficiencia de máquina.

Saldos: escala fija10000 por U; inventario conserva enteros completos y se añade saldo industrial fraccionario por material. Se visualiza el total en Industria. Sólo unidades completas se consumen/venden/transportan; la fracción se conserva y se acumula. Para componentes equivale a producción parcial. El saldo acompaña al inventario global del jugador, no se pierde al cambiar de estación o dividir lotes. Godot JSON industry_remainders; C# línea27 sin desplazar las26previas. Migración de10/71materiales inicializa nuevosIDs y saldos a0. No convertir inventario completo a float ni redondear por operación.

Tritio/xenón: pasada determinista de composición,1 %por asteroide elegible,50/50 entre ambos. En hielo sólo20 %noagua/metano es elegible: incidencia esperada0,2 %del campo. Se conserva512/640agua/metano. Son visibles por TAB normal y se refinan. Sin stock inicial. No son los especiales ocultos y su composición habitual persiste por generación/respawn. Los especiales, Detector de trazas y salvaging permanecen con sus reglas previas.

Verificación completada:65recetas y cálculos7,6/9,5, lotes equivalentes, progreso de componentes, persistencia de saldo, lectura de partidas10/71y25/26líneas, nuevos gases escasos y proporción de hielo. Mantener test-cluster.gd. Revisar interfaz y PNG, compilar ambos0.1.11 y archivar0.1.10 sólo tras verificar los ejecutables nuevos. Conservar las partidas/hardpoints mediante hashes. El siguiente trabajo se elige según petición del usuario; siguen pendientes ensamblaje final, costes/tiempos, mejoras de eficiencia por módulos, territorios del clúster y barras de escudo.

Entrega 0.1.11 verificada: C# --smoke y Godot test-industry.gd/test-cluster.gd pasan. Exportación Godot incluye station-industry.txt y arranca sin errores con código0. Revisadas interfaz de refinado/fabricación y tabla PNG, incluidas9,5U teóricas y7,6U al80 %. Los 34 archivos originales comprobados de partidas/hardpoints conservan sus hashes. Ejecutables0.1.11 en raíz y0.1.10 archivados en releases/0.1.10; editores sin cambios. No se ha copiado ni publicado en GitHub.

## Estado vigente 0.1.12 · pérdidas sólo en refinado

Decisión nueva del usuario: Procesado/Fabricación/Ensamblaje siempre100 %, sin pérdidas. Únicamente Refinado conserva95 %de recuperación y eficiencia de estación80 %inicial. La función de eficiencia de ambas ediciones retorna10000 para cualquier etapa distinta de Refinado, con independencia de parámetros antiguos de fabricación. attributes/station-industry.txt conserva su esquema por compatibilidad, pero fabrication_percent queda100 y no regula otros procesos. El ensamblaje final no se implementa aún; su futura regla también es100 %.

No redondear ni eliminar saldos anteriores, incluidos componentes parciales de0.1.11. No se generan nuevas fracciones en procesado/fabricación con las recetas enteras actuales. Inventarios/IDs/recetas, salvaging, gases escasos, especiales y persistencia permanecen. Tests comprueban componentes completos, electrólisis sin pérdidas y que valores históricos0/80 no afecten a Procesamiento/Fabricacion/Ensamblaje. PNG vigente crafting-0.1.12.png y tabla lore/industry/materiales-y-crafting.md. Ejecutables de ambas ediciones0.1.12 en raíz, editores1.6/1.3.

Entrega0.1.12 verificada: C# --smoke y Godot test-industry.gd pasan; exportación/arranque Godot sin errores, código0. Tabla PNG revisada: acería100teórico=100actual; refinado conserva7,6/10. Hashes sin cambios de 34 archivos de partidas y hardpoints. Ambos0.1.12 en raíz,0.1.11 archivados en releases/0.1.11.

## Decisión pendiente · salvaging según construcción de la nave

El usuario confirma que la recuperación dependerá de los componentes que tenga la nave destruida o que se hayan requerido para construirla. Podrá proporcionar componentes o materiales refinados, según la nave. Se definirá al asignar los componentes a los cascos; aún no hay tablas por nave, cantidades, probabilidades ni proporciones de recuperación acordadas. No inventarlas ni aplicar la regla antes de esa asignación. Mantener por ahora el salvaging genérico de 0.1.12 en Godot/C#. No confundir esta futura recuperación mediante salvaging con drops directos de módulos al morir. Documentado también en lore/industry/materiales-y-crafting.md. Esta actualización sólo registra una decisión: no cambia código, binarios ni versión.

## Estado vigente 0.1.13 · ocho ambientes y 100 sectores

Se añaden Aurora solar, Vacío profundo, Nube criogénica y Tormenta iónica a Arco de gas, Velo de polvo, Límite planetario y Remanente de supernova. Son ocho familias. Se conservan los perfiles históricos nacar/vesper, variantes de gas/remanente: diez perfiles técnicos, un único fondo por cada uno de los cien sectores. Reparto por familia: gas16,polvo11,planeta5,remanente10,solar18,vacío19,criogénica17,iónica4. Los17sectores de hielo usan criogénica. La ambientación no cambia afiliación, seguridad, rutas ni minería.

Fuentes: data/background-profiles.txt (siete columnas históricas y opacity opcional), sector-backgrounds.txt (dirección4107+ID interno,perfil) y background-types.txt (familia/nombre/color editorial). Los sectores con códigos siguen usando la dirección numérica para fondos. No guardar asignaciones en partidas: se toman del catálogo al cargar. La opacidad se modula en Godot y con ColorMatrix en C#, por defecto1 para perfiles antiguos. Estrellas/paralaje/sqrt(zoom) se mantienen. PNG nuevos: solar-aurora-v2.png,deep-void.png,cryo-cloud-v2.png,ion-storm.png. Borradores propios en assets/backgrounds/drafts con .gdignore, fuera de exportación. C# integra sólo los cuatro seleccionados.

Arte creado con herramienta integrada imagegen, cuatro generaciones y dos revisiones de bordes. Prompts completos en lore/maps/prompts-ambientes-0.1.13.md. Catálogo/tabla de asignaciones en lore/maps/ambientes.md y mapa-estelar.md. Lámina y mapa PNG de0.1.13 se regeneran con build/render-ambiences.ps1 y render-star-map.ps1. El mapa usa una banda de color interior para ambiente y conserva estaciones/hielo/escudos.

Comprobado: C# --smoke pasa con100asignaciones,ocho perfiles usados,17hielo,Nácar/Vesper preservados,alfa de bordes y renderizado de ocho perfiles. Godot test-backgrounds.gd,test-cluster.gd,test-industry.gd pasan. preview-backgrounds.gd renderiza los ocho en escenas reales; se inspeccionan criogénica/solar y la lámina/mapa. Exportación y comprobación final cerradas. Los ejecutables vigentes son0.1.13; editores1.6/1.3 sin cambios.

Nota del entorno de verificación: el lanzador pwsh de WindowsApps falló al crear procesos. Se usó Windows PowerShell nativo y node_repl con fs/child_process para operaciones autorizadas. Godot importó correctamente con APPDATA/LOCALAPPDATA aislados en build/.background-runtime, un directorio temporal propio ignorado por Godot. No desinstalar herramientas ni desactivar antivirus por mensajes de Safe save. Es una nota de continuidad del entorno, no un cambio de requisitos del juego.

Entrega0.1.13 cerrada: exportación Godot incluye los cuatro PNG seleccionados y excluye drafts; arranque del exe sin errores,código0. C# --smoke y las tres regresiones Godot pasan. Renderizados reales y mapa/lámina inspeccionados. Se detectaron actualizaciones concurrentes de archivos del usuario y se conservaron sin restaurar ni sobrescribir: savegames\godot\latest.json, data\hardpoints\ship26.txt. Las compilaciones finales incorporan los hardpoints del árbol actual; --smoke C# y arranque Godot pasan tras recompilar. Ejecutables0.1.13 en raíz;0.1.12 archivados en releases/0.1.12. No se ha actualizado GitHub.

## Estado vigente 0.1.14 · atraque de Ocaso y compatibilidad

Ocaso(ID41) sigue siendo Battleship(clase3),longitud134/anchura67. No cabía90 % en normales164×58, máximo86,57 %. Ahora docking_ports/DockingPorts comprueba tamaño y despeje con la colisión real de estación. Naves menores que Dread prefieren normales compatibles y, si ninguno vale, capitales; capitales siguen usando su categoría. Un normal personalizado suficientemente ancho admite Ocaso. Los puertos ofrecidos en UI/manual/auto son los mismos. dock_at/DockAt remapea puertos antiguos incompatibles y protege listas vacías. Sin cambiar atributos/PNG/hardpoints ni coordenadas de puertos.

Godot también usaba por error imágenes compartidas get_image al preparar el fondo difuminado: máscara de Cénit256×256 en lugar de860×860, generando colisiones falsas con Covetor19,Luminaria39,Incandescencia42. Se usa duplicate() antes de transformaciones de cielo,estación,rotación y escudo. Las máscaras mantienen resolución/alfa originales y los PNG en disco no cambian. C# ya usaba máscara original. Tras corregirlo ambas ediciones dan los mismos resultados.

ship_overlaps_station/ShipOverlapsStation se comparte entre vuelo y validación de puerto; se comprueban casco centrado y cinco puntos del pasillo exterior. Caché por nave/estación en dock_compatibility/DockCompatibility, transitoria y no persistida. La geometría actual no cambia durante el vuelo; si en el futuro se implementa edición/recarga, invalidar la caché. Se preservan velocidad≤3,alineación≤10°,cobertura90 %,ambos sentidos y lógica de pulsar/mantener/soltarB.

Pruebas:46naves×15estaciones=690combinaciones. Godot test-docking.gd y C# --smoke(csharp/DockingChecks.cs) pasan5.300manuales y690auto por edición, además de normal personalizado ancho, remapeo de Ocaso y ausencia de puerto. build/build-csharp.ps1 compila ahora tres archivos. Informe de catálogo/causas en lore/fleets/atraques-0.1.14.md. audit-docking.gd debe producir lista vacía. Usar guardados temporales al verificar. Entrega cerrada: test-docking.gd, audit-docking.gd (lista vacía), test-industry.gd, test-backgrounds.gd y test-cluster.gd pasan. C# --smoke termina con código 0 y 5.300 casos manuales/690 auto. Exportación Godot y arranque del ejecutable terminan con código 0, sin errores. Los 34 archivos de guardados/hardpoints del inventario inicial conservan sus hashes. Ejecutables 0.1.14 en raíz; 0.1.13 archivados en releases/0.1.13. Editores 1.6/1.3 sin cambios. No se ha actualizado GitHub.

## Estado vigente 0.1.15 · estadísticas del sector

Consola: sector_stats 1 muestra el panel superior derecho a la izquierda del minimapa; sector_stats 0 lo oculta. Tab completa el comando y alterna valores. Godot show_sector_stats/sector_stats_rows/draw_sector_stats; C# showSectorStats/SectorStatsRows/DrawSectorStats. Lista nombre, número y destinos de todas las conexiones (también sin explorar), NPC vivos presentes y perfil de fondo exacto (id del catálogo). Mercantes ya forman parte de npcs; no contarlos dos veces. Excluye jugador/estaciones/restos. No persiste, arranca apagado y se actualiza al dibujar. C# añade Id al perfil de fondo, sin alterar formato de datos.

Verificado: build/test-sector-stats.gd pasa los 100 sectores, estados válidos/inválidos, autocompletado y dibujo; C# --smoke completo pasa con comprobaciones equivalentes. Exportación Godot y arranque del ejecutable terminan con código 0 sin errores. Ambos ejecutables 0.1.15 en raíz; 0.1.14 archivados en releases/0.1.14. Barras de escudo recordadas al usuario, siguen pendientes. Sin cambios a guardados, hardpoints, atributos o mapa; sin publicación en GitHub.

## Estado vigente 0.1.16 · criogenia jugable y pendientes en Projects

Los 17 sistemas de hielo conservan cryo-cloud (asignación verificada; ya coincidían). Este perfil deja de ser puramente visual: reduce velocidad base 10 %, +10 puntos cada 60 s, máximo 80 % tras 420 s. Exposición por visita y nave; NPC recién llegados empiezan en 10 %. Reduce velocidad máxima del jugador y velocidad objetivo de NPC/autoatraque/mercantes; no altera giro, empuje, armas, minería ni escudos. Reinicio al salir por puerta, FTL, tp o rescate a otro sector; nuevo sector criogénico empieza al 10 %. Atracado/pausas no acumulan exposición.

Termorregulador Boreal ID 12: utilidad pasiva, un hueco, compra 1.800/venta 900, stock inicial 2 en estaciones. Equipado evita frío y escarcha, inventario no. No suma bonos y el contador de visita sigue aunque esté protegido. NPC sin módulo por defecto; cryo_protected/CryoProtected admite excepciones futuras. Detector de trazas ID 11 sigue stock cero. Módulos pasan de 12 a 13 manteniendo IDs; lectores C# aceptan prefijos anteriores (incluidos 11/12) y Godot completa stocks con 2.

Godot implementa cryo_seconds/cryo_sector, cryogenic_sector, cryo_slowdown, player_cruise_speed, draw_frost. C# añade csharp/Cryogenic.cs y el build lo compila junto a Game, Industry y DockingChecks. Mascara azul/blanca con vetas siguiendo alfa, intensidad según efecto; no mutar imágenes originales. HUD muestra porcentaje/Boreal activo. Godot JSON conserva cryo_seconds; C# línea 28 opcional; ruta mercante añade campo 9 opcional en C#, clave cryo_seconds en Godot. Mercantes simulan exposición por su propio sector incluso fuera de pantalla. No guardar exposición como dato global del sector.

Pruebas: test-cryogenic.gd pasa; C# --smoke completo pasa con pruebas equivalentes, migración de stock y persistencia. test-industry.gd, test-backgrounds.gd, test-cluster.gd, test-sector-stats.gd y test-docking.gd pasan (5.300 manuales y 690 auto). Renderizados Godot/C# inspeccionados en lore/maps/criogenia-godot-0.1.16.png y criogenia-0.1.16.png. Reglas en lore/maps/criogenia.md. Entrega cerrada: exportación y arranque de Godot terminan con código 0 sin errores. Ejecutables 0.1.16 de ambas ediciones en raíz; 0.1.15 archivados en releases/0.1.15. Los 49 archivos de partidas y hardpoints del inventario inicial mantienen sus hashes. Editores 1.6/1.3 sin cambios.

GitHub Project https://github.com/users/Pegaxsus/projects/3: se añaden seis Draft issues a In progress, que estaba vacío, sin duplicar las 71 Done. Temas: efectos de los siete ambientes restantes; ensamblaje y salvaging según componentes; despliegue/recuperación de hangares; territorios/seguridad/patrullas de Cluster01/facciones; barras de escudo; mejoras de refinado y distribución del detector raro. No están implementados por estar en esa columna: ubicación solicitada por el usuario. documentation/pendientes.md contiene alcance y decisiones; prueba visual github-pendientes-0.1.16.jpg. La columna tiene objetivo visual 3 y ahora indica 6/3; no se modificó ese límite. No se han publicado código, commits ni push, ni sincronizado releases posteriores a 0.1.6.

## Estado vigente 0.1.17 · estación, capas, asteroides y espectrómetro

Estación Umbral BI añadida en E7-UUH ID 29/dirección 4136, (0,0), índice persistente 15, 34.000 casco. Dos puertos normales/dos capitales; mercados/industria habituales, eficiencia 80/100. Catálogo de estaciones ahora 16, siete en Cluster01. Se añade al final, sin cambiar índices anteriores. Sector station=1 y tabla/mapping/mapa actualizados, referencia original intacta. Mapa claro vigente lore/maps/mapa-estelar-0.1.17.png.

Godot/survey.gd y csharp/Survey.cs contienen recursos y lógica de exploración. C# build compila cinco archivos. data/background-layers.txt describe tres capas por cada uno de diez perfiles: principal, copia girada/desplazada y perfil relacionado tenue. Se conserva clasificación y efectos del perfil principal; capas no multiplican criogenia. Los otros ambientes siguen pendientes de reglas.

23 PNG nuevos generados con image_gen integrado en assets/asteroids/materials; catálogo data/asteroid-materials.txt. Se prepara en memoria el alfa útil y tamaño hasta 256, sin modificar PNG originales. Hielos azules, minerales con acentos desaturados. El sprite usa material principal; especiales ocultos no cambian apariencia del asteroide. Sus sprites se usan en informe y están disponibles para futuros depósitos principales. Prompts exactos/procedencia en lore/maps/prompts-asteroides-0.1.17.json; galería asteroides-0.1.17.png inspeccionada, 23 imágenes con alfa.

Gigantes: 2+sector%3 por campo, 299/64.000, índices 620+n*4. Radio 150–240, posición determinista en cuadrantes exteriores, separada de otros asteroides. Conservan composición. Extracción ideal produce 24–32 fragmentos de 10 U; progreso de minería requiere 3*max(1,radio/45) segundos. Se conserva casco base 2.400 y resto de reglas, incluidos especiales y sobrecarga. Respawn respeta radio, jugador, estaciones, puertas y límites; sigue el ciclo existente. JSON añade geology_version=1; C# línea 29 opcional. Al cargar datos anteriores se conserva salud/minado/progreso, pero los índices gigantes usan posición nueva segura en lugar de posición antigua de pequeño. Guardados nuevos conservan posiciones. No cambiar índices de campos.

Espectrómetro de materiales ID 13, utilidad pasiva al completar escaneo TAB equipado, un hueco, compra 2.600/venta 1.300, stock inicial 2 en tiendas. Totales de todos los asteroides vivos del sector, principales/secundarios y especiales, extracción ideal; suma materiales repetidos, excluye agotados/respawn, drops, carga y restos. Instantánea, repetir TAB para refrescar. Ventana pausa, cierra Esc/Enter/botón, sin coordenadas. No revela special_seen/SpecialRevealed: Detector raro ID 11 sigue distinto y sin distribución. Boreal ID 12 intacto. Catálogo módulos 14 entradas; lectores conservan prefijos de partidas anteriores. Reporte no persiste.

Puertas: centros a 4.433–4.733 de origen en los ejes; sprite radio 67 deja 200–500 de margen exterior al mapa. Mismo cálculo determinista por sector/enlace en ambas ediciones. clear_gate_approaches/ClearGateApproaches despeja 300+radio de asteroide al crear/cargar; respawn respeta esa zona. Llegada, mineros sin estación y mercantes consumen coordenadas nuevas. No cambian conexiones/exploración/alcance FTL.

Test-survey.gd pasa catálogo, 299 gigantes, 232 entradas, márgenes/despeje, totales exactos, equipamiento, compra, persistencia y migración de posición antigua. C# --smoke con RunSurveySmoke equivalente y alfa pasa. 46x16 atraques: 5.484 manuales/736 auto por edición. Prueba criogénica ajustada a tolerancia de .002 de posición por precisión float a coordenadas lejanas. Renderizados inspeccionados de gigantes, informes, capas y mapa; reglas en lore/maps/exploracion-0.1.17.md. Entrega cerrada: siete regresiones Godot y C# --smoke pasan. Exportación incluye explícitamente background-layers.txt y asteroid-materials.txt; comprobación inicial exige 23 sprites y diez perfiles de capas, también en ejecutable. Arranque Godot exportado termina con código 0 sin errores. Los tests de clúster/industria borran sólo su guardado temporal propio al empezar para evitar reutilizar estado entre ejecuciones. Ejecutables 0.1.17 en raíz, 0.1.16 archivados en releases/0.1.16. No se actualiza GitHub ni Projects en esta tarea.

Verificación de datos del usuario en 0.1.17: los 49 archivos iniciales de partidas/hardpoints mantienen sus hashes. No se han modificado fichas de naves ni hardpoints. Editores 1.6/1.3 sin cambios.

## Entrega local para GitHub · 20 de noviembre de 2026

El usuario pide explícitamente crear un commit de la versión actual 0.1.17. Para esta entrega se sincroniza y se confirma la copia Godot en GoogleDrive/07-SOFTWARE_and_RES/GitHub-desktop/OrbitalAdventure/OrbitalAdventure, remoto Pegaxsus/OrbitalAdventure, conservando su alcance: Godot, recursos, datos, lore, documentación y editores. La edición del juego C#, partidas, ejecutables y cachés permanecen fuera de esa copia. El commit de entrega lleva el título «Actualiza Hangar Orbital Godot a 0.1.17»; consultar git log para su hash. Esta petición autoriza el commit local y actualiza la preferencia anterior sólo para esta operación. El push queda pendiente del usuario. No modificar GitHub Projects al sincronizar código.
