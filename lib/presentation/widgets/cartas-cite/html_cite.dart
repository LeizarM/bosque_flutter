import 'package:flutter/material.dart';

/// Render y utilidades del HTML del cuerpo de un documento CITE.
///
/// ## Por qué HTML y por qué éste
///
/// El módulo JSF guardaba el cuerpo con el editor Quill de PrimeFaces, así que
/// las ~780 cartas que ya están en `tcr_documento.cuerpo` son HTML:
/// `<p>`, `<strong>`, `<em>`, `<a>`, `&nbsp;`. Los reportes Jasper las imprimen
/// con `markup="html"`, que soporta un subconjunto chico y fijo de etiquetas.
///
/// Cambiar de formato obligaría a migrar esos documentos y a tocar los seis
/// reportes. Se mantiene HTML, y este archivo es lo que hace falta para
/// mostrarlo y editarlo.
///
/// ## Por qué un parser propio y no un paquete
///
/// El proyecto no tiene `flutter_html` ni `flutter_quill`, y meterlos por esto
/// serían dos dependencias nuevas —con su resolución de versiones y su riesgo
/// de romper el build— para renderizar seis etiquetas. Lo que Jasper imprime es
/// exactamente lo que este parser entiende; agregar soporte para más HTML del
/// que el reporte sabe imprimir sería mentirle a quien redacta.

/// Las etiquetas que sobreviven al viaje hasta el PDF.
const _etiquetasNegrita = {'b', 'strong'};
const _etiquetasCursiva = {'i', 'em'};
const _etiquetasSubrayado = {'u', 'ins'};
const _etiquetasTachado = {'s', 'strike', 'del'};
const _etiquetasBloque = {'p', 'div', 'br', 'li', 'ul', 'ol', 'h1', 'h2', 'h3'};

/// Convierte el HTML del cuerpo en spans de texto.
///
/// Lo que no entiende lo ignora en lugar de mostrarlo crudo: un `<table>`
/// pegado desde Word aparecería como texto plano, que es feo pero legible —y
/// es justo lo que va a pasar en el PDF, así que la vista previa no miente.
List<InlineSpan> spansDeHtml(String html, TextStyle base, Color colorEnlace) {
  final spans = <InlineSpan>[];
  final buffer = StringBuffer();

  var negrita = 0, cursiva = 0, subrayado = 0, tachado = 0, enlace = 0;

  void volcar() {
    if (buffer.isEmpty) return;
    spans.add(TextSpan(
      text: buffer.toString(),
      style: base.copyWith(
        fontWeight: negrita > 0 ? FontWeight.w700 : null,
        fontStyle: cursiva > 0 ? FontStyle.italic : null,
        decoration: TextDecoration.combine([
          if (subrayado > 0 || enlace > 0) TextDecoration.underline,
          if (tachado > 0) TextDecoration.lineThrough,
        ]),
        color: enlace > 0 ? colorEnlace : null,
      ),
    ));
    buffer.clear();
  }

  /// Un salto sólo si no venimos de uno: `</p><p>` son dos cierres de bloque
  /// seguidos y no tienen que abrir dos renglones en blanco.
  void saltoDeBloque() {
    final texto = buffer.toString();
    if (texto.isNotEmpty && !texto.endsWith('\n')) {
      buffer.write('\n');
    } else if (texto.isEmpty && spans.isNotEmpty) {
      final ultimo = spans.last;
      if (ultimo is TextSpan && !(ultimo.text ?? '').endsWith('\n')) {
        buffer.write('\n');
      }
    }
  }

  var i = 0;
  while (i < html.length) {
    final c = html[i];

    if (c == '<') {
      final fin = html.indexOf('>', i);
      if (fin == -1) {
        // '<' suelto: es texto, no una etiqueta rota.
        buffer.write(c);
        i++;
        continue;
      }

      final crudo = html.substring(i + 1, fin).trim();
      i = fin + 1;
      if (crudo.isEmpty) continue;

      final cierre = crudo.startsWith('/');
      final cuerpo = cierre ? crudo.substring(1) : crudo;
      final nombre = cuerpo.split(RegExp(r'[\s/>]')).first.toLowerCase();

      if (_etiquetasNegrita.contains(nombre)) {
        volcar();
        negrita += cierre ? -1 : 1;
        if (negrita < 0) negrita = 0;
      } else if (_etiquetasCursiva.contains(nombre)) {
        volcar();
        cursiva += cierre ? -1 : 1;
        if (cursiva < 0) cursiva = 0;
      } else if (_etiquetasSubrayado.contains(nombre)) {
        volcar();
        subrayado += cierre ? -1 : 1;
        if (subrayado < 0) subrayado = 0;
      } else if (_etiquetasTachado.contains(nombre)) {
        volcar();
        tachado += cierre ? -1 : 1;
        if (tachado < 0) tachado = 0;
      } else if (nombre == 'a') {
        volcar();
        enlace += cierre ? -1 : 1;
        if (enlace < 0) enlace = 0;
      } else if (_etiquetasBloque.contains(nombre)) {
        volcar();
        if (nombre == 'br') {
          buffer.write('\n');
        } else if (nombre == 'li' && !cierre) {
          saltoDeBloque();
          buffer.write('•  ');
        } else if (cierre || nombre == 'p' || nombre == 'div') {
          saltoDeBloque();
        }
      }
      // Cualquier otra etiqueta (span, font, table…) se descarta.
      continue;
    }

    if (c == '&') {
      final fin = html.indexOf(';', i);
      if (fin != -1 && fin - i <= 8) {
        buffer.write(_entidad(html.substring(i + 1, fin)));
        i = fin + 1;
        continue;
      }
    }

    buffer.write(c);
    i++;
  }

  volcar();
  return spans.isEmpty ? [TextSpan(text: '', style: base)] : spans;
}

