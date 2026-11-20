# Materiales e industria · 0.1.12

[Tabla visual de recetas](crafting-0.1.12.png). Implementado en Godot y C#: **23 materiales base, 36 materiales procesados, 29 componentes y 65 recetas**. El esquema acordado es **base → refinado → materiales procesados → procesado/fabricación → componentes → ensamblaje final futuro**. Algunos procesados tienen uso directo o requieren nuevas transformaciones antes de convertirse en componentes.

## Familias y etapas

- **Combustibles base:** hielo de agua, metano, tritio y xenón.
- **Construcción base:** hierro, aluminio, titanio, cobre, silicio, carbono, níquel, tungsteno, cromo, cobalto, magnesio y molibdeno.
- **Especiales base:** tierras raras, veltrita, naurita, oraxita, silexio, terina y cuarión. Los seis últimos y sus propiedades son ficticios.
- **Procesados:** agua y gases purificados, hidrógeno, oxígeno, lingotes, obleas, carbono purificado, concentrados/cristales, aleaciones, barras, cables, vidrio, cerámica, propulsor y refrigerante.
- **Componentes:** placas, tubos, bastidores, chips/circuitos, piezas de construcción y conjuntos industriales. Que algo se fabrique no implica que sea un módulo equipable ni que añada hardpoints.

Los 71 IDs previos se conservan con sus cantidades. Sólo cambian sus etiquetas de etapa cuando corresponde. Nuevos IDs 71/72: tritio/xenón; 73/74: sus productos purificados; 75–87: componentes nuevos. El ID 60 pasa a llamarse Piezas de construcción. La lista de componentes es extensible y no exige todos los componentes para todas las clases de nave.

## Rendimiento y eficiencia de estación

La receta especifica los ingredientes y la producción de diseño, **sin codificar una eficiencia de máquina**. El refinado tiene una recuperación física general del **95 %**; después se aplica la eficiencia de la estación. La eficiencia base de refinería es **80 %**, configurable por estación en `attributes/station-industry.txt`. **Procesado, fabricación y ensamblaje tienen siempre eficiencia 100 %, sin pérdidas**, independientemente de la refinería o de cualquier valor histórico de fabricación en los datos. La mejora por módulos de estación queda para el futuro.

| Operación | Fórmula | Ejemplo |
| --- | --- | --- |
| Refinado | Producción de diseño × 0,95 × eficiencia de refinería | 10 U de cobre → 9,5 U a eficiencia 100 %; **7,6 U al 80 %** |
| Procesado/fabricación/ensamblaje | Producción de diseño × 1 | Receta de 1 componente → **1 completo**, sin pérdidas |
| Lotes | Se aplica a todo el lote sin redondear por unidad | Diez lotes de cobre de 10 U producen 76 U al 80 % |

Las transformaciones químicas conservan sus proporciones de diseño. Las aleaciones y otros productos a granel ya no incluyen las pérdidas fijas de las recetas anteriores. El número de piezas de una receta de fabricación expresa cuántas piezas se diseñan con esos ingredientes, no un porcentaje de eficiencia. Sólo el refinado aplica pérdidas. El procesado y la fabricación conservan todos sus resultados de diseño, incluidos los procesos con varias salidas.

**Decimales sin pérdida:** se lleva un saldo industrial del jugador por material, con precisión de 0,0001 U. Las unidades completas pasan al inventario y las fracciones se acumulan, se muestran en Materiales y se guardan/cargan. Por ejemplo, 7,6 U son 7 U disponibles y 0,6 U de saldo. Sólo las unidades completas se consumen en recetas, se venden o transportan; el resto no desaparece. Las fracciones nuevas sólo proceden del refinado. Los saldos anteriores, incluidos los de componentes de 0.1.11, se conservan sin redondear ni eliminar. El saldo acompaña al almacén global del jugador, también al cambiar de estación; la eficiencia de estación sólo interviene al refinar.

## Uso y alcance

