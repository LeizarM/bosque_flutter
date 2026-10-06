// Destino final: lib/presentation/screens/tareas-rutinarias/arqueo_caja_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/arqueo_caja_provider.dart';
import 'package:bosque_flutter/core/state/corte_provider.dart';
import 'package:bosque_flutter/core/state/documentacion_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/vale_arqueo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/fila_formulario_responsiva.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';

/// Reemplaza dlgArqCaja del legacy. El total/diferencia se recalculan en
/// vivo mientras se edita (igual que calcularTotalYDiferencia() del legacy)
/// y de nuevo en el servidor al guardar — aquí solo es para mostrar, el
/// servidor nunca confía en este número. Cerrar con descuadre está
/// permitido a propósito (comportamiento legacy real, no un bug) — solo se
/// avisa antes de confirmar.
///
/// saldoMovSap/tc NO son manuales en el legacy (confirmado leyendo
/// OBJECT_DEFINITION real de p_list_sucXMovCaja/p_list_arqueoCajaSucursales,
/// 2026-09-03): se autocompletan del desglose SAP por caja y del tipo de
/// cambio del día — ver [ArqueoCajaNotifier.cargarContexto]. Desde
/// 2026-09-07 son de SOLO LECTURA (pedido de Marcelo): los dos son valores
/// del sistema, y dejarlos editables permitía cerrar un arqueo cuyo "saldo
/// según sistema" no era el del sistema, o con un T.C. distinto al oficial
/// — en ambos casos la diferencia calculada deja de significar algo. El
/// widget sigue siendo Stateful porque necesita los controladores para
/// mostrar esos valores autocompletados.
class ArqueoCajaScreen extends ConsumerStatefulWidget {
  final int idTarRuti;
  final int idBitTarea;
  final String nombreTarea;

  const ArqueoCajaScreen({
    super.key,
    required this.idTarRuti,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  ConsumerState<ArqueoCajaScreen> createState() => _ArqueoCajaScreenState();
}

class _ArqueoCajaScreenState extends ConsumerState<ArqueoCajaScreen> {
  final _saldoSapCtrl = TextEditingController();
  final _tcCtrl = TextEditingController(text: '1');
  final _obsCtrl = TextEditingController();
  final _obsFocus = FocusNode();
  bool _contextoAplicado = false;
  // A pedido de Marcelo (2026-09-07): un descuadre > 0.10 Bs no bloquea el
  // cierre, pero exige explicar por qué en la observación — no basta con el
  // diálogo "¿seguro?" que ya existía para descuadres menores (0.01-0.10).
  bool _mostrarErrorObs = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(arqueoCajaProvider.notifier)
          .cargarContexto(widget.idBitTarea),
    );
  }

  @override
  void dispose() {
    _saldoSapCtrl.dispose();
    _tcCtrl.dispose();
    _obsCtrl.dispose();
    _obsFocus.dispose();
    super.dispose();
  }

  // Sigue siendo necesario como wrapper (y como callback `String
  // Function(dynamic)` para _ArqueoAnteriorCard): el valor crudo llega como
  // `dynamic` (String ISO o null) desde el JSON del backend, algo que
  // FormatearFecha.formatearFecha (que espera un DateTime ya parseado) no
  // resuelve por sí solo.
  String _dateFmt(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : null;
    if (d == null) return '—';
    return FormatearFecha.formatearFecha(d);
  }

