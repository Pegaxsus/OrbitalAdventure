# Flota del Imperio de Helión · 0.1.8

Once cascos nuevos. La proa apunta hacia arriba y la facción del catálogo es helion. Los números de nave del hangar empiezan en 1 y el ID de edición empieza en 0.

| Nave | ID para hardpoints | Archivo recibido | Nombre | Clase | Longitud | Masa (t) | Empuje (kN) | Casco | Bodega (U) | Ranuras A/D/U/M |
| ---: | ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 36 | 35 | fragata01.png | Ascua | Fragata | 38 | 12 | 1200 | 112 | 24 | 1 / 1 / 1 / 1 |
| 37 | 36 | Fragata02.png | Alba | Fragata | 42 | 15 | 1410 | 135 | 28 | 1 / 1 / 1 / 1 |
| 38 | 37 | Crucero01.png | Aurora | Crucero | 70 | 34 | 2950 | 270 | 58 | 2 / 1 / 2 / 1 |
| 39 | 38 | Crucero02.png | Fulgor | Crucero | 80 | 46 | 3700 | 340 | 72 | 2 / 1 / 2 / 1 |
| 40 | 39 | Portaaviones espacial industrial desde arriba.png | Luminaria | Crucero | 76 | 40 | 3250 | 300 | 98 | 2 / 1 / 2 / 1 |
| 41 | 40 | battleship01.png | Lanza Solar | Battleship | 124 | 140 | 7250 | 760 | 160 | 4 / 2 / 2 / 2 |
| 42 | 41 | battleship02.png | Ocaso | Battleship | 134 | 170 | 8200 | 870 | 190 | 4 / 2 / 2 / 2 |
| 43 | 42 | battleship03.png | Incandescencia | Battleship | 144 | 200 | 9100 | 1010 | 215 | 4 / 2 / 2 / 2 |
| 44 | 43 | Dreadnought01.png | Corona | Dreadnought | 252 | 820 | 20400 | 2650 | 390 | 5 / 3 / 3 / 2 |
| 45 | 44 | Carrier01.png | Sol Invicto | Carrier | 248 | 790 | 19200 | 2320 | 380 | 5 / 3 / 3 / 2 |
| 46 | 45 | carrier02.png | Arca Solar | Carrier | 232 | 650 | 17300 | 2000 | 345 | 5 / 3 / 3 / 2 |

Los valores se han equilibrado con la escala de la flota existente. La velocidad máxima base sigue max(95, 345 − 1,62 × longitud) y el giro base max(23, 159 − longitud). Thrusters y Gyro aplican sus mejoras habituales. La masa y la relación empuje/masa determinan la aceleración y la respuesta inercial.

## Preparar los hardpoints

Abre shipConfigurator-1.6.exe en la raíz y elige el ID de la tabla. Los PNG se llaman helion-fragata01.png, helion-fragata02.png, helion-crucero01.png, helion-crucero02.png, helion-crucero03.png, helion-battleship01.png, helion-battleship02.png, helion-battleship03.png, helion-dreadnought01.png, helion-carrier01.png y helion-carrier02.png dentro de assets/ships/.

El configurador generará data/hardpoints/ship35.txt hasta ship45.txt al guardar. Los once cascos empiezan sin fichas específicas de hardpoints. Los lectores existentes admiten esa ausencia y emplean los orígenes genéricos del prototipo para las funciones operativas. Tras definir los puntos, vuelve a exportar Godot y compilar C# para incorporarlos a sus ejecutables.

## Cazas y drones

Fragata, Crucero, Battleship y Dreadnought necesitan el rasgo fighter_hangar para admitir cazas. Carrier y Titán tienen permiso de serie. Todos los cascos de Helión admiten puntos para drones. Ninguno de los nueve cascos menores de Helión incorpora la excepción fighter_hangar. La pista dibujada en Crucero03 forma parte del sprite y su clasificación continúa siendo Crucero.

Los sistemas de vuelo y recuperación de unidades siguen pendientes de integración. Esta entrega incorpora los cascos, los atributos y los permisos de configuración.

## Revisión visual pendiente

El recurso original Dreadnought01.png incluye una pequeña mancha blanca en el lateral derecho. Se ha conservado el recurso entregado y queda anotada para el pulido visual.
