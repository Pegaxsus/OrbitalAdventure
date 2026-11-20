# Lanzamientos de Godot

Historial reconstruido a partir de las entregas del proyecto. Las compilaciones de prueba sin número conservan su identificación original.

## 0.1.17 · Umbral, ambientes por capas y prospección

**Pedido.** Estación en E7-UUH y mapa PNG; varios sprites de ambiente superpuestos; asteroides por material, incluidos gigantes; espectrómetro equipado que informe cantidades globales; puertas a 200–500 unidades del borde.

**Trabajo realizado.** Estación Umbral BI añadida al final del catálogo (índice 15), con mercados, industria y cuatro puertos. Tres capas por perfil con transparencias y paralaje, manteniendo efectos del ambiente principal. 23 sprites transparentes originales por material bruto, colores poco saturados e hielos azules. Entre dos y cuatro gigantes por sector, 299 en total, diámetro 300–480, más mineral y más tiempo de minería. Espectrómetro de materiales ID 13, utilidad, compra 2.600/venta 1.300, stock 2: TAB equipado muestra una instantánea de todos los materiales restantes, incluidos especiales, sin ubicaciones. 232 entradas de puerta con margen exterior 200–500 y zonas despejadas; tráfico y respawn adaptados. Catálogos y guardados antiguos compatibles, sin desplazar IDs. Mapas y documentación actualizados.

**Verificación.** Nuevas regresiones de catálogo, gigantes, márgenes, llegada, cantidades, compra, equipamiento, guardado/carga y migración. 46 naves por 16 estaciones: 5.484 atraques manuales y 736 automáticos por edición. Imágenes, alfa y renderizados inspeccionados. Detalle en lore/maps/exploracion-0.1.17.md; prompts de generación integrados junto al catálogo. Los efectos pendientes de los otros ambientes no se implementan.

## 0.1.16 · Nube criogénica y Termorregulador Boreal

**Pedido.** Asociar criogenia a sistemas de hielo, ralentizar progresivamente a las naves, añadir inmunidad de utilidad y efecto de escarcha, y registrar otros pendientes en GitHub Projects/In progress.

**Trabajo realizado.** Verificadas las 17 asignaciones de hielo a cryo-cloud. Reducción de velocidad de 10 % al entrar y 10 puntos por minuto, máximo 80 %. Exposición individual por visita para jugador/NPC, incluidos mercantes. Reinicio al cambiar de sistema; contador pausado atracado/con las pausas existentes. Termorregulador Boreal (ID 12, utilidad, compra 1.800/venta 900, dos unidades iniciales por estación) anula ralentización y escarcha al equiparse. Máscara cristalina proporcional, sobre el alfa de la nave y HUD de frío. Exposición del jugador/mercante persistida y migración de mercados/guardados antiguos. Detector raro permanece sin stock. No cambian sprites, colisiones, atributos ni hardpoints.

**Pendientes.** Seis fichas añadidas a In progress de Projects: otros ambientes, ensamblaje/salvaging, hangares, territorios/facciones, barras de escudo y mejoras industriales/detector. Alcance en documentation/pendientes.md. Los otros ambientes aún no reciben efectos. No se ha publicado código.

**Verificación.** Criogenia: escalones/límite, inmunidad equipada, NPC nuevos/protegidos, compra, guardado/carga, mercantes, salida por puertas y cambio de sistema. C# --smoke completo y seis regresiones Godot pasan, incluidas 5.300 pruebas manuales/690 de autoatraque. Escarcha renderizada e inspeccionada en ambas ediciones. Reglas y láminas en lore/maps/criogenia.md.

## 0.1.15 · Comando sector_stats

**Pedido.** Activar y ocultar estadísticas del sector desde consola con valores 1 y 0.

**Trabajo realizado.** Nuevo comando sector_stats 0/1, autocompletado del nombre y valores con Tab. Panel superior derecho junto al minimapa: nombre, cantidad y destinos de conexiones, NPC vivos y perfil exacto del fondo. Datos actuales en cada dibujo; incluye conexiones no exploradas por ser depuración. Desactivado al arrancar, sin persistencia. Disponible en Godot y C#.

