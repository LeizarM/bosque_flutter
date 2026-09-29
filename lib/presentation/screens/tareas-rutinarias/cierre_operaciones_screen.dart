// Destino final: lib/presentation/screens/tareas-rutinarias/cierre_operaciones_screen.dart
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/paneles_cierre.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La revisión de Cierre de Operaciones: reemplaza el diálogo dlgRevArqueo del
/// sistema anterior.
///
/// Marcelo (2026-09-11): "Cierre de Operaciones es como una revisión de varias
/// tareas para verificar que sí hicieron su trabajo los demás empleados:
/// verificar monto entre sistemas, cheques, las tareas rutinarias automáticas,
/// caja fuerte, arqueo de caja". Y, sacando el módulo del menú: "será la tarea
/// 'Verificar Cierre de Operaciones' donde está esta pantalla; esa tarea estará
/// asignada a un cargo donde verificar cada sección si se cumplió, y tiene que
/// revisar TODO; una vez que revise todo, recién se completa".
///
/// De ahí las dos reglas de la pantalla:
///
/// - **La tarea es el permiso.** Se entra con la ocurrencia del día desde "Mis
///   tareas rutinarias" y eso alcanza para ver y marcar las cinco secciones; el
///   servidor comprueba lo mismo. Ya no depende de los botones de la vista 78.
/// - **No se cierra hasta revisar todo.** Cada sección se revisa marcando sus
///   filas o con su interruptor "Revisado", y el botón de cierre recién se
///   habilita cuando están las cinco (y mirando el día de la tarea).
class CierreOperacionesScreen extends ConsumerStatefulWidget {
  final int idBitTarea;
  final String nombreTarea;

  /// Con qué tarea se entró: decide cómo se cierra.
  final ModoCierre modo;

  /// El día de la ocurrencia. Null = hoy.
  final DateTime? fecha;

  const CierreOperacionesScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
    this.modo = ModoCierre.cierre,
    this.fecha,
  });

  @override
  ConsumerState<CierreOperacionesScreen> createState() =>
      _CierreOperacionesScreenState();
}

