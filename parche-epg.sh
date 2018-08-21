#!/usr/local/bin/bash

# recibe el número de días a pedir de guía y edita el fichero data.xt (usado para petición de curl), cambiando la fecha desde (hoy) y la fecha hasta (hoy+días)


# parámetro recibido
dias=$1
sdias=86400 # segundos por día
dias=$((dias*sdias)) # días pasados a segundos
desde=`date "+%s"` # fecha actual en formato epoch
hasta=$((desde+dias))

# conversión a formato yyyy-mm-dd
desde=`date -j -r $desde +"%Y-%m-%d"`
hasta=`date -j -r $hasta +"%Y-%m-%d"`

#edición de data.txt con las nuevas fechas desde y hasta
perl -p -i'.bak' -e "s/&export-date-from=\d{4}-\d{2}-\d{2}/&export-date-from=$desde/; s/&export-date-to=\d{4}-\d{2}-\d{2}/&export-date-to=$hasta/;" data.txt

# borro los archivos de guía viejos
rm -rf /tmp/guia.movistar-xml*

# descarga del xml de movistar. Todos los canales excepto alquiler
time curl 'http://comunicacion.movistarplus.es/wp-admin/admin-post.php' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: http://comunicacion.movistarplus.es' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'Referer: http://comunicacion.movistarplus.es/programacion/' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: es,en;q=0.9,es-ES;q=0.8' --data "@data.txt" --compressed -o /tmp/guia.movistar-xml.xml

# edición del xml recibido para que sea igual que en la antigua exportación de movistar
perl -p -i'.bak' -e "s/<\?xml version=\"1.0\" encoding=\"utf-8\"\?><xml>/<\?xml version='1.0' encoding='UTF-8' \?>/; s/<\/xml>//g; s/(<export>)/\n        \t\t\t\1/g; s/(<\/pase>)/<web><\/web>\n\t\t\t\t\t\1/g; s/ {24}/\t\t\t\t\t/g; s/&/&amp;/g; s/cadena=\"(.*?)\" fecha=\">(.*?)\"\>/cadena='\1' fecha='\2'>/g;" /tmp/guia.movistar-xml.xml

# lo paso por tvhstar.sh, pero con src/server.js editado para que no descargue la guía (usará el preparado anteriormente) y no se quede en ejecución programada
./tvhstar.sh
