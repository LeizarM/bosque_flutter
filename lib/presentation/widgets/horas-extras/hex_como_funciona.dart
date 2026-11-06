/// «¿Cómo funciona?» de Mis horas: las cuatro reglas que un operario necesita
/// saber, en corto; abierta la primera vez y después plegada. La preferencia
/// se guarda en el teléfono solo por comodidad: no decide nada.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_haptica.dart';

/// Clave local de la preferencia: `true` = plegada.
const String _clavePlegada = 'hex_como_funciona_plegada';

/// Una regla del módulo con su ícono y su color.
typedef _PuntoHex = ({IconData icono, TonoHex tono, String texto});

const List<_PuntoHex> _puntos = [
  (
    icono: Icons.event_available_outlined,
    tono: TonoHex.exito,
    texto:
        'Solo cuentan las jornadas que tu encargado te asignó, con su motivo.',
  ),
  (
    icono: Icons.fingerprint,
    tono: TonoHex.primario,
    texto: 'El biométrico crea tus reportes solo.',
  ),
  (
    icono: Icons.location_on_outlined,
    tono: TonoHex.terciario,
    texto: 'Usa la app solo si no alcanzaste a marcar; necesita tu ubicación.',
  ),
  (
    icono: Icons.schedule,
    tono: TonoHex.pendiente,
    texto: 'Tu horario del biométrico define desde qué hora es extra.',
  ),
];

/// Tarjeta plegable con las reglas. La pantalla la abre o la pliega desde el
/// botón «?» del encabezado con una `GlobalKey<ComoFuncionaHexState>`.
class ComoFuncionaHex extends StatefulWidget {
  const ComoFuncionaHex({super.key});

  @override
  State<ComoFuncionaHex> createState() => ComoFuncionaHexState();
}

class ComoFuncionaHexState extends State<ComoFuncionaHex> {
  /// Nulo hasta leer la preferencia: mientras tanto se dibuja plegada.
  bool? _abierta;

  bool get abierta => _abierta ?? false;

  @override
  void initState() {
    super.initState();
    _leer();
  }

  /// Sin dato es la primera vez: se abre y se deja plegada para la próxima.
  /// Si el almacenamiento falla, cuenta como la primera vez.
  Future<void> _leer() async {
    bool? plegada;
    try {
      final p = await SharedPreferences.getInstance();
      plegada = p.getBool(_clavePlegada);
    } catch (_) {
      plegada = null;
    }
    if (!mounted) return;
    setState(() => _abierta = plegada != true);
    if (plegada == null) _guardar(plegada: true);
  }

  Future<void> _guardar({required bool plegada}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_clavePlegada, plegada);
    } catch (_) {
      // Sin almacenamiento se recuerda solo mientras dura la pantalla.
    }
  }

  /// Abre o pliega; si al abrir su borde de arriba quedó fuera de la vista
  /// (la página bajó), la sube hasta ahí.
  void alternar() {
    final abrir = !abierta;
    setState(() => _abierta = abrir);
    _guardar(plegada: !abrir);
    if (!abrir) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: abierta ? 'Plegar ¿Cómo funciona?' : 'Abrir ¿Cómo funciona?',
            excludeSemantics: true,
            child: InkWell(
              onTap: () {
                HapticaHex.toque();
                alternar();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Esp.m,
                    vertical: Esp.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: cs.primary,
                      ),
                      const SizedBox(width: Esp.m),
                      Expanded(
                        child: Text(
                          '¿Cómo funciona?',
                          style: context.tituloSeccion(),
                        ),
                      ),
                      Icon(
                        abierta ? Icons.expand_less : Icons.expand_more,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child:
                abierta
                    ? const Padding(
                      padding: EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m),
                      child: _PuntosHex(),
                    )
                    : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Las reglas una debajo de otra; desde [hexAnchoTabla], de a dos.
class _PuntosHex extends StatelessWidget {
  const _PuntosHex();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final dos = c.maxWidth >= hexAnchoTabla;
      final ancho = dos ? (c.maxWidth - Esp.xl) / 2 : c.maxWidth;
      return Wrap(
        spacing: Esp.xl,
        runSpacing: Esp.s,
        children: [
          for (final p in _puntos)
            SizedBox(width: ancho, child: _PuntoFilaHex(p)),
        ],
      );
    },
  );
}

class _PuntoFilaHex extends StatelessWidget {
  const _PuntoFilaHex(this.punto);

  final _PuntoHex punto;

  @override
  Widget build(BuildContext context) {
    final par = coloresTonoHex(context, punto.tono);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: par.fondo, shape: BoxShape.circle),
          child: Icon(punto.icono, size: 16, color: par.letra),
        ),
        const SizedBox(width: Esp.s),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: Esp.xs),
            child: Text(
              punto.texto,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
