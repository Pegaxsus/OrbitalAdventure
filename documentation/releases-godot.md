# Lanzamientos de Godot

Historial reconstruido a partir de las entregas del proyecto. Las compilaciones de prueba sin número conservan su identificación original.

## Migración de 0.0.10 · sin número propio

**Pedido.** Migrar el prototipo de Windows Forms a Godot sin perder las mecánicas existentes.

**Trabajo realizado.** Proyecto Godot 4.5.1 en GDScript, ejecutable autónomo de Windows, reutilización de sprites y fichas de 17 naves. Se portaron vuelo, colisiones, ping, minería, recogida y persistencia. La compilación se publicó como `HangarOrbital-Godot.exe`.

## Prueba de misiles · sin número propio

**Pedido.** Probar un misil como escena reutilizable.

**Trabajo realizado.** Se creó `missile.tscn`, con aceleración, estela, explosión y daño por proximidad. Se publicó `HangarOrbital-Godot-Misiles.exe`.

## Prueba de inventario · sin número propio

**Pedido.** Descargar materiales al volver al hangar.

**Trabajo realizado.** Se añadió la descarga con U, la vista de recursos y el inventario persistente. Se publicó `HangarOrbital-Godot-Inventario.exe`.

## 0.0.11

**Pedido.** Numerar ambas ediciones y equiparar misiles e inventario.

**Trabajo realizado.** Misiles en modo Misiles con Espacio, recarga de 0,85 s, daño directo y de área. Descarga con U en el hangar, inventario por recurso y persistencia. Se identificó cada ejecutable por edición y número.

## 0.0.12

**Pedido.** Guardar por separado bajo `savegames` y cargar el último guardado al iniciar.

**Trabajo realizado.** Cada edición usa su subcarpeta y un archivo `latest`. F9 vuelve a cargar. Si no existe el archivo nuevo, se busca el guardado antiguo de la misma edición.

## 0.0.13

**Pedido.** Añadir pérdida de progreso minero, teclas de potencia, objetivos y ayuda.

**Trabajo realizado.** La minería pierde avance fuera de la ventana o sin láser. O/L ajustan la potencia. T recorre objetivos por distancia, Y deselecciona. H alterna la ayuda y B vuelve al hangar.

## 0.0.14

**Pedido.** Corregir las tildes de la interfaz.

**Trabajo realizado.** Se corrigieron los textos españoles del juego, incluyendo nombres de recursos, mensajes y ayuda.

## 0.0.15

**Pedido.** Introducir trader, minero, pirata y patrulla.

**Trabajo realizado.** Trader temporal de tres tamaños con dos escoltas en la variante grande y un indicador direccional. Minero neutral, pirata que busca carga y huye con poco casco, y patrulla que investiga disparos, persigue al pirata y reacciona ante agresiones observadas contra neutrales.

## 0.0.16

**Pedido.** Limitar el minero a su bodega y añadir minimapa, puertas y mapa estelar.

**Trabajo realizado.** El minero recoge hasta 20 U y sale por una puerta. Se crearon cinco sectores conectados por seis rutas generadas con semilla común. G salta desde una puerta, M abre el mapa y N alterna el motor auxiliar. El mapa solo muestra conexiones cruzadas y la partida conserva su estado.

## 0.0.17

**Pedido.** Marcar las puertas cruzadas y añadir restos, salvaging y explosiones.

**Trabajo realizado.** Las puertas cruzadas aparecen en el minimapa. Una nave destruida produce una explosión y entre tres y siete restos según su tamaño. Se prepararon 22 PNG transparentes. El primer salvaging recuperaba 5 U de hierro por pieza y los restos se guardan por sector.

## 0.0.18

**Pedido.** Limpiar la marca de agua de los PNG de restos.

**Trabajo realizado.** Se limpiaron y volvieron a recortar los 22 sprites con transparencia. Los píxeles bajo la marca se reconstruyeron. Se recompilaron ambas ediciones.

## 0.0.19

**Pedido.** Acortar y colorear el rayo de salvaging, variar la extracción por tamaño y destruir restos con armas.

**Trabajo realizado.** Rayo verde de alcance equivalente al 55 % de la longitud de la nave. La recuperación requiere entre 1 y 2,5 s de contacto y entrega 3, 5 o 7 U de cobre, hierro, titanio o aluminio. Disparos y misiles eliminan los restos alcanzados sin generar recursos.

