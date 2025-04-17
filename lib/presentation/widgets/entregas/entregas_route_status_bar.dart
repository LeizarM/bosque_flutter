import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class EntregasRouteStatusBar extends StatelessWidget {
  final bool rutaIniciada;
  final DateTime? fechaInicio;
  final bool isLocationEnabled;
  final bool isProcessing;
  final bool entregasVacias;
  final VoidCallback onIniciarRuta;
  final VoidCallback onFinalizarRuta;

  const EntregasRouteStatusBar({
    Key? key,
    required this.rutaIniciada,
    this.fechaInicio,
    required this.isLocationEnabled,
    required this.isProcessing,
    required this.entregasVacias,
    required this.onIniciarRuta,
    required this.onFinalizarRuta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Container(
      color: rutaIniciada
          ? colorScheme.primaryContainer
          : colorScheme.surfaceTint.withAlpha(20),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rutaIniciada
                      ? 'Ruta iniciada'
                      : 'Ruta no iniciada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtilsBosque.getResponsiveValue<double>(
                      context: context,
                      defaultValue: 16,
                      mobile: 14,
                      desktop: 18,
                    ),
                    color: rutaIniciada
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                if (fechaInicio != null)
                  Text(
                    'Iniciada: ${fechaInicio!.day.toString().padLeft(2, '0')}/${fechaInicio!.month.toString().padLeft(2, '0')}/${fechaInicio!.year} ${fechaInicio!.hour.toString().padLeft(2, '0')}:${fechaInicio!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: rutaIniciada
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
          if (isProcessing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          else if (!rutaIniciada)
            ElevatedButton(
              onPressed: (entregasVacias || !isLocationEnabled)
                  ? null
                  : onIniciarRuta,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.surfaceTint.withAlpha(20),
                foregroundColor: colorScheme.onPrimary,
                disabledForegroundColor: colorScheme.onSurface.withAlpha(150),
              ),
              child: const Text('Iniciar entregas'),
            )
          else
            ElevatedButton(
              onPressed: !isLocationEnabled ? null : onFinalizarRuta,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                disabledBackgroundColor: colorScheme.surfaceTint.withAlpha(20),
                foregroundColor: colorScheme.onError,
                disabledForegroundColor: colorScheme.onSurface.withAlpha(150),
              ),
              child: const Text('Finalizar entregas'),
            ),
        ],
      ),
    );
  }
}