/// Los filtros de la grilla de cheques: empresa, sucursal, nro de cheque,
/// cliente, tipo, estado, banco, fechas y orden. En escritorio van todos a la
/// vista; en movil, la empresa y la sucursal siempre y el resto detras de un
/// boton que dice cuantos hay aplicados.
///
/// Empresa, sucursal y orden se aplican al elegirlos (cambian lo que se mira, no
/// que se busca); el resto, con «Buscar». La empresa la puede cambiar cualquier
/// usuario, como en el legacy; la sucursal, solo con `btnChqSucrs`. Las
/// sucursales que se ofrecen son las de la empresa elegida.
///
/// «Recibido desde» y «Recibido hasta» abren con los ultimos tres meses (los
/// pone la grilla); se pueden cambiar o quitar, y sin fechas se piden todos los
/// cheques. Con «desde» posterior a «hasta» el campo lo dice y «Buscar» queda
/// apagado. [RangoActivoCheques] dice, bajo los filtros, que rango se esta
/// mostrando.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart'
    show obtenerBancos;
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/rango_recepcion_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/lista_cheques.dart'
    show anchoMinimoTabla;
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

class FiltrosCheques extends ConsumerStatefulWidget {
  const FiltrosCheques({super.key});

  @override
  ConsumerState<FiltrosCheques> createState() => _FiltrosChequesState();
}

class _FiltrosChequesState extends ConsumerState<FiltrosCheques> {
  final _nro = TextEditingController();
  final _cliente = TextEditingController();
  String? _tipo;
  String? _estado;
  int? _banco;
  DateTime? _fechaCobro;
  DateTime? _recibidoDesde;
  DateTime? _recibidoHasta;

  /// En movil, el panel de filtros desplegado.
  bool _abierto = false;

  @override
  void initState() {
    super.initState();
    // Al volver del detalle los filtros que estaban aplicados reaparecen.
    final f = ref.read(grillaChequesProvider).filtro;
    _nro.text = f.nroCheque ?? '';
    _cliente.text = f.cliente ?? '';
    _tipo = f.tipo;
    _estado = f.estado;
    _banco = f.codBanco;
    _fechaCobro = f.fechaCobro;
    _recibidoDesde = f.fechaRecepcionDesde;
    _recibidoHasta = f.fechaRecepcionHasta;
  }

  @override
  void dispose() {
    _nro.dispose();
    _cliente.dispose();
    super.dispose();
  }

  GrillaChequesNotifier get _grilla =>
      ref.read(grillaChequesProvider.notifier);

  /// El motivo por el que el rango escrito no sirve, o null. El servidor tambien
  /// lo rechazaria (400): se dice aqui para no esperar la respuesta.
  String? get _errorRango =>
      (_recibidoDesde != null &&
              _recibidoHasta != null &&
              _recibidoHasta!.isBefore(_recibidoDesde!))
          ? 'No puede ser anterior a «Recibido desde».'
          : null;

  void _buscar() {
    if (_errorRango != null) return;
    _grilla.aplicarCriterios(
      nroCheque: _nro.text,
      cliente: _cliente.text,
      tipo: _tipo,
      estado: _estado,
      codBanco: _banco,
      fechaCobro: _fechaCobro,
      fechaRecepcionDesde: _recibidoDesde,
      fechaRecepcionHasta: _recibidoHasta,
    );
  }

  /// Quita todo y vuelve al rango de recepcion por defecto (no a «todos»).
  void _limpiar() {
    final r = _grilla.rangoPorDefecto;
    setState(() {
      _nro.clear();
      _cliente.clear();
      _tipo = null;
      _estado = null;
      _banco = null;
      _fechaCobro = null;
      _recibidoDesde = r.desde;
      _recibidoHasta = r.hasta;
    });
    _grilla.limpiarCriterios();
  }

