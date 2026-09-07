// Destino final: lib/presentation/screens/tareas-rutinarias/dependientes_jefe_screen.dart
import 'package:bosque_flutter/core/state/dependientes_jefe_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/dependiente_cargo_tile.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/nueva_tarea_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pantalla del jefe/gerente: elige a quiénes de su equipo asignar una tarea
/// rutinaria y con qué frecuencia. Todo lo que aparece acá ya viene filtrado
/// por el backend según el cargo vigente de quien inició sesión — si no
/// califica como jefe, [DependientesJefeState.autorizado] llega en `false`
/// y esta pantalla lo explica en vez de mostrar una lista vacía sin razón.
class DependientesJefeScreen extends ConsumerWidget {
  const DependientesJefeScreen({super.key});

  Future<void> _abrirFormulario(BuildContext context, int cantidad) async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NuevaTareaFormSheet(cantidadSeleccionados: cantidad),
    );
    if (creado == true && context.mounted) {
      HapticFeedback.mediumImpact();
      mostrarAviso(context, 'Tarea rutinaria creada y asignada.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dependientesJefeProvider);
    final notifier = ref.read(dependientesJefeProvider.notifier);
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 900;

    ref.listen(dependientesJefeProvider, (previo, actual) {
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Programar tarea a mi equipo')),
      body: RefreshIndicator(
        onRefresh: notifier.cargar,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child:
              state.cargando
                  ? const Center(
                    key: ValueKey('cargando'),
                    child: CircularProgressIndicator(),
                  )
                  : !state.autorizado
                  ? _EstadoNoAutorizado(
                    key: const ValueKey('no-autorizado'),
                    mensaje: state.mensajeInfo,
                  )
                  : Column(
                    key: const ValueKey('contenido'),
                    children: [
                      _FiltrosBar(
                        profundidad: state.profundidad,
                        alcanceSucursal: state.alcanceSucursal,
                        onProfundidad: notifier.cambiarProfundidad,
                        onAlcance: notifier.cambiarAlcanceSucursal,
                      ),
                      Expanded(
                        child:
                            state.dependientes.isEmpty
                                ? const _EstadoSinDependientes()
                                : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal:
                                        esAncho
                                            ? (anchoDisponible - 900) / 2
                                            : 0,
                                  ),
                                  itemCount: state.dependientes.length,
                                  itemBuilder: (context, i) {
                                    final d = state.dependientes[i];
                                    // Entrada suave y acotada, misma disciplina
                                    // que el resto del módulo: sin
                                    // AnimationController propio.
                                    return TweenAnimationBuilder<double>(
                                      key: ValueKey('dep-${d.claveSeleccion}'),
                                      tween: Tween(begin: 0, end: 1),
                                      duration: Duration(
                                        milliseconds:
                                            200 + (i.clamp(0, 8) * 20),
                                      ),
                                      curve: Curves.easeOut,
                                      builder:
                                          (context, valor, child) => Opacity(
                                            opacity: valor,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                (1 - valor) * 8,
                                              ),
                                              child: child,
                                            ),
                                          ),
                                      child: DependienteCargoTile(
                                        dependiente: d,
                                        seleccionado: state.seleccionados
                                            .contains(d.claveSeleccion),
                                        onTap:
                                            () => notifier.alternarSeleccion(
                                              d.claveSeleccion,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
        ),
      ),
      floatingActionButton:
          (!state.cargando &&
                  state.autorizado &&
                  state.seleccionados.isNotEmpty)
              ? FloatingActionButton.extended(
                onPressed:
                    () => _abrirFormulario(context, state.seleccionados.length),
                icon: const Icon(Icons.add_task),
                label: Text('Asignar a ${state.seleccionados.length}'),
              )
              : null,
    );
  }
}

class _FiltrosBar extends StatelessWidget {
  final String profundidad;
  final String alcanceSucursal;
  final ValueChanged<String> onProfundidad;
  final ValueChanged<String> onAlcance;

  const _FiltrosBar({
    required this.profundidad,
    required this.alcanceSucursal,
    required this.onProfundidad,
    required this.onAlcance,
  });

  @override
  Widget build(BuildContext context) {
    final selectorAlcanceEquipo = _SelectorDosOpciones(
      etiqueta: 'Alcance del equipo',
      valor: profundidad,
      opciones: const {'T': 'Todo el subárbol', 'D': 'Solo directos'},
      onCambio: onProfundidad,
      icono: Icons.account_tree_outlined,
    );
    final selectorSucursales = _SelectorDosOpciones(
      etiqueta: 'Sucursales',
      valor: alcanceSucursal,
      opciones: const {'A': 'Todas', 'M': 'Solo la mía'},
      onCambio: onAlcance,
      icono: Icons.storefront_outlined,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      // LayoutBuilder en vez de Wrap: un SizedBox de ancho double.infinity
      // dentro de un Wrap revienta en pantallas angostas (el Wrap da a sus
      // hijos un ancho no acotado). En mobile se apilan a ancho completo; en
      // tablet/desktop quedan lado a lado con un ancho fijo cómodo.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esAngosto = constraints.maxWidth < 560;
          if (esAngosto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                selectorAlcanceEquipo,
                const SizedBox(height: 10),
                selectorSucursales,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 260, child: selectorAlcanceEquipo),
              const SizedBox(width: 16),
              SizedBox(width: 260, child: selectorSucursales),
            ],
          );
        },
      ),
    );
  }
}

class _SelectorDosOpciones extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Map<String, String> opciones;
  final ValueChanged<String> onCambio;
  final IconData icono;

  const _SelectorDosOpciones({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onCambio,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              icono,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          segments:
              opciones.entries
                  .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                  .toList(),
          selected: {valor},
          onSelectionChanged: (nuevo) => onCambio(nuevo.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }
}

class _EstadoNoAutorizado extends StatelessWidget {
  final String? mensaje;

  const _EstadoNoAutorizado({super.key, this.mensaje});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 40,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta sección es para jefes de área y gerentes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje ??
                  'Tu cargo actual no tiene dependientes para programar tareas.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoSinDependientes extends StatelessWidget {
  const _EstadoSinDependientes();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'No hay cargos para este filtro',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba cambiando "Todas las sucursales" o "Todo el subárbol" arriba.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
