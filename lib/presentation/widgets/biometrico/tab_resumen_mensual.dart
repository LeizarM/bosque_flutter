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
///
/// Rediseñada 2026-09-01: el `DataTable` original se autoajustaba al
/// contenido, no al ancho disponible — en una pantalla ancha dejaba una
/// franja vacía entre columnas en vez de usarla, y en una angosta obligaba a
/// scrollear horizontal. Ahora es una tabla de `Expanded`/flex que SIEMPRE
/// llena el ancho del panel (≥ `Aire.medio`) y una lista de tarjetas en
/// `Aire.justo` (< 600px) — mismo umbral que ya usa el resto del módulo, no
/// uno nuevo inventado para esta pantalla. Se agregó además un buscador en
/// vivo por nombre, ausente antes (con ~400 filas posibles, no había forma
/// de encontrar a alguien sin bajar a mano).
class TabResumenMensual extends ConsumerStatefulWidget {
  const TabResumenMensual({super.key, required this.onVerDetalle});

  /// Cambia a la pestaña Reporte con este empleado ya elegido.
  final VoidCallback onVerDetalle;

  @override
  ConsumerState<TabResumenMensual> createState() => _TabResumenMensualState();
}

class _TabResumenMensualState extends ConsumerState<TabResumenMensual> {
  final _buscarCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mes = ref.watch(mesSeleccionadoBiometricoProvider);
    final async = ref.watch(resumenMensualBiometricoProvider(mes));

