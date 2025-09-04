
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Valida datos opcionales sin espacios como entrada valida
String? validarTextoOpcional(String? value, {bool esObligatorio = false}) {
  final trimmed = (value ?? "").trim();

  if(esObligatorio && trimmed.isEmpty){
    return 'Este campo es obligatorio'; // No acepta el campo vacío
  }
  if(trimmed.isNotEmpty){
    if (trimmed.length < 2) {
      return 'Debe tener al menos 2 caracteres';
    } else if (trimmed.length > 30) {
      return 'Debe tener menos de 30 caracteres';
    } else if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(trimmed)) {
      return 'Solo se permiten letras';
    }
  }
  return null;
}

// Bloquea espacios como dato valido
List<TextInputFormatter> bloquearEspacios = [
  FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
];

List<TextInputFormatter> bloquearTodosLosEspacios = [
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
];
//validar campos solo para NUMEROS
String? validarSoloNumeros(String? value,{bool esObligatorio = false}) {
  final trimmed = (value ?? "").trim(); // Elimina espacios antes de validar

  if(esObligatorio && trimmed.isEmpty){
    return 'Este campo es obligatorio'; // No acepta el campo vacío
  }

  if(trimmed.isNotEmpty){
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {  
    return 'Solo se permiten números';
  }
  if (trimmed.length < 7) {
    return 'Debe tener al menos 7 caracteres';
  }else if (trimmed.length > 8) {
    return 'Debe tener menos de 8 caracteres';
  }

  }

  return null;
}

//validar direccion: permite letras, numeros y (,) (.) (°)
String? validarTextoMixto(String? value, {bool esObligatorio = false}) {
  final trimmed = (value ?? "").trim(); // Elimina espacios antes de validar

  if (esObligatorio && trimmed.isEmpty) {
    return 'Este campo es obligatorio'; // No acepta el campo vacío
  }

  if (trimmed.isNotEmpty) {
    if (trimmed.length < 2) {
      return 'Debe tener al menos 2 caracteres';
    } else if (trimmed.length > 200) {
      return 'Debe tener menos de 200 caracteres';
    } else if (!RegExp(r'^[a-zA-ZÁÉÍÓÚÜÑáéíóúüñ0-9.,°#/\-()& ]+$').hasMatch(trimmed)) {
      return 'Solo se permiten letras, números y símbolos comunes como . , ° # / - ( ) &';
    } else if (RegExp(r'[.,°#/\-()&]{2,}').hasMatch(trimmed)) {
      return 'No se permiten símbolos repetidos consecutivamente';
    }
  }

  return null;
}


//validar correo electronico
String? validarEmail(String? value,{bool esObligatorio = false}) {
  final trimmed = (value ?? "").trim(); // Elimina espacios antes de validar

  if (trimmed.isEmpty) {
    return 'Este campo es obligatorio'; // No acepta el campo vacío
  }

  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
    return 'Formato de correo electrónico inválido';
  }

  return null;
}

//VALIDAR DESCRIPCION DE FORMACION
String? validarDescripcionFormacion(String? value) {
  final trimmed = (value ?? "").trim(); // Elimina espacios antes de validar

  if (trimmed.isEmpty) {
    return 'Este campo es obligatorio'; // No acepta el campo vacío
  }

  if (trimmed.length < 10) {
    return 'Debe tener al menos 10 caracteres';
  } else if (trimmed.length > 200) {
    return 'Debe tener menos de 200 caracteres';
  } else if (!RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ.,° ]+$').hasMatch(trimmed)) {
    return 'Solo se permiten letras, números, puntos (.), comas (,) y el carácter (°)';
  }

  return null;
}

//VALIDAR DURACION DE FORMACION
String? validarNumerosCortos(String? value) {
  final trimmed = (value ?? "").trim(); // Elimina espacios antes de validar

  if (trimmed.isEmpty) {
    return 'Este campo es obligatorio'; // No acepta el campo vacío
  }

  if (trimmed.length < 2) {
    return 'Debe tener al menos 2 caracteres';
  }else if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
    return 'Solo se pe rmiten números';
  }
  return null;
}

//validar duracion de formacion
String? validarDuracion(String? value, String unidadSeleccionada, {bool esObligatorio = false}) {
  final trimmed = (value ?? "").trim();

  if (esObligatorio && trimmed.isEmpty) {
    return 'Este campo es obligatorio';
  }

  if (trimmed.isNotEmpty) {
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {  
      return 'Solo se permiten números';
    }

    final int? duracion = int.tryParse(trimmed);
    if (duracion == null) return 'Ingrese un número válido';

    // Definir límites máximos según la unidad seleccionada
    final Map<String, int> limitesDuracion = {
      'hrs': 2400,   // Máximo 2400 horas
      'dia': 30,      // Máximo 30 días
      'mes': 12,    // Máximo 4 meses
      'sem': 4,     // Máximo 12 semanas
      'ani': 10,      // Máximo 10 años
    };

    // Definir la cantidad de dígitos permitidos
    final Map<String, int> limitesDigitos = {
      'hrs': 4,  
      'dia': 2,  
      'sem': 1,  
      'mes': 2,  
      'ani': 2,  
    };

    final int? limiteMaximo = limitesDuracion[unidadSeleccionada];
    final int? limiteDigitos = limitesDigitos[unidadSeleccionada];

    if (limiteMaximo == null || limiteDigitos == null) return 'Unidad de duración no válida';

    if (duracion > limiteMaximo) {
      return 'La duración máxima para $unidadSeleccionada es $limiteMaximo';
    }

    if (trimmed.length > limiteDigitos) {
      return 'Solo se permiten hasta $limiteDigitos dígitos en $unidadSeleccionada';
    }
  }

  return null;
}
//validar dropdowns
String? validarDropdown(String? value, String nombreCampo) {
  if (value == null || value.isEmpty) {
    return 'Seleccione una opción para $nombreCampo';
  }
  return null;
}
//validar fechas
String? validarFecha(String? value) {
  if (value == null || value.isEmpty) {
    return 'Seleccione una fecha';
  }

  try {
    DateTime fechaIngresada = DateFormat('dd-MM-yyyy').parse(value);
    DateTime fechaActual = DateTime.now();

    // Validar que la fecha no sea futura (opcional)
    if (fechaIngresada.isAfter(fechaActual)) {
      return 'La fecha no puede ser en el futuro';
    }

    // Validar que la fecha esté dentro de un rango específico
    DateTime fechaMinima = DateTime(2000);
    DateTime fechaMaxima = DateTime(2100);
    if (fechaIngresada.isBefore(fechaMinima) || fechaIngresada.isAfter(fechaMaxima)) {
      return 'La fecha debe estar entre ${DateFormat('dd-MM-yyyy').format(fechaMinima)} y ${DateFormat('dd-MM-yyyy').format(fechaMaxima)}';
    }

  } catch (e) {
    return 'Formato de fecha incorrecto';
  }

  return null;
}

//validar dropdown search
// validadores.dart
String? validarSeleccionDropdownSearch(dynamic value) {
  return value == null ? 'Seleccione una opción válida' : null;
}


/// onFieldSubmitted: (value) => validarYEnviarEnWeb(_formKey, _guardarFuncion),
void validarYEnviarEnWeb(GlobalKey<FormState> formKey, VoidCallback onSave) {
  if (kIsWeb) {
    if (formKey.currentState?.validate() ?? false) {
      onSave();
    }
  }
}








