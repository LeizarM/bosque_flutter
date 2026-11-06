/// Diálogos de escritura del módulo Horas Extras: el armazón, la escritura
/// que cierra y recarga, los selectores (día, hora, opción con buscador) y
/// el campo de texto largo (motivo u observación).
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/app_scroll_behavior.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/nombres_parecidos.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_escrituras.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';

/// Abre un diálogo de escritura que no se cierra tocando afuera. La recarga
/// que recibe [dialogo] llama a [refrescar] solo si la pantalla que lo abrió
/// sigue montada: su `ref` muere con ella.
Future<void> abrirDialogoHex(
  BuildContext context, {
  required VoidCallback refrescar,
  required Widget Function(VoidCallback refrescar) dialogo,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  void recargar() {
    if (context.mounted) refrescar();
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => dialogo(recargar),
  );
}

/// La escritura de un diálogo: una sola a la vez y, si sale bien o el dato ya
/// cambió (409), recarga la lista y cierra. Un 400 deja el diálogo abierto
/// para corregir con el mensaje del SP a la vista.
mixin EscrituraEnDialogoHex<T extends StatefulWidget> on State<T> {
  /// Para [DialogoHex]: deshabilita el diálogo mientras escribe.
  final OcupadoHex ocupado = OcupadoHex();

  /// Recarga la lista de la pantalla que abrió el diálogo.
  VoidCallback get refrescarLista;

  Future<void> escribir(
    Future<HexRespuesta> Function(bool confirmado) accion,
  ) async {
    await ejecutarHex(
      context,
      ocupado: ocupado,
      accion: accion,
      refrescar: _terminar,
    );
  }

  void _terminar() {
    refrescarLista();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    ocupado.dispose();
    super.dispose();
  }
}

/// El desplazamiento de la app, con el teclado cerrándose al arrastrar: el
/// contenido de un diálogo de escritura se desplaza con el teclado abierto.
class _CierraTecladoHex extends AppScrollBehavior {
  const _CierraTecladoHex();

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) => ScrollViewKeyboardDismissBehavior.onDrag;
}

/// Desde este ancho de ventana un [DialogoHex] con `lateral` va en dos
/// columnas. Se mide la ventana: el diálogo se dibuja sobre toda la pantalla.
const double hexAnchoDialogoDoble = 960;

