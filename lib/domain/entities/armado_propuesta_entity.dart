/// Lo que devuelve el armado de una propuesta de precios (asistente "Nueva
/// propuesta"): la grilla calculada de una familia, los fletes, las familias
/// ya cargadas y el resultado de las escrituras.
///
/// **Por que estan juntas en un archivo.** Ninguna es una tabla: son las formas
/// de respuesta de `/price/armado/*`, que existen solo para este asistente y se
/// leen siempre juntas. Las tablas del modulo siguen teniendo su entity propia
/// (regla N:N); estas son el equivalente de los DTO del backend
/// (`CalculoFamiliaDto`, `LineaArmadoDto`, `FletesArmadoDto`...).
///
/// **El precio nunca se calcula aca.** Lo calcula el servidor, tanto en la
/// vista previa como al guardar: la pantalla solo muestra lo que llego. Por eso
/// no hay ningun metodo que haga la cuenta del precio.
library;

import 'package:flutter/foundation.dart';

/// Que pasa con una lista de precios al guardar la familia.
enum EstadoLineaArmado {
  /// Todavia no esta en la propuesta y el precio cambia: se agrega.
  nueva,

  /// Ya esta en la propuesta: se reemplaza por el calculo nuevo.
  actualiza,

  /// Quedaria igual: no se escribe.
  sinCambio,

  /// No hay costo con que calcular: solo se ve lo vigente y lo guardado.
  sinCalculo,

  /// Estaba en la propuesta, pero su lista hoy esta inactiva: se muestra con
  /// su precio guardado y no se recalcula. Al aprobar se aplica igual.
  listaInactiva;

  static EstadoLineaArmado desdeCodigo(String? codigo) => switch (codigo) {
    'NUEVA' => EstadoLineaArmado.nueva,
    'ACTUALIZA' => EstadoLineaArmado.actualiza,
    'SIN_CAMBIO' => EstadoLineaArmado.sinCambio,
    'LISTA_INACTIVA' => EstadoLineaArmado.listaInactiva,
    _ => EstadoLineaArmado.sinCalculo,
  };

  String get codigo => switch (this) {
    EstadoLineaArmado.nueva => 'NUEVA',
    EstadoLineaArmado.actualiza => 'ACTUALIZA',
    EstadoLineaArmado.sinCambio => 'SIN_CAMBIO',
    EstadoLineaArmado.sinCalculo => 'SIN_CALCULO',
    EstadoLineaArmado.listaInactiva => 'LISTA_INACTIVA',
  };

  String get etiqueta => switch (this) {
    EstadoLineaArmado.nueva => 'Se agrega',
    EstadoLineaArmado.actualiza => 'Se actualiza',
    EstadoLineaArmado.sinCambio => 'Sin cambio',
    EstadoLineaArmado.sinCalculo => 'Sin calcular',
    EstadoLineaArmado.listaInactiva => 'Lista inactiva',
  };
}

/// Una lista de precios de la familia: lo vigente, lo ya propuesto y lo que
/// resulta del costo nuevo.
@immutable
class LineaArmadoEntity {
  const LineaArmadoEntity({
    required this.idPrecio,
    required this.idClasificacion,
    required this.codSucursal,
    required this.nombreSucursal,
    required this.nombrePrecio,
    required this.vpp,
    required this.listNum,
    required this.porcentaje,
    required this.iva,
    required this.it,
    required this.flete,
    required this.precioActual,
    required this.estado,
    required this.fueraDeOrden,
    this.idPrecioPropuesto,
    this.precioPropuestoGuardado,
    this.precioCalculado,
    double? porcentajeVigente,
    this.porcentajeCambiado = false,
  }) : porcentajeVigente = porcentajeVigente ?? porcentaje;

  final BigInt idPrecio;
  final BigInt idClasificacion;
  final BigInt codSucursal;
  final String nombreSucursal;
  final String nombrePrecio;
  final int vpp;
  final BigInt listNum;

  /// Margen con el que se calculo la linea, en puntos (27 = 27 %). Si se
  /// cambio en el editor es el nuevo; si no, el de tpr_porcentaje.
  final double porcentaje;

  /// El margen que la familia tiene hoy en tpr_porcentaje para esta lista.
  final double porcentajeVigente;

