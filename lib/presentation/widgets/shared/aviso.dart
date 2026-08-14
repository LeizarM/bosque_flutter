/// El aviso de la app.
///
/// **Se mudó a `lib/core/ui/aviso.dart`.** Es una pieza transversal —la usan 29
/// pantallas de ocho módulos— así que su lugar es `core/`, no
/// `presentation/widgets/`. **El código no cambió: `mostrarAviso`, `avisar`,
/// `TonoAviso` y el dibujo son exactamente los mismos.**
///
/// Este archivo queda como re-export para no tocar 29 imports que funcionan.
/// Lo nuevo importa `package:bosque_flutter/core/ui/aviso.dart`.
library;

export 'package:bosque_flutter/core/ui/aviso.dart';