**Verificación.** Regresión de los 100 sectores, activación/desactivación, valor inválido y autocompletado; C# --smoke completo superado. Ejecutables 0.1.15.

## 0.1.14 · Atraque de Ocaso y auditoría de flota

**Pedido.** Corregir el atraque de Ocaso y revisar otras naves con conflictos.

**Trabajo realizado.** Ocaso no cumplía90 % de cobertura en los puertos normales:67deancho frente a58delpuerto. La selección ahora comprueba dimensiones y despeje del casco/entrada, usando capitales cuando una nave menor no dispone de un normal compatible. Ocaso sigue siendo Battleship y conserva sus atributos. Un puerto normal personalizado suficientemente ancho sigue siendo válido. Se protege la lista vacía y se remapean atraques antiguos incompatibles. La compatibilidad se cachea sin persistirla.

**Corrección adicional Godot.** Se duplica Image antes de redimensionar fondos/rotar/crear escudos, para no mutar imágenes compartidas. Cénit conserva su máscara original860×860, eliminando colisiones falsas detectadas con Covetor, Luminaria e Incandescencia.

**Verificación.** Las46naves frente a15estaciones:5.300casos manuales y690automáticos por edición, con ambos sentidos de atraque, colisiones, puertos personalizados, remapeo y ausencia de puertos. C# --smoke y Godot test-docking.gd pasan. Informe en lore/fleets/atraques-0.1.14.md. No se cambian posiciones/tamaños de puertos ni atributos/hardpoints del usuario.

## 0.1.13 · Ocho ambientes para todo el mapa

**Pedido.** Crear cuatro bocetos adicionales para disponer de ocho ambientes y aplicar uno a cada sector.

**Trabajo realizado.** Aurora solar, Vacío profundo, Nube criogénica y Tormenta iónica amplían los cuatro tipos originales. Se asignan fondos a los 100 sectores; los 17 sistemas de hielo usan Nube criogénica. Nácar y Vesper conservan sus variantes históricas. PNG transparentes, bordes suaves y opacidad por perfil, compatibles con los perfiles antiguos de siete columnas. Se mantienen paralaje, estrellas y legibilidad. Catálogo y lámina de ocho tipos, prompts de generación, tabla de sectores y mapa PNG con leyenda de ambientes. Fondos puramente visuales: no cambian conexiones, facciones o recursos.

**Verificación.** C# --smoke y Godot test-backgrounds.gd comprueban cobertura, recursos, bordes y las variantes preservadas. Se renderizan los ocho perfiles en ambas ediciones; se revisan escenas de juego y lámina/mapa. Regresiones de Cluster01 e industria superadas. Ejecutables 0.1.13 en raíz.

## 0.1.12 · Pérdidas sólo en refinado

**Pedido.** Procesado, fabricación y futuro ensamblaje al 100 %, sin pérdidas; sólo el refinado pierde material.

**Trabajo realizado.** Se fija el rendimiento de toda etapa distinta de Refinado al 100 %, incluso si datos históricos de estación indican otro valor. Refinado conserva recuperación 95 % y eficiencia inicial de estación 80 % (10 U de cobre → 7,6 U). Se conservan saldos y partidas anteriores. Configuración, pruebas, tabla Markdown y PNG actualizados. El ensamblaje sigue pendiente, con regla de eficiencia 100 % documentada.

**Verificación.** C# --smoke y regresión industrial de Godot: 65 recetas, componentes completos y electrólisis sin pérdidas; refinado y persistencia conservados. Ejecutables 0.1.12 en raíz.

## 0.1.11 · Etapas industriales y eficiencia de estación

**Pedido.** Aclarar refinado y procesado/fabricación, reclasificar productos, añadir tritio/xenón escasos y componentes del esquema, y trasladar la eficiencia de producción a cada estación. Ensamblaje final y artefactos quedan pendientes.

