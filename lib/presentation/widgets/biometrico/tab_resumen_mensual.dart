import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/domain/entities/resumen_asistencia_empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Pestaña "Resumen mensual": todos los empleados enlazados, un mes, sus
/// totales — responde "dónde veo el reporte de todos los empleados". El
/// detalle día-por-día de UNO de ellos sigue viviendo en la pestaña Reporte;
/// tocar una fila acá te manda ahí ya con ese empleado elegido, en vez de
/// repetir el detalle de 400 personas en una sola pantalla.
class TabResumenMensual extends ConsumerWidget {
  const TabResumenMensual({super.key, required this.onVerDetalle});

  /// Cambia a la pestaña Reporte con este empleado ya elegido.
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSeleccionadoBiometricoProvider);
    final async = ref.watch(resumenMensualBiometricoProvider(mes));

    return Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SelectorDeMesResumen(mes: mes),
              const Spacer(),
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed:
                    () => ref.invalidate(resumenMensualBiometricoProvider(mes)),
              ),
              _BotonDescargarResumenPdf(mes: mes),
              _BotonDescargarDetalladoTodosPdf(mes: mes),
              const _BotonDescargarHorarioVigentePdf(),
            ],
          ),
          const SizedBox(height: Esp.m),
          Expanded(
            child: async.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Esp.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: Esp.m),
                          Text(
                            'Calculando el mes de todos los empleados — '
                            'puede tardar unos segundos.',
                          ),
                        ],
                      ),
                    ),
                  ),
              error:
                  (e, _) => MensajeVacio(
                    icono: Icons.error_outline,
                    titulo: 'No se pudo calcular el resumen',
                    detalle: textoDeError(e),
                  ),
              data: (filas) {
                if (filas.isEmpty) {
                  return const MensajeVacio(
                    icono: Icons.groups_outlined,
                    titulo: 'Sin empleados enlazados',
                    detalle: 'Enlazá empleados en la pestaña Empleados primero.',
                  );
                }
                return _TablaResumen(filas: filas, onVerDetalle: onVerDetalle);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorDeMesResumen extends ConsumerWidget {
  const _SelectorDeMesResumen({required this.mes});
  final DateTime mes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mesSeleccionadoBiometricoProvider.notifier);
    final esMesActual =
        mes.year == DateTime.now().year && mes.month == DateTime.now().month;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed:
              () => notifier.state = DateTime(mes.year, mes.month - 1, 1),
        ),
        SizedBox(
          width: 170,
          child: Text(
            '${nombresMeses[mes.month - 1]} ${mes.year}',
            textAlign: TextAlign.center,
            style: context.tituloSeccion(),
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed:
              esMesActual
                  ? null
                  : () =>
                      notifier.state = DateTime(mes.year, mes.month + 1, 1),
        ),
      ],
    );
  }
}

