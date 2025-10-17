import 'dart:io' as io;
import 'dart:typed_data';
import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/resumen_detallado.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:universal_html/html.dart' as html;

class FacturasEjecutadasView extends ConsumerStatefulWidget {
  const FacturasEjecutadasView({super.key});

  @override
  ConsumerState<FacturasEjecutadasView> createState() => _FacturasEjecutadasViewState();
}

class _FacturasEjecutadasViewState extends ConsumerState<FacturasEjecutadasView> {
  Uint8List? bytesFacturas;
  String? fileNameFacturas;
  bool isLoading = false;

  String? _periodoSeleccionado;
  String? _estadoSeleccionado;

@override
Widget build(BuildContext context) {
  final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
  final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);
  final isMobile = ResponsiveUtilsBosque.isMobile(context);

  return Scaffold(
    appBar: AppBar(
      title: const Text('Consumo Tigo'),
      centerTitle: true,
      actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Refrescar',
      onPressed: () {
        ref.invalidate(facturasTigoProvider);
      },
    ),
  ],
    ),
    body: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: isMobile
          ? _buildFacturasEjecutadasListMobile(ref.watch(facturasTigoProvider))
          : Center(
              child: SizedBox(
                width: 900,
                child: _buildFacturasEjecutadasList(ref.watch(facturasTigoProvider)),
              ),
            ),
    ),
  );
}
   Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }
  
  Widget _buildFacturasEjecutadasListMobile(AsyncValue<List<FacturaTigoEntity>> facturasAsync) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Filtros apilados
      facturasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (facturas) {
          final periodos = facturas.map((f) => f.periodoCobrado).toSet().toList();
          final estados = facturas.map((f) => f.estado ?? 'Sin Estado').toSet().toList();

          return Column(
            children: [
              DropdownButtonFormField<String>(
                value: _periodoSeleccionado,
                decoration: const InputDecoration(labelText: 'Período Cobrado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...periodos.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                ],
                onChanged: (value) => setState(() => _periodoSeleccionado = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...estados.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                ],
                onChanged: (value) => setState(() => _estadoSeleccionado = value),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      // Botón subir factura centrado
      Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir Factura'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            await _mostrarDialogoSubirFactura(context, ref);
          },
        ),
      ),
      const SizedBox(height: 16),
      // Lista
      Expanded(
        child: facturasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (facturas) {
            final facturasFiltradas = facturas.where((f) {
              final periodoOk = _periodoSeleccionado == null || f.periodoCobrado == _periodoSeleccionado;
              final estadoOk = _estadoSeleccionado == null || (f.estado ?? 'Sin Estado') == _estadoSeleccionado;
              return periodoOk && estadoOk;
            }).toList();

            if (facturasFiltradas.isEmpty) {
              return const Center(child: Text('No hay facturas ejecutadas.'));
            }

            return ListView.separated(
              itemCount: facturasFiltradas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final factura = facturasFiltradas[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  child: ListTile(
                    title: Text('Período: ${factura.periodoCobrado }'),
                    subtitle: Text('Estado: ${factura.estado }'),
                    trailing: Text(
                      'Total: ${factura.totalCobradoXCuenta.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _navegarADetalle(context, factura.periodoCobrado ),
                    leading: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[100],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Ver'),
                      onPressed: () => _navegarADetalle(context, factura.periodoCobrado ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildFacturasEjecutadasList(AsyncValue<List<FacturaTigoEntity>> facturasAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros
        facturasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (facturas) {
            final periodos = facturas.map((f) => f.periodoCobrado).toSet().toList();
            final estados = facturas.map((f) => f.estado ?? 'Sin Estado').toSet().toList();

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _periodoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Período Cobrado'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...periodos.map((p) => DropdownMenuItem(value: p, child: Text(p ))),
                    ],
                    onChanged: (value) => setState(() => _periodoSeleccionado = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _estadoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...estados.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                    ],
                    onChanged: (value) => setState(() => _estadoSeleccionado = value),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Botón subir factura alineado a la derecha
        Row(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir Factura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await _mostrarDialogoSubirFactura(context, ref);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lista
        Expanded(
          child: facturasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (facturas) {
              final facturasFiltradas = facturas.where((f) {
                final periodoOk = _periodoSeleccionado == null || f.periodoCobrado == _periodoSeleccionado;
                final estadoOk = _estadoSeleccionado == null || (f.estado ?? 'Sin Estado') == _estadoSeleccionado;
                return periodoOk && estadoOk;
              }).toList();

              if (facturasFiltradas.isEmpty) {
                return const Center(child: Text('No hay facturas ejecutadas.'));
              }

              return ListView.separated(
                itemCount: facturasFiltradas.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final factura = facturasFiltradas[index];
                  return ListTile(
                    title: Text('Período: ${factura.periodoCobrado }'),
                    subtitle: Text('Estado: ${factura.estado }'),
                    trailing: Text(
                      'Total: ${factura.totalCobradoXCuenta.toStringAsFixed(2) }',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _navegarADetalle(context, factura.periodoCobrado ),
                    leading: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[100],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Ver detalles'),
                      onPressed: () => _navegarADetalle(context, factura.periodoCobrado),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  

  Future<void> _mostrarDialogoSubirFactura(BuildContext context, WidgetRef ref) async {
    Uint8List? localBytes;
    String? localFileName;
    bool localLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Subir Factura Tigo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Seleccionar archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: localLoading
    ? null
    : () async {
        await seleccionarArchivo((bytes, name) {
          setDialogState(() {
            localBytes = bytes;
            localFileName = name;
          });
        });
      },
                  ),
                  if (localFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        localFileName!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  child: localLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Subir'),
                  onPressed: (localBytes != null && !localLoading)
                      ? () async {
                          setDialogState(() => localLoading = true);
                          final audUsuario = await getCodUsuario(); // Cambia por el usuario real
                          final result = await ref.read(
                            subirExcelFacturasTigoProvider((
                              localBytes!,
                              localFileName ?? 'facturas.xlsx',
                              audUsuario,
                            )).future,
                          );
                          // refrescar lista
                          ref.invalidate(facturasTigoProvider); 
                          setDialogState(() => localLoading = false);
                          if (result['ok'] == 'success') {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Archivo subido correctamente!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al subir archivo: ${result['msg']}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navegarADetalle(BuildContext context, String periodoCobrado) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ResumenDetalladoScreen(periodoCobrado: periodoCobrado),
    ),
  );
}

  Future<void> seleccionarArchivo(Function(Uint8List, String) onSelected) async {
  if (kIsWeb) {
    // Solo para web
    // ignore: avoid_web_libraries_in_flutter
    
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.xlsx,.xlsm';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file!);
      reader.onLoadEnd.listen((e) {
        final bytes = reader.result as Uint8List;
        onSelected(bytes, file.name);
      });
    });
  } else if (io.Platform.isAndroid) {
    // Solo para Android
    // Requiere flutter_file_dialog
   
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
      //allowedExtensions: ['xlsx', 'xlsm'],
    );
    final filePath = await FlutterFileDialog.pickFile(params: params);
if (filePath != null) {
  final file = io.File(filePath);
  final bytes = await file.readAsBytes();
  final fileName = file.uri.pathSegments.last;
  if (fileName.endsWith('.xlsx') || fileName.endsWith('.xlsm')) {
    onSelected(bytes, fileName);
  } else {
    // Opcional: muestra un mensaje de error
    // Puedes usar un callback o un SnackBar aquí
  }
}
  }
}
}