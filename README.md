## Introducción

Parches para descarga y procesado de guía movistar desde nueva web de programación: http://comunicacion.movistarplus.es/programacion/

## Aviso
Estos parches hacen uso de [tvhstar](https://github.com/LuisPalacios/tvhstar) para el procesado final del xml y que pueda ser consumido por tvheadend.
En este repo sólo se encuentran los archivos nuevos y/o modificados del proyecto tvhstar.

### Uso

Revisa el código del script bash y del js para editar las rutas de los archivos a generar:
	En `parche-epg.sh`:
		ficheroXML='/tmp/guia.movistar-xml-TMP.xml' # fichero de destino
		
	En `borra_duplis_y_ordena.js`
		const ficheroXML = '/tmp/guia.movistar-xml.xml'
	
En el directorio tvhstar ejecuta

    tvhstar $ ./parche-epg.sh NN

NN = número de días que se quieren de la guía (desde HOY hasta HOY+días)