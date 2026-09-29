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
                        style: estiloBotonAccion(context),
                        tooltip: 'Actualizar',
                        icon: const Icon(Icons.refresh),
                        onPressed:
                            () => _refrescar(ref, elegido.idEmpleado, mes),
                      ),
                      const SizedBox(width: Esp.xs),
                      _BotonDescargarPdf(
                        idEmpleado: elegido.idEmpleado,
                        mes: mes,
                      ),
                      const SizedBox(width: Esp.xs),
                      _BotonDescargarRangoPdf(
                        idEmpleado: elegido.idEmpleado,
                        mesActual: mes,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Esp.xl),
                if (elegido == null)
                  const MensajeVacio(
                    icono: Icons.badge_outlined,
                    titulo: 'Elige un empleado',
                    detalle:
                        'Busca por nombre arriba para ver su asistencia del mes.',
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
          style: estiloBotonAccion(context),
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
          style: estiloBotonAccion(context),
          tooltip: 'Mes siguiente',
          // No se navega más allá del mes en curso: todavía no hay
          // marcaciones futuras que reportar.
          icon: const Icon(Icons.chevron_right),
          onPressed:
              esMesActual
                  ? null
                  : () => notifier.state = DateTime(mes.year, mes.month + 1, 1),
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
      style: estiloBotonAccion(context),
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

/// Mismo PDF que [_BotonDescargarPdf] (`RptBiometricoDetallado.jrxml`), pero
/// para un rango de varios meses del mismo empleado en un solo archivo (un
/// mes por página) — para pedidos tipo "todas las marcaciones desde tal mes
/// hasta hoy" sin descargar un PDF por mes a mano.
class _BotonDescargarRangoPdf extends ConsumerStatefulWidget {
  const _BotonDescargarRangoPdf({
    required this.idEmpleado,
    required this.mesActual,
  });
  final BigInt idEmpleado;
  final DateTime mesActual;

  @override
  ConsumerState<_BotonDescargarRangoPdf> createState() =>
      _BotonDescargarRangoPdfState();
}

class _BotonDescargarRangoPdfState
    extends ConsumerState<_BotonDescargarRangoPdf> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: estiloBotonAccion(context),
      tooltip: 'Descargar rango de meses',
      icon:
          _generando
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.date_range_outlined),
      onPressed: _generando ? null : _elegirRangoYDescargar,
    );
  }

  Future<void> _elegirRangoYDescargar() async {
    final rango = await showDialog<_RangoElegido>(
      context: context,
      builder: (c) => _DialogoRangoMeses(mesHastaInicial: widget.mesActual),
    );
    if (rango == null || !mounted) return;

    setState(() => _generando = true);
    try {
      final repo = ref.read(biometricoRepositoryProvider);
      final pdf = await repo.reporteDetalladoRangoPdf(
        codEmpleado: widget.idEmpleado,
        anioDesde: rango.desde.year,
        mesDesde: rango.desde.month,
        anioHasta: rango.hasta.year,
        mesHasta: rango.hasta.month,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name:
            'AsistenciaBiometrica_${widget.idEmpleado}_rango_'
            '${rango.desde.year}${rango.desde.month.toString().padLeft(2, '0')}_'
            '${rango.hasta.year}${rango.hasta.month.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      if (mounted) avisarError(context, e);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }
}

class _RangoElegido {
  const _RangoElegido(this.desde, this.hasta);
  final DateTime desde;
  final DateTime hasta;
}

/// Diálogo de "Desde mes/año" – "Hasta mes/año". Arranca 12 meses antes del
/// mes que ya se estaba mirando en la pestaña, hasta ese mismo mes — el caso
/// más común es "el último año", no todo el historial por defecto.
class _DialogoRangoMeses extends StatefulWidget {
  const _DialogoRangoMeses({required this.mesHastaInicial});
  final DateTime mesHastaInicial;

  @override
  State<_DialogoRangoMeses> createState() => _DialogoRangoMesesState();
}

class _DialogoRangoMesesState extends State<_DialogoRangoMeses> {
  late int _mesDesde;
  late int _anioDesde;
  late int _mesHasta;
  late int _anioHasta;

  @override
  void initState() {
    super.initState();
    final hasta = widget.mesHastaInicial;
    final desde = DateTime(hasta.year - 1, hasta.month, 1);
    _mesDesde = desde.month;
    _anioDesde = desde.year;
    _mesHasta = hasta.month;
    _anioHasta = hasta.year;
  }

  List<int> get _anios {
    final actual = DateTime.now().year;
    return [for (var a = actual - 10; a <= actual; a++) a];
  }

  @override
  Widget build(BuildContext context) {
    final rangoInvalido =
        DateTime(_anioDesde, _mesDesde).isAfter(DateTime(_anioHasta, _mesHasta));

    return AlertDialog(
      title: const Text('Descargar rango de meses'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Un PDF con un mes por página, del mismo empleado.'),
          const SizedBox(height: Esp.l),
          Text('Desde', style: context.apagado()),
          const SizedBox(height: Esp.xs),
          _SelectorMesAnio(
            mes: _mesDesde,
            anio: _anioDesde,
            anios: _anios,
            onMes: (v) => setState(() => _mesDesde = v),
            onAnio: (v) => setState(() => _anioDesde = v),
          ),
          const SizedBox(height: Esp.m),
          Text('Hasta', style: context.apagado()),
          const SizedBox(height: Esp.xs),
          _SelectorMesAnio(
            mes: _mesHasta,
            anio: _anioHasta,
            anios: _anios,
            onMes: (v) => setState(() => _mesHasta = v),
            onAnio: (v) => setState(() => _anioHasta = v),
          ),
          if (rangoInvalido) ...[
            const SizedBox(height: Esp.m),
            Text(
              'El mes de inicio es posterior al mes final.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              rangoInvalido
                  ? null
                  : () => Navigator.pop(
                    context,
                    _RangoElegido(
                      DateTime(_anioDesde, _mesDesde),
                      DateTime(_anioHasta, _mesHasta),
                    ),
                  ),
          child: const Text('Descargar'),
        ),
      ],
    );
  }
}

class _SelectorMesAnio extends StatelessWidget {
  const _SelectorMesAnio({
    required this.mes,
    required this.anio,
    required this.anios,
    required this.onMes,
    required this.onAnio,
  });
  final int mes;
  final int anio;
  final List<int> anios;
  final ValueChanged<int> onMes;
  final ValueChanged<int> onAnio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: mes,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(nombresMeses[m - 1])),
            ],
            onChanged: (v) {
              if (v != null) onMes(v);
            },
          ),
        ),
        const SizedBox(width: Esp.s),
        SizedBox(
          width: 100,
          child: DropdownButtonFormField<int>(
            value: anio,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final a in anios)
                DropdownMenuItem(value: a, child: Text('$a')),
            ],
            onChanged: (v) {
              if (v != null) onAnio(v);
            },
          ),
        ),
      ],
    );
  }
}
