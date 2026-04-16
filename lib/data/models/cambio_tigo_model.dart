import 'dart:convert';
import 'package:bosque_flutter/domain/entities/cambio_tigo_entity.dart';

CambiosTigoModel cambiosTigoModelFromJson(String str) =>
    CambiosTigoModel.fromJson(json.decode(str));

String cambiosTigoModelToJson(CambiosTigoModel data) =>
    json.encode(data.toJson());

class CambiosTigoModel {
  final int codCambio;
  final int codEmpleado;
  final int codTelefono;
  final int codCuenta;
  final String nombreOrigen;
  final String nombreCompleto;
  final String telefono;
  final String tipoSocio;
  final String descripcion;
  final String estado;
  final String periodoCobrado;
  final int audUsuario;
  // Campo de filtro: se ENVIA al backend pero NO se recibe en la respuesta
  final String? search;
  final int fila;
  final int pagina;
  final int tamanoPagina;
  final int totalPaginas;

  CambiosTigoModel({
    this.codCambio = 0,
    this.codEmpleado = 0,
    this.codTelefono = 0,
    this.codCuenta = 0,
    this.nombreOrigen = '',
    this.nombreCompleto = '',
    this.telefono = '',
    this.tipoSocio = '',
    this.descripcion = '',
    this.estado = '',
    this.periodoCobrado = '',
    this.audUsuario = 0,
    this.search,
    this.fila = 0,
    this.pagina = 1,
    this.tamanoPagina = 15,
    this.totalPaginas = 1,
  });

  // fromJson: mapea la RESPUESTA del backend
  // search NO se incluye porque el backend no lo devuelve
  factory CambiosTigoModel.fromJson(Map<String, dynamic> json) =>
      CambiosTigoModel(
        codCambio: json['codCambio'] ?? 0,
        codEmpleado: json['codEmpleado'] ?? 0,
        codTelefono: json['codTelefono'] ?? 0,
        codCuenta: json['codCuenta'] ?? 0,
        nombreOrigen: json['nombreOrigen'] ?? '',
        nombreCompleto: json['nombreCompleto'] ?? '',
        telefono: json['telefono']?.toString() ?? '',
        tipoSocio: json['tipoSocio'] ?? '',
        descripcion: json['descripcion'] ?? '',
        estado: json['estado'] ?? '',
        periodoCobrado: json['periodoCobrado'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
        // search no se mapea desde la respuesta
        fila: json['fila'] ?? 0,
        pagina: json['pagina'] ?? 1,
        tamanoPagina: json['tamanoPagina'] ?? 15,
        totalPaginas: json['totalPaginas'] ?? 1,
      );

  // toJson: se ENVIA al backend como body del request
  // search y tipoSocio se incluyen como filtros opcionales
  Map<String, dynamic> toJson() => {
    'codCambio': codCambio,
    'codEmpleado': codEmpleado,
    'codTelefono': codTelefono == 0 ? null : codTelefono,
    'codCuenta': codCuenta == 0 ? null : codCuenta,
    'nombreOrigen': nombreOrigen,
    'nombreCompleto': nombreCompleto,
    'telefono': telefono,
    // tipoSocio: enviar null si está vacío → SQL recibe NULL → devuelve TODOS
    'tipoSocio': tipoSocio.isNotEmpty ? tipoSocio : null,
    'descripcion': descripcion,
    'estado': estado.isNotEmpty ? estado : null,
    'periodoCobrado': periodoCobrado.isNotEmpty ? periodoCobrado : null,
    'audUsuario': audUsuario,
    'search': (search?.isNotEmpty == true) ? search : null,
    'fila': fila,
    'pagina': pagina,
    'tamanoPagina': tamanoPagina,
    'totalPaginas': totalPaginas,
  };

  // Model → Entity
  CambiosTigoEntity toEntity() => CambiosTigoEntity(
    codCambio: codCambio,
    codEmpleado: codEmpleado,
    codTelefono: codTelefono,
    codCuenta: codCuenta,
    nombreOrigen: nombreOrigen,
    nombreCompleto: nombreCompleto,
    telefono: telefono,
    tipoSocio: tipoSocio,
    descripcion: descripcion,
    estado: estado,
    periodoCobrado: periodoCobrado,
    audUsuario: audUsuario,
    search: search,
    fila: fila,
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    totalPaginas: totalPaginas,
  );

  // Entity → Model
  factory CambiosTigoModel.fromEntity(CambiosTigoEntity entity) =>
      CambiosTigoModel(
        codCambio: entity.codCambio,
        codEmpleado: entity.codEmpleado,
        codTelefono: entity.codTelefono,
        codCuenta: entity.codCuenta,
        nombreOrigen: entity.nombreOrigen,
        nombreCompleto: entity.nombreCompleto,
        telefono: entity.telefono,
        tipoSocio: entity.tipoSocio,
        descripcion: entity.descripcion,
        estado: entity.estado,
        periodoCobrado: entity.periodoCobrado,
        audUsuario: entity.audUsuario,
        search: entity.search,
        fila: entity.fila,
        pagina: entity.pagina,
        tamanoPagina: entity.tamanoPagina,
        totalPaginas: entity.totalPaginas,
      );
}
