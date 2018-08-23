## Introducción
Parches para descarga y procesado de guía movistar desde nueva web de programación: http://comunicacion.movistarplus.es/programacion/

## Aviso
Estos parches hacen uso de [tvhstar](https://github.com/LuisPalacios/tvhstar) para el procesado final del xml y que pueda ser consumido por tvheadend.
En este repo sólo se encuentran los archivos nuevos y/o modificados del proyecto tvhstar.

No esperes código bonito ni refinado... me he gastado los ojos investigando, comprendiendo y parcheando como he podido (un poco de bash, otro poco de perl, algo más de node.js...), para poder tener una guía funcional en tvheadend.
Acepto encantado todas las correciones o mejoras que puedas aportar. ¡Gracias!

## Uso
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
