import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Extensión para BuildContext con utilidades responsivas (Mobile, Tablet y Desktop)
extension ResponsiveContext on BuildContext {
  // ============================================================================
  // DETECCIÓN DE DISPOSITIVO (Usando ResponsiveFramework correctamente)
  // ============================================================================

  /// Retorna true si es móvil
  bool get isMobile => ResponsiveBreakpoints.of(this).isMobile;

  /// Retorna true si es tablet
  bool get isTablet => ResponsiveBreakpoints.of(this).isTablet;

  /// Retorna true si es desktop
  bool get isDesktop => ResponsiveBreakpoints.of(this).isDesktop;

  // ============================================================================
  // MÉTODO GENÉRICO PARA VALORES RESPONSIVOS
  // ============================================================================

  /// Obtiene un valor responsivo basado en el dispositivo actual
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile) return mobile;
    if (isTablet && tablet != null) return tablet;
    if (isDesktop && desktop != null) return desktop;
    
    return tablet ?? desktop ?? mobile;
  }

  // ============================================================================
  // DIMENSIONES RESPONSIVAS
  // ============================================================================

  /// Retorna padding responsivo
  EdgeInsets get padding => responsiveValue(
    mobile: const EdgeInsets.all(12),
    tablet: const EdgeInsets.all(14),
    desktop: const EdgeInsets.all(16),
  );

  /// Retorna spacing entre elementos
  double get spacing => responsiveValue(
    mobile: 8.0,
    tablet: 10.0,
    desktop: 12.0,
  );

  /// Retorna spacing pequeño
  double get smallSpacing => spacing * 0.5;

  /// Retorna spacing grande
  double get largeSpacing => spacing * 2;

  // ============================================================================
  // TAMAÑOS DE FUENTE
  // ============================================================================

  /// Tamaño de fuente para títulos
  double get titleFontSize => responsiveValue(
    mobile: 18.0,
    tablet: 20.0,
    desktop: 22.0,
  );

  /// Tamaño de fuente para subtítulos
  double get subtitleFontSize => responsiveValue(
    mobile: 14.0,
    tablet: 15.0,
    desktop: 16.0,
  );

  /// Tamaño de fuente para body
  double get bodyFontSize => responsiveValue(
    mobile: 12.0,
    tablet: 13.0,
    desktop: 14.0,
  );

  /// Tamaño de fuente pequeño
  double get smallFontSize => responsiveValue(
    mobile: 10.0,
    tablet: 11.0,
    desktop: 12.0,
  );

  // ============================================================================
  // ESTILOS DE TEXTO
  // ============================================================================

  /// Estilo de título responsivo
  TextStyle get titleStyle => TextStyle(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF1F2937),
  );

  /// Estilo de subtítulo responsivo
  TextStyle get subtitleStyle => TextStyle(
    fontSize: subtitleFontSize,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF6B7280),
  );

  /// Estilo de body responsivo
  TextStyle get bodyStyle => TextStyle(
    fontSize: bodyFontSize,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF374151),
  );

  /// Estilo de body responsivo (más claro)
  TextStyle get bodyLightStyle => TextStyle(
    fontSize: bodyFontSize,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF9CA3AF),
  );

  // ============================================================================
  // ICONOS Y BORDES
  // ============================================================================

  /// Tamaño de icono responsivo
  double get iconSize => responsiveValue(
    mobile: 20.0,
    tablet: 22.0,
    desktop: 24.0,
  );

  /// Tamaño de icono pequeño
  double get smallIconSize => iconSize * 0.75;

  /// Tamaño de icono grande
  double get largeIconSize => iconSize * 1.5;

  /// BorderRadius responsivo
  BorderRadius get borderRadius => BorderRadius.circular(
    responsiveValue(
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    ),
  );

  // ============================================================================
  // DIMENSIONES DE LAYOUT
  // ============================================================================

  /// Ancho del panel izquierdo (solo para desktop y tablet grande)
  double get leftPanelWidth => responsiveValue(
    mobile: 0.0,
    tablet: 300.0,
    desktop: 380.0,
  );

  /// Ancho máximo del contenedor
  double get maxContainerWidth => responsiveValue(
    mobile: double.infinity,
    tablet: 500.0,
    desktop: 1200.0,
  );

  // ============================================================================
  // ALTURA DE COMPONENTES
  // ============================================================================

  /// Altura del header compacto
  double get headerHeight => responsiveValue(
    mobile: 56.0,
    tablet: 60.0,
    desktop: 64.0,
  );

  // ============================================================================
  // LÓGICA DE LAYOUT
  // ============================================================================

  /// Retorna true si debe mostrar layout lado a lado
  bool get shouldShowSideBySide => isTablet || isDesktop;

  /// Retorna true si los tabs deben ser scrollables
  bool get shouldTabsBeScrollable => isMobile;

  /// Retorna número de columnas para mostrar contenido
  int get columnCount => responsiveValue(
    mobile: 1,
    tablet: 2,
    desktop: 2,
  );
}