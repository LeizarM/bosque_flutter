/// Una conexión a SAP (tsap_Conexion) que comparten los módulos: de qué empresa es, si apunta
/// a la base real o a la de prueba, dónde corren los SP y con qué usuario se entra al Service
/// Layer.
///
/// La contraseña no viaja: el backend solo dice si está cargada. En el desplegable de un módulo
/// llegan además sin URL ni usuario, que solo se ven en Administración > Conexiones SAP.
class SapConexionEntity {
  static const produccion = 'PRODUCCION';
  static const prueba = 'PRUEBA';

  /// null en un alta.
  final int? idConexion;
  final String nombre;
  final int codEmpresa;
  final String empresa;

  /// [produccion] o [prueba].
  final String ambiente;

  /// Vacío = la misma instancia que BOSQUE.
  final String linkedServer;

  /// CompanyDB del Service Layer y base donde corren los SP.
  final String baseSap;
  final String slUrl;
  final String slUsuario;
  final bool habilitada;
  final bool claveCargada;

  /// Cuántas configuraciones de módulos la usan: con alguna, no se puede quitar.
  final int enUso;
  final DateTime? audFecha;

  const SapConexionEntity({
    this.idConexion,
    this.nombre = '',
    required this.codEmpresa,
    this.empresa = '',
    this.ambiente = prueba,
    this.linkedServer = '',
    this.baseSap = '',
    this.slUrl = '',
    this.slUsuario = '',
    this.habilitada = true,
    this.claveCargada = false,
    this.enUso = 0,
    this.audFecha,
  });

  bool get esPrueba => ambiente == prueba;

  /// Lo que comparten las conexiones de hoy, para no escribirlo de nuevo en cada alta.
  factory SapConexionEntity.plantilla() => const SapConexionEntity(
    codEmpresa: 0,
    linkedServer: '192.168.3.114',
    slUrl: 'https://sequoia:50000/b1s/v1/',
  );
}
