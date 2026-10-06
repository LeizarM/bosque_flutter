/// Reglas de los tres paneles del detalle del cheque (notas de remision,
/// transacciones bancarias y postergaciones) que la pantalla repite para avisar
/// antes de enviar. Es logica pura, sin Flutter ni Riverpod.
///
/// **No son la fuente de verdad.** Reproducen `ReglasPanelesCheque.java` del
/// backend, que a su vez copia lo que el legacy exige en `NotaRemisionManagedBean`,
/// `WizardCheque.saveNotaRemision`, `saveNroTransaccion` y `savePostePostrgcn`.
/// El servidor vuelve a comprobarlas todas y su mensaje es el que manda: aqui
/// solo sirven para que el usuario vea el motivo junto al campo, completo y sin
/// esperar la respuesta.
///
/// Los textos que se escriben se comprueban **ya recortados** (es lo que viaja:
/// el legacy no recortaba, y un recorte solo puede dejar mas claro un error).
abstract final class ReglasPanelesCheque {
  // ── Nota de remision ─────────────────────────────────────────────────────

  /// El regex de `NotaRemisionManagedBean.validarNotaRemision`, **literal**:
  /// `^[0-9  ]{5,10}` (digitos y espacios, de 5 a 10). Los dos espacios dentro
  /// de la clase son espacios normales, como en el original.
  static final RegExp _notaRemision = RegExp(r'^[0-9  ]{5,10}$');
  static final RegExp _caracterNota = RegExp(r'[0-9 ]');

  static const int notaRemisionMin = 5;
  static const int notaRemisionMax = 10;

  /// `maxlength="6"` del campo del legacy: la factura va de 1 a 999999.
  static const int nroFacturaMaxDigitos = 6;
  static const int nroFacturaMax = 999999;

  // ── Transaccion bancaria ─────────────────────────────────────────────────

  /// `saveNroTransaccion`: `getNroTransaccion().length() > 4`, es decir, al
  /// menos 5 caracteres. Sin ningun regex de formato.
  static const int nroTransaccionMin = 5;

  /// El largo de la columna (`varchar(30)`). El legacy no ponia tope y la base
  /// cortaba en silencio; el servidor lo rechaza con un mensaje.
  static const int nroTransaccionMax = 30;

  // ── Postergacion ─────────────────────────────────────────────────────────

  /// `savePostePostrgcn`: `getObservacion().length() > 2`, es decir, al menos 3
  /// caracteres.
  static const int observacionMin = 3;

  /// `maxlength="200"` del cuadro de texto.
  static const int observacionMax = 200;

  // ── Mensajes ─────────────────────────────────────────────────────────────

  static String _verCaracter(String c) => c == ' ' ? 'espacio' : '«$c»';

  /// «tiene caracteres que no se aceptan («a», «-»)»: los que sobran, de a uno,
  /// hasta seis.
  static String _sobran(String valor, RegExp unCaracter) {
    final vistos = <String>[];
    for (final c in valor.split('')) {
      if (!unCaracter.hasMatch(c)) {
        final v = _verCaracter(c);
        if (!vistos.contains(v)) vistos.add(v);
      }
    }
    final lista = vistos.length <= 6 ? vistos : [...vistos.take(6), '…'];
    return lista.join(', ');
  }

  // ── Validadores: cada uno devuelve el mensaje o null si cumple ───────────

