/// Reglas de formulario del modulo de cheques que la pantalla repite para avisar
/// antes de enviar. Es logica pura, sin Flutter ni Riverpod.
///
/// **No son la fuente de verdad.** Reproducen `ReglasCheque.java` del backend,
/// que a su vez copia los validadores del legacy tal como los aplica hoy; el
/// servidor vuelve a comprobarlas todas y su mensaje es el que manda. Aqui solo
/// sirven para que el usuario vea el error junto al campo y no tenga que esperar
/// la respuesta. Donde el legacy hace menos de lo que promete su mensaje (el
/// largo del Nro de cheque, por ejemplo) aqui tampoco se endurece.
abstract final class ReglasCheque {
  /// Dias a cada lado de la fecha del cheque dentro de los que cae la fecha de
  /// cobro.
  static const int diasToleranciaCobro = 28;

  /// Digitos, `?` y guion medio, de cualquier largo: el `{2,25}` del legacy no
  /// limita nada (el largo real lo limita el campo, 45).
  static final RegExp _nroCheque = RegExp(r'^[0-9?-]*$');

  static final RegExp _aOrdenDe = RegExp(r"^[a-zA-Z ñÑáÁéÉíÍóÓúÚ']{0,100}$");
  static final RegExp _reciboManual = RegExp(r"^[a-zA-Z0-9 ']{1,25}$");
  static final RegExp _nroTalonario = RegExp(r'^[a-zA-Z0-9 ]{1,25}$');
  static final RegExp _observacion = RegExp(
    r"^[a-zA-Z0-9 ñÑáÁéÉíÍóÓúÚ,;:.']{2,200}$",
  );
  static final RegExp _nroSap = RegExp(r"^[a-zA-Z0-9 ñÑáÁéÉíÍóÓúÚ']{2,40}$");

  // ── Formatos: cada uno devuelve el mensaje o null si cumple ──────────────

  static String? errorNroCheque(String? v) =>
      v != null && _nroCheque.hasMatch(v)
          ? null
          : 'Solo se permiten números y guion medio.';

  static String? errorAOrdenDe(String? v) =>
      v != null && _aOrdenDe.hasMatch(v)
          ? null
          : 'Solo se permiten letras, acentos y espacios.';

  static String? errorReciboManual(String? v) =>
      v != null && _reciboManual.hasMatch(v)
          ? null
          : 'Letras, números y espacios (de 1 a 25 caracteres).';

  static String? errorNroTalonario(String? v) =>
      v != null && _nroTalonario.hasMatch(v)
          ? null
          : 'Letras, números y espacios (de 1 a 25 caracteres).';

  /// Vacia es valida: la observacion no es obligatoria.
  static String? errorObservacion(String? v) {
    if (v == null || v.isEmpty) return null;
    return _observacion.hasMatch(v)
        ? null
        : 'Letras, números, espacios y , ; : . (de 2 a 200 caracteres).';
  }

  /// El Nro de SAP: su obligatoriedad la decide quien llama (solo al cerrar).
  static String? errorNroSap(String? v) =>
      v != null && _nroSap.hasMatch(v)
          ? null
          : 'Letras, números y espacios (de 2 a 40 caracteres).';

  /// El nombre de un banco: el regex de `BancoManagedBean.validarNombre` **tal
  /// cual**, con sus rarezas, igual que el servidor (`ReglasCheque.java`). `A-z`
  /// admite tambien `[ \ ] ^ _ \``, la `S` suelta es la letra S y el `'-'` es el
  /// rango de un solo caracter, el apostrofe: **el guion medio no entra**, aunque
  /// el mensaje del servidor diga que si. No hay punto ni acentos.
  static final RegExp _nombreBanco = RegExp(r"^[a-zA-z0-9 ' ' '-'  /S]{3,50}$");

  /// Se valida el nombre ya sin espacios de los bordes, que es lo que se envia.
  static String? errorNombreBanco(String? v) =>
      v != null && _nombreBanco.hasMatch(v.trim())
          ? null
          : 'De 3 a 50 caracteres: letras sin acento, números, espacios, '
              'apóstrofe y barra (/). Sin punto ni acentos.';

  // ── Recibo y talonario ───────────────────────────────────────────────────

  /// El recibo manual segun quien entrego el cheque: del cliente, «0»; de un
  /// empleado, distinto de «0». [codEmpleado] 0 = lo dejo el cliente. «0» se
  /// compara exacto, como el `equals("0")` del legacy.
  static String? errorReciboSegunEntrega({
    required int codEmpleado,
    required String reciboManual,
  }) {
    final reciboCero = reciboManual == '0';
    if (codEmpleado == 0 && !reciboCero) {
      return 'Si el cheque lo dejó el cliente, el recibo manual debe ser 0.';
    }
    if (codEmpleado != 0 && reciboCero) {
      return 'Si lo trajo un empleado, el recibo manual debe ser distinto de 0.';
    }
    return null;
  }

  /// Un recibo manual exige un talonario manual distinto de «0».
  static String? errorTalonarioSegunRecibo({
    required String reciboManual,
    required String nroTalonario,
  }) =>
      reciboManual != '0' && nroTalonario == '0'
          ? 'Si hay un recibo manual, el talonario manual debe ser distinto de 0.'
          : null;

  /// Las tres reglas que ligan a quien entrego el cheque con el recibo y el
  /// talonario manual. Son independientes y el legacy las acumula; la cuarta
  /// (que el par exista en `tmto_talonario`) la comprueba solo el servidor.
  static List<String> erroresReciboTalonario({
    required int codEmpleado,
    required String reciboManual,
    required String nroTalonario,
  }) {
    final entrega = errorReciboSegunEntrega(
      codEmpleado: codEmpleado,
      reciboManual: reciboManual,
    );
    final talonario = errorTalonarioSegunRecibo(
      reciboManual: reciboManual,
      nroTalonario: nroTalonario,
    );
    return [if (entrega != null) entrega, if (talonario != null) talonario];
  }

  // ── Fechas ───────────────────────────────────────────────────────────────

  static DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

  /// El rango de fechas de cobro admitido para un cheque con [fechaCheque]:
  /// 28 dias antes y 28 despues, ambos incluidos.
  static ({DateTime desde, DateTime hasta}) rangoCobro(DateTime fechaCheque) {
    final d = _dia(fechaCheque);
    return (
      desde: DateTime(d.year, d.month, d.day - diasToleranciaCobro),
      hasta: DateTime(d.year, d.month, d.day + diasToleranciaCobro),
    );
  }

  /// La fecha de cobro cae dentro de +-28 dias de la del cheque. Compara dias,
  /// no instantes.
  static bool cobroEnRango(DateTime fechaCobro, DateTime fechaCheque) {
    final r = rangoCobro(fechaCheque);
    final c = _dia(fechaCobro);
    return !c.isBefore(r.desde) && !c.isAfter(r.hasta);
  }

  /// Lee un monto escrito con coma de miles («12,345.67»). Null si esta vacio
  /// o no es un numero.
  static double? leerMonto(String? t) {
    if (t == null || t.trim().isEmpty) return null;
    return double.tryParse(t.trim().replaceAll(',', ''));
  }
}
