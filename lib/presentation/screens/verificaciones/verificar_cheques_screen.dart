/// Verificar Cheques: la pantalla donde se asienta que el deposito de un cheque
/// se comprobo en el banco (tabla `tch_verificacionDeposito`).
///
/// Reemplaza a `tchCheque/verificarDepositos.xhtml` (tb_vista codVista 77). Es la
/// misma pantalla del legacy: la nomina de verificaciones de un dia, «Nuevo»
/// (elegir un cheque pendiente y regularizarlo), editar una verificacion y
/// «Cancelar» (anularla; no se borra). Cambios:
///
/// - **Paginacion y orden en el servidor**: la lista trae lo mas reciente primero.
/// - **Sin botones de permiso**: la vista no los tiene; el servidor exige solo el
///   rol, como el legacy.
/// - **Las reglas que el JSF hacia ocultando botones** (no verificar un cheque
///   cerrado ni dos veces) las aplica el servidor, y sus mensajes se muestran
///   completos.
/// - **Tabla en escritorio, tarjetas en movil**, sin scroll horizontal.
///
/// El correo de observaciones que el legacy tenia en esta pantalla no se migro.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/dialogo_pendientes_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/dialogo_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/filtro_verificaciones.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/lista_verificaciones.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/piezas_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/resumen_verificaciones.dart';

class VerificarChequesScreen extends ConsumerStatefulWidget {
  const VerificarChequesScreen({super.key});

  @override
  ConsumerState<VerificarChequesScreen> createState() =>
      _VerificarChequesScreenState();
}