Atracado, abre **Industria [F]**, descarga con **U**, selecciona receta y fabrica lotes de 1 o 10. Hay páginas/rueda y una pestaña Materiales. Se muestran la producción efectiva por lote, la de diseño y la eficiencia de estación. Se verifican todos los ingredientes y el límite de inventario antes de consumir nada. Sin ingredientes, o con refinería deshabilitada (0 %), no se consume nada. Procesado/fabricación no dependen de ese porcentaje.

La estación proporciona energía e instalaciones de forma abstracta: servicio instantáneo y gratuito, sin colas ni mantenimiento todavía. Agua, gases y componentes se almacenan; no activan consumo de combustible, soporte vital ni nuevas funciones de nave. **Las tablas de ensamblaje de naves, estaciones y módulos equipables se crearán más adelante.** Los artefactos, sus eventos, colección, venta y decoración quedan para un futuro lejano.

Los componentes de construcción no tienen relación directa con los anclajes de un casco. Una Bahía de hangar fabricada es un ingrediente para futuras naves que la requieran; no equipa cazas ni añade slots. Una fragata no requerirá Hangar Bay en su receta. Se mantienen los permisos de cazas Carrier/Titán y las excepciones explícitas por perk.

## Tritio y xenón

Son combustibles brutos **escasos y visibles al escanear normalmente**, distintos de las trazas especiales ocultas. Tras generar el campo, cada asteroide elegible tiene un 1 % de probabilidad de contener uno de los dos, con selección equiprobable. En sectores ordinarios son elegibles todos; en hielo, sólo el 20 % que no pertenece al agua/metano. Esto conserva exactamente 512/640 asteroides de agua/metano y deja una incidencia media de combustibles escasos cercana al 0,2 % del total en esos sistemas. Un sistema puede no contener uno o ambos.

La distribución es determinista por sector, se conserva por generación al cargar y forma parte de la composición ordinaria del asteroide. Se extraen con minería normal y se refinan en sus productos purificados. No tienen stock comercial inicial ni se añaden al stock de traders. El respawn conserva su composición habitual. No se consumen todavía para propulsión o reactores; sus aplicaciones finales quedan pendientes.

## Especiales y salvaging

Se conserva la mecánica de 0.1.10: iniciar/cargar redistribuye 1–3 U en 3–7 asteroides vivos por sector, limitado a los disponibles. TAB normal no revela las trazas; el Detector de trazas ID 11 de utilidad permite detectarlas. Sigue sin stock, equipo inicial, portadores, drops ni receta de ensamblaje. Fabricar un Sensor de trazas o Conjunto de sensores produce componentes, no este módulo.

Minar suelta un fragmento especial y vacía la traza. La sobrecarga reduce el rendimiento al 10 %, mínimo 1 U. Los mineros NPC consumen las trazas de los asteroides que extraen sin generar botín especial. Respawn, guardar, FTL y cambio de sector no reponen especiales; cargar sí. Las trazas/revelación no se guardan, pero sí los materiales ya obtenidos, fragmentos y saldos industriales.

**Salvaging sin cambios:** cobre, hierro, titanio o aluminio brutos; 3, 5 o 7 U por resto. Su procesamiento posterior usa la misma refinería que los materiales minados.

**Decisión futura confirmada:** el salvaging recuperará componentes o materiales refinados en función de los componentes que tenga la nave destruida o que haya requerido su construcción. El contenido recuperable dependerá de esa nave, en lugar de la tabla genérica actual. Esta regla se definirá e implementará cuando se asignen los componentes de construcción a cada nave. Las cantidades, probabilidades y proporciones de recuperación quedan pendientes; no se presuponen. Hasta entonces se conserva el comportamiento actual en ambas ediciones. Esta decisión no convierte automáticamente el salvaging en botín directo al destruir una nave.

## Catálogo