## 0.0.20

**Pedido.** Añadir Coupled/Decoupled y capacidades de ranuras por tamaño.

**Trabajo realizado.** F alterna la asistencia y el modo se guarda. Coupled frena al soltar el empuje de traslación. Se añadieron fichas de ranuras para armamento, defensa, utilidad y motores, visibles en el hangar. El montaje de módulos queda pendiente.

## 0.0.21

**Pedido.** Cambiar Coupled/Decoupled a C, activar Coupled por defecto, crear una imagen de la flota y actualizar la documentación con cada entrega.

**Trabajo realizado.** C alterna la asistencia y P cambia la pintura. Las partidas nuevas y las anteriores sin preferencia guardada empiezan en Coupled. Las partidas que ya guardaron el modo conservan su elección. Se generó una ficha visual de las 17 naves a partir de sus sprites y atributos y se actualizó la guía técnica.

## 0.0.22

**Pedido.** Incorporar estaciones fijas con casco alto, colisión y dos puertos por extremo. Sustituir el acceso remoto al hangar por atraque con B y mostrar un fondo espacial desenfocado en el hangar.

**Trabajo realizado.** Se incorporaron seis estaciones de tamaño 155, con 4.200–4.900 t, 24.000–30.000 puntos de casco y ocho puertos cada una. Los puertos se marcan en verde a corta distancia. B exige que la nave esté dentro del puerto, alineada y a baja velocidad. Una partida nueva comienza atracada y Enter permite salir desde el puerto. El guardado conserva la estación y el puerto cuando la nave está atracada. La colisión afecta a la nave del jugador; el casco de la estación es un atributo reservado para una futura interacción de combate.

## 0.0.23

**Pedido.** Dejar una única estación verde en el sector inicial, hacer que los mineros descarguen allí y que los piratas puedan atacarla con respuesta de las patrullas.

**Trabajo realizado.** La Estación Salvia es la única activa, en el sector 4107. El minero local lleva cada recogida a un puerto cercano y deposita la carga en una reserva propia de la estación. Los piratas pueden dañar el casco de Salvia y la patrulla prioriza su defensa. El casco y la reserva se guardan. Los mineros de sectores sin estación conservan su salida por puerta al llenar la bodega. Salvia queda operativa con un mínimo de 1 punto de casco.

## 0.0.24

**Pedido.** Reducir los puertos de atraque para que no se solapen.

**Trabajo realizado.** Los ocho puertos de Salvia pasan a medir 170 × 44 unidades. Sus centros se sitúan a 160 unidades en el eje de cada brazo y a 48 unidades a cada lado. Los puertos contiguos quedan separados y la nave más grande conserva espacio para atracar. El dibujo y la validación de atraque comparten las mismas dimensiones.

## 0.0.25

**Pedido.** Añadir un panel de Inventario accesible con I al estar atracado, con los slots sobre la nave y una cuadrícula para futuros objetos. Reorganizar la ayuda en tres columnas.

**Trabajo realizado.** El panel muestra la nave seleccionada y sus ranuras de armamento, defensa, utilidad y motores, diferenciadas por color. A la derecha hay una cuadrícula vacía de 16 × 16 celdas. I abre y cierra el panel y, mientras está abierto, bloquea las acciones del hangar que quedan debajo. H muestra los controles agrupados en Vuelo, Interacción y Hangar y mapa. La instalación, el arrastre y el guardado de módulos quedan para una entrega posterior.

## 0.0.26

**Pedido.** Reducir el inventario a 8 × 8 conservando su tamaño visual. Asignar una ranura de armamento a las naves pequeñas y dos a las medianas.

**Trabajo realizado.** La cuadrícula conserva sus 256 × 256 unidades de interfaz con 64 celdas de 32 × 32. Las once naves medianas pasan a dos ranuras de armamento. La clase pequeña, aún sin naves, queda definida con una en la tabla de diseño.

## 0.0.27

**Pedido.** Nombrar las clases de naves, añadir un panel de detalles y montar módulos de combate y extracción para el jugador y los NPC.

