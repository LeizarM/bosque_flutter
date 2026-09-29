/// El costo de una familia y la grilla de precios que resulta: reemplaza a
/// `dlgVista` y `dlgVistaP`.
///
/// **El precio lo calcula el servidor:** "Calcular" pide la vista previa y
/// "Guardar" recalcula y graba (nunca se guarda un número calculado aquí), y se
/// apaga cuando el costo o un porcentaje deja de ser el de la grilla a la vista.
/// Los porcentajes de utilidad se editan en la grilla: "Calcular" manda los que
/// difieren del vigente y "Guardar" los registra en tpr_porcentaje en la misma
/// transacción que los precios.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/state/armado_propuesta_provider.dart';
import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/articulos_de_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_datos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_dialogos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';

/// Abre el editor. Devuelve la grilla guardada, o null si se cerró sin guardar.
///
/// Con [costoInicial] abre ya calculado (lo usa la carga en lote para "abrir en
/// el editor" una familia con costo ya escrito). Teléfono: hoja casi a pantalla
/// completa; escritorio: diálogo ancho y alto (la grilla es lo que se mira).
Future<CalculoFamiliaEntity?> abrirEditorFamilia(
  BuildContext context, {
  required int codigoFamilia,
  FamiliaVista? familia,
  double? costoInicial,
}) {
  final pantalla = MediaQuery.sizeOf(context);
  final editor = _EditorFamilia(
    codigoFamilia: codigoFamilia,
    familia: familia,
    compacto: pantalla.width < 600,
    costoInicial: costoInicial,
  );

  if (pantalla.width < 600) {
    return showModalBottomSheet<CalculoFamiliaEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FractionallySizedBox(heightFactor: 0.96, child: editor),
    );
  }
  return showDialog<CalculoFamiliaEntity>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => Dialog(
          insetPadding: const EdgeInsets.all(Esp.xl),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: pantalla.width < 1100 ? pantalla.width : 1040,
            height: pantalla.height * 0.88,
            child: editor,
          ),
        ),
  );
}

class _EditorFamilia extends ConsumerStatefulWidget {
  const _EditorFamilia({
    required this.codigoFamilia,
    required this.familia,
    required this.compacto,
    this.costoInicial,
  });

  final int codigoFamilia;
  final FamiliaVista? familia;
  final bool compacto;
  final double? costoInicial;

  @override
  ConsumerState<_EditorFamilia> createState() => _EditorFamiliaState();
}

class _EditorFamiliaState extends ConsumerState<_EditorFamilia> {
  final _costo = TextEditingController();
  final _foco = FocusNode();

  /// Lo escrito en la columna %, por lista de precio (idClasificacion). Nace con
  /// la primera grilla y sobrevive a los recálculos.
  final Map<BigInt, TextEditingController> _porcentajes = {};

  CalculoFamiliaEntity? _calculo;
  bool _calculando = true;
  String? _error;

  /// Que se ve debajo del costo: la grilla de listas o los articulos.
  _Vista _vista = _Vista.listas;

  @override
  void initState() {
    super.initState();
    _costo.addListener(() => setState(() {}));
    final inicial = widget.costoInicial;
    if (inicial != null && inicial > 0) {
      _costo.text = fmtMonto.format(inicial);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          inicial != null && inicial > 0
              ? _calcular()
              : _calcular(inicial: true),
    );
  }