  /// El numero de la nota. Obligatorio; 5 a 10 digitos (con espacios).
  static String? errorNotaRemision(String? texto) {
    final v = (texto ?? '').trim();
    if (v.isEmpty) {
      return 'Falta la nota de remisión. Escribe el número que figura en el '
          'documento (de $notaRemisionMin a $notaRemisionMax dígitos).';
    }
    if (_notaRemision.hasMatch(v)) return null;
    final sobran = _sobran(v, _caracterNota);
    if (sobran.isNotEmpty) {
      return 'La nota de remisión «$v» no es válida: tiene caracteres que no se '
          'aceptan ($sobran). Solo acepta números, de $notaRemisionMin a '
          '$notaRemisionMax dígitos.';
    }
    return v.length < notaRemisionMin
        ? 'La nota de remisión «$v» es demasiado corta (${v.length} '
            '${v.length == 1 ? 'carácter' : 'caracteres'}). Debe tener de '
            '$notaRemisionMin a $notaRemisionMax dígitos.'
        : 'La nota de remisión «$v» es demasiado larga (${v.length} '
            'caracteres). Debe tener de $notaRemisionMin a $notaRemisionMax '
            'dígitos.';
  }

  /// El numero de factura. Obligatorio; entero de 1 a 999999.
  static String? errorNroFactura(String? texto) {
    final v = (texto ?? '').trim();
    if (v.isEmpty) {
      return 'Falta el número de factura. Escribe el número de la factura SAP '
          '(de 1 a $nroFacturaMax).';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      final sobran = _sobran(v, RegExp(r'[0-9]'));
      return 'El número de factura «$v» no es válido: tiene caracteres que no '
          'se aceptan ($sobran). Solo acepta números, de 1 a '
          '$nroFacturaMaxDigitos dígitos.';
    }
    if (v.length > nroFacturaMaxDigitos) {
      return 'El número de factura «$v» es demasiado largo (${v.length} '
          'dígitos). Solo acepta hasta $nroFacturaMaxDigitos dígitos '
          '(máximo $nroFacturaMax).';
    }
    if (int.parse(v) <= 0) {
      return 'El número de factura «$v» no es válido: debe ser mayor que 0. '
          'Escribe el número que figura en la factura.';
    }
    return null;
  }

  /// El numero de la transaccion. Obligatorio; de 5 a 30 caracteres, sin mas
  /// formato (el legacy no restringe los caracteres).
  static String? errorNroTransaccion(String? texto) {
    final v = (texto ?? '').trim();
    if (v.isEmpty) {
      return 'Falta el número de transacción. Escríbelo tal como lo da el banco '
          '(de $nroTransaccionMin a $nroTransaccionMax caracteres).';
    }
    if (v.length < nroTransaccionMin) {
      return 'El número de transacción «$v» es demasiado corto (${v.length} '
          '${v.length == 1 ? 'carácter' : 'caracteres'}). Debe tener más de '
          '${nroTransaccionMin - 1} caracteres; revisa que esté completo.';
    }
    if (v.length > nroTransaccionMax) {
      return 'El número de transacción es demasiado largo (${v.length} '
          'caracteres). Admite hasta $nroTransaccionMax; revisa que no se '
          'hayan pegado datos de más.';
    }
    return null;
  }

  /// El motivo de la postergacion. Obligatorio; de 3 a 200 caracteres, texto
  /// libre.
  static String? errorObservacionPostergacion(String? texto) {
    final v = (texto ?? '').trim();
    if (v.isEmpty) {
      return 'Falta el motivo de la postergación. Cuenta brevemente por qué se '
          'posterga el cobro (de $observacionMin a $observacionMax caracteres).';
    }
    if (v.length < observacionMin) {
      return 'El motivo «$v» es demasiado corto (${v.length} '
          '${v.length == 1 ? 'carácter' : 'caracteres'}). Debe tener más de '
          '${observacionMin - 1} caracteres para que se entienda.';
    }
    if (v.length > observacionMax) {
      return 'El motivo es demasiado largo (${v.length} caracteres). Admite '
          'hasta $observacionMax; resúmelo.';
    }
    return null;
  }

  /// La fecha de la factura, de la transaccion o de la postergacion. Obligatoria
  /// y sin rango (el legacy no la acota).
  static String? errorFechaRequerida(DateTime? fecha, {required String campo}) =>
      fecha == null ? 'Falta $campo. Elígela en el calendario.' : null;
}
