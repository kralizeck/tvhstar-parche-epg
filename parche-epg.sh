#!/usr/bin/env bash

# 
# kralizeck 2018/08/24
#
# Este script realiza varios procesos para preparar un xml que entienda tvhstar:
# 1. recibe el número de días a pedir de guía y edita (con perl) el fichero data.xt (usado para petición de curl), cambiando la fecha desde (hoy) y la fecha hasta (hoy+días)
# 2. descarga (con curl) la guía completa (excepto canales de alquiler) de la web de movistar y guarda el xml en $ficheroXML
# 3. edita $ficheroXML (con perl) para que tenga el mismo formato que las descargas de la antigua web de exportación de movistar
# 4. procesa $ficheroXML (con node.js) para eliminar pases repetidos (rarezas de la nueva web, parece ser) y corregir las fechas de los pases finales de cada día (más rarezas de movistar...)
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
dias=$((dias-1)) # resto un día a los días pedidos
dias=$((dias*sdias)) # días pedidos pasados a segundos
desde=`date "+%s"` # fecha actual en formato epoch
hasta=$((desde+dias))

# conversión a formato yyyy-mm-dd
# pasar las fechas a formato YYYY-MM-DD
desde=`perl -MPOSIX -le 'print strftime("%Y-%m-%d",localtime($ARGV[0]))' $desde`
hasta=`perl -MPOSIX -le 'print strftime("%Y-%m-%d",localtime($ARGV[0]))' $hasta`

echo -e "\n#########################################################"
echo `date`
echo "#########################################################"

#edición de data.txt con las nuevas fechas desde y hasta
perl -p -i'.bak' -e "s/&export-date-from=.*?&/&export-date-from=$desde&/; s/&export-date-to=.*?&/&export-date-to=$hasta&/;" $ficherodata

##########
#	Paso 2 #
##########

echo -e "\nSolicitando la guía desde el $desde al $hasta...\n"

rm $ficheroXML
touch $ficheroXML # por si falla la comunicación con web  de movistar, que exista el fichero y pueda controlar el error

# descarga del xml de movistar. Todos los canales excepto alquiler - curl en modo silent
curl -s 'https://comunicacion.movistarplus.es/wp-admin/admin-post.php' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: https://comunicacion.movistarplus.es' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://comunicacion.movistarplus.es/programacion/' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: es,en;q=0.9,es-ES;q=0.8' -H 'Cookie: POLITICA_COOKIES=v2; _ga=GA1.2.2111594661.1529764084; cookie-policy-consent-accepted=true; _gcl_au=1.1.1227228084.1549558307' --data "@$ficherodata" --compressed -o $ficheroXML

exit_code_curl=$?

## control de errores básico - curl y fichero recibido ##

# si el exit code de curl no es 0 => algo ha ido  mal...
if [ "$exit_code_curl" -ne "0" ]; then 
		echo -e ">>>> ERROR CURL <<<< al descargar $ficheroXML - exit code $exit_code_curl\n" # algún error de curl
		exit
fi

# control de errores básico - tamaño fichero
sizefichero=`perl -le 'print -s $ARGV[0]' $ficheroXML`
if [ "$sizefichero" -eq 0 ]; then 
		echo -e ">>>> ERROR <<<< al descargar $ficheroXML - fichero de tamaño $sizefichero\n" # error cuando no puede conectar con la página o no hay datos de canales
		exit
fi

##########
#	Paso 3 #
##########

echo -e "\nConvirtiendo $ficheroXML a formato xml viejuno de exportación de movistar...\n"

# edición del xml recibido para que sea igual que en la antigua exportación de movistar
#2019.02.19 - añado eliminar .>BR designtimesp=''.*?''< (pete al parsear el xml en node)
perl -p -i'.bak' -e "s/<\?xml version=\"1.0\" encoding=\"utf-8\"\?><xml>/<\?xml version='1.0' encoding='UTF-8' \?>/; s/<\/xml>//g; s/(<export>)/\n        \t\t\t\1/g; s/(<\/pase>)/<web><\/web>\n\t\t\t\t\t\1/g; s/ {24}/\t\t\t\t\t/g; s/&/&amp;/g; s/cadena=\"(.*?)\" fecha=\">(.*?)\"\>/cadena='\1' fecha='\2'>/g; s/>BR designtimesp=''.*?''<//g;" $ficheroXML

##########
#	Paso 4 #
##########

node borra_duplis_y_corrige_fecha.js $ficheroXML

# control de errores básico - proceso con node.js, si el errorlevel del node es 0=>todo bien, si es 1=> algo ha fallado
exit_code_node=$?
if [ $exit_code_node -eq 1 ]; then # si estado es 1, algo ha fallado con el proceso del xml con node
	echo -e ">>>> ERROR NODE.JS <<<< al procesar $ficheroXML con node.js - exit code node: $exit_code_node\n" # error cuando no puede conectar con la página, no hay datos de canales, xml malformado de movistar, etc...
	exit
fi

##########
#	Paso 5 #
##########

# lanzo tvhstar.sh (el ficheroXML es el mismo que el definido en server.js), pero no descargará la guía de la web (usará el preparado anteriormente en este script) ni se quedará en bucle de ejecución programada

./tvhstar.sh