  @override
  void dispose() {
    _costo.dispose();
    _foco.dispose();
    for (final ctrl in _porcentajes.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  double? get _costoEscrito => importeDesdeTexto(_costo.text);

  /// El campo de la lista, si se puede editar.
  TextEditingController? _campoDe(LineaArmadoEntity l) =>
      _porcentajeEditable(l) ? _porcentajes[l.idClasificacion] : null;

  /// Crea los campos de las listas nuevas y, tras calcular, alinea el texto con
  /// el porcentaje con el que se calculo -normalmente ya coinciden-.
  void _sincronizarPorcentajes(CalculoFamiliaEntity c) {
    for (final l in c.lineas) {
      if (!_porcentajeEditable(l)) continue;
      final ctrl = _porcentajes[l.idClasificacion];
      if (ctrl == null) {
        _porcentajes[l.idClasificacion] = TextEditingController(
          text: porcenEditable(l.porcentaje),
        )..addListener(_alEscribirPorcentaje);
        continue;
      }
      final escrito = porcenDesdeTexto(ctrl.text);
      if (escrito == null || !mismoPorcentaje(escrito, l.porcentaje)) {
        ctrl.text = porcenEditable(l.porcentaje);
      }
    }
  }

  void _alEscribirPorcentaje() {
    if (mounted) setState(() {});
  }

  /// Los porcentajes escritos que difieren del vigente, por lista. Null si
  /// alguno esta vacio o no es un margen posible: con eso no se calcula ni se
  /// guarda.
  Map<BigInt, double>? get _porcentajesPedidos {
    final c = _calculo;
    if (c == null) return const {};
    final r = <BigInt, double>{};
    for (final l in c.lineas) {
      final ctrl = _campoDe(l);
      if (ctrl == null) continue;
      final v = porcenDesdeTexto(ctrl.text);
      if (v == null || !_porcentajePosible(v)) return null;
      if (!mismoPorcentaje(v, l.porcentajeVigente)) r[l.idClasificacion] = v;
    }
    return r;
  }

  /// Los porcentajes escritos son con los que se calculo la grilla a la vista.
  bool get _porcentajesAlDia {
    final c = _calculo;
    if (c == null) return true;
    for (final l in c.lineas) {
      final ctrl = _campoDe(l);
      if (ctrl == null) continue;
      final v = porcenDesdeTexto(ctrl.text);
      if (v == null || !mismoPorcentaje(v, l.porcentaje)) return false;
    }
    return true;
  }

  /// Deja cada lista con el porcentaje vigente de la familia y, si la grilla ya
  /// estaba calculada, la recalcula (si no, "Guardar" quedaría apagado esperando).
  void _volverAVigentes() {
    final c = _calculo;
    if (c == null) return;
    for (final l in c.lineas) {
      _campoDe(l)?.text = porcenEditable(l.porcentajeVigente);
    }
    if (c.estaCalculada && (_costoEscrito ?? 0) > 0) _calcular();
  }

  /// Ningun papel cuesta menos de 50 dolares la tonelada: un costo asi es casi
  /// siempre un "1.020" tipeado con el punto de miles, que el lector de
  /// importes toma como decimal -es lo que manda el teclado del telefono-.
  bool get _costoSospechoso {
    final c = _costoEscrito;
    return c != null && c > 0 && c < 50;
  }

  /// La grilla a la vista se calculo con el costo que esta escrito.
  bool get _costoAlDia {
    final escrito = _costoEscrito;
    final calculado = _calculo?.costo;
    return escrito != null &&
        calculado != null &&
        (escrito - calculado).abs() < 0.00005;
  }

  /// La grilla a la vista es la del costo y los porcentajes escritos: lo que
  /// se guarda tiene que ser lo que se vio.
  bool get _grillaAlDia => _costoAlDia && _porcentajesAlDia;

  /// La primera vez se pide sin costo: el servidor usa el ya guardado en la
  /// propuesta, y si no hay devuelve la grilla solo con los precios vigentes.
  Future<void> _calcular({bool inicial = false}) async {
    final costo = inicial ? null : _costoEscrito;
    if (!inicial && (costo == null || costo <= 0)) {
      setState(() => _error = 'Escriba un costo por tonelada mayor a cero.');
      return;
    }
    final porcentajes = inicial ? null : _porcentajesPedidos;
    if (!inicial && porcentajes == null) {
      setState(
        () =>
            _error =
                'Revise los porcentajes marcados en rojo: cada uno tiene que '
                'ser un número mayor a -100 y hasta 1.000.',
      );
      return;
    }

    setState(() {
      _calculando = true;
      _error = null;
    });
    final r = await ref
        .read(armadoProvider.notifier)
        .calcularFamilia(
          widget.codigoFamilia,
          costo: costo,
          porcentajes: porcentajes,
        );
    if (!mounted) return;

    // Fuera del setState: cambiar el texto de un campo avisa a su oyente, que
    // a su vez pide dibujar.
    if (r.salio) _sincronizarPorcentajes(r.valor!);
    setState(() {
      _calculando = false;
      if (!r.salio) {
        _error = r.error;
        return;
      }
      _calculo = r.valor;
      if (inicial && r.valor!.costo != null) {
        _costo.text = fmtMonto.format(r.valor!.costo!);
      }
    });
    if (inicial && _calculo?.costo == null) _foco.requestFocus();
  }

  Future<void> _guardar() async {
    final calculo = _calculo;
    final costo = _costoEscrito;
    final porcentajes = _porcentajesPedidos;
    if (calculo == null ||
        costo == null ||
        porcentajes == null ||
        !_grillaAlDia) {
      return;
    }

    setState(() => _error = null);
    final r = await ref
        .read(armadoProvider.notifier)
        .guardarFamilia(widget.codigoFamilia, costo, porcentajes: porcentajes);
    if (!mounted) return;
    if (r.salio) {
      Navigator.of(context).pop(r.valor);
    } else {
      setState(() => _error = r.error);
    }
  }

  Future<void> _cerrar() async {
    // Solo se pregunta si hay un calculo nuevo o un porcentaje cambiado sin
    // guardar: cerrar despues de mirar no pierde nada.
    final preciosSinGuardar =
        _calculo != null &&
        _calculo!.estaCalculada &&
        _calculo!.lineasAEscribir > 0 &&
        !_calculo!.guardado;
    final pedidos = _porcentajesPedidos;
    final porcentajesSinGuardar = pedidos == null || pedidos.isNotEmpty;
    if (preciosSinGuardar || porcentajesSinGuardar) {
      final familia = widget.codigoFamilia;
      final salir = await confirmar(
        context,
        titulo: '¿Cerrar sin guardar?',
        detalle:
            preciosSinGuardar
                ? 'Los precios calculados para la familia $familia no se '
                    'guardaron en la propuesta'
                    '${porcentajesSinGuardar ? ', ni los porcentajes que cambió' : ''}.'
                : 'Los porcentajes que cambió para la familia $familia no se '
                    'guardaron.',
        textoConfirmar: 'Cerrar sin guardar',
        textoCancelar: 'Seguir editando',
        destructiva: true,
      );
      if (!salir || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ocupado = ref.watch(armadoProvider.select((e) => e.ocupado));
    final calculo = _calculo;
    final pedidos = _porcentajesPedidos;
    final grillaAlDia = _grillaAlDia;
    final articulos =
        ref
            .watch(
              articulosPorFamiliasProvider(
                ClaveFamilias([widget.codigoFamilia]),
              ),
            )
            .valueOrNull;

    return Material(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Cabecera(
            codigoFamilia: widget.codigoFamilia,
            familia: widget.familia,
            calculo: calculo,
            onCerrar: ocupado ? null : _cerrar,
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, 0),
            child: _Costo(
              controlador: _costo,
              foco: _foco,
              calculo: calculo,
              compacto: widget.compacto,
              calculando: _calculando,
              habilitado: !ocupado,
              onCalcular: () => _calcular(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: NotaDelDato(texto: _error!, tono: TonoNota.error),
            ),
          if (calculo != null && calculo.listasInactivas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: NotaDelDato(texto: _textoInactivas(calculo)),
            ),
          if (calculo != null && calculo.hayErrores)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: NotaDelDato(
                texto: _textoErrores(calculo.errores),
                tono: TonoNota.error,
              ),
            ),
          if (_costoSospechoso)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: NotaDelDato(
                texto:
                    'El costo quedó en USD ${fmtMonto.format(_costoEscrito!)} '
                    'por tonelada. Si quiso escribir miles, use la coma solo '
                    'para los decimales: 1.020 con un solo punto se lee como '
                    'uno con dos centésimos.',
                tono: TonoNota.aviso,
              ),
            ),
          if (pedidos == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Esp.l),
              child: NotaDelDato(
                texto:
                    'Hay porcentajes vacíos o fuera de rango, marcados en '
                    'rojo. Cada uno tiene que ser mayor a -100 y hasta 1.000.',
                tono: TonoNota.error,
              ),
            )
          else if (calculo != null && calculo.estaCalculada && !grillaAlDia)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: NotaDelDato(
                texto: _textoDesactualizada(),
                tono: TonoNota.aviso,
              ),
            )
          else if (calculo != null && calculo.porcentajesCambiados > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              child: _NotaPorcentajes(
                texto: _textoPorcentajesCambiados(calculo.porcentajesCambiados),
                compacto: widget.compacto,
                onVolver: ocupado || _calculando ? null : _volverAVigentes,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.s),
            child: _SelectorVista(
              vista: _vista,
              listas: calculo?.lineas.length,
              articulos: articulos?.length,
              compacto: widget.compacto,
              onCambiar: (v) => setState(() => _vista = v),
            ),
          ),
          Expanded(
            child:
                _vista == _Vista.articulos
                    ? _Articulos(
                      articulos: articulos,
                      compacto: widget.compacto,
                    )
                    : _Grilla(
                      calculo: calculo,
                      calculando: _calculando,
                      compacto: widget.compacto,
                      campoDe: _campoDe,
                      habilitado: !ocupado && !_calculando,
                      onEnviar: () => _calcular(),
                    ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          _Pie(
            calculo: calculo,
            puedeGuardar:
                calculo != null &&
                calculo.sePuedeGuardar &&
                pedidos != null &&
                grillaAlDia,
            ocupado: ocupado,
            compacto: widget.compacto,
            onCancelar: ocupado ? null : _cerrar,
            onGuardar: _guardar,
          ),
        ],
      ),
    );
  }

  /// Por que la grilla no tiene todas las listas de la familia: las inactivas
  /// no se reprecian, igual que en el sistema anterior.
  String _textoInactivas(CalculoFamiliaEntity c) {
    final n = c.listasInactivas.length;
    final nombres = c.listasInactivas.take(6).join(', ');
    final resto = n > 6 ? ' y ${n - 6} más' : '';
    final enPropuesta =
        c.lineasInactivas == 0
            ? ''
            : ' ${c.lineasInactivas == 1 ? 'Una de ellas ya estaba' : '${c.lineasInactivas} ya estaban'} '
                'en la propuesta: se muestra con su precio guardado, no se '
                'recalcula y al aprobar se aplica igual.';
    return '${n == 1 ? 'Una lista de esta familia está inactiva' : '$n listas de esta familia están inactivas'} '
        'y no se reprecian: $nombres$resto. Se activan en «Listas de precio».'
        '$enPropuesta';
  }

  /// Que cambio desde el ultimo calculo. Siempre termina en "Vuelva a
  /// calcular": es lo unico que hay que hacer.
  String _textoDesactualizada() {
    final costo = !_costoAlDia;
    final porcentajes = !_porcentajesAlDia;
    final que =
        costo && porcentajes
            ? 'Cambió el costo y porcentajes después de calcular.'
            : costo
            ? 'El costo escrito no es el de la grilla.'
            : 'Cambió porcentajes después de calcular.';
    return '$que Vuelva a calcular antes de guardar.';
  }

  String _textoPorcentajesCambiados(int n) =>
      n == 1
          ? 'Cambió el porcentaje de una lista. Al guardar queda registrado '
              'para la familia (también en «Porcentajes») y se usa desde ahora '
              'para calcular sus precios.'
          : 'Cambió el porcentaje de $n listas. Al guardar quedan registrados '
              'para la familia (también en «Porcentajes») y se usan desde '
              'ahora para calcular sus precios.';

  String _textoErrores(List<String> errores) {
    final primeros = errores.take(3).join('\n');
    final resto = errores.length - 3;
    return 'No se puede guardar: hay precios que quedan por debajo de la '
        'lista anterior de su sucursal.\n$primeros'
        '${resto > 0 ? '\n(y $resto más)' : ''}';
  }
}

// Cabecera

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.codigoFamilia,
    required this.familia,
    required this.calculo,
    required this.onCerrar,
  });

  final int codigoFamilia;
  final FamiliaVista? familia;
  final CalculoFamiliaEntity? calculo;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final descripcion = calculo?.descripcion ?? familia?.descripcion ?? '';
    final proveedor = calculo?.proveedor ?? familia?.proveedorSap ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Esp.s,
                  runSpacing: Esp.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Familia $codigoFamilia',
                      style: tt.titleMedium?.copyWith(fontWeight: Peso.dato),
                    ),
                    if (calculo?.enPropuesta ?? false)
                      const Etiqueta(
                        texto: 'Ya en la propuesta',
                        tono: TonoEtiqueta.exito,
                      ),
                  ],
                ),
                if (descripcion.isNotEmpty)
                  Text(
                    descripcion,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (proveedor.trim().isNotEmpty)
                  Text(
                    proveedor,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

// Costo

class _Costo extends StatelessWidget {
  const _Costo({
    required this.controlador,
    required this.foco,
    required this.calculo,
    required this.compacto,
    required this.calculando,
    required this.habilitado,
    required this.onCalcular,
  });

  final TextEditingController controlador;
  final FocusNode foco;
  final CalculoFamiliaEntity? calculo;
  final bool compacto;
  final bool calculando;
  final bool habilitado;
  final VoidCallback onCalcular;

  @override
  Widget build(BuildContext context) {
    final campo = TextField(
      controller: controlador,
      focusNode: foco,
      enabled: habilitado,
      textAlign: TextAlign.end,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onCalcular(),
      style: context.numero(fuerte: true),
      decoration: const InputDecoration(
        labelText: 'Costo propuesto',
        prefixText: 'USD ',
        suffixText: '/t',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );

    final boton = BotonAccion(
      etiqueta: 'Calcular',
      etiquetaOcupado: 'Calculando',
      icono: Icons.calculate_outlined,
      tonal: true,
      ocupado: calculando,
      onPressed: habilitado ? onCalcular : null,
    );

    final c = calculo;
    final datos = Wrap(
      spacing: Esp.l,
      runSpacing: Esp.xs,
      children: [
        _Dato(
          rotulo: 'Costo actual',
          valor:
              c == null || c.costoActual <= 0
                  ? '--'
                  : montoLegible(c.costoActual, moneda: 'USD'),
        ),
        if (c?.costoGuardado != null)
          _Dato(
            rotulo: 'Guardado en la propuesta',
            valor: montoLegible(c!.costoGuardado!, moneda: 'USD'),
          ),
        if (c != null && c.lineas.isNotEmpty)
          _Dato(
            rotulo: 'IVA + IT',
            valor:
                '${porcentajeLegible(c.lineas.first.iva)} + '
                '${porcentajeLegible(c.lineas.first.it)}',
          ),
      ],
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: campo),
              const SizedBox(width: Esp.s),
              boton,
            ],
          ),
          const SizedBox(height: Esp.s),
          datos,
        ],
      );
    }
    return Row(
      children: [
        SizedBox(width: 240, child: campo),
        const SizedBox(width: Esp.m),
        boton,
        const SizedBox(width: Esp.xl),
        Expanded(child: datos),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(rotulo, style: context.apagado()),
      Text(valor, style: context.numero(fuerte: true)),
    ],
  );
}

