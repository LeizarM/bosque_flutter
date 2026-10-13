import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';

class ArchivoFisicoModel {
  final int codArchivo;
  final String nombre;
  final String? responsable;
  final int? codSucursal;
  final int estado;
  final int audUsuario;
  final DateTime? audFecha;
  final String? nombreSucursal;
  final String? ciudadSucursal;
  final int cajas;
  final int lineas;

  const ArchivoFisicoModel({
    required this.codArchivo,
    required this.nombre,
    this.responsable,
    this.codSucursal,
    this.estado = ArchivoFisicoEntity.activo,
    this.audUsuario = 0,
    this.audFecha,
    this.nombreSucursal,
    this.ciudadSucursal,
    this.cajas = 0,
    this.lineas = 0,
  });

  factory ArchivoFisicoModel.fromJson(Map<String, dynamic> json) {
    // `num` y no `int`: el backend serializa BIGINT e INT sin distinguir.
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return ArchivoFisicoModel(
      codArchivo: entero('codArchivo') ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      responsable: json['responsable'] as String?,
      codSucursal: entero('codSucursal'),
      estado: entero('estado') ?? ArchivoFisicoEntity.activo,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      nombreSucursal: json['nombreSucursal'] as String?,
      ciudadSucursal: json['ciudadSucursal'] as String?,
      cajas: entero('cajas') ?? 0,
      lineas: entero('lineas') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'codArchivo': codArchivo,
    'nombre': nombre,
    'responsable': responsable,
    'codSucursal': codSucursal,
    'estado': estado,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'nombreSucursal': nombreSucursal,
    'ciudadSucursal': ciudadSucursal,
    'cajas': cajas,
    'lineas': lineas,
  };

  /// El cuerpo de `registrar`: solo lo que escribe el SP.
  Map<String, dynamic> toRegistroJson() => {
    'codArchivo': codArchivo,
    'nombre': nombre,
    'responsable': responsable,
    'codSucursal': codSucursal,
    'estado': estado,
    'audUsuario': audUsuario,
  };

  ArchivoFisicoEntity toEntity() => ArchivoFisicoEntity(
    codArchivo: codArchivo,
    nombre: nombre,
    responsable: responsable,
    codSucursal: codSucursal,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreSucursal: nombreSucursal,
    ciudadSucursal: ciudadSucursal,
    cajas: cajas,
    lineas: lineas,
  );

  factory ArchivoFisicoModel.fromEntity(ArchivoFisicoEntity e) =>
      ArchivoFisicoModel(
        codArchivo: e.codArchivo,
        nombre: e.nombre,
        responsable: e.responsable,
        codSucursal: e.codSucursal,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        nombreSucursal: e.nombreSucursal,
        ciudadSucursal: e.ciudadSucursal,
        cajas: e.cajas,
        lineas: e.lineas,
      );
}
