/// Cuándo dos nombres de tarea dicen lo mismo aunque no estén escritos igual.
///
/// Marcelo (2026-09-11), sobre el aviso de tarea repetida: "solo funciona si
/// es exacto, ¿qué pasa si alguien anota 'Arqueo Caja' o 'Caja Arqueo' o
/// 'Arqueo Cajah'? Es lo mismo, pero no lo es al mismo tiempo".
///
/// De ahí los dos niveles de [NivelParecido]. `igual` es el mismo texto salvo
/// mayúsculas, tildes, signos y espacios: casi seguro un duplicado. `parecido`
/// son las mismas palabras importantes, en cualquier orden y con algún error
/// de tipeo: puede ser la misma tarea o no, y hay que mirarla. Por eso el aviso
/// muestra cuáles son y no solo cuántas.
///
/// No importa nada de Flutter, así se puede probar contra el catálogo real con
/// `dart run`.
library;

import 'dart:math' as math;

enum NivelParecido { igual, parecido }

const _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
};

/// El texto en minúsculas y sin tildes. La ñ se queda: "año" y "ano" no son
/// la misma palabra.
String sinTildes(String texto) {
  final sb = StringBuffer();
  for (final r in texto.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    sb.write(_sinTilde[c] ?? c);
  }
  return sb.toString();
}

final _separadores = RegExp(r'[^a-z0-9ñ]+');
final _digito = RegExp(r'[0-9]');

/// Lo que se compara para decir "igual": minúsculas, sin tildes, y los
/// signos, espacios y saltos de línea convertidos en un solo espacio.
String claveDeNombre(String texto) =>
    sinTildes(texto).replaceAll(_separadores, ' ').trim();

/// Palabras que aparecen en casi cualquier nombre y no distinguen una tarea de
/// otra. Sin sacarlas, "Arqueo Caja" no se reconoce en "Arqueo de Caja".
const _vacias = {
  'a', 'al', 'con', 'de', 'del', 'e', 'el', 'en', 'la', 'las', 'lo', 'los', //
  'o', 'para', 'por', 'que', 'se', 'su', 'sus', 'u', 'un', 'una', 'y', //
};

List<String> _palabrasDeClave(String clave) => [
  for (final p in clave.split(' '))
    if (p.isNotEmpty && !_vacias.contains(p)) p,
];

/// Si dos palabras son la misma con un error de tipeo o con otra terminación.
///
/// - Cortas (menos de 4 letras) y las que llevan números: solo idénticas.
///   "mes" y "más", o "2025" y "2026", son palabras distintas.
/// - De 4 a 7 letras: un error ("cajah", "arqeuo").
/// - De 8 o más: dos ("sucursales" y "sucursal").
/// - La misma raíz de 6 letras o más: "verificar" y "verificación".
bool mismaPalabra(String a, String b) {
  if (a == b) return true;
  final corta = a.length < b.length ? a.length : b.length;
  if (corta < 4 || _digito.hasMatch(a) || _digito.hasMatch(b)) return false;

  final tolerancia = corta >= 8 ? 2 : 1;
  if ((a.length - b.length).abs() <= tolerancia &&
      _distancia(a, b, tolerancia) <= tolerancia) {
    return true;
  }
  final raiz = _prefijoComun(a, b);
  return raiz >= 6 && raiz >= corta * 0.8;
}

/// Errores de tipeo entre dos palabras: letra de más, de menos, cambiada o
/// dos letras vecinas invertidas. Deja de contar pasado [tope].
int _distancia(String a, String b, int tope) {
  final m = b.length;
  var dosAtras = List<int>.filled(m + 1, 0);
  var atras = List<int>.generate(m + 1, (j) => j);
  var fila = List<int>.filled(m + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    fila[0] = i;
    var menor = i;
    for (var j = 1; j <= m; j++) {
      final cambio = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = atras[j] + 1;
      if (fila[j - 1] + 1 < v) v = fila[j - 1] + 1;
      if (atras[j - 1] + cambio < v) v = atras[j - 1] + cambio;
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
          dosAtras[j - 2] + 1 < v) {
        v = dosAtras[j - 2] + 1;
      }
      fila[j] = v;
      if (v < menor) menor = v;
    }
    if (menor > tope) return tope + 1;
    final reciclada = dosAtras;
    dosAtras = atras;
    atras = fila;
    fila = reciclada;
  }
  return atras[m];
}

int _prefijoComun(String a, String b) {
  final n = a.length < b.length ? a.length : b.length;
  var i = 0;
  while (i < n && a.codeUnitAt(i) == b.codeUnitAt(i)) {
    i++;
  }
  return i;
}

