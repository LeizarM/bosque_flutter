/// Traduce lo que devuelve el backend a algo que entienda quien usa la app.
///
/// **Se mudó a `lib/core/ui/mensajes_usuario.dart`**, sin cambiar una letra:
/// las reglas nacieron mirando los `RAISERROR` de los `trs_sp_`, pero el
/// envoltorio del `CATCH`, los errores del motor y los cortes de red son los
/// mismos para todo el ERP, y el módulo de `permisos-rrhh` los necesita igual.
///
/// Este archivo queda como re-export: lo importan 8 widgets de `rol-sabados/`
/// y `test/mensajes_usuario_test.dart`.
library;

export 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