**Trabajo realizado.** Las clases actuales se llaman Crucero, Battleship y Dreadnought. Fragata es la clase pilotable mínima prevista y Titán es la futura clase superior. Cazas y drones quedan previstos como unidades de IA. El inventario incluye una ametralladora, un misil, un equipo de minería y otro de salvaging. Arrastrar un módulo a una ranura de armamento habilita su modo en esa nave. La partida guarda las posiciones de los módulos. El minero equipa minería, la patrulla, las escoltas y los piratas equipan ametralladora, y el trader lleva las ranuras de armamento vacías.

## 0.0.28

**Pedido.** Añadir desequipado general, aumentar el tamaño de los textos, abrir mercados de minería y objetos en el hangar, incorporar Créditos y botín de NPC y cambiar Misil por Cohete.

**Trabajo realizado.** El botón devuelve todos los módulos de la nave activa a la cuadrícula si caben. El hangar muestra la cartera y abre los dos mercados, con compra y venta de una unidad por clic. Las existencias minerales de la estación reciben también los depósitos de los mineros. Cada módulo instalado en un NPC destruido tiene un 50 % de probabilidad de caer y se recoge por proximidad. La partida conserva cartera, existencias, módulos y botín pendiente. Los precios de venta iniciales son la mitad del precio de compra, redondeada hacia abajo.

## 0.0.29

**Pedido.** Añadir las mineras Procurer, Retriever y Covetor con bodega ampliada. Mover el inventario a un botón del hangar. Combinar módulos repetidos, cambiar la resistencia de restos, añadir el Tractor Beam Tier0 y descubrir Salvia al atracar.

**Trabajo realizado.** El hangar ofrece las tres mineras y sus fichas. Las ametralladoras disparan en paralelo desde puntos distintos. Los rayos de minería y salvaging convergen, y cada impacto adicional sobre el mismo objetivo amplía la ventana minera o acelera la recuperación. Los restos resisten tres o cuatro impactos de ametralladora, sin barra de vida. Los cohetes pasan a través de ellos y sus explosiones no los dañan. El Tractor Beam Tier0 cuesta 220 Créditos, ocupa utilidad y atrae módulos flotantes y fragmentos minerales dentro de 1,25 veces la longitud de la nave. Salvia aparece en el mapa y el minimapa del sector inicial tras el primer atraque manual.

## 0.0.30

**Pedido.** Corregir la orientación invertida de las tres mineras nuevas.

**Trabajo realizado.** Los sprites de Procurer, Retriever y Covetor giran 180° al cargarse. La proa queda orientada hacia el avance en vuelo y el arte se muestra con la misma orientación en el hangar y el inventario.

## 0.0.31

**Pedido.** Añadir cantidades de compra y venta guardadas, ordenar las filas del mercado, añadir botones de descarga y desatraque, regenerar asteroides minados y ralentizar al minero.

**Trabajo realizado.** Ambos mercados tienen un campo de cantidad por fila y ejecutan el lote completo si hay existencias, saldo y espacio. Las columnas Inventario y Estación enmarcan los controles de compraventa y las filas minerales llevan separadores. El hangar tiene botones para descargar la bodega y desatracar. Cada cinco minutos de simulación se selecciona un 25 % de los asteroides minados de cada sector, redondeado hacia arriba. Se recolocan y aparecen en diez segundos. El minero viaja a 48 unidades/s, espera ocho segundos entre búsquedas y tarda 18 segundos en extraer.

## 0.0.32

**Pedido.** Añadir una estación en 4108, asignar precios de materiales por estación, crear rutas comerciales de NPC y ajustar el comportamiento de los piratas.

**Trabajo realizado.** Nácar abre en 4108 con inventario y precios propios. J abre el comercio con un trader de paso cercano. Un mercante compra hasta ocho unidades con margen positivo, navega por las puertas y entrega el lote al mercado de destino. El lote en tránsito y el estado de Nácar se guardan. Los piratas aparecen solos o en pareja, priorizan al último atacante y al bajar del 40 % tienen una única probabilidad del 50 % de huir.

## 0.0.33

**Pedido.** Usar la lámina de explosiones al destruir una nave. Mantener el casco inmóvil mientras estallan dos puntos y cubrirlo con una explosión final antes de que desaparezca.

