import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/area_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget expandible que permite crear un área nueva directamente
/// desde el formulario de cargo, sin abrir un diálogo adicional.
///
/// Uso:
/// ```dart
/// NuevaAreaExpandable(
///   codEmpresa: widget.codEmpresa,
///   onAreaCreada: (codArea) {
///     setState(() => _codAreaSeleccionada = codArea);
///   },
/// )
/// ```
class NuevaAreaExpandable extends ConsumerStatefulWidget {
  final int codEmpresa;

  /// Se invoca con el codArea de la nueva área después de guardar.
  /// El padre puede usarlo para auto-seleccionar el área en el dropdown.
  final Function(int codArea) onAreaCreada;

  const NuevaAreaExpandable({
    super.key,
    required this.codEmpresa,
    required this.onAreaCreada,
  });

  @override
  ConsumerState<NuevaAreaExpandable> createState() =>
      _NuevaAreaExpandableState();
}

class _NuevaAreaExpandableState extends ConsumerState<NuevaAreaExpandable> {
  bool _expandido = false;
  bool _guardando = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // En form_area.dart -> método _guardarArea()

  Future<void> _guardarArea() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);

    try {
      final user = ref.read(userProvider);
      // 🆕 Usamos el nuevo provider
      final registrarFn = ref.read(registrarAreaProvider);

      final nuevaArea = AreaEntity(
        codArea: 0,
        codEmpresa: widget.codEmpresa,
        nombreArea: _nombreController.text.trim(),
        descripcion: '',
        estado: 1,
        audUsuario: user?.codUsuario ?? 0,
      );

      final response = await registrarFn(nuevaArea);

      if (!mounted) return;

      if (response.status == 201 ||
          (response.idGenerado != null && response.idGenerado! > 0)) {
        // 🔥 LA SOLUCIÓN: ref.refresh fuerza la petición inmediata y devolvemos el await
        // Esto asegura que la caché de Riverpod tenga los nuevos datos YA.
        await ref.refresh(areasPorEmpresaProvider(widget.codEmpresa).future);

        if (response.idGenerado != null && response.idGenerado! > 0) {
          widget.onAreaCreada(response.idGenerado!);
        }

        _nombreController.clear();
        setState(() {
          _expandido = false;
          _guardando = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ ${response.message}')));
      } else {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${response.message}'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // form_area.dart

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_expandido)
            // BOTÓN COMPACTO: Se verá como un pequeño botón de texto con icono
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _expandido = true),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Nueva Área',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            )
          else
            // FORMULARIO EXPANDIDO DENTRO DEL CARD
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Divider(),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la nueva área',
                        isDense: true,
                        prefixIcon: Icon(Icons.business, size: 20),
                      ),
                      // 👇 1. BLOQUEA EL TECLADO PARA CARACTERES NO PERMITIDOS
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          // Permite a-z, A-Z, 0-9, acentos, ñ, espacios (\s) y guion (\-)
                          RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\-]'),
                        ),
                      ],
                      // 👇 2. VALIDA QUE NO ESTÉ VACÍO AL GUARDAR
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requerido';
                        }
                        // Validación extra por si acaso el usuario pega texto
                        if (!RegExp(
                          r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\-]+$',
                        ).hasMatch(v.trim())) {
                          return 'Solo letras, números y guiones';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // BOTÓN CANCELAR
                        TextButton(
                          onPressed: () {
                            _nombreController.clear();
                            setState(() => _expandido = false);
                          },
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // BOTÓN GUARDAR (Más pequeño)
                        ElevatedButton(
                          onPressed: _guardando ? null : _guardarArea,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(80, 32),
                          ),
                          child:
                              _guardando
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