| ID | Material | Familia | Etapa | Rareza de origen |
| ---: | --- | --- | --- | --- |
| 0 | Hielo de agua | combustible | bruto | comun |
| 1 | Metano | combustible | bruto | comun |
| 2 | Hierro | construccion | bruto | comun |
| 3 | Aluminio | construccion | bruto | comun |
| 4 | Titanio | construccion | bruto | comun |
| 5 | Cobre | construccion | bruto | comun |
| 6 | Silicio | construccion | bruto | comun |
| 7 | Carbono | construccion | bruto | comun |
| 8 | Níquel | construccion | bruto | comun |
| 9 | Tierras raras | especial | bruto | oculto |
| 10 | Tungsteno | construccion | bruto | comun |
| 11 | Cromo | construccion | bruto | comun |
| 12 | Cobalto | construccion | bruto | comun |
| 13 | Magnesio | construccion | bruto | comun |
| 14 | Molibdeno | construccion | bruto | comun |
| 15 | Veltrita | especial | bruto | oculto |
| 16 | Naurita | especial | bruto | oculto |
| 17 | Oraxita | especial | bruto | oculto |
| 18 | Silexio | especial | bruto | oculto |
| 19 | Terina | especial | bruto | oculto |
| 20 | Cuarión | especial | bruto | oculto |
| 21 | Agua purificada | combustible | procesado | comun |
| 22 | Metano purificado | combustible | procesado | comun |
| 23 | Lingote de hierro | construccion | procesado | comun |
| 24 | Lingote de aluminio | construccion | procesado | comun |
| 25 | Lingote de titanio | construccion | procesado | comun |
| 26 | Lingote de cobre | construccion | procesado | comun |
| 27 | Obleas de silicio | construccion | procesado | comun |
| 28 | Carbono purificado | construccion | procesado | comun |
| 29 | Lingote de níquel | construccion | procesado | comun |
| 30 | Concentrado de tierras raras | especial | procesado | comun |
| 31 | Lingote de tungsteno | construccion | procesado | comun |
| 32 | Lingote de cromo | construccion | procesado | comun |
| 33 | Lingote de cobalto | construccion | procesado | comun |
| 34 | Lingote de magnesio | construccion | procesado | comun |
| 35 | Lingote de molibdeno | construccion | procesado | comun |
| 36 | Cristal de veltrita | especial | procesado | comun |
| 37 | Cristal de naurita | especial | procesado | comun |
| 38 | Cristal de oraxita | especial | procesado | comun |
| 39 | Cristal de silexio | especial | procesado | comun |
| 40 | Cristal de terina | especial | procesado | comun |
| 41 | Cristal de cuarión | especial | procesado | comun |
| 42 | Hidrógeno | combustible | procesado | comun |
| 43 | Oxígeno | combustible | procesado | comun |
| 44 | Acero | construccion | procesado | comun |
| 45 | Acero inoxidable | construccion | procesado | comun |
| 46 | Superaleación Ni-Co | construccion | procesado | comun |
| 47 | Aleación Al-Mg | construccion | procesado | comun |
| 48 | Carburo de tungsteno | construccion | procesado | comun |
| 49 | Barra de cobre | construccion | procesado | comun |
| 50 | Cable de cobre | construccion | procesado | comun |
| 51 | Placa de acero | construccion | componente | comun |
| 52 | Placa de titanio | construccion | componente | comun |
| 53 | Tubo de acero | construccion | componente | comun |
| 54 | Bastidor ligero | construccion | componente | comun |
| 55 | Vidrio técnico | construccion | procesado | comun |
| 56 | Cerámica térmica | construccion | procesado | comun |
| 57 | Chip básico | construccion | componente | comun |
| 58 | Circuito de control | construccion | componente | comun |
| 59 | Imán de tierras raras | especial | componente | comun |
| 60 | Piezas de construcción | construccion | componente | comun |
| 61 | Sección de casco | construccion | componente | comun |
| 62 | Conjunto de motor | construccion | componente | comun |
| 63 | Matriz de escudo | especial | componente | comun |
| 64 | Sensor de trazas | especial | componente | comun |
| 65 | Núcleo FTL | especial | componente | comun |
| 66 | Mezcla propulsora H-O | combustible | procesado | comun |
| 67 | Refrigerante industrial | construccion | procesado | comun |
| 68 | Soporte de hábitat | construccion | componente | comun |
| 69 | Chasis de dron | construccion | componente | comun |
| 70 | Viga de estación | construccion | componente | comun |
| 71 | Tritio | combustible | bruto | escaso |
| 72 | Xenón | combustible | bruto | escaso |
| 73 | Tritio purificado | combustible | procesado | comun |
| 74 | Xenón purificado | combustible | procesado | comun |
| 75 | Placas de blindaje compuesto | construccion | componente | comun |
| 76 | Batería de condensadores | construccion | componente | comun |
| 77 | Bodega modular | construccion | componente | comun |
| 78 | Sistema informático | construccion | componente | comun |
| 79 | Bahía de hangar | construccion | componente | comun |
| 80 | Montaje de armamento | construccion | componente | comun |
| 81 | Regulador térmico del núcleo | construccion | componente | comun |
| 82 | Núcleo de reactor | construccion | componente | comun |
| 83 | Bahía de mantenimiento | construccion | componente | comun |
| 84 | Bahía de drones | construccion | componente | comun |
| 85 | Conjunto de sensores | construccion | componente | comun |
| 86 | Componentes de armamento | construccion | componente | comun |
| 87 | Sistema de propulsión | construccion | componente | comun |

