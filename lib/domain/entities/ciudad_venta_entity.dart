/// Una ciudad del catálogo de Ventas. Cuando viene de una asignación
/// (`tven_UsuarioCiudad`) trae también el usuario.
class CiudadVentaEntity {
  final int codUsuario;
  final int codCiudad;
  final String ciudad;

  const CiudadVentaEntity({
    this.codUsuario = 0,
    required this.codCiudad,
    required this.ciudad,
  });
}

/// Lo que arma el selector de ciudad del catálogo. Lo decide el backend.
///
/// - Administrador: todas las ciudades de venta; "Todas" = el país entero.
/// - Con excepciones: sólo las asignadas; "Todas" = la suma de esas.
/// - Sin excepciones: su ciudad del login y nada más.
class CiudadesPermitidasEntity {
  /// `codCiudad` que significa "Todas" para el backend.
  static const int todasLasCiudades = 0;

  final List<CiudadVentaEntity> ciudades;
  final bool todas;
  final bool esAdmin;
  final int codCiudadInicial;

  const CiudadesPermitidasEntity({
    required this.ciudades,
    required this.todas,
    required this.esAdmin,
    required this.codCiudadInicial,
  });

  /// Hay algo que elegir: más de una ciudad, o "Todas".
  bool get tieneSelector => ciudades.length > 1 || todas;

  String nombreDe(int codCiudad) {
    if (codCiudad == todasLasCiudades) return 'Todas';
    for (final c in ciudades) {
      if (c.codCiudad == codCiudad) return c.ciudad;
    }
    return '';
  }
}
