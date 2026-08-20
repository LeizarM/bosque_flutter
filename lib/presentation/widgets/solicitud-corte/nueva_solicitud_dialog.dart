/// Nueva solicitud de servicio de corte.
///
/// Solo el tipo ESPECIAL: el "Serv. Corte Estandar" del sistema anterior esta
/// comentado en produccion desde 2025 y no se genera mas.
///
/// El formulario tiene dos partes: la cabecera —fecha y observacion— y los
/// items a cortar, que se agregan de a uno. En el sistema anterior la tabla
/// nacia con diez filas vacias y habia que adivinar cuales contaban; aqui se
/// agrega lo que hay y se ve el total actualizado.
library;

import 'package:bosque_flutter/core/state/solicitud_corte_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/item_sap_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:bosque_flutter/presentation/widgets/solicitud-corte/diagrama_corte.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La empresa por la que se emite. El sistema anterior la tenia fija en 1
/// ("por default y de momento"); se conserva hasta que exista mas de una.
const _codEmpresaPorDefecto = 1;

/// Abre el formulario. Devuelve true si se registro la solicitud.
Future<bool> abrirNuevaSolicitud(BuildContext context) async {
  final creada = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const NuevaSolicitudDialog(),
  );
  return creada ?? false;
}

class NuevaSolicitudDialog extends ConsumerStatefulWidget {
  const NuevaSolicitudDialog({super.key});

  @override
  ConsumerState<NuevaSolicitudDialog> createState() =>
      _NuevaSolicitudDialogState();
}

class _NuevaSolicitudDialogState extends ConsumerState<NuevaSolicitudDialog> {
  final _obsCtrl = TextEditingController();
  DateTime _fechaSolicitud = DateTime.now();
  final List<CcrSolicitudDetalleEntity> _items = [];
  bool _guardando = false;

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _total =>
      _items.fold(0.0, (t, i) => t + i.cantToneladasSolicitados);

  Future<void> _agregarItem() async {
    final nuevo = await showDialog<CcrSolicitudDetalleEntity>(
      context: context,
      builder: (_) => _ItemDialog(
        buscar: (texto) => ref
            .read(solicitudCorteRepositoryProvider)
            .buscarItemsSap(texto: texto),
        totalCatalogo: ref.read(totalItemsSapProvider).valueOrNull ?? 0,
        yaElegidos: _items.map((i) => i.codigoSAPBase).toSet(),
      ),
    );
    if (nuevo != null) setState(() => _items.add(nuevo));
  }

