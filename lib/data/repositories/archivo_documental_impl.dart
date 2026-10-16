import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/tipo_imagen.dart';
import 'package:bosque_flutter/data/models/archivo_fisico_model.dart';
import 'package:bosque_flutter/data/models/caja_archivo_model.dart';
import 'package:bosque_flutter/data/models/contenido_caja_model.dart';
import 'package:bosque_flutter/data/models/destruccion_documento_model.dart';
import 'package:bosque_flutter/data/models/empleado_archivo_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/entrega_documento_model.dart';
import 'package:bosque_flutter/data/models/foto_caja_model.dart';
import 'package:bosque_flutter/data/models/prestamo_documento_model.dart';
import 'package:bosque_flutter/data/models/sucursal_archivo_model.dart';
import 'package:bosque_flutter/data/models/tipo_documento_archivo_model.dart';
import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/destruccion_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';

class ArchivoDocumentalImpl extends BaseApiRepository
    implements ArchivoDocumentalRepository {
  /// Una foto de varios MB por una red lenta tarda más que la espera global.
  static const Duration _esperaFoto = Duration(minutes: 2);

  /// El detalle completo son ~1.100 filas que Jasper compila y pagina.
  static const Duration _esperaReporte = Duration(minutes: 2);

  // ── Archivos ────────────────────────────────────────────────────────────
  @override
  Future<List<ArchivoFisicoEntity>> listarArchivos() => _lista(
    AppConstants.arcArchivosListar,
    ArchivoFisicoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<int> registrarArchivo(ArchivoFisicoEntity archivo) async =>
      (await postAndReturnId(
        endpoint: AppConstants.arcArchivosRegistrar,
        data: ArchivoFisicoModel.fromEntity(archivo).toRegistroJson(),
        errorMessage: 'No se pudo guardar el archivo.',
      )).toInt();

  @override
  Future<void> eliminarArchivo(int codArchivo) => postAndReturnId(
    endpoint: AppConstants.arcArchivosEliminar,
    data: {'codArchivo': codArchivo},
    errorMessage: 'No se pudo eliminar el archivo.',
  );

  // ── Tipos de documento ──────────────────────────────────────────────────
  @override
  Future<List<TipoDocumentoArchivoEntity>> listarTipos() => _lista(
    AppConstants.arcTiposListar,
    TipoDocumentoArchivoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<int> registrarTipo(TipoDocumentoArchivoEntity tipo) async =>
      (await postAndReturnId(
        endpoint: AppConstants.arcTiposRegistrar,
        data: TipoDocumentoArchivoModel.fromEntity(tipo).toRegistroJson(),
        errorMessage: 'No se pudo guardar el tipo de documento.',
      )).toInt();

  @override
  Future<void> eliminarTipo(int codTipoDocumento) => postAndReturnId(
    endpoint: AppConstants.arcTiposEliminar,
    data: {'codTipoDocumento': codTipoDocumento},
    errorMessage: 'No se pudo eliminar el tipo de documento.',
  );

  // ── Cajas ───────────────────────────────────────────────────────────────
  @override
  Future<List<CajaArchivoEntity>> listarCajas() => _lista(
    AppConstants.arcCajasListar,
    CajaArchivoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<int> siguienteNumero(int codArchivo) async =>
      (await postAndReturnId(
        endpoint: AppConstants.arcCajasSiguienteNumero,
        data: {'codArchivo': codArchivo},
        errorMessage: 'No se pudo proponer el número de caja.',
      )).toInt();

  @override
  Future<int> registrarCaja(CajaArchivoEntity caja) async =>
      (await postAndReturnId(
        endpoint: AppConstants.arcCajasRegistrar,
        data: CajaArchivoModel.fromEntity(caja).toRegistroJson(),
        errorMessage: 'No se pudo guardar la caja.',
      )).toInt();

  @override
  Future<void> eliminarCaja(int codCaja) => postAndReturnId(
    endpoint: AppConstants.arcCajasEliminar,
    data: {'codCaja': codCaja},
    errorMessage: 'No se pudo eliminar la caja.',
  );

  // ── Contenido ───────────────────────────────────────────────────────────
  @override
  Future<List<ContenidoCajaEntity>> listarContenido() => _lista(
    AppConstants.arcContenidoListar,
    ContenidoCajaModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<int> registrarContenido(ContenidoCajaEntity contenido) async =>
      (await postAndReturnId(
        endpoint: AppConstants.arcContenidoRegistrar,
        data: ContenidoCajaModel.fromEntity(contenido).toRegistroJson(),
        errorMessage: 'No se pudo guardar la línea de contenido.',
      )).toInt();

  @override
  Future<void> eliminarContenido(int codContenido) => postAndReturnId(
    endpoint: AppConstants.arcContenidoEliminar,
    data: {'codContenido': codContenido},
    errorMessage: 'No se pudo eliminar la línea de contenido.',
  );

  // ── Fotos ───────────────────────────────────────────────────────────────
  @override
  Future<List<FotoCajaEntity>> listarFotos(int codCaja) => _lista(
    AppConstants.arcFotosListar,
    FotoCajaModel.fromJson,
    (m) => m.toEntity(),
    data: {'codCaja': codCaja},
  );

  @override
  Future<int> subirFoto(
    int codCaja,
    Uint8List bytes,
    String nombre, {
    void Function(int enviados, int total)? alProgreso,
  }) => _multipart(
    AppConstants.arcFotosSubir,
    'codCaja',
    codCaja,
    bytes,
    nombre,
    'No se pudo subir la foto.',
    alProgreso,
  );

  @override
  Future<void> reemplazarFoto(
    int codFoto,
    Uint8List bytes,
    String nombre, {
    void Function(int enviados, int total)? alProgreso,
  }) => _multipart(
    AppConstants.arcFotosReemplazar,
    'codFoto',
    codFoto,
    bytes,
    nombre,
    'No se pudo reemplazar la foto.',
    alProgreso,
  );

  @override
  Future<void> eliminarFoto(int codFoto) => postAndReturnId(
    endpoint: AppConstants.arcFotosEliminar,
    data: {'codFoto': codFoto},
    errorMessage: 'No se pudo eliminar la foto.',
  );

  @override
  Future<Uint8List> verFoto(int codFoto) async {
    try {
      final r = await dio.post(
        AppConstants.arcFotosVer,
        data: {'codFoto': codFoto},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(r.data as List<int>);
    } on DioException catch (e) {
      // Con respuesta en bytes el JSON de error llega sin interpretar.
      final datos = e.response?.data;
      if (datos is List<int>) {
        try {
          final cuerpo = jsonDecode(utf8.decode(datos));
          if (cuerpo is Map && cuerpo['message'] != null) {
            throw Exception(cuerpo['message'].toString());
          }
        } on FormatException {
          // No era JSON: sigue el mensaje por tipo de error.
        }
      }
      throw Exception(DioClient.handleDioError(e, 'No se pudo cargar la foto.'));
    }
  }

  // ── Empresas (tb_empresa) ───────────────────────────────────────────────
  @override
  Future<List<EmpresaEntity>> listarEmpresas() => _lista(
    AppConstants.arcEmpresas,
    EmpresaModel.fromJson,
    (m) => m.toEntity(),
  );

  // ── Sucursales, empleados y reportes ────────────────────────────────────
  @override
  Future<List<SucursalArchivoEntity>> listarSucursales() => _lista(
    AppConstants.arcSucursales,
    SucursalArchivoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<List<EmpleadoArchivoEntity>> listarEmpleados() => _lista(
    AppConstants.arcEmpleados,
    EmpleadoArchivoModel.fromJson,
    (m) => m.toEntity(),
  );

  // ── Préstamos y bitácora de destrucción ─────────────────────────────────
  @override
  Future<List<EntregaDocumentoEntity>> listarEntregas() => _lista(
    AppConstants.arcEntregasListar,
    EntregaDocumentoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<int> registrarEntrega(PedidoEntrega pedido) async =>
      (await postAndReturnId(
        endpoint: AppConstants.arcEntregasRegistrar,
        data: pedido.toJson(),
        errorMessage: 'No se pudo registrar el préstamo.',
      )).toInt();

  @override
  Future<void> devolverEntrega(int codEntrega, {String? observacion}) => postAndReturnId(
    endpoint: AppConstants.arcEntregasDevolver,
    data: {'codEntrega': codEntrega, 'observacion': observacion},
    errorMessage: 'No se pudo registrar la devolución.',
  );

  @override
  Future<void> anularEntrega(int codEntrega) => postAndReturnId(
    endpoint: AppConstants.arcEntregasAnular,
    data: {'codEntrega': codEntrega},
    errorMessage: 'No se pudo anular la entrega.',
  );

  @override
  Future<List<PrestamoDocumentoEntity>> listarPrestamos() => _lista(
    AppConstants.arcPrestamosListar,
    PrestamoDocumentoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<void> devolver(int codPrestamo, {String? observacion}) => postAndReturnId(
    endpoint: AppConstants.arcPrestamosDevolver,
    data: {'codPrestamo': codPrestamo, 'observacionDevolucion': observacion},
    errorMessage: 'No se pudo registrar la devolución.',
  );

  @override
  Future<void> anularPrestamo(int codPrestamo) => postAndReturnId(
    endpoint: AppConstants.arcPrestamosAnular,
    data: {'codPrestamo': codPrestamo},
    errorMessage: 'No se pudo anular el préstamo.',
  );

  @override
  Future<List<DestruccionDocumentoEntity>> listarDestrucciones() => _lista(
    AppConstants.arcDestruccionesListar,
    DestruccionDocumentoModel.fromJson,
    (m) => m.toEntity(),
  );

  @override
  Future<void> destruir(PedidoMovimientoCaja pedido) => postAndReturnId(
    endpoint: AppConstants.arcDestruccionesRegistrar,
    data: pedido.toJson(),
    errorMessage: 'No se pudo registrar la destrucción.',
  );

  @override
  Future<void> anularDestruccion(int codDestruccion) => postAndReturnId(
    endpoint: AppConstants.arcDestruccionesAnular,
    data: {'codDestruccion': codDestruccion},
    errorMessage: 'No se pudo anular el registro de destrucción.',
  );

  @override
  Future<Uint8List> generarReporte(PedidoReporteArchivo pedido) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.arcReporte,
        data: pedido.toJson(),
        receiveTimeout: _esperaReporte,
      );

  /// `postAndReturnList` deja pasar el `DioException` crudo y `humanizar` lo
  /// toma siempre por falla del sistema: un corte o un reinicio del servidor
  /// pedía «avisa a Sistemas». Aquí se traduce igual que en las escrituras.
  Future<List<E>> _lista<M, E>(
    String endpoint,
    M Function(Map<String, dynamic>) fromJson,
    E Function(M) aEntidad, {
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final m = await postAndReturnList(endpoint: endpoint, data: data, fromJson: fromJson);
      return m.map(aEntidad).toList();
    } on DioException catch (e) {
      throw Exception(DioClient.handleDioError(e, 'No se pudo traer la información.'));
    }
  }

  /// El id va como parte de texto y la imagen o el PDF en `archivo`. Sin
  /// nombre de archivo Tomcat trata la parte como texto: por eso siempre lleva
  /// uno, con la extensión del formato real (en la web llega `scaled_<nombre>`).
  Future<int> _multipart(
    String endpoint,
    String parteId,
    int id,
    Uint8List bytes,
    String nombre,
    String respaldo,
    void Function(int, int)? alProgreso,
  ) async {
    final tipo = tipoDeImagen(bytes) ?? TipoImagen.jpeg;
    final pdf = esPdf(bytes);
    try {
      final r = await dio.post(
        endpoint,
        data: FormData.fromMap({
          parteId: id.toString(),
          'archivo': MultipartFile.fromBytes(
            bytes,
            filename: pdf ? 'documento.pdf' : 'foto.${tipo.extension}',
            contentType: pdf ? DioMediaType('application', 'pdf') : DioMediaType('image', tipo.subtipo),
          ),
        }),
        onSendProgress: alProgreso,
        options: Options(sendTimeout: _esperaFoto, receiveTimeout: _esperaFoto),
      );
      final datos = r.data is Map ? r.data['data'] : null;
      return (datos as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 413 && e.response?.data is! Map) {
        throw Exception(
          'El servidor rechazó el archivo porque pesa demasiado. Elige uno más liviano.',
        );
      }
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(e.response!.data['message'] ?? respaldo);
      }
      throw Exception(DioClient.handleDioError(e, respaldo));
    }
  }
}
