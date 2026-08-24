import 'package:flutter/services.dart';

/// Validadores y formateadores de entrada del modulo de Comisiones.
///
/// Los mensajes se muestran tal cual al usuario: dicen que se espera, no que
/// esta mal. Las reglas numericas replican los CHECK de la base, para que el
/// error aparezca al tipear y no al guardar.
class ValidadoresComision {
  const ValidadoresComision._();

  // ── Formateadores de entrada ──────────────────────────────────────────

  /// Solo digitos. Para codigos SAP y numeros de documento.
  static final soloEnteros = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
  ];

  /// Decimal con hasta dos cifras. Para importes y metas.
  static final decimal2 = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,12}([.,]\d{0,2})?$')),
  ];

  /// Decimal con hasta cuatro cifras. Para porcentajes finos como 2.7550.
  static final decimal4 = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d{0,4})?$')),
  ];

  /// Letras, numeros, espacios y los signos que aparecen en nombres de grupo.
  static final textoNombre = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(
      RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,\-_/()]"),
    ),
    LengthLimitingTextInputFormatter(100),
  ];

  // ── Validadores de formulario ─────────────────────────────────────────

  /// Campo de texto obligatorio.
  static String? requerido(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingrese $campo.';
    }
    return null;
  }

  /// Nombre obligatorio con longitud minima util.
  static String? nombre(String? valor, {String campo = 'un nombre'}) {
    final base = requerido(valor, campo);
    if (base != null) return base;
    if (valor!.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }
    return null;
  }

  /// Porcentaje en base 100. La base lo guarda en base 1, la conversion la hace
  /// el formulario al armar la entidad.
  static String? porcentaje(String? valor, {bool obligatorio = true}) {
    if (valor == null || valor.trim().isEmpty) {
      return obligatorio ? 'Ingrese el porcentaje.' : null;
    }
    final numero = aDouble(valor);
    if (numero == null) return 'El porcentaje debe ser un numero.';
    if (numero < 0) return 'El porcentaje no puede ser negativo.';
    if (numero > 100) return 'El porcentaje no puede superar 100.';
    return null;
  }

  /// Importe monetario. Acepta cero cuando el campo es opcional.
  static String? monto(
    String? valor, {
    bool obligatorio = true,
    String campo = 'el monto',
  }) {
    if (valor == null || valor.trim().isEmpty) {
      return obligatorio ? 'Ingrese $campo.' : null;
    }
    final numero = aDouble(valor);
    if (numero == null) return 'Ingrese $campo como numero.';
    if (numero < 0) return 'El monto no puede ser negativo.';
    return null;
  }

  /// Codigo de vendedor en SAP: entero positivo.
  static String? codigoSap(String? valor, {bool obligatorio = false}) {
    if (valor == null || valor.trim().isEmpty) {
      return obligatorio ? 'Ingrese el codigo SAP.' : null;
    }
    final numero = int.tryParse(valor.trim());
    if (numero == null) return 'El codigo SAP debe ser un numero entero.';
    if (numero <= 0) return 'El codigo SAP debe ser mayor a cero.';
    return null;
  }

  /// Al menos una de las dos metas debe tener valor.
  static String? algunaMeta(String? metaUsd, String? metaBs) {
    final usd = aDouble(metaUsd ?? '') ?? 0;
    final bs = aDouble(metaBs ?? '') ?? 0;
    if (usd <= 0 && bs <= 0) {
      return 'Indique al menos una meta, en USD o en BS.';
    }
    return null;
  }

  /// La fecha de fin no puede quedar antes de la de inicio.
  static String? rangoFechas(DateTime? inicio, DateTime? fin) {
    if (inicio == null) return 'Seleccione la fecha de inicio.';
    if (fin != null && fin.isBefore(inicio)) {
      return 'La fecha de fin no puede ser anterior a la de inicio.';
    }
    return null;
  }

  // ── Conversion ────────────────────────────────────────────────────────

  /// Convierte el texto del campo a double aceptando coma o punto decimal.
  static double? aDouble(String valor) {
    if (valor.trim().isEmpty) return null;
    return double.tryParse(valor.trim().replaceAll(',', '.'));
  }

  /// Porcentaje tal como lo guarda tcom_grupo: puntos porcentuales.
  ///
  /// 0.7 en la tabla significa 0,7%. La division entre 100 la hace el SP de
  /// calculo, no la aplicacion, asi que aca no se convierte nada. Valores
  /// reales en la base: de 0.0 a 2.0.
  static double aPuntosPorcentuales(String valor) => aDouble(valor) ?? 0;

  /// Texto para el campo del formulario, sin ceros de relleno.
  static String aTextoPorcentaje(double puntos) =>
      puntos.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
}