/// Cuánto distingue cada palabra dentro de un catálogo.
///
/// Sin esto, "Administrar el firewall, velando por su correcto funcionamiento
/// en todo momento" y "Administrar el Tomcat, velando por su correcto…"
/// salían parecidas: comparten 6 de 7 palabras, y la única que importa es la
/// distinta. El catálogo real tiene ese molde en seis tareas de Sistemas. Una
/// palabra que está en muchas tareas pesa poco; una que está en pocas, mucho.
class PesoDePalabras {
  final Map<String, int> _enCuantas;
  final int _tareas;

  const PesoDePalabras._(this._enCuantas, this._tareas);

  factory PesoDePalabras(Iterable<NombreComparable> catalogo) {
    final cuenta = <String, int>{};
    var tareas = 0;
    for (final nombre in catalogo) {
      tareas++;
      for (final palabra in nombre.palabras.toSet()) {
        cuenta[palabra] = (cuenta[palabra] ?? 0) + 1;
      }
    }
    return PesoDePalabras._(cuenta, tareas);
  }

  /// Entre 1 (está en todas las tareas) y ~7 (no está en ninguna).
  double de(String palabra) =>
      math.log((_tareas + 1) / ((_enCuantas[palabra] ?? 0) + 1)) + 1;
}

/// Qué parte de los dos nombres se corresponde, de 0 a 1.
///
/// Es la parte emparejada del peso total de las palabras de los dos. Sin
/// [peso] todas pesan 1 y es el coeficiente de Dice: 2 × pares ÷ (palabras de
/// uno + palabras del otro). Primero se emparejan las idénticas y después las
/// parecidas, para que una parecida no le quite la pareja a una idéntica.
double parecidoEntre(List<String> a, List<String> b, [PesoDePalabras? peso]) {
  if (a.isEmpty || b.isEmpty) return 0;
  double pesoDe(String palabra) => peso == null ? 1 : peso.de(palabra);

  final libreA = List<bool>.filled(a.length, true);
  final libreB = List<bool>.filled(b.length, true);
  var emparejado = 0.0;
  for (final exacta in const [true, false]) {
    for (var i = 0; i < a.length; i++) {
      if (!libreA[i]) continue;
      for (var j = 0; j < b.length; j++) {
        if (!libreB[j]) continue;
        if (exacta ? a[i] == b[j] : mismaPalabra(a[i], b[j])) {
          libreA[i] = false;
          libreB[j] = false;
          emparejado += pesoDe(a[i]) + pesoDe(b[j]);
          break;
        }
      }
    }
  }

  var total = 0.0;
  for (final palabra in a) {
    total += pesoDe(palabra);
  }
  for (final palabra in b) {
    total += pesoDe(palabra);
  }
  return emparejado / total;
}

/// Desde cuánto [parecidoEntre] cuenta como parecido.
///
/// Sin pesos, dos nombres de 2 y 3 palabras que comparten 2 dan 0,8 y no
/// avisan: "Arqueo de Caja" y "Arqueo de Caja Chica" son tareas distintas.
/// Sí avisan 3 de 4 palabras (0,86).
const umbralParecido = 0.85;

/// Un nombre preparado una vez para compararlo muchas.
class NombreComparable {
  /// Ver [claveDeNombre].
  final String clave;

  /// Las palabras que cuentan, sin las vacías.
  final List<String> palabras;

  const NombreComparable._(this.clave, this.palabras);

  factory NombreComparable(String texto) {
    final clave = claveDeNombre(texto);
    return NombreComparable._(clave, _palabrasDeClave(clave));
  }

  /// Ver [parecidoEntre].
  double parecidoCon(NombreComparable otro, [PesoDePalabras? peso]) =>
      parecidoEntre(palabras, otro.palabras, peso);

  /// Nulo si no se parecen.
  NivelParecido? comparar(NombreComparable otro, [PesoDePalabras? peso]) {
    if (clave.isEmpty || otro.clave.isEmpty) return null;
    if (clave == otro.clave) return NivelParecido.igual;
    return parecidoCon(otro, peso) >= umbralParecido
        ? NivelParecido.parecido
        : null;
  }

  /// Si este nombre responde a la búsqueda [consulta].
  ///
  /// Encuentra lo mismo que antes —el texto seguido, sin mayúsculas ni
  /// tildes— y además las palabras en otro orden o con un error de tipeo:
  /// "caja arqueo" y "arqueo cajah" encuentran "Arqueo de Caja". La última
  /// palabra puede estar a medio escribir.
  bool respondeA(NombreComparable consulta) {
    if (consulta.clave.isEmpty || clave.contains(consulta.clave)) return true;
    final buscadas = consulta.palabras;
    if (buscadas.isEmpty) return false;
    for (var i = 0; i < buscadas.length; i++) {
      final q = buscadas[i];
      final aMedias = i == buscadas.length - 1 && q.length >= 2;
      if (!palabras.any(
        (p) => mismaPalabra(p, q) || (aMedias && p.startsWith(q)),
      )) {
        return false;
      }
    }
    return true;
  }
}
