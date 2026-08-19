import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';

/// Conversión JSON ⇄ entidad del módulo Cartas CITE.
///
/// Los helpers de arriba concentran la defensa contra lo que devuelve el
/// backend: los ids llegan como `int` de Jackson pero en Dart son `BigInt`, y
/// varias columnas de `tcr_*` son nullable en la base —el módulo viejo grababa
/// sin validar— así que un `null` en `dirigido` o `asunto` es normal y no debe
/// romper la pantalla.
BigInt _id(dynamic v) {
  if (v == null) return BigInt.zero;
  if (v is BigInt) return v;
  if (v is num) return BigInt.from(v.toInt());
  return BigInt.tryParse(v.toString()) ?? BigInt.zero;
}

int _entero(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _texto(dynamic v) => v?.toString() ?? '';

/// El backend serializa fechas como `yyyy-MM-dd HH:mm:ss` (ver `JacksonConfig`),
/// que `DateTime.parse` no acepta por el espacio en lugar de la T.
DateTime? _fecha(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

/// Formato que espera el backend en los payloads de escritura.
String _fechaTexto(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-'
    '${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')} 00:00:00';

class CartaCiteModel {
  final CartaCiteEntity entity;

  const CartaCiteModel(this.entity);

  factory CartaCiteModel.fromJson(Map<String, dynamic> json) => CartaCiteModel(
        CartaCiteEntity(
          idDocumento: _id(json['idDocumento']),
          idTipoDoc: _id(json['idTipoDoc']),
          idGestion: _id(json['idGestion']),
          codEmpresa: _id(json['codEmpresa']),
          codUsuario: _id(json['codUsuario']),
          codEmpleado: _id(json['codEmpleado']),
          empleadoDe: _texto(json['empleadoDe']),
          cargoDe: _texto(json['cargoDe']),
          ciudad: _texto(json['ciudad']),
          area: _texto(json['area']).trim(),
          nroCite: _entero(json['nroCite']),
          fechaDoc: _fecha(json['fechaDoc']),
          dirigido: _texto(json['dirigido']),
          cargoDirigido: _texto(json['cargoDirigido']),
          referencia: _texto(json['referencia']),
          via: _texto(json['via']),
          cargoVia: _texto(json['cargoVia']),
          asunto: _texto(json['asunto']),
          cuerpo: _texto(json['cuerpo']),
          estado: _texto(json['estado']).isEmpty ? 'V' : _texto(json['estado']),
          tipo: _texto(json['tipo']),
          gestion: _entero(json['gestion']),
          empresa: _texto(json['empresa']),
          cite: _texto(json['cite']),
          exportado: _texto(json['exportado']).isEmpty ? 'NO' : _texto(json['exportado']),
          redactadoPor: _texto(json['redactadoPor']),
          esAutor: _entero(json['esAutor']),
          esAnulado: _entero(json['esAnulado']),
          idRegDoc: _id(json['idRegDoc']),
          totalRegistros: _entero(json['totalRegistros']),
          copiasArchivo: (json['copiasArchivo'] as List<dynamic>? ?? [])
              .map((e) => CopiaArchModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList(),
          destinatarios: (json['destinatarios'] as List<dynamic>? ?? [])
              .map((e) => CopiaEncabezadoModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList(),
          remitentes: (json['remitentes'] as List<dynamic>? ?? [])
              .map((e) => RemitenteModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList(),
        ),
      );

  CartaCiteEntity toEntity() => entity;

  /// Payload de `/cartas-cite/guardar`.
  ///
  /// **No manda `nroCite` ni `idGestion`.** En un alta los asigna el SP dentro
  /// de la transacción y en una modificación no se tocan: mandarlos sólo daría
  /// la ilusión de que el cliente los controla.
  ///
  /// Los campos que el tipo de documento no usa viajan igual en vacío; el SP
  /// les pone su 'N/A' según el tipo, que es lo que esperan los reportes.
  Map<String, dynamic> toJson({
    required int audUsuario,
    List<BigInt> copiasAEliminar = const [],
    List<BigInt> destinatariosAEliminar = const [],
    List<BigInt> remitentesAEliminar = const [],
  }) {
    final e = entity;
    return {
      'idDocumento': e.idDocumento.toInt(),
      'idTipoDoc': e.idTipoDoc.toInt(),
      'codEmpresa': e.codEmpresa.toInt(),
      'codUsuario': e.codUsuario.toInt(),
      'codEmpleado': e.codEmpleado.toInt(),
      'empleadoDe': e.empleadoDe,
      'cargoDe': e.cargoDe,
      'ciudad': e.ciudad,
      'area': e.area,
      'fechaDoc': _fechaTexto(e.fechaDoc ?? DateTime.now()),
      'dirigido': e.dirigido,
      'cargoDirigido': e.cargoDirigido,
      'referencia': e.referencia,
      'via': e.via,
      'cargoVia': e.cargoVia,
      'asunto': e.asunto,
      'cuerpo': e.cuerpo,
      'audUsuario': audUsuario,
      'copiasArchivo': e.copiasArchivo
          .map((c) => CopiaArchModel(c).toJson(audUsuario))
          .toList(),
      'destinatarios': e.destinatarios
          .map((c) => CopiaEncabezadoModel(c).toJson(audUsuario))
          .toList(),
      'remitentes':
          e.remitentes.map((r) => RemitenteModel(r).toJson(audUsuario)).toList(),
      'copiasArchivoAEliminar': copiasAEliminar.map((i) => i.toInt()).toList(),
      'destinatariosAEliminar': destinatariosAEliminar.map((i) => i.toInt()).toList(),
      'remitentesAEliminar': remitentesAEliminar.map((i) => i.toInt()).toList(),
    };
  }
}

class CopiaArchModel {
  final CopiaArchEntity entity;
  const CopiaArchModel(this.entity);

  factory CopiaArchModel.fromJson(Map<String, dynamic> json) => CopiaArchModel(
        CopiaArchEntity(
          idCopiaArch: _id(json['idCopiaArch']),
          copiaArch: _texto(json['copiaArch']),
        ),
      );

  CopiaArchEntity toEntity() => entity;

  Map<String, dynamic> toJson(int audUsuario) => {
        'idCopiaArch': entity.idCopiaArch.toInt(),
        'copiaArch': entity.copiaArch,
        'audUsuario': audUsuario,
      };
}

class CopiaEncabezadoModel {
  final CopiaEncabezadoEntity entity;
  const CopiaEncabezadoModel(this.entity);

  factory CopiaEncabezadoModel.fromJson(Map<String, dynamic> json) =>
      CopiaEncabezadoModel(
        CopiaEncabezadoEntity(
          idCopiaEncab: _id(json['idCopiaEncab']),
          copiaEnca: _texto(json['copiaEnca']),
          cargoCopia: _texto(json['cargoCopia']),
        ),
      );

  CopiaEncabezadoEntity toEntity() => entity;

  Map<String, dynamic> toJson(int audUsuario) => {
        'idCopiaEncab': entity.idCopiaEncab.toInt(),
        'copiaEnca': entity.copiaEnca,
        'cargoCopia': entity.cargoCopia,
        'audUsuario': audUsuario,
      };
}

class RemitenteModel {
  final RemitenteEntity entity;
  const RemitenteModel(this.entity);

  factory RemitenteModel.fromJson(Map<String, dynamic> json) => RemitenteModel(
        RemitenteEntity(
          idRemitente: _id(json['idRemitente']),
          remitente: _texto(json['remitente']),
          cargoRemitente: _texto(json['cargoRemitente']),
        ),
      );

  RemitenteEntity toEntity() => entity;

  Map<String, dynamic> toJson(int audUsuario) => {
        'idRemitente': entity.idRemitente.toInt(),
        'remitente': entity.remitente,
        'cargoRemitente': entity.cargoRemitente,
        'audUsuario': audUsuario,
      };
}

class TipoDocumentoCiteModel {
  final TipoDocumentoCiteEntity entity;
  const TipoDocumentoCiteModel(this.entity);

  factory TipoDocumentoCiteModel.fromJson(Map<String, dynamic> json) =>
      TipoDocumentoCiteModel(TipoDocumentoCiteEntity(
        idTipoDoc: _id(json['idTipoDoc']),
        tipo: _texto(json['tipo']),
      ));

  TipoDocumentoCiteEntity toEntity() => entity;
}

class AreaCiteModel {
  final AreaCiteEntity entity;
  const AreaCiteModel(this.entity);

  /// `siglas` es `nchar(20)` en la base, así que llega con relleno de espacios
  /// a la derecha. Sin el trim, el valor del desplegable nunca coincide con el
  /// `area` guardado del documento y el combo aparece en blanco al editar.
  factory AreaCiteModel.fromJson(Map<String, dynamic> json) =>
      AreaCiteModel(AreaCiteEntity(
        siglas: _texto(json['siglas']).trim(),
        descripcion: _texto(json['descripcion']).trim(),
      ));

  AreaCiteEntity toEntity() => entity;
}

class GestionCiteModel {
  final GestionCiteEntity entity;
  const GestionCiteModel(this.entity);

  factory GestionCiteModel.fromJson(Map<String, dynamic> json) =>
      GestionCiteModel(GestionCiteEntity(
        idGestion: _id(json['idGestion']),
        gestion: _entero(json['gestion']),
        activo: _texto(json['activo']),
        nroCite: _entero(json['nroCite']),
      ));

  GestionCiteEntity toEntity() => entity;
}

class EmpleadoCiteModel {
  final EmpleadoCiteEntity entity;
  const EmpleadoCiteModel(this.entity);

  factory EmpleadoCiteModel.fromJson(Map<String, dynamic> json) =>
      EmpleadoCiteModel(EmpleadoCiteEntity(
        codEmpleado: _id(json['codEmpleado']),
        nombreCompleto: _texto(json['nombreCompleto']).trim(),
        cargo: _texto(json['cargo']).trim(),
      ));

  EmpleadoCiteEntity toEntity() => entity;
}
