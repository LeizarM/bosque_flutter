/// Los filtros del catálogo de familias. En web van a la vista; en teléfono, en
/// un panel plegable cerrado al inicio que muestra en el título cuántos criterios
/// hay puestos (para no olvidar un filtro). Los combos muestran también lo
/// inactivo (con sufijo), a diferencia de los del formulario: hay familias que
/// apuntan a un color o presentación dados de baja y no se podrían encontrar.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Ancho de cada combo en escritorio. Entra "Grupo de familia SAP" sin cortarse
/// y caben cuatro por renglon en 1080 px de cajon.
const double _anchoCombo = 210;

class FiltrosFamilias extends ConsumerStatefulWidget {
  const FiltrosFamilias({
    super.key,
    required this.filtro,
    required this.onFiltro,
    required this.busqueda,
    required this.onBusqueda,
    required this.compacto,
  });

  /// Criterios que viajan al backend.
  final FiltroFamilias filtro;
  final ValueChanged<FiltroFamilias> onFiltro;

  /// Texto libre que se aplica del lado del cliente sobre lo ya descargado.
  final String busqueda;
  final ValueChanged<String> onBusqueda;

  final bool compacto;

  @override
  ConsumerState<FiltrosFamilias> createState() => _FiltrosFamiliasState();
}

