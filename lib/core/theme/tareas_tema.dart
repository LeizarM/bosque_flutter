import 'package:flutter/material.dart';

/// Tema tipográfico del módulo Tareas Rutinarias.
///
/// La app corre con la tipografía por defecto de Flutter (Roboto): funciona,
/// pero se lee como pantalla sin diseñar — la queja de Marcelo (2026-09-07:
/// "en los labels aparece bien feo… fonts más amigables"). Plus Jakarta Sans
/// tiene la misma legibilidad a 11px, formas más redondas y bastante más
/// carácter.
///
/// **Ya está empaquetada**: `pubspec.yaml` la declara con sus cuatro pesos
/// (400/500/600/700) desde que se hizo el módulo de Comisiones. No se estaba
/// usando en ningún lado fuera de ahí, así que esto no agrega ni un byte al
/// bundle.
///
/// Se aplica envolviendo cada pantalla del módulo en un [Theme], igual que
/// hace `ComisionesTema.temaModulo` — y por el mismo motivo, escrito en su
/// propio archivo: *"No se cambia la de la app: el módulo se envuelve en su
/// propio Theme, así el resto del sistema queda intacto"*. Cambiar
/// `ThemeData.fontFamily` global tocaría las ~90 pantallas de la app de una
/// vez, incluidas las que nadie miró en esta migración.
///
/// A diferencia del de Comisiones, este NO redefine el ColorScheme ni la
/// escala de tamaños: solo cambia la familia. Todo lo demás —colores, modo
/// oscuro, semilla elegida por el usuario, densidades— sigue saliendo del tema
/// de la app, así que no hay dos paletas que mantener sincronizadas.
class TareasTema {
  const TareasTema._();

  /// Interfaz del módulo.
  static const String fuenteUI = 'PlusJakartaSans';

  static ThemeData temaModulo(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      // `apply` conserva tamaños, pesos y colores de cada estilo y solo pisa
      // la familia — que es exactamente el alcance que se quiere aquí.
      textTheme: base.textTheme.apply(fontFamily: fuenteUI),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fuenteUI),
    );
  }
}

/// Envoltorio de una pantalla del módulo Tareas Rutinarias.
///
/// `TareasScope(child: Scaffold(...))` en vez de repetir
/// `Theme(data: TareasTema.temaModulo(context), child: ...)` en cada pantalla:
/// el nombre dice a qué módulo pertenece la pantalla, no cómo está
/// implementado, y si mañana el módulo necesita algo más que tipografía se
/// agrega aquí y no en diez archivos.
class TareasScope extends StatelessWidget {
  final Widget child;

  const TareasScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      Theme(data: TareasTema.temaModulo(context), child: child);
}