**Trabajo realizado.** Catálogo de 88 entradas: 23 brutos, 36 procesados y 29 componentes; 65 recetas. Nuevos combustibles escasos con composición determinista y stock inicial cero, conservando el 80 % de hielo agua/metano. Se incorporan blindaje, condensadores, bodegas, informática, hangares, montajes, regulación, reactores, mantenimiento, drones, sensores, armamento y propulsión. No modifican hardpoints ni permisos de cazas. Las recetas guardan producción de diseño; el refinado aplica recuperación general 95 % y después eficiencia de estación. Todas parten de 80 % en refinado/fabricación, configurables por estación. Se conservan fracciones con precisión 0,0001 U, visibles y persistentes, utilizables al completar unidades. Diez U de cobre producen 7,6 U al 80 % o 9,5 U al 100 %. Se migran inventarios de diez/71 materiales y guardados previos, sin renumerar IDs. Imagen y tablas actualizadas en lore/industry.

**Verificación.** Pruebas de las 65 recetas, cálculos independientes de eficiencia, conservación por lotes, progreso parcial, persistencia y migración, nuevos combustibles y proporción de hielo. C# supera --smoke y Godot test-industry.gd y test-cluster.gd. Revisión de interfaz y tabla visual. Ejecutables 0.1.11 en raíz; actualizados documentación y Lighthouse.

## 0.1.10 · Materiales, especiales ocultos e industria

**Pedido.** Clasificar combustibles, construcción y especiales; añadir cinco elementos y seis minerales ficticios, conservar salvaging, sortear trazas ocultas por sesión y definir detector raro y crafting con documentación visual.

**Trabajo realizado.** Catálogo compartido de 71 materiales/productos, incluidos 21 recursos brutos. Tungsteno, cromo, cobalto, magnesio y molibdeno amplían construcción; tierras raras pasan a especiales junto con veltrita, naurita, oraxita, silexio, terina y cuarión. Se distribuyen depósitos de 1–3 U en 3–7 asteroides vivos por sector al iniciar/cargar; TAB normal no los muestra. Sólo una nueva carga redistribuye depósitos: el respawn no los repone. Detector de trazas ID 11 de utilidad, sin stock, equipo inicial, portadores ni drops. Industria de estación [F] implementa 50 recetas y lotes de 1/10 con consumo atómico y almacén persistente: refinado, electrólisis/pirólisis, aleaciones, placas, tubos, chips y componentes avanzados para futuro ensamblaje. Mercados paginados y vista de materiales. Se preservan IDs antiguos, prefijos de guardado y salvaging. El PNG y las tablas están en lore/industry. El servicio es instantáneo y gratuito por ahora; no ensambla naves ni módulos equipables.

**Corrección.** C# admite guardados de 26 líneas generados desde 0.1.9, además de los formatos anteriores.

**Verificación.** C# supera --smoke con todas las recetas, trazas, detector, no reposición, guardado/carga y migración. Godot supera test-industry.gd y la regresión de Cluster01; se renderiza la nueva interfaz y se revisa el PNG de recetas. Las partidas y fichas originales se comprueban mediante hashes. Se generan ambos ejecutables 0.1.10.

## 0.1.9 · Cluster01 y alcance FTL de Carrier

**Pedido.** Añadir el clúster de la referencia con acceso por 4110, nombres propios, sistemas de hielo y estaciones según el tipo de marco. Triplicar el alcance FTL de Carrier y actualizar el mapa.

**Trabajo realizado.** Se incorporan 91 sectores, 17 de hielo y 6 con estación, para un total de 100 sectores, 116 enlaces y 15 estaciones. Se conservan los enlaces e IDs anteriores. Las dos entradas nuevas parten de 4110. Los sectores quedan sin facción asignada. Los sistemas de hielo tienen 512 de 640 asteroides de agua/metano. El rasgo long_ftl de los seis Carrier multiplica por tres el rango: 9 enlaces con el módulo actual; recarga de 300 s y bloqueo de escudo de 60 s. El mapa admite zoom y desplazamiento, distingue estaciones e hielo y usa los códigos nuevos. La consola tp acepta nombres de sector. Se elimina el límite de bits para descubrimiento y rutas, conservando la lectura de partidas anteriores. Se entrega el PNG actualizado y la correspondencia con la referencia.

