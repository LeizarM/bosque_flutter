/// Un talonario de vales de caja chica entregado a la sucursal (o al
/// encargado) de una ocurrencia: `p_list_tac_CajaChica` 'V' (archivo SQL 93).
/// Qué vale se puede usar lo decide el SP al registrar el egreso.
class TalonarioCajaChica {
  final int codTalonario;
  final String nroTalonario;
  final int desde;
  final int hasta;
  final int usados;
  final int libres;

  /// El vale que sigue al último usado; null si ya se usó el último.
  final int? siguienteVale;

  /// El que se usa ahora (archivo SQL 97): uno por sucursal y uno por persona.
  /// Los demás esperan a que este llegue a su último vale.
  final bool activo;

  /// A nombre de quién está, si se entregó a una persona (archivo SQL 98):
  /// lo usa cualquiera de su sucursal, por ejemplo el cajero. Vacío si se
  /// entregó a la sucursal.
  final String titular;

  const TalonarioCajaChica({
    required this.codTalonario,
    required this.nroTalonario,
    required this.desde,
    required this.hasta,
    this.usados = 0,
    this.libres = 0,
    this.siguienteVale,
    this.activo = false,
    this.titular = '',
  });
}

/// Las reglas del número de recibo para quien registra, en palabras:
/// `p_list_tac_CajaChica` 'G' (archivo SQL 99). Las escribe el SP con la misma
/// configuración que aplica al registrar, así que no se repiten en la app.
class ReglasReciboCajaChica {
  final String titulo;
  final String regla;

  /// Si el número de recibo es obligatorio para registrar.
  final bool obligatorio;

  const ReglasReciboCajaChica({
    required this.titulo,
    required this.regla,
    required this.obligatorio,
  });
}

/// Un vale de un talonario de caja chica y el egreso en que se usó:
/// `p_list_tac_CajaChica` 'T' (archivo SQL 93). Sin usar, solo trae el número.
class ValeCajaChica {
  final int numVale;
  final bool usado;
  final DateTime? fecha;
  final String nombreSucursal;
  final int? lote;
  final double? monto;
  final String descripcion;
  final String entregadoA;

  const ValeCajaChica({
    required this.numVale,
    this.usado = false,
    this.fecha,
    this.nombreSucursal = '',
    this.lote,
    this.monto,
    this.descripcion = '',
    this.entregadoA = '',
  });
}

/// Cómo va un talonario de caja chica, a partir de sus vales.
class UsoTalonarioCajaChica {
  final List<ValeCajaChica> vales;

  const UsoTalonarioCajaChica(this.vales);

  List<ValeCajaChica> get usados => [
    for (final v in vales)
      if (v.usado) v,
  ];

  int get total => vales.length;

  /// El último vale usado; null si no se usó ninguno.
  int? get ultimo => usados.isEmpty ? null : usados.last.numVale;

  /// Sin usar después del último usado: los que quedan en el talonario.
  int get quedan {
    final u = ultimo;
    return u == null ? total : vales.where((v) => v.numVale > u).length;
  }

  /// Sin usar antes del último usado: un vale que se saltó (roto, perdido o
  /// todavía sin registrar).
  List<int> get saltados {
    final u = ultimo;
    if (u == null) return const [];
    return [
      for (final v in vales)
        if (!v.usado && v.numVale < u) v.numVale,
    ];
  }
}
