/// Reglas de formulario de «Verificar Cheques» que la pantalla repite para avisar
/// antes de enviar. Es logica pura, sin Flutter ni Riverpod.
///
/// **No son la fuente de verdad.** Reproducen `ReglasVerificacion.java` del
/// backend, que copia el validador del legacy tal como lo aplica hoy
/// (`VerificacionDepositoManagedBean.validarObservacion`); el servidor vuelve a
/// comprobar todo y su mensaje es el que manda. Aqui solo sirven para que el
/// usuario vea el error junto al campo y no espere la respuesta.
abstract final class ReglasVerificacion {
  /// El largo maximo de la observacion: la columna es `varchar(50)` y el campo
  /// del legacy tenia `maxlength=50`.
  static const int largoMaximoObservacion = 50;

  /// `^[a-zA-Z0-9  ' '',''.' ]{0,50}` del legacy, interpretada como la clase de
  /// caracteres que es: letras **sin tilde ni ñ**, digitos, espacio, apostrofe,
  /// coma y punto. No admite `;`, `:`, guion, parentesis ni saltos de linea.
  static final RegExp _observacion = RegExp(r"^[a-zA-Z0-9 ',.]{0,50}$");
  static final RegExp _caracterValido = RegExp(r"^[a-zA-Z0-9 ',.]$");

  /// Lo que acepta el campo, dicho en una frase.
  static const String queAceptaObservacion =
      'letras sin tilde ni ñ, números, espacios, apóstrofe, coma y punto, '
      'hasta 50 caracteres';

  /// Los caracteres de [v] que la observacion no admite, sin repetir y en el
  /// orden en que aparecen. Vacio si todos valen.
  static List<String> caracteresNoAceptados(String v) {
    final vistos = <String>[];
    for (final c in v.split('')) {
      if (!_caracterValido.hasMatch(c) && !vistos.contains(c)) vistos.add(c);
    }
    return vistos;
  }

  static String _verCaracter(String c) => switch (c) {
    ' ' => 'espacio',
    '\n' => 'salto de línea',
    '\t' => 'tabulación',
    _ => '«$c»',
  };

  /// Vacia es valida. Si no cumple, dice **que sobra** y que acepta el campo.
  static String? errorObservacion(String? v) {
    if (v == null || v.isEmpty) return null;
    if (_observacion.hasMatch(v)) return null;
    final sobran = caracteresNoAceptados(v);
    if (sobran.isNotEmpty) {
      final lista = sobran.take(6).map(_verCaracter).join(', ');
      return 'La observación tiene caracteres que no se aceptan '
          '($lista${sobran.length > 6 ? ', …' : ''}). '
          'Solo acepta $queAceptaObservacion.';
    }
    return 'La observación es demasiado larga (${v.length} caracteres). '
        'Solo acepta $queAceptaObservacion.';
  }
}