  /// Los criterios aplicados cambiaron por fuera de este panel («Quitar
  /// filtros» o «Ver todos» del listado vacio): los campos los siguen.
  void _traerAplicados(ChequeFiltroEntity f) {
    setState(() {
      if (_nro.text.trim() != (f.nroCheque ?? '')) {
        _nro.text = f.nroCheque ?? '';
      }
      if (_cliente.text.trim() != (f.cliente ?? '')) {
        _cliente.text = f.cliente ?? '';
      }
      _tipo = f.tipo;
      _estado = f.estado;
      _banco = f.codBanco;
      _fechaCobro = f.fechaCobro;
      _recibidoDesde = f.fechaRecepcionDesde;
      _recibidoHasta = f.fechaRecepcionHasta;
    });
  }

  static bool _mismosCriterios(ChequeFiltroEntity a, ChequeFiltroEntity b) =>
      a.nroCheque == b.nroCheque &&
      a.cliente == b.cliente &&
      a.tipo == b.tipo &&
      a.estado == b.estado &&
      a.codBanco == b.codBanco &&
      a.fechaCobro == b.fechaCobro &&
      a.fechaRecepcionDesde == b.fechaRecepcionDesde &&
      a.fechaRecepcionHasta == b.fechaRecepcionHasta;

  /// Cuantos criterios estan **aplicados** (los del servidor, no los que se
  /// estan escribiendo). Las dos fechas de recepcion cuentan como uno, y solo si
  /// no son el rango por defecto: ese ya viene puesto y no lo eligio el usuario.
  int _aplicados(ChequeFiltroEntity f) {
    final r = _grilla.rangoPorDefecto;
    final rangoPropio =
        f.tieneRangoRecepcion &&
        !(f.fechaRecepcionDesde == r.desde && f.fechaRecepcionHasta == r.hasta);
    return [
          f.nroCheque,
          f.cliente,
          f.tipo,
          f.estado,
          f.codBanco,
          f.fechaCobro,
        ].where((c) => c != null).length +
        (rangoPropio ? 1 : 0);
  }