**Verificación.** Pruebas de conectividad, puertas, estaciones, composición de hielo, alcance FTL y descubrimiento sobre índices altos. C# supera --smoke; Godot supera build/test-cluster.gd, incluida migración de una partida de nueve sectores. Se generan y comprueban ambos ejecutables.

## 0.1.8 · Flota del Imperio de Helión

**Pedido.** Añadir once naves de Helión con las clases indicadas en los PNG y atributos propios. Mantener la restricción de cazas en todas las clases menores de Carrier salvo rasgo específico.

**Trabajo realizado.** El catálogo crece de 35 a 46 cascos. Los IDs 35–45 incorporan dos Fragatas, tres Cruceros, tres Battleships, un Dreadnought y dos Carrier. Se asignan nombres, casco, masa, empuje, longitud, carga y ranuras. Los PNG se integran en assets/ships y la interfaz muestra la facción Helión. Los catálogos de ambas ediciones coinciden y shipConfigurator 1.6 lee los cascos nuevos. Las fichas de hardpoints quedan para el usuario. Se comprobaron las direcciones de equipo, la ampliación de escudos guardados y las reglas de cazas.

**Corrección dentro de 0.1.8.** Se sustituye el PNG de Luminaria (ID 39, Crucero03) por «Portaaviones espacial industrial desde arriba.png», solicitado por el usuario. Se recompilan ambas ediciones con la misma versión.

## 0.1.7 · Clase Carrier y permisos de hangar

**Pedido.** Reclasificar Firmamento, Leviatán, Nyx y Chimera como Carrier. Reservar los cazas para Carrier y Titán, con una excepción por rasgo para futuras naves menores. Dreadnought conserva los drones.

**Trabajo realizado.** Los cuatro cascos pasan a Carrier, claseID 5. Titán reserva claseID 6. Se actualizan ambos catálogos, la carga de anclajes y shipConfigurator 1.6. El rasgo fighter_hangar habilita cazas mediante el parámetro habilita_cazas. Los anclajes incompatibles se conservan en las fichas y se omiten al cargar el juego. Los atraques capitales admiten los Carrier. Se verificaron los 35 cascos, la excepción por rasgo y la lectura de anclajes antiguos. El vuelo y recuperación de cazas y drones siguen pendientes.

## 0.1.6 · Ambientes por sector

**Pedido.** Documentar los seis conceptos de fondo y preparar los cuatro bocetos para futuros sistemas.

**Trabajo realizado.** Arco de gas, Velo de polvo, Límite planetario y Remanente de supernova se incluyen como PNG con transparencia y perfiles configurables. Las asignaciones de Nácar y Vesper siguen vigentes. El catálogo en lore/maps documenta también Vacío profundo y Aurora solar.

## 0.1.5 · Organización del proyecto

**Pedido.** Reunir el arte por categorías, separar atributos y datos, centralizar la ambientación y limpiar la raíz.

**Trabajo realizado.** Proyecto importable desde la raíz. Rutas actualizadas en escenas, scripts y perfil de exportación. Conserva los guardados en savegames/godot. shipConfigurator 1.3 usa el catálogo, los sprites y los hardpoints reubicados. Los ejecutables vigentes se entregan en la raíz y las versiones anteriores se archivan en releases/.

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

## 0.0.59

**Pedido.** Añadir la constelación del Imperio de Asterión, accesible por una única puerta exterior desde 4111. Usar la estación entregada para la capital con astillero, añadir guardias Stratios, aumentar la actividad pirata del sector sin estación y actualizar el mapa.

**Trabajo realizado.** Se añadieron 4112 (Ciudadela Asterión), 4113 (Meridiano), 4114 (Linde) y 4115 (Vesper). La ruta de puertas es 4111–4112–4113–4115–4114. Las cuatro marcas usan el nuevo escudo azul de Asterión. La Ciudadela integra el astillero y conserva los anclajes de stationBuilder. Meridiano y Linde tienen mercados propios. Las tres Stratios de la capital llevan escudo de 75 % del casco y propulsión un 25 % superior a la de una patrulla normal. Cada baja inicia 1.800 segundos de simulación, guardados en la partida. Vesper recibe oleadas de 3–4 piratas con más frecuencia y mercantes de tránsito. Se verificaron ambas ediciones y se entregó el nuevo mapa.