// Listas o artículos

enum _Vista { listas, articulos }

/// Las dos vistas del editor, con cuantas cosas tiene cada una.
class _SelectorVista extends StatelessWidget {
  const _SelectorVista({
    required this.vista,
    required this.listas,
    required this.articulos,
    required this.compacto,
    required this.onCambiar,
  });

  final _Vista vista;
  final int? listas;
  final int? articulos;
  final bool compacto;
  final ValueChanged<_Vista> onCambiar;

  @override
  Widget build(BuildContext context) {
    String cuenta(int? n) => n == null ? '' : ' ($n)';
    final selector = SegmentedButton<_Vista>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: _Vista.listas,
          icon: const Icon(Icons.price_change_outlined, size: 18),
          label: Text(
            '${compacto ? 'Listas' : 'Listas de precio'}${cuenta(listas)}',
          ),
        ),
        ButtonSegment(
          value: _Vista.articulos,
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: Text(
            '${compacto ? 'Artículos' : 'Artículos afectados'}${cuenta(articulos)}',
          ),
        ),
      ],
      selected: {vista},
      onSelectionChanged: (s) => onCambiar(s.first),
    );
    return compacto
        ? SizedBox(width: double.infinity, child: selector)
        : Align(alignment: Alignment.centerLeft, child: selector);
  }
}

