#!/usr/bin/env bash

# 
# kralizeck 2018/08/24
#
# Este script realiza varios procesos para preparar un xml que entienda tvhstar:
# 1. recibe el número de días a pedir de guía y edita (con perl) el fichero data.xt (usado para petición de curl), cambiando la fecha desde (hoy) y la fecha hasta (hoy+días)
# 2. descarga (con curl) la guía completa (excepto canales de alquiler) de la web de movistar y guarda el xml en $ficheroXML
# 3. edita $ficheroXML (con perl) para que tenga el mismo formato que las descargas de la antigua web de exportación de movistar
# 4. procesa $ficheroXML (con node.js) para eliminar pases repetidos (rarezas de la nueva web, parece ser) y ordenar los pases dentro de cada cadena/día (más rarezas...)
# 5. lanza tvhstar.sh para que haga su magia con el fichero preparado

# control de errores - parámetros recibidos
ARGS=1

if [ $# -ne "$ARGS" ]
then
  echo -e "\n\tUso: `basename $0` días\n"
  exit
fi

##########
#	Paso 1 #
##########

# parámetro recibido
dias=$1

# variables
ficheroXML='/tmp/guia.movistar-xml-TMP.xml' # fichero de destino

ficherodata='data.txt'
sdias=86400 # segundos por día
dias=$((dias*sdias)) # días pedidos pasados a segundos
desde=`date "+%s"` # fecha actual en formato epoch
hasta=$((desde+dias))

# conversión a formato yyyy-mm-dd
# desde=`date -j -r $desde +"%Y-%m-%d"`
# hasta=`date -j -r $hasta +"%Y-%m-%d"`
# he pasado a usar perl para la conversión porque el comando date en FreeBSD no funciona igual que en linux
desde=`perl -MPOSIX -le 'print strftime("%Y-%m-%d",localtime($ARGV[0]))' $desde`
hasta=`perl -MPOSIX -le 'print strftime("%Y-%m-%d",localtime($ARGV[0]))' $hasta`

#edición de data.txt con las nuevas fechas desde y hasta
perl -p -i'.bak' -e "s/&export-date-from=.*?&/&export-date-from=$desde&/; s/&export-date-to=.*?&/&export-date-to=$hasta&/;" $ficherodata

##########
#	Paso 2 #
##########

echo -e "\nSolicitando la guía desde el $desde al $hasta...\n"

# descarga del xml de movistar. Todos los canales excepto alquiler
curl 'http://comunicacion.movistarplus.es/wp-admin/admin-post.php' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: http://comunicacion.movistarplus.es' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'Referer: http://comunicacion.movistarplus.es/programacion/' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: es,en;q=0.9,es-ES;q=0.8' --data "@$ficherodata" --compressed -o $ficheroXML

# control de errores básico - curl - DESACTIVADO por ahora... no parece funcionar en linux
# sizefichero=`stat -f%z $ficheroXML`
# if [ "$sizefichero" -eq 0 ]; then 
		# echo ">>>> ERROR <<<< al descargar $ficheroXML - fichero de tamaño $sizefichero" # error cuando no puede conectar con la página o cosas así
		# exit
# fi

##########
#	Paso 3 #
##########

echo -e "\nConvirtiendo $ficheroXML a formato xml viejuno de exportación de movistar...\n"

# edición del xml recibido para que sea igual que en la antigua exportación de movistar
perl -p -i'.bak' -e "s/<\?xml version=\"1.0\" encoding=\"utf-8\"\?><xml>/<\?xml version='1.0' encoding='UTF-8' \?>/; s/<\/xml>//g; s/(<export>)/\n        \t\t\t\1/g; s/(<\/pase>)/<web><\/web>\n\t\t\t\t\t\1/g; s/ {24}/\t\t\t\t\t/g; s/&/&amp;/g; s/cadena=\"(.*?)\" fecha=\">(.*?)\"\>/cadena='\1' fecha='\2'>/g;" $ficheroXML

##########
#	Paso 4 #
##########

node borra_duplis_y_ordena.js $ficheroXML

##########
#	Paso 5 #
##########

# lanzo tvhstar.sh (el ficheroXML es el mismo que el definido en server.js), pero no descargará la guía de la web (usará el preparado anteriormente en este script) ni se quedará en bucle de ejecución programada

./tvhstar.sh
