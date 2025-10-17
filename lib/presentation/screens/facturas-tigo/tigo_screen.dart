import 'dart:typed_data';

import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:bosque_flutter/presentation/screens/facturas-tigo/ver_factura.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FacturasTigoView extends ConsumerStatefulWidget {
  const FacturasTigoView({Key? key}) : super(key: key);

  @override
  ConsumerState<FacturasTigoView> createState() => _FacturasTigoViewState();
}

class _FacturasTigoViewState extends ConsumerState<FacturasTigoView> {
  Uint8List? bytesFacturas;
  String? fileNameFacturas;

  Uint8List? bytesSocios;
  String? fileNameSocios;
  bool isLoading = false;

 @override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Scaffold(
        backgroundColor: Colors.blueGrey[50],
        appBar: AppBar(
          title: const Text('Subir Facturas Tigo'),
          centerTitle: true,
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file, size: 90, color: Colors.blue),
                const SizedBox(height: 24),
                _buildFacturasTigoInstructions(),
                const SizedBox(height: 32),

                // --- Cards en fila para escritorio/tablet, columna en móvil ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Facturas
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long, color: Colors.blue[700], size: 28),
                                      const SizedBox(width: 10),
                                      Text('Facturas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                 // _buildSeleccionarFacturaButton(),
                                  if (fileNameFacturas != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: _buildArchivoSeleccionadoCard(
                                        fileNameFacturas!,
                                        Colors.lightBlue[50]!,
                                        Icons.insert_drive_file,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  _buildSubirFacturasButton(ref),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Card Socios
                       /* Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people, color: Colors.purple[700], size: 28),
                                      const SizedBox(width: 10),
                                      Text('Socios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[800])),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildSeleccionarSociosButton(),
                                  if (fileNameSocios != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: _buildArchivoSeleccionadoCard(
                                        fileNameSocios!,
                                        Colors.purple[50]!,
                                        Icons.insert_drive_file,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  _buildSubirSociosButton(ref),
                                ],
                              ),
                            ),
                          ),
                        ),*/
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Botón para ver facturas/socios
                _buildVerFacturasSociosButton(),
                const SizedBox(height: 24),

                // Ayuda
                _buildAyudaBox(),
              ],
            ),
          ),
        ),
      ),
      if (isLoading)
        Container(
          color: Colors.black.withOpacity(0.4),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 6,
                ),
                SizedBox(height: 24),
                Text(
                  'Subiendo archivo...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

 /* Future<void> seleccionarArchivoExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xlsm'],
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        bytesFacturas = result.files.single.bytes;
        fileNameFacturas = result.files.single.name;
      });
    } else {
      setState(() {
        bytesFacturas = null;
        fileNameFacturas = null;
      });
    }
  }*/

  

  Widget _buildFacturasTigoInstructions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(
            'FACTURAS TIGO',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Siga estos pasos para subir su archivo de facturas Tigo:',
            style: TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.looks_one, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Presione el botón "Seleccionar Factura".',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.looks_two, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifique el nombre del archivo seleccionado.',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.looks_3, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Presione "Subir archivo" para enviarlo.',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 /* Widget _buildSeleccionarFacturaButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.folder_open, size: 28),
      label: const Text('Seleccionar factura', style: TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(260, 56),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 20),
        elevation: 4,
      ),
      onPressed: isLoading ? null : seleccionarArchivoFacturas,
    );
  }

  Widget _buildSeleccionarSociosButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.folder_open, size: 28),
      label: const Text(
        'Seleccionar archivo de socios TIGO',
        style: TextStyle(fontSize: 20),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(260, 56),
        backgroundColor: Colors.purple[300],
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 20),
        elevation: 4,
      ),
      onPressed: isLoading ? null : seleccionarArchivoSocios,
    );
  }*/

  Widget _buildArchivoSeleccionadoCard(
    String fileName,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: ListTile(
        leading: Icon(
          icon,
          color: color == Colors.purple[50] ? Colors.purple : Colors.blue,
          size: 32,
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildVerFacturasSociosButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.table_view, size: 28),
      label: const Text('Ver facturas/socios', style: TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(260, 56),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 20),
        elevation: 4,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FacturasEjecutadasView()),
        );
      },
    );
  }

  Widget _buildAyudaBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '¿Necesita ayuda? Llame al soporte o pida ayuda a un compañero.',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubirFacturasButton(WidgetRef ref) {
    return ElevatedButton.icon(
      icon:
          isLoading
              ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
              : const Icon(Icons.cloud_upload, size: 28),
      label:
          isLoading
              ? const Text('Subiendo...', style: TextStyle(fontSize: 20))
              : const Text('Subir archivo', style: TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(260, 56),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 20),
        elevation: 4,
      ),
      onPressed:
          (bytesFacturas != null && !isLoading)
              ? () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('¿Está seguro?'),
                        content: const Text(
                          '¿Desea subir el archivo seleccionado?',
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          ElevatedButton(
                            child: const Text('Sí, subir'),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                );
                if (confirm != true) return;

                setState(() => isLoading = true);
                final audUsuario = 34; // Cambia por el usuario real
                final result = await ref.read(
                  subirExcelFacturasTigoProvider((
                    bytesFacturas!,
                    fileNameFacturas ?? 'facturas.xlsx',
                    audUsuario,
                  )).future,
                );
                setState(() => isLoading = false);
                if (result['ok'] == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Archivo subido correctamente!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  setState(() {
                    bytesFacturas = null;
                    fileNameFacturas = null;
                  });
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
    );
  }

 /* Future<void> seleccionarArchivoFacturas() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xlsm'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        bytesFacturas = result.files.single.bytes;
        fileNameFacturas = result.files.single.name;
      });
    }
  }

  Future<void> seleccionarArchivoSocios() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xlsm'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        bytesSocios = result.files.single.bytes;
        fileNameSocios = result.files.single.name;
      });
    }
  }*/
}
