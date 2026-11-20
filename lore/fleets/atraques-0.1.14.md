# Auditoría de atraques · 0.1.14

Revisadas las 46 naves del catálogo frente a las 15 estaciones: **690 combinaciones nave/estación**, con pruebas de atraque manual en ambos sentidos de todos los puertos ofrecidos y autoatraque desde una aproximación desalineada. Resultado: **5.300 casos manuales y 690 automáticos superados**, en Godot y C#.

## Ocaso

Ocaso (ID 41, Battleship) tiene longitud134 y anchura67. El puerto normal164×58 sólo puede contener58/67 =86,57 % de su envolvente, por debajo del90 % requerido. Por eso no podía atracar en14 de las15estaciones; el astillero ya ofrecía un atraque universal de tamaño capital.

La elección de puerto ya no se basa únicamente en clase. Una nave de clase menor que Dread usa puertos normales cuando cabe; si no hay uno adecuado, utiliza puertos capitales compatibles. Ocaso sigue siendo Battleship, con sus mismos atributos y hardpoints; en las estaciones actuales se le muestran las zonas capitales. La clase Dread/Carrier conserva la reserva de atraque capital.

Las demás45naves caben en su categoría anterior en los puertos estándar. No se han renombrado/reclasificado cascos ni ampliado zonas de atraque del usuario.

## Conflicto adicional en Godot

Cénit mostraba colisiones falsas con Covetor (ID19), Luminaria (ID39) e Incandescencia (ID42) en algunos puertos/aproximaciones. Al preparar el fondo difuminado del hangar, Godot redimensionaba el Image obtenido de la textura compartida. La máscara de colisión acababa siendo256×256 difuminada en vez de860×860 original, engordando la silueta.

Se duplica la imagen antes de transformarla. La máscara conserva la resolución y alfa originales y coincide con C#. Se aplica la misma precaución a las copias para cielo, rotación de sprites y escudos, evitando modificar las imágenes fuente compartidas en memoria. No se modifican los PNG en disco.

## Reglas de compatibilidad

- Cobertura mínima90 % según longitud y anchura reales de la nave.
- Para clases menores que Dread, preferir puertos normales compatibles, incluidos los personalizados más anchos. Recurrir a capitales si hace falta.
- Comprobar que el casco alineado en el centro y el pasillo exterior de aproximación no colisionen con la estación, reutilizando la misma geometría de colisión del vuelo.
- Mostrar, aceptar y usar en autoatraque la misma lista de puertos.
- Mantener velocidad≤3, alineación≤10°, la posibilidad de entrar en ambos sentidos y la espera/cancelación del autoatraque.
- Remapear un puerto antiguo incompatible al entrar/cargar en hangar; no acceder a una lista vacía si una futura estación carece de puertos adecuados.
- Guardar la compatibilidad en caché por nave/estación para no analizar píxeles cada fotograma. La caché es transitoria y no se guarda. Si se añade edición/recarga de geometría durante la partida, hay que invalidarla.

## Catálogo comprobado

| ID | Nave | Clase | Longitud | Anchura de envolvente | Atraque estándar |
| ---: | --- | --- | ---: | ---: | --- |
| 0 | Nave 01 | Crucero | 34 | 19.80 | Normal |
| 1 | Nave 02 | Crucero | 47 | 22.51 | Normal |
| 2 | Nave 03 | Crucero | 60 | 25.58 | Normal |
| 3 | Nave 04 | Crucero | 73 | 19.41 | Normal |
| 4 | Nave 05 | Crucero | 86 | 28.60 | Normal |
| 5 | Nave 06 | Battleship | 99 | 19.70 | Normal |
| 6 | Nave 07 | Battleship | 112 | 29.03 | Normal |
| 7 | Nave 08 | Dreadnought | 125 | 23.81 | Capital |
| 8 | Leviatán | Carrier | 155 | 32.96 | Capital |
| 9 | Mastodonte | Dreadnought | 138 | 29.69 | Capital |
| 10 | Coloso | Dreadnought | 127 | 29.01 | Capital |
| 11 | Alción | Crucero | 62 | 33.21 | Normal |
| 12 | Azor | Crucero | 51 | 28.10 | Normal |
| 13 | Centella | Crucero | 72 | 30.49 | Normal |
| 14 | Bastión | Battleship | 76 | 35.51 | Normal |
| 15 | Baluarte | Battleship | 82 | 32.57 | Normal |
| 16 | Tempestad | Battleship | 88 | 30.11 | Normal |
| 17 | Procurer | Fragata | 32 | 16.00 | Normal |
| 18 | Retriever | Crucero | 78 | 39.00 | Normal |
| 19 | Covetor | Battleship | 94 | 47.00 | Normal |
| 20 | Rorqual | Dreadnought | 242 | 159.04 | Capital |
| 21 | Nyx | Carrier | 224 | 138.94 | Capital |
| 22 | Chimera | Carrier | 210 | 77.08 | Capital |
| 23 | Phoenix | Dreadnought | 232 | 102.02 | Capital |
| 24 | Raptor | Fragata | 29 | 26.21 | Normal |
| 25 | Manticore | Fragata | 32 | 33.43 | Normal |
| 26 | Stratios | Crucero | 62 | 35.91 | Normal |
| 27 | Vigía | Fragata | 36 | 12.60 | Normal |
| 28 | Sextante | Crucero | 66 | 23.21 | Normal |
| 29 | Alidada | Crucero | 72 | 19.29 | Normal |
| 30 | Equinoccio | Crucero | 83 | 23.90 | Normal |
| 31 | Solsticio | Battleship | 114 | 31.57 | Normal |
| 32 | Eclíptica | Battleship | 108 | 25.34 | Normal |
| 33 | Firmamento | Carrier | 248 | 63.41 | Capital |
| 34 | Horizonte | Dreadnought | 222 | 41.04 | Capital |
| 35 | Ascua | Fragata | 38 | 12.67 | Normal |
| 36 | Alba | Fragata | 42 | 14.00 | Normal |
| 37 | Aurora | Crucero | 70 | 23.33 | Normal |
| 38 | Fulgor | Crucero | 80 | 26.67 | Normal |
| 39 | Luminaria | Crucero | 76 | 42.77 | Normal |
| 40 | Lanza Solar | Battleship | 124 | 41.33 | Normal |
| 41 | Ocaso | Battleship | 134 | 67.00 | Capital |
| 42 | Incandescencia | Battleship | 144 | 48.11 | Normal |
| 43 | Corona | Dreadnought | 252 | 84.00 | Capital |
| 44 | Sol Invicto | Carrier | 248 | 139.57 | Capital |
| 45 | Arca Solar | Carrier | 232 | 174.00 | Capital |

Pruebas reproducibles: build/test-docking.gd y --smoke de C# (csharp/DockingChecks.cs, compilado por build/build-csharp.ps1). Se prueban además el remapeo de Ocaso desde un puerto antiguo, un puerto normal personalizado más ancho y la ausencia de puertos compatibles. build/audit-docking.gd genera un informe de conflictos actuales; con la corrección no detecta ninguno. Las pruebas usan guardados temporales, sin escribir las partidas reales.