**Trabajo realizado.** La lámina transparente se usa como atlas de siete fotogramas. La secuencia conserva la posición y orientación del casco, reproduce dos estallidos escalonados y termina con una explosión a escala de la nave. Se aplica a la nave del jugador y a los NPC. El jugador vuelve al hangar cuando termina la secuencia.

## 0.0.34

**Pedido.** Añadir cuatro Dreadnoughts de mayor tamaño, con perfiles de portanaves, combate e industria.

**Trabajo realizado.** Se añadieron Rorqual, Carrier I, Carrier II y Dread Combat. Miden entre 210 y 242 unidades de longitud. Los carriers y el casco de combate llevan entre 280 y 305 U; el Rorqual lleva 780 U y admite varias herramientas de minería y salvaging. Salvia y Nácar cuentan con un atraque exterior para los nuevos cascos. El lanzamiento de cazas y drones y las torretas quedan para futuras entregas.

## 0.0.35

**Pedido.** Acercar el atraque de los Dreadnoughts nuevos y dejar un solo puerto para estos cascos. Recordar los tamaños y atributos de la flota.

**Trabajo realizado.** El único puerto de gran tamaño de cada estación se desplazó de 400 a 385 unidades al norte. Sus límites quedan separados cinco unidades de los puertos normales. La tabla de la flota se preparó con las fichas de las 24 naves.

## 0.0.36

**Pedido.** Unificar los atributos en un archivo por edición y vincular cada nave a su PNG desde el catálogo.

**Trabajo realizado.** C# carga ships-csharp.csv y Godot carga ships-godot.txt. Cada fila incluye ID, sprite, rotación, atributos, ranuras y nombre. Los IDs de las 24 naves se conservaron. El script build-csharp.ps1 empaqueta los PNG mencionados en el catálogo.

## 0.0.37

**Pedido.** Añadir clase, claseID y rasgos a los catálogos y dar al Rorqual autoapuntado minero y mayor alcance.

**Trabajo realizado.** Cada casco declara su clase y su ID. El campo traits acepta varios rasgos separados por una barra vertical. El Rorqual selecciona el asteroide válido más cercano a la proa dentro de un cono de 90° y orienta hacia él los láseres equipados. Su alcance minero aumenta un 25 %. Los parámetros están en ship-traits.txt, compartido por ambas ediciones.

## 0.0.38

**Pedido.** Crear un sistema para situar los puntos de salida de motores, disparos y láseres en naves, y definir anclajes en estaciones.

**Trabajo realizado.** Ambas ediciones cargan hardpoints.txt. Las coordenadas locales de cada casco se transforman con su posición y giro. Se conectaron las llamas, la ametralladora, los cohetes, los láseres de minería y salvaging y las trazas de NPC. Los centros de atraque de las estaciones se leen del mismo archivo. El Rorqual incluye anclajes ajustados como ejemplo. Los cascos sin filas específicas usan posiciones predeterminadas.

## 0.0.39

**Pedido.** Crear un editor visual que permita cargar sprites y situar hardpoints con el ratón, guardando una ficha por nave.

**Trabajo realizado.** Editor-Hardpoints.exe abre los sprites del catálogo o un PNG de referencia. Permite colocar, seleccionar y quitar puntos por tipo. Guarda una ficha por ID de nave que ambas ediciones leen al volver a compilar o exportar. Los puntos de estación siguen en el archivo común y los del Rorqual se trasladaron a su ficha individual.


## 0.0.40

**Pedido.** Acortar y ensanchar los puertos, permitir 10° de desviación, exigir que el 90 % de la nave esté dentro y admitir hasta 3 unidades/s. Reparar las estaciones tras cinco segundos sin daño.

**Trabajo realizado.** Puertos normales de 164 × 58 y puerto capital de 258 × 196. El atraque mide la intersección del rectángulo girado de la nave con el puerto. Cada estación recupera el 20 % de su casco máximo por minuto tras cinco segundos sin daño y hasta completar el casco. Publicado el ejecutable para Windows.


## 0.0.41

**Pedido.** Añadir misiles guiados como módulo, asignar teclas numéricas según el equipo instalado y limitar el comercio con traders a la bodega de la nave activa.

