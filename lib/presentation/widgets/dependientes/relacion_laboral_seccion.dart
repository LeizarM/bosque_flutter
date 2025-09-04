import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/info_row.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RelacionLaboralSeccion extends ConsumerWidget{
   final int codEmpleado;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  
  final Function(String) onToggleSeccion;
  
  const RelacionLaboralSeccion({
    super.key,
    required this.codEmpleado,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    
    required this.onToggleSeccion,
    
  });
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      final especiales = ['s.a.', 's.r.l.', 'ipx', 'esppapel'];
      if (especiales.contains(word.toLowerCase())) return word.toUpperCase();
      return _capitalize(word);
    }).join(' ');
  }

  String formatText(String text, bool isDesktop) {
    if (isDesktop) return text.toUpperCase();
    return _capitalizeWords(text);
  }

  Widget autoText(String text, TextStyle style, {int maxLines = 1, TextAlign? textAlign}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        softWrap: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cargarRelEmp = ref.watch(relacionLaboralProvider(codEmpleado));
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color icono = isDark ? colorScheme.primary : Colors.teal.shade700;
    final Color textoPrincipal = isDark ? colorScheme.onSurface : Colors.grey.shade900;
    final Color textoSecundario = isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 8,
        vertical: isDesktop ? 16 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header simple
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              autoText(
                formatText('Relación laboral', isDesktop),
                TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: textoPrincipal,
                  fontFamily: 'Montserrat',
                  letterSpacing: 0.5,
                ),
              ),
              
            ],
          ),
          
            Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
            cargarRelEmp.when(
              data: (relEmp) {
                if (relEmp.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: autoText(
                        formatText('No hay relación laboral registrada', isDesktop),
                        TextStyle(
                          color: textoSecundario,
                          fontSize: isDesktop ? 15 : 14,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: relEmp.map((relacionLaboral) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _datoConEtiqueta(
                          icon: Icons.work_rounded,
                          etiqueta: 'Cargo',
                          valor: formatText(relacionLaboral.cargo, isDesktop),
                          colorValor: textoPrincipal,
                          colorIcono: icono,
                          textoSecundario: textoSecundario,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 8),
                        _datoConEtiqueta(
                          icon: Icons.calendar_today,
                          etiqueta: 'Fecha de inicio',
                          valor: relacionLaboral.fechaIni != null
                              ? DateFormat('dd-MM-yyyy').format(relacionLaboral.fechaIni)
                              : '',
                          colorValor: textoPrincipal,
                          colorIcono: icono,
                          textoSecundario: textoSecundario,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 8),
                        _datoConEtiqueta(
                          icon: Icons.business_rounded,
                          etiqueta: 'Tipo',
                          valor: formatText(relacionLaboral.tipoRel, isDesktop),
                          colorValor: textoPrincipal,
                          colorIcono: icono,
                          textoSecundario: textoSecundario,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 8),
                        _datoConEtiqueta(
                          icon: Icons.business_rounded,
                          etiqueta: 'Empresa interna',
                          valor: formatText(relacionLaboral.empresaInterna, isDesktop),
                          colorValor: textoPrincipal,
                          colorIcono: icono,
                          textoSecundario: textoSecundario,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 8),
                        Row(
  children: [
    // Empresa fiscal
    Expanded(
      flex: 1,
      child: _datoConEtiqueta(
        icon: Icons.business_center_rounded,
        etiqueta: 'Empresa fiscal',
        valor: formatText(relacionLaboral.empresaFiscal, isDesktop),
        colorValor: textoPrincipal,
        colorIcono: icono,
        textoSecundario: textoSecundario,
        isDesktop: isDesktop,
        maxLines: 1, // Limita a una línea y usa ellipsis
      ),
    ),
    const SizedBox(width: 16), // Espacio entre los campos
    // Sucursal
    Expanded(
      flex: 1,
      child: _datoConEtiqueta(
        icon: Icons.location_on_rounded,
        etiqueta: 'Sucursal',
        valor: formatText(relacionLaboral.sucursal, isDesktop),
        colorValor: textoPrincipal,
        colorIcono: icono,
        textoSecundario: textoSecundario,
        isDesktop: isDesktop,
        maxLines: 1,
      ),
    ),
  ],
)
                      ],
                    ),
                  )).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: autoText(
                  formatText('Error al cargar la relación laboral: $error', isDesktop),
                  TextStyle(color: Colors.red),
                ),
              ),
            ),
          
        ],
      ),
    );
  }

  Widget _datoConEtiqueta({
    IconData? icon,
    required String etiqueta,
    required String valor,
    required Color colorValor,
    required Color colorIcono,
    required Color textoSecundario,
    required bool isDesktop,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: colorIcono, size: isDesktop ? 18 : 16),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 11,
                  color: textoSecundario,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                ),
              ),
              autoText(
                valor,
                TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: colorValor,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
              ),
            ],
          ),
        ),
      ],
    );
  }
}