    return Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final acciones = [
                IconButton(
                  style: estiloBotonAccion(context),
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh),
                  onPressed:
                      () => ref.invalidate(resumenMensualBiometricoProvider(mes)),
                ),
                _BotonDescargarResumenPdf(mes: mes),
                _BotonDescargarDetalladoTodosPdf(mes: mes),
                const _BotonDescargarHorarioVigentePdf(),
              ];
              // Aire.justo (< 600px): los botones no entran en la misma
              // línea que el selector de mes sin apretarse — se acomodan
              // debajo, envueltos, en vez de desbordar o achicarse hasta
              // ser ilegibles.
              if (Aire.de(constraints.maxWidth).esChico) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SelectorDeMesResumen(mes: mes),
                    const SizedBox(height: Esp.xs),
                    Wrap(spacing: Esp.xs, children: acciones),
                  ],
                );
              }
              return Row(
                children: [
                  _SelectorDeMesResumen(mes: mes),
                  const Spacer(),
                  // Wrap en vez de spread directo: con estiloBotonAccion
                  // (fondo visible, no un ícono pelado) los botones tocándose
                  // se ven amontonados — spacing acá, igual que en Aire.justo.
                  Wrap(spacing: Esp.xs, children: acciones),
                ],
              );
            },
          ),
          const SizedBox(height: Esp.m),
          TextField(
            controller: _buscarCtrl,
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar empleado...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Esquina.chica),
              ),
              suffixIcon:
                  _busqueda.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _buscarCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      ),
            ),
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
              data: (todas) {
                if (todas.isEmpty) {
                  return const MensajeVacio(
                    icono: Icons.groups_outlined,
                    titulo: 'Sin empleados enlazados',
                    detalle: 'Enlazá empleados en la pestaña Empleados primero.',
                  );
                }
                final filtro = _busqueda.trim().toLowerCase();
                final filas =
                    filtro.isEmpty
                        ? todas
                        : todas
                            .where(
                              (f) =>
                                  f.nombreEmpleado.toLowerCase().contains(filtro),
                            )
                            .toList();
                if (filas.isEmpty) {
                  return MensajeVacio(
                    icono: Icons.search_off,
                    titulo: 'Sin resultados',
                    detalle: 'Nadie coincide con "$_busqueda".',
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (Aire.de(constraints.maxWidth).esChico) {
                      return _TarjetasResumen(
                        filas: filas,
                        onVerDetalle: widget.onVerDetalle,
                      );
                    }
                    return _TablaResumen(
                      filas: filas,
                      onVerDetalle: widget.onVerDetalle,
                    );
                  },
                );
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

/// `idEmpleado` del empleado seleccionado en la pestaña Reporte — mismo
/// camino de resolución que usaba el `DataTable` original.
void _verDetalle(
  WidgetRef ref,
  ResumenAsistenciaEmpleadoEntity f,
  VoidCallback onVerDetalle,
) {
  // El picker de la pestaña Reporte sólo lista `enlazado`s de
  // `empleadosBiometricoProvider` — buscamos ahí al que coincide en vez de
  // fabricar una entidad a mano, para no arrastrar datos (idEmpleadBio,
  // datoNombreBiom) que este resumen no tiene.
  final empleados = ref.read(empleadosBiometricoProvider).valueOrNull ?? [];
  final elegido =
      empleados.where((e) => e.idEmpleado == f.codEmpleado).firstOrNull;
  if (elegido != null) {
    ref.read(empleadoSeleccionadoBiometricoProvider.notifier).state = elegido;
  }
  onVerDetalle();
}

const List<int> _flexColumnas = [5, 2, 2, 2, 4];

/// La tabla, para `Aire.medio`/`Aire.amplio` — cada celda es un `Expanded`
/// con el mismo flex que su encabezado, así que la fila SIEMPRE llena el
/// ancho disponible en vez de autoajustarse al contenido como hacía
/// `DataTable` (eso era el hueco vacío que se veía en pantalla ancha).
class _TablaResumen extends ConsumerWidget {
  const _TablaResumen({required this.filas, required this.onVerDetalle});
  final List<ResumenAsistenciaEmpleadoEntity> filas;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estiloEncabezado = context.tituloSeccion();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.l),
          child: Row(
            children: [
              Expanded(
                flex: _flexColumnas[0],
                child: Text('Empleado', style: estiloEncabezado),
              ),
              Expanded(
                flex: _flexColumnas[1],
                child: Text(
                  'Días asignados',
                  textAlign: TextAlign.center,
                  style: estiloEncabezado,
                ),
              ),
              Expanded(
                flex: _flexColumnas[2],
                child: Text(
                  'No marcados',
                  textAlign: TextAlign.center,
                  style: estiloEncabezado,
                ),
              ),
              Expanded(
                flex: _flexColumnas[3],
                child: Text(
                  'Atraso (min)',
                  textAlign: TextAlign.center,
                  style: estiloEncabezado,
                ),
              ),
              Expanded(
                flex: _flexColumnas[4],
                child: Text('Observaciones', style: estiloEncabezado),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        const SizedBox(height: Esp.s),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: filas.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = filas[i];
              return _FilaResumen(
                fila: f,
                onTap: () => _verDetalle(ref, f, onVerDetalle),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({required this.fila, required this.onTap});
  final ResumenAsistenciaEmpleadoEntity fila;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      hoverColor: cs.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Esp.l,
          vertical: Esp.m,
        ),
        child: Row(
          children: [
            Expanded(
              flex: _flexColumnas[0],
              child: Text(fila.nombreEmpleado, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: _flexColumnas[1],
              child: Text(
                '${fila.diasAsignados}',
                textAlign: TextAlign.center,
                style: context.numero(),
              ),
            ),
            Expanded(
              flex: _flexColumnas[2],
              child: Center(
                child: Etiqueta(
                  texto: '${fila.diasNoMarcados}',
                  tono:
                      fila.diasNoMarcados > 0
                          ? TonoEtiqueta.error
                          : TonoEtiqueta.neutro,
                ),
              ),
            ),
            Expanded(
              flex: _flexColumnas[3],
              child: Text(
                '${fila.minutosAtraso}',
                textAlign: TextAlign.center,
                style: context.numero(),
              ),
            ),
            Expanded(
              flex: _flexColumnas[4],
              child: Text(
                fila.observaciones ?? '',
                style: context.apagado(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 32,
              child: Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de tarjetas, para `Aire.justo` (< 600px) — mismo umbral que ya usa
/// el resto del módulo (ver `Aire` en `tokens_bosque.dart`), no uno nuevo.
class _TarjetasResumen extends ConsumerWidget {
  const _TarjetasResumen({required this.filas, required this.onVerDetalle});
  final List<ResumenAsistenciaEmpleadoEntity> filas;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: filas.length,
      separatorBuilder: (_, _) => const SizedBox(height: Esp.s),
      itemBuilder: (context, i) {
        final f = filas[i];
        return _TarjetaResumen(
          fila: f,
          onTap: () => _verDetalle(ref, f, onVerDetalle),
        );
      },
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.fila, required this.onTap});
  final ResumenAsistenciaEmpleadoEntity fila;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(fila.nombreEmpleado, style: context.tituloSeccion()),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: Esp.m),
              Wrap(
                spacing: Esp.xl,
                runSpacing: Esp.s,
                children: [
                  _Estadistica(etiqueta: 'Días asignados', valor: '${fila.diasAsignados}'),
                  _Estadistica(
                    etiqueta: 'No marcados',
                    valor: '${fila.diasNoMarcados}',
                    destacado: fila.diasNoMarcados > 0,
                  ),
                  _Estadistica(etiqueta: 'Atraso', valor: '${fila.minutosAtraso} min'),
                ],
              ),
              if ((fila.observaciones ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: Esp.s),
                Text(fila.observaciones!, style: context.apagado()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  const _Estadistica({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });
  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: context.apagado()),
        Text(
          valor,
          style: context.numero(fuerte: true, color: destacado ? cs.error : null),
        ),
      ],
    );
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
      style: estiloBotonAccion(context),
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
      style: estiloBotonAccion(context),
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
      style: estiloBotonAccion(context),
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
