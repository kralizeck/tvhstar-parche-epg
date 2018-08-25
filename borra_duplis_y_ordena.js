//
//  kralizeck 2018/08/23
//	=========================================================
//	Uso:
//	node borra_duplis_y_ordena.js ficheroXML
//	=========================================================
//
//	Este program procesa un archivo xml con la guía de movistar, realizando dos tareas:
//	  1.- elimina los posibles pases duplicados (misma cadena, día y hora)
//	  2.- en cada grupo de pases para una cadena-día, ordena los pases por horas (ascendente)

const fichero = process.argv[2]; // el fichero a procesar
const ficheroXML = '/tmp/guia.movistar-xml.xml'; // fichero de salida

// contadores para los totales de pases eliminados, pares de pases comparados, número de canales
var contador_eliminados = 0, contador_pares = 0, contador_canales = []; 

// =========================================================
// Funciones
// =========================================================

function ordenaPases(pases_a_ordenar) {
		pases_a_ordenar.sort(function(a, b)
		{
			contador_pares++;
			// console.log("Comparando ", a.$.cadena, a.$.fecha, a.hora, "<<<>>>", b.$.cadena, b.$.fecha, b.hora);
			var x = a.hora, y = b.hora;
			if (a.hora < b.hora)
				return -1;
			if (a.hora > b.hora)
				return 1;
			return 0;
		});
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
		console.log("1 - Total pases inciales:", pases + 1);

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
		console.log("3 - Total pases finales:", pases + 1);

		// ORDENANDO
		
		let salida = { // json para ir guardando lo ordenado por canal/día/hora
			"export": {
				"pase": [
				]
			}
		};
		
		console.log("4 - Ordenando", pases + 1, "pases");
		
		// tomo los datos del primer pase (menos enredos en el while), lo único que necesito es cadena y fecha (reuso las variables utilizadas para los duplicados)
		cadena_previo = result.export.pase[0].$.cadena;
		fecha_previo = result.export.pase[0].$.fecha;
		var pases_a_ordenar = [result.export.pase[0]]; // creo el array de pases a ordenar y añado el primero
		
		var i = 1;
		while (i < pases) {
			cadena_actual = result.export.pase[i].$.cadena;
			fecha_actual = result.export.pase[i].$.fecha;
			if (cadena_actual === cadena_previo && fecha_actual === fecha_previo && i < pases - 1) { // misma cadena y mismo día y NO estamos en el último registro
				// añado el pase al array a ordenar
				pases_a_ordenar.push(result.export.pase[i]);
				// actualizo los valores previos para la siguiente iteración de comparación de pases
				cadena_previo = cadena_actual;
				fecha_previo = fecha_actual;
			} else { // no son iguales, así que a ordenar el array, pasarlo al json definitivo y resetear valores
				ordenaPases(pases_a_ordenar); // mando los pases a ordenar
				// añado los pases ordenados de la cadena/día al array de salida
				salida.export.pase = salida.export.pase.concat(pases_a_ordenar);
				// reseteo de variables
				cadena_previo = cadena_actual;
				fecha_previo = fecha_actual;
				pases_a_ordenar = [result.export.pase[i]]; // nuevo pase inicial del canal/día siguiente
			}
			i++;
		}
		console.log("    Total pares de pases comparados:", contador_pares);
		
		var total_canales = contador_canales.length; // ya, ya, debería ser +1... pero así se queda...
		console.log("5 - Total cadenas:", total_canales, "(pases totales:", pases + 1, ")");
		
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
