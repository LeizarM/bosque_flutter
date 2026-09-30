import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'descuento_widgets.dart';

class InformeEmpDescuentosScreen extends ConsumerStatefulWidget {
  const InformeEmpDescuentosScreen({super.key});

  @override
  ConsumerState<InformeEmpDescuentosScreen> createState() =>
      _InformeEmpDescuentosScreenState();
}

class _InformeEmpDescuentosScreenState
    extends ConsumerState<InformeEmpDescuentosScreen> {
  // Filtros seleccionados
  EmpleadoEntity? _empleadoSeleccionado;
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;

  // Por defecto solo activos (@esActivo = 1); con el check se piden todos.
  bool _incluirInactivos = false;

  // Tope de ancho del contenido: en pantallas muy grandes las tarjetas dejan
  // de estirarse y se pierde el hilo entre un extremo y otro.
  static const double _anchoMaximo = 1200;

  static const List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  List<int> get _anios {
    final current = DateTime.now().year;
    return [current - 2, current - 1, current];
  }

  /// «Septiembre 2026».
  String get _periodo => '${_meses[_mesSeleccionado - 1]} $_anioSeleccionado';

  // Relación laboral terminada (esActivo = 0 en p_list_Empleado 'Y').
  bool _inactivo(EmpleadoEntity e) => e.relEmpEmpr.esActivo == 0;

  String _nombreEmpleado(EmpleadoEntity e) {
    // El nombre viene en el objeto persona anidado
    if (e.persona.datoPersona != null &&
        e.persona.datoPersona!.trim().isNotEmpty) {
      return e.persona.datoPersona!.trim();
    }
    final desdePersona =
        '${e.persona.nombres} ${e.persona.apPaterno} ${e.persona.apMaterno}'
            .trim();
    if (desdePersona.isNotEmpty) return desdePersona;
    // Fallback: campos de nivel superior
    if (e.datoPersona.trim().isNotEmpty) return e.datoPersona.trim();
    return '${e.nombres} ${e.apPaterno} ${e.apMaterno}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    // Se mide el ancho disponible y no el de la ventana: dentro del dashboard
    // el menú lateral se come su parte.
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final relleno =
            ancho >= 1000 ? Esp.xxl : (ancho >= 600 ? Esp.xl : Esp.l);
        return SingleChildScrollView(
          padding: EdgeInsets.all(relleno),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _anchoMaximo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEncabezado(context),
                  const SizedBox(height: Esp.xl),
                  _buildFiltros(context),
                  const SizedBox(height: Esp.xl),
                  _buildContenido(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Encabezado y filtros ──────────────────────────────────────────────────

  Widget _buildEncabezado(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(Esquina.media),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: Icon(
              Icons.request_quote_outlined,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descuentos por Empleado',
                style: t.titleLarge?.copyWith(fontWeight: Peso.dato),
              ),
              Text(
                'Consulte los préstamos, anticipos y multas descontados en un período',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: cs.primary),
                const SizedBox(width: Esp.s),
                Text(
                  'Período y empleado',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
                ),
              ],
            ),
            const SizedBox(height: Esp.l),
            LayoutBuilder(
              builder: (context, c) => _buildCampos(context, c.maxWidth),
            ),
          ],
        ),
      ),
    );
  }

  /// Los campos en una rejilla de 12 columnas: cada uno ocupa `span`. Con
  /// espacio amplio van mes, año y empleado en una fila; con menos, mes y año
  /// juntos y el empleado debajo.
  Widget _buildCampos(BuildContext context, double ancho) {
    // Hacia abajo: la suma de una fila nunca pasa del ancho, así no salta de
    // línea por un error de redondeo.
    double de(int span) {
      final columna = (ancho - Esp.m * 11) / 12;
      return (columna * span + Esp.m * (span - 1)).floorToDouble();
    }

    final (mes, anio, empleado) = ancho >= 720 ? (3, 2, 7) : (6, 6, 12);

    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.m,
      children: [
        SizedBox(width: de(mes), child: _buildMesDropdown()),
        SizedBox(width: de(anio), child: _buildAnioDropdown()),
        SizedBox(width: de(empleado), child: _buildEmpleadoDropdown(context)),
        // El check va bajo el empleado, que es el campo al que modifica.
        SizedBox(width: ancho, child: _buildIncluirInactivos(context)),
      ],
    );
  }

  Widget _buildMesDropdown() {
    return DropdownButtonFormField<int>(
      value: _mesSeleccionado,
      decoration: const InputDecoration(labelText: 'Mes'),
      isExpanded: true,
      items: [
        for (var i = 0; i < _meses.length; i++)
          DropdownMenuItem<int>(value: i + 1, child: Text(_meses[i])),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _mesSeleccionado = v);
      },
    );
  }

  Widget _buildAnioDropdown() {
    return DropdownButtonFormField<int>(
      value: _anioSeleccionado,
      decoration: const InputDecoration(labelText: 'Año'),
      isExpanded: true,
      items: [
        for (final a in _anios)
          DropdownMenuItem<int>(value: a, child: Text('$a')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _anioSeleccionado = v);
      },
    );
  }

  /// Sin el check solo se listan los activos; con él, todos (activos primero).
  Widget _buildIncluirInactivos(BuildContext context) {
    return CheckboxListTile(
      value: _incluirInactivos,
      onChanged: (v) => setState(() => _incluirInactivos = v ?? false),
      title: Text(
        'Incluir empleados inactivos',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildEmpleadoDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownSearch<EmpleadoEntity>(
      selectedItem: _empleadoSeleccionado,
      asyncItems: (text) async {
        final items = await ref.read(
          getListaEmpleados((
            text.isEmpty ? null : text,
            // 1 = solo activos; null = todos (el SP los ordena activos primero).
            _incluirInactivos ? null : 1,
            1,
            200,
            null,
          )).future,
        );
        return items;
      },
      itemAsString:
          (e) =>
              _inactivo(e)
                  ? '${_nombreEmpleado(e)} (Inactivo)'
                  : _nombreEmpleado(e),
      compareFn: (a, b) => a.codEmpleado == b.codEmpleado,
      dropdownDecoratorProps: DropDownDecoratorProps(
        // Mismo tamaño de letra que los otros campos del filtro.
        baseStyle: theme.textTheme.bodyLarge,
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Empleado',
          hintText: 'Buscar por nombre...',
          prefixIcon: Icon(Icons.person_search, color: colorScheme.primary),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        // La búsqueda va al servidor: con inactivos son más de 200 y filtrar
        // solo en el cliente dejaría a los últimos fuera del alcance.
        isFilterOnline: true,
        searchDelay: const Duration(milliseconds: 300),
        searchFieldProps: TextFieldProps(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Escriba para buscar...',
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            isDense: true,
          ),
        ),
        itemBuilder: (context, emp, isSelected) {
          final nombre = _nombreEmpleado(emp);
          final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
          final inactivo = _inactivo(emp);
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            title: Text(
              nombre,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: inactivo ? colorScheme.onSurfaceVariant : null,
              ),
            ),
            trailing: inactivo ? const _EtiquetaInactivo() : null,
            selected: isSelected,
            selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
          );
        },
        constraints: const BoxConstraints(maxHeight: 280),
      ),
      onChanged: (emp) => setState(() => _empleadoSeleccionado = emp),
    );
  }

  // ── Contenido ─────────────────────────────────────────────────────────────

  Widget _buildContenido(BuildContext context) {
    final emp = _empleadoSeleccionado;
    if (emp == null) {
      return _buildMensaje(
        context,
        icono: Icons.person_search,
        titulo: 'Selecciona un empleado',
        detalle: 'Elige el período y el empleado para ver sus descuentos',
      );
    }

    final params = (emp.codEmpleado, _mesSeleccionado, _anioSeleccionado);
    final descuentosAsync = ref.watch(descuentosEmpleadoProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildContextoEmpleado(context, emp),
        const SizedBox(height: Esp.l),
        descuentosAsync.when(
          // Un esqueleto del alto de unas tarjetas reserva el lugar: la
          // página no salta cuando llegan los datos.
          loading:
              () => _enTarjeta(
                context,
                const SizedBox(
                  height: 312,
                  child: EsqueletoLista(filas: 4, altoFila: 64),
                ),
              ),
          error:
              (e, _) => _enTarjeta(
                context,
                SizedBox(
                  height: 240,
                  child: MensajeError(
                    error: e,
                    onReintentar:
                        () => ref.invalidate(descuentosEmpleadoProvider(params)),
                  ),
                ),
              ),
          data: (descuentos) {
            if (descuentos.isEmpty) {
              return _buildMensaje(
                context,
                icono: Icons.check_circle_outline,
                titulo: 'Sin descuentos registrados',
                detalle: 'No hay descuentos para $_periodo',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResumenDescuentos(descuentos: descuentos, periodo: _periodo),
                const SizedBox(height: Esp.l),
                ListaDescuentos(descuentos: descuentos),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Quién y de cuándo es lo que se está viendo; queda a la vista aunque los
  /// filtros se hayan desplazado fuera de pantalla.
  Widget _buildContextoEmpleado(BuildContext context, EmpleadoEntity emp) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final nombre = _nombreEmpleado(emp);
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer,
          child: Text(
            inicial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(fontWeight: Peso.dato),
              ),
              Text(
                _periodo,
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (_inactivo(emp)) ...[
          const SizedBox(width: Esp.s),
          const _EtiquetaInactivo(),
        ],
      ],
    );
  }

  Widget _enTarjeta(BuildContext context, Widget hijo) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(Theme.of(context).colorScheme),
      child: hijo,
    );
  }

  Widget _buildMensaje(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String detalle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return _enTarjeta(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Esp.xxl,
          horizontal: Esp.l,
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: Esp.s),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: t.titleSmall?.copyWith(
                fontWeight: Peso.titulo,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Esp.xs),
            Text(detalle, textAlign: TextAlign.center, style: context.apagado()),
          ],
        ),
      ),
    );
  }
}

/// «Inactivo»: neutra, porque no es un problema sino un dato del empleado.
class _EtiquetaInactivo extends StatelessWidget {
  const _EtiquetaInactivo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 2),
        child: Text(
          'Inactivo',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
