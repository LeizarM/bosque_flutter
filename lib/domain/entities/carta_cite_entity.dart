/// Entidades del módulo Cartas CITE.
///
/// Un CITE es la correspondencia numerada de la empresa: cartas, memorandos,
/// certificados de trabajo, comunicaciones internas e informes de control
/// interno. Cada uno lleva un correlativo por (tipo, empresa, gestión) que se
/// imprime como `G.A./007/2025` y que, una vez emitido, no se reutiliza aunque
/// el documento se anule.
///
/// El correlativo **lo asigna la base al guardar**, no el formulario: lo que se
/// ve mientras se redacta es una previsualización.
library;

/// Los seis tipos de la tabla `tcr_tipoDocumento`.
///
/// Los ids no son correlativos (falta el 3, 4 y 5) y no se hardcodea la lista
/// —viene de la base—, pero sí las reglas de qué campos muestra cada uno,
/// porque son las que dibujan el formulario.
abstract final class TipoCite {
  static const int carta = 1;
  static const int memorando = 2;
  static const int certificadoTrabajo = 6;
  static const int comunicacionInterna = 7;
  static const int informeControlInterno = 8;
  static const int comunicacionCi = 9;

  /// Los que se dirigen a alguien de afuera, con nombre escrito a mano.
  static bool destinatarioLibre(int t) =>
      t == carta || t == informeControlInterno || t == comunicacionCi;

  /// Los que eligen a un empleado de la planilla de un desplegable.
  static bool destinatarioEmpleado(int t) =>
      t == memorando || t == comunicacionInterna;

  static bool usaCiudad(int t) =>
      t == carta || t == certificadoTrabajo || t == informeControlInterno || t == comunicacionCi;

  static bool usaReferencia(int t) => t == carta || t == comunicacionCi;

  static bool usaAsunto(int t) =>
      t == memorando || t == comunicacionInterna || t == informeControlInterno;

  /// Sólo el informe de control interno lleva "Vía:".
  static bool usaVia(int t) => t == informeControlInterno;

  /// El certificado de trabajo no elige área: el sistema le pone G.A.
  static bool usaArea(int t) => t != certificadoTrabajo;

  /// En la COM. CI el destinatario se guarda como "DE:" del formato impreso.
  static bool destinatarioEsRemite(int t) => t == comunicacionCi;
}

/// Cabecera de un documento CITE.
class CartaCiteEntity {
  BigInt idDocumento;
  BigInt idTipoDoc;
  BigInt idGestion;
  BigInt codEmpresa;
  BigInt codUsuario;
  BigInt codEmpleado;

  /// Sólo en COM. CI: el destinatario, que el formato imprime como "DE:".
  String empleadoDe;
  String cargoDe;

  String ciudad;

  /// Sigla del área emisora ("G.A."), que es lo que sale impreso en el CITE.
  String area;

  int nroCite;
  DateTime? fechaDoc;
  String dirigido;
  String cargoDirigido;
  String referencia;
  String via;
  String cargoVia;
  String asunto;

  /// Cuerpo en HTML simple. Lo produce el editor y lo imprime Jasper con
  /// `markup="html"`, así que el subconjunto de etiquetas es acotado:
  /// `<p> <strong> <em> <u> <s> <br> <a>`.
  String cuerpo;

  /// Estado de la fila, siempre 'V'.
  ///
  /// **No indica anulación**: eso llega en [esAnulado]. La marca de anulación
  /// vive en una tabla aparte para no alterar la numeración del módulo JSF,
  /// que cuenta las filas con `estado='V'` para saber qué número sigue.
  String estado;

  // ── sólo lectura, los llena el backend ────────────────────────────────
  String tipo;
  int gestion;
  String empresa;

  /// El correlativo ya formateado: `G.A./007/2025`.
  String cite;

  /// "SI" cuando ya se generó el PDF alguna vez.
  String exportado;
  String redactadoPor;

  /// 1 si el usuario que consulta redactó el documento.
  int esAutor;

  /// 1 si el documento fue anulado. El listado ya los excluye, así que sólo
  /// puede venir en 1 al abrir uno directamente.
  int esAnulado;

  BigInt idRegDoc;

  /// Total de filas que matchean el filtro; viaja repetido en cada fila.
  int totalRegistros;

  // ── hijos ─────────────────────────────────────────────────────────────
  List<CopiaArchEntity> copiasArchivo;
  List<CopiaEncabezadoEntity> destinatarios;
  List<RemitenteEntity> remitentes;

  CartaCiteEntity({
    required this.idDocumento,
    required this.idTipoDoc,
    required this.idGestion,
    required this.codEmpresa,
    required this.codUsuario,
    required this.codEmpleado,
    this.empleadoDe = '',
    this.cargoDe = '',
    this.ciudad = '',
    this.area = '',
    this.nroCite = 0,
    this.fechaDoc,
    this.dirigido = '',
    this.cargoDirigido = '',
    this.referencia = '',
    this.via = '',
    this.cargoVia = '',
    this.asunto = '',
    this.cuerpo = '',
    this.estado = 'V',
    this.tipo = '',
    this.gestion = 0,
    this.empresa = '',
    this.cite = '',
    this.exportado = 'NO',
    this.redactadoPor = '',
    this.esAutor = 0,
    this.esAnulado = 0,
    BigInt? idRegDoc,
    this.totalRegistros = 0,
    List<CopiaArchEntity>? copiasArchivo,
    List<CopiaEncabezadoEntity>? destinatarios,
    List<RemitenteEntity>? remitentes,
  })  : idRegDoc = idRegDoc ?? BigInt.zero,
        copiasArchivo = copiasArchivo ?? [],
        destinatarios = destinatarios ?? [],
        remitentes = remitentes ?? [];