class _Articulos extends StatelessWidget {
  const _Articulos({required this.articulos, required this.compacto});

  /// Null mientras se cargan.
  final List<ArticuloPrecioEntity>? articulos;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final lista = articulos;
    if (lista == null) return const EsqueletoLista(filas: 6, altoFila: 44);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lista.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.xs),
            child: Text(
              '${lista.length == 1 ? 'Este artículo cambia' : 'Estos ${lista.length} artículos cambian'} '
              'de precio con la familia. $textoPrecioDeArticulos',
              style: context.apagado(),
            ),
          ),
        Expanded(
          child: ListaArticulosFamilia(
            articulos: lista,
            compacto: compacto,
            relleno: const EdgeInsets.fromLTRB(Esp.l, Esp.xs, Esp.l, Esp.m),
          ),
        ),
      ],
    );
  }
}

// Grilla

/// Rebaja en el color principal, aumento en el de error: antes de aprobar se
/// mira cuánto SUBE un precio. Mismo criterio que la vista preliminar.
Color _colorVariacion(ColorScheme cs, LineaArmadoEntity l) {
  if (!l.estaCalculada || l.variacion.abs() < 0.005) return cs.onSurfaceVariant;
  return l.variacion > 0 ? cs.error : cs.primary;
}

/// Siempre con un decimal: con "hasta dos" una fila decia +18,3 % y la de
/// abajo +18,44 %, y la columna no se podia recorrer con la vista.
final NumberFormat _fmtVariacion = NumberFormat('#,##0.0', 'es');

