import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool permitirFechaFutura; // Nuevo parámetro

  const DatePickerField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.permitirFechaFutura = false, // false por defecto
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1960),
          lastDate: DateTime(2050),
        );

        if (picked != null) {
          controller.text = _formatDate(picked);
        }
      },
      validator:
          validator ??
          (value) => FormatearFecha.validarFecha(
            value,
            permitirFechaFutura: permitirFechaFutura,
          ),
    );
  }
}

class FormatearFecha {
  static DateTime parseFecha(String fecha) {
    List<String> partes = fecha.split('/');
    return DateTime(
      int.parse(partes[2]), // año
      int.parse(partes[1]), // mes
      int.parse(partes[0]), // día
    );
  }

  static String formatearFecha(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
  }

  static String? validarFecha(
    String? value, {
    bool permitirFechaFutura = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'La fecha es obligatoria';
    }

    try {
      DateTime fechaIngresada = parseFecha(value);
      DateTime fechaActual = DateTime.now();

      // Solo validar fecha futura si no está permitida
      if (!permitirFechaFutura && fechaIngresada.isAfter(fechaActual)) {
        return 'La fecha no puede ser en el futuro';
      }

      // Validar que la fecha esté dentro del rango permitido
      DateTime fechaMinima = DateTime(1960);
      DateTime fechaMaxima = DateTime(2050);
      if (fechaIngresada.isBefore(fechaMinima) ||
          fechaIngresada.isAfter(fechaMaxima)) {
        return 'La fecha debe estar entre ${formatearFecha(fechaMinima)} y ${formatearFecha(fechaMaxima)}';
      }
    } catch (e) {
      return 'Formato de fecha inválido. Use DD/MM/YYYY';
    }

    return null;
  }
}
