// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Asignacion`, via `p_list_trs_Asignacion @ACCION='L'`.
///
/// Ojo con el vacio: **libre es la AUSENCIA de fila**, no una fila con estado
/// 'L'. Una celda que no viene en la lista es libre.
///
/// Una celda ocupada de la grilla: una persona en un sábado.
///
/// **Que no haya celda significa LIBRE.** El libre no se guarda: es la ausencia
/// de la fila. Por eso la grilla no viene completa y hay que armarla cruzando.
class CeldaTurnoEntity {
  final int idAsignacion;
  final int idRol;
  final int idParticipante;
  final int idSabado;

  /// La letra que se pinta: 1 · V · C · B · A · X · E.
  final String codigoExcel;
  final String estadoNombre;

  /// La capa que la escribió, y lo que decide si sobrevive a una regeneración:
  /// `G` = la rotación (se rehace) · `P` = un jefe · `M` = corrección manual.
  final String origen;
  final String observacion;
  final DateTime? fecha;
  final String nombreRol;

  /// El otro, ya resuelto a nombre. Vacío si esta celda no tiene un cambio
  /// aprobado detrás, que es el caso de casi todas.
  ///
  /// **No sale de `trs_Asignacion` sino de `trs_Cambio`**, y por eso hasta
  /// ahora no estaba: la celda guarda el resultado del cambio —una `C` acá, un
  /// `1` allá— pero nunca guardó con quién.
  final String cambioCon;

  /// `T` = esta persona falta y la cubren · `R` = esta persona cubre a otro.
  ///
  /// **No se puede deducir de la letra.** En una permuta los papeles se dan
  /// vuelta el sábado de reposición: el que cubrió pasa a ser el que falta. El
  /// backend lo resuelve cruzando persona con sábado.
  final String cambioRol;

  /// `COBERTURA` (uno cubre y no se devuelve) o `PERMUTA` (se intercambian el
  /// sábado y quedan los dos con la misma cantidad de turnos).
  final String cambioTipo;

  const CeldaTurnoEntity({
    required this.idAsignacion,
    required this.idRol,
    required this.idParticipante,
    required this.idSabado,
    required this.codigoExcel,
    required this.estadoNombre,
    required this.origen,
    required this.observacion,
    this.fecha,
    required this.nombreRol,
    this.cambioCon = '',
    this.cambioRol = '',
    this.cambioTipo = '',
  });

  /// true si la escribió una persona y una regeneración NO la va a pisar.
  bool get esIntervencion => origen == 'M' || origen == 'P';

  /// true si hay un cambio aprobado detrás **y se sabe con quién**.
  ///
  /// Se mira el nombre y no [cambioRol] a propósito: una cobertura aprobada a
  /// la que todavía no se le asignó reemplazo deja el nombre vacío, y anunciar
  /// «lo cubre» sin nadie sería peor que no decir nada.
  bool get hayCambio => cambioCon.isNotEmpty;

  /// La frase para mostrar, o `''` si no hay con quién.
  ///
  /// La dirección importa más que el tipo: lo primero que se pregunta mirando
  /// una celda es si esta persona es la que falta o la que vino de más.
  String get cambioTexto {
    if (!hayCambio) return '';
    final permuta = cambioTipo == 'PERMUTA' ? 'Permuta · ' : '';
    return cambioRol == 'T'
        ? '${permuta}Lo cubre $cambioCon'
        : '${permuta}Cubre a $cambioCon';
  }
}