String _variacionLegible(LineaArmadoEntity l) {
  if (!l.estaCalculada || l.precioActual == 0) return '--';
  final signo = l.variacionPorcentual > 0 ? '+' : '';
  return '$signo${_fmtVariacion.format(l.variacionPorcentual)} %';
}

/// Las listas inactivas no se recalculan: su porcentaje no se cambia aquí.
bool _porcentajeEditable(LineaArmadoEntity l) =>
    l.estado != EstadoLineaArmado.listaInactiva;

/// Los mismos limites que valida el servidor.
bool _porcentajePosible(double v) => v > -100 && v <= 1000;

TonoEtiqueta _tonoEstado(LineaArmadoEntity l) {
  if (l.fueraDeOrden) return TonoEtiqueta.error;
  return switch (l.estado) {
    EstadoLineaArmado.nueva => TonoEtiqueta.exito,
    EstadoLineaArmado.actualiza => TonoEtiqueta.aviso,
    _ => TonoEtiqueta.neutro,
  };
}

class _Grilla extends StatelessWidget {
  const _Grilla({
    required this.calculo,
    required this.calculando,
    required this.compacto,
    required this.campoDe,
    required this.habilitado,
    required this.onEnviar,
  });

  final CalculoFamiliaEntity? calculo;
  final bool calculando;
  final bool compacto;

