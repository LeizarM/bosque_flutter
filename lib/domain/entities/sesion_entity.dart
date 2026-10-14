/// Un inicio de sesión de la app (trec_sesion): desde dónde, su última señal y, si terminó, cómo.
class SesionEntity {
  final BigInt idSesion;
  final int codUsuario;

  /// web, android, ios, windows, macos, linux o desconocida.
  final String plataforma;
  final String? versionApp;
  final String? ip;
  final DateTime? fechaInicio;
  final DateTime? fechaVence;
  final DateTime? fechaUltimaSenal;
  final DateTime? fechaCierre;

  /// S salió, A administrador, B bloqueado, I dado de baja, R cambió la contraseña; null si sigue abierta.
  final String? motivoCierre;
  final int? codUsuarioCierre;
  final int? audUsuario;
  final DateTime? audFecha;

  // Apoyo que arma el SP para la pantalla.
  final String login;
  final String nombreCompleto;
  final String? loginCierre;

  /// C conectada, N sin señal reciente, V vencida, X cerrada.
  final String estado;

  /// La sesión del administrador que mira la lista: no se ofrece cerrarla.
  final bool esActual;

  const SesionEntity({
    required this.idSesion,
    required this.codUsuario,
    required this.plataforma,
    required this.versionApp,
    required this.ip,
    required this.fechaInicio,
    required this.fechaVence,
    required this.fechaUltimaSenal,
    required this.fechaCierre,
    required this.motivoCierre,
    required this.codUsuarioCierre,
    required this.audUsuario,
    required this.audFecha,
    required this.login,
    required this.nombreCompleto,
    required this.loginCierre,
    required this.estado,
    required this.esActual,
  });

  bool get conectada => estado == 'C';

  /// Abierta y con el token vigente: se puede cerrar.
  bool get abierta => estado == 'C' || estado == 'N';

  String get textoEstado => switch (estado) {
    'C' => 'Conectada',
    'N' => 'Sin señal',
    'V' => 'Vencida',
    _ => textoCierre ?? 'Cerrada',
  };

  /// Cómo terminó, en palabras de la pantalla; null si sigue abierta.
  String? get textoCierre => switch (motivoCierre) {
    'S' => 'Salió',
    'A' => loginCierre == null ? 'Cerrada por un administrador' : 'Cerrada por $loginCierre',
    'B' => 'Usuario bloqueado',
    'I' => 'Dado de baja',
    'R' => 'Cambió la contraseña',
    _ => null,
  };

  String get textoPlataforma => switch (plataforma) {
    'web' => 'Web',
    'android' => 'Android',
    'ios' => 'iPhone / iPad',
    'windows' => 'Windows',
    'macos' => 'macOS',
    'linux' => 'Linux',
    _ => 'Desconocida',
  };
}