class _CierreOperacionesScreenState
    extends ConsumerState<CierreOperacionesScreen> {
  /// Para llevar la vista a la sección que se toca en el resumen de abajo.
  final Map<PanelCierre, GlobalKey> _llaves = {
    for (final p in PanelCierre.values) p: GlobalKey(),
  };

  void _irAlPanel(PanelCierre panel) {
    final contexto = _llaves[panel]?.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apertura = AperturaCierre(
      idBitTarea: widget.idBitTarea,
      modo: widget.modo,
      fechaOcurrencia: widget.fecha ?? DateTime.now(),
    );
    final prov = cierreOperacionesProvider(apertura);
    final state = ref.watch(prov);
    final notifier = ref.read(prov.notifier);

    ref.listen(prov, (previo, actual) {
      if (actual.cerradas != null && previo?.cerradas == null) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, _mensajeDeCierre(actual));
        cerrarRuta(context, true);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
      if (actual.aviso != null && actual.aviso != previo?.aviso) {
        mostrarAviso(context, actual.aviso!);
      }
    });

    return TareasScope(
      child: LayoutBuilder(
        builder: (context, cajon) {
          final chico = Aire.de(cajon.maxWidth).esChico;
          return Scaffold(
            appBar: AppBarTareas(
              titulo: widget.nombreTarea,
              subtitulo: _subtitulo(state),
              insignia: InsigniaTarea.deTipo(context, widget.modo.idATR),
              acciones: [
                // El calendario + "Desplegar" del sistema anterior.
                if (chico)
                  IconButton(
                    tooltip: 'Cambiar el día: ${_fechaCorta(state.fecha)}',
                    icon: const Icon(Icons.event_outlined),
                    onPressed: () => _elegirFecha(state, notifier),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _elegirFecha(state, notifier),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_fechaCorta(state.fecha)),
                  ),
                IconButton(
                  tooltip: 'Volver a leer el día',
                  icon: const Icon(Icons.refresh),
                  onPressed: notifier.cargar,
                ),
                IconButton(
                  tooltip: 'Cargar el PDF de Cierre de Operaciones',
                  icon:
                      state.descargandoPdf
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.picture_as_pdf_outlined),
                  onPressed:
                      state.descargandoPdf
                          ? null
                          : () => _verPdf(
                            notifier.pdfCierre,
                            'Cierre de Operaciones',
                            'cierre_de_operaciones_${fechaParaSql(state.fecha)}.pdf',
                          ),
                ),
              ],
            ),
            body: SafeArea(
              child: MargenPaginaTareas(
                abajo: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!state.mirandoElDiaDeLaTarea)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.m),
                        child: _FranjaOtroDia(
                          fechaTarea: state.fechaOcurrencia,
                          onVolver:
                              () => notifier.cambiarFecha(state.fechaOcurrencia),
                        ),
                      ),
                    // El checkbox "Mostrar otras sucursales" del sistema
                    // anterior: amplía arqueos, caja fuerte y tareas a toda la
                    // empresa.
                    Padding(
                      padding: const EdgeInsets.only(bottom: Esp.m),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilterChip(
                          avatar: const Icon(
                            Icons.store_mall_directory_outlined,
                            size: 18,
                          ),
                          label: const Text('Todas las sucursales'),
                          selected: state.todasSucursales,
                          onSelected: notifier.alternarTodasSucursales,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: notifier.cargar,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: Esp.l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final panel in state.paneles) ...[
                                KeyedSubtree(
                                  key: _llaves[panel],
                                  child: _panel(context, panel, state, notifier),
                                ),
                                if (panel != state.paneles.last)
                                  const SizedBox(height: Esp.l),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BarraAccionTareas(
              resumen: _ResumenCierre(state: state, onIrAlPanel: _irAlPanel),
              accion: FilledButton.icon(
                onPressed: state.puedeCerrar ? notifier.cerrar : null,
                icon:
                    state.cerrando
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.task_alt),
                label: Text(
                  state.cerrando
                      ? 'Cerrando…'
                      : widget.modo == ModoCierre.cierre
                      ? 'Cerrar Cierre de Operaciones'
                      : 'Cerrar la verificación',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Las secciones ─────────────────────────────────────────────────────────

  Widget _panel(
    BuildContext context,
    PanelCierre cual,
    CierreOperacionesState s,
    CierreOperacionesNotifier n,
  ) {
    // Las que no tienen filas que marcar se revisan con el interruptor.
    final ValueChanged<bool>? confirmar =
        s.necesitaConfirmacion(cual)
            ? (valor) {
              HapticFeedback.selectionClick();
              n.confirmarSeccion(cual, valor);
            }
            : null;
    final revisada = s.seccionRevisada(cual);

    switch (cual) {
      case PanelCierre.arqueos:
        return PanelCierreCard(
          titulo: 'Arqueos de caja',
          detalle: 'Lo que cerró cada cajero, con su diferencia.',
          icono: Icons.point_of_sale,
          color: TareasColors.tipoTareaTexto(context, 2),
          datos: s.arqueos,
          vacio: 'No hubo arqueos de caja ese día.',
          tituloError: 'No se pudo leer los arqueos',
          onReintentar: () => n.recargar(cual),
          revisada: revisada,
          onRevisada: confirmar,
          contador:
              s.arqueos.filas.isEmpty
                  ? null
                  : ContadorPanel.avance(
                    s.arqueosRevisados,
                    s.arqueos.filas.length,
                    'revisados',
                  ),
          contenido:
              (_) => ContenidoArqueos(
                filas: s.arqueos.filas,
                guardando: (id) => s.guardando.contains('arqueo:$id'),
                onRevisar: (id) {
                  HapticFeedback.selectionClick();
                  n.marcarArqueoRevisado(id);
                },
                onPdf:
                    (id) => _verPdf(
                      () => n.pdfArqueo(id),
                      'Arqueo de caja',
                      'arqueo_de_caja_$id.pdf',
                    ),
              ),
        );

      case PanelCierre.traspasos:
        return PanelCierreCard(
          titulo: 'Traspaso de Caja AXA contra movimiento de caja',
          detalle: 'Cómo quedó lo que marcó el cajero en su tarea.',
          icono: Icons.compare_arrows,
          color: TareasColors.tipoTareaTexto(context, 12),
          datos: s.traspasos,
          vacio: 'El sistema no devolvió traspasos para ese día.',
          tituloError: 'No se pudo leer los traspasos',
          onReintentar: () => n.recargar(cual),
          revisada: revisada,
          onRevisada: confirmar,
          contador:
              s.traspasos.filas.isEmpty
                  ? null
                  : ContadorPanel.avance(
                    s.traspasosRevisados,
                    s.traspasos.filas.length,
                    'revisados',
                  ),
          contenido: (_) => ContenidoTraspasos(filas: s.traspasos.filas),
        );

      case PanelCierre.cajaFuerte:
        return PanelCierreCard(
          titulo: 'Caja fuerte',
          detalle: 'Lo que llegó a la caja fuerte ese día.',
          icono: Icons.lock_outlined,
          color: TareasColors.tipoTareaTexto(context, 4),
          datos: s.cajaFuerte,
          vacio: 'No hubo llegadas a caja fuerte ese día.',
          tituloError: 'No se pudo leer las llegadas',
          onReintentar: () => n.recargar(cual),
          revisada: revisada,
          onRevisada: confirmar,
          contador:
              s.cajaFuerte.filas.isEmpty
                  ? null
                  : ContadorPanel.avance(
                    s.llegadasVerificadas,
                    s.cajaFuerte.filas.length,
                    'verificadas',
                  ),
          acciones: [
            IconButton(
              tooltip: 'Descargar el PDF de caja fuerte',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              visualDensity: VisualDensity.compact,
              onPressed:
                  s.descargandoPdf
                      ? null
                      : () => _verPdf(
                        n.pdfCajaFuerte,
                        'Caja Fuerte',
                        'caja_fuerte_${fechaParaSql(s.fecha)}.pdf',
                      ),
            ),
          ],
          contenido:
              (_) => ContenidoCajaFuerte(
                filas: s.cajaFuerte.filas,
                guardando: (id) => s.guardando.contains('llegada:$id'),
                onVerificar: (id) {
                  HapticFeedback.selectionClick();
                  n.marcarLlegadaVerificada(id);
                },
              ),
        );

      case PanelCierre.cheques:
        return PanelCierreCard(
          titulo: 'Cheques',
          detalle: 'Los cheques en custodia contra lo que SAP cobró ese día.',
          icono: Icons.receipt_long_outlined,
          color: TareasColors.valesTexto(context),
          datos: s.cheques,
          vacio: 'No hubo cheques ese día.',
          tituloError: 'No se pudo leer los cheques',
          onReintentar: () => n.recargar(cual),
          revisada: revisada,
          onRevisada: confirmar,
          contador:
              s.cheques.filas.isEmpty
                  ? null
                  : ContadorPanel(
                    texto:
                        s.chequesParaRevisar == 0
                            ? 'Todos cobrados'
                            : '${s.chequesParaRevisar} para revisar',
                    completo: s.chequesParaRevisar == 0,
                  ),
          contenido: (_) => ContenidoCheques(filas: s.cheques.filas),
        );

      case PanelCierre.tareas:
        return PanelCierreCard(
          titulo: 'Tareas rutinarias del día',
          detalle:
              s.todasSucursales
                  ? 'Lo que el Job les generó ese día a los demás, en toda la empresa.'
                  : 'Lo que el Job les generó ese día a los demás, en la sucursal.',
          icono: Icons.fact_check_outlined,
          color: TareasColors.tipoTareaTexto(context, 1),
          datos: s.tareas,
          vacio: 'Ese día no hubo tareas de otras personas en esta sucursal.',
          tituloError: 'No se pudo leer las tareas del día',
          onReintentar: () => n.recargar(cual),
          revisada: revisada,
          onRevisada: confirmar,
          contador:
              s.tareas.filas.isEmpty
                  ? null
                  : ContadorPanel(
                    texto:
                        s.tareasSinHacer == 0
                            ? 'Todas respondidas'
                            : '${s.tareasSinHacer} sin hacer',
                    completo: s.tareasSinHacer == 0,
                  ),
          contenido: (_) => ContenidoTareas(filas: s.tareas.filas),
        );
    }
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _elegirFecha(
    CierreOperacionesState s,
    CierreOperacionesNotifier n,
  ) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: s.fecha,
      firstDate: DateTime(2020),
      // Un día que todavía no pasó no tiene nada que revisar.
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
    );
    if (elegida == null) return;
    HapticFeedback.selectionClick();
    await n.cambiarFecha(elegida);
  }

  Future<void> _verPdf(
    Future<Uint8List?> Function() generar,
    String titulo,
    String archivo,
  ) async {
    HapticFeedback.selectionClick();
    final bytes = await generar();
    if (bytes == null || !mounted) return;
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: titulo,
      nombreArchivo: archivo,
    );
  }

  // ── Textos ────────────────────────────────────────────────────────────────

  String _mensajeDeCierre(CierreOperacionesState s) {
    if (s.modo == ModoCierre.cierre) {
      return 'Cierre de Operaciones del ${_fechaCorta(s.fechaOcurrencia)} cerrado.';
    }
    final n = s.cerradas ?? 0;
    return 'Verificación cerrada${n > 0 ? ' ($n ocurrencia(s))' : ''}.';
  }

  String _subtitulo(CierreOperacionesState s) {
    final dia = _conDiaSemana(s.fecha);
    if (!s.todoLeido) return dia;
    final falta = s.faltaParaCerrar;
    if (falta.isEmpty) return '$dia · todo revisado';
    return '$dia · falta ${falta.first}'
        '${falta.length > 1 ? ' y ${falta.length - 1} más' : ''}';
  }
}

const _diasDeLaSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// "Viernes 11/09/2026". El día de la semana ayuda a ver de un vistazo si el
/// día que se está revisando es el que se quería.
String _conDiaSemana(DateTime d) =>
    '${_diasDeLaSemana[d.weekday - 1]} ${FormatearFecha.formatearFecha(d)}';

String _fechaCorta(DateTime d) => FormatearFecha.formatearFecha(d);

/// Se está mirando un día que no es el de la tarea.
class _FranjaOtroDia extends StatelessWidget {
  final DateTime fechaTarea;
  final VoidCallback onVolver;

  const _FranjaOtroDia({required this.fechaTarea, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    final color = TareasColors.pendienteTexto(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TareasColors.pendiente(context),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Esp.m,
          vertical: Esp.s,
        ),
        child: Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.history, size: 18, color: color),
            Text(
              'Estás mirando otro día. Tu tarea es del '
              '${_fechaCorta(fechaTarea)} y solo ese se puede cerrar.',
              style: TextStyle(color: color),
            ),
            TextButton(
              onPressed: onVolver,
              child: Text('Volver al ${_fechaCorta(fechaTarea)}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que falta para cerrar: una pastilla por sección, y tocar una lleva hasta
/// ella.
class _ResumenCierre extends StatelessWidget {
  final CierreOperacionesState state;
  final void Function(PanelCierre) onIrAlPanel;

  const _ResumenCierre({required this.state, required this.onIrAlPanel});

  @override
  Widget build(BuildContext context) {
    if (!state.mirandoElDiaDeLaTarea) {
      return Text(
        'Para cerrar, vuelve al ${_fechaCorta(state.fechaOcurrencia)}.',
        style: context.apagado(),
      );
    }
    if (!state.todoLeido && !state.algoFallo) {
      return Text('Leyendo el día…', style: context.apagado());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.algoFallo)
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.xs),
            child: Text(
              'Hay secciones que no se pudieron leer: reintenta antes de cerrar.',
              style: context.apagado(),
            ),
          ),
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          children: [
            for (final panel in state.paneles)
              _ChipSeccion(
                texto: _textoDe(panel),
                revisada: state.seccionRevisada(panel),
                onTap: () => onIrAlPanel(panel),
              ),
          ],
        ),
      ],
    );
  }

  String _textoDe(PanelCierre panel) {
    final datos = state.panel(panel);
    if (!datos.cargado) {
      return switch (panel) {
        PanelCierre.arqueos => 'Arqueos sin leer',
        PanelCierre.traspasos => 'Traspasos sin leer',
        PanelCierre.cajaFuerte => 'Caja fuerte sin leer',
        PanelCierre.cheques => 'Cheques sin leer',
        PanelCierre.tareas => 'Tareas sin leer',
      };
    }
    return switch (panel) {
      PanelCierre.arqueos =>
        state.arqueos.filas.isEmpty
            ? 'Sin arqueos'
            : '${state.arqueosRevisados}/${state.arqueos.filas.length} arqueos revisados',
      PanelCierre.traspasos =>
        state.traspasos.filas.isEmpty
            ? 'Sin traspasos'
            : '${state.traspasosRevisados}/${state.traspasos.filas.length} traspasos revisados',
      PanelCierre.cajaFuerte =>
        state.cajaFuerte.filas.isEmpty
            ? 'Sin llegadas'
            : '${state.llegadasVerificadas}/${state.cajaFuerte.filas.length} llegadas verificadas',
      PanelCierre.cheques =>
        state.cheques.filas.isEmpty
            ? 'Sin cheques'
            : state.chequesParaRevisar == 0
            ? '${state.cheques.filas.length} cheques cobrados'
            : '${state.chequesParaRevisar} de ${state.cheques.filas.length} cheques para revisar',
      PanelCierre.tareas =>
        state.tareas.filas.isEmpty
            ? 'Sin tareas'
            : state.tareasSinHacer == 0
            ? '${state.tareas.filas.length} tareas respondidas'
            : '${state.tareasSinHacer} de ${state.tareas.filas.length} tareas sin hacer',
    };
  }
}

class _ChipSeccion extends StatelessWidget {
  final String texto;
  final bool revisada;
  final VoidCallback onTap;

  const _ChipSeccion({
    required this.texto,
    required this.revisada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fondo =
        revisada
            ? TareasColors.realizado(context)
            : TareasColors.pendiente(context);
    final color =
        revisada
            ? TareasColors.realizadoTexto(context)
            : TareasColors.pendienteTexto(context);
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(Esquina.pastilla),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                revisada ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14,
                color: color,
              ),
              const SizedBox(width: Esp.xs),
              Text(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