  /// El campo del porcentaje de una lista; null si no se puede cambiar.
  final TextEditingController? Function(LineaArmadoEntity) campoDe;
  final bool habilitado;

  /// Enter en un porcentaje recalcula, como Enter en el costo.
  final VoidCallback onEnviar;

  /// El porcentaje de la lista: su campo o, si no se puede cambiar, el numero.
  Widget _porcentaje(BuildContext context, LineaArmadoEntity l) {
    final ctrl = campoDe(l);
    if (ctrl == null) {
      return celdaNumero(context, porcentajeLegible(l.porcentaje));
    }
    return _CampoPorcentajeLinea(
      controlador: ctrl,
      linea: l,
      habilitado: habilitado,
      onEnviar: onEnviar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = calculo;
    if (c == null) {
      return calculando
          ? const EsqueletoLista(filas: 8, altoFila: 44)
          : const MensajeVacio(
            icono: Icons.grid_off,
            titulo: 'No se pudo cargar la grilla',
            detalle: 'Revise el mensaje de arriba y vuelva a calcular.',
          );
    }
    if (c.lineas.isEmpty) {
      return const MensajeVacio(
        icono: Icons.price_change_outlined,
        titulo: 'La familia no tiene precios en ninguna lista activa',
        detalle:
            'Sin listas de precios no hay nada que repreciar. Revise las '
            'listas de precio de la familia.',
      );
    }

    final cs = Theme.of(context).colorScheme;

    if (compacto) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m),
        itemCount: c.lineas.length,
        itemBuilder: (context, i) {
          final l = c.lineas[i];
          return TarjetaPropuesta(
            titulo: 'Lista ${l.etiquetaLista}',
            subtitulo: l.nombreSucursal,
            etiqueta: Etiqueta(
              texto: l.fueraDeOrden ? 'Fuera de orden' : l.estado.etiqueta,
              tono: _tonoEstado(l),
            ),
            destacado: Row(
              children: [
                Expanded(
                  child: _Dato(
                    rotulo: 'Actual',
                    valor: fmtMonto.format(l.precioActual),
                  ),
                ),
                Icon(Icons.arrow_forward, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: _Dato(
                    rotulo: 'Propuesto',
                    valor:
                        l.estaCalculada
                            ? fmtMonto.format(l.precioCalculado!)
                            : '--',
                  ),
                ),
                Text(
                  _variacionLegible(l),
                  style: context.numero(
                    fuerte: true,
                    color: _colorVariacion(cs, l),
                  ),
                ),
              ],
            ),
            datos: [
              _FilaPorcentaje(
                linea: l,
                controlador: campoDe(l),
                campo: _porcentaje(context, l),
              ),
              FilaDeDato(
                rotulo: 'Flete',
                valor: montoLegible(l.flete, moneda: 'USD'),
              ),
              if (l.precioPropuestoGuardado != null)
                FilaDeDato(
                  rotulo: 'Guardado',
                  valor: fmtMonto.format(l.precioPropuestoGuardado!),
                ),
            ],
          );
        },
      );
    }

    // Los anchos suman 980 px con la columna Guardado: entran en el diálogo de 1040
    // menos su margen. Si se agrega una columna, achicar otra: el scroll lateral
    // esconde justo la columna que decide. El porcentaje es la más ancha de las
    // chicas porque es un campo.
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
      child: TablaPropuesta<LineaArmadoEntity>(
        filas: c.lineas,
        columnas: [
          ColumnaPropuesta(
            'Sucursal',
            160,
            (ctx, l) => celdaTexto(ctx, l.nombreSucursal),
            alinear: Alignment.centerLeft,
          ),
          ColumnaPropuesta(
            'Lista',
            140,
            (ctx, l) => celdaTexto(ctx, l.etiquetaLista),
            alinear: Alignment.centerLeft,
          ),
          ColumnaPropuesta(
            '% utilidad',
            92,
            _porcentaje,
            alinear: Alignment.center,
            ayuda:
                'Margen de la familia en esta lista. Puede cambiarlo aquí: '
                'al guardar queda registrado para la familia.',
          ),
          ColumnaPropuesta(
            'Flete',
            72,
            (ctx, l) => celdaNumero(ctx, fmtMonto.format(l.flete)),
            ayuda: 'Flete de la sucursal, en dólares por tonelada.',
          ),
          ColumnaPropuesta(
            'Actual',
            100,
            (ctx, l) => celdaNumero(ctx, fmtMonto.format(l.precioActual)),
            banda: 'Precio por tonelada (USD)',
          ),
          if (c.enPropuesta)
            ColumnaPropuesta(
              'Guardado',
              100,
              (ctx, l) => celdaNumero(
                ctx,
                l.precioPropuestoGuardado == null
                    ? '--'
                    : fmtMonto.format(l.precioPropuestoGuardado!),
              ),
              banda: 'Precio por tonelada (USD)',
              ayuda: 'Lo que ya estaba propuesto para esta lista.',
            ),
          ColumnaPropuesta(
            'Propuesto',
            108,
            (ctx, l) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (l.fueraDeOrden) ...[
                  Icon(Icons.error_outline, size: 16, color: cs.error),
                  const SizedBox(width: Esp.xs),
                ],
                celdaNumero(
                  ctx,
                  l.estaCalculada ? fmtMonto.format(l.precioCalculado!) : '--',
                  fuerte: true,
                  color: l.fueraDeOrden ? cs.error : null,
                ),
              ],
            ),
            banda: 'Precio por tonelada (USD)',
          ),
          ColumnaPropuesta(
            'Variación',
            84,
            (ctx, l) => celdaNumero(
              ctx,
              _variacionLegible(l),
              color: _colorVariacion(cs, l),
            ),
          ),
          ColumnaPropuesta(
            'Al guardar',
            124,
            (ctx, l) => Etiqueta(
              texto: l.fueraDeOrden ? 'Fuera de orden' : l.estado.etiqueta,
              tono: _tonoEstado(l),
            ),
            alinear: Alignment.centerLeft,
          ),
        ],
      ),
    );
  }
}