  Future<void> _guardar() async {
    final obs = _obsCtrl.text.trim();

    if (obs.length < 3 || obs.length > 200) {
      avisar(
        context,
        'La observacion debe tener entre 3 y 200 caracteres.',
        esError: true,
      );
      return;
    }
    if (_items.isEmpty) {
      avisar(context, 'Agregue al menos un item a cortar.', esError: true);
      return;
    }

    final usuario = ref.read(userProvider);
    final codUsuario = usuario?.codUsuario ?? 0;

    final cabecera = CcrSolicitudEntity(
      idSolicitud: 0,
      codEmpresa: _codEmpresaPorDefecto,
      numeracion: 0, // lo calcula el SP
      tipoSolicitud: 'ESP',
      fechaSolicitud: _fechaSolicitud,
      idSolicitante: codUsuario,
      datoSolicitante: usuario?.nombreCompleto ?? '',
      estado: 'SOL',
      observacion: obs,
      totalToneladas: _total,
      audUsuario: codUsuario,
    );

    setState(() => _guardando = true);
    try {
      final id = await ref
          .read(solicitudCorteRepositoryProvider)
          .registrarSolicitud(solicitud: cabecera, detalle: _items);
      if (!mounted) return;
      avisar(context, 'Solicitud de corte registrada (Nro interno $id).');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, e.toString(), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Solo para poder decir entre cuantos items se busca; el catalogo no se
    // descarga.
    ref.watch(totalItemsSapProvider);

    return LayoutBuilder(
      builder: (context, restricciones) {
        final aire = Aire.de(restricciones.maxWidth);

        return Dialog(
          insetPadding: EdgeInsets.all(aire.esChico ? Esp.s : Esp.xxl),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.m, Esp.l),
                  color: cs.surfaceContainerHigh,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nueva solicitud de corte',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: Peso.titulo),
                            ),
                            Text(
                              'Servicio de corte especial. El numero lo asigna '
                              'el sistema al guardar.',
                              style: context.apagado(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                        onPressed: _guardando
                            ? null
                            : () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: ListView(
                    padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.xl),
                    children: [
                      _CampoFecha(
                        fecha: _fechaSolicitud,
                        onCambio: (f) => setState(() => _fechaSolicitud = f),
                      ),
                      SizedBox(height: Esp.m),
                      TextField(
                        controller: _obsCtrl,
                        maxLines: 2,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Observacion',
                          helperText:
                              'Que hay que cortar y para que. Lo lee planta.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: Esp.l),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Items a cortar',
                              style: context.tituloSeccion(),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _guardando ? null : _agregarItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar item'),
                          ),
                        ],
                      ),
                      SizedBox(height: Esp.m),

                      if (_items.isEmpty)
                        Container(
                          padding: EdgeInsets.all(Esp.l),
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outlineVariant),
                            borderRadius: BorderRadius.circular(Esquina.media),
                          ),
                          child: Text(
                            'Todavia no hay items. Agregue el papel a cortar '
                            'con sus medidas de salida.',
                            style: context.apagado(),
                          ),
                        )
                      else
                        for (var i = 0; i < _items.length; i++)
                          _FilaItem(
                            item: _items[i],
                            onQuitar: _guardando
                                ? null
                                : () => setState(() => _items.removeAt(i)),
                          ),

                      if (_items.isNotEmpty) ...[
                        SizedBox(height: Esp.m),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Total solicitado  ', style: context.apagado()),
                            Text(
                              '${fmtNumero.format(_total)} kg',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: Peso.dato,
                                    fontFeatures: cifrasTabulares,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Esp.l),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _guardando
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      SizedBox(width: Esp.s),
                      FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          _guardando ? 'Guardando…' : 'Registrar solicitud',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UN ITEM YA AGREGADO
// ═══════════════════════════════════════════════════════════════════════════

class _FilaItem extends StatelessWidget {
  const _FilaItem({required this.item, required this.onQuitar});

  final CcrSolicitudDetalleEntity item;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: Esp.s),
      padding: EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiagramaCorte(
            anchoBase: item.anchoSAPBase,
            largoBase: item.largoSAPBase,
            anchoSalida: item.anchoSalidaEsp,
            largoSalida: item.largoSalidaEsp,
            compacto: true,
          ),
          SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.codigoSAPBase,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: Peso.dato,
                    fontFeatures: cifrasTabulares,
                  ),
                ),
                Text(
                  item.datoSAPBase,
                  style: context.apagado(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Esp.s),
                Wrap(
                  spacing: Esp.l,
                  runSpacing: Esp.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Dato(
                      etiqueta: 'Corte',
                      valor:
                          '${fmtNumero.format(item.anchoSalidaEsp)} × '
                          '${fmtNumero.format(item.largoSalidaEsp)} cm',
                    ),
                    _Dato(
                      etiqueta: 'Cortes',
                      valor: fmtEntero.format(item.nroCortes),
                    ),
                    _Dato(
                      etiqueta: 'Hojas/resma',
                      valor: fmtEntero.format(item.cantHojasSalidaEsp),
                    ),
                    _Dato(
                      etiqueta: 'Kilos',
                      valor: fmtNumero.format(item.cantToneladasSolicitados),
                    ),
                    _Dato(
                      etiqueta: 'Paquetes',
                      valor: fmtNumero.format(item.cantPaquetesSolicitados),
                    ),
                    EtiquetaEntrega(entrega: item.fechaEntrega),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Quitar item',
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$etiqueta ', style: context.apagado()),
      Text(valor, style: context.numero(fuerte: true)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AGREGAR UN ITEM
// ═══════════════════════════════════════════════════════════════════════════

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({
    required this.buscar,
    required this.totalCatalogo,
    required this.yaElegidos,
  });

  /// Busca en el servidor. El catalogo no viaja entero.
  final Future<List<ItemSapEntity>> Function(String texto) buscar;

  final int totalCatalogo;
  final Set<String> yaElegidos;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  ItemSapEntity? _item;

  /// Lo ultimo que se tipeo, para descartar respuestas que llegan tarde.
  String _consultaActual = '';

  /// Los ultimos resultados buenos: se devuelven cuando una consulta quedo
  /// obsoleta, para que la lista no parpadee a vacio mientras se escribe.
  List<ItemSapEntity> _ultimos = const [];

  bool _buscando = false;

  /// Busca con freno: no una consulta por tecla, sino una cuando se deja de
  /// escribir. Sin esto "BOND 75" serian siete viajes al servidor.
  Future<Iterable<ItemSapEntity>> _buscarConFreno(TextEditingValue v) async {
    final q = v.text.trim();
    _consultaActual = q;

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (_consultaActual != q) return _ultimos;

    if (mounted) setState(() => _buscando = true);
    final r = await widget.buscar(q);
    if (!mounted) return _ultimos;
    setState(() => _buscando = false);

    // Llego tarde: ya se escribio otra cosa.
    if (_consultaActual != q) return _ultimos;

    _ultimos = r;
    return r;
  }

  final _kilosCtrl = TextEditingController();
  final _anchoCtrl = TextEditingController();
  final _largoCtrl = TextEditingController();
  final _cortesCtrl = TextEditingController();
  final _hojasCtrl = TextEditingController();
  DateTime? _fechaEntrega;

  @override
  void dispose() {
    for (final c in [
      _kilosCtrl,
      _anchoCtrl,
      _largoCtrl,
      _cortesCtrl,
      _hojasCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _n0 => double.tryParse(_kilosCtrl.text) ?? 0;
  double get _ancho => double.tryParse(_anchoCtrl.text) ?? 0;
  double get _largo => double.tryParse(_largoCtrl.text) ?? 0;
  int get _cortes => int.tryParse(_cortesCtrl.text) ?? 0;
  int get _hojas => int.tryParse(_hojasCtrl.text) ?? 0;

  /// Los paquetes que salen, en vivo: es el numero que el solicitante quiere
  /// ver antes de confirmar.
  double get _paquetes => _item == null
      ? 0
      : CcrSolicitudDetalleEntity.calcularPaquetes(
          cantidad: _n0,
          gramaje: _item!.gramaje,
          ancho: _ancho,
          largo: _largo,
          cantHojas: _hojas.toDouble(),
        );

  /// La validacion del sistema anterior, en el mismo orden.
  String? get _problema {
    if (_item == null) return 'Seleccione el papel a cortar.';
    if (widget.yaElegidos.contains(_item!.codItem)) {
      return 'Ese item ya esta en la solicitud.';
    }
    if (_n0 <= 0) return 'La cantidad a cortar debe ser mayor a cero.';
    if (_ancho <= 0) return 'El ancho a cortar debe ser mayor a cero.';
    if (_largo <= 0) return 'El largo a cortar debe ser mayor a cero.';
    if (_cortes <= 0) return 'La cantidad de cortes debe ser mayor a cero.';
    if (_hojas <= 0) return 'Las hojas por resma deben ser mayor a cero.';
    if (_fechaEntrega == null) return 'Indique la fecha de entrega.';
    if (!_fechaEntrega!.isAfter(DateTime.now())) {
      return 'La fecha de entrega debe ser posterior a hoy.';
    }
    if (_item!.datoFabricante.isEmpty ||
        _item!.empaque.isEmpty ||
        _item!.datoTipo.isEmpty) {
      return 'El item no tiene fabricante, empaque o tipo cargados en SAP.';
    }
    return null;
  }

  void _aceptar() {
    final problema = _problema;
    if (problema != null) {
      avisar(context, problema, esError: true);
      return;
    }
    Navigator.pop(
      context,
      CcrSolicitudDetalleEntity.desdeItemSap(
        _item!,
        cantToneladasSolicitados: _n0,
        anchoSalidaEsp: _ancho,
        largoSalidaEsp: _largo,
        cantHojasSalidaEsp: _hojas,
        nroCortes: _cortes,
        fechaEntrega: _fechaEntrega!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar item a cortar'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // La busqueda la resuelve el servidor y devuelve unas decenas de
              // items. Antes se descargaba el catalogo entero —~1.500 items,
              // 550 KB— cada vez que se abria este formulario.
              Autocomplete<ItemSapEntity>(
                displayStringForOption: (i) => i.etiqueta,
                optionsMaxHeight: 300,
                optionsBuilder: _buscarConFreno,
                onSelected: (i) => setState(() => _item = i),
                fieldViewBuilder: (ctx, control, foco, _) => TextField(
                  controller: control,
                  focusNode: foco,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Papel a cortar',
                    helperText: widget.totalCatalogo > 0
                        ? 'Escriba codigo o descripcion. '
                              '${fmtEntero.format(widget.totalCatalogo)} items '
                              'en el catalogo.'
                        : 'Escriba codigo o descripcion.',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _buscando
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              if (_item != null) ...[
                SizedBox(height: Esp.s),
                _FichaItem(item: _item!),
              ],
              SizedBox(height: Esp.m),

              Row(
                children: [
                  Expanded(
                    child: _Num(
                      control: _anchoCtrl,
                      etiqueta: 'Ancho salida (cm)',
                      onCambio: () => setState(() {}),
                    ),
                  ),
                  SizedBox(width: Esp.m),
                  Expanded(
                    child: _Num(
                      control: _largoCtrl,
                      etiqueta: 'Largo salida (cm)',
                      onCambio: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Esp.m),
              Row(
                children: [
                  Expanded(
                    child: _Num(
                      control: _cortesCtrl,
                      etiqueta: 'Nro. de cortes',
                      enteros: true,
                      onCambio: () => setState(() {}),
                    ),
                  ),
                  SizedBox(width: Esp.m),
                  Expanded(
                    child: _Num(
                      control: _hojasCtrl,
                      etiqueta: 'Hojas por resma',
                      enteros: true,
                      onCambio: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Esp.m),
              Row(
                children: [
                  Expanded(
                    child: _Num(
                      control: _kilosCtrl,
                      etiqueta: 'Kilos a cortar',
                      onCambio: () => setState(() {}),
                    ),
                  ),
                  SizedBox(width: Esp.m),
                  Expanded(
                    child: _CampoFecha(
                      fecha: _fechaEntrega,
                      etiqueta: 'Fecha de entrega',
                      primera: DateTime.now().add(const Duration(days: 1)),
                      onCambio: (f) => setState(() => _fechaEntrega = f),
                    ),
                  ),
                ],
              ),

              // El corte dibujado, en vivo: es la confirmacion de que lo que se
              // esta pidiendo es lo que se queria pedir.
              if (_item != null && _ancho > 0 && _largo > 0) ...[
                SizedBox(height: Esp.m),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Esp.m),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(Esquina.chica),
                  ),
                  child: DiagramaCorte(
                    anchoBase: _item!.ancho,
                    largoBase: _item!.largo,
                    anchoSalida: _ancho,
                    largoSalida: _largo,
                  ),
                ),
              ],

              if (_paquetes > 0) ...[
                SizedBox(height: Esp.m),
                _Calculado(paquetes: _paquetes),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _aceptar, child: const Text('Agregar')),
      ],
    );
  }
}

/// Lo que SAP sabe del item elegido: se muestra para confirmar que es el papel
/// correcto antes de pedir el corte.
class _FichaItem extends StatelessWidget {
  const _FichaItem({required this.item});

  final ItemSapEntity item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Wrap(
        spacing: Esp.l,
        runSpacing: Esp.xs,
        children: [
          _Dato(etiqueta: 'Gramaje', valor: fmtNumero.format(item.gramaje)),
          _Dato(etiqueta: 'Formato', valor: item.formato),
          _Dato(etiqueta: 'Empaque', valor: item.empaque),
          _Dato(etiqueta: 'Marca', valor: item.datoFabricante),
          _Dato(
            etiqueta: 'Stock',
            valor: fmtNumero.format(item.cantidadDisponible),
          ),
        ],
      ),
    );
  }
}

class _Calculado extends StatelessWidget {
  const _Calculado({required this.paquetes});

  final double paquetes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, size: 18, color: cs.onPrimaryContainer),
          SizedBox(width: Esp.s),
          Text(
            'Salen ${fmtNumero.format(paquetes)} paquetes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPOS
// ═══════════════════════════════════════════════════════════════════════════

class _Num extends StatelessWidget {
  const _Num({
    required this.control,
    required this.etiqueta,
    required this.onCambio,
    this.enteros = false,
  });

  final TextEditingController control;
  final String etiqueta;
  final VoidCallback onCambio;
  final bool enteros;

  @override
  Widget build(BuildContext context) => TextField(
    controller: control,
    keyboardType: TextInputType.numberWithOptions(decimal: !enteros),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        enteros ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
      ),
    ],
    style: context.numero(fuerte: true),
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    onChanged: (_) => onCambio(),
  );
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.fecha,
    required this.onCambio,
    this.etiqueta = 'Fecha de la solicitud',
    this.primera,
  });

  final DateTime? fecha;
  final ValueChanged<DateTime> onCambio;
  final String etiqueta;
  final DateTime? primera;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();

    return InkWell(
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha ?? primera ?? hoy,
          firstDate: primera ?? DateTime(hoy.year - 1),
          lastDate: DateTime(hoy.year + 2, 12, 31),
        );
        if (elegida != null) onCambio(elegida);
      },
      borderRadius: BorderRadius.circular(Esquina.chica),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(fechaCorta(fecha), style: context.numero(fuerte: true)),
      ),
    );
  }
}
