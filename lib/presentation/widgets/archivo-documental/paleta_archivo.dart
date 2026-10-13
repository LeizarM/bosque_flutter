/// Los colores del archivo de documentos. Cada dato tiene su tono fijo (la caja
/// es kraft, la gestión violeta, la ubicación verde) y cada archivo o empresa
/// uno de su paleta, así un mismo color significa lo mismo en toda la pantalla.
library;

import 'package:flutter/material.dart';

/// Un tono resuelto para el brillo del tema: [fuerte] para íconos y botones
/// llenos (con [sobreFuerte] encima) y [fondo] con [texto] para chips y mosaicos.
@immutable
class Tono {
  const Tono({
    required this.fuerte,
    required this.sobreFuerte,
    required this.fondo,
    required this.texto,
  });

  final Color fuerte;
  final Color sobreFuerte;
  final Color fondo;
  final Color texto;
}

abstract final class TonosArchivo {
  static const Color caja = Color(0xFFB8741A);
  static const Color documentos = Color(0xFF2563EB);
  static const Color gestion = Color(0xFF7C3AED);
  static const Color ubicacion = Color(0xFF059669);
  static const Color fotos = Color(0xFFDB2777);
  static const Color reportes = Color(0xFF0891B2);
  static const Color peligro = Color(0xFFDC2626);

  /// Archivos físicos (sucursales), por orden de alta.
  static const List<Color> archivos = [
    Color(0xFF0D9488),
    Color(0xFF4F46E5),
    Color(0xFFEA580C),
    Color(0xFF9333EA),
    Color(0xFF16A34A),
    Color(0xFFE11D48),
    Color(0xFF0284C7),
    Color(0xFFA16207),
  ];

  static const List<Color> empresas = [
    Color(0xFF1D4ED8),
    Color(0xFFC2410C),
    Color(0xFF7E22CE),
    Color(0xFF15803D),
    Color(0xFFBE185D),
    Color(0xFF0F766E),
  ];
}

final Map<(int, Brightness), Tono> _tonos = {};

/// El esquema M3 de [semilla] con el brillo del tema. El color pleno sale de la
/// variante `fidelity` (fiel a la semilla, vivo) y el fondo suave de la normal
/// (pastel con letra oscura): así cada par contrasta en claro y en oscuro.
Tono tonoDe(BuildContext context, Color semilla) {
  final brillo = Theme.of(context).brightness;
  return _tonos.putIfAbsent((semilla.toARGB32(), brillo), () {
    final vivo = ColorScheme.fromSeed(
      seedColor: semilla,
      brightness: brillo,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final suave = ColorScheme.fromSeed(seedColor: semilla, brightness: brillo);
    return Tono(
      fuerte: vivo.primary,
      sobreFuerte: vivo.onPrimary,
      fondo: suave.primaryContainer,
      texto: suave.onPrimaryContainer,
    );
  });
}

/// Tono neutro del tema, para lo que no tiene dueño (sin empresa, sin archivo).
Tono tonoNeutro(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Tono(
    fuerte: cs.onSurfaceVariant,
    sobreFuerte: cs.surface,
    fondo: cs.surfaceContainerHighest,
    texto: cs.onSurfaceVariant,
  );
}

/// El color de un archivo sale de su id y no del nombre: renombrarlo no lo cambia.
Color semillaDeArchivo(int codArchivo, Iterable<int> codigos) =>
    _dePaleta(codArchivo, codigos, TonosArchivo.archivos);

Color semillaDeEmpresa(int codEmpresa, Iterable<int> codigos) =>
    _dePaleta(codEmpresa, codigos, TonosArchivo.empresas);

Color _dePaleta(int cod, Iterable<int> codigos, List<Color> paleta) {
  final orden = codigos.toSet().toList()..sort();
  final i = orden.indexOf(cod);
  return paleta[(i < 0 ? 0 : i) % paleta.length];
}
