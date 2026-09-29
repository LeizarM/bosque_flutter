/// Búsqueda por palabras del catálogo de Ventas.
///
/// "bond 75" encuentra "BOBINA BOND BLANCO 075G 058X100CM 1ROLLO SUZANO":
/// - Cada palabra tiene que aparecer (en cualquier orden) en la descripción o
///   en el código. Mayúsculas y tildes no importan.
/// - Una palabra que es sólo número se compara contra los números del texto
///   sin ceros a la izquierda y por prefijo: "75" encuentra "075G" y "750",
///   pero no "1750" (que es otro gramaje).
/// - Cualquier otra palabra se busca como parte del texto: "bon" encuentra
///   "BOND", "75g" encuentra "075G".
class BusquedaArticulos {
  final List<String> _palabras;
  final List<String> _numeros;

  BusquedaArticulos._(this._palabras, this._numeros);

  factory BusquedaArticulos(String consulta) {
    final palabras = <String>[];
    final numeros = <String>[];
    for (final p in normalizar(consulta).split(RegExp(r'\s+'))) {
      if (p.isEmpty) continue;
      if (_soloDigitos.hasMatch(p)) {
        numeros.add(_sinCeros(p));
      } else {
        palabras.add(p);
      }
    }
    return BusquedaArticulos._(palabras, numeros);
  }

  static final _soloDigitos = RegExp(r'^\d+$');
  static final _digitos = RegExp(r'\d+');

  bool get vacia => _palabras.isEmpty && _numeros.isEmpty;

  /// Minúsculas y sin tildes. Mantiene el largo del texto, así las posiciones
  /// sirven para resaltar sobre el original.
  static String normalizar(String texto) {
    const con = 'áàäâéèëêíìïîóòöôúùüûÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛ';
    const sin = 'aaaaeeeeiiiioooouuuuaaaaeeeeiiiioooouuuu';
    final buf = StringBuffer();
    for (final ch in texto.toLowerCase().split('')) {
      final i = con.indexOf(ch);
      buf.write(i >= 0 ? sin[i] : ch);
    }
    return buf.toString();
  }

  static String _sinCeros(String n) {
    final s = n.replaceFirst(RegExp(r'^0+'), '');
    return s.isEmpty ? '0' : s;
  }

  bool _numeroCoincide(String enTexto, String buscado) =>
      _sinCeros(enTexto).startsWith(buscado);

  /// ¿El texto (ya pasado por [normalizar]) cumple todas las palabras?
  bool coincideNormalizado(String normalizado) {
    for (final p in _palabras) {
      if (!normalizado.contains(p)) return false;
    }
    if (_numeros.isNotEmpty) {
      final enTexto = _digitos
          .allMatches(normalizado)
          .map((m) => m.group(0)!)
          .toList(growable: false);
      for (final n in _numeros) {
        if (!enTexto.any((t) => _numeroCoincide(t, n))) return false;
      }
    }
    return true;
  }

  bool coincide(String texto) => coincideNormalizado(normalizar(texto));

  /// Tramos del texto que coinciden con la búsqueda, ordenados y sin
  /// superponerse, para resaltarlos. `(inicio, fin)` con fin exclusivo.
  List<(int, int)> tramos(String texto) {
    if (vacia) return const [];
    final t = normalizar(texto);
    final tramos = <(int, int)>[];
    for (final p in _palabras) {
      var i = t.indexOf(p);
      while (i >= 0) {
        tramos.add((i, i + p.length));
        i = t.indexOf(p, i + p.length);
      }
    }
    if (_numeros.isNotEmpty) {
      // Sólo la parte que se buscó: en "075058100" con "75" se marca "075",
      // no el número entero.
      for (final m in _digitos.allMatches(t)) {
        final run = m.group(0)!;
        final ceros = run.length - run.replaceFirst(RegExp(r'^0+'), '').length;
        for (final n in _numeros) {
          if (_numeroCoincide(run, n)) {
            final largo = (ceros + n.length).clamp(1, run.length);
            tramos.add((m.start, m.start + largo));
          }
        }
      }
    }
    if (tramos.isEmpty) return const [];
    tramos.sort((a, b) => a.$1.compareTo(b.$1));
    final unidos = <(int, int)>[tramos.first];
    for (final r in tramos.skip(1)) {
      final ultimo = unidos.last;
      if (r.$1 <= ultimo.$2) {
        unidos[unidos.length - 1] = (
          ultimo.$1,
          r.$2 > ultimo.$2 ? r.$2 : ultimo.$2,
        );
      } else {
        unidos.add(r);
      }
    }
    return unidos;
  }
}