**Trabajo realizado.** El misil sale perpendicularmente desde su hardpoint, gira hacia el objetivo fijado con T y acelera hasta el impacto. Se vende en el Mercado Objetos y puede aparecer en el botín pirata. Las teclas 1–5 se asignan sin huecos según los módulos instalados. La rueda controla el zoom y Mayús + rueda regula la potencia en minería. El trader entrega y recibe materiales directamente de la bodega y respeta su capacidad. Se conservaron los identificadores de los módulos y los valores de mercado de los guardados anteriores.


## 0.0.42

**Pedido.** Diagnosticar por qué la ametralladora equipada deja de disparar.

**Trabajo realizado.** Se restauró la cuenta atrás de la ametralladora en cada paso de física y se reinicia al limpiar la munición. Se verificaron cuatro proyectiles en 256 ms manteniendo Espacio con la partida guardada.


## 0.0.43

**Pedido.** Incorporar los sprites del cohete y del misil y añadir fuego en sus toberas durante el vuelo.

**Trabajo realizado.** Se importaron los dos sprites con fondo transparente. Cada proyectil gira según su rumbo y muestra una llama animada tras la tobera, naranja para el cohete y azul para el misil.


## 0.0.44

**Pedido.** Cerrar las pantallas con Escape, aumentar un 20 % el lado de las celdas y presentar los iconos antes de integrarlos.

**Trabajo realizado.** Escape cierra la pantalla activa. La cuadrícula 8 × 8 pasa de 32 a 38,4 unidades por celda y se amplía el panel. Los iconos se presentan por separado para revisión y esta compilación usa las abreviaturas.


## 0.0.45

**Pedido.** Integrar los iconos aprobados, equipar con doble clic y añadir Thrusters, Gyro y PDC.

**Trabajo realizado.** Se añadieron las mejoras de motor, sus sprites de botín y las ranuras compatibles. El PDC orienta la torreta, responde a atacantes y dispara ráfagas de tres tiros. Dos impactos interceptan un proyectil entrante. Cada estación monta cuatro PDC. Se conservaron los índices de los módulos existentes.


## 0.0.46

**Pedido.** Mover sólo los cuatro cañones del PDC durante la defensa.

**Trabajo realizado.** Se separó el sprite en base fija y cañones articulados. Al perder la amenaza, los cañones mantienen su ángulo respecto al casco.


## 0.0.47

**Pedido.** Añadir las fragatas Raptor y Manticore y el crucero Stratios, con fichas propias y salva doble en la Manticore.

**Trabajo realizado.** Se incorporaron las tres naves a los catálogos y al selector del hangar. La Manticore duplica cada salva de misiles y cohetes mediante el rasgo `double_ordnance`. Se amplió el espacio de direcciones de defensa y se conservaron las ranuras de las partidas anteriores.


## 0.0.48

**Pedido.** Corregir el nombre del crucero Stratios.

**Trabajo realizado.** Se corrigió el nombre en el catálogo y en el selector del hangar. El crucero conserva el ID 26 y sus atributos.


## 0.0.49

**Pedido.** Retirar los PDC de los NPC actuales, introducir raids aleatorias, consola, targeting por clic y detalles de objetivos escaneados.

**Trabajo realizado.** El tráfico empieza con minero y patrulla. Tras una espera aleatoria se evalúan incursiones de una o dos naves con objetivos distintos. La consola física sobre Tab acepta `show_vectors 0/1`. El clic selecciona entidades y T elige la más cercana. El panel bajo el minimapa muestra los detalles del objetivo, con contenido y módulos revelados por el ping.


## 0.0.50

**Pedido.** Autocompletar y recorrer comandos con Tab y mostrar vectores en todos los NPC.

**Trabajo realizado.** Tab completa por prefijo y recorre las coincidencias. También permite alternar los valores 0 y 1 de show_vectors. Las flechas tienen una longitud mínima visible aun sin empuje y siguen el rumbo del casco si la nave está quieta. Se actualizó la velocidad de los mercantes que usan rutas comerciales.


## 0.0.51

**Pedido.** Distinguir títulos y contenidos del objetivo y añadir un módulo de escudo con efecto de silueta, regeneración y botín NPC.

