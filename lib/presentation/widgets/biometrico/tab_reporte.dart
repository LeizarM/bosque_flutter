import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/domain/entities/bio_empl_bosq_empl_entity.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/buscador_empleado_biometrico.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/calendario_asistencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Pestaña "Reporte": elegir empleado + mes, ver el calendario de asistencia
/// ya corregido (feriado / sábado libre / permiso / vacación separados de
/// una falta real).
class TabReporte extends ConsumerWidget {
  const TabReporte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elegido = ref.watch(empleadoSeleccionadoBiometricoProvider);
    final mes = ref.watch(mesSeleccionadoBiometricoProvider);

    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);
        return SingleChildScrollView(
          padding: EdgeInsets.all(aire.esChico ? Esp.l : Esp.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // El buscador nunca ocupa todo el ancho en pantallas
                    // amplias: un combo de 900 px se lee peor que uno de 360.
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: const BuscadorEmpleadoBiometrico(),
                      ),
                    ),
                    if (elegido != null) ...[
                      IconButton(
                        tooltip: 'Actualizar',
                        icon: const Icon(Icons.refresh),
                        onPressed:
                            () =>
                                _refrescar(ref, elegido.idEmpleado, mes),
                      ),
                      _BotonDescargarPdf(
                        idEmpleado: elegido.idEmpleado,
                        mes: mes,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Esp.xl),
                if (elegido == null)
                  const MensajeVacio(
                    icono: Icons.badge_outlined,
                    titulo: 'Elegí un empleado',
                    detalle:
                        'Buscá por nombre arriba para ver su asistencia del mes.',
                  )
                else ...[
                  _SelectorDeMes(mes: mes),
                  const SizedBox(height: Esp.xl),
                  _ReporteDelMes(
                    empleado: elegido,
                    mes: mes,
                    anchoDisponible: cajon.maxWidth,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static void _refrescar(WidgetRef ref, BigInt idEmpleado, DateTime mes) {
    ref.invalidate(
      reporteBiometricoProvider(
        ReporteBiometricoParams(
          codEmpleado: idEmpleado,
          anio: mes.year,
          mes: mes.month,
        ),
      ),
    );
  }
}

class _SelectorDeMes extends ConsumerWidget {
  const _SelectorDeMes({required this.mes});
  final DateTime mes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mesSeleccionadoBiometricoProvider.notifier);
    final esMesActual =
        mes.year == DateTime.now().year && mes.month == DateTime.now().month;

    return Row(
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
          // No se navega más allá del mes en curso: todavía no hay
          // marcaciones futuras que reportar.
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

class _ReporteDelMes extends ConsumerWidget {
  const _ReporteDelMes({
    required this.empleado,
    required this.mes,
    required this.anchoDisponible,
  });

  final BioEmplBosqEmplEntity empleado;
  final DateTime mes;
  final double anchoDisponible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      reporteBiometricoProvider(
        ReporteBiometricoParams(
          codEmpleado: empleado.idEmpleado,
          anio: mes.year,
          mes: mes.month,
        ),
      ),
    );

    return async.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: Esp.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => MensajeVacio(
            icono: Icons.error_outline,
            titulo: 'No se pudo cargar el reporte',
            detalle: textoDeError(error),
          ),
      data: (dias) {
        if (dias.isEmpty) {
          return const MensajeVacio(
            icono: Icons.event_busy,
            titulo: 'Sin datos para este mes',
            detalle: 'No hay información de asistencia para el rango elegido.',
          );
        }
        return CalendarioAsistencia(
          mes: mes,
          dias: dias,
          anchoDisponible: anchoDisponible,
          userId: empleado.idEmpleadBio.toInt(),
          codEmpleado: empleado.idEmpleado.toInt(),
        );
      },
    );
  }
}

/// El PDF detallado (`RptBiometricoDetallado.jrxml`), con su columna Obs
/// explicando cada día que no es una falta real. Mismo patrón que el botón
/// de descarga de `permisos-rrhh/ficha_saldo.dart`: pide los bytes y los
/// abre con `Printing.layoutPdf`, que en escritorio/web da la vista previa
/// con la opción de guardar o imprimir.
class _BotonDescargarPdf extends ConsumerStatefulWidget {
  const _BotonDescargarPdf({required this.idEmpleado, required this.mes});
  final BigInt idEmpleado;
  final DateTime mes;

  @override
  ConsumerState<_BotonDescargarPdf> createState() => _BotonDescargarPdfState();
}

class _BotonDescargarPdfState extends ConsumerState<_BotonDescargarPdf> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Descargar PDF',
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
      final pdf = await repo.reporteMensualPdf(
        codEmpleado: widget.idEmpleado,
        anio: widget.mes.year,
        mes: widget.mes.month,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name:
            'AsistenciaBiometrica_${widget.idEmpleado}_'
            '${widget.mes.year}${widget.mes.month.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      if (mounted) avisarError(context, e);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }
}
