import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/formulario_socios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class GruposTigoScreen extends ConsumerStatefulWidget {
  final String periodoCobrado;
  const GruposTigoScreen({super.key, required this.periodoCobrado});

  @override
  ConsumerState<GruposTigoScreen> createState() => _GruposTigoScreenState();
}

class _GruposTigoScreenState extends ConsumerState<GruposTigoScreen> {
  @override
  Widget build(BuildContext context) {
    print ('GruposTigoScreen build - periodoCobrado: ${widget.periodoCobrado}');
    final gruposAsync = ref.watch(obtenerGruposTigo(widget.periodoCobrado));

    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos Tigo'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () {
              ref.invalidate(obtenerGruposTigo(widget.periodoCobrado));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.group_add),
        label: const Text('Nuevo Grupo'),
        backgroundColor: Colors.blue[700],
        onPressed: () {
          _mostrarFormularioGrupo(context, ref);
        },
      ),
      body: Container(
        color: Colors.blueGrey[50],
        child: gruposAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (grupos) {
            if (grupos.isEmpty) {
              return const Center(
                child: Text(
                  'No hay grupos registrados.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              );
            }
            if (isMobile) {
              return _buildGruposListMobile(
                grupos: grupos,
                onEditarGrupo: (grupo) => _mostrarFormularioGrupo(context, ref, grupo: grupo),
                onEliminarGrupo: (grupo) => _eliminarGrupo(context, ref, grupo),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Listado de Grupos',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _buildGruposTable(
                            grupos: grupos,
                            onEditarGrupo: (grupo) => _mostrarFormularioGrupo(context, ref, grupo: grupo),
                            onEliminarGrupo: (grupo) => _eliminarGrupo(context, ref, grupo),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Widget para desktop/tablet
  Widget _buildGruposTable({
    required List<SocioTigoEntity> grupos,
    required void Function(SocioTigoEntity grupo) onEditarGrupo,
    required void Function(SocioTigoEntity grupo) onEliminarGrupo,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
          headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
          columns: const [
            DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: grupos.map((grupo) {
            final esSinAsignar = (grupo.nombreCompleto ).toUpperCase() == '   SIN ASIGNAR';
            return DataRow(
              color: esSinAsignar
                  ? MaterialStateProperty.all(Colors.red[50])
                  : null,
              cells: [
                DataCell(Row(
                  children: [
                    if (esSinAsignar)
                      const Icon(Icons.warning, color: Colors.red, size: 18),
                    Text(
                      grupo.nombreCompleto,
                      style: TextStyle(
                        color: esSinAsignar ? Colors.red : null,
                        fontWeight: esSinAsignar ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                )),
                DataCell(Text(grupo.telefono.toString() )),
                DataCell(Text(grupo.descripcion ?? '-')),
                DataCell(Row(
                  children: [
                    Tooltip(
                      message: 'Editar',
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => onEditarGrupo(grupo),
                      ),
                    ),
                    if (!esSinAsignar)
                      Tooltip(
                        message: 'Eliminar',
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onEliminarGrupo(grupo),
                        ),
                      ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Widget para móvil
  Widget _buildGruposListMobile({
    required List<SocioTigoEntity> grupos,
    required void Function(SocioTigoEntity grupo) onEditarGrupo,
    required void Function(SocioTigoEntity grupo) onEliminarGrupo,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: grupos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final grupo = grupos[index];
        final esSinAsignar = (grupo.nombreCompleto ).toUpperCase() == '   SIN ASIGNAR';
        return Card(
          color: esSinAsignar ? Colors.red[50] : Colors.white,
          child: ListTile(
            leading: esSinAsignar
                ? const Icon(Icons.warning, color: Colors.red)
                : const Icon(Icons.group, color: Colors.blueGrey),
            title: Text(
              grupo.nombreCompleto,
              style: TextStyle(
                color: esSinAsignar ? Colors.red : null,
                fontWeight: esSinAsignar ? FontWeight.bold : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teléfono: ${grupo.telefono }'),
                Text('Descripción: ${grupo.descripcion ?? "-"}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEditarGrupo(grupo),
                ),
                if (!esSinAsignar)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onEliminarGrupo(grupo),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarFormularioGrupo(BuildContext context, WidgetRef ref, {SocioTigoEntity? grupo}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: FormularioSocios(
            title: grupo == null ? 'Agregar Grupo' : 'Editar Grupo',
            socios: grupo,
            codEmpleado: null,
            periodoCobrado: widget.periodoCobrado,
            isEditing: grupo != null,
            onSave: (nuevoGrupo) async {
              await ref.read(registrarSocioTigo(nuevoGrupo).future);
              ref.invalidate(obtenerGruposTigo(widget.periodoCobrado));
              ref.invalidate(tigoResumenDetallado(widget.periodoCobrado));
              ref.invalidate(obtenerNroSinAsignar(widget.periodoCobrado));
              //refresh de tigoArbolDetallado
              ref.invalidate(tigoArbolDetallado((null, widget.periodoCobrado)));
            },
            onCancel: () {
              Navigator.of(ctx).pop();
            },
          ),
        );
      },
    );
  }

  void _eliminarGrupo(BuildContext context, WidgetRef ref, SocioTigoEntity grupo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Grupo'),
          ],
        ),
        content: const Text('¿Está seguro que desea eliminar este grupo?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(eliminarGrupoTigo(grupo.codCuenta).future);
      ref.invalidate(obtenerGruposTigo(widget.periodoCobrado));
      ref.invalidate(tigoResumenDetallado(widget.periodoCobrado));
      ref.invalidate(obtenerNroSinAsignar(widget.periodoCobrado));
      ref.invalidate(tigoArbolDetallado((null, widget.periodoCobrado)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo eliminado'), backgroundColor: Colors.red),
      );
    }
  }
}