  /// Un documento nuevo, en blanco, para el tipo y la empresa elegidos.
  factory CartaCiteEntity.nuevo({
    required int idTipoDoc,
    required int codEmpresa,
    required int codUsuario,
  }) =>
      CartaCiteEntity(
        idDocumento: BigInt.zero,
        idTipoDoc: BigInt.from(idTipoDoc),
        idGestion: BigInt.zero,
        codEmpresa: BigInt.from(codEmpresa),
        codUsuario: BigInt.from(codUsuario),
        codEmpleado: BigInt.zero,
        fechaDoc: DateTime.now(),
        ciudad: 'La Paz',
      );

  bool get esNuevo => idDocumento == BigInt.zero;
  bool get anulado => esAnulado == 1;
  bool get yaExportado => exportado == 'SI';
  int get tipoDoc => idTipoDoc.toInt();

  /// Copia con los hijos duplicados y todos los ids en cero: el documento
  /// resultante se guarda como uno nuevo y saca su propio número de CITE.
  ///
  /// Es la función "Duplicar" del módulo viejo, que servía para no volver a
  /// tipear una carta casi igual a otra.
  CartaCiteEntity duplicar() => CartaCiteEntity(
        idDocumento: BigInt.zero,
        idTipoDoc: idTipoDoc,
        idGestion: BigInt.zero,
        codEmpresa: codEmpresa,
        codUsuario: codUsuario,
        codEmpleado: codEmpleado,
        empleadoDe: empleadoDe,
        cargoDe: cargoDe,
        ciudad: ciudad,
        area: area,
        nroCite: 0,
        fechaDoc: DateTime.now(),
        dirigido: dirigido,
        cargoDirigido: cargoDirigido,
        referencia: referencia,
        via: via,
        cargoVia: cargoVia,
        asunto: asunto,
        cuerpo: cuerpo,
        tipo: tipo,
        empresa: empresa,
        copiasArchivo: copiasArchivo
            .map((e) => CopiaArchEntity(idCopiaArch: BigInt.zero, copiaArch: e.copiaArch))
            .toList(),
        destinatarios: destinatarios
            .map((e) => CopiaEncabezadoEntity(
                idCopiaEncab: BigInt.zero, copiaEnca: e.copiaEnca, cargoCopia: e.cargoCopia))
            .toList(),
        remitentes: remitentes
            .map((e) => RemitenteEntity(
                idRemitente: BigInt.zero, remitente: e.remitente, cargoRemitente: e.cargoRemitente))
            .toList(),
      );
}

/// Una línea del bloque "cc/Arch" del pie. La columna en BD son 25 caracteres.
class CopiaArchEntity {
  BigInt idCopiaArch;
  String copiaArch;

  CopiaArchEntity({required this.idCopiaArch, this.copiaArch = ''});
}

/// Un destinatario extra del encabezado ("Copia a:"), con nombre y cargo.
class CopiaEncabezadoEntity {
  BigInt idCopiaEncab;
  String copiaEnca;
  String cargoCopia;

  CopiaEncabezadoEntity({
    required this.idCopiaEncab,
    this.copiaEnca = '',
    this.cargoCopia = '',
  });
}

/// Quien firma. Máximo dos: es lo que entra en el formato impreso y el SP
/// rechaza el tercero.
class RemitenteEntity {
  BigInt idRemitente;
  String remitente;
  String cargoRemitente;

  RemitenteEntity({
    required this.idRemitente,
    this.remitente = '',
    this.cargoRemitente = '',
  });
}

/// Catálogo `tcr_tipoDocumento`.
class TipoDocumentoCiteEntity {
  final BigInt idTipoDoc;
  final String tipo;

  const TipoDocumentoCiteEntity({required this.idTipoDoc, required this.tipo});
}

/// Área emisora. Se identifica por sigla, no por id: la sigla es lo que se
/// graba y lo que se imprime.
class AreaCiteEntity {
  final String siglas;
  final String descripcion;

  const AreaCiteEntity({required this.siglas, required this.descripcion});

  String get etiqueta => '$siglas — $descripcion';
}

/// Gestión (año) del correlativo. En la previsualización viene además el
/// `nroCite` que tocaría.
class GestionCiteEntity {
  final BigInt idGestion;
  final int gestion;
  final String activo;
  final int nroCite;

  const GestionCiteEntity({
    required this.idGestion,
    required this.gestion,
    this.activo = 'NO',
    this.nroCite = 0,
  });

  bool get esActiva => activo == 'SI';
}

/// Una persona con su cargo vigente: destinatarios de planilla y la firma del
/// usuario logueado.
class EmpleadoCiteEntity {
  final BigInt codEmpleado;
  final String nombreCompleto;
  final String cargo;

  const EmpleadoCiteEntity({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.cargo = '',
  });
}
