/// Los filtros del catálogo de vehículos. En web van a la vista; en teléfono, el
/// buscador queda afuera y el resto en un panel plegable que cuenta en el título
/// cuántos criterios hay puestos (un filtro olvidado en un panel cerrado
/// explicaría una lista vacía). Todo se aplica del lado del cliente.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

class FiltrosCoches extends StatefulWidget {
  const FiltrosCoches({
    super.key,
    required this.filtro,
    required this.onFiltro,
    required this.sucursales,
    required this.compacto,
    this.ayudaSucursal,
  });

  final FiltroCoches filtro;
  final ValueChanged<FiltroCoches> onFiltro;
  final List<OpcionSucursal> sucursales;
  final bool compacto;

  /// «Cargando…» o el aviso de que el catálogo no llegó; null si todo bien.
  final String? ayudaSucursal;

  @override
  State<FiltrosCoches> createState() => _FiltrosCochesState();
}

class _FiltrosCochesState extends State<FiltrosCoches> {
  late final TextEditingController _buscador;

  @override
  void initState() {
    super.initState();
    _buscador = TextEditingController(text: widget.filtro.texto);
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  void _limpiar() {
    _buscador.clear();
    widget.onFiltro(const FiltroCoches());
  }

  @override
  Widget build(BuildContext context) =>
      widget.compacto ? _movil(context) : _escritorio(context);

  // Escritorio: todo a la vista. En `Wrap` y no en `Row` con `Spacer`: entre 720
  // y 1000 px buscador, combo y estado suman más que el ancho.
  Widget _escritorio(BuildContext context) => Wrap(
    spacing: Esp.m,
    runSpacing: Esp.m,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(width: 320, child: _campoBuscador()),
      SizedBox(width: 240, child: _comboSucursal()),
      _estado(),
      if (widget.filtro.hayAlgo)
        TextButton.icon(
          onPressed: _limpiar,
          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
          label: const Text('Limpiar filtros'),
        ),
    ],
  );

  Widget _movil(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final puestos = widget.filtro.criterios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campoBuscador(),
        const SizedBox(height: Esp.s),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            // Abre solo si ya hay criterios: si no, interesa la lista y no la
            // maquinaria para acotarla.
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
              SizedBox(width: double.infinity, child: _estado()),
              const SizedBox(height: Esp.m),
              _comboSucursal(),
              const SizedBox(height: Esp.s),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.filtro.hayAlgo ? _limpiar : null,
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

  Widget _campoBuscador() => TextField(
    controller: _buscador,
    textInputAction: TextInputAction.search,
    onChanged: (t) => widget.onFiltro(widget.filtro.copyWith(texto: t)),
    decoration: InputDecoration(
      isDense: true,
      border: const OutlineInputBorder(),
      prefixIcon: const Icon(Icons.search, size: 18),
      hintText: 'Placa, marca, clase, color o sucursal',
      suffixIcon:
          widget.filtro.texto.isEmpty
              ? null
              : IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Borrar la búsqueda',
                onPressed: () {
                  _buscador.clear();
                  widget.onFiltro(widget.filtro.copyWith(texto: ''));
                },
              ),
    ),
  );

  Widget _estado() => SegmentedButton<EstadoFiltroCoche>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: EstadoFiltroCoche.todos, label: Text('Todos')),
      ButtonSegment(value: EstadoFiltroCoche.activos, label: Text('Activos')),
      ButtonSegment(
        value: EstadoFiltroCoche.inactivos,
        label: Text('Inactivos'),
      ),
    ],
    selected: {widget.filtro.estado},
    onSelectionChanged:
        (s) => widget.onFiltro(widget.filtro.copyWith(estado: s.first)),
  );

  Widget _comboSucursal() => ComboBuscable<int?>(
    etiqueta: 'Sucursal',
    valor: widget.filtro.codSucursal,
    ayuda: widget.ayudaSucursal,
    opciones: [
      const DropdownMenuEntry<int?>(value: null, label: 'Todas'),
      for (final s in widget.sucursales)
        DropdownMenuEntry<int?>(value: s.codSucursal, label: s.nombre),
    ],
    onElegir:
        (v) => widget.onFiltro(
          v == null
              ? widget.filtro.copyWith(limpiarSucursal: true)
              : widget.filtro.copyWith(codSucursal: v),
        ),
  );
}
