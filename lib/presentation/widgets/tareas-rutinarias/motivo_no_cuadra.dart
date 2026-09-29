// Destino final: lib/presentation/widgets/tareas-rutinarias/motivo_no_cuadra.dart
import 'package:flutter/material.dart';

/// Pregunta qué no cuadró antes de marcar un traspaso.
///
/// Devuelve la observación, o `null` si la persona canceló: cancelar a mitad
/// de camino no deja la fila marcada como que no cuadra. El servidor también
/// exige la observación (error 23 del SP); esto solo evita el viaje.
///
/// Lo usan las dos pantallas que marcan traspasos de Caja AXA: la tarea del
/// cajero (295) y la revisión de Cierre de Operaciones.
Future<String?> pedirMotivoNoCuadra(BuildContext context, String? inicial) =>
    showDialog<String>(
      context: context,
      builder: (_) => _DialogoMotivo(inicial: inicial),
    );

/// El controlador del campo vive en el diálogo, no en la función que lo abre.
///
/// **Por qué importa.** Liberarlo apenas `showDialog` devuelve lo mata mientras
/// el diálogo todavía se está cerrando: durante esa animación el campo se
/// vuelve a construir y se suscribe al controlador, y Flutter corta con
/// "A TextEditingController was used after being disposed" — pantalla roja
/// entera en la web (Marcelo, 2026-09-11, al marcar un traspaso). Aquí lo
/// libera el `dispose()` del State, que corre recién cuando la ruta ya salió.
class _DialogoMotivo extends StatefulWidget {
  final String? inicial;

  const _DialogoMotivo({this.inicial});

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  late final TextEditingController _campo = TextEditingController(
    text: widget.inicial ?? '',
  );
  final _formulario = GlobalKey<FormState>();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formulario.currentState?.validate() != true) return;
    Navigator.of(context).pop(_campo.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('¿Qué no cuadró?'),
    content: Form(
      key: _formulario,
      child: TextFormField(
        controller: _campo,
        autofocus: true,
        maxLength: 300,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Observación',
          hintText:
              'Ejemplo: el monto en el formulario dice 1.200 y '
              'en el sistema 1.020.',
        ),
        validator:
            (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Escribe qué fue lo que no cuadró.'
                    : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _guardar, child: const Text('Guardar')),
    ],
  );
}