class _FiltrosFamiliasState extends ConsumerState<FiltrosFamilias> {
  late final TextEditingController _codigo;
  late final TextEditingController _buscador;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(
      text: widget.filtro.codigoFamilia?.toString() ?? '',
    );
    _buscador = TextEditingController(text: widget.busqueda);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _codigo.dispose();
    _buscador.dispose();
    super.dispose();
  }

  /// El codigo dispara una consulta al backend, asi que no se manda por tecla:
  /// escribir "1204" serian cuatro consultas y las tres primeras se descartan.
  void _codigoConEspera(String texto) {
    _reloj?.cancel();
    _reloj = Timer(const Duration(milliseconds: 450), () {
      final limpio = texto.trim();
      if (limpio.isEmpty) {
        widget.onFiltro(widget.filtro.copyWith(limpiarCodigoFamilia: true));
        return;
      }
      final valor = int.tryParse(limpio);
      // Un cero SI filtra -por cero- y devuelve la lista vacia. Se trata como
      // "sin criterio", que es lo que la persona quiso decir.
      if (valor == null || valor <= 0) {
        widget.onFiltro(widget.filtro.copyWith(limpiarCodigoFamilia: true));
        return;
      }
      widget.onFiltro(widget.filtro.copyWith(codigoFamilia: valor));
    });
  }

  void _limpiar() {
    _reloj?.cancel();
    _codigo.clear();
    _buscador.clear();
    widget.onBusqueda('');
    widget.onFiltro(filtroFamiliasInicial);
  }

  /// Cuántos criterios hay puestos, para el título del panel plegable de móvil:
  /// un filtro olvidado en un panel cerrado explicaría una lista vacía. El estado
  /// cuenta solo si se apartó del inicial ("Activas" es el valor de arranque).
  int get _criteriosPuestos {
    final f = widget.filtro;
    return [
          f.codigoFamilia,
          f.idGrpFamiliaSap,
          f.idProveedorSap,
          f.idPresentacion,
          f.idTipo,
          f.idRangoGram,
          f.idColor,
        ].where((c) => c != null).length +
        (f.estado == filtroFamiliasInicial.estado ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return widget.compacto ? _movil(context) : _escritorio(context);
  }

  // Escritorio: todo a la vista

  /// Todo en `Wrap` y nada en `Row` con `Spacer`: entre 600 y 1000 px de cajón
  /// (tablet o ventana a media pantalla) buscador, estado y botón de limpiar
  /// suman más que el ancho y una fila rígida desborda.
  Widget _escritorio(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: Esp.m,
        runSpacing: Esp.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 320, child: _campoBuscador()),
          _estado(),
          if (_criteriosPuestos > 0 || widget.busqueda.isNotEmpty)
            TextButton.icon(
              onPressed: _limpiar,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Limpiar filtros'),
            ),
        ],
      ),
      const SizedBox(height: Esp.m),
      Wrap(spacing: Esp.m, runSpacing: Esp.m, children: _combos()),
    ],
  );

  // Móvil: buscador afuera, criterios adentro

  Widget _movil(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final puestos = _criteriosPuestos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campoBuscador(),
        const SizedBox(height: Esp.s),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            // Arranca abierto solo si ya hay criterios puestos: si no, lo que
            // interesa es la lista y no la maquinaria para acotarla.
            initiallyExpanded: puestos > 0,
            tilePadding: const EdgeInsets.symmetric(horizontal: Esp.m),
            childrenPadding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m),
            leading: Icon(
              Icons.filter_alt_outlined,
              color: cs.onSurfaceVariant,
            ),
            title: Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle:
                puestos == 0
                    ? null
                    : Text(
                      puestos == 1
                          ? '1 criterio aplicado'
                          : '$puestos criterios aplicados',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: Peso.titulo,
                      ),
                    ),
            children: [
              _estado(),
              const SizedBox(height: Esp.m),
              for (final combo in _combos()) ...[
                SizedBox(width: double.infinity, child: combo),
                const SizedBox(height: Esp.m),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: puestos == 0 ? null : _limpiar,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Piezas

  Widget _campoBuscador() => TextField(
    controller: _buscador,
    onChanged: widget.onBusqueda,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      isDense: true,
      border: const OutlineInputBorder(),
      prefixIcon: const Icon(Icons.search, size: 18),
      hintText: 'Buscar en lo listado…',
      helperText: 'Filtra sobre las familias ya descargadas',
      suffixIcon:
          widget.busqueda.isEmpty
              ? null
              : IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Borrar la búsqueda',
                onPressed: () {
                  _buscador.clear();
                  widget.onBusqueda('');
                },
              ),
    ),
  );

  Widget _estado() => SegmentedButton<int?>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: null, label: Text('Todas')),
      ButtonSegment(value: 1, label: Text('Activas')),
      ButtonSegment(value: 0, label: Text('Inactivas')),
    ],
    selected: <int?>{widget.filtro.estado},
    onSelectionChanged: (s) {
      final elegido = s.first;
      widget.onFiltro(
        elegido == null
            ? widget.filtro.copyWith(limpiarEstado: true)
            : widget.filtro.copyWith(estado: elegido),
      );
    },
  );

  List<Widget> _combos() {
    final grupos = ref.watch(gruposFamiliaSapProvider);
    final proveedores = ref.watch(proveedoresSapComboProvider);
    final presentaciones = ref.watch(presentacionesProvider);
    final tipos = ref.watch(tiposProductoProvider);
    final rangos = ref.watch(rangosGramajeComboProvider);
    final colores = ref.watch(coloresProvider);
    final f = widget.filtro;

    return [
      _Envoltura(compacto: widget.compacto, child: _campoCodigo()),
      _Envoltura(
        compacto: widget.compacto,
        child: _combo(
          etiqueta: 'Grupo de familia SAP',
          lista: grupos,
          valor: f.idGrpFamiliaSap,
          id: (g) => g.idGrpFamiliaSap,
          rotulo: (g) => g.nombreVisible,
          onElegir:
              (v) => widget.onFiltro(
                v == null
                    ? f.copyWith(limpiarGrupoFamilia: true)
                    : f.copyWith(idGrpFamiliaSap: v),
              ),
        ),
      ),
      _Envoltura(
        compacto: widget.compacto,
        child: _combo(
          etiqueta: 'Proveedor SAP',
          lista: proveedores,
          valor: f.idProveedorSap,
          id: (p) => p.idProveedorSap,
          rotulo: (p) => p.nombreLegible,
          onElegir:
              (v) => widget.onFiltro(
                v == null
                    ? f.copyWith(limpiarProveedor: true)
                    : f.copyWith(idProveedorSap: v),
              ),
        ),
      ),
      _Envoltura(
        compacto: widget.compacto,
        child: _combo(
          etiqueta: 'Presentación',
          lista: presentaciones,
          valor: f.idPresentacion,
          id: (p) => p.idPresentacion,
          rotulo: (p) => p.nombreLegible,
          activo: (p) => p.esActiva,
          onElegir:
              (v) => widget.onFiltro(
                v == null
                    ? f.copyWith(limpiarPresentacion: true)
                    : f.copyWith(idPresentacion: v),
              ),
        ),
      ),
      _Envoltura(
        compacto: widget.compacto,
        child: _combo(
          etiqueta: 'Tipo',
          lista: tipos,
          valor: f.idTipo,
          id: (t) => t.idTipo,
          rotulo: (t) => t.nombreLegible,
          activo: (t) => t.esActivo,
          onElegir:
              (v) => widget.onFiltro(
                v == null
                    ? f.copyWith(limpiarTipo: true)
                    : f.copyWith(idTipo: v),
              ),
        ),
      ),
      _Envoltura(
        compacto: widget.compacto,
        child: _combo(
          etiqueta: 'Rango de gramaje',
          lista: rangos,
          valor: f.idRangoGram,
          id: (r) => r.idRangoGram,
          rotulo: (r) => r.rangoLegible,
          onElegir:
              (v) => widget.onFiltro(
                v == null
                    ? f.copyWith(limpiarRangoGram: true)
                    : f.copyWith(idRangoGram: v),
              ),
        ),
      ),
      _Envoltura(
        compacto: widget.compacto,
        child: _combo(
          etiqueta: 'Color',
          lista: colores,
          valor: f.idColor,
          id: (c) => c.idColor,
          rotulo: (c) => c.nombreVisible,
          activo: (c) => c.esActivo,
          onElegir:
              (v) => widget.onFiltro(
                v == null
                    ? f.copyWith(limpiarColor: true)
                    : f.copyWith(idColor: v),
              ),
        ),
      ),
    ];
  }

  Widget _campoCodigo() => TextField(
    controller: _codigo,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: _codigoConEspera,
    decoration: const InputDecoration(
      isDense: true,
      border: OutlineInputBorder(),
      labelText: 'Código de familia',
      hintText: 'Exacto',
    ),
  );

  /// Un combo de catalogo. [activo] es null cuando esa tabla no tiene columna de
  /// estado (grupos de familia, proveedores y rangos de gramaje no la tienen).
  Widget _combo<T>({
    required String etiqueta,
    required AsyncValue<List<T>> lista,
    required BigInt? valor,
    required BigInt Function(T) id,
    required String Function(T) rotulo,
    required ValueChanged<BigInt?> onElegir,
    bool Function(T)? activo,
  }) {
    final opciones = lista.maybeWhen(
      data:
          (datos) => [
            const DropdownMenuEntry<BigInt?>(value: null, label: 'Todos'),
            for (final d in datos)
              DropdownMenuEntry<BigInt?>(
                value: id(d),
                label:
                    activo != null && !activo(d)
                        ? '${rotulo(d)} (inactivo)'
                        : rotulo(d),
              ),
          ],
      orElse: () => const <DropdownMenuEntry<BigInt?>>[],
    );

    return ComboBuscable<BigInt?>(
      etiqueta: etiqueta,
      valor: valor,
      opciones: opciones,
      onElegir: onElegir,
      ayuda: switch (lista) {
        AsyncError() => 'No se pudo cargar el catálogo',
        AsyncLoading() => 'Cargando…',
        _ => null,
      },
    );
  }
}

/// En escritorio los combos van en un `Wrap` y necesitan un ancho; en móvil ocupan el
/// renglón entero (`ComboBuscable` usa `expandedInsets: zero`: toma el del padre).
class _Envoltura extends StatelessWidget {
  const _Envoltura({required this.compacto, required this.child});

  final bool compacto;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      compacto ? child : SizedBox(width: _anchoCombo, child: child);
}
