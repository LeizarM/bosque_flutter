import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool permitirFechaFutura; // Nuevo parámetro

  const DatePickerField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.permitirFechaFutura = false, // false por defecto
  });

  // Misma regla que FormatearFecha.formatearFecha: se delega ahi en vez de
  // duplicar el DateFormat, para no tener dos lugares con el mismo patron
  // dd/MM/yyyy que puedan divergir con el tiempo.
  String _formatDate(DateTime date) => FormatearFecha.formatearFecha(date);

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
  // DateFormat en vez de interpolar a mano: es la libreria estandar para esto
  // (ya se usa en el modulo via NumberFormat, ver formato_moneda.dart) y evita
  // reinventar el zero-padding.
  //
  // Sin locale explicito a proposito: los 3 patrones son puramente numericos
  // (dd/MM/yyyy, HH:mm) y no tocan nombres de mes/dia ni AM/PM, asi que el
  // locale no cambia un solo caracter del resultado. Pedir 'es' aca no suma
  // nada y agrega un riesgo real: si alguna de estas static queda inicializada
  // antes de que Flutter cargue los datos de 'es' (ver nota de
  // initializeDateFormatting mas abajo), DateFormat('...', 'es') explota con
  // LocaleDataException. Sin locale, intl cae siempre en su fallback interno
  // 'en_US', que esta harcodeado en el propio paquete y nunca lanza esa
  // excepcion — por eso el resultado es identico al de antes sin heredar ese
  // riesgo.
  //
  // No hace falta un initializeDateFormatting() propio en main(): la app ya
  // registra GlobalMaterialLocalizations.delegate (ver MaterialApp.router en
  // main.dart), y ese delegate carga los datos de fecha de intl para todos
  // los locales empaquetados -incluido 'es'- antes de construir cualquier
  // pantalla (flutter_localizations, material_localizations.dart, delegate
  // .load() -> util.loadDateIntlDataIfNotLoaded()). Agregar la llamada de
  // nuevo aca seria redundante.
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  static final DateFormat _formatoHora = DateFormat('HH:mm');
  static final DateFormat _formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');

  static DateTime parseFecha(String fecha) {
    List<String> partes = fecha.split('/');
    return DateTime(
      int.parse(partes[2]), // año
      int.parse(partes[1]), // mes
      int.parse(partes[0]), // día
    );
  }

  /// Fecha corta: dd/MM/yyyy.
  static String formatearFecha(DateTime fecha) => _formatoFecha.format(fecha);

  /// Hora corta: HH:mm.
  static String formatearHora(DateTime fecha) => _formatoHora.format(fecha);

  /// Fecha y hora: dd/MM/yyyy HH:mm.
  static String formatearFechaHora(DateTime fecha) =>
      _formatoFechaHora.format(fecha);

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
