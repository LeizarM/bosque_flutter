/// El selector de la semilla del tema: la hoja con las nueve muestras y el
/// botón que la abre. Lo usan el login y la barra superior del dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

const BorderRadius _esquina = BorderRadius.all(Radius.circular(14));

/// Nombres de las semillas de [colorList], en orden.
///
/// El color solo no alcanza para elegir: quien no distingue bien el violeta del
/// púrpura necesita leerlo. Una semilla sin nombre se muestra por su posición.
const List<String> nombresDeSemilla = [
  'Azul',
  'Turquesa',
  'Verde',
  'Rojo',
  'Violeta',
  'Amarillo',
  'Naranja',
  'Púrpura',
  'Rosa',
];

String _nombre(int i) =>
    i < nombresDeSemilla.length ? nombresDeSemilla[i] : 'Color ${i + 1}';

/// Abre la hoja con las nueve semillas; al tocar una la aplica y la guarda.
void mostrarSelectorColorTema(BuildContext context, WidgetRef ref) {
  final elegida = ref.read(themeNotifierProvider).selectedColor;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    // En escritorio la hoja no se estira de lado a lado.
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final t = Theme.of(context).textTheme;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.xl, 0, Esp.xl, Esp.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: _esquina,
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: cs.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: Esp.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color del tema',
                          style: t.titleMedium?.copyWith(
                            fontWeight: Peso.titulo,
                          ),
                        ),
                        Text(
                          'Elige tu color favorito',
                          style: t.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Esp.xl),
              Wrap(
                spacing: Esp.m,
                runSpacing: Esp.l,
                children: [
                  for (var i = 0; i < colorList.length; i++)
                    MuestraDeColor(
                      color: colorList[i],
                      nombre: _nombre(i),
                      elegida: elegida == i,
                      onTap: () {
                        ref
                            .read(themeNotifierProvider.notifier)
                            .changeColorIndex(i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Una semilla: el color con su nombre debajo; la elegida lleva un anillo de
/// `onSurface`, que contrasta con la hoja sea cual sea la semilla.
class MuestraDeColor extends StatelessWidget {
  final Color color;
  final String nombre;
  final bool elegida;
  final VoidCallback onTap;

  const MuestraDeColor({
    super.key,
    required this.color,
    required this.nombre,
    required this.elegida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Negro o blanco encima del color, el que contraste más.
    final tinta =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // El anillo se dibuja siempre, transparente si no está elegida, para
          // que las muestras midan lo mismo y la grilla no salte.
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: elegida ? cs.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              color: color,
              borderRadius: _esquina,
              child: InkWell(
                onTap: onTap,
                borderRadius: _esquina,
                child: SizedBox(
                  height: 58,
                  child: Center(
                    child: AnimatedScale(
                      scale: elegida ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      child: Icon(Icons.check_rounded, color: tinta, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Esp.xs),
          Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: elegida ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: elegida ? Peso.dato : Peso.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// El botón de la barra superior: una paleta con un punto del color vigente.
class BotonColorTema extends ConsumerWidget {
  const BotonColorTema({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final elegida = ref.watch(themeNotifierProvider).selectedColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: 'Color del tema · ${_nombre(elegida)}',
        onPressed: () => mostrarSelectorColorTema(context, ref),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.palette_outlined, size: 20),
            Positioned(
              right: -3,
              bottom: -3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