## 0.0.60

**Pedido.** Añadir ocho cascos de Asterión con fondo transparente, clase, nombre y atributos. Afiliar la Stratios y reforzar la capital con dos cruceros del sprite crucero1 y un Battleship del sprite battleship1 desarmados hasta preparar sus hardpoints.

**Trabajo realizado.** La flota suma 35 naves. Los IDs nuevos 27–34 son Vigía, Sextante, Alidada, Equinoccio, Solsticio, Eclíptica, Firmamento y Horizonte. Stratios y los ocho cascos llevan la facción asterion en ambos catálogos. Ciudadela Asterión conserva las tres Stratios reforzadas y añade dos Alidada y una Eclíptica. Estos refuerzos habilitan la ametralladora al cargar su hardpoint número 0. Los seis puestos conservan el respawn de 30 minutos. Las nuevas ranuras usan un bloque independiente para mantener las direcciones anteriores. La ficha flota-0.0.60.md incluye atributos e IDs para shipConfigurator.

## 0.1.0

**Pedido.** Investigar la compra de FTL en Linde, mantener presencia pirata habitual en 4115, indicar el destino de las puertas y sustituir los círculos por un sprite.

**Trabajo realizado.** El FTL cuesta 5.000 Créditos. El botón cortaba el último dígito y mostraba 500 en la captura. Los botones del mercado ajustan el texto al espacio disponible y distinguen el aviso de falta de stock del aviso de saldo insuficiente, que muestra el coste total y el importe que falta. Vesper genera una patrulla pirata de 3–4 naves al entrar y revisa su relevo cada 10–18 s cuando no queda ninguna nave combativa. Las puertas usan el sprite jump-gate.png. Después de cruzar, la etiqueta de cada extremo muestra el sector de destino. Seleccionar una puerta con clic muestra ese destino en el panel de objetivo.

## 0.1.1

**Pedido.** Redibujar la puerta en 2D, quitar el límite aparente de motores en el editor y restringir cohetes y misiles en cuatro naves mineras.

**Trabajo realizado.** La puerta usa un anillo pixel art frontal sin perspectiva. shipConfigurator 1.1 muestra el recuento de motores como puntos sin límite y permite guardarlos por encima del número de ranuras. Procurer, Retriever, Covetor y Rorqual tienen el rasgo no_ordnance. Bloquea instalar y usar cohetes y misiles. Los módulos de guardados anteriores quedan inactivos hasta retirarlos.

## 0.1.2

**Pedido.** Quitar los anclajes de láser, ametralladora, minería y salvaging de Firmamento, Chimera, Nyx y Leviatán, renombrar la nave 24 a Phoenix y actualizar la flota.

**Trabajo realizado.** Se añadió el rasgo no_direct_tools a los cuatro cascos, se retiraron los anclajes incompatibles de sus fichas y se bloqueó su uso y su instalación en ambas ediciones. shipConfigurator 1.2 indica los tipos incompatibles. Phoenix conserva su ID. Se regeneraron el Markdown y la imagen clara de las 35 naves.

## 0.1.3

**Pedido.** Probar un fondo de nebulosa que se mezcle con las estrellas del sector 4108.

**Trabajo realizado.** Se añadió una nube azul generada con ruido de varias escalas y alfa progresivo en los bordes. Se dibuja una sola vez por vista, anclada a Nácar, con paralaje y zoom moderado. La prueba está disponible en vuelo en ambas ediciones.

## 0.1.4

**Pedido.** Añadir una nebulosa roja intensa a 4115 y permitir el teletransporte por consola con tp.

**Trabajo realizado.** Vesper tiene una nebulosa roja más intensa con paralaje y transparencia gradual. La consola acepta tp seguido del número de sector. El salto coloca la nave en vuelo, carga el sector y conserva el estado del FTL y el historial de puertas. Un número inexistente no cambia la partida.
