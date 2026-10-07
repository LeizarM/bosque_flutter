// Destino final: lib/presentation/widgets/tareas-rutinarias/motivo_no_cuadra.dart
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:flutter/material.dart';

/// Pregunta qué no cuadró antes de marcar un traspaso.
///
/// Devuelve la observación, o `null` si la persona canceló: cancelar a mitad
/// de camino no deja la fila marcada como que no cuadra. Que no venga vacía
/// lo exige el servidor (error 23 del SP), no este diálogo: las reglas de
/// registro van en SQL. El tope de 300 es el largo de la columna.
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

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _guardar() => cerrarRuta(context, _campo.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('¿Qué no cuadró?'),
    content: TextField(
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
    ),
    actions: [
      TextButton(
        onPressed: () => cerrarRuta(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _guardar, child: const Text('Guardar')),
    ],
  );
}