## Componentes del esquema

| Concepto del usuario | Componente implementado | Alcance |
| --- | --- | --- |
| Armor Plates | Placas de blindaje compuesto; placas de acero/titanio previas | Estructura y protección |
| Capacitor Battery | Batería de condensadores | Reserva eléctrica futura |
| Cargo Bay | Bodega modular | Ingrediente de naves de carga |
| Computer System | Sistema informático | Control de conjuntos complejos |
| Construction Parts | Piezas de construcción | ID 60 conservado |
| Hangar Bay | Bahía de hangar | Futuras naves que la requieran; no fragatas |
| Weapon Mount | Montaje de armamento | Pieza industrial; no crea hardpoints |
| Core Temperature Regulator | Regulador térmico del núcleo | Gestión térmica futura |
| Reactor Core | Núcleo de reactor | Ingrediente industrial; no reactor activo |
| Drone Bay | Bahía de drones | No habilita drones por sí misma |
| Sensor Cluster | Conjunto de sensores | Usa sensores y control |
| Maintenance Bay | Bahía de mantenimiento | Mantenimiento futuro |
| Weapon Components | Componentes de armamento | Ingrediente de armas futuras |
| Propulsion Systems | Sistema de propulsión | Usa conjuntos de motor y regulación |

## Recetas y cantidades por lote

«Teórico» incluye la recuperación del 95 % para el refinado y supone una estación al 100 %. «Actual» aplica 80 % de refinería y 100 % en los demás procesos. No se descartan las fracciones. Las relaciones químicas están simplificadas para el juego; no son instrucciones industriales reales.

### Refinado