  /// [porcentaje] es uno cambiado en el editor: al guardar la familia queda
  /// registrado en tpr_porcentaje.
  final bool porcentajeCambiado;
  final double iva;
  final double it;

  /// Flete de la sucursal, en USD por tonelada.
  final double flete;

  /// Precio por tonelada vigente hoy.
  final double precioActual;

  /// Fila de tpr_precioPropuesta si la lista ya estaba en la propuesta.
  final BigInt? idPrecioPropuesto;

  /// Lo que ya estaba propuesto. Null si la lista no estaba en la propuesta.
  final double? precioPropuestoGuardado;

  /// El precio que resulta del costo. Null si no hubo costo con que calcular.
  final double? precioCalculado;

  final EstadoLineaArmado estado;

  /// Queda por debajo de la lista anterior de la misma sucursal. Con una sola
  /// linea asi el servidor no deja guardar la familia.
  final bool fueraDeOrden;

  bool get estaEnPropuesta => idPrecioPropuesto != null;

  bool get estaCalculada => precioCalculado != null;

  /// "Precio 3": como las nombraba el sistema anterior, que armaba el nombre
  /// con `nombrePrecio + ' ' + vpp`. En la base todas se llaman "Precio" y lo
  /// que las distingue es el numero; si algun dia una lista trae su numero en
  /// el nombre, se muestra tal cual.
  String get etiquetaLista {
    final nombre = nombrePrecio.trim();
    if (nombre.isEmpty) return 'Lista $vpp';
    return RegExp(r'\d').hasMatch(nombre) ? nombre : '$nombre $vpp';
  }

  /// Diferencia contra el precio vigente. Cero si no hay calculo.
  double get variacion =>
      precioCalculado == null ? 0 : precioCalculado! - precioActual;

  /// Variacion en porcentaje del precio vigente. Cero sin calculo o sin precio
  /// vigente: sin base no hay porcentaje.
  double get variacionPorcentual =>
      (precioCalculado == null || precioActual == 0)
          ? 0
          : (variacion / precioActual) * 100;

  /// El calculo nuevo cambia lo que ya estaba propuesto.
  bool get cambiaLoGuardado =>
      precioCalculado != null &&
      precioPropuestoGuardado != null &&
      (precioCalculado! - precioPropuestoGuardado!).abs() >= 0.00005;

  /// Texto por el que filtra el buscador.
  String get textoBuscable =>
      '$vpp $nombrePrecio $nombreSucursal ${estado.etiqueta}'.toLowerCase();
}

/// La grilla de una familia en el armado.
@immutable
class CalculoFamiliaEntity {
  const CalculoFamiliaEntity({
    required this.codigoFamilia,
    required this.grupoFamilia,
    required this.proveedor,
    required this.presentacion,
    required this.tipo,
    required this.rangoGramaje,
    required this.color,
    required this.costoActual,
    required this.enPropuesta,
    required this.lineas,
    required this.errores,
    required this.lineasNuevas,
    required this.lineasActualizadas,
    required this.lineasSinCambio,
    required this.guardado,
    this.lineasInactivas = 0,
    this.listasInactivas = const <String>[],
    this.porcentajesCambiados = 0,
    this.idPropuesta,
    this.costo,
    this.costoGuardado,
    this.impedimento,
  });

  /// Null en la vista previa de una propuesta que todavia no existe.
  final BigInt? idPropuesta;

  final int codigoFamilia;
  final String grupoFamilia;
  final String proveedor;
  final String presentacion;
  final String tipo;
  final String rangoGramaje;
  final String color;

  /// Con que costo se calculo. Null si no hubo con que.
  final double? costo;

  /// Costo vigente de la familia (tpr_producto.costoTM).
  final double costoActual;

  /// Costo ya guardado para la familia en la propuesta.
  final double? costoGuardado;

  /// La familia ya esta cargada en la propuesta.
  final bool enPropuesta;

  final List<LineaArmadoEntity> lineas;

  /// Un mensaje por linea fuera de orden, listo para mostrar.
  final List<String> errores;

  final int lineasNuevas;
  final int lineasActualizadas;
  final int lineasSinCambio;

  /// Lineas de la propuesta cuya lista hoy esta inactiva.
  final int lineasInactivas;