  /// Ordena los bloques del arqueo según el ancho disponible.
  ///
  /// Un arqueo es una conciliación: dos lados que tienen que encontrarse. En
  /// una sola columna de 700px los dos lados nunca están en pantalla a la vez
  /// —se cuenta, se sube a mirar el saldo SAP, se vuelve a bajar— y en un
  /// monitor de 1920 sobraban ~980px sin usar (Marcelo, 2026-09-07: "no me
  /// quites espacio de la pantalla").
  ///
  /// Desde [TareasBreakpoints.splitMin] los dos lados se abren uno al lado del
  /// otro, con el mismo corte que ya existe en los datos: a la izquierda lo
  /// que dice el sistema (SAP, tipo de cambio, arqueo anterior — todo de solo
  /// lectura), a la derecha lo que la persona cuenta (cortes, documentación,
  /// vales — todo editable). No es decoración: es exactamente la línea que
  /// separa lo que se verifica de lo que se carga.
  ///
  /// 5:7 y no mitad y mitad porque el lado del conteo tiene 14 filas de cortes
  /// más documentación y vales, y el del sistema es una tabla compacta.
  ///
  /// La observación va última y a ancho completo en los dos layouts: explica
  /// la diferencia, y la diferencia recién existe cuando los dos lados están
  /// llenos. Abajo del umbral el orden es el de siempre, en una sola columna.
  List<Widget> _componerCuerpo({
    required bool esSplit,
    required Widget contexto,
    required Widget? anterior,
    required Widget sistema,
    required Widget cortes,
    required Widget documentacion,
    required Widget vales,
    required Widget observacion,
  }) {
    if (!esSplit) {
      return [
        contexto,
        if (anterior != null) ...[anterior, const SizedBox(height: 12)],
        sistema,
        cortes,
        documentacion,
        vales,
        observacion,
      ];
    }

    return [
      contexto,
      Row(
        // start y no stretch: stretch exige alto acotado, y dárselo pediría
        // IntrinsicHeight — que revienta con los LayoutBuilder que hay adentro
        // (ver el doc de FranjaAcento). Las dos columnas miden distinto a
        // propósito: cada una termina donde termina su contenido.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [sistema, if (anterior != null) anterior],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cortes, documentacion],
            ),
          ),
        ],
      ),
      // Vales va a lo ANCHO, fuera de la columna de la derecha. Es una tabla de
      // seis campos por fila (Nº, nombre, monto, fecha, empresa, observaciones)
      // y en 7/12 del ancho cada columna quedaba en ~120px: los textos de
      // ayuda salían cortados —"Nº ...", "Monto (...", "Fec…"— justo mientras
      // se está cargando, que es cuando hacen falta. Con el ancho completo
      // entran enteros. Mismo criterio que ya tenía Observación.
      vales,
      observacion,
    ];
  }

  Future<void> _confirmarYGuardar(
    BuildContext context,
    WidgetRef ref,
    double diferencia,
  ) async {
    // Descuadre > 0.10 Bs: no se bloquea el cierre, pero es obligatorio decir
    // por qué falta o sobra — reemplaza el diálogo de confirmación por una
    // exigencia real en el campo, no una simple advertencia descartable.
    if (diferencia.abs() > 0.10 && _obsCtrl.text.trim().isEmpty) {
      setState(() => _mostrarErrorObs = true);
      HapticFeedback.lightImpact();
      mostrarAviso(
        context,
        'El descuadre supera Bs 0.10 — indica una observación explicando la diferencia antes de cerrar.',
        tono: TonoAviso.error,
      );
      _obsFocus.requestFocus();
      return;
    }
    if (diferencia.abs() > 0.01 && diferencia.abs() <= 0.10) {
      final continuar = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Hay una diferencia'),
              content: Text(
                'El arqueo tiene un descuadre de ${FormatoMoneda.bs(diferencia)}. '
                '¿Seguro que quieres cerrar el arqueo así, sin ajustar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => cerrarRuta(ctx, false),
                  child: const Text('Revisar de nuevo'),
                ),
                FilledButton(
                  onPressed: () => cerrarRuta(ctx, true),
                  child: const Text('Cerrar igual'),
                ),
              ],
            ),
      );
      if (continuar != true) return;
    }
    if (!context.mounted) return;
    await ref
        .read(arqueoCajaProvider.notifier)
        .registrar(idTarRuti: widget.idTarRuti, idBitTarea: widget.idBitTarea);
  }

  /// Tras cerrar el arqueo, ofrece el comprobante (RptArqueoDeCaja del
  /// legacy — WizardTareas.cargarPdfArqueosDeCaja) antes de volver. idAC
  /// recién existe en este momento (lo devuelve el servidor al registrar),
  /// así que este es el único punto donde la pantalla puede pedirlo.
  Future<void> _ofrecerPdfYCerrar(int? idAC) async {
    if (idAC == null) {
      // No debería pasar (el servidor siempre devuelve idGenerado en un
      // registro exitoso), pero sin id no hay reporte que pedir — se cierra
      // igual, como antes de este botón.
      cerrarRuta(context, true);
      return;
    }
    bool generandoPdf = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Arqueo registrado'),
                  content: const Text(
                    '¿Quieres ver el comprobante en PDF antes de salir?',
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          generandoPdf ? null : () => cerrarRuta(ctx),
                      child: const Text('No, gracias'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          generandoPdf
                              ? null
                              : () async {
                                setDialogState(() => generandoPdf = true);
                                HapticFeedback.selectionClick();
                                try {
                                  final bytes = await ref
                                      .read(arqueoCajaProvider.notifier)
                                      .reportePdf(idAC);
                                  if (!ctx.mounted) return;
                                  cerrarRuta(ctx);
                                  if (!context.mounted) return;
                                  await mostrarPdf(
                                    context,
                                    bytes: bytes,
                                    titulo: 'Arqueo de caja',
                                    nombreArchivo: 'arqueo-de-caja-$idAC.pdf',
                                  );
                                } catch (e) {
                                  setDialogState(() => generandoPdf = false);
                                  if (!context.mounted) return;
                                  mostrarAviso(
                                    context,
                                    'No se pudo generar el PDF del arqueo.',
                                    tono: TonoAviso.error,
                                  );
                                }
                              },
                      icon:
                          generandoPdf
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(generandoPdf ? 'Generando…' : 'Ver PDF'),
                    ),
                  ],
                ),
          ),
    );
    if (!context.mounted) return;
    // Un cuadro de aire entre cerrar el dialogo del PDF y cerrar la
    // pantalla: al irse el dialogo el foco vuelve solo a un campo del
    // arqueo, y cerrar en el mismo cuadro lo destruye recien enfocado
    // (el porque completo esta en cerrar_ruta.dart).
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) cerrarRuta(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cortesState = ref.watch(corteProvider);
    final docsState = ref.watch(documentacionProvider);
    final state = ref.watch(arqueoCajaProvider);
    final notifier = ref.read(arqueoCajaProvider.notifier);

    final cortesActivos = cortesState.items;
    final total = state.totalCon(cortesActivos);
    final diferencia = state.diferenciaCon(cortesActivos);
    final cuadrado = diferencia.abs() <= 0.01;

    // Autocompleta los controladores UNA sola vez, apenas llega el contexto
    // real del servidor — después el usuario puede seguir editando sin que
    // se le pise lo que ya escribió.
    if (!_contextoAplicado &&
        !state.cargandoContexto &&
        (state.desgloseSap.isNotEmpty || state.tc != 1)) {
      _contextoAplicado = true;
      _saldoSapCtrl.text = FormatoMoneda.monto.format(state.saldoMovSap);
      _tcCtrl.text = FormatoMoneda.tipoCambio.format(state.tc);
    }

    ref.listen(arqueoCajaProvider, (previo, actual) {
      if (actual.completado && previo?.completado != true) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, 'Arqueo registrado — tarea completada.');
        _ofrecerPdfYCerrar(actual.idAC);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    final usuario = ref.watch(userProvider);
    final ahora = DateTime.now();
    final fechaHoy = FormatearFecha.formatearFecha(ahora);
    // "Hora" -- el legacy la muestra en el header (regArqCaja.hora, hora de
    // apertura del formulario) y aquí faltaba (Marcelo, 2026-09-07, tras
    // comparar contra el Tareas.xhtml real).
    final horaApertura = FormatearFecha.formatearHora(ahora);

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: widget.nombreTarea,
          subtitulo: [
            if ((usuario?.nombreSucursal ?? '').trim().isNotEmpty)
              usuario!.nombreSucursal.trim(),
            '$fechaHoy $horaApertura',
          ].join(' · '),
          insignia: InsigniaTarea.deTipo(context, 2),
        ),
        body: LayoutBuilder(
          builder: (context, cajon) {
            // El ancho del cajón y no el de la ventana: el sidebar del
            // dashboard se come 260 px, y con MediaQuery las dos columnas
            // aparecían cuando ya no entraban. Sin columna centrada: antes,
            // entre 900 y 1100 px, el formulario quedaba en 700 px al medio.
            final esSplit = cajon.maxWidth >= TareasBreakpoints.splitMin;
            return (cortesState.cargando || docsState.cargando) &&
                    cortesActivos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: TareasBreakpoints.contentMaxWidthSplit,
                    ),
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      children: _componerCuerpo(
                        esSplit: esSplit,
                        contexto: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 8,
                              children: [
                                _DatoContexto(
                                  icono: Icons.badge_outlined,
                                  etiqueta: 'Encargado',
                                  valor: usuario?.nombreCompleto ?? '—',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                _DatoContexto(
                                  icono: Icons.work_outline,
                                  etiqueta: 'Cargo',
                                  valor: usuario?.cargo ?? '—',
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                _DatoContexto(
                                  icono: Icons.store_outlined,
                                  etiqueta: 'Sucursal',
                                  valor: usuario?.nombreSucursal ?? '—',
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                _DatoContexto(
                                  icono: Icons.event_outlined,
                                  etiqueta: 'Fecha',
                                  valor: fechaHoy,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                _DatoContexto(
                                  icono: Icons.schedule_outlined,
                                  etiqueta: 'Hora',
                                  valor: horaApertura,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        anterior:
                            state.anterior == null
                                ? null
                                : _ArqueoAnteriorCard(
                                  anterior: state.anterior!,
                                  dateFmt: _dateFmt,
                                ),
                        sistema: _Seccion(
                          titulo: 'Según el sistema',
                          icono: Icons.dns_outlined,
                          acento: TareasColors.sapMovimientoTexto(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.cargandoContexto)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: LinearProgressIndicator(),
                                ),
                              // Desglose SAP por caja — el legacy lo muestra
                              // como tabla real (header "CAJA"/"MONTO (Bs.)"),
                              // aquí antes era una lista suelta sin encabezado ni
                              // fila de total visualmente atada al desglose
                              // (Marcelo, 2026-09-07: "el legacy tiene mas
                              // informacion"). El total sigue siendo
                              // state.saldoMovSap — mismo valor de siempre, solo
                              // ahora atado visualmente a las filas que lo
                              // componen, igual que el legacy.
                              if (state.desgloseSap.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_outlined,
                                      size: 16,
                                      color: TareasColors.sapMovimientoTexto(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Movimiento de caja SAP',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    // El acento de color va como HIJO (una barra
                                    // de 3px), no como BorderSide izquierdo: un
                                    // Border con lados de distinto color MÁS
                                    // borderRadius hace que Border.paint lance en
                                    // tiempo de pintado (box_border.dart:756).
                                    // RenderObject._paintWithContext se traga esa
                                    // excepción, así que el subárbol nunca llega
                                    // al canvas: la tabla seguía ocupando su alto
                                    // pero no se pintaba ni un píxel (regresión
                                    // del pase visual, 2026-09-07). Mismo patrón
                                    // que _Seccion más abajo, que sí funciona.
                                    border: Border.all(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FranjaAcento(
                                    ancho: 3,
                                    color: TareasColors.sapMovimientoTexto(
                                      context,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHigh,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Caja',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                'Monto (Bs)',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...state.desgloseSap.map(
                                          (fila) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _CajaSap(fila: fila),
                                                ),
                                                Text(
                                                  FormatoMoneda.monto.format(
                                                    (fila['monto'] as num?)
                                                            ?.toDouble() ??
                                                        0,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: TareasColors.sapMovimiento(
                                              context,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Total',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      TareasColors.sapMovimientoTexto(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                FormatoMoneda.bs(state.saldoMovSap),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      TareasColors.sapMovimientoTexto(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              // Solo lectura (Marcelo, 2026-09-07): el saldo SAP
                              // es la suma de las filas del desglose de arriba,
                              // resuelta por el servidor. Dejarlo editable
                              // permitía guardar un arqueo cuyo "saldo según
                              // sistema" no era el del sistema — y la diferencia
                              // calculada contra ese número deja de significar
                              // nada. Se muestra para verificar, no para
                              // corregir.
                              TextFormField(
                                controller: _saldoSapCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Saldo según sistema (SAP)',
                                  helperText:
                                      state.desgloseSap.isNotEmpty
                                          ? 'Calculado del desglose SAP — no editable'
                                          : null,
                                  isDense: true,
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Tabla de referencia Hoy/Ayer — el legacy la
                              // muestra como tabla de 3 columnas (Día/Fecha/
                              // T.C.), aquí antes solo se veía "Ayer: X" chico
                              // como helper text del campo editable. El campo
                              // de tipo de cambio sigue siendo el mismo, editable
                              // igual que siempre — esto es puramente la
                              // referencia visual de qué venía del sistema.
                              if (state.tc != 1 || state.tcAyer != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.currency_exchange,
                                      size: 16,
                                      color: TareasColors.tipoCambioTexto(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tipo de cambio',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    // Mismo caso que el bloque SAP de arriba: el
                                    // acento va como barra hija, porque un Border
                                    // de lados con distinto color + borderRadius
                                    // lanza en Border.paint y deja el subárbol
                                    // sin pintar.
                                    border: Border.all(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FranjaAcento(
                                    ancho: 3,
                                    color: TareasColors.tipoCambioTexto(
                                      context,
                                    ),
                                    child: Table(
                                      // Líneas entre filas: sin ellas, Hoy y Ayer se
                                      // leían como una sola.
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                        ),
                                      ),
                                      columnWidths: const {
                                        0: FlexColumnWidth(1),
                                        1: FlexColumnWidth(1.3),
                                        2: FlexColumnWidth(1),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHigh,
                                          ),
                                          children: [
                                            _CeldaTc(
                                              'Día',
                                              esHeader: true,
                                              context: context,
                                            ),
                                            _CeldaTc(
                                              'Fecha',
                                              esHeader: true,
                                              context: context,
                                            ),
                                            _CeldaTc(
                                              'T.C.',
                                              esHeader: true,
                                              context: context,
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            _CeldaTc(
                                              'Hoy',
                                              context: context,
                                              color:
                                                  TareasColors.tipoCambioTexto(
                                                    context,
                                                  ),
                                            ),
                                            _CeldaTc(
                                              _dateFmt(state.fechaHoyTc),
                                              context: context,
                                              color:
                                                  TareasColors.tipoCambioTexto(
                                                    context,
                                                  ),
                                            ),
                                            _CeldaTc(
                                              FormatoMoneda.tipoCambio.format(
                                                state.tc,
                                              ),
                                              context: context,
                                              color:
                                                  TareasColors.tipoCambioTexto(
                                                    context,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        if (state.tcAyer != null)
                                          TableRow(
                                            children: [
                                              _CeldaTc(
                                                'Ayer',
                                                context: context,
                                              ),
                                              _CeldaTc(
                                                _dateFmt(state.fechaAyerTc),
                                                context: context,
                                              ),
                                              _CeldaTc(
                                                FormatoMoneda.tipoCambio.format(
                                                  state.tcAyer!,
                                                ),
                                                context: context,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              // Solo lectura (Marcelo, 2026-09-07): el tipo de
                              // cambio sale de la tabla "Hoy/Ayer" de arriba, que
                              // es la fuente oficial. Editable, un tipeo cambiaba
                              // la conversión de todos los cortes en USD y el
                              // arqueo cerraba con un total que no reproduce
                              // nadie.
                              TextFormField(
                                controller: _tcCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de cambio (a usar)',
                                  helperText:
                                      'Tomado del T.C. de hoy — no editable',
                                  isDense: true,
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        cortes: _Seccion(
                          titulo: 'Cortes (billetes y monedas)',
                          icono: Icons.payments_outlined,
                          acento: Theme.of(context).colorScheme.primary,
                          child: Column(
                            children: [
                              ...cortesActivos.map((c) {
                                final cantidad =
                                    state.cantidadPorCorte[c.idCorte] ?? 0;
                                final valorUnitario = c.corte ?? 0;
                                final esDolares = c.tipoCorte == 'USD';
                                final subtotalBs =
                                    cantidad *
                                    valorUnitario *
                                    (esDolares ? state.tc : 1);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Badge de moneda — el legacy tiene una
                                      // columna "TIPO CORTE" propia (Bolivianos/
                                      // Dólares) además de la denominación;
                                      // antes aquí la moneda solo se leía metida
                                      // en el texto de la etiqueta.
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color:
                                              esDolares
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .tertiaryContainer
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          esDolares ? '\$us' : 'Bs',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                esDolares
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onTertiaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '${c.descripcion ?? ''} (${FormatoMoneda.monto.format(valorUnitario)})',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Cantidad',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          onChanged:
                                              (v) => notifier.setCantidadCorte(
                                                c.idCorte,
                                                int.tryParse(v) ?? 0,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 84,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          child: Text(
                                            key: ValueKey(subtotalBs),
                                            cantidad > 0
                                                ? FormatoMoneda.monto.format(
                                                  subtotalBs,
                                                )
                                                : '—',
                                            textAlign: TextAlign.end,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              fontWeight:
                                                  cantidad > 0
                                                      ? FontWeight.w700
                                                      : FontWeight.normal,
                                              color:
                                                  cantidad > 0
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface
                                                      : Theme.of(
                                                        context,
                                                      ).colorScheme.outline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Subtotal cortes',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Text(
                                        key: ValueKey(state.cantidadPorCorte),
                                        'Bs ${FormatoMoneda.monto.format(cortesActivos.fold<double>(0, (a, c) {
                                          final cant = state.cantidadPorCorte[c.idCorte] ?? 0;
                                          final factor = c.tipoCorte == 'USD' ? state.tc : 1;
                                          return a + cant * (c.corte ?? 0) * factor;
                                        }))}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        documentacion: _Seccion(
                          titulo: 'Documentación',
                          icono: Icons.description_outlined,
                          acento: TareasColors.documentacionTexto(context),
                          child: Column(
                            children:
                                docsState.items
                                    .map(
                                      (d) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                d.nombre,
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Monto',
                                                      isDense: true,
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                textInputAction:
                                                    TextInputAction.next,
                                                onChanged:
                                                    (v) => notifier.setMontoDoc(
                                                      d.idDoc,
                                                      double.tryParse(v) ?? 0,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        vales: _Seccion(
                          titulo: 'Vales',
                          icono: Icons.receipt_long_outlined,
                          acento: TareasColors.valesTexto(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // El encabezado solo si hay vales Y hay ancho para
                              // la tabla: seis títulos de columna sin nada debajo
                              // es peor que no mostrar nada.
                              if (esSplit && state.vales.isNotEmpty)
                                const _EncabezadoVales(),
                              ...state.vales.map(
                                (v) => _FilaVale(
                                  key: ValueKey(v.id),
                                  vale: v,
                                  enTabla: esSplit,
                                  onCambio:
                                      (actualizar) => notifier.actualizarVale(
                                        v.id,
                                        actualizar,
                                      ),
                                  onQuitar: () => notifier.quitarVale(v.id),
                                ),
                              ),
                              if (state.vales.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'Sin vales. Agrega uno si salió dinero de la caja respaldado con un vale.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: notifier.agregarVale,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar vale'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        observacion: TextFormField(
                          controller: _obsCtrl,
                          focusNode: _obsFocus,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText:
                                diferencia.abs() > 0.10
                                    ? 'Observación (obligatoria — explica la diferencia)'
                                    : 'Observación (opcional)',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            errorText:
                                _mostrarErrorObs && _obsCtrl.text.trim().isEmpty
                                    ? 'Debes explicar el descuadre antes de cerrar.'
                                    : null,
                          ),
                          onChanged: (v) {
                            notifier.setObs(v);
                            if (_mostrarErrorObs && v.trim().isNotEmpty) {
                              setState(() => _mostrarErrorObs = false);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                );
          },
        ),
        // El color cambia de "cuadrado" a "descuadrado" en vivo mientras se
        // edita — AnimatedContainer lo hace sentir como un cambio de estado
        // real, no un repintado brusco. Siempre visible (pegado abajo, arriba
        // del botón), no al final del scroll: es la respuesta a "por qué
        // cerrar" y necesita estar a la vista mientras se llena el formulario,
        // no solo al terminar.
        // La barra de accion del modulo: el cuadre a la izquierda y el boton
        // a la derecha. Antes el boton ocupaba todo el ancho de la pantalla.
        bottomNavigationBar: BarraAccionTareas(
          resumen: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        cuadrado
                            ? TareasColors.cuadrado(context)
                            : TareasColors.descuadrado(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cuadrado
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color:
                            cuadrado
                                ? TareasColors.cuadradoTexto(context)
                                : TareasColors.descuadradoTexto(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            'Total contado: ${FormatoMoneda.bs(total)}',
                            key: ValueKey(FormatoMoneda.monto.format(total)),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  cuadrado
                                      ? TareasColors.cuadradoTexto(context)
                                      : TareasColors.descuadradoTexto(context),
                            ),
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          cuadrado
                              ? 'Cuadra'
                              : 'Dif: ${FormatoMoneda.bs(diferencia)}',
                          key: ValueKey(
                            cuadrado
                                ? 'cuadrado'
                                : FormatoMoneda.monto.format(diferencia),
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                cuadrado
                                    ? TareasColors.cuadradoTexto(context)
                                    : TareasColors.descuadradoTexto(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          accion: FilledButton.icon(
                    onPressed:
                        state.guardando
                            ? null
                            : () =>
                                _confirmarYGuardar(context, ref, diferencia),
                    icon:
                        state.guardando
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                            : const Icon(Icons.check),
                    label: Text(
                      state.guardando ? 'Guardando…' : 'Cerrar arqueo',
                    ),
                  ),
        ),
      ),
    );
  }
}

/// Una celda de la tabla de referencia Hoy/Ayer del tipo de cambio — ver
/// comentario junto a su uso en el build principal.
class _CeldaTc extends StatelessWidget {
  final String texto;
  final bool esHeader;
  final BuildContext context;
  final Color? color;

  const _CeldaTc(
    this.texto, {
    this.esHeader = false,
    required this.context,
    this.color,
  });

  @override
  Widget build(BuildContext _) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style:
            esHeader
                ? Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)
                : Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
      ),
    );
  }
}

class _DatoContexto extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? color;

  const _DatoContexto({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: color ?? scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

/// Arqueo anterior de esta sucursal — contexto/comparación, no bloquea
/// nada. No existe en el diálogo de CREAR del legacy (esa lógica es del
/// panel de supervisor, ya migrado como Verificar Cierre) — aquí es un uso
/// nuevo del mismo dato real, pedido explícitamente por Marcelo.
class _ArqueoAnteriorCard extends StatelessWidget {
  final Map<String, dynamic> anterior;
  final String Function(dynamic) dateFmt;

  const _ArqueoAnteriorCard({required this.anterior, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diferencia = (anterior['diferencia'] as num?)?.toDouble() ?? 0;
    final cuadrado = diferencia.abs() <= 0.01;
    final revisado = (anterior['fueRevisado'] as num?)?.toInt() == 1;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 18,
              color: TareasColors.sapMovimientoTexto(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arqueo anterior · ${dateFmt(anterior['fecha'])}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total: ${FormatoMoneda.bs((anterior['total'] as num?)?.toDouble() ?? 0)} · '
                    '${cuadrado ? 'Cuadró' : 'Diferencia: ${FormatoMoneda.bs(diferencia)}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              revisado ? Icons.verified_outlined : Icons.hourglass_empty,
              size: 16,
              color:
                  revisado
                      ? TareasColors.realizadoTexto(context)
                      : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// [acento] pinta una franja de 4px a la izquierda de la tarjeta y tiñe el
/// ícono del título — identidad visual fija por tipo de bloque (Cortes,
/// Documentación, Vales), no un color de estado. Ver el comentario de
/// "Acentos de sección" en TareasColors. `null` conserva el borde neutro de
/// siempre (usado por bloques sin un tono propio, p.ej. "Datos generales",
/// que ya tiñe sus dos sub-bloques SAP/Tipo de cambio por separado).
class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  final IconData? icono;
  final Color? acento;

  const _Seccion({
    required this.titulo,
    required this.child,
    this.icono,
    this.acento,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      // FranjaAcento, no IntrinsicHeight: el contenido de Documentación y
      // Vales incluye FilaFormularioResponsiva (un LayoutBuilder), y
      // IntrinsicHeight le pide dimensiones intrínsecas que LayoutBuilder no
      // puede dar — la tarjeta entera quedaba sin pintar. Ver el doc de
      // FranjaAcento.
      child: FranjaAcento(
        color: acento,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 18, color: acento),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de vale -- réplica de las 6 columnas reales de la tabla "VALES SIN
/// CERRAR" del legacy (Tareas.xhtml:1007-1040, confirmado leyendo el XHTML
/// real, no de memoria: Nº Vale, NOMBRE, MONTO (Bs.), FECHA, EMPRESA,
/// OBSERVACIONES). Antes aquí solo había Nombre/Monto -- Marcelo señaló el
/// hueco directamente (2026-09-07) tras comparar con el legacy. El backend
/// (ValeArqueoDto/ArqueoRegistroDao.construirValesXml, atributos @f/@ce) ya
/// aceptaba fecha/codEmpresa desde siempre -- el hueco era solo aquí.

// Pesos de columna de la tabla de vales. Viven aquí arriba porque el
// encabezado (_EncabezadoVales) y cada fila (_FilaVale) TIENEN que usar los
// mismos: si divergen, las columnas dejan de alinearse entre sí y la tabla
// vuelve a ser lo que era, campos sueltos que casi coinciden.
const double _gapVale = 8;
const double _accionVale = 44;
const int _flexNumVale = 2;
const int _flexNombreVale = 5;
const int _flexMontoVale = 3;
const int _flexFechaVale = 3;
const int _flexEmpresaVale = 4;
const int _flexObsVale = 5;

/// Encabezado de la tabla de vales — se dibuja UNA vez, arriba de las filas.
///
/// Existe para que las filas puedan prescindir del `labelText` flotante de
/// cada campo: con seis campos por vale y varios vales cargados, repetir
/// "Nº Vale / Nombre / Monto…" en cada renglón era casi todo el texto de la
/// sección. Nombrar la columna una sola vez es lo que hace cualquier planilla
/// de caja, que es exactamente lo que esta sección es.
class _EncabezadoVales extends StatelessWidget {
  const _EncabezadoVales();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    Widget col(int flex, String texto) =>
        Expanded(flex: flex, child: Text(texto, style: estilo));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          col(_flexNumVale, 'Nº vale'),
          const SizedBox(width: _gapVale),
          col(_flexNombreVale, 'Nombre'),
          const SizedBox(width: _gapVale),
          col(_flexMontoVale, 'Monto (Bs)'),
          const SizedBox(width: _gapVale),
          col(_flexFechaVale, 'Fecha'),
          const SizedBox(width: _gapVale),
          col(_flexEmpresaVale, 'Empresa'),
          const SizedBox(width: _gapVale),
          col(_flexObsVale, 'Observaciones'),
          const SizedBox(width: _accionVale),
        ],
      ),
    );
  }
}

class _FilaVale extends ConsumerWidget {
  final ValeArqueoEntity vale;
  final void Function(ValeArqueoEntity Function(ValeArqueoEntity)) onCambio;
  final VoidCallback onQuitar;

  /// `true` = un renglón de tabla, con las columnas alineadas contra las de
  /// los demás vales y contra [_EncabezadoVales]. `false` = los seis campos
  /// envueltos en [FilaFormularioResponsiva], que es lo que corresponde
  /// cuando no hay ancho para seis columnas (teléfono, ventana chica).
  final bool enTabla;

  const _FilaVale({
    super.key,
    required this.vale,
    required this.onCambio,
    required this.onQuitar,
    this.enTabla = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empresasAsync = ref.watch(empresasProvider);

    // Los seis campos se arman una sola vez y los dos layouts los reusan: si
    // se duplicaran, un cambio de teclado o de validación habría que aplicarlo
    // dos veces, y tarde o temprano quedaría aplicado en una sola.
    InputDecoration deco(String etiqueta) => InputDecoration(
      // En tabla el nombre de la columna ya está en el encabezado; repetirlo
      // dentro de cada campo es ruido. Queda como hint para que un campo
      // vacío no sea una caja anónima.
      labelText: enTabla ? null : etiqueta,
      hintText: enTabla ? etiqueta : null,
      isDense: true,
      border: const OutlineInputBorder(),
    );

    final numero = TextFormField(
      initialValue: vale.numVale?.toString(),
      decoration: deco('Nº Vale'),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      onChanged: (v) => onCambio((f) => f.copyWith(numVale: int.tryParse(v))),
    );

    final nombre = TextFormField(
      initialValue: vale.nombre,
      decoration: deco('Nombre'),
      textInputAction: TextInputAction.next,
      onChanged: (v) => onCambio((f) => f.copyWith(nombre: v)),
    );

    final monto = TextFormField(
      initialValue: vale.monto?.toString(),
      decoration: deco('Monto (Bs)'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: (v) => onCambio((f) => f.copyWith(monto: double.tryParse(v))),
    );

    final fecha = OutlinedButton.icon(
      onPressed: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: vale.fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (elegida != null) onCambio((f) => f.copyWith(fecha: elegida));
      },
      icon: const Icon(Icons.event_outlined, size: 16),
      label: Text(
        vale.fecha == null
            ? 'Fecha'
            : FormatearFecha.formatearFecha(vale.fecha!),
        overflow: TextOverflow.ellipsis,
      ),
    );

    final empresa = empresasAsync.when(
      data:
          (empresas) => DropdownButtonFormField<int>(
            value: vale.codEmpresa,
            decoration: deco('Empresa'),
            isExpanded: true,
            items:
                empresas
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.codEmpresa,
                        child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged: (v) => onCambio((f) => f.copyWith(codEmpresa: v)),
          ),
      loading:
          () => const SizedBox(
            height: 20,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error: (_, __) => const Text('Empresa: error al cargar'),
    );

    final observaciones = TextFormField(
      initialValue: vale.obs,
      decoration: deco('Observaciones'),
      textInputAction: TextInputAction.done,
      onChanged: (v) => onCambio((f) => f.copyWith(obs: v)),
    );

    final borrar = IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Quitar vale',
      // Rojo: es el unico control de la fila que destruye algo.
      color: TareasColors.eliminar(context),
      hoverColor: TareasColors.eliminarFondo(context),
      onPressed: onQuitar,
    );

    if (!enTabla) {
      // Sin ancho para seis columnas: los campos se envuelven solos y el botón
      // de borrar queda anclado a la tarjeta entera, no a la primera fila —
      // ver el dartdoc de FilaFormularioResponsiva.
      return FilaFormularioResponsiva(
        accion: borrar,
        campos: [
          CampoResponsivo(minWidth: 90, child: numero),
          CampoResponsivo(minWidth: 180, child: nombre),
          CampoResponsivo(minWidth: 120, child: monto),
          CampoResponsivo(minWidth: 150, child: fecha),
          CampoResponsivo(minWidth: 170, child: empresa),
          CampoResponsivo(minWidth: 220, child: observaciones),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: _flexNumVale, child: numero),
          const SizedBox(width: _gapVale),
          Expanded(flex: _flexNombreVale, child: nombre),
          const SizedBox(width: _gapVale),
          Expanded(flex: _flexMontoVale, child: monto),
          const SizedBox(width: _gapVale),
          Expanded(flex: _flexFechaVale, child: fecha),
          const SizedBox(width: _gapVale),
          Expanded(flex: _flexEmpresaVale, child: empresa),
          const SizedBox(width: _gapVale),
          Expanded(flex: _flexObsVale, child: observaciones),
          SizedBox(width: _accionVale, child: borrar),
        ],
      ),
    );
  }
}

/// Una fila del movimiento de caja SAP: la empresa y, debajo, qué caja es.
///
/// Cada empresa tiene más de una cuenta de caja en la sucursal, y con solo el
/// nombre de la empresa las filas parecían duplicadas (Marcelo, 2026-10-05).
/// El nombre de la caja y la cuenta los manda el archivo SQL 72; si todavía no
/// llegan —backend o SQL anteriores—, la fila queda como antes.
class _CajaSap extends StatelessWidget {
  final Map<String, dynamic> fila;

  const _CajaSap({required this.fila});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // La etiqueta viene del sistema anterior con dos puntos al final
    // ("ESPPAPEL:").
    final empresa = ((fila['bd'] as String?) ?? '')
        .trim()
        .replaceFirst(RegExp(r':\s*$'), '');
    final caja = ((fila['nombreCaja'] as String?) ?? '').trim();
    final cuenta = (fila['codigoCuentaCajaSap'] ?? '').toString().trim();
    final detalle = [
      if (caja.isNotEmpty) caja,
      if (cuenta.isNotEmpty) 'cuenta $cuenta',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(empresa, style: tema.textTheme.bodySmall),
        if (detalle.isNotEmpty)
          Text(
            detalle,
            style: tema.textTheme.labelSmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