/// Si [DialogoHex] pone su `lateral` a la derecha en esta ventana; si no, el
/// que lo arma lo pone bajo el formulario.
bool dialogoDobleHex(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= hexAnchoDialogoDoble;

// Medidas del diálogo de dos columnas.
const double _anchoDoble = 880;
const double _altoDobleMaximo = 560;
const double _altoDobleMinimo = 240;
const double _marcoDoble = 240;

/// Título con su [subtitulo] (el efecto), contenido que se desplaza con el
/// teclado abierto, «Cancelar» y la acción, apagada si [aceptarHabilitado] es
/// `false`. Mientras escribe nada se toca y el «atrás» no lo cierra.
class DialogoHex extends StatelessWidget {
  const DialogoHex({
    super.key,
    required this.titulo,
    required this.icono,
    required this.ocupado,
    required this.contenido,
    required this.accion,
    required this.alAceptar,
    this.destructiva = false,
    this.subtitulo,
    this.aceptarHabilitado = true,
    this.lateral,
  });

  final String titulo;
  final IconData icono;
  final OcupadoHex ocupado;

  /// Qué pasa al aceptar, bajo el título; siempre a la vista.
  final String? subtitulo;
  final bool aceptarHabilitado;

  /// El contenido según haya una escritura en curso (para deshabilitarlo).
  final List<Widget> Function(bool enCurso) contenido;
  final String accion;
  final VoidCallback alAceptar;
  final bool destructiva;

  /// Una columna derecha con su propio desplazamiento (una vista previa),
  /// solo si [dialogoDobleHex]; recibe su alto acotado.
  final Widget Function(bool enCurso)? lateral;

  /// Formulario a la izquierda y [lateral] a la derecha, con un alto fijo
  /// para que cada columna se desplace sola.
  Widget _dosColumnas(BuildContext context, bool enCurso, Widget derecha) {
    final alto = (MediaQuery.sizeOf(context).height - _marcoDoble).clamp(
      _altoDobleMinimo,
      _altoDobleMaximo,
    );
    return SizedBox(
      width: _anchoDoble,
      height: alto,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: Esp.s, right: Esp.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: contenido(enCurso),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: Esp.l),
              child: derecha,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final efecto = subtitulo?.trim() ?? '';
    final derecha = dialogoDobleHex(context) ? lateral : null;
    return ValueListenableBuilder<bool>(
      valueListenable: ocupado,
      builder:
          (context, enCurso, _) => PopScope(
            canPop: !enCurso,
            child: ScrollConfiguration(
              behavior: const _CierraTecladoHex(),
              child: AlertDialog(
                scrollable: derecha == null,
                icon: Icon(icono, color: destructiva ? cs.error : cs.primary),
                title:
                    efecto.isEmpty
                        ? Text(titulo)
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(titulo),
                            const SizedBox(height: Esp.xs),
                            Text(
                              efecto,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                content:
                    derecha != null
                        ? _dosColumnas(context, enCurso, derecha(enCurso))
                        : SizedBox(
                          width: 440,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: contenido(enCurso),
                          ),
                        ),
                actions: [
                  TextButton(
                    onPressed:
                        enCurso ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  BotonAccion(
                    etiqueta: accion,
                    ocupado: enCurso,
                    destructiva: destructiva,
                    onPressed: aceptarHabilitado ? alAceptar : null,
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// Tope de letra dentro del selector de hora de Flutter: con 1,5 y el teclado
/// abierto su modo de texto desborda 16 px; 1,4 es lo máximo que entra.
const double _escalaMaximaReloj = 1.4;

/// El selector de hora del módulo. Siempre en 24 h: si no, en la web el «01»
/// escrito con una hora inicial de la tarde se lee como 13:00.
Future<TimeOfDay?> pedirHoraHex(
  BuildContext context, {
  required TimeOfDay inicial,
  required String ayuda,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showTimePicker(
    context: context,
    initialTime: inicial,
    helpText: ayuda,
    confirmText: 'Aceptar',
    cancelText: 'Cancelar',
    builder: (context, hijo) {
      final mq = MediaQuery.of(context);
      return MediaQuery(
        data: mq.copyWith(
          alwaysUse24HourFormat: true,
          textScaler: mq.textScaler.clamp(maxScaleFactor: _escalaMaximaReloj),
        ),
        child: hijo!,
      );
    },
  );
}

/// El calendario del módulo. Los límites son solo del calendario (por defecto
/// ±10 años) y [inicial] se acota a ellos para no romper el selector; qué
/// fechas valen lo decide el SP.
Future<DateTime?> pedirDiaHex(
  BuildContext context, {
  required DateTime? inicial,
  required String ayuda,
  DateTime? primero,
  DateTime? ultimo,
}) {
  // El campo que se estaba escribiendo no vuelve a abrir el teclado al cerrar.
  FocusManager.instance.primaryFocus?.unfocus();
  final hoy = DateUtils.dateOnly(DateTime.now());
  final desde = primero ?? DateTime(hoy.year - 10);
  final hasta = ultimo ?? DateTime(hoy.year + 10, 12, 31);
  final dia = inicial ?? hoy;
  return showDatePicker(
    context: context,
    initialDate:
        dia.isBefore(desde)
            ? desde
            : dia.isAfter(hasta)
            ? hasta
            : dia,
    firstDate: desde,
    lastDate: hasta,
    helpText: ayuda,
    confirmText: 'Aceptar',
    cancelText: 'Cancelar',
  );
}

/// Un campo que abre un selector (día, hora u opción): la etiqueta, el valor
/// elegido o [pista], y la [ayuda] debajo. Sin [alTocar] queda deshabilitado.
/// Con [alQuitar] y un valor, el icono pasa a ser el botón que lo quita.
class CampoSelectorHex extends StatelessWidget {
  const CampoSelectorHex({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.alTocar,
    this.pista = 'Elige',
    this.ayuda,
    this.alQuitar,
    this.textoQuitar = 'Quitar',
  });

  final String etiqueta;
  final String? valor;
  final IconData icono;
  final VoidCallback? alTocar;
  final String pista;
  final String? ayuda;
  final VoidCallback? alQuitar;
  final String textoQuitar;

  @override
  Widget build(BuildContext context) {
    final texto = valor;
    final quitar = alQuitar;
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          helperMaxLines: 3,
          enabled: alTocar != null,
          border: const OutlineInputBorder(),
          suffixIcon:
              texto == null || quitar == null
                  ? Icon(icono, size: 18)
                  : IconButton(
                    tooltip: textoQuitar,
                    visualDensity: VisualDensity.standard,
                    onPressed: quitar,
                    icon: const Icon(Icons.close, size: 18),
                  ),
        ),
        child:
            texto == null
                ? Text(pista, style: context.apagado())
                : Text(texto, style: context.numero(fuerte: true)),
      ),
    );
  }
}

/// Una opción de [pedirOpcionHex]: el valor, lo que se lee y una línea de
/// apoyo (el cargo y la sucursal de una persona, por ejemplo).
typedef OpcionHex<T> = ({T valor, String texto, String? apoyo});

/// Buscador de una lista larga (personas, sucursales) en su propio diálogo:
/// se escribe, se filtra y se toca. Sin menú flotante: con el teclado abierto
/// el diálogo se achica y la lista se desplaza. Nulo si se cancela.
Future<T?> pedirOpcionHex<T extends Object>(
  BuildContext context, {
  required String titulo,
  required List<OpcionHex<T>> opciones,
  T? actual,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<T>(
    context: context,
    builder:
        (_) =>
            _BuscadorHex<T>(titulo: titulo, opciones: opciones, actual: actual),
  );
}

class _BuscadorHex<T extends Object> extends StatefulWidget {
  const _BuscadorHex({
    required this.titulo,
    required this.opciones,
    required this.actual,
  });

  final String titulo;
  final List<OpcionHex<T>> opciones;
  final T? actual;

  @override
  State<_BuscadorHex<T>> createState() => _BuscadorHexState<T>();
}

class _BuscadorHexState<T extends Object> extends State<_BuscadorHex<T>> {
  static final RegExp _espacios = RegExp(r'\s+');

  final TextEditingController _buscar = TextEditingController();
  final ScrollController _lista = ScrollController();

  /// Texto y apoyo de cada opción sin mayúsculas ni tildes, una sola vez.
  late final List<String> _claves = [
    for (final o in widget.opciones) sinTildes('${o.texto}\n${o.apoyo ?? ''}'),
  ];

  @override
  void dispose() {
    _buscar.dispose();
    _lista.dispose();
    super.dispose();
  }

  /// Las opciones que tienen cada palabra escrita, en cualquier orden, en su
  /// texto o su apoyo; sin importar mayúsculas ni tildes.
  List<OpcionHex<T>> _visibles(String buscado) {
    final palabras = [
      for (final p in sinTildes(buscado).split(_espacios))
        if (p.isNotEmpty) p,
    ];
    if (palabras.isEmpty) return widget.opciones;
    return [
      for (var i = 0; i < widget.opciones.length; i++)
        if (palabras.every(_claves[i].contains)) widget.opciones[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles(_buscar.text);
    void elegir(T v) => Navigator.of(context).pop(v);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.xl, Esp.s),
              child: Text(
                widget.titulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: TextField(
                controller: _buscar,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Escribe para buscar…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
                // Con una sola coincidencia, «Buscar» del teclado la elige.
                onSubmitted: (_) {
                  if (visibles.length == 1) elegir(visibles.single.valor);
                },
              ),
            ),
            const SizedBox(height: Esp.xs),
            Expanded(
              child:
                  visibles.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Esp.l),
                          child: Text(
                            'Nada coincide con «${_buscar.text.trim()}».',
                            textAlign: TextAlign.center,
                            style: context.apagado(),
                          ),
                        ),
                      )
                      : Scrollbar(
                        controller: _lista,
                        child: ListView.builder(
                          controller: _lista,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: visibles.length,
                          itemBuilder: (_, i) {
                            final o = visibles[i];
                            return ListTile(
                              title: Text(oGuionHex(o.texto)),
                              subtitle:
                                  textoUsableHex(o.apoyo) == null
                                      ? null
                                      : Text(o.apoyo!),
                              selected: o.valor == widget.actual,
                              onTap: () => elegir(o.valor),
                            );
                          },
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.s, 0, Esp.s, Esp.s),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un campo de texto largo de un diálogo (motivo u observación). La [ayuda]
/// va debajo: no se corta como una etiqueta larga con letra grande.
class TextoLargoHex extends StatelessWidget {
  const TextoLargoHex({
    super.key,
    required this.control,
    required this.etiqueta,
    required this.habilitado,
    this.pista,
    this.ayuda,
    this.autofocus = false,
    this.largoMaximo,
  });

  final TextEditingController control;
  final String etiqueta;
  final bool habilitado;
  final String? pista;
  final String? ayuda;

  /// Solo si es lo único que se puede hacer en el diálogo.
  final bool autofocus;

  /// Tope de caracteres con su contador; nulo, sin tope en la app.
  final int? largoMaximo;

  @override
  Widget build(BuildContext context) => TextField(
    controller: control,
    enabled: habilitado,
    autofocus: autofocus,
    maxLength: largoMaximo,
    minLines: 2,
    maxLines: 4,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: etiqueta,
      hintText: pista,
      helperText: ayuda,
      alignLabelWithHint: true,
      border: const OutlineInputBorder(),
    ),
  );
}
