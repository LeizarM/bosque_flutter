import 'dart:typed_data';

import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Botón de voucher con 3 estados visuales:
/// - Sin voucher: botón para subir
/// - Subiendo: indicador de progreso
/// - Con voucher: chip verde + opción de reemplazar
class VoucherButton extends ConsumerWidget {
  final BigInt idTransaccion;
  final int codEmpresa;

  const VoucherButton({
    super.key,
    required this.idTransaccion,
    this.codEmpresa = 0,
  });

  Future<void> _seleccionarYSubir(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // necesario para web (bytes)
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;

    ref
        .read(transaccionFormProvider.notifier)
        .subirVoucher(
          idTransaccion: idTransaccion,
          audUsuario: audUsuario,
          filePath: kIsWeb ? null : file.path,
          fileBytes: file.bytes,
          fileName: file.name,
        );
  }

  Future<void> _verVoucher(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final repo = PagosExtranjerosImpl();
      final codEmpresaActual = ref.read(transaccionFormProvider).codEmpresa;
      final (bytes, contentType) = await repo.descargarVoucher(
        idTransaccion,
        codEmpresa: codEmpresaActual != 0 ? codEmpresaActual : codEmpresa,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(); // quitar loading
      _mostrarVoucher(context, bytes, contentType);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // quitar loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al descargar voucher: $e')));
    }
  }

  void _mostrarVoucher(
    BuildContext context,
    dynamic bytes,
    String contentType,
  ) {
    final isImage = contentType.startsWith('image/');
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: cs.primaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Voucher',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child:
                      isImage
                          ? InteractiveViewer(
                            child: Image.memory(bytes, fit: BoxFit.contain),
                          )
                          : PdfPreview(
                            build: (_) async => bytes as Uint8List,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            allowPrinting: false,
                            allowSharing: false,
                            pdfFileName: 'voucher.pdf',
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(transaccionFormProvider);
    final cs = Theme.of(context).colorScheme;

    // Estado: subiendo
    if (formState.subiendoVoucher) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Estado: tiene voucher
    if (formState.tieneVoucher) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionChip(
            avatar: Icon(Icons.check_circle, color: cs.primary, size: 18),
            label: const Text('Voucher'),
            onPressed: () => _verVoucher(context, ref),
            backgroundColor: cs.primaryContainer,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.upload_file, size: 20),
            tooltip: 'Reemplazar voucher',
            onPressed: () => _seleccionarYSubir(context, ref),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    // Estado: sin voucher
    return OutlinedButton.icon(
      icon: const Icon(Icons.upload_file, size: 18),
      label: const Text('Subir Voucher'),
      onPressed: () => _seleccionarYSubir(context, ref),
    );
  }
}