/// El porcentaje de una lista, editable en la misma grilla. Resaltado en el
/// color terciario si difiere del vigente -eso es lo que se va a registrar- y
/// en rojo si no es un margen posible.
class _CampoPorcentajeLinea extends StatelessWidget {
  const _CampoPorcentajeLinea({
    required this.controlador,
    required this.linea,
    required this.habilitado,
    required this.onEnviar,
  });

  final TextEditingController controlador;
  final LineaArmadoEntity linea;
  final bool habilitado;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = porcenDesdeTexto(controlador.text);
    final invalido = v == null || !_porcentajePosible(v);
    final cambiado = !invalido && !mismoPorcentaje(v, linea.porcentajeVigente);

    final borde =
        invalido ? cs.error : (cambiado ? cs.tertiary : cs.outlineVariant);
    final ayuda =
        invalido
            ? 'Escriba un porcentaje mayor a -100 y hasta 1.000.'
            : cambiado
            ? 'Vigente: ${porcentajeLegible(linea.porcentajeVigente)}. Al '
                'guardar se registra el nuevo para la familia.'
            : 'Margen de la familia en esta lista. Puede cambiarlo aquí.';

    return Tooltip(
      message: ayuda,
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: controlador,
          enabled: habilitado,
          textAlign: TextAlign.end,
          // Con signo: un margen negativo es raro pero existe, igual que en
          // «Porcentajes».
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onEnviar(),
          style: context.numero(
            fuerte: cambiado,
            color:
                invalido
                    ? cs.error
                    : (cambiado ? cs.onTertiaryContainer : null),
          ),
          decoration: InputDecoration(
            isDense: true,
            // Siempre con fondo: sobre las filas rayadas un campo sin relleno
            // se confunde con el renglon y no parece que se pueda escribir.
            filled: true,
            fillColor:
                invalido
                    ? cs.errorContainer.withValues(alpha: 0.5)
                    : (cambiado
                        ? cs.tertiaryContainer
                        : cs.surfaceContainerLowest),
            suffixText: '%',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Esp.s,
              vertical: Esp.s,
            ),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borde,
                width: cambiado || invalido ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: invalido ? cs.error : cs.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Que los porcentajes cambiados se van a registrar, con la salida para
/// deshacerlos. En el telefono el boton va debajo: al lado dejaba el texto en
/// una columna de tres palabras.
class _NotaPorcentajes extends StatelessWidget {
  const _NotaPorcentajes({
    required this.texto,
    required this.compacto,
    required this.onVolver,
  });

  final String texto;
  final bool compacto;
  final VoidCallback? onVolver;

  @override
  Widget build(BuildContext context) {
    final boton = TextButton.icon(
      onPressed: onVolver,
      icon: const Icon(Icons.undo_rounded, size: 18),
      label: const Text('Volver a los vigentes'),
    );
    if (!compacto) {
      return NotaDelDato(
        icono: Icons.percent_rounded,
        texto: texto,
        accion: boton,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NotaDelDato(icono: Icons.percent_rounded, texto: texto),
        Align(alignment: Alignment.centerRight, child: boton),
      ],
    );
  }
}

/// El porcentaje en la tarjeta del telefono: el rotulo, el campo y, si se
/// cambio, cuanto era.
class _FilaPorcentaje extends StatelessWidget {
  const _FilaPorcentaje({
    required this.linea,
    required this.controlador,
    required this.campo,
  });

  final LineaArmadoEntity linea;
  final TextEditingController? controlador;
  final Widget campo;

  @override
  Widget build(BuildContext context) {
    final v =
        controlador == null
            ? linea.porcentaje
            : porcenDesdeTexto(controlador!.text);
    final cambiado =
        v != null &&
        _porcentajePosible(v) &&
        !mismoPorcentaje(v, linea.porcentajeVigente);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('% de utilidad', style: context.apagado()),
                if (cambiado)
                  Text(
                    'Vigente: ${porcentajeLegible(linea.porcentajeVigente)}',
                    style: context.apagado(),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 116,
            child:
                controlador == null
                    ? Align(alignment: Alignment.centerRight, child: campo)
                    : campo,
          ),
        ],
      ),
    );
  }
}