| Nº | Proceso | Consume | Teórico | Actual |
| ---: | --- | --- | --- | --- |
| 1 | Refinar Hielo de agua | 10 × Hielo de agua | 9,5 × Agua purificada | 7,6 × Agua purificada |
| 2 | Refinar Metano | 10 × Metano | 9,5 × Metano purificado | 7,6 × Metano purificado |
| 3 | Refinar Hierro | 10 × Hierro | 9,5 × Lingote de hierro | 7,6 × Lingote de hierro |
| 4 | Refinar Aluminio | 10 × Aluminio | 9,5 × Lingote de aluminio | 7,6 × Lingote de aluminio |
| 5 | Refinar Titanio | 10 × Titanio | 9,5 × Lingote de titanio | 7,6 × Lingote de titanio |
| 6 | Refinar Cobre | 10 × Cobre | 9,5 × Lingote de cobre | 7,6 × Lingote de cobre |
| 7 | Refinar Silicio | 10 × Silicio | 9,5 × Obleas de silicio | 7,6 × Obleas de silicio |
| 8 | Refinar Carbono | 10 × Carbono | 9,5 × Carbono purificado | 7,6 × Carbono purificado |
| 9 | Refinar Níquel | 10 × Níquel | 9,5 × Lingote de níquel | 7,6 × Lingote de níquel |
| 10 | Refinar Tierras raras | 2 × Tierras raras | 1,9 × Concentrado de tierras raras | 1,52 × Concentrado de tierras raras |
| 11 | Refinar Tungsteno | 10 × Tungsteno | 9,5 × Lingote de tungsteno | 7,6 × Lingote de tungsteno |
| 12 | Refinar Cromo | 10 × Cromo | 9,5 × Lingote de cromo | 7,6 × Lingote de cromo |
| 13 | Refinar Cobalto | 10 × Cobalto | 9,5 × Lingote de cobalto | 7,6 × Lingote de cobalto |
| 14 | Refinar Magnesio | 10 × Magnesio | 9,5 × Lingote de magnesio | 7,6 × Lingote de magnesio |
| 15 | Refinar Molibdeno | 10 × Molibdeno | 9,5 × Lingote de molibdeno | 7,6 × Lingote de molibdeno |
| 16 | Refinar Veltrita | 2 × Veltrita | 1,9 × Cristal de veltrita | 1,52 × Cristal de veltrita |
| 17 | Refinar Naurita | 2 × Naurita | 1,9 × Cristal de naurita | 1,52 × Cristal de naurita |
| 18 | Refinar Oraxita | 2 × Oraxita | 1,9 × Cristal de oraxita | 1,52 × Cristal de oraxita |
| 19 | Refinar Silexio | 2 × Silexio | 1,9 × Cristal de silexio | 1,52 × Cristal de silexio |
| 20 | Refinar Terina | 2 × Terina | 1,9 × Cristal de terina | 1,52 × Cristal de terina |
| 21 | Refinar Cuarión | 2 × Cuarión | 1,9 × Cristal de cuarión | 1,52 × Cristal de cuarión |
| 51 | Refinar Tritio | 10 × Tritio | 9,5 × Tritio purificado | 7,6 × Tritio purificado |
| 52 | Refinar Xenón | 10 × Xenón | 9,5 × Xenón purificado | 7,6 × Xenón purificado |

### Procesamiento

| Nº | Proceso | Consume | Teórico | Actual |
| ---: | --- | --- | --- | --- |
| 22 | Electrólisis del agua | 9 × Agua purificada | 1 × Hidrógeno + 8 × Oxígeno | 1 × Hidrógeno + 8 × Oxígeno |
| 23 | Pirólisis del metano | 4 × Metano purificado | 3 × Carbono purificado + 1 × Hidrógeno | 3 × Carbono purificado + 1 × Hidrógeno |
| 24 | Acería | 99 × Lingote de hierro + 1 × Carbono purificado | 100 × Acero | 100 × Acero |
| 25 | Acero inoxidable | 7 × Acero + 2 × Lingote de cromo + 1 × Lingote de níquel | 10 × Acero inoxidable | 10 × Acero inoxidable |
| 26 | Superaleación de motor | 5 × Lingote de níquel + 3 × Lingote de cobalto + 1 × Lingote de cromo + 1 × Lingote de molibdeno | 10 × Superaleación Ni-Co | 10 × Superaleación Ni-Co |
| 27 | Aleación ligera | 9 × Lingote de aluminio + 1 × Lingote de magnesio | 10 × Aleación Al-Mg | 10 × Aleación Al-Mg |
| 28 | Sinterizado de carburo | 9 × Lingote de tungsteno + 1 × Carbono purificado | 10 × Carburo de tungsteno | 10 × Carburo de tungsteno |
| 35 | Vidrio de silicio | 3 × Obleas de silicio + 3 × Oxígeno | 6 × Vidrio técnico | 6 × Vidrio técnico |
| 36 | Cerámica técnica | 2 × Obleas de silicio + 1 × Carbono purificado + 1 × Lingote de magnesio | 4 × Cerámica térmica | 4 × Cerámica térmica |
| 46 | Preparar mezcla propulsora | 1 × Hidrógeno + 8 × Oxígeno | 9 × Mezcla propulsora H-O | 9 × Mezcla propulsora H-O |
| 47 | Preparar refrigerante | 4 × Agua purificada + 1 × Carbono purificado | 5 × Refrigerante industrial | 5 × Refrigerante industrial |

### Fabricación

