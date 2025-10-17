import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:bosque_flutter/presentation/screens/facturas-tigo/ver_grupos.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class ResumenDetalladoScreen extends ConsumerStatefulWidget {
  final String periodoCobrado;
  const ResumenDetalladoScreen({Key? key, required this.periodoCobrado}) : super(key: key);

  @override
  ConsumerState<ResumenDetalladoScreen> createState() => _ResumenDetalladoScreenState();
}

class _ResumenDetalladoScreenState extends ConsumerState<ResumenDetalladoScreen> {
  final Map<String, bool> expandedMap = {};
  String? _empresaSeleccionada;
  bool mostrarTigoEjecutado = false;
  TextEditingController _searchController = TextEditingController();

final Map<int, bool> expandedArbolMap = {};
final TextEditingController _buscadorController = TextEditingController();
String _buscadorTexto = '';


@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
  @override
Widget build(BuildContext context) {
  final isMobile = ResponsiveUtilsBosque.isMobile(context);

  final tigoEjecutadoAsync = ref.watch(
  obtenerTigoEjecutado((null, widget.periodoCobrado))
);
// Validar solo una vez al entrar
  final ejecutadoEnProvider = tigoEjecutadoAsync.asData?.value.any(
  (r) => r.estado.toUpperCase() == 'EJECUTADO' || r.estado.toUpperCase() == 'CONSOLIDADO'
) ?? false;

if (ejecutadoEnProvider && !mostrarTigoEjecutado) {
  setState(() {
    mostrarTigoEjecutado = true;
  });
}
  final resumenDetalladoAsync = ref.watch(tigoResumenDetallado(widget.periodoCobrado));
  final facturasAsync = ref.watch(facturasTigoProvider);

  final mostrarDatosTigoEjecutado = mostrarTigoEjecutado ||
      (tigoEjecutadoAsync.asData?.value != null && tigoEjecutadoAsync.asData!.value.isNotEmpty);

  final datos = mostrarDatosTigoEjecutado ? tigoEjecutadoAsync : resumenDetalladoAsync;

  final tigoEjecutadoEstadoEjecutado = tigoEjecutadoAsync.maybeWhen(
    data: (lista) => lista.any(
      (r) => r.estado.toUpperCase() == 'EJECUTADO' || r.estado.toUpperCase() == 'CONSOLIDADO'
    ),
    orElse: () => false,
  );

  final bool ejecutado = facturasAsync.maybeWhen(
    data: (facturas) => facturas.any(
      (f) => f.periodoCobrado == widget.periodoCobrado && f.estado?.toUpperCase() == 'EJECUTADO'
    ),
    orElse: () => false,
  );

  // --- LAYOUT MOBILE ---
  if (isMobile) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: const Text('Detalle de Facturas Tigo'),
      backgroundColor: Colors.blue[800],
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
    _buildRefreshButtonResumen(
      onRefresh: () {
        ref.invalidate(tigoArbolDetallado((_empresaSeleccionada, widget.periodoCobrado)));
        ref.invalidate(tigoResumenDetallado(widget.periodoCobrado));
      },
    ),
  ],
    ),
    bottomNavigationBar: BottomAppBar(
      color: Colors.blue[50],
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blueGrey),
              tooltip: 'Ver Grupos',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GruposTigoScreen(periodoCobrado: widget.periodoCobrado),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
              tooltip: 'Generar Reporte',
              onPressed: () async {
                ref.invalidate(jasperPdfFacturasTigoProvider(widget.periodoCobrado));
                try {
                  final pdfBytes = await ref.read(jasperPdfFacturasTigoProvider(widget.periodoCobrado).future);
                  await Printing.layoutPdf(
                    onLayout: (format) async => pdfBytes,
                    name: 'RptConsumoTigo',
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo descargar el reporte PDF')),
                  );
                }
              },
            ),
            
            PermissionWidget(
            buttonName: 'btnEjecutarTigo',
            child:IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.red),
              tooltip: 'Ejecutar',
              onPressed: ejecutado
                  ? null
                  : () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmar ejecución'),
                          content: const Text(
                            'Una vez ejecutado no se podrá volver a ejecutar esta operación.\n¿Desea continuar?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Ejecutar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true) {
                        final resumen = ref.read(tigoArbolDetallado((null,widget.periodoCobrado))).asData?.value ?? [];
                        final tieneSinAsignar = resumen.any((r) => (r.nombreCompleto.toUpperCase()) == 'SIN ASIGNAR');
                        if (tieneSinAsignar) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se puede ejecutar: Hay números sin asignar.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        try {
                          final result = await ref.read(insertarAnticipoTigo(widget.periodoCobrado).future);
                          ref.invalidate(facturasTigoProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result
                                  ? 'Anticipos generados correctamente.'
                                  : 'No se pudo generar anticipos.'),
                              backgroundColor: result ? Colors.green : const Color.fromARGB(255, 235, 78, 67),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al ejecutar: $e')),
                          );
                        }
                      }
                    },
            ),
            ),
            /*IconButton(
              icon: const Icon(Icons.save_alt, color: Colors.lightBlue),
              tooltip: 'Insertar Datos',
              onPressed: tigoEjecutadoEstadoEjecutado
                  ? null
                  : () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Insertar datos'),
                          content: const Text('¿Desea insertar los datos de la tabla?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Insertar'),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true) {
                        final resumen = ref.read(tigoArbolDetallado((null,widget.periodoCobrado))).asData?.value ?? [];
                        final tieneSinAsignar = resumen.any((r) => (r.nombreCompleto.toUpperCase() ) == 'SIN ASIGNAR');
                        if (tieneSinAsignar) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se puede insertar: Hay números sin asignar.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        try {
                          final audUsuario = await ref.read(userProvider.notifier).getCodUsuario();
                          final result = await ref.read(ejecutarTigo((widget.periodoCobrado, audUsuario)).future);
                          setState(() {
                            mostrarTigoEjecutado = true;
                          });
                          ref.invalidate(obtenerTigoEjecutado((_empresaSeleccionada, widget.periodoCobrado)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result
                                  ? '¡Datos insertados correctamente!'
                                  : 'No se pudo insertar los datos.'),
                              backgroundColor: result ? Colors.green : Colors.red,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al insertar: $e')),
                          );
                        }
                      }
                    },
            ),*/
          ],
        ),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          const SizedBox(height: 10),
          // Filtro de empresa en una fila aparte
          resumenDetalladoAsync.when(
            loading: () => const SizedBox(),
            error: (err, _) => const SizedBox(),
            data: (resumen) {
              final empresas = resumen
                  .map((e) => e.empresa ?? '')
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
              return empresas.isEmpty
                  ? const SizedBox()
                  : _buildEmpresaFiltro(
                      empresas,
                      _empresaSeleccionada,
                      (value) => setState(() => _empresaSeleccionada = value),
                    );
            },
          ),
          const SizedBox(height: 10),
          // Estado del periodo
          if (mostrarDatosTigoEjecutado)
            Builder(
              builder: (_) {
                final lista = tigoEjecutadoAsync.asData?.value ?? [];
                final estado = lista.isNotEmpty ? lista.first.estado : null;
                return _buildEstadoPeriodo(estado);
              },
            ),
          // Panel de periodo cobrado
          resumenDetalladoAsync.when(
            loading: () => const SizedBox(),
            error: (err, _) => const SizedBox(),
            data: (resumen) {
              if (resumen.isEmpty) return const SizedBox();
              final periodo = resumen.first.periodoCobrado ;
              return _buildPeriodoCobradoPanel(periodo);
            },
          ),
          const SizedBox(height: 10),
          // Tabla responsiva
          Expanded(
            child: datos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error al cargar datos: $err',
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
              data: (resumen) {
                final resumenFiltrado = _empresaSeleccionada == null
                    ? resumen
                    : resumen.where((r) => r.empresa == _empresaSeleccionada).toList();

                if (resumenFiltrado.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay datos detallados.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                // Agrupa por codEmpleado y nombreCompleto
                final grupos = <String, List<TigoEjecutadoEntity>>{};
                for (final r in resumenFiltrado) {
                  final key = '${r.codEmpleado}_${r.nombreCompleto}';
                  grupos.putIfAbsent(key, () => []).add(r);
                }

                return _buildResumenTableMobile(
                  grupos,
                  expandedMap,
                  (key) => setState(() => expandedMap[key] = !(expandedMap[key] ?? false)),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- LAYOUT DESKTOP/TABLET ---
  return Scaffold(
  appBar: AppBar(
    leading: Navigator.of(context).canPop()
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null,
    title: const Text('Detalle de Facturas Tigo'),
    backgroundColor: Colors.blue[800],  
    iconTheme: const IconThemeData(color: Colors.white),
    actions: [
    _buildRefreshButtonResumen(
      onRefresh: () {
        ref.invalidate(tigoArbolDetallado((_empresaSeleccionada, widget.periodoCobrado)));
      },
    ),
  ],
  ),
  body: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel principal
        Expanded(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header y filtro de empresa
                  Row(
                    children: [

                      const Spacer(),
                      resumenDetalladoAsync.when(
                        loading: () => const SizedBox(),
                        error: (err, _) => const SizedBox(),
                        data: (resumen) {
                          final empresas = resumen
                              .map((e) => e.empresa ?? '')
                              .where((e) => e.isNotEmpty)
                              .toSet()
                              .toList()
                            ..sort();
                          return empresas.isEmpty
                              ? const SizedBox()
                              : _buildEmpresaFiltro(
                                  empresas,
                                  _empresaSeleccionada,
                                  (value) => setState(() => _empresaSeleccionada = value),
                                );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Estado del periodo
                  if (mostrarDatosTigoEjecutado)
                    Builder(
                      builder: (_) {
                        final lista = tigoEjecutadoAsync.asData?.value ?? [];
                        final estado = lista.isNotEmpty ? lista.first.estado : null;
                        return _buildEstadoPeriodo(estado);
                      },
                    ),
                  // Panel de periodo cobrado
                  resumenDetalladoAsync.when(
                    loading: () => const SizedBox(),
                    error: (err, _) => const SizedBox(),
                    data: (resumen) {
                      if (resumen.isEmpty) return const SizedBox();
                      final periodo = resumen.first.periodoCobrado ;
                      return _buildPeriodoCobradoPanel(periodo);
                    },
                  ),
                  Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: _buscadorController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, teléfono o empresa',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onChanged: (value) {
          setState(() {
            _buscadorTexto = value.trim().toLowerCase();
          });
        },
      ),
    ),
                  // Tabla principal
                  Expanded(
  child: Builder(
    builder: (context) {
      if (mostrarTigoEjecutado) {
        // Mostrar el árbol ejecutado
        final ejecutadoAsync = ref.watch(
          obtenerTigoEjecutado((null, widget.periodoCobrado))
        );

        return ejecutadoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error al cargar datos: $err')),
          data: (arbol) {
            final arbolFiltrado = filtrarArbolPorEmpresa(arbol, _empresaSeleccionada)
              .where((e) =>
                e.nombreCompleto.toLowerCase().contains(_buscadorTexto) ||
                (e.corporativo ?? '').toLowerCase().contains(_buscadorTexto) ||
                (e.empresa ?? '').toLowerCase().contains(_buscadorTexto)
              ).toList();

            return _buildArbolTablaTigoEjecutado(arbolFiltrado);
          },
        );
      } else {
        // Mostrar el árbol normal
        final arbolDetalladoAsync = ref.watch(
          tigoArbolDetallado((_empresaSeleccionada, widget.periodoCobrado))
        );

        return arbolDetalladoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error al cargar datos: $err')),
          data: (arbol) {
            final arbolFiltrado = filtrarArbolPorEmpresa(arbol, _empresaSeleccionada)
              .where((e) =>
                e.nombreCompleto.toLowerCase().contains(_buscadorTexto) ||
                (e.corporativo ?? '').toLowerCase().contains(_buscadorTexto) ||
                (e.empresa ?? '').toLowerCase().contains(_buscadorTexto)
              ).toList();

            return _buildArbolTablaSimulada(arbolFiltrado);
          },
        );
      }
    },
  ),
),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 36),
        // Panel de operaciones
        Container(
          width: 340,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.13),
                blurRadius: 16,
                offset: const Offset(4, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildOperacionesPanel(
              context: context,
              ref: ref,
              ejecutado: ejecutado,
              tigoEjecutadoEstadoEjecutado: tigoEjecutadoEstadoEjecutado,
              periodoCobrado: widget.periodoCobrado,
              onVerGrupos: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GruposTigoScreen(periodoCobrado: widget.periodoCobrado),
                  ),
                );
              },
              onGenerarReporte: () async {
  // Elimina o comenta la validación:
  // final resumen = ref.read(tigoResumenDetallado(widget.periodoCobrado)).asData?.value ?? [];
  // final tieneSinAsignar = resumen.any((r) => (r.nombreCompleto?.toUpperCase() ?? '') == 'SIN ASIGNAR');
  // if (tieneSinAsignar) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('No se puede generar el reporte: Hay números SIN ASIGNAR.'),
  //       backgroundColor: Colors.red,
  //     ),
  //   );
  //   return;
  // }

  // Ahora siempre permite imprimir:
  ref.invalidate(jasperPdfFacturasTigoProvider(widget.periodoCobrado));
  try {
    final pdfBytes = await ref.read(jasperPdfFacturasTigoProvider(widget.periodoCobrado).future);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'RptConsumoTigo',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo descargar el reporte PDF')),
    );
  }
},
              onEjecutar: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmar ejecución'),
                    content: const Text(
                      'Una vez ejecutado no se podrá volver a ejecutar esta operación.\n¿Desea continuar?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Ejecutar'),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  final resumen = ref.read(tigoResumenDetallado(widget.periodoCobrado)).asData?.value ?? [];
                  final tieneSinAsignar = resumen.any((r) => (r.nombreCompleto.toUpperCase()) == 'SIN ASIGNAR');
                  if (tieneSinAsignar) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se puede ejecutar: Hay números sin asignar.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  try {
      // 1. Ejecutar anticipos
      final resultEjecutar = await ref.read(insertarAnticipoTigo(widget.periodoCobrado).future);
      ref.invalidate(facturasTigoProvider);

      // 2. Insertar datos (solo si ejecutar fue exitoso)
      if (resultEjecutar) {
        final audUsuario = await ref.read(userProvider.notifier).getCodUsuario();
        final resultInsertar = await ref.read(ejecutarTigo((widget.periodoCobrado, audUsuario)).future);
        setState(() {
          mostrarTigoEjecutado = true;
        });
        ref.invalidate(obtenerTigoEjecutado((_empresaSeleccionada, widget.periodoCobrado)));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultInsertar
                ? '¡Anticipos y datos insertados correctamente!'
                : 'Anticipos ejecutados, pero no se pudo insertar los datos.'),
            backgroundColor: resultInsertar ? Colors.green : Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo ejecutar anticipos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al ejecutar: $e')),
      );
    }
                }
              },
              /*onInsertarDatos: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Insertar datos'),
                    content: const Text('¿Desea insertar los datos de la tabla?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Insertar'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  final resumen = ref.read(tigoResumenDetallado(widget.periodoCobrado)).asData?.value ?? [];
                  final tieneSinAsignar = resumen.any((r) => (r.nombreCompleto?.toUpperCase() ?? '') == 'SIN ASIGNAR');
                  if (tieneSinAsignar) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se puede insertar: Hay números sin asignar.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  try {
                    final audUsuario = await ref.read(userProvider.notifier).getCodUsuario();
                    final result = await ref.read(ejecutarTigo((widget.periodoCobrado, audUsuario)).future);
                    setState(() {
                      mostrarTigoEjecutado = true;
                    });
                    ref.invalidate(obtenerTigoEjecutado(widget.periodoCobrado));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result
                            ? '¡Datos insertados correctamente!'
                            : 'No se pudo insertar los datos.'),
                        backgroundColor: result ? Colors.green : Colors.red,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al insertar: $e')),
                    );
                  }
                }
              },*/
            ),
          ),
        ),
      ],
    ),
  )
  );
}
  // Dentro de _ResumenDetalladoScreenState

