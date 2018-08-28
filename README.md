## Introducción
Parches para descarga y procesado de guía movistar desde nueva web de programación: http://comunicacion.movistarplus.es/programacion/

Estos parches hacen uso de [tvhstar](https://github.com/LuisPalacios/tvhstar) para el procesado final del xml y que pueda ser consumido por tvheadend. Sólo modifico el archivos src/server.js de tvhstar (¡¡¡haz copia antes de pisarlo!!!).

Mi script de bash y el de node.js realizan lo siguiente:

1- descarga un xml con la guía de todos los canales (excepto alquiler) desde la nueva web de movistar, para el número de días que le indiquemos
2- edición del xml descargado para que tenga un formato entendible por tvhstar y que pueda prepararlo para tvheadend
3- lanza tvhstar.sh para que procese el xml preparado

## Aviso
No esperes código bonito, ni refinado, ni mucho control de errores... me he gastado los ojos investigando, comprendiendo y parcheando como he podido (un poco de bash, otro poco de perl, algo más de node.js...), para poder tener una guía funcional en tvheadend.

Mi sistema es FreeBSD 11.1, así que puede haber "pequeñas diferencias" si usas otro sistema... rutas de bash, perl, curl, node... opciones de los comandos usados... cosas así.

He intentado hacerlo compatible con linux (¡gracias! @gedas07), más abajo están los requisitos.

Acepto encantado todas las correciones o mejoras que puedas aportar. ¡¡Gracias!!

## Requisitos
- proyecto [tvhstar](https://github.com/LuisPalacios/tvhstar) instalado y configurado (["Configuración de tvhstar"](https://github.com/LuisPalacios/tvhstar/blob/master/README.md#configuraci%C3%B3n))
- bash
- curl (probado con v7.61.0)
- perl (probado con v5.26.2)
- node.js (probado con v10.7.0)

## Uso

### tvhstar
Tienes que tener correctamente descargado y configurado [tvhstar](https://github.com/LuisPalacios/tvhstar)

Haz copia de tu fichero `src/server.js` (tendrás que recuperar de él todas tus "Constantes (progPreferences)", con los nombres y rutas de ficheros).

### Ficheros a descargar y editar
Todos se descargan donde tengas instalado tvhstar.

- `src/server.js`: sí, soy pesado, pero haz un backup de tu server.js actual... Una vez descargado, edítalo y revisa todos los ficheros y rutas de "Constantes" (está todo al principio del fichero). Para más detalles consulta las instrucciones de ["Configuración de tvhstar"](https://github.com/LuisPalacios/tvhstar/blob/master/README.md#configuraci%C3%B3n)

- `parche-epg.sh`: script principal del invento. Le indicamos el número de días que queremos y él edita el `data.txt`, descarga el xml de movistar, lo "arregla" para que tvhstar lo entienda y lanza tvhstar para que se genere el xml para tvheadend. Edítalo y revisa el valor de:

```
ficheroXML='/tmp/guia.movistar-xml-TMP.xml' # fichero de destino
```

- `borra_duplis_y_corrige_fecha.js`: script node.js ejecutado por `parche-epg.sh` para eliminar pases duplicados (la nueva web es un poco "loca" repitiendo pases) y corregir la fecha dentro de cada cadena/día (movistar "considera" que de las 00:00 a las 06:00h, aprox, son pases del mismo día, no del siguiente...). Edítalo y revisa el valor de:

```
const ficheroXML = '/tmp/guia.movistar-xml.xml'; // fichero de salida
```
		
**_¡CRÍTICO!_**:   tendrá que ser igual que el valor de "ficheroXML" en src/server.js
 
- `data.txt`: usado por script `parche-epg.sh` para descargar la guía desde la [web de movistar](http://comunicacion.movistarplus.es/programacion/), está configurado para descargar todos los canales, excepto los de alquiler. No hay que editar nada en él. De las fechas ya se encarga `parche-epg.sh`. Si quieres cambiar los canales a descargar tendrás que ver (con el debugger de chrome, por ejemplo) una petición POST de lo que te interesa y modificar el data.txt... ya lo documentaré en otro momento.

Y ya está. No se necesita más. El resto de ficheros son de estadísticas y pruebas xml viejas y nuevas. No son necesarios para el funcionamiento del script.

### Ejecución
Desde el directorio de tvhstar ejecuta:

```
./parche-epg.sh días
```
 
> **días** = número de días que se quieren de la guía, p.ej. `/.parche-epg.sh 7`

**NO HAY** que ejectuar `tvhstar.sh` después. El script parche-epg-sh lo lanzará cuando termine de descargar y preparar el xml de la guía.


## Algunos archivos sueltos (NO NECESARIOS PARA EL USO DEL SCRIPT)
- `estadísticas-ejecución.txt`: algunos números sacados con time de la ejecución de los distintos pasos. Una prueba "borrica" pidiendo 100 días ("sólo" me entregó lo que tenía, del 23/8 al 30/9)... y todo tardó menos de 55s. Desde luego la exportación de la nueva web me parece mucho más rápida que la viejuna.

- Directorio `xml`: un ejemplo de xml exportado desde la vieja web (menos mal que lo tenía por ahí perdido, para poder comparar), otro del xml que exporta actualmente y otro xml de una exportación actual "fallida" (un xml sin pases).