| Nº | Proceso | Consume | Teórico | Actual |
| ---: | --- | --- | --- | --- |
| 29 | Extruir barras | 2 × Lingote de cobre | 2 × Barra de cobre | 2 × Barra de cobre |
| 30 | Trefilar cable | 2 × Barra de cobre | 2 × Cable de cobre | 2 × Cable de cobre |
| 31 | Laminar acero | 3 × Acero | 3 × Placa de acero | 3 × Placa de acero |
| 32 | Laminar titanio | 3 × Lingote de titanio | 3 × Placa de titanio | 3 × Placa de titanio |
| 33 | Formar tubos | 2 × Acero | 2 × Tubo de acero | 2 × Tubo de acero |
| 34 | Montar bastidor ligero | 4 × Aleación Al-Mg + 1 × Lingote de titanio | 4 × Bastidor ligero | 4 × Bastidor ligero |
| 37 | Fabricar chips | 1 × Barra de cobre + 2 × Obleas de silicio | 2 × Chip básico | 2 × Chip básico |
| 38 | Ensamblar circuito | 2 × Chip básico + 2 × Cable de cobre + 1 × Vidrio técnico | 4 × Circuito de control | 4 × Circuito de control |
| 39 | Sinterizar imanes | 1 × Concentrado de tierras raras + 2 × Lingote de hierro + 1 × Lingote de cobalto | 3 × Imán de tierras raras | 3 × Imán de tierras raras |
| 40 | Lote de construcción | 4 × Placa de acero + 2 × Tubo de acero + 2 × Bastidor ligero | 7 × Piezas de construcción | 7 × Piezas de construcción |
| 41 | Fabricar sección de casco | 6 × Piezas de construcción + 3 × Placa de titanio + 2 × Cerámica térmica | 10 × Sección de casco | 10 × Sección de casco |
| 42 | Fabricar conjunto de motor | 4 × Superaleación Ni-Co + 2 × Carburo de tungsteno + 2 × Tubo de acero + 1 × Circuito de control | 8 × Conjunto de motor | 8 × Conjunto de motor |
| 43 | Fabricar matriz de escudo | 1 × Cristal de veltrita + 1 × Cristal de naurita + 2 × Cable de cobre + 1 × Imán de tierras raras | 4 × Matriz de escudo | 4 × Matriz de escudo |
| 44 | Fabricar sensor de trazas | 1 × Cristal de oraxita + 1 × Cristal de silexio + 2 × Chip básico + 1 × Circuito de control | 4 × Sensor de trazas | 4 × Sensor de trazas |
| 45 | Fabricar núcleo FTL | 1 × Cristal de terina + 1 × Cristal de cuarión + 3 × Superaleación Ni-Co + 2 × Circuito de control + 1 × Imán de tierras raras | 7 × Núcleo FTL | 7 × Núcleo FTL |
| 48 | Fabricar soporte de hábitat | 3 × Piezas de construcción + 2 × Vidrio técnico + 1 × Circuito de control + 2 × Agua purificada + 2 × Oxígeno | 9 × Soporte de hábitat | 9 × Soporte de hábitat |
| 49 | Fabricar chasis de dron | 3 × Bastidor ligero + 2 × Circuito de control + 1 × Imán de tierras raras + 1 × Cable de cobre | 6 × Chasis de dron | 6 × Chasis de dron |
| 50 | Fabricar viga de estación | 5 × Acero inoxidable + 3 × Tubo de acero + 2 × Piezas de construcción | 9 × Viga de estación | 9 × Viga de estación |
| 53 | Fabricar blindaje compuesto | 3 × Placa de acero + 2 × Placa de titanio + 1 × Cerámica térmica | 1 × Placas de blindaje compuesto | 1 × Placas de blindaje compuesto |
| 54 | Fabricar batería de condensadores | 2 × Lingote de aluminio + 2 × Cable de cobre + 2 × Carbono purificado + 1 × Cerámica térmica | 1 × Batería de condensadores | 1 × Batería de condensadores |
| 55 | Fabricar bodega modular | 3 × Bastidor ligero + 4 × Piezas de construcción + 2 × Placa de acero | 1 × Bodega modular | 1 × Bodega modular |
| 56 | Fabricar sistema informático | 3 × Chip básico + 2 × Circuito de control + 1 × Cable de cobre + 1 × Refrigerante industrial | 1 × Sistema informático | 1 × Sistema informático |
| 57 | Fabricar montaje de armamento | 2 × Placa de acero + 1 × Lingote de titanio + 1 × Carburo de tungsteno | 1 × Montaje de armamento | 1 × Montaje de armamento |
| 58 | Fabricar regulador térmico | 3 × Tubo de acero + 2 × Refrigerante industrial + 1 × Circuito de control | 1 × Regulador térmico del núcleo | 1 × Regulador térmico del núcleo |
| 59 | Fabricar bahía de mantenimiento | 4 × Piezas de construcción + 2 × Bastidor ligero + 1 × Sistema informático | 1 × Bahía de mantenimiento | 1 × Bahía de mantenimiento |
| 60 | Fabricar bahía de hangar | 8 × Piezas de construcción + 6 × Bastidor ligero + 2 × Sistema informático + 1 × Bahía de mantenimiento | 1 × Bahía de hangar | 1 × Bahía de hangar |
| 61 | Fabricar núcleo de reactor | 4 × Superaleación Ni-Co + 2 × Carburo de tungsteno + 1 × Regulador térmico del núcleo + 1 × Sistema informático + 1 × Batería de condensadores | 1 × Núcleo de reactor | 1 × Núcleo de reactor |
| 62 | Fabricar bahía de drones | 3 × Bastidor ligero + 1 × Bodega modular + 1 × Sistema informático | 1 × Bahía de drones | 1 × Bahía de drones |
| 63 | Fabricar conjunto de sensores | 2 × Sensor de trazas + 1 × Sistema informático + 2 × Cable de cobre | 1 × Conjunto de sensores | 1 × Conjunto de sensores |
| 64 | Fabricar componentes de armamento | 3 × Acero + 2 × Carburo de tungsteno + 1 × Chip básico | 1 × Componentes de armamento | 1 × Componentes de armamento |
| 65 | Fabricar sistema de propulsión | 2 × Conjunto de motor + 1 × Regulador térmico del núcleo + 2 × Cable de cobre | 1 × Sistema de propulsión | 1 × Sistema de propulsión |