**Trabajo realizado.** Títulos Segoe UI en negrita y datos Consolas. Escudo en ranura de defensa, con icono blanco, capacidad del 50 % del casco por módulo y daño sobrante al casco. Se regenera tras 10 s sin daño, al 50 % de su capacidad por minuto. Efecto de 0,6 s sobre la silueta alfa con borde #2bfbf5 e interior con 40 % de transparencia. Los NPC tienen 20 % de probabilidad de llevarlo y 20 % de soltarlo si lo llevan. La carga y la espera del escudo del jugador se guardan.


## 0.0.52

**Pedido.** Añadir una guía de continuidad para IAs, dos prompts reutilizables, el destello de rotura del escudo y una propuesta de seis facciones con lore.

**Trabajo realizado.** Se añadió AI_LIGHTHOUSE.md con estado, decisiones y próximos pasos, junto con instrucciones de mantenimiento y prompts separados. Al agotarse el escudo aparece un pulso blanco sobre su silueta durante 0,28 s. Se preparó un dosier editorial de facciones. Las barras de escudo quedan pendientes para la próxima revisión de interfaz.


## 0.0.53

**Pedido.** Módulo FTL de utilidad, alcance de tres sistemas, confirmación desde el mapa, recarga de cinco minutos, bloqueo del escudo un minuto y transiciones de llegada/salida de los traders.

**Trabajo realizado.** Se añadió FTL (ID 10), vendido a 5.000 Créditos. El alcance se mide por el camino mínimo de puertas. El mapa permite seleccionar destinos conocidos y confirmar el salto. Cooldown y bloqueo se guardan. Traders y mercantes lo llevan de fábrica y tienen 10 % de probabilidad de soltarlo. Se generó un atlas de seis fotogramas y se añadieron estallido, desaceleración de llegada y aceleración de salida.


## 0.0.54

**Pedido.** Corregir el cuadrado gris en la animación FTL y dar al humo un borde redondo y natural.

**Trabajo realizado.** Se generó una nueva versión del atlas con nubes circulares. El render aplica una máscara radial suave y transparencia total en los bordes de cada celda. El efecto se desvanece al terminar y los fotogramas procesados se reutilizan desde caché.


## 0.0.55

**Pedido.** Añadir estaciones BI, TRI y astillero, con sus atraques, y autoatraque manteniendo B desde cualquier solape con la zona verde.

**Trabajo realizado.** Ícaro en 4109 tiene dos puertos normales y dos Dread. Tríada en 4110 tiene seis normales y tres Dread, radiales al origen. Forja en 4111 reserva la compra futura de naves y dispone de dos puertos normales y uno Dread. Las nuevas estaciones usan colisión de silueta, casco, regeneración, mercados y persistencia propios. Mantener B alinea, centra y frena la nave. Atraca tras un segundo continuo cumpliendo las condiciones. Soltar B cancela.


## 0.0.56

**Pedido.** Puertos de la TRI paralelos por ala, orientación anterior en las demás, un solo puerto compartido en el astillero, atraque directo si B se pulsa en posición correcta y deselección con doble clic en vacío.

**Trabajo realizado.** Cada par de la TRI comparte el eje de su ala. BI mantiene centros y recupera sus ejes cardinales. Forja usa un único atraque universal para todas las clases. B atraca inmediatamente si cumple las condiciones; mantenerlo permite la asistencia y su cuenta final de un segundo. El doble clic vacío limpia cualquier objetivo y el clic simple vacío lo conserva.

## stationBuilder 1.0 · herramienta compartida

**Pedido.** Crear un programa para componer estaciones con PNG arrastrables, giro, escala, duplicación, orden de capas y hardpoints de puertos normales, Dread y PDC. Exportar la estación como PNG para asignarle atributos posteriormente.

**Trabajo realizado.** Se entrega `stationBuilder-1.0.exe`, editor Windows independiente y compartido por ambas ediciones. Incluye composición por capas, edición de posición, giro y escala, selección por transparencia, pivote configurable y colocación de puertos con las medidas vigentes del juego. Guarda PNG transparente sin guías, proyecto `.station.json` con los recursos incorporados y ficha `.hardpoints.csv`. Puede reabrirse sin los PNG originales. El formato ampliado de hardpoints requiere adaptación al integrar la estación en el juego. Fuente y compilación disponibles en `StationBuilder.cs` y `build-station-builder.ps1`; manual en `documentation/stationBuilder.md`. Compilación y prueba `--smoke` correctas con código 0, incluyendo arrastre, orden, transformaciones, exportación y reapertura. Se revisó la interfaz renderizada con TRI. El juego continúa en 0.0.56; esta entrega tiene numeración propia y no modifica sus ejecutables ni guardados.