  /// Vuelve a pedir la lista de empresas y, si la pantalla no llego a abrir
  /// (esa lista es lo primero que necesita), la abre.
  void _reintentarEmpresas() {
    ref.invalidate(empresasChequeProvider);
    if (!ref.read(grillaChequesProvider).iniciado) _grilla.iniciar();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChequeFiltroEntity>(
      grillaChequesProvider.select((s) => s.filtro),
      (previo, nuevo) {
        if (previo == null || !_mismosCriterios(previo, nuevo)) {
          _traerAplicados(nuevo);
        }
      },
    );

    final grilla = ref.watch(grillaChequesProvider);
    final permisos = ref.watch(permisosChequeProvider);
    final catalogos = ref.watch(catalogosChequeProvider).valueOrNull;
    final bancos = ref.watch(obtenerBancos).valueOrNull ?? const <BancoEntity>[];
    final asyncEmpresas = ref.watch(empresasChequeProvider);
    final empresas =
        asyncEmpresas.valueOrNull ?? const <EmpresaChequeEntity>[];
    final empresaActiva = ref.watch(empresaChequeActivaProvider);
    final sucursales = ref.watch(sucursalesChequeActivasProvider);

    final empresa = _CampoEmpresa(
      codEmpresa: empresaActiva?.codEmpresa ?? 0,
      empresas: empresas,
      cargando: asyncEmpresas.isLoading,
      onElegir: _grilla.elegirEmpresa,
    );
    final sucursal = _CampoSucursal(
      codSucursal: grilla.codSucursal,
      sucursales: sucursales,
      habilitado: permisos.puedeElegirSucursal,
      onElegir: _grilla.elegirSucursal,
    );

    // El fallo de la lista de empresas se dice aparte: el combo solo no explica
    // por que esta vacio.
    final errorEmpresas =
        asyncEmpresas.hasError && !asyncEmpresas.isLoading
            ? NotaDelDato(
              key: const ValueKey('error-empresas'),
              tono: TonoNota.error,
              texto:
                  'No se pudo cargar la lista de empresas: '
                  '${mensajeDeErrorCheque(asyncEmpresas.error!)}',
              accion: TextButton(
                onPressed: _reintentarEmpresas,
                child: const Text('Reintentar'),
              ),
            )
            : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chico = constraints.maxWidth < anchoMinimoTabla;

        final campos = _campos(
          context,
          grilla: grilla,
          tipos: catalogos?.tiposCheque ?? const [],
          estados: catalogos?.estadosCheque ?? const [],
          bancos: bancos,
          ancho: chico ? double.infinity : null,
        );

        if (chico) {
          return _Movil(
            empresa: empresa,
            sucursal: sucursal,
            aviso: errorEmpresas,
            campos: campos,
            botones: _botones(grilla),
            orden: grilla.filtro.orden,
            onOrden: _grilla.cambiarOrden,
            aplicados: _aplicados(grilla.filtro),
            abierto: _abierto,
            onAlternar: () => setState(() => _abierto = !_abierto),
          );
        }

        final cs = Theme.of(context).colorScheme;
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: _tinteFiltros(cs),
          shape: contornoSuperficie(cs),
          child: Padding(
            padding: const EdgeInsets.all(Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CabeceraFiltros(aplicados: _aplicados(grilla.filtro)),
                const SizedBox(height: Esp.m),
                if (errorEmpresas != null) ...[
                  errorEmpresas,
                  const SizedBox(height: Esp.m),
                ],
                Wrap(
                  spacing: Esp.m,
                  runSpacing: Esp.m,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 200, child: empresa),
                    SizedBox(width: 240, child: sucursal),
                    ...campos,
                    _Orden(
                      orden: grilla.filtro.orden,
                      onCambio: _grilla.cambiarOrden,
                    ),
                    ..._botones(grilla),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Buscar y Limpiar. Sin sucursal no hay nada que buscar.
  List<Widget> _botones(EstadoGrillaCheques grilla) => [
    FilledButton.icon(
      onPressed: (grilla.haySucursal && _errorRango == null) ? _buscar : null,
      icon: const Icon(Icons.search, size: 18),
      label: const Text('Buscar'),
    ),
    TextButton.icon(
      onPressed: _limpiar,
      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
      label: const Text('Limpiar'),
    ),
  ];

  /// Los campos de busqueda. Con [ancho] null cada uno tiene su ancho propio
  /// (escritorio); con `double.infinity` ocupan todo el renglon (movil).
  List<Widget> _campos(
    BuildContext context, {
    required EstadoGrillaCheques grilla,
    required List<OpcionChequeEntity> tipos,
    required List<OpcionChequeEntity> estados,
    required List<BancoEntity> bancos,
    required double? ancho,
  }) {
    Widget caja(double anchoPropio, Widget hijo) => SizedBox(
      width: ancho ?? anchoPropio,
      child: hijo,
    );

    final bancoValido =
        _banco != null && bancos.any((b) => b.codBanco == _banco) ? _banco : null;

    return [
      caja(
        180,
        TextField(
          key: const ValueKey('filtro-nro'),
          controller: _nro,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _buscar(),
          decoration: const InputDecoration(
            labelText: 'Nro. de cheque',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ),
      caja(
        240,
        TextField(
          key: const ValueKey('filtro-cliente'),
          controller: _cliente,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _buscar(),
          decoration: const InputDecoration(
            labelText: 'Cliente',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ),
      caja(
        170,
        _Desplegable<String>(
          clave: 'filtro-tipo',
          etiqueta: 'Tipo',
          valor: _tipo,
          opciones: [for (final o in tipos) (o.codigo, o.nombre)],
          onCambio: (v) => setState(() => _tipo = v),
        ),
      ),
      caja(
        170,
        _Desplegable<String>(
          clave: 'filtro-estado',
          etiqueta: 'Estado',
          valor: _estado,
          opciones: [for (final o in estados) (o.codigo, o.nombre)],
          onCambio: (v) => setState(() => _estado = v),
        ),
      ),
      caja(
        220,
        _Desplegable<int>(
          clave: 'filtro-banco',
          etiqueta: 'Banco',
          valor: bancoValido,
          opciones: [for (final b in bancos) (b.codBanco, b.nombre)],
          onCambio: (v) => setState(() => _banco = v),
        ),
      ),
      caja(
        200,
        _FechaFiltro(
          etiqueta: 'Fecha de cobro',
          valor: _fechaCobro,
          onCambio: (f) => setState(() => _fechaCobro = f),
        ),
      ),
      ..._camposDeRecepcion(ancho: ancho),
    ];
  }

  /// «Recibido desde» y «Recibido hasta». En escritorio van juntos, en un solo
  /// bloque que el renglon no parte; en movil, uno sobre otro, a todo el ancho.
  List<Widget> _camposDeRecepcion({required double? ancho}) {
    final desde = CampoFechaCheque(
      key: const ValueKey('filtro-recibido-desde'),
      etiqueta: 'Recibido desde',
      valor: _recibidoDesde,
      obligatorio: false,
      permiteQuitar: true,
      onCambio: (f) => setState(() => _recibidoDesde = f),
    );
    final hasta = CampoFechaCheque(
      key: const ValueKey('filtro-recibido-hasta'),
      etiqueta: 'Recibido hasta',
      valor: _recibidoHasta,
      obligatorio: false,
      permiteQuitar: true,
      error: _errorRango,
      onCambio: (f) => setState(() => _recibidoHasta = f),
    );
    // En movil cada campo es un renglon.
    if (ancho != null) return [desde, hasta];
    return [
      SizedBox(
        width: 200 * 2 + Esp.s,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: desde),
            const SizedBox(width: Esp.s),
            Expanded(child: hasta),
          ],
        ),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA DE LA SUPERFICIE
// ═══════════════════════════════════════════════════════════════════════════

/// La superficie de los filtros: la de las demas tarjetas con un tinte apenas
/// perceptible del primario, para que se lea como la zona de busqueda.
Color _tinteFiltros(ColorScheme cs) => Color.alphaBlend(
  cs.primary.withValues(alpha: 0.04),
  cs.surfaceContainerLow,
);

/// El rotulo «Filtros» y, cuando hay alguno aplicado, cuantos son. **Solo
/// informa**: no se toca (la pastilla no es un boton) y no cuenta el rango de
/// recepcion que ya viene puesto por defecto.
class _CabeceraFiltros extends StatelessWidget {
  const _CabeceraFiltros({required this.aplicados});

  final int aplicados;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              'Filtros',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: Peso.dato),
            ),
          ],
        ),
        if (aplicados > 0)
          PastillaCheque(
            key: const ValueKey('filtros-activos'),
            texto: aplicados == 1 ? '1 filtro activo' : '$aplicados filtros activos',
            tono: SemanticaCheque.info,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOVIL
// ═══════════════════════════════════════════════════════════════════════════

/// La empresa y la sucursal siempre a la vista (una sobre la otra: la sucursal
/// depende de la empresa) y el resto detras de un boton que avisa cuantos
/// filtros hay aplicados.
class _Movil extends StatelessWidget {
  const _Movil({
    required this.empresa,
    required this.sucursal,
    required this.aviso,
    required this.campos,
    required this.botones,
    required this.orden,
    required this.onOrden,
    required this.aplicados,
    required this.abierto,
    required this.onAlternar,
  });

  final Widget empresa;
  final Widget sucursal;

  /// El error de la lista de empresas, si lo hay.
  final Widget? aviso;
  final List<Widget> campos;
  final List<Widget> botones;
  final OrdenCheques orden;
  final ValueChanged<OrdenCheques> onOrden;
  final int aplicados;
  final bool abierto;
  final VoidCallback onAlternar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: _tinteFiltros(cs),
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CabeceraFiltros(aplicados: aplicados),
            const SizedBox(height: Esp.m),
            if (aviso != null) ...[aviso!, const SizedBox(height: Esp.m)],
            empresa,
            const SizedBox(height: Esp.m),
            Row(
              children: [
                Expanded(child: sucursal),
                const SizedBox(width: Esp.xs),
                IconButton(
                  tooltip: abierto ? 'Ocultar filtros' : 'Mostrar filtros',
                  isSelected: abierto,
                  onPressed: onAlternar,
                  icon: Badge(
                    isLabelVisible: aplicados > 0,
                    label: Text('$aplicados'),
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child:
                  abierto
                      ? Padding(
                        padding: const EdgeInsets.only(top: Esp.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final c in campos) ...[
                              c,
                              const SizedBox(height: Esp.m),
                            ],
                            _Orden(orden: orden, onCambio: onOrden, ancho: true),
                            const SizedBox(height: Esp.m),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: Esp.s,
                              runSpacing: Esp.s,
                              children: botones,
                            ),
                          ],
                        ),
                      )
                      : const SizedBox(width: double.infinity),
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

/// La empresa de trabajo, como el combo «Empresa» del legacy: cualquier usuario
/// puede cambiarla. De ella salen las sucursales de abajo y, al registrar, la
/// empresa del cheque. [codEmpresa] 0 = todavia sin resolver.
class _CampoEmpresa extends StatelessWidget {
  const _CampoEmpresa({
    required this.codEmpresa,
    required this.empresas,
    required this.cargando,
    required this.onElegir,
  });

  final int codEmpresa;
  final List<EmpresaChequeEntity> empresas;
  final bool cargando;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context) {
    final hay = empresas.any((e) => e.codEmpresa == codEmpresa);
    return KeyedSubtree(
      key: const ValueKey('combo-empresa'),
      child: DropdownButtonFormField<int>(
        key: ValueKey('filtro-empresa-$codEmpresa-${empresas.length}'),
        value: hay ? codEmpresa : null,
        isExpanded: true,
        items: [
          for (final e in empresas)
            DropdownMenuItem<int>(
              value: e.codEmpresa,
              child: Text(e.nombre, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged:
            empresas.isEmpty
                ? null
                : (v) {
                  if (v != null && v != codEmpresa) onElegir(v);
                },
        hint: Text(cargando ? 'Cargando…' : 'Sin empresas'),
        decoration: const InputDecoration(
          labelText: 'Empresa',
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// La sucursal de trabajo, de la empresa elegida. Solo se puede cambiar con
/// `btnChqSucrs`; sin el se muestra la propia, bloqueada.
class _CampoSucursal extends StatelessWidget {
  const _CampoSucursal({
    required this.codSucursal,
    required this.sucursales,
    required this.habilitado,
    required this.onElegir,
  });

  final int codSucursal;
  final List<SucursalChequeEntity> sucursales;
  final bool habilitado;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context) {
    // Una sucursal que la lista no trae (todavia llegando, o fuera de la
    // empresa) igual se muestra: sin item el desplegable fallaria.
    final hay = sucursales.any((s) => s.codSucursal == codSucursal);
    final items = [
      for (final s in sucursales)
        DropdownMenuItem<int>(
          value: s.codSucursal,
          child: Text(s.nombre, overflow: TextOverflow.ellipsis),
        ),
      if (codSucursal > 0 && !hay)
        DropdownMenuItem<int>(
          value: codSucursal,
          child: Text('Sucursal $codSucursal'),
        ),
    ];

    return KeyedSubtree(
      key: const ValueKey('combo-sucursal'),
      child: DropdownButtonFormField<int>(
        key: ValueKey('filtro-sucursal-$codSucursal-${items.length}'),
        value: codSucursal > 0 ? codSucursal : null,
        isExpanded: true,
        items: items,
        onChanged:
            habilitado && items.isNotEmpty
                ? (v) {
                  if (v != null && v != codSucursal) onElegir(v);
                }
                : null,
        hint: const Text('Elige una sucursal'),
        decoration: InputDecoration(
          labelText: 'Sucursal',
          isDense: true,
          border: const OutlineInputBorder(),
          prefixIcon:
              habilitado ? null : const Icon(Icons.lock_outline, size: 16),
        ),
      ),
    );
  }
}

/// Un desplegable con la opcion «Todos» (valor null) adelante.
class _Desplegable<T> extends StatelessWidget {
  const _Desplegable({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onCambio,
  });

  final String clave;
  final String etiqueta;
  final T? valor;
  final List<(T, String)> opciones;
  final ValueChanged<T?> onCambio;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      key: ValueKey('$clave-$valor-${opciones.length}'),
      value: valor,
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Todos')),
        for (final (v, texto) in opciones)
          DropdownMenuItem<T?>(
            value: v,
            child: Text(texto, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onCambio,
      decoration: InputDecoration(
        labelText: etiqueta,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Una fecha de filtro: abre el calendario y se puede quitar.
class _FechaFiltro extends StatelessWidget {
  const _FechaFiltro({
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
  });

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> onCambio;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Esquina.chica),
      onTap: () async {
        final hoy = DateTime.now();
        final elegida = await showDatePicker(
          context: context,
          initialDate: valor ?? hoy,
          firstDate: DateTime(2000),
          lastDate: DateTime(hoy.year + 5),
          helpText: etiqueta,
        );
        if (elegida != null) onCambio(elegida);
      },
      child: InputDecorator(
        isEmpty: valor == null,
        decoration: InputDecoration(
          labelText: etiqueta,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon:
              valor == null
                  ? const Icon(Icons.event_outlined, size: 18)
                  : IconButton(
                    tooltip: 'Quitar $etiqueta',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onCambio(null),
                  ),
        ),
        child: Text(
          valor == null ? '' : textoFecha(valor),
          style: const TextStyle(fontFeatures: cifrasTabulares),
        ),
      ),
    );
  }
}

/// «Ordenar por»: recepcion o fecha de cobro.
class _Orden extends StatelessWidget {
  const _Orden({required this.orden, required this.onCambio, this.ancho = false});

  final OrdenCheques orden;
  final ValueChanged<OrdenCheques> onCambio;

  /// En movil el selector ocupa todo el renglon.
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final selector = SegmentedButton<OrdenCheques>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: OrdenCheques.recepcion, label: Text('Recepción')),
        ButtonSegment(value: OrdenCheques.cobro, label: Text('Cobro')),
      ],
      selected: {orden},
      onSelectionChanged: (s) => onCambio(s.first),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ordenar por', style: context.apagado()),
        const SizedBox(height: Esp.xs),
        ancho ? SizedBox(width: double.infinity, child: selector) : selector,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RANGO ACTIVO
// ═══════════════════════════════════════════════════════════════════════════

/// Una linea discreta bajo los filtros que dice que recepcion se esta
/// mostrando («Mostrando cheques recibidos del 03/07/2026 al 03/10/2026»), para
/// que nadie piense que faltan los cheques viejos. Habla de lo **aplicado** (lo
/// que pidio la grilla), no de lo que se esta escribiendo en los campos. Sin
/// sucursal no hay listado y no se dibuja.
class RangoActivoCheques extends ConsumerWidget {
  const RangoActivoCheques({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (haySucursal, desde, hasta) = ref.watch(
      grillaChequesProvider.select(
        (s) => (
          s.haySucursal,
          s.filtro.fechaRecepcionDesde,
          s.filtro.fechaRecepcionHasta,
        ),
      ),
    );
    if (!haySucursal) return const SizedBox.shrink();

    const tono = SemanticaCheque.info;
    final texto = ChequesColores.texto(context, tono);
    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          key: const ValueKey('rango-activo'),
          decoration: BoxDecoration(
            color: ChequesColores.fondo(context, tono),
            borderRadius: BorderRadius.circular(Esquina.pastilla),
            border: Border.all(
              color: ChequesColores.pleno(context, tono).withValues(alpha: 0.30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range_outlined, size: 16, color: texto),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    textoRangoRecepcion(desde, hasta),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: texto,
                      fontWeight: Peso.titulo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