Widget _buildEmpresaFiltro(
  List<String> empresas,
  String? empresaSeleccionada,
  ValueChanged<String?> onChanged,
) {
  return SizedBox(
    width: 220,
    child: DropdownButtonFormField<String>(
      value: empresaSeleccionada,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Filtrar por empresa',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Todas las empresas'),
        ),
        ...empresas.map((empresa) => DropdownMenuItem(
              value: empresa,
              child: Text(empresa),
            )),
      ],
      onChanged: onChanged,
    ),
  );
}
//widgets
Widget _buildPeriodoCobradoPanel(String periodo) {
  return Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
    decoration: BoxDecoration(
      color: Colors.blue[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_month, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          'Período cobrado: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
            fontSize: 16,
          ),
        ),
        Text(
          periodo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}
Widget _buildEstadoPeriodo(String? estado) {
  if (estado == null) return const SizedBox();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        const Icon(Icons.info, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          'Estado del periodo: $estado',
          style: TextStyle(
            color: estado.toUpperCase() == 'EJECUTADO'
                ? Colors.green
                : Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}
Widget _buildMensajeEjecutado() {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(
      'Este periodo ya fue ejecutado.',
      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
    ),
  );
}
Widget _buildOperacionesPanel({
  required BuildContext context,
  required WidgetRef ref,
  required bool ejecutado,
  required bool tigoEjecutadoEstadoEjecutado,
  required String periodoCobrado,
  required VoidCallback onVerGrupos,
  required VoidCallback onGenerarReporte,
  required VoidCallback onEjecutar,
}) {
  return Column(
    children: [
      const SizedBox(height: 18),
      ElevatedButton.icon(
        icon: const Icon(Icons.person_add),
        label: const Text('Ver Grupos'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: Colors.blueGrey[100],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onVerGrupos,
      ),
      const SizedBox(height: 18),
      ElevatedButton.icon(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generar Reporte'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onGenerarReporte,
      ),
      const SizedBox(height: 18),
      PermissionWidget(
        buttonName: 'btnEjecutarTigo', // <-- USA EL NOMBRE DEL PERMISO CORRECTO
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('EJECUTAR'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: ejecutado ? Colors.grey : Colors.red[100],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: ejecutado ? null : onEjecutar,
        ),
      ),
      if (ejecutado) _buildMensajeEjecutado(),
    ],
  );
}
//dise;o movil
  Widget _buildResumenTableMobile(
  Map<String, List<TigoEjecutadoEntity>> grupos,
  Map<String, bool> expandedMap,
  void Function(String key) onExpand,
) {
  return Expanded(
    child: Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue[100]),
              dataRowColor: WidgetStateProperty.all(Colors.white),
              columnSpacing: 18,
              columns: const [
                DataColumn(label: SizedBox(width: 24)), // Expander
                DataColumn(label: Text('TELÉFONO', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('NOMBRE COMPLETO', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('DESCRIPCIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('EMPRESA', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('TOTAL COBRADO', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('MONTO EMPRESA', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('MONTO EMPLEADO', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: grupos.entries.expand((entry) {
                final key = entry.key;
                final grupo = entry.value;
                final principal = grupo.firstWhere(
                  //(r) => r.descripcion == null || r.descripcion == r.nombreCompleto,
                  (r) => r.descripcion == r.nombreCompleto,
                  orElse: () => grupo.first,
                );
                final detalles = grupo.where((r) => r != principal).toList();
                final isExpanded = expandedMap[key] ?? false;
                final esSinAsignar = (principal.nombreCompleto ).toUpperCase() == 'SIN ASIGNAR';

                List<DataRow> rows = [
                  DataRow(
                    color: esSinAsignar
                        ? WidgetStateProperty.all(Colors.red[50])
                        : WidgetStateProperty.all(Colors.blue[50]),
                    cells: [
                      DataCell(
                        detalles.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.blue,
                                ),
                                onPressed: () => onExpand(key),
                              )
                            : const SizedBox(width: 24),
                      ),
                      DataCell(Text(principal.corporativo.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Row(
                        children: [
                          if (esSinAsignar)
                            const Icon(Icons.warning, color: Colors.red, size: 18),
                          Flexible(
                            child: Text(
                              principal.nombreCompleto ,
                              style: TextStyle(
                                color: esSinAsignar ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )),
                      DataCell(Text(principal.descripcion , style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(principal.empresa ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(principal.totalCobradoXCuenta.toStringAsFixed(2) , style: const TextStyle(color: Colors.green))),
                      DataCell(Text(principal.montoCubiertoXEmpresa.toStringAsFixed(2), style: const TextStyle(color: Colors.deepPurple))),
                      DataCell(Text(principal.montoEmpleado.toStringAsFixed(2) , style: const TextStyle(color: Colors.indigo))),
                    ],
                  ),
                ];

                if (isExpanded) {
                  rows.addAll(detalles.map((detalle) {
                    return DataRow(
                      color: MaterialStateProperty.all(const Color(0xFFFFF3E0)), // naranja claro
                      cells: [
                        const DataCell(SizedBox(width: 24)),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(detalle.corporativo?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        const DataCell(Text('', style: TextStyle(fontSize: 13))),
                        DataCell(Text(detalle.descripcion, style: const TextStyle(fontSize: 13))),
                        DataCell(Text(detalle.empresa ?? '', style: const TextStyle(fontSize: 13))),
                        DataCell(Text(detalle.totalCobradoXCuenta.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: Colors.green))),
                        DataCell(Text(detalle.montoCubiertoXEmpresa.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: Colors.deepPurple))),
                        DataCell(Text(detalle.montoEmpleado.toStringAsFixed(2) , style: const TextStyle(fontSize: 13, color: Colors.indigo))),
                      ],
                    );
                  }));
                }

                return rows;
              }).toList(),
            ),
          ),
        ),
      ),
    ),
  );
}

/*Widget _buildBuscadorResumen({
  required TextEditingController controller,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, teléfono o empresa',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onChanged: onChanged,
    ),
  );
}*/
Widget _buildRefreshButtonResumen({
  required VoidCallback onRefresh,
  String tooltip = 'Refrescar datos',
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
      tooltip: tooltip,
      onPressed: onRefresh,
    ),
  );
}
// Encabezado y tabla
Widget _buildArbolTablaSimulada(List<TigoEjecutadoEntity> arbol) {
  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.blue[800],
          border: const Border(bottom: BorderSide(color: Colors.blueGrey, width: 1)),
        ),
        child: Row(
          children: const [
            SizedBox(width: 40),
            _TablaCell('TELÉFONO', isHeader: true),
            _TablaCell('NOMBRE', isHeader: true),
            _TablaCell('DESCRIPCIÓN', isHeader: true),
            _TablaCell('EMPRESA', isHeader: true),
            _TablaCell('TOTAL', isHeader: true),
            _TablaCell('EMPRESA', isHeader: true),
            _TablaCell('EMPLEADO', isHeader: true),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          children: _buildArbolTablaRows(arbol, 0),
        ),
      ),
    ],
  );
}

