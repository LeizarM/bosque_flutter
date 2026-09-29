// Destino final: lib/domain/entities/traspaso_efectivo_tesbase_entity.dart

/// Una transferencia de efectivo entre sistemas.
///
/// Es del subsistema TesBase (tesorería, `ttes_TesBase`): Cobranza la registra
/// en el sistema anterior cuando un cliente pasa efectivo de una base a otra, y
/// nace PENDIENTE. La tarea 289 (idATR 11) es verificarlas y cerrarlas.
///
/// **No confundir con Caja AXA** (idATR 12, `tac_traspasoMovCaja`). Los nombres
/// casi iguales ya causaron un enredo: ver el archivo SQL 51.
class TraspasoEfectivoTesBaseEntity {
  final int codTes;
  final String? codCliente;
  final String? datoCliente;

  /// La base de origen (tb_empresa).
  final String? nombreEmpresa;
  final DateTime? fechaRegistro;
  final String? observacion;

  /// PEN, CER o FIN.
  final String? estado;
  final DateTime? fechaFinalizacion;

  const TraspasoEfectivoTesBaseEntity({
    required this.codTes,
    this.codCliente,
    this.datoCliente,
    this.nombreEmpresa,
    this.fechaRegistro,
    this.observacion,
    this.estado,
    this.fechaFinalizacion,
  });

  String get _estado => (estado ?? '').trim().toUpperCase();

  /// Todavía sin verificar.
  bool get pendiente => _estado == 'PEN';

  /// El estado dicho para una persona. CER lo pone esta tarea al cerrarla;
  /// FIN, el módulo de registro del sistema anterior.
  String get estadoTexto => switch (_estado) {
    'PEN' => 'Pendiente',
    'CER' => 'Cerrada',
    'FIN' => 'Finalizada',
    '' => 'Sin estado',
    final otro => otro,
  };

  /// Código y nombre del cliente, sin separadores sueltos cuando falta uno.
  String get cliente {
    final partes =
        [
          codCliente,
          datoCliente,
        ].map((s) => (s ?? '').trim()).where((s) => s.isNotEmpty).toList();
    return partes.isEmpty ? 'Cliente sin datos' : partes.join(' · ');
  }

  /// Días desde que se registró, contados por fecha y no por horas.
  int? diasPendiente(DateTime hoy) {
    final r = fechaRegistro;
    if (r == null) return null;
    final a = DateTime(r.year, r.month, r.day);
    final b = DateTime(hoy.year, hoy.month, hoy.day);
    return b.difference(a).inDays;
  }
}

/// Qué día revisa una ocurrencia de la tarea 289.
///
/// Marcelo (2026-09-11): "tiene que aparecer de un día anterior por defecto y
/// si es feriado, domingo o lunes, de dos días antes". Lo calcula el servidor
/// (archivo SQL 58) con los feriados de la sucursal de quien tiene la tarea:
/// el lunes revisa el sábado, y el día después de un feriado, el anterior al
/// feriado.
class DiaRevisadoTesBase {
  /// La fecha de la ocurrencia.
  final DateTime fechaTarea;

  /// El día hábil anterior: lo registrado ese día es lo que se revisa.
  final DateTime fechaRevisada;

  /// El feriado que se saltó, si hubo alguno (el más reciente), como está
  /// cargado en el calendario de RR.HH.
  final String? feriado;

  const DiaRevisadoTesBase({
    required this.fechaTarea,
    required this.fechaRevisada,
    this.feriado,
  });

  /// Los días que quedan entre el revisado y la tarea, sin contar ninguno de
  /// los dos: los que se saltaron por domingo o feriado.
  List<DateTime> get diasSaltados => [
    for (
      var d = DateTime(
        fechaRevisada.year,
        fechaRevisada.month,
        fechaRevisada.day + 1,
      );
      d.isBefore(DateTime(fechaTarea.year, fechaTarea.month, fechaTarea.day));
      d = DateTime(d.year, d.month, d.day + 1)
    )
      d,
  ];
}
