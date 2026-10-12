import 'package:bosque_flutter/domain/entities/empleado_entity.dart';

class IndemnizacionEntity {
  final int? codIndemnizacion;
  final int? codEmpleado;
  final double? montoIndemnizacion;
  final DateTime? fechaIndemnizacion;
  final String? descripcion;
  final int? estado;
  final String? empleadoNombres;
  final String? empleadoApellidos;
  final String? empresa;

  final int? nro;
  final String? apellidos;
  final String? fechaIngreso;
  final String? periodo;
  final String? fechaSalida;
  final int? diasactual;
  final String? antiguedad;
  final double? totalGanadoFecha;
  final double? tercerMesAnterior;
  final double? segundoMesAnterior;
  final double? primerMesAnterior;
  final double? promedioMeses;
  final double? indemnizacionMesAnterior;
  final int? dias30;
  final double? indemnizacionCalculada;
  final double? indemnizacionActual;
  final double? pagoFiniquitoQuinq;
  final double? indemnizacionFinal;
  final String? caja;
  final String? sucursal;
  final String? area;

  // Metadata Paginacion
  final int? pagina;
  final int? tamanoPagina;
  final int? totalPaginas;
  final int? totalRegistros;

  IndemnizacionEntity({
    this.codIndemnizacion,
    this.codEmpleado,
    this.montoIndemnizacion,
    this.fechaIndemnizacion,
    this.descripcion,
    this.estado,
    this.empleadoNombres,
    this.empleadoApellidos,
    this.empresa,
    this.nro,
    this.apellidos,
    this.fechaIngreso,
    this.periodo,
    this.fechaSalida,
    this.diasactual,
    this.antiguedad,
    this.totalGanadoFecha,
    this.tercerMesAnterior,
    this.segundoMesAnterior,
    this.primerMesAnterior,
    this.promedioMeses,
    this.indemnizacionMesAnterior,
    this.dias30,
    this.indemnizacionCalculada,
    this.indemnizacionActual,
    this.pagoFiniquitoQuinq,
    this.indemnizacionFinal,
    this.caja,
    this.sucursal,
    this.area,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.totalRegistros,
  });


  IndemnizacionEntity copyWith({
    int? codIndemnizacion,
    int? codEmpleado,
    double? montoIndemnizacion,
    DateTime? fechaIndemnizacion,
    String? descripcion,
    int? estado,
    String? empleadoNombres,
    String? empleadoApellidos,
    String? empresa,
    // ... no aÃ±adimos todos los del listado aqui para no hacer tan grande esto a menos que se requiera localmente
  }) {
    return IndemnizacionEntity(
      codIndemnizacion: codIndemnizacion ?? this.codIndemnizacion,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      montoIndemnizacion: montoIndemnizacion ?? this.montoIndemnizacion,
      fechaIndemnizacion: fechaIndemnizacion ?? this.fechaIndemnizacion,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      empleadoNombres: empleadoNombres ?? this.empleadoNombres,
      empleadoApellidos: empleadoApellidos ?? this.empleadoApellidos,
      empresa: empresa ?? this.empresa,
      nro: this.nro,
      apellidos: this.apellidos,
      fechaIngreso: this.fechaIngreso,
      periodo: this.periodo,
      fechaSalida: this.fechaSalida,
      diasactual: this.diasactual,
      antiguedad: this.antiguedad,
      totalGanadoFecha: this.totalGanadoFecha,
      tercerMesAnterior: this.tercerMesAnterior,
      segundoMesAnterior: this.segundoMesAnterior,
      primerMesAnterior: this.primerMesAnterior,
      promedioMeses: this.promedioMeses,
      indemnizacionMesAnterior: this.indemnizacionMesAnterior,
      dias30: this.dias30,
      indemnizacionCalculada: this.indemnizacionCalculada,
      indemnizacionActual: this.indemnizacionActual,
      pagoFiniquitoQuinq: this.pagoFiniquitoQuinq,
      indemnizacionFinal: this.indemnizacionFinal,
      caja: this.caja,
      sucursal: this.sucursal,
      area: this.area,
      pagina: this.pagina,
      tamanoPagina: this.tamanoPagina,
      totalPaginas: this.totalPaginas,
      totalRegistros: this.totalRegistros,
    );
  }
}