  /// Las listas INACTIVAS en las que la familia tiene precio ("Central ·
  /// Precio 1"). No entran en la grilla -una lista inactiva no se reprecia- y
  /// se nombran para que su ausencia no parezca un error.
  final List<String> listasInactivas;

  /// Solo true en la respuesta de guardar.
  final bool guardado;

  /// Cuantas listas se calcularon con un porcentaje cambiado en el editor. Al
  /// guardar, esos porcentajes quedan registrados para la familia.
  final int porcentajesCambiados;

  /// Solo en la vista previa en lote: por que la familia no se podria guardar
  /// tal como esta, ya escrito para mostrar. Null si se puede.
  final String? impedimento;

  bool get hayErrores => errores.isNotEmpty;

  bool get estaCalculada => costo != null && lineas.any((l) => l.estaCalculada);

  /// Cuantas listas se escribirian al guardar.
  int get lineasAEscribir => lineasNuevas + lineasActualizadas;

  /// Se puede guardar tal como esta: calculada, sin errores y con algo que
  /// escribir (o ya en la propuesta, donde guardar actualiza el costo).
  bool get sePuedeGuardar =>
      impedimento == null &&
      estaCalculada &&
      !hayErrores &&
      (lineasAEscribir > 0 || enPropuesta);

  /// Cuanto se mueven en promedio los precios calculados contra los vigentes,
  /// en porcentaje. Null sin calculo.
  double? get variacionMedia {
    final conBase = [
      for (final l in lineas)
        if (l.estaCalculada && l.precioActual != 0) l.variacionPorcentual,
    ];
    if (conBase.isEmpty) return null;
    return conBase.reduce((a, b) => a + b) / conBase.length;
  }

  /// Grupo, tipo, presentacion, gramaje y color, sin separadores colgando.
  String get descripcion {
    final partes = [
      for (final p in [grupoFamilia, tipo, presentacion, rangoGramaje, color])
        if (p.trim().isNotEmpty) p.trim(),
    ];
    return partes.isEmpty ? 'Sin descripción' : partes.join(' · ');
  }
}

/// El flete de una sucursal, en USD por tonelada.
@immutable
class FleteArmadoEntity {
  const FleteArmadoEntity({
    required this.codSucursal,
    required this.nombreSucursal,
    required this.valor,
    this.idIncre,
  });

  /// Fila de tpr_costoIncre. Null en un alta: todavia no existe.
  final BigInt? idIncre;
  final BigInt codSucursal;
  final String nombreSucursal;
  final double valor;

  FleteArmadoEntity conValor(double nuevo) => FleteArmadoEntity(
    idIncre: idIncre,
    codSucursal: codSucursal,
    nombreSucursal: nombreSucursal,
    valor: nuevo,
  );
}

/// Los fletes del paso de datos y de donde salieron.
@immutable
class FletesArmadoEntity {
  const FletesArmadoEntity({
    required this.deLaPropuesta,
    required this.fletes,
    this.idPropuestaReferencia,
  });

  /// De que propuesta salen los valores. En un alta, la ultima por familia;
  /// null si no hubo ninguna de donde copiar.
  final BigInt? idPropuestaReferencia;

  /// true = los fletes guardados de la propuesta; false = sugeridos para un alta.
  final bool deLaPropuesta;

  final List<FleteArmadoEntity> fletes;
}

/// Una familia que ya esta en la propuesta.
@immutable
class FamiliaArmadaEntity {
  const FamiliaArmadaEntity({
    required this.codigoFamilia,
    required this.lineas,
    this.costoSug,
  });

  final int codigoFamilia;

  /// Costo propuesto en USD por tonelada. Null en datos viejos sin costo.
  final double? costoSug;

  /// Cuantas listas tienen precio propuesto.
  final int lineas;
}

/// Lo que hizo una escritura del armado que no devuelve grilla.
@immutable
class ResultadoArmadoEntity {
  const ResultadoArmadoEntity({
    required this.idPropuesta,
    required this.articulos,
    required this.omitidos,
    required this.familiasRecalculadas,
    required this.lineasEscritas,
  });

  /// La propuesta afectada; en un alta, la recien creada.
  final BigInt idPropuesta;

  /// Articulos agregados o quitados.
  final int articulos;

  /// Articulos que ya estaban y no se repitieron.
  final int omitidos;

  final int familiasRecalculadas;
  final int lineasEscritas;
}