## stationBuilder 1.1 · herramienta compartida

**Pedido.** Controles de tamaño y escala en el recuadro seleccionado, menú contextual para eliminar y ordenar, giro directo de puertos y PDC y movimiento del plano manteniendo el clic derecho.

**Trabajo realizado.** Se entrega `stationBuilder-1.1.exe`. Las cuatro esquinas del PNG ajustan su escala conservando proporciones; un círculo exterior controla el giro de PNG, puertos normales, Dread y PDC. Se muestran dimensiones, escala y ángulo. El clic derecho abre al soltar un menú de eliminar, traer al frente o enviar al fondo para PNG y de eliminar para hardpoints. Un arrastre derecho desde cinco píxeles desplaza sólo el plano y suprime el menú. Se conservan el botón central, los campos del panel y los proyectos de 1.0. Compilación sin advertencias y prueba --smoke con código 0 para los controles, el menú, la separación entre clic y arrastre, y exportación/reapertura. Revisión visual con TRI realizada. Manual, doc.md y AI_LIGHTHOUSE actualizados. Herramienta compartida por ambas ediciones; juego sin cambios en 0.0.56.

## stationBuilder 1.2 · herramienta compartida

**Pedido.** Ampliar el menú de clic derecho, separar el guardado editable de la exportación del juego y permitir deformar los PNG por eje.

**Trabajo realizado.** El menú permite copiar, pegar en el punto pulsado, duplicar y girar 90° a ambos lados. Los rombos de los laterales y los campos X/Y ajustan cada eje local. Guardar proyecto genera el archivo editable y Exportar PNG genera el sprite y la ficha de hardpoints. El editor abre los proyectos anteriores y guarda la deformación en el formato 2. Compilación y prueba --smoke con código 0. Ejecutable stationBuilder-1.2.exe.

## stationBuilder 1.3 · herramienta compartida

**Pedido.** Seleccionar varios objetos con Ctrl+clic, copiar y pegar con Ctrl+C y Ctrl+V y mover la selección con las flechas.

**Trabajo realizado.** Se entrega stationBuilder-1.3.exe. La selección mixta permite arrastrar, copiar, pegar, duplicar, girar, eliminar y reordenar capas. El pegado conserva la disposición y las flechas desplazan un píxel por pulsación o repetición. Compilación y prueba --smoke con código 0.

## 0.0.57

**Pedido.** Incorporar la estación creada con stationBuilder al sector inicial, con mercado y hardpoints. Actualizar la ficha de flota en PNG claro y Markdown y generar el mapa actual.

**Trabajo realizado.** Cénit se añade al sector 4107 en (1.850, 1.250), a 2.233 unidades de Salvia. Conserva los cuatro atraques normales, un Dread y cuatro PDC del CSV. Tiene 42.000 puntos de casco, colisión por silueta, mercados propios y persistencia independiente. Los mapas colocan las estaciones descubiertas por sector y coordenadas reales. Los mineros eligen la estación más cercana de su sector para descargar. Se corrigió la cobertura de módulos de los mercados adicionales y el muestreo de colisión en la proa de los cascos anchos. Se publican la flota de 27 naves en tema claro, su tabla Markdown y el mapa completo de cinco sectores y seis conexiones.

## 0.0.58

**Pedido.** Nombrar las naves 09 a 17, reclasificar 15 a 17 como Battleship y renombrar los portanaves 22 y 23 como Nyx y Chimera.

**Trabajo realizado.** Se actualizaron los dos catálogos. En orden de selector, 09 a 17 son Leviatán, Mastodonte, Coloso, Alción, Azor, Centella, Bastión, Baluarte y Tempestad. Las tres Battleship reciben las ranuras estándar 4 / 2 / 2 / 2. Se conservan IDs, sprites y atributos físicos. Se generaron la ficha Markdown y el PNG claro de 0.0.58. C# superó --smoke y Godot se exportó y arrancó sin errores.
