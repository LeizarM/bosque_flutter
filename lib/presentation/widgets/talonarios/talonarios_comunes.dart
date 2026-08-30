import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';

/// Las piezas que comparten las tres pantallas de talonarios.
///
/// Sin este archivo, el badge de estado, la fila y el campo de fecha se
/// escriben tres veces y se arreglan una sola.

// ═══════════════════════════════════════════════════════════════════════════
// EL ESTADO DE UN TALONARIO
// ═══════════════════════════════════════════════════════════════════════════

/// El par fondo/letra del estado, construido desde el tema.
///
/// **No es `Colors.orange`.** El usuario elige entre nueve semillas y hay modo
/// oscuro: un color fijo se ve de otra app en ocho de ellas, y en oscuro pide
/// letra negra que nadie le pone. [colorDeCatalogo] arma el par midiendo el
/// contraste, que es exactamente el problema que hay que resolver acá.
ColorDeEstado colorDeEstadoTalonario(ColorScheme cs, int codEstado) =>
    // El índice del catálogo es 0-based; los estados van de 1 a 4.
    colorDeCatalogo(cs, (codEstado - 1).clamp(0, 3));

/// El icono de cada estado, para que el color no sea la única señal.
///
/// Quien no distingue los colores —o mira la pantalla al sol— tiene que poder
/// leer el estado igual. El texto ya está; el icono ayuda a barrer la lista.
IconData iconoDeEstadoTalonario(int codEstado) => switch (codEstado) {
  2 => Icons.assignment_ind_outlined,
  3 => Icons.assignment_return_outlined,
  4 => Icons.lock_outline,
  _ => Icons.inventory_2_outlined,
};

/// La pastilla de estado de un talonario.
class EstadoTalonario extends StatelessWidget {
  const EstadoTalonario({
    super.key,
    required this.codEstado,
    required this.texto,
    this.conIcono = true,
  });

  final int codEstado;
  final String texto;
  final bool conIcono;

  @override
  Widget build(BuildContext context) {
    final c = colorDeEstadoTalonario(context.cs, codEstado);
    return Semantics(
      label: 'Estado: $texto',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Esp.s,
          vertical: Esp.xs - 1,
        ),
        decoration: BoxDecoration(
          color: c.fondo,
          borderRadius: BorderRadius.circular(Esquina.pastilla),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conIcono) ...[
              Icon(iconoDeEstadoTalonario(codEstado), size: 13, color: c.texto),
              const SizedBox(width: Esp.xs),
            ],
            Text(
              texto,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: c.texto,
                fontWeight: Peso.titulo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA FILA DE UN TALONARIO
// ═══════════════════════════════════════════════════════════════════════════

/// Un talonario como tarjeta. Es la forma para pantallas angostas.
class TarjetaTalonario extends StatelessWidget {
  const TarjetaTalonario({
    super.key,
    required this.talonario,
    this.onTap,
    this.acciones,
  });

  final TalonarioEntity talonario;
  final VoidCallback? onTap;
  final Widget? acciones;

  @override
  Widget build(BuildContext context) {
    final t = talonario;
    return Material(
      // `Card` trae elevacion, y una sombra por fila es caro de rasterizar en
      // web: con 480 filas el scroll se traba. Superficie plana con borde: el
      // estilo Material 3 y una fraccion del costo por frame.
      color: context.cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Esquina.media),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.l,
            vertical: Esp.m,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.nroTalonario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: Peso.dato,
                                  fontFeatures: cifrasTabulares,
                                ),
                          ),
                        ),
                        const SizedBox(width: Esp.s),
                        // Flexible y no un tamaño fijo: estadoActual es un
                        // String libre del backend, no un enum. Un estado más
                        // largo no puede empujar al número fuera de la fila.
                        Flexible(
                          child: EstadoTalonario(
                            codEstado: t.codEstadoActual,
                            texto: t.estadoActual,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      '${t.datoTipo}  ·  folios ${t.numeracionInicial}–${t.numeracionFinal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.apagado(),
                    ),
                    if (t.datoDestinatario.isNotEmpty) ...[
                      const SizedBox(height: Esp.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 13,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: Esp.xs),
                          Expanded(
                            child: Text(
                              t.datoDestinatario,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.apagado(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (acciones != null) acciones!,
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA TABLA
// ═══════════════════════════════════════════════════════════════════════════

/// Anchos de las columnas. Fijos para que cabecera y filas queden alineadas
/// sin medir nada.
abstract final class _Col {
  static const double nro = 120;
  static const double folios = 150;
  static const double estado = 130;
  static const double acciones = 52;
}

/// La cabecera de la tabla. Va **fuera** del scroll, para que no se vaya.
class CabeceraTablaTalonarios extends StatelessWidget {
  const CabeceraTablaTalonarios({super.key});

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: context.cs.onSurfaceVariant,
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Esp.l,
        vertical: Esp.s,
      ),
      color: context.cs.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: _Col.nro, child: Text('NÚMERO', style: estilo)),
          const SizedBox(width: Esp.m),
          Expanded(flex: 3, child: Text('TIPO', style: estilo)),
          const SizedBox(width: Esp.m),
          SizedBox(width: _Col.folios, child: Text('FOLIOS', style: estilo)),
          const SizedBox(width: Esp.m),
          SizedBox(width: _Col.estado, child: Text('ESTADO', style: estilo)),
          const SizedBox(width: Esp.m),
          Expanded(flex: 3, child: Text('EN PODER DE', style: estilo)),
          const SizedBox(width: _Col.acciones),
        ],
      ),
    );
  }
}

/// Una fila de la tabla.
///
/// Deliberadamente plana: un `Row` de `Text`. Sin `Card`, sin sombra y sin
/// ripple, que es lo que hace que 480 filas scrolleen sin trabarse.
class FilaTablaTalonario extends StatelessWidget {
  const FilaTablaTalonario({
    super.key,
    required this.talonario,
    required this.par,
    this.onTap,
    this.acciones,
  });