List<Widget> _buildArbolTablaRows(List<TigoEjecutadoEntity> lista, int nivel) {
  List<Widget> rows = [];
  for (int i = 0; i < lista.length; i++) {
    final e = lista[i];
    final tieneHijos = e.items.isNotEmpty;
    final isExpanded = expandedArbolMap[e.codEmpleado] ?? false;
    final isChild = nivel > 0;
    final esSinAsignar = (e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR');

    rows.add(
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: esSinAsignar
                ? Colors.red[100]
                : isChild
                    ? Colors.blue[50]
                    : (i % 2 == 0 ? Colors.white : Colors.grey[200]),
            border: Border(
              left: isChild && !esSinAsignar
                  ? BorderSide(color: Colors.blue[300]!, width: 4)
                  : BorderSide.none,
              bottom: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: tieneHijos
                    ? IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: esSinAsignar ? Colors.red : Colors.blue[800],
                        ),
                        onPressed: () {
                          setState(() {
                            expandedArbolMap[e.codEmpleado] = !isExpanded;
                          });
                        },
                      )
                    : null,
              ),
              _TablaCell(
                e.corporativo??'',
                nivel: nivel,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.nombreCompleto.startsWith('ZZZ')
                ?e.nombreCompleto.replaceFirst(RegExp(r'^ZZZ\s*'), '').trim()
                : e.nombreCompleto,
                nivel: nivel,
                isBold: nivel == 0,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
                icon: esSinAsignar ? Icons.warning : null,
              ),
              _TablaCell(
                e.descripcion,
                nivel: nivel,
                isBold: nivel == 0,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
                //icon: esSinAsignar ? Icons.warning : null,
              ),
              _TablaCell(
                e.empresa ?? '',
                nivel: nivel,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.totalCobradoXCuenta.toStringAsFixed(2),
                nivel: nivel,
                align: TextAlign.right,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.montoCubiertoXEmpresa.toStringAsFixed(2),
                nivel: nivel,
                align: TextAlign.right,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.montoEmpleado.toStringAsFixed(2) ,
                nivel: nivel,
                align: TextAlign.right,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
            ],
          ),
        ),
      ),
    );

    if (tieneHijos && isExpanded) {
      rows.addAll(_buildArbolTablaRows(e.items, nivel + 1));
    }
  }
  return rows;
}


