import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';

/// Archivo de documentos. Las escrituras lanzan con el motivo del servidor;
/// alta si el id es 0, edición si no, y devuelven el id.
abstract class ArchivoDocumentalRepository {
  Future<List<ArchivoFisicoEntity>> listarArchivos();
  Future<int> registrarArchivo(ArchivoFisicoEntity archivo);
  Future<void> eliminarArchivo(int codArchivo);

  Future<List<TipoDocumentoArchivoEntity>> listarTipos();
  Future<int> registrarTipo(TipoDocumentoArchivoEntity tipo);
  Future<void> eliminarTipo(int codTipoDocumento);

  /// Todas las cajas: la búsqueda se hace del lado del cliente.
  Future<List<CajaArchivoEntity>> listarCajas();
  Future<int> siguienteNumero(int codArchivo);
  Future<int> registrarCaja(CajaArchivoEntity caja);
  Future<void> eliminarCaja(int codCaja);

  /// Todo el contenido de todas las cajas.
  Future<List<ContenidoCajaEntity>> listarContenido();
  Future<int> registrarContenido(ContenidoCajaEntity contenido);
  Future<void> eliminarContenido(int codContenido);

  Future<List<FotoCajaEntity>> listarFotos(int codCaja);

  /// [alProgreso] recibe bytes enviados y total, para la barra de la subida.
  Future<int> subirFoto(
    int codCaja,
    Uint8List bytes,
    String nombre, {
    void Function(int enviados, int total)? alProgreso,
  });
  Future<void> reemplazarFoto(
    int codFoto,
    Uint8List bytes,
    String nombre, {
    void Function(int enviados, int total)? alProgreso,
  });
  Future<void> eliminarFoto(int codFoto);
  Future<Uint8List> verFoto(int codFoto);

  Future<List<EmpresaEntity>> listarEmpresas();

  /// Las sucursales (`tb_sucursal`) para ubicar un archivo físico.
  Future<List<SucursalArchivoEntity>> listarSucursales();

  /// El PDF de un reporte. Sin documentos que cumplan lanza con el motivo.
  Future<Uint8List> generarReporte(PedidoReporteArchivo pedido);
}

/// Los reportes del archivo; [clave] es el nombre que espera el backend.
enum ReporteArchivo {
  porSucursal('POR_SUCURSAL', 'Documentos por sucursal'),
  porTipo('POR_TIPO', 'Dónde está cada tipo de documento'),
  detalle('DETALLE', 'Detalle de documentos por caja');

  const ReporteArchivo(this.clave, this.titulo);

  final String clave;
  final String titulo;
}

/// Un pedido de reporte. Todo filtro null es «todos»; [codEmpresa] = 0 pide los
/// documentos sin empresa.
class PedidoReporteArchivo {
  const PedidoReporteArchivo({
    required this.reporte,
    this.codSucursal,
    this.codTipoDocumento,
    this.codEmpresa,
    this.anioDesde,
    this.anioHasta,
  });

  final ReporteArchivo reporte;
  final int? codSucursal;
  final int? codTipoDocumento;
  final int? codEmpresa;
  final int? anioDesde;
  final int? anioHasta;

  Map<String, dynamic> toJson() => {
    'reporte': reporte.clave,
    'codSucursal': codSucursal,
    'codTipoDocumento': codTipoDocumento,
    'codEmpresa': codEmpresa,
    'anioDesde': anioDesde,
    'anioHasta': anioHasta,
  };
}
