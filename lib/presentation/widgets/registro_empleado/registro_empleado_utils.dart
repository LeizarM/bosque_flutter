// lib/presentation/widgets/registro_empleado/registro_empleado_utils.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ============================================
// UTILIDADES DE FECHA
// ============================================

class FechaUtils {
  /// Formatea DateTime a String en formato dd/MM/yyyy
  static String formatDate(DateTime? date) {  // ← Cambiar a DateTime?
    if (date == null) return '';  // ← Agregar esta línea
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Parsea String (dd/MM/yyyy) a DateTime
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) return null;  // ← Agregar null check
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Valida si una fecha es válida
  static bool isValidDate(String dateString) {
    return parseDate(dateString) != null;
  }
}
// ============================================
// CUSTOM DATE PICKER WIDGET
// ============================================

class CustomDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime)? onDateSelected;
  // Al ponerlo aquí, lo hacemos disponible
  final bool enabled; 

  const CustomDatePicker({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    // Al asignarle true aquí, CUALQUIER otro archivo que use 
    // CustomDatePicker seguirá funcionando igual que antes sin pedir cambios.
    this.enabled = true, 
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      // Usamos el valor de enabled
      enabled: enabled, 
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        border: const OutlineInputBorder(),
        isDense: true, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        filled: true,
        // Si está deshabilitado, le damos un tono gris suave
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        suffixIcon: Icon(
          Icons.calendar_today, 
          size: 18, 
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400
        ),
      ),
      validator: validator,
      // Solo permite el tap si enabled es true
      onTap: enabled ? () async {
        // ✅ Desenfoca primero para evitar error en Flutter Web
        FocusManager.instance.primaryFocus?.unfocus();
  final resolvedFirstDate = firstDate ?? DateTime(1900);
  final resolvedLastDate = lastDate ?? DateTime(2100);
  
  DateTime initialDate = DateTime.now();
  if (controller.text.isNotEmpty) {
    final parsed = FechaUtils.parseDate(controller.text);
    if (parsed != null) initialDate = parsed;
  }

  // Clamp initialDate to [firstDate, lastDate] range
  if (initialDate.isBefore(resolvedFirstDate)) {
    initialDate = resolvedFirstDate;
  } else if (initialDate.isAfter(resolvedLastDate)) {
    initialDate = resolvedLastDate;
  }

  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: resolvedFirstDate,
    lastDate: resolvedLastDate,
  );

  if (pickedDate != null) {
    controller.text = FechaUtils.formatDate(pickedDate);
    onDateSelected?.call(pickedDate);
  }
} : null,
    );
  }
}

// ============================================
// EMPLOYEE IMAGE CELL
// ============================================

class EmployeeImageCell extends ConsumerWidget {
  final int codEmpleado;

  const EmployeeImageCell({
    Key? key,
    required this.codEmpleado,
  }) : super(key: key);

  String _getImageUrl(int codEmpleado, int version) {
    return '${AppConstants.baseUrl}${AppConstants.getImageUrl}/$codEmpleado.jpg?v=$version';
  }

  void _showEmployeeImage(BuildContext context, WidgetRef ref) {
    final version = ref.watch(imageVersionProvider);
    final imageUrl = _getImageUrl(codEmpleado, version);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      alignment: Alignment.center,
                      child: const Text('Imagen no disponible'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(imageVersionProvider);
    final imageUrl = _getImageUrl(codEmpleado, version);

    return GestureDetector(
      onTap: () => _showEmployeeImage(context, ref),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: 25, color: Colors.grey.shade500);
            },
          ),
        ),
      ),
    );
  }
}
// ============================================
// CUSTOM DROPDOWN WIDGET (Genérico reutilizable)
// ============================================

/// Widget genérico para dropdowns que muestran un nombre pero guardan un código
/// 
/// Parámetros:
/// - asyncValue: AsyncValue con la lista de items
/// - label: Etiqueta del dropdown
/// - currentValue: Código seleccionado actual (lo que se guarda en BD)
/// - onChanged: Callback cuando cambia la selección
/// - getName: Función para extraer el nombre a mostrar (ej: (e) => e.nombre)
/// - getCode: Función para extraer el código a guardar (ej: (e) => e.codTipos)
/// - validator: Validador opcional
/// - maxHeight: Altura máxima del menú desplegable
class CustomDropdown<T extends Object> extends StatelessWidget {
  final AsyncValue<List<T>> asyncValue;
  final String label;
  final String? currentValue;
  final Function(String?) onChanged;
  final String Function(T) getName;
  final String Function(T) getCode;
  final String? Function(String?)? validator;
  final double maxHeight;

  const CustomDropdown({
    Key? key,
    required this.asyncValue,
    required this.label,
    required this.currentValue,
    required this.onChanged,
    required this.getName,
    required this.getCode,
    this.validator,
    this.maxHeight = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, stack) => const Center(
        child: Text('Error cargando datos'),
      ),
      data: (items) {
        // Crear dropdown items con código como value, nombre como display
        final dropdownItems = items.map((item) {
          final codigo = getCode(item);
          final nombre = getName(item);
          return DropdownMenuItem<String>(
            value: codigo, // Guardar el código
            child: Text(nombre, overflow: TextOverflow.ellipsis), // Mostrar nombre
          );
        }).toList();

        // Verificar que el código actual está en la lista disponible
        final validValue = dropdownItems.any((i) => i.value == currentValue)
            ? currentValue
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
          ),
          isExpanded: true,
          menuMaxHeight: maxHeight,
          items: dropdownItems,
          onChanged: onChanged,
          validator: validator ?? (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
        );
      },
    );
  }
}
// ============================================
// WIDGET PARA MOSTRAR DESCRIPCIÓN EN LUGAR DE CÓDIGO 
// ver ejemplo en detalle_educacion.dart
// ============================================

class DisplayValue<T> extends ConsumerWidget {
  /// El código/id a buscar
  final String code;

  /// El provider que retorna la lista de items
  final FutureProvider<List<T>> provider;

  /// Función para extraer el código del item
  final String Function(T) getCode;

  /// Función para extraer la descripción del item
  final String Function(T) getDescription;

  /// Fallback si no encuentra el item
  final String? fallback;

  /// Estilos opcionales
  final TextStyle? style;

  const DisplayValue({
    Key? key,
    required this.code,
    required this.provider,
    required this.getCode,
    required this.getDescription,
    this.fallback,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(provider).when(
      data: (items) {
        try {
          final item = items.firstWhere((item) => getCode(item) == code);
          return Text(
            getDescription(item),
            style: style ?? const TextStyle( fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        } catch (_) {
          return Text(
            fallback ?? code,
            style: style ?? const TextStyle( fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        }
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Text(
        fallback ?? code,
        style: style ?? const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}