List<TigoEjecutadoEntity> filtrarArbolPorEmpresa(List<TigoEjecutadoEntity> arbol, String? empresa) {
  List<TigoEjecutadoEntity> resultado = [];
  for (final nodo in arbol) {
    // Siempre incluye el nodo resumen
    if (nodo.nombreCompleto.trim().startsWith('ZZZ TOTAL')) {
      resultado.add(nodo);
      continue;
    }
    // Si no hay empresa seleccionada, incluye todo
    if (empresa == null || empresa.trim().isEmpty) {
      resultado.add(
        nodo.copyWith(
          items: filtrarArbolPorEmpresa(nodo.items, empresa),
        ),
      );
    } else if ((nodo.empresa ?? '').trim() == empresa.trim()) {
      resultado.add(
        nodo.copyWith(
          items: filtrarArbolPorEmpresa(nodo.items, empresa),
        ),
      );
    } else {
      // Si el nodo no es de la empresa, pero tiene hijos de la empresa, incluye solo los hijos
      final hijosFiltrados = filtrarArbolPorEmpresa(nodo.items, empresa);
      if (hijosFiltrados.isNotEmpty) {
        resultado.add(
          nodo.copyWith(
            items: hijosFiltrados,
          ),
        );
      }
    }
  }
  return resultado;
}
//ARBOL TIGO EJECUTADO
Widget _buildArbolTablaTigoEjecutado(List<TigoEjecutadoEntity> arbol) {
  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.blue[800],
          border: const Border(bottom: BorderSide(color: Colors.blueGrey, width: 1)),
        ),
        child: Row(
          children: const [
            SizedBox(width: 40),
            _TablaCell('TELÉFONO', isHeader: true),
            _TablaCell('NOMBRE', isHeader: true),
            _TablaCell('DESCRIPCIÓN', isHeader: true),
            _TablaCell('EMPRESA', isHeader: true),
            _TablaCell('ESTADO', isHeader: true),
            _TablaCell('TOTAL', isHeader: true),
            _TablaCell('EMPRESA', isHeader: true),
            _TablaCell('EMPLEADO', isHeader: true),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          children: _buildArbolTigoEjecutadoRows(arbol, 0),
        ),
      ),
    ],
  );
}

