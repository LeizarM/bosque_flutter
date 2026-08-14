// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

/// **Origen:** `p_list_Permiso @ACCION='D'`, uno de los 5 tramos que el backend
/// arma sobre la fila de 20 columnas del SP.
///
/// La `etiqueta` la escribe el propio SP (con `UPDATE`s sobre la tabla temporal)
/// y llega con las fechas ya adentro. Se muestra **literal**, sin reescribir ni
/// corregir la ortografía: el criterio de aceptación es que sea carácter por
/// carácter igual a la del modal legacy, que es contra lo que RR.HH. compara.
///
/// Uno de los 5 tramos del desglose.
class TramoSaldoEntity {
  /// `SALDO_PENULTIMO` | `ASIGNADA_ANIO` | `ACUMULADA` | `UTILIZADA` |
  /// `PROGRAMADA`. Es lo único estable: la etiqueta cambia con las fechas.
  final String clave;

  /// La frase que escribió el SP. Se muestra **tal cual**, con sus fechas
  /// adentro. Llega a ~95 caracteres: la pantalla tiene que dejarla envolver.
  final String etiqueta;

  final double monto;
  final String montoTxt;

  /// `DEBE` suma, `HABER` resta, **`INFO` no entra en el total** (ver D1).
  final String signo;

  /// Reservado para el drill-down de la Fase 2. En la Fase 1 llega siempre
  /// `false` y no se pinta ningún botón «Detalle».
  final bool tieneDetalle;

  const TramoSaldoEntity({
    required this.clave,
    required this.etiqueta,
    required this.monto,
    required this.montoTxt,
    required this.signo,
    required this.tieneDetalle,
  });

  bool get esInformativo => signo == 'INFO';

  /// Suma al total: es saldo a favor del empleado.
  bool get suma => signo == 'DEBE';

  /// Resta del total: días que ya usó o que tiene comprometidos.
  bool get resta => signo == 'HABER';

  /// El signo escrito, que es lo que la etiqueta del SP no dice. «22 días» no
  /// aclara si se suman o se restan, y en un saldo eso es la mitad del dato.
  String get montoConSigno =>
      esInformativo ? montoTxt : '${suma ? '+' : '−'} $montoTxt';
}
