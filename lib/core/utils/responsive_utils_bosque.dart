import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Clase utilitaria para manejar dimensiones responsivas y estilos
class ResponsiveUtilsBosque {
  // Breakpoints estándar para la aplicación
  static const breakpoints = [
    Breakpoint(start: 0, end: 450, name: MOBILE),
    Breakpoint(start: 451, end: 800, name: TABLET),
    Breakpoint(start: 801, end: 1920, name: DESKTOP),
    Breakpoint(start: 1921, end: double.infinity, name: '4K'),
  ];

  /// Determina si el dispositivo es desktop
  static bool isDesktop(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final isLargeDisplay = screenWidth > 1500 && screenHeight > 1200;
    return ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP) || isLargeDisplay;
  }

  /// Determina si el dispositivo es tablet
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ResponsiveBreakpoints.of(context).between(TABLET, DESKTOP) || 
           (screenWidth > 750 && screenWidth < 1200);
  }

  /// Determina si el dispositivo es móvil
  static bool isMobile(BuildContext context) {
    return !isDesktop(context) && !isTablet(context);
  }

  /// Obtiene el padding horizontal adecuado según el dispositivo
  static double getHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final isLargeDisplay = screenWidth > 1500 && screenHeight > 1200;
    final isIpadPro = (screenWidth >= 1000 && screenWidth <= 1366) && 
                       (screenHeight >= 900 && screenHeight <= 1366);
    
    if (isLargeDisplay) return 24.0;
    if (isIpadPro) return 16.0;
    if (isDesktop(context)) return 32.0;
    if (isTablet(context)) return 20.0;
    return 16.0; // Mobile
  }

  /// Obtiene el padding vertical adecuado según el dispositivo
  static double getVerticalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final isLargeDisplay = screenWidth > 1500 && screenHeight > 1200;
    final isIpadPro = (screenWidth >= 1000 && screenWidth <= 1366) && 
                       (screenHeight >= 900 && screenHeight <= 1366);
    
    if (isLargeDisplay) return 16.0;
    if (isIpadPro) return 8.0;
    if (isDesktop(context)) return 24.0;
    if (isTablet(context)) return 16.0;
    return 12.0; // Mobile
  }

  /// Obtiene las dimensiones del grid para diferentes resoluciones
  static GridDimensions getGridDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount = 3; // Por defecto 3 columnas para escritorio
    double childAspectRatio = 1.8; // Proporción para 3 columnas
    
    if (screenWidth > 1800) {
      crossAxisCount = 4; // 4 columnas para pantallas muy anchas
      childAspectRatio = 2.0;
    } else if (screenWidth < 1200) {
      crossAxisCount = 2; // 2 columnas para escritorio más pequeño
      childAspectRatio = 1.6;
    }
    
    return GridDimensions(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );
  }

  /// Obtiene el estilo de texto apropiado para títulos según el dispositivo
   static TextStyle? getTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: getResponsiveValue<double>(
        context: context,
        defaultValue: 24.0,
        mobile: 20.0,
        desktop: 28.0,
      ),
    );
  } 

  /// Obtiene un valor responsive basado en el tipo de dispositivo
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T defaultValue,
    T? mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context) && mobile != null) return mobile;
    if (isTablet(context) && tablet != null) return tablet;
    if (isDesktop(context) && desktop != null) return desktop;
    return defaultValue;
  }
}

/// Clase para almacenar las dimensiones del grid
class GridDimensions {
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  
  GridDimensions({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
  });
}