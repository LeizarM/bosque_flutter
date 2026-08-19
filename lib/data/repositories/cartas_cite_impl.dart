import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/carta_cite_model.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:bosque_flutter/domain/repositories/cartas_cite_repository.dart';

/// Implementación HTTP del módulo Cartas CITE.
///
/// Todos los endpoints son POST, incluidas las lecturas: es la convención del
/// backend, no un descuido.
class CartasCiteImpl extends BaseApiRepository implements CartasCiteRepository {
  /// El backend serializa con `yyyy-MM-dd HH:mm:ss` y acepta ese mismo formato
  /// de entrada (`JacksonConfig.DATE_FORMATS`).
  String _fecha(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-'
      '${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')} 00:00:00';

  @override
  Future<List<CartaCiteEntity>> listar({
    required DateTime fechaDesde,
    required DateTime fechaHasta,
    required int idTipoDoc,
    required int codEmpresa,
    required int codUsuario,
    String? buscar,
    required int pagina,
    required int tamanoPagina,
  }) async {
    final modelos = await postAndReturnList<CartaCiteModel>(
      endpoint: AppConstants.citeListar,
      data: {
        'fechaDesde': _fecha(fechaDesde),
        'fechaHasta': _fecha(fechaHasta),
        'idTipoDoc': idTipoDoc,
        'codEmpresa': codEmpresa,
        'codUsuario': codUsuario,
        'buscar': buscar,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
      },
      fromJson: (json) => CartaCiteModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CartaCiteEntity?> obtener(BigInt idDocumento) async {
    final modelo = await postAndReturnObject<CartaCiteModel>(
      endpoint: AppConstants.citeObtener,
      data: {'idDocumento': idDocumento.toInt()},
      fromJson: (json) => CartaCiteModel.fromJson(json),
      errorMessage: 'No se pudo cargar el documento',
    );
    return modelo?.toEntity();
  }

  @override
  Future<GestionCiteEntity?> siguienteCite({
    required int idTipoDoc,
    required int codEmpresa,
  }) async {
    final modelo = await postAndReturnObject<GestionCiteModel>(
      endpoint: AppConstants.citeSiguienteCite,
      data: {'idTipoDoc': idTipoDoc, 'codEmpresa': codEmpresa},
      fromJson: (json) => GestionCiteModel.fromJson(json),
      errorMessage: 'No se pudo obtener el número de CITE',
    );
    return modelo?.toEntity();
  }

  @override
  Future<List<TipoDocumentoCiteEntity>> tiposDocumento() async {
    final modelos = await postAndReturnList<TipoDocumentoCiteModel>(
      endpoint: AppConstants.citeTiposDocumento,
      data: const {},
      fromJson: (json) => TipoDocumentoCiteModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AreaCiteEntity>> areas(int codEmpresa) async {
    final modelos = await postAndReturnList<AreaCiteModel>(
      endpoint: AppConstants.citeAreas,
      data: {'codEmpresa': codEmpresa},
      fromJson: (json) => AreaCiteModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<EmpleadoCiteEntity>> empleados() async {
    final modelos = await postAndReturnList<EmpleadoCiteModel>(
      endpoint: AppConstants.citeEmpleados,
      data: const {},
      fromJson: (json) => EmpleadoCiteModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<EmpleadoCiteEntity?> empleado(int codEmpleado) async {
    final modelo = await postAndReturnObject<EmpleadoCiteModel>(
      endpoint: AppConstants.citeEmpleado,
      data: {'codEmpleado': codEmpleado},
      fromJson: (json) => EmpleadoCiteModel.fromJson(json),
      errorMessage: 'No se pudo obtener el empleado',
    );
    return modelo?.toEntity();
  }

  @override
  Future<EmpleadoCiteEntity?> firmaUsuario(int codUsuario) async {
    final modelo = await postAndReturnObject<EmpleadoCiteModel>(
      endpoint: AppConstants.citeFirmaUsuario,
      data: {'codUsuario': codUsuario},
      fromJson: (json) => EmpleadoCiteModel.fromJson(json),
      errorMessage: 'No se pudo obtener el cargo del usuario',
    );
    return modelo?.toEntity();
  }

  @override
  Future<List<GestionCiteEntity>> gestiones() async {
    final modelos = await postAndReturnList<GestionCiteModel>(
      endpoint: AppConstants.citeGestiones,
      data: const {},
      fromJson: (json) => GestionCiteModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> prepararGestion(int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.citePrepararGestion,
      data: {'audUsuario': audUsuario},
      errorMessage: 'No se pudo preparar la gestión',
    );
  }

  @override
  Future<String> guardar(
    CartaCiteEntity carta, {
    required List<BigInt> copiasAEliminar,
    required List<BigInt> destinatariosAEliminar,
    required List<BigInt> remitentesAEliminar,
    required int audUsuario,
  }) async {
    /// Se usa `postAndReturnFullResponse` y no `postAndReturnId` porque en un
    /// alta el mensaje del backend trae el número de CITE realmente asignado,
    /// que es lo único que le importa a quien acaba de redactar.
    final respuesta = await postAndReturnFullResponse<Map<String, dynamic>>(
      endpoint: AppConstants.citeGuardar,
      data: CartaCiteModel(carta).toJson(
        audUsuario: audUsuario,
        copiasAEliminar: copiasAEliminar,
        destinatariosAEliminar: destinatariosAEliminar,
        remitentesAEliminar: remitentesAEliminar,
      ),
      fromJson: (json) => json,
      errorMessage: 'No se pudo guardar el documento',
    );
    return respuesta['message']?.toString() ?? 'Documento guardado.';
  }

  @override
  Future<String> anular(BigInt idDocumento, int audUsuario, {String? motivo}) async {
    final respuesta = await postAndReturnFullResponse<Map<String, dynamic>>(
      endpoint: AppConstants.citeAnular,
      data: {
        'idDocumento': idDocumento.toInt(),
        'audUsuario': audUsuario,
        'motivo': motivo,
      },
      fromJson: (json) => json,
      errorMessage: 'No se pudo anular el documento',
    );
    return respuesta['message']?.toString() ?? 'Documento anulado.';
  }

  @override
  Future<Uint8List> generarPdf({
    required BigInt idDocumento,
    required bool conLogo,
    required int audUsuario,
  }) {
    return DioClient.descargarReportePdf(
      endpoint: AppConstants.citeGenerarPdf,
      data: {
        'idDocumento': idDocumento.toInt(),
        'logo': conLogo ? 'SI' : 'NO',
        'audUsuario': audUsuario,
      },
    );
  }

  @override
  Future<Uint8List> reporteMensual({
    required int mes,
    required int anio,
    required int idTipoDoc,
    required int codEmpresa,
  }) {
    return DioClient.descargarReportePdf(
      endpoint: AppConstants.citeReporteMensual,
      data: {
        'mes': mes,
        'anio': anio,
        'idTipoDoc': idTipoDoc,
        'codEmpresa': codEmpresa,
      },
    );
  }
}
