//
//  kralizeck 2018/08/28
//	=========================================================
//	Uso:
//	node borra_duplis_y_ordena.js ficheroXML
//	=========================================================
//
//	Este program procesa un archivo xml con la guía de movistar, realizando dos tareas:
//	  1.- elimina los posibles pases duplicados (misma cadena, día y hora)
//	  2.- corrige el día que le corresponde a un pase si es después de medianoche (movistar y sus cosas...). En cada grupo de pases para una cadena-día, los pases a partir de las 00:00h son del día siguiente
//

const fichero = process.argv[2]; // el fichero a procesar
const ficheroXML = '/tmp/guia.movistar-xml.xml'; // fichero de salida

// contadores para los totales de pases eliminados, pares de pases comparados, pases con día cambiado (enredo de cómo movistar considera los días/pases), número de canales
var contador_eliminados = 0, contador_cambio_dia = 0, contador_canales = [], total_canales = 0; 

// =========================================================
// Funciones
// =========================================================

function corrigePases(pases_a_corregir) {
	// recibe un array con los pases de un canal/día y corrige el día de los pases que en realidad corresponden al día siguiente
	// preparación de variables
	let milisegundos_un_dia = 86400000; // milisegundos en un día, para "crear" el día siguiente
	let dia = new Date(pases_a_corregir[0].$.fecha); // tomo la fecha del primer elemento
	let dia_siguiente = new Date(dia.valueOf() + milisegundos_un_dia); // fecha del día siguiente
	let hora_previo = pases_a_corregir[0].hora[0]; // hora del primer pase
	let hora_actual = undefined;

	dia_siguiente = yyyymmdd(dia_siguiente); // convierto dia_siguiente a formato YYYY-MM-DD
	
	// a procesar los pases_a_corregir
	let pases2 = pases_a_corregir.length; //total de pases en pases_a_corregir
	let salta_dia = 0; // flag para saber que ya tengo que cambiar todos los días de todos los pases siguientes
	let i = 1;

	while (i < pases2) {
		hora_actual = pases_a_corregir[i].hora[0];
		if (salta_dia === 0) {
			if (hora_actual < hora_previo) {
				salta_dia = 1; // al resto, si quedan, hay que cambiarles el día
				pases_a_corregir[i].$.fecha = dia_siguiente;
				contador_cambio_dia++;
				hora_previo = hora_actual;
			}
		} else {
				pases_a_corregir[i].$.fecha = dia_siguiente;
		}
		hora_previo = hora_actual;
		i++;
	}
}

// recibe una fecha y devuelve una cadena con formato YYYY-MM-DD
function yyyymmdd(fecha) {
    let a = fecha.getFullYear();
    let m = fecha.getMonth() + 1;
    let d = fecha.getDate();
    return '' + a + '-' + (m < 10 ? '0' : '') + m + '-' + (d < 10 ? '0' : '') + d;
}

// =========================================================
// Método principal
// =========================================================

var fs = require('fs'),
    parseString = require('xml2js').parseString,
		xml2js = require('xml2js');
		
fs.readFile(fichero, 'utf-8', function (err, data){
	if(err) console.log(err);
  parseString(data, function(err, result){
		if(err) console.log(err);

		var pases = result.export.pase.length; // número total de pases
		console.log("Procesando xml", fichero);
		console.log('---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ');
		console.log("1 - Total pases inciales:", pases);

		// ELIMINANDO DUPLICADOS - analizo los pases en orden inverso, en orden "normal" se saltaba repetidos (enredos con los índices del array al eliminar elementos, supongo)
		for( var actual = result.export.pase.length-1; actual >= 0; actual-- ) {
			var previo = actual - 1; // índice del pase anterior
			if (actual > 0) { // no proceso el último (primer) elemento (index=0), que ya ha sido comparado en la última iteración
				var cadena_actual = result.export.pase[actual].$.cadena;
				var cadena_previo = result.export.pase[previo].$.cadena;
				var fecha_actual = result.export.pase[actual].$.fecha;
				var fecha_previo = result.export.pase[previo].$.fecha;
				var hora_actual = result.export.pase[actual].hora[0];
				var hora_previo = result.export.pase[previo].hora[0];
				
				if (cadena_actual === cadena_previo && fecha_actual === fecha_previo && hora_actual === hora_previo) {
					contador_eliminados++;
					result.export.pase.splice(actual, 1); // elimino el elemento actual, está duplicado
				}
				
				if (!(contador_canales.includes(cadena_actual))) contador_canales.push(cadena_actual); // si la cadena aún no está en el contador, la añado
			}
		}

		pases = result.export.pase.length; // actualizo total de pases por si se ha borrado alguno
		
		console.log("2 - Pases duplicados eliminados:", contador_eliminados);
		console.log("3 - Total pases finales:", pases);

		// CORRIGIENDO EL DÍA - si la hora de un pase es mayor que la del siguiente eso implica que el siguiente ya
		
		let salida = { // json para ir guardando lo ordenado por canal/día/hora
			"export": {
				"pase": [
				]
			}
		};
		
		console.log("4 - Revisando fechas de", pases, "pases");
		
		// tomo los datos del primer pase (menos enredos en el while), lo único que necesito es cadena y fecha (reuso las variables utilizadas para los duplicados)
		cadena_previo = result.export.pase[0].$.cadena;
		fecha_previo = result.export.pase[0].$.fecha;
		var pases_a_corregir = [result.export.pase[0]]; // creo el array de pases a corregir y añado el primero

		var i = 1;

		while (i < pases) {
			cadena_actual = result.export.pase[i].$.cadena;
			fecha_actual = result.export.pase[i].$.fecha;

			if (cadena_actual === cadena_previo && fecha_actual === fecha_previo && i < pases - 1) { // misma cadena y mismo día y NO estamos en el último registro
				pases_a_corregir.push(result.export.pase[i]); // añado el pase al array a corregir

				// actualizo los valores previos para la siguiente iteración de comparación de pases
				cadena_previo = cadena_actual;
				fecha_previo = fecha_actual;
			} else { // hemos pasado al siguiente día, así que a corregir el array, pasarlo al json definitivo y resetear valores
			
				if (i === (pases - 1)) pases_a_corregir.push(result.export.pase[i]); // se me había escapado el último pase, lo añado

				corrigePases(pases_a_corregir); // mando los pases a corregir
				// añado los pases ordenados de la cadena/día al array de salida
				salida.export.pase = salida.export.pase.concat(pases_a_corregir);
				// reseteo de variables
				cadena_previo = cadena_actual;
				fecha_previo = fecha_actual;
				pases_a_corregir = [result.export.pase[i]]; // nuevo pase inicial del canal/día siguiente
			}
			i++;
		}
		
		console.log("    Total pases con fecha corregida:", contador_cambio_dia);
		total_canales = contador_canales.length; // ya, ya, debería ser +1... pero así se queda...
		console.log("5 - Total cadenas:", total_canales, "(pases totales:", pases, ")");

		// crear nuevo xml
		var builder = new xml2js.Builder();
		var xml = builder.buildObject(salida);
		fs.writeFile(ficheroXML, xml, function(err, salida){
				if (err) console.log(err);
		console.log('---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ');
		console.log("Escrito nuevo xml en", ficheroXML);
		console.log("Ya se puede pasar a tvhstar para que haga su magia...");
		});
	});
});       