// Pie

class _Pie extends StatelessWidget {
  const _Pie({
    required this.calculo,
    required this.puedeGuardar,
    required this.ocupado,
    required this.compacto,
    required this.onCancelar,
    required this.onGuardar,
  });

  final CalculoFamiliaEntity? calculo;
  final bool puedeGuardar;
  final bool ocupado;
  final bool compacto;
  final VoidCallback? onCancelar;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final c = calculo;
    final String resumen;
    if (c == null || !c.estaCalculada) {
      resumen = 'Escriba el costo y toque Calcular.';
    } else {
      final partes = [
        if (c.lineasNuevas > 0) '${c.lineasNuevas} se agregan',
        if (c.lineasActualizadas > 0) '${c.lineasActualizadas} se actualizan',
        if (c.lineasSinCambio > 0) '${c.lineasSinCambio} sin cambio',
        if (c.porcentajesCambiados > 0)
          c.porcentajesCambiados == 1
              ? '1 porcentaje nuevo'
              : '${c.porcentajesCambiados} porcentajes nuevos',
      ];
      resumen = partes.isEmpty ? 'Nada que guardar.' : partes.join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.s, Esp.l, Esp.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              resumen,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.apagado(),
            ),
          ),
          if (!compacto) ...[
            TextButton(onPressed: onCancelar, child: const Text('Cancelar')),
            const SizedBox(width: Esp.s),
          ],
          BotonAccion(
            etiqueta: 'Guardar',
            etiquetaOcupado: 'Guardando',
            icono: Icons.save_outlined,
            ocupado: ocupado,
            onPressed: puedeGuardar ? onGuardar : null,
          ),
        ],
      ),
    );
  }
}