  final TalonarioEntity talonario;

  /// Para el rayado. Sin él, en una tabla ancha el ojo pierde el renglón.
  final bool par;

  final VoidCallback? onTap;
  final Widget? acciones;

  @override
  Widget build(BuildContext context) {
    final t = talonario;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: par ? null : context.cs.surfaceContainerLow.withValues(alpha: 0.5),
        // Solo horizontal: el alto lo fija el `itemExtent` de la lista, y el
        // `Row` centra. Con padding vertical, el `PopupMenuButton` de acciones
        // —que mide 48 por el mínimo táctil— más 24 de padding se pasaba del
        // alto de la fila y desbordaba.
        padding: const EdgeInsets.symmetric(horizontal: Esp.l),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            SizedBox(
              width: _Col.nro,
              child: Text(
                t.nroTalonario,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ),
            const SizedBox(width: Esp.m),
            Expanded(
              flex: 3,
              child: Text(
                t.datoTipo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Esp.m),
            SizedBox(
              width: _Col.folios,
              child: Text(
                '${t.numeracionInicial}–${t.numeracionFinal}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.numero(),
              ),
            ),
            const SizedBox(width: Esp.m),
            SizedBox(
              width: _Col.estado,
              child: Align(
                alignment: Alignment.centerLeft,
                child: EstadoTalonario(
                  codEstado: t.codEstadoActual,
                  texto: t.estadoActual,
                ),
              ),
            ),
            const SizedBox(width: Esp.m),
            Expanded(
              flex: 3,
              child: Text(
                t.datoDestinatario.isEmpty ? '—' : t.datoDestinatario,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    t.datoDestinatario.isEmpty
                        ? context.apagado()
                        : null,
              ),
            ),
            SizedBox(
              width: _Col.acciones,
              child: Align(
                alignment: Alignment.centerRight,
                child: acciones ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPOS
// ═══════════════════════════════════════════════════════════════════════════

/// Un campo de fecha que se escribe a mano **o** se elige del calendario.
///
/// El `ListTile` que había antes no se leía como algo editable: no tenía borde
/// ni etiqueta flotante, así que en medio de un formulario parecía un dato fijo.
/// Después fue un `InputDecorator` que solo se podía tocar, y para llegar a una
/// fecha de hace años había que retroceder de a un mes. Ahora se tipea, con la
/// misma máscara dd/mm/aaaa que el diálogo de rango.
class CampoFecha extends StatefulWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onElegir,
    this.ayuda,
    this.habilitado = true,
  });

  final String etiqueta;
  final DateTime valor;
  final ValueChanged<DateTime> onElegir;
  final String? ayuda;
  final bool habilitado;

  @override
  State<CampoFecha> createState() => _CampoFechaState();
}

class _CampoFechaState extends State<CampoFecha> {
  static final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  static final DateTime _minima = DateTime(2019);

  late final TextEditingController _c = TextEditingController(
    text: _fmt.format(widget.valor),
  );
  String? _error;

  DateTime get _maxima => DateTime.now().add(const Duration(days: 1));

  @override
  void didUpdateWidget(CampoFecha viejo) {
    super.didUpdateWidget(viejo);
    // Solo se pisa el texto si la fecha cambió desde afuera; si no, el cursor
    // saltaría al final en cada tecla.
    if (widget.valor != viejo.valor) {
      final nuevo = _fmt.format(widget.valor);
      if (_c.text != nuevo) _c.text = nuevo;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _abrirCalendario() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: widget.valor,
      firstDate: _minima,
      lastDate: _maxima,
      helpText: widget.etiqueta,
    );
    if (sel == null) return;
    setState(() => _error = null);
    widget.onElegir(sel);
  }

  void _alEscribir(String texto) {
    if (texto.length < 10) {
      // A medio escribir: se bloquea sin acusar a nadie todavía.
      setState(() => _error = '');
      return;
    }
    final DateTime f;
    try {
      // parseStrict: el laxo acepta 32/13/2024 y lo corre de mes en silencio.
      f = _fmt.parseStrict(texto);
    } on FormatException {
      setState(() => _error = 'Fecha inexistente');
      return;
    }
    if (f.isBefore(_minima) || f.isAfter(_maxima)) {
      setState(() => _error = 'Fuera del rango permitido');
      return;
    }
    setState(() => _error = null);
    widget.onElegir(f);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _c,
    enabled: widget.habilitado,
    keyboardType: TextInputType.datetime,
    style: const TextStyle(fontFeatures: cifrasTabulares),
    inputFormatters: [MascaraFecha()],
    decoration: InputDecoration(
      labelText: widget.etiqueta,
      hintText: 'dd/mm/aaaa',
      helperText: widget.ayuda,
      errorText: (_error != null && _error!.isEmpty) ? ' ' : _error,
      suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_today, size: 18),
        tooltip: 'Elegir del calendario',
        onPressed: widget.habilitado ? _abrirCalendario : null,
      ),
    ),
    onChanged: _alEscribir,
  );
}

/// Apellidos y nombre, sin los espacios de más que deja la base.
String nombreEmpleado(String apPaterno, String apMaterno, String nombres) =>
    '$apPaterno $apMaterno $nombres'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