class _VerificarChequesScreenState
    extends ConsumerState<VerificarChequesScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Pide la primera pagina (la de hoy) despues del primer dibujo: un provider
    // no se toca mientras el arbol se arma.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(grillaVerificacionesProvider.notifier).iniciar();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GrillaVerificacionesNotifier get _grilla =>
      ref.read(grillaVerificacionesProvider.notifier);

  void _recargar() {
    final e = ref.read(grillaVerificacionesProvider);
    e.iniciado ? _grilla.recargar() : _grilla.iniciar();
    ref.invalidate(chequesSinVerificarProvider);
  }

  /// «Nuevo»: el modal de cheques pendientes.
  void _nuevo() => abrirPendientesVerificacion(context);

  Future<void> _alElegirAccion(
    AccionFilaVerificacion accion,
    VerificacionFilaEntity fila,
  ) async {
    switch (accion) {
      case AccionFilaVerificacion.editar:
        await abrirVerificacionEditar(context, fila);
      case AccionFilaVerificacion.anular:
        await _anular(fila);
    }
  }

  /// «Cancelar» del legacy: pide confirmacion («¿Estas seguro de cancelar -
  /// anular?») y pasa la verificacion a Anulada. No la borra.
  Future<void> _anular(VerificacionFilaEntity fila) async {
    final c = fila.cheque;
    final ok = await confirmar(
      context,
      titulo: 'Cancelar la verificación',
      detalle:
          'La verificación del cheque ${textoODash(c.nroCheque)} '
          '(${textoODash(fila.datoBanco)}, ${textoFecha(fila.verificacion.fechaBanco)}) '
          'quedará anulada y dejará de valer.\n\n'
          'No se borra: seguirá en la lista como Anulada. ¿Estás seguro?',
      textoConfirmar: 'Sí, anular',
      textoCancelar: 'No',
      destructiva: true,
    );
    if (!ok || !mounted) return;

    final ops = ref.read(operacionesVerificacionesProvider.notifier);
    ops.limpiarError();
    final mensaje = await ops.anular(fila.codvd);
    if (!mounted) return;
    if (mensaje != null) {
      avisar(context, mensaje);
      return;
    }
    // El motivo (casi siempre una verificacion que ya no existe) se muestra
    // completo y tal cual lo redacto el servidor.
    final error = ref.read(operacionesVerificacionesProvider).error;
    avisar(context, error ?? 'No se pudo anular la verificación.', esError: true);
  }

  @override
  Widget build(BuildContext context) {
    // Se observa siempre: la grilla es autoDispose y, sin un oyente, se
    // destruiria al abrir un dialogo largo.
    final grilla = ref.watch(grillaVerificacionesProvider);
    final ocupado = ref.watch(
      operacionesVerificacionesProvider.select((s) => s.ocupado),
    );

    // Al cambiar de pagina se vuelve arriba: en el telefono el boton «siguiente»
    // esta al final de una pagina larga.
    ref.listen(grillaVerificacionesProvider.select((s) => s.pagina), (_, __) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });

    // ChequesScope: tipografia y colores de estado del modulo (ver ChequesTema).
    // Los paneles lo reciben tambien, desde abrirPanelCheque.
    return ChequesScope(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricciones) {
            final chico = Aire.de(restricciones.maxWidth) == Aire.justo;
            final margen = chico ? Esp.m : Esp.xl;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cabecera(
                  chico: chico,
                  onRecargar: _recargar,
                  onNuevo: _nuevo,
                ),
                SizedBox(
                  height: 2,
                  child:
                      (grilla.cargando || ocupado)
                          ? const LinearProgressIndicator(minHeight: 2)
                          : null,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(
                      margen,
                      Esp.l,
                      margen,
                      Esp.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AvisoSinVerificar(onVerificar: _nuevo),
                        if (ref.watch(chequesSinVerificarProvider).hasValue)
                          const SizedBox(height: Esp.m),
                        const FiltroVerificaciones(),
                        const RangoActivoVerificaciones(),
                        const SizedBox(height: Esp.l),
                        _Cuerpo(
                          estado: grilla,
                          onAccion: _alElegirAccion,
                          onReintentar: _recargar,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.chico,
    required this.onRecargar,
    required this.onNuevo,
  });

  final bool chico;
  final VoidCallback onRecargar;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Insignia con el icono del modulo en un circulo del primario-contenedor,
    // junto al titulo y el subtitulo.
    final insignia = DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: chico ? 38 : 44,
        child: Icon(
          Icons.verified_outlined,
          size: chico ? 20 : 24,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
    final titulo = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        insignia,
        SizedBox(width: chico ? Esp.s : Esp.m),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verificar cheques',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: Peso.dato,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Nómina de cheques depositados y verificados',
                style: context.apagado(),
              ),
            ],
          ),
        ),
      ],
    );

    final recargar = IconButton(
      onPressed: onRecargar,
      icon: const Icon(Icons.refresh),
      tooltip: 'Actualizar',
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        chico ? Esp.m : Esp.xl,
        Esp.l,
        chico ? Esp.s : Esp.xl,
        Esp.m,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.05),
          cs.surfaceContainerLow,
        ),
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (chico)
            Expanded(child: titulo)
          else
            Expanded(child: Align(alignment: Alignment.centerLeft, child: titulo)),
          recargar,
          const SizedBox(width: Esp.xs),
          if (chico)
            IconButton.filled(
              onPressed: onNuevo,
              icon: const Icon(Icons.add),
              tooltip: 'Nuevo: elegir un cheque para verificar',
            )
          else
            FilledButton.icon(
              onPressed: onNuevo,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo'),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUERPO: LISTADO O EL ESTADO QUE CORRESPONDA
// ═══════════════════════════════════════════════════════════════════════════

/// Alto de los mensajes de estado dentro del scroll de la pantalla: son
/// `Center(SingleChildScrollView)` y piden una altura acotada.
const double _altoMensaje = 320;

class _Cuerpo extends ConsumerWidget {
  const _Cuerpo({
    required this.estado,
    required this.onAccion,
    required this.onReintentar,
  });

  final EstadoGrillaVerificaciones estado;
  final AlElegirAccionVerificacion onAccion;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grilla = ref.read(grillaVerificacionesProvider.notifier);

    // Un fallo no es «sin verificaciones»: se dice cual fue y se ofrece reintentar.
    if (estado.error != null) {
      return SizedBox(
        height: _altoMensaje,
        child: ErrorCheques(
          titulo: 'No se pudieron cargar las verificaciones',
          texto: estado.error!,
          onReintentar: onReintentar,
        ),
      );
    }

    if (estado.resultado == null) return const _EsqueletoLista();

    if (estado.filas.isEmpty) {
      final dia = estado.fechaBanco;
      return SizedBox(
        height: _altoMensaje,
        child: Column(
          children: [
            Expanded(
              child: MensajeVacio(
                icono: dia == null ? Icons.inbox_outlined : Icons.event_busy_outlined,
                titulo:
                    dia == null
                        ? 'Todavía no hay verificaciones'
                        : 'No hay verificaciones del ${textoFecha(dia)}',
                detalle:
                    dia == null
                        ? 'Usa «Nuevo» para elegir un cheque pendiente y '
                            'verificar su depósito.'
                        : 'Cambia la fecha, o usa «Nuevo» para verificar un '
                            'cheque pendiente.',
              ),
            ),
            if (dia != null)
              TextButton.icon(
                onPressed: () => grilla.buscarPorFecha(null),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Ver todas las verificaciones'),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResumenVerificaciones(
          filas: estado.filas,
          total: estado.total,
          totalPaginas: estado.totalPaginas,
        ),
        const SizedBox(height: Esp.l),
        ListaVerificaciones(
          filas: estado.filas,
          onAccion: onAccion,
          pie: PaginadorVerificaciones(
            pagina: estado.pagina,
            totalPaginas: estado.totalPaginas,
            total: estado.total,
            singular: 'verificación',
            plural: 'verificaciones',
            onAnterior: estado.hayAnterior ? grilla.anterior : null,
            onSiguiente: estado.haySiguiente ? grilla.siguiente : null,
          ),
        ),
      ],
    );
  }
}

/// Bloques grises del alto de las filas que van a llegar: la pagina no salta
/// cuando llegan los datos. Sin animacion: es solo para la primera carga.
class _EsqueletoLista extends StatelessWidget {
  const _EsqueletoLista();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('esqueleto-verificaciones'),
      children: [
        for (var i = 0; i < 6; i++) ...[
          Opacity(
            opacity: 1 - (i * 0.12).clamp(0.0, 0.6),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Esquina.media),
              ),
            ),
          ),
          const SizedBox(height: Esp.s),
        ],
      ],
    );
  }
}