String _entidad(String nombre) {
  switch (nombre.toLowerCase()) {
    case 'nbsp':
      return ' ';
    case 'amp':
      return '&';
    case 'lt':
      return '<';
    case 'gt':
      return '>';
    case 'quot':
      return '"';
    case 'apos':
    case '#39':
      return "'";
    default:
      if (nombre.startsWith('#')) {
        final code = int.tryParse(nombre.substring(1));
        if (code != null) return String.fromCharCode(code);
      }
      return '&$nombre;';
  }
}

/// Texto plano del HTML, para las columnas del listado y los buscadores.
String textoPlanoDeHtml(String html) {
  final spans = spansDeHtml(html, const TextStyle(), Colors.black);
  final b = StringBuffer();
  for (final s in spans) {
    if (s is TextSpan) b.write(s.text ?? '');
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Escapa texto plano para poder meterlo en el HTML sin romperlo.
String escaparHtml(String texto) => texto
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Envuelve en `<p>` un cuerpo que el usuario escribió sin tocar la barra de
/// formato.
///
/// Sin esto, quien escribe dos párrafos separados por un enter ve el PDF con
/// todo pegado en un solo bloque: Jasper con `markup="html"` ignora los saltos
/// de línea reales, sólo entiende `<p>` y `<br>`. Es el error más fácil de
/// cometer y el que sólo se descubre cuando la carta ya está impresa.
String normalizarCuerpo(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return '';

  // Ya tiene marcado de bloque: se respeta tal cual.
  if (RegExp(r'<\s*(p|div|br|ul|ol|li)\b', caseSensitive: false).hasMatch(t)) {
    return t;
  }

  // Texto suelto (puede traer <strong> y demás en línea): un <p> por párrafo.
  final parrafos = t
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .map((p) => '<p>${p.replaceAll('\n', '<br>')}</p>');

  return parrafos.join();
}

/// Muestra el HTML del cuerpo tal como lo va a imprimir el reporte.
class VistaHtmlCite extends StatelessWidget {
  final String html;
  final TextStyle? estilo;
  final TextAlign alineacion;

  const VistaHtmlCite({
    super.key,
    required this.html,
    this.estilo,
    this.alineacion = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = estilo ??
        Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.45);

    if (html.trim().isEmpty) {
      return Text(
        'El documento todavía no tiene contenido.',
        style: base.copyWith(
          color: Theme.of(context).hintColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spansDeHtml(html, base, cs.primary)),
      textAlign: alineacion,
    );
  }
}