class _TablaResumen extends ConsumerWidget {
  const _TablaResumen({required this.filas, required this.onVerDetalle});
  final List<ResumenAsistenciaEmpleadoEntity> filas;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    // Scroll vertical AFUERA, horizontal ADENTRO: un solo SingleChildScrollView
    // horizontal (como había antes) deja a la tabla sin scroll vertical propio
    // — DataTable no lo tiene — y con >20 filas la parte de abajo queda
    // recortada por el Expanded del padre en vez de poder bajar.
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Empleado')),
            DataColumn(label: Text('Días asignados'), numeric: true),
            DataColumn(label: Text('Días NO marcados'), numeric: true),
            DataColumn(label: Text('Atrasos (min)'), numeric: true),
            DataColumn(label: Text('Observaciones')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final f in filas)
              DataRow(
                cells: [
                  DataCell(Text(f.nombreEmpleado)),
                  DataCell(Text('${f.diasAsignados}')),
                  DataCell(
                    Text(
                      '${f.diasNoMarcados}',
                      style: TextStyle(
                        color: f.diasNoMarcados > 0 ? cs.error : null,
                        fontWeight:
                            f.diasNoMarcados > 0 ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  DataCell(Text('${f.minutosAtraso}')),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        f.observaciones ?? '',
                        style: context.apagado(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      tooltip: 'Ver detalle',
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      onPressed: () => _verDetalle(ref, f),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _verDetalle(WidgetRef ref, ResumenAsistenciaEmpleadoEntity f) {
    // El picker de la pestaña Reporte sólo lista `enlazado`s de
    // `empleadosBiometricoProvider` — buscamos ahí al que coincide en vez de
    // fabricar una entidad a mano, para no arrastrar datos (idEmpleadBio,
    // datoNombreBiom) que este resumen no tiene.
    final empleados = ref.read(empleadosBiometricoProvider).valueOrNull ?? [];
    final elegido =
        empleados.where((e) => e.idEmpleado == f.codEmpleado).firstOrNull;
    if (elegido != null) {
      ref.read(empleadoSeleccionadoBiometricoProvider.notifier).state =
          elegido;
    }
    onVerDetalle();
  }
}

class _BotonDescargarResumenPdf extends ConsumerStatefulWidget {
  const _BotonDescargarResumenPdf({required this.mes});
  final DateTime mes;

  @override
  ConsumerState<_BotonDescargarResumenPdf> createState() =>
      _BotonDescargarResumenPdfState();
}

class _BotonDescargarResumenPdfState
    extends ConsumerState<_BotonDescargarResumenPdf> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Descargar resumen PDF (una fila por empleado)',
      icon:
          _generando
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.picture_as_pdf_outlined),
      onPressed: _generando ? null : _descargar,
    );
  }

  Future<void> _descargar() async {
    setState(() => _generando = true);
    try {
      final repo = ref.read(biometricoRepositoryProvider);
      final pdf = await repo.reporteMensualResumenPdf(
        anio: widget.mes.year,
        mes: widget.mes.month,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name:
            'ResumenAsistenciaBiometrica_'
            '${widget.mes.year}${widget.mes.month.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      if (mounted) avisarError(context, e);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }
}

/// El reporte DETALLADO día a día (mismo PDF que la pestaña Reporte, con la
/// columna Obs) pero para TODOS los empleados enlazados del mes, uno detrás
/// de otro — a diferencia de [_BotonDescargarResumenPdf], que trae una sola
/// fila por persona. Pide confirmación antes: es un PDF potencialmente
/// grande (un empleado por página, ~30 filas cada uno) y puede tardar.
class _BotonDescargarDetalladoTodosPdf extends ConsumerStatefulWidget {
  const _BotonDescargarDetalladoTodosPdf({required this.mes});
  final DateTime mes;

  @override
  ConsumerState<_BotonDescargarDetalladoTodosPdf> createState() =>
      _BotonDescargarDetalladoTodosPdfState();
}

class _BotonDescargarDetalladoTodosPdfState
    extends ConsumerState<_BotonDescargarDetalladoTodosPdf> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Descargar detallado PDF (día a día, todos los empleados)',
      icon:
          _generando
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.summarize_outlined),
      onPressed: _generando ? null : _confirmarYDescargar,
    );
  }

  Future<void> _confirmarYDescargar() async {
    final ok = await confirmar(
      context,
      titulo: 'Detallado de todos los empleados',
      mensaje:
          'Se va a generar el detalle día a día de '
          '${nombresMeses[widget.mes.month - 1]} ${widget.mes.year} para '
          'cada empleado enlazado, uno atrás del otro. Puede tardar '
          'bastante y el PDF puede salir pesado — ¿continuar?',
      accion: 'Generar',
    );
    if (!ok || !mounted) return;

    setState(() => _generando = true);
    try {
      final repo = ref.read(biometricoRepositoryProvider);
      final pdf = await repo.reporteMensualDetalladoTodosPdf(
        anio: widget.mes.year,
        mes: widget.mes.month,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name:
            'DetalleAsistenciaBiometrica_'
            '${widget.mes.year}${widget.mes.month.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      if (mounted) avisarError(context, e);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }
}

/// Qué `BioHrSemanal` tiene HOY cada empleado enlazado, con el detalle de
/// horas por día de semana (`RptBiometricoHorarioVigente.jrxml`) — a
/// diferencia de los otros dos botones de esta fila, no es un reporte
/// mensual ("ahora mismo", sin `anio`/`mes`), así que no depende del
/// selector de mes de esta pestaña.
class _BotonDescargarHorarioVigentePdf extends ConsumerStatefulWidget {
  const _BotonDescargarHorarioVigentePdf();

  @override
  ConsumerState<_BotonDescargarHorarioVigentePdf> createState() =>
      _BotonDescargarHorarioVigentePdfState();
}

class _BotonDescargarHorarioVigentePdfState
    extends ConsumerState<_BotonDescargarHorarioVigentePdf> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Descargar horario vigente PDF (qué horario tiene cada empleado hoy)',
      icon:
          _generando
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.schedule_outlined),
      onPressed: _generando ? null : _descargar,
    );
  }

  Future<void> _descargar() async {
    setState(() => _generando = true);
    try {
      final repo = ref.read(biometricoRepositoryProvider);
      final pdf = await repo.horarioVigentePorEmpleadoPdf();
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'HorarioVigentePorEmpleado',
      );
    } catch (e) {
      if (mounted) avisarError(context, e);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }
}