## Continuidad y datos

`data/materials.txt`: id,key,name,category,stage,price,rarity. `data/recipes.txt`: id,key,name,stage,inputs,outputs. Las cantidades de receta son enteras de diseño; la recuperación y eficiencia se calculan fuera de ellas. `attributes/station-industry.txt`: station,refining_percent,fabrication_percent. La refinería se limita a 0–100; estaciones sin fila usan 80 %. La columna fabrication_percent se conserva a 100 para compatibilidad y el motor garantiza 100 % para cualquier etapa distinta del refinado, aunque un fichero antiguo indique 80 o 0. Módulos de mejora, tarifas, energía, tiempo, cola y montaje final siguen pendientes.

Godot guarda industry_remainders junto al inventario en JSON; C# añade una línea 27 al guardado, con los saldos por material. Ambas ediciones migran inventarios de 10 y 71 materiales manteniendo sus prefijos e inicializando nuevos productos/saldos a cero. El saldo se almacena como entero entre 0 y 9999 y no se reinicia al fabricar, cambiar de estación o guardar/cargar.

Fuentes: Godot/industry.gd y csharp/Industry.cs; build/render-crafting.ps1 regenera la imagen de los mismos datos. Pruebas: test-industry.gd y --smoke verifican todas las recetas, cálculos de 7,6/9,5, lotes equivalentes, fabricación sin pérdidas, saldos guardados, migración, escasez y proporción de hielo. test-cluster.gd conserva las comprobaciones del mapa. Respeta los IDs y anclajes existentes.

Base científica de las cadenas existentes: [DOE: electrólisis](https://www.energy.gov/cmei/fuels/hydrogen-production-electrolysis) y [DOE: pirólisis del metano](https://www.energy.gov/sites/default/files/2021-09/h2-shot-summit-panel2-methane-pyrolysis.pdf). La estación aporta la energía de manera abstracta; las cantidades y componentes son reglas de juego.
