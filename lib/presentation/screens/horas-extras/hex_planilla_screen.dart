import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_empresas.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_ejecutada.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_ejecutar.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_lista.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_previa.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// `thexPlanilla/Planilla`: RRHH revisa la vista previa del lote del mes (o
/// de una sucursal), ve lo que falta firmar, la ejecuta (congela los montos)
/// y consulta e imprime las planillas ya ejecutadas, sueltas o por lote.
class HexPlanillaScreen extends ConsumerStatefulWidget {
  const HexPlanillaScreen({super.key});

  @override
  ConsumerState<HexPlanillaScreen> createState() => _HexPlanillaScreenState();
}

class _HexPlanillaScreenState extends ConsumerState<HexPlanillaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(length: 2, vsync: this);
  final ScrollController _desplazamiento = ScrollController();

  /// La combinación cuya vista previa se ve; nula: la lista de pendientes.
  HexPendienteEntity? _pendiente;

  /// D39: el lote del mes cuya vista previa se ve; tiene prioridad.
  CombinacionHex? _lote;

  /// El mes elegido para el lote; nulo: el más reciente con pendientes.
  ({int anio, int mes})? _mesLote;

  /// La planilla ejecutada que se ve; nula: la lista de ejecutadas.
  HexPlanillaEntity? _planilla;
  int _pagina = 1;

  /// Desde el primer toque de «Ejecutar planilla» hasta cerrar el PDF: un
  /// doble toque no abre dos confirmaciones.
  bool _ejecutando = false;

  /// Mientras se recargan P y W antes de confirmar (el botón lo muestra).
  bool _actualizando = false;

  bool get _enPendientes => _pestanas.index == 0;

  @override
  void initState() {
    super.initState();
    _pestanas.addListener(_alCambiarPestana);
  }

  @override
  void dispose() {
    _pestanas
      ..removeListener(_alCambiarPestana)
      ..dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _alCambiarPestana() {
    setState(() {});
    if (!_pestanas.indexIsChanging) _alInicio();
  }

  /// Al cambiar de vista, la pantalla vuelve arriba.
  void _alInicio() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _desplazamiento.hasClients) _desplazamiento.jumpTo(0);
    });
  }

  void _ver(VoidCallback cambio) {
    setState(cambio);
    _alInicio();
  }

  /// Ejecutó o la combinación ya no está (409): las dos listas cambiaron.
  void _trasEjecutar() {
    ref
      ..invalidate(hexPendientesProvider)
      ..invalidate(hexPlanillasProvider);
    if (mounted) {
      _ver(() {
        _pendiente = null;
        _lote = null;
      });
    }
  }

  /// Recarga la vista previa (con la espera en el botón), confirma con las
  /// cifras nuevas y ejecuta. La guarda se libera salga como salga.
  Future<void> _ejecutar(ResumenPreviaHex r, {required bool conPdf}) async {
    if (_ejecutando) return;
    setState(() => _ejecutando = _actualizando = true);
    try {
      final alDia = await resumenAlDiaHex(context, ref, r);
      if (!mounted) return;
      setState(() => _actualizando = false);
      if (alDia == null) return;
      await ejecutarPlanillaHex(
        context,
        ref,
        alDia,
        conPdf: conPdf,
        refrescar: _trasEjecutar,
      );
    } finally {
      if (mounted) setState(() => _ejecutando = _actualizando = false);
    }
  }

  /// Un solo desplazamiento para la pantalla; en el ancho las tablas van en
  /// cajas con el alto de sus filas, hasta el de la ventana.
  @override
  Widget build(BuildContext context) {
    // Se lee aquí, en `build`: la ejecución lo usa para ofrecer el PDF.
    final conPdf = tienePermisoDeBoton(ref, BotonHex.pdfPlanilla);
    return PrimaryScrollController(
      controller: _desplazamiento,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, c) {
            final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
            final anchoLista = c.maxWidth - 2 * relleno;
            final alto = math.max(
              c.maxHeight - 2 * relleno,
              hexAltoMinimoLista,
            );
            final abajo = MediaQuery.paddingOf(context).bottom;
            return PaginaDesplazableHex(
              controlador: _desplazamiento,
              relleno: relleno,
              abajo: abajo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EncabezadoHex(
                    titulo: 'Planilla de horas extra',
                    detalle:
                        anchoLista >= hexAnchoTabla
                            ? 'Revisa la vista previa del lote del mes, lo que '
                                'falta firmar, ejecútalo para congelar los '
                                'montos e imprime la planilla para pagar.'
                            : null,
                  ),
                  const SizedBox(height: Esp.m),
                  _barraPestanas(),
                  const SizedBox(height: Esp.l),
                  if (_enPendientes)
                    _porEjecutar(anchoLista, alto, conPdf: conPdf)
                  else
                    _ejecutadas(anchoLista, alto),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Las dos pestañas, con su ícono y cuántas hay; no se desplazan de lado.
  Widget _barraPestanas() => BarraPestanasHex(
    controlador: _pestanas,
    anchoMaximo: 480,
    pestanas: [
      pestanaHex(
        icono: Icons.pending_actions,
        texto: 'Por ejecutar',
        cuenta: ref.watch(hexPendientesProvider).valueOrNull?.length,
        tonoCuenta: TonoHex.pendiente,
      ),
      pestanaHex(
        icono: Icons.receipt_long,
        texto: 'Ejecutadas',
        cuenta: ref.watch(hexPlanillasProvider).valueOrNull?.length,
      ),
    ],
  );

  Widget _enCaja(Widget hijo) => SizedBox(height: hexAltoEstado, child: hijo);

  // ═════════════════════════════════════════════════════════════════════════
  // POR EJECUTAR
  // ═════════════════════════════════════════════════════════════════════════

  Widget _porEjecutar(double anchoLista, double alto, {required bool conPdf}) {
    final lote = _lote;
    if (lote != null) {
      return PrevistaHex(
        key: ValueKey(lote),
        combinacion: lote,
        nombreSucursal: 'Todas las sucursales con reportes aprobados',
        altoMaximo: alto,
        alVolver: () => _ver(() => _lote = null),
        actualizando: _actualizando,
        alEjecutar: _ejecutando ? null : (r) => _ejecutar(r, conPdf: conPdf),
      );
    }
    final p = _pendiente;
    final combinacion = p == null ? null : combinacionHex(p);
    if (p != null && combinacion != null) {
      return PrevistaHex(
        key: ValueKey(combinacion),
        combinacion: combinacion,
        nombreSucursal: sucursalHex(p.nombreSucursal, p.codSucursal),
        altoMaximo: alto,
        alVolver: () => _ver(() => _pendiente = null),
        actualizando: _actualizando,
        alEjecutar: _ejecutando ? null : (r) => _ejecutar(r, conPdf: conPdf),
      );
    }
    return ref
        .watch(hexPendientesProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => _enCaja(const EsqueletoLista()),
          error:
              (e, _) => _enCaja(
                vistaErrorHex(
                  e,
                  reintentar: () => ref.invalidate(hexPendientesProvider),
                ),
              ),
          data: (filas) => _pendientes(filas, anchoLista, alto),
        );
  }

  void _elegir(HexPendienteEntity p) {
    if (combinacionHex(p) != null) _ver(() => _pendiente = p);
  }

  String _empresa(BigInt? cod) =>
      cod == null ? '—' : nombreEmpresaHex(ref, cod);

  /// «Octubre de 2026» para una celda o el título de una tarjeta.
  static String _periodo(HexPendienteEntity p) {
    final texto = periodoHex(p.anio, p.mes);
    return texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
  }

  List<AccionHex> _accionesPendiente(HexPendienteEntity p) => [
    AccionHex('Ver vista previa', Icons.chevron_right, () => _elegir(p)),
  ];

  /// Los meses que se ofrecen para el lote: los que tienen pendientes y el
  /// actual, del más reciente al más antiguo.
  static List<({int anio, int mes})> _mesesLote(
    List<HexPendienteEntity> filas,
  ) {
    final hoy = DateTime.now();
    final meses =
        <({int anio, int mes})>{
            (anio: hoy.year, mes: hoy.month),
            for (final p in filas)
              if (p.anio > 0 && p.mes >= 1 && p.mes <= 12)
                (anio: p.anio, mes: p.mes),
          }.toList()
          ..sort(
            (a, b) =>
                a.anio != b.anio
                    ? b.anio.compareTo(a.anio)
                    : b.mes.compareTo(a.mes),
          );
    return meses;
  }

  /// El mes del lote: el elegido, o el más reciente con pendientes.
  ({int anio, int mes}) _mesElegido(List<HexPendienteEntity> filas) {
    final meses = _mesesLote(filas);
    final elegido = _mesLote;
    if (elegido != null && meses.contains(elegido)) return elegido;
    final conPendientes = [
      for (final m in meses)
        if (filas.any((p) => p.anio == m.anio && p.mes == m.mes)) m,
    ];
    return conPendientes.isNotEmpty ? conPendientes.first : meses.first;
  }

  Widget _pendientes(
    List<HexPendienteEntity> filas,
    double anchoLista,
    double alto,
  ) {
    final mes = _mesElegido(filas);
    final tarjetaLote = _LoteDelMesHex(
      meses: _mesesLote(filas),
      mes: mes,
      compacto: anchoLista < hexAnchoTabla,
      alElegir: (m) => setState(() => _mesLote = m),
      alVer: () => _ver(() => _lote = loteHex(mes.anio, mes.mes)),
    );
    final ancho = usaTablaHex(anchoLista, null);
    final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
    final lista = ListadoHex<HexPendienteEntity>(
      filas: filas,
      desplazamientoExterno: !ancho,
      alTocarFila: _elegir,
      vacio: const MensajeVacio(
        icono: Icons.task_alt,
        titulo: 'No hay planillas por ejecutar',
        detalle:
            'Aparecen aquí cuando un jefe de área aprueba reportes de un mes '
            'que aún no tiene planilla.',
      ),
      columnas: [
        BosqueColumn(
          label: 'Sucursal',
          flex: 3,
          cellBuilder:
              (p) => Text(
                sucursalHex(p.nombreSucursal, p.codSucursal),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
              ),
        ),
        BosqueColumn(
          label: 'Empresa',
          flex: 3,
          cellBuilder: (p) => Text(_empresa(p.codEmpresa)),
        ),
        BosqueColumn(
          label: 'Período',
          flex: 2,
          cellBuilder: (p) => Text(_periodo(p)),
        ),
        BosqueColumn(
          label: 'Reportes aprobados',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder:
              (p) => Text(enteroHex(p.cantidadReportes), style: cifras),
        ),
        BosqueColumn(
          label: '',
          flex: 1,
          alignment: Alignment.centerRight,
          cellBuilder: (p) => AccionesHex(acciones: _accionesPendiente(p)),
        ),
      ],
      tarjeta:
          (p) => TarjetaHex(
            titulo: sucursalHex(p.nombreSucursal, p.codSucursal),
            subtitulo: _empresa(p.codEmpresa),
            alTocar: () => _elegir(p),
            acciones: _accionesPendiente(p),
            contenido: Text(
              '${_periodo(p)} · '
              '${cuentaHex(p.cantidadReportes, 'reporte aprobado', 'reportes aprobados')}',
            ),
          ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tarjetaLote,
        const SizedBox(height: Esp.l),
        Text('Por sucursal', style: context.tituloSeccion()),
        const SizedBox(height: Esp.xs),
        Text(
          'O elige una sola sucursal y mes para revisar su vista previa.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.s),
        cajaTablaHex(
          tabla: ancho,
          filas: filas.length,
          maximo: alto,
          lista: lista,
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EJECUTADAS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _ejecutadas(double anchoLista, double alto) {
    final planillas = ref.watch(hexPlanillasProvider);
    final elegida = _planilla;
    if (elegida != null) {
      // La fila recién recargada, si llegó (por ejemplo, ya anulada).
      final fresca =
          planillas.valueOrNull
              ?.where((p) => p.idPlanilla == elegida.idPlanilla)
              .firstOrNull;
      return EjecutadaHex(
        key: ValueKey(elegida.idPlanilla),
        planilla: fresca ?? elegida,
        altoMaximo: alto,
        alVolver: () => _ver(() => _planilla = null),
      );
    }
    return planillas.when(
      skipLoadingOnReload: true,
      loading: () => _enCaja(const EsqueletoLista()),
      error:
          (e, _) => _enCaja(
            vistaErrorHex(
              e,
              reintentar: () => ref.invalidate(hexPlanillasProvider),
            ),
          ),
      data: (todas) => _planillasEjecutadas(todas, anchoLista, alto),
    );
  }

  void _abrir(HexPlanillaEntity p) => _ver(() => _planilla = p);

  List<AccionHex> _accionesPlanilla(HexPlanillaEntity p) => [
    AccionHex('Ver planilla', Icons.visibility_outlined, () => _abrir(p)),
    AccionHex(
      'Imprimir / PDF',
      Icons.picture_as_pdf_outlined,
      () => verPdfPlanillaHex(context, ref, p),
      boton: BotonHex.pdfPlanilla,
      tono: TonoHex.primario,
    ),
    // D39: el PDF del lote, con una sección por sucursal y el total general.
    if (p.idLote != null)
      AccionHex(
        'PDF del lote',
        Icons.library_books_outlined,
        () => verPdfLoteHex(context, ref, p),
        boton: BotonHex.pdfPlanilla,
      ),
  ];

  Widget _planillasEjecutadas(
    List<HexPlanillaEntity> todas,
    double anchoLista,
    double alto,
  ) {
    return ListaPlanillasHex(
      planillas: todas,
      pagina: _pagina,
      alCambiarPagina: (n) => _ver(() => _pagina = n),
      anchoLista: anchoLista,
      altoMaximo: alto,
      alTocarFila: _abrir,
      vacio: const MensajeVacio(
        icono: Icons.receipt_long_outlined,
        titulo: 'Aún no hay planillas ejecutadas',
        detalle:
            'Las planillas que ejecutes en «Por ejecutar» quedan aquí, con su '
            'PDF.',
      ),
      columnas: columnasPlanillasHex(context, ref, acciones: _accionesPlanilla),
      tarjeta:
          (p) => TarjetaPlanillaHex(
            p,
            acciones: _accionesPlanilla(p),
            principales: const {BotonHex.pdfPlanilla},
            alTocar: () => _abrir(p),
          ),
    );
  }
}

/// D39: el lote del mes. RRHH elige el mes y abre su vista previa: todas las
/// sucursales juntas, lo que falta firmar y «Ejecutar lote».
class _LoteDelMesHex extends StatelessWidget {
  const _LoteDelMesHex({
    required this.meses,
    required this.mes,
    required this.compacto,
    required this.alElegir,
    required this.alVer,
  });

  final List<({int anio, int mes})> meses;
  final ({int anio, int mes}) mes;
  final bool compacto;
  final ValueChanged<({int anio, int mes})> alElegir;
  final VoidCallback alVer;

  static String _texto(({int anio, int mes}) m) {
    final t = periodoHex(m.anio, m.mes);
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selector = DropdownButtonFormField<({int anio, int mes})>(
      value: mes,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Mes del lote',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final m in meses)
          DropdownMenuItem(
            value: m,
            child: Text(_texto(m), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (m) {
        if (m != null) alElegir(m);
      },
    );
    final ver = SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: alVer,
        icon: const Icon(Icons.layers_outlined, size: 18),
        label: const Text('Ver lote del mes'),
      ),
    );
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Lote del mes', style: context.tituloSeccion()),
        const SizedBox(height: Esp.xs),
        Text(
          'Ejecuta juntas todas las sucursales con reportes aprobados hasta '
          'ese mes. No se ejecuta mientras falte firmar algún reporte.',
          style: context.apagado(),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textos,
                  const SizedBox(height: Esp.m),
                  selector,
                  const SizedBox(height: Esp.m),
                  ver,
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 3, child: textos),
                  const SizedBox(width: Esp.l),
                  SizedBox(width: 240, child: selector),
                  const SizedBox(width: Esp.m),
                  ver,
                ],
              ),
    );
  }
}
