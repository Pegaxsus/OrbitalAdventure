# Lanzamientos de C#

Historial reconstruido a partir de las entregas del proyecto. Las compilaciones de prueba sin número conservan su identificación original.

## 0.0.1

**Pedido.** Crear una demo básica ejecutable en Windows.

**Trabajo realizado.** Prototipo C# con Windows Forms, hangar con segundo motor opcional, sector de asteroides sembrado y guardado manual.

## 0.0.2

**Pedido.** Aumentar el detalle del pixel art siguiendo una referencia.

**Trabajo realizado.** Se dibujó un casco panelado, con proa definida, cabina azul y variante de tobera.

## 0.0.3

**Pedido.** Girar la nave al pulsar las teclas.

**Trabajo realizado.** La proa gira suavemente hacia la dirección de movimiento, incluidas diagonales. Se añadió el ángulo al guardado.

## 0.0.4

**Pedido.** Separar empuje, giro y frenado para simular inercia.

**Trabajo realizado.** W da empuje principal, A/D dan empuje lateral al 25 %, Q/E controlan el giro y S frena. La velocidad se conserva al soltar los mandos.

## 0.0.5

**Pedido.** Incorporar las ocho naves de referencia, freno X y ping Tab.

**Trabajo realizado.** Selector de naves con perfiles de masa, empuje, velocidad y giro. X frena en todas las direcciones y S aplica contraempuje. Tab lanza un anillo de escaneo.

## 0.0.6

**Pedido.** Añadir zoom, llamas y ametralladora.

**Trabajo realizado.** Rueda para zoom en vuelo, llama con W y trazadoras rápidas con Espacio.

## 0.0.7

**Pedido.** Ampliar el sector y añadir colisiones y vida.

**Trabajo realizado.** Sector de 10.000 × 10.000 con 640 asteroides, daño de colisión y de proyectil, casco por tamaño y persistencia de daño.

## 0.0.8

**Pedido.** Revelar recursos con el ping y cambiar de modo con Mayús izquierda.

**Trabajo realizado.** Diez recursos, con uno o dos por asteroide y composición estable. Se guarda el descubrimiento. Mayús alterna Armamento, Misiles, Minería y Drones y, al mantenerla, la rueda permite recorrerlos.

## 0.0.9

**Pedido.** Añadir un minijuego de minería y recogida.

**Trabajo realizado.** Láser corto, ventana de potencia, progreso, sobrecarga con daño y recuperación del 10 % o 100 % en fragmentos.

## 0.0.10

**Pedido.** Mover la ventana de minería, limitar bodega, ampliar la flota y organizar los recursos.

**Trabajo realizado.** Láser blanco y amarillo, bodega por nave, 17 cascos, selector de color y carpetas para sprites y atributos.

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