List<Widget> _buildArbolTigoEjecutadoRows(List<TigoEjecutadoEntity> lista, int nivel) {
  List<Widget> rows = [];
  for (int i = 0; i < lista.length; i++) {
    final e = lista[i];
    final tieneHijos = e.items.isNotEmpty;
    final isExpanded = expandedArbolMap[e.codEmpleado] ?? false;
    final isChild = nivel > 0;
    final esSinAsignar = (e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR');

    rows.add(
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: esSinAsignar
                ? Colors.red[100]
                : isChild
                    ? Colors.blue[50]
                    : (i % 2 == 0 ? Colors.white : Colors.grey[200]),
            border: Border(
              left: isChild && !esSinAsignar
                  ? BorderSide(color: Colors.blue[300]!, width: 4)
                  : BorderSide.none,
              bottom: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: tieneHijos
                    ? IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: esSinAsignar ? Colors.red : Colors.blue[800],
                        ),
                        onPressed: () {
                          expandedArbolMap[e.codEmpleado] = !isExpanded;
                          setState(() {});
                        },
                      )
                    : null,
              ),
              _TablaCell(
                e.corporativo ?? '',
                nivel: nivel,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.nombreCompleto.startsWith('ZZZ')
                  ? e.nombreCompleto.replaceFirst(RegExp(r'^ZZZ\s*'), '').trim()
                  : e.nombreCompleto,
                nivel: nivel,
                isBold: nivel == 0,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
                icon: esSinAsignar ? Icons.warning : null,
              ),
              _TablaCell(
                e.descripcion,
                nivel: nivel,
                isBold: nivel == 0,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.empresa ?? '',
                nivel: nivel,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.estado ,
                nivel: nivel,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.totalCobradoXCuenta.toStringAsFixed(2),
                nivel: nivel,
                align: TextAlign.right,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.montoCubiertoXEmpresa.toStringAsFixed(2),
                nivel: nivel,
                align: TextAlign.right,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
              _TablaCell(
                e.montoEmpleado.toStringAsFixed(2),
                nivel: nivel,
                align: TextAlign.right,
                isChild: isChild,
                textColor: esSinAsignar ? Colors.red[700] : null,
              ),
            ],
          ),
        ),
      ),
    );

    if (tieneHijos && isExpanded) {
      rows.addAll(_buildArbolTigoEjecutadoRows(e.items, nivel + 1));
    }
  }
  return rows;
}

}
// Celda de tabla con mejor diseño
class _TablaCell extends StatelessWidget {
  final String text;
  final int nivel;
  final bool isHeader;
  final bool isBold;
  final TextAlign align;
  final bool isChild;
  final Color? textColor;
  final IconData? icon;
  const _TablaCell(
    this.text, {
    this.nivel = 0,
    this.isHeader = false,
    this.isBold = false,
    this.align = TextAlign.center,
    this.isChild = false,
    this.textColor,
    this.icon,
  });
  @override
Widget build(BuildContext context) {
  // Determina la alineación principal del Row basada en el parámetro 'align'
  MainAxisAlignment rowAlignment;
  if (align == TextAlign.right) {
    rowAlignment = MainAxisAlignment.end; // 'end' alinea a la derecha
  } else if (align == TextAlign.left) {
    rowAlignment = MainAxisAlignment.start; // 'start' alinea a la izquierda
  } else {
    rowAlignment = MainAxisAlignment.center; // Por defecto o TextAlign.center
  }

  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isHeader ? Colors.blue[900]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isHeader ? 14 : 10,
        horizontal: isChild ? 32.0 : 8.0,
      ),
      // Elimina la propiedad 'alignment' del Container ya que el Row la controlará.
      // alignment: Alignment.center, // <-- ELIMINADO

      // El Row ahora usa la alineación dinámica
      child: Row(
        mainAxisAlignment: rowAlignment, // <-- PROPIEDAD CLAVE MODIFICADA
        children: [
          if (icon != null)
            Icon(icon, color: textColor ?? Colors.red, size: 18),
          Flexible(
            child: Text(
              text,
              // Mantenemos textAlign: align para que el texto dentro del Flexible se alinee
              textAlign: align, 
              style: TextStyle(
                fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: textColor ?? (isHeader ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}