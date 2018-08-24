## Introducción
Parches para descarga y procesado de guía movistar desde nueva web de programación: http://comunicacion.movistarplus.es/programacion/

Estos parches hacen uso de [tvhstar](https://github.com/LuisPalacios/tvhstar) para el procesado final del xml y que pueda ser consumido por tvheadend. Sólo modifico el archivos src/server.js de tvhstar (¡¡¡haz copia antes de pisarlo!!!).

Mi script de bash y el de node.js realizan lo siguiente:
1- descarga de un xml con la guía de todos los canales (excepto alquiler) desde la nueva web de movistar, para el número de días que le indiquemos
2- edición del xml descargado para que tenga un formato entendible por tvhstar y que pueda prepararlo para tvheadend

## Aviso
No esperes código bonito, ni refinado, ni mucho control de errores... me he gastado los ojos investigando, comprendiendo y parcheando como he podido (un poco de bash, otro poco de perl, algo más de node.js...), para poder tener una guía funcional en tvheadend.

Mi sistema es FreeBSD 11.1, así que puede haber "pequeñas diferencias" si usas otro sistema... rutas de bash, perl, curl, node... opciones de los comandos usados... cosas así.

Acepto encantado todas las correciones o mejoras que puedas aportar. ¡Gracias!

## Uso

### tvhstar
Tienes que tener correctamente descargado y configurado [tvhstar](https://github.com/LuisPalacios/tvhstar)

Haz copia de tu fichero `src/server.js` (tendrás que recupear de él todas tus Constantes, con los nombres y rutas de ficheros)

Revisa el código del script bash y del js para editar las rutas de los archivos a generar:

En `parche-epg.sh`:
	
	ficheroXML='/tmp/guia.movistar-xml-TMP.xml' # fichero de destino
		
En `borra_duplis_y_ordena.js`
	
	const ficheroXML = '/tmp/guia.movistar-xml.xml'
	
En el directorio tvhstar ejecuta

    tvhstar $ ./parche-epg.sh NN

NN = número de días que se quieren de la guía (desde HOY hasta HOY+días)

## Algunos archivos sueltos
- `estadísticas-ejecución.txt`: algunos números sacados con time de la ejecución de los distintos pasos. Una prueba "borrica" pidiendo 100 días ("sólo" me entregó lo que tenía, del 23/8 al 30/9)... y todo tardó menos de 55s. Desde luego la exportación de la nueva web me parece mucho más rápida que la viejuna.

- Directorio `xml`: un ejemplo de xml exportado desde la vieja web (menos mal que lo tenía por ahí perdido, para poder comparar) y otro del xml que exporta actualmente.
