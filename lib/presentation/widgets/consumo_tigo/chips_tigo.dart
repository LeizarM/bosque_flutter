import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/tipo_renovacion_chip_tigo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/form_chip_tigo.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/chip_tigo_entity.dart';
import 'package:bosque_flutter/core/state/consumo_tigo_provider.dart';
// Importa donde hayas guardado el widget genérico
// import 'package:bosque_flutter/presentation/widgets/shared/bosque_flat_table.dart';

class ChipTigoScreen extends ConsumerStatefulWidget {
  // 1. CAMBIO A STATEFUL
  const ChipTigoScreen({super.key});

  @override
  ConsumerState<ChipTigoScreen> createState() => _ChipTigoScreenState();
}

class _ChipTigoScreenState extends ConsumerState<ChipTigoScreen> {
  final TextEditingController _buscadorController = TextEditingController();
  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chipTigoProvider);
    final notifier = ref.read(chipTigoProvider.notifier);
    ref.listenMessages(chipTigoProvider, context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Chips Tigo'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        // Dentro de AppBar -> actions:
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
            onPressed:
                (state.periodoFiltro == null)
                    ? null // Deshabilitado si no hay periodo válido
                    : () async {
                      // Llamamos a tu función general de utilidad
                      await mostrarReportePdf(
                        context: context,
                        filename: 'RptPerdida_${state.periodoFiltro}.pdf',
                        downloadFunction: () async {
                          // Aquí disparamos el provider manualmente con .future
                          return await ref.read(
                            rptPerdidaLineasProvider(
                              state.periodoFiltro!,
                            ).future,
                          );
                        },
                      );
                    },
          ),
        ],
      ),
      body: BosqueFlatTable<ChipTigoEntity>(
        items: state.chipsPerdidos,
        cargando: state.cargando,
        searchHint: 'Buscar por empleado o teléfono...',
        searchController: _buscadorController,
        onSearch:
            (val) => notifier.setSearch(val), // El SQL hace el trabajo pesado
        // -- PAGINACIÓN AUTOMÁTICA --
        currentPage:
            (!state.cargando && state.chipsPerdidos.isNotEmpty)
                ? state.pagina
                : null,
        totalPages:
            (!state.cargando && state.chipsPerdidos.isNotEmpty)
                ? (state.chipsPerdidos.first.totalPaginas != null &&
                        state.chipsPerdidos.first.totalPaginas! > 0
                    ? state.chipsPerdidos.first.totalPaginas
                    : 1)
                : null,
        firstRow:
            (!state.cargando && state.chipsPerdidos.isNotEmpty)
                ? state.chipsPerdidos.first.fila
                : null,
        lastRow:
            (!state.cargando && state.chipsPerdidos.isNotEmpty)
                ? state.chipsPerdidos.last.fila
                : null,
        onPageChanged: (newPage) => notifier.setPagina(newPage),
        currentPageSize: state.tamanoPagina,
        onPageSizeChanged: (newSize) => notifier.setTamanoPagina(newSize),

        extraFilters: [
          // --- SELECTOR DE PERIODO DINÁMICO (Viene de SQL) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String>(
              value: state.periodoFiltro,
              underline: const SizedBox(),
              items:
                  state.periodos.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                      ), // Muestra 'TODOS' o '2026-03' tal cual vienen del SP
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) notifier.setPeriodo(val);
              },
            ),
          ),
        ],
        // DEFINICIÓN DE COLUMNAS PARA WEB
        columns: [
          BosqueColumn(
            label: '#',
            flex: 0, // Ancho mínimo para la columna de fila
            cellBuilder:
                (e) => Text(
                  e.fila.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
          ),
          BosqueColumn(
            label: 'Empleado',
            flex: 2,
            cellBuilder:
                (e) => Text(
                  e.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
          ),
          BosqueColumn(
            label: 'Teléfono',
            flex: 1,
            cellBuilder: (e) => Text(e.telefono),
          ),
          BosqueColumn(
            label: 'Código',
            flex: 1,
            cellBuilder: (e) => Text(e.codigo ?? ''),
          ),
          BosqueColumn(
            label: 'Motivo de Reposición',
            flex: 1,
            cellBuilder:
                (e) => DisplayValue<TipoRenovacionChipTigoEntity>(
                  code: e.descripcion, // Aquí entra el 'PERD' que manda SQL
                  provider:
                      obtenerTipoRenovacionChip, // El provider que trae la lista de v_tipos
                  getCode: (item) => item.codTipos,
                  getDescription:
                      (item) =>
                          item.nombre, // Esto es lo que se pintará en pantalla
                  fallback:
                      e.descripcion, // Si falla, muestra el código por si acaso
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
          ),
          BosqueColumn(
            label: 'Fecha Solicitud',
            flex: 1,
            //cellBuilder: (e) => Text(e.fechaSolicitud.toIso8601String().substring(0, 10)),
            //o usar dependendencia intl:
            cellBuilder:
                (e) => Text(
                  FechaUtils.formatDate(e.fechaSolicitud),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ), //Text(DateFormat('yyyy-MM-dd').format(e.fechaSolicitud)
          ),
          BosqueColumn(
            label: 'Acciones',
            flex: 1,
            cellBuilder:
                (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BOTÓN EDITAR
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue,
                      ),
                      onPressed: () => _abrirFormulario(context, entity: e),
                    ),
                    const SizedBox(width: 8),
                    // BOTÓN ELIMINAR
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: state.guardando ? Colors.grey : Colors.red,
                      ),
                      onPressed:
                          state.guardando
                              ? null
                              : () => _confirmarEliminacion(context, ref, e),
                    ),
                  ],
                ),
          ),
        ],
        // DISEÑO PARA MÓVIL
        mobileCardBuilder:
            (e) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                title: Text(
                  e.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Telefono: ${e.telefono}'),
                    Row(
                      children: [
                        const Text('Motivo: '),
                        Expanded(
                          child: DisplayValue<TipoRenovacionChipTigoEntity>(
                            code: e.descripcion,
                            provider: obtenerTipoRenovacionChip,
                            getCode: (t) => t.codTipos,
                            getDescription: (t) => t.nombre,
                            fallback: e.descripcion,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Fecha: ${FechaUtils.formatDate(e.fechaSolicitud)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (e.codigo != null && e.codigo!.isNotEmpty)
                      Text(
                        'Código: ${e.codigo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _abrirFormulario(context, entity: e),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: state.guardando ? Colors.grey : Colors.red,
                      ),
                      onPressed:
                          state.guardando
                              ? null
                              : () => _confirmarEliminacion(context, ref, e),
                    ),
                  ],
                ),
                //onTap: () => _abrirFormulario(context, entity: e),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[900],
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {ChipTigoEntity? entity}) {
    showDialog(
      context: context,
      builder: (context) => FormChipTigo(entity: entity),
    );
  }

  void _confirmarEliminacion(
    BuildContext context,
    WidgetRef ref,
    ChipTigoEntity entity,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Confirmar eliminación'),
              ],
            ),
            content: Text(
              '¿Está seguro de eliminar el registro de ${entity.nombreCompleto}?\nEsta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      // Invocamos el provider que ya tiene el patrón de limpieza de mensajes
      await ref.read(chipTigoProvider.notifier).eliminarChip(entity);
    }
  }
}
