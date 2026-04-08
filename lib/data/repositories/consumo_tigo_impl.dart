import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/models/cambio_tigo_model.dart';
import 'package:bosque_flutter/data/models/chip_tigo_model.dart';
import 'package:bosque_flutter/data/models/factura_tigo_model.dart';
import 'package:bosque_flutter/data/models/socios_tigo_model.dart';
import 'package:bosque_flutter/data/models/tigo_ejecutado_model.dart';
import 'package:bosque_flutter/data/models/tipo_renovacion_chip_tigo.dart';
import 'package:bosque_flutter/domain/entities/cambio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/chip_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_renovacion_chip_tigo_entity.dart';
import 'package:bosque_flutter/domain/repositories/Consumo_tigo_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ConsumoTigoImpl implements ConsumoTigoRepository {
  final Dio _dio = DioClient.getInstance();
  //subir excel factura tigo
  @override
  Future<Map<String, dynamic>> subirExcel(
    Uint8List fileBytes,
    String fileName,
    int audUsuario,
  ) async {
    try {
      console('Subiendo archivo Excel: $fileName, usuario: $audUsuario');

      final formData = FormData.fromMap({
        'audUsuario': audUsuario,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        AppConstants.tigoCargarFacturas,
        data: formData,
      );

      console('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error al subir archivo: ${response.statusCode} - ${response.data}',
        );
      }
    } on DioException catch (e) {
      console('DioException: ${e.response?.data}');
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      console('Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  //ver excel factura tigo
  @override
  Future<List<FacturaTigoEntity>> obtenerFacturaTigo() async {
    try {
      final response = await _dio.post(
        AppConstants.tigoVerFactura,
        data: {}, // Envía un JSON vacío
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => FacturaTigoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener facturaTigo Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener facturaTigo: $e');
      return [];
    }
  }

  //subir excel socios tigo
  @override
  Future<Map<String, dynamic>> subirExcelSocios(
    Uint8List fileBytes,
    String fileName,
    int audUsuario,
  ) async {
    try {
      console(
        'Subiendo archivo Excel de socios: $fileName, usuario: $audUsuario',
      );

      final formData = FormData.fromMap({
        'audUsuario': audUsuario,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        AppConstants.tigoCargarSocios,
        data: formData,
      );

      console('Respuesta del servidor (socios): ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error al subir archivo de socios: ${response.statusCode} - ${response.data}',
        );
      }
    } on DioException catch (e) {
      console('DioException: ${e.response?.data}');
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      console('Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  //OBTENER TOTAL COBRADO X CUENTA
  @override
  Future<List<TigoEjecutadoEntity>> obtenerTotalXcuenta(
    String periodoCobrado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoTotalXCuenta,
        data: {'periodoCobrado': periodoCobrado}, // Envía un JSON vacío
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TigoEjecutadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener tigoTotalCobradoXCuenta Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener tigoTotalXCuenta: $e');
      return [];
    }
  }

  //obtener socios tigo
  @override
  Future<List<SocioTigoEntity>> obtenerSociosTigo() async {
    try {
      final response = await _dio.post(
        AppConstants.tigoVerSocios,
        data: {}, // Envía un JSON vacío
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SociosTigoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener asociadosTigo Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener sociosTigo: $e');
      return [];
    }
  }

  // registrar socios tigo
  @override
  Future<List<SocioTigoEntity>> registrarSocio(SocioTigoEntity socio) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoCargarSocios,
        data: socio.toJson(),
      );

      // Log para depuración
      console('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después de registrar exitosamente, obtener la lista actualizada
        return await obtenerSociosTigo();
      } else {
        throw Exception(
          'Error al registrar socio: ${response.statusCode} - ${response.data}',
        );
      }
    } on DioException catch (e) {
      console('DioException: ${e.response?.data}');
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      console('Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  //OBTENER RESUMEN CUENTAS TIGO
  @override
  Future<List<TigoEjecutadoEntity>> obtenerResumenCuentas(
    String periodoCobrado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoResumenCuentas,
        data: {'periodoCobrado': periodoCobrado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TigoEjecutadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener resumenxcuenta Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener tigoresumencuenta: $e');
      return [];
    }
  }

  //OBTENER RESUMEN DETALLADO TIGO
  @override
  Future<List<TigoEjecutadoEntity>> obtenerResumenDetallado(
    String periodoCobrado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoResumenDetallado,
        data: {"periodoCobrado": periodoCobrado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TigoEjecutadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener resumenDetallado Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener resumenDetallado: $e');
      return [];
    }
  }

  //INSERTAR ANTICIPO TIGO tigoInsertarAnticipo
  @override
Future<bool> generarAnticiposTigo(String periodoCobrado) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoInsertarAnticipo,
      data: {'periodoCobrado': periodoCobrado},
      // ✅ ESTO ES LO QUE ARREGLA EL ERROR 500
      options: Options(
        receiveTimeout: const Duration(seconds: 120), // 2 minutos para el SP
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.statusCode == 200) {
      return true;
    } 
    return false;
  } on DioException catch (e) {
    // Si el error es por tiempo, lo capturamos aquí
    if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('El proceso de anticipos tardó más de 2 minutos. Verifique en SQL.');
    }
    rethrow;
  }
}

  //DESCARGAR REPORTE TIGO
  Future<Uint8List> descargarReporteFacturasTigo(String periodoCobrado) async {
    final response = await _dio.post(
      AppConstants.tigoExportarPdf, // Cambia esto por la URL de tu endpoint
      data: {'periodoCobrado': periodoCobrado}, // No envíes parámetros
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el PDF');
    }
  }

  //MOSTRAR PDF EN PANTALLA
  Future<void> descargarRptConsumoTigo({
    required BuildContext context,
    required String periodoCobrado,
    required ConsumoTigoImpl repo, // Usa tu repo para mantener la arquitectura
  }) async {
    try {
      // Usamos el método ya existente en tu repo para obtener los bytes del PDF
      final pdfBytes = await repo.descargarReporteFacturasTigo(periodoCobrado);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'RptConsumoTigo.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al descargar el PDF: $e')));
    }
  }

  //obtener lista grupos tigo
  //obtener socios tigo
  @override
  Future<List<SocioTigoEntity>> obtenerGruposTigo(String periodoCobrado) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoObtenerGrupos,
        data: {'periodoCobrado': periodoCobrado}, // Envía un JSON vacío
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SociosTigoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener asociadosTigo Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener sociosTigo: $e');
      return [];
    }
  }

  //ELIMINAR GRUPO
  @override
  Future<bool> eliminarGrupo(int codCuenta) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.baseUrl}${AppConstants.tigoEliminarGrupo}/$codCuenta',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //insertar tigo ejectuado
  @override
Future<bool> insertarTigoEjectuado(
  String periodoCobrado,
  int audUsuario,
) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoEjecutarTigo,
      data: {'periodoCobrado': periodoCobrado, 'audUsuario': audUsuario},
      // ✅ CAMBIO 1: Aumentar el tiempo de espera a 2 minutos
      // Esto evita que la app "cuelgue" la conexión a los 10 segundos
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    console('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(
        'Error al ejecutar: ${response.statusCode} - ${response.data}',
      );
    }
  } on DioException catch (e) {
    final response = e.response;

    // ✅ CAMBIO 2: Manejo de Timeout específico
    if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('El servidor tardó demasiado en procesar la ejecución (Timeout de 2 min).');
    }

    // ✅ CAMBIO 3: Mejorar la extracción del mensaje de error
    // Ahora también revisamos errores 500, no solo 400
    if (response != null && (response.statusCode == 400 || response.statusCode == 500)) {
      final data = response.data;
      if (data is Map && data.containsKey('msg')) {
        final errorMessage = data['msg'] as String;
        throw Exception(errorMessage);
      }
    }

    console('DioException genérica: ${response?.data ?? e.message}');
    throw Exception('Error de conexión o servidor. Intente más tarde.');
  } catch (e) {
    console('Error inesperado: $e');
    rethrow;
  }
}

  //obtener tigo ejecutado
  @override
  Future<List<TigoEjecutadoEntity>> obtenerTigoEjecutado(
    String? empresa,
    String periodoCobrado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoObtenerEjecutado,
        data: {'empresa': empresa, 'periodoCobrado': periodoCobrado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TigoEjecutadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener tigoEjecutado Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener obTigoEjecutado: $e');
      return [];
    }
  }

  //OBTENER NUMERO SIN ASIGNAR TIGO
  @override
  Future<List<SocioTigoEntity>> obtenerNroSinAsignar(
    String periodoCobrado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoObtenerNrosSinAsignar,
        data: {'periodoCobrado': periodoCobrado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SociosTigoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener obtenerNroSinAsignar Dio: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener obtenerNroSinAsignar: $e');
      return [];
    }
  }

  //obtener arbol detallado
  @override
  Future<List<TigoEjecutadoEntity>> obtenerArbolDetallado(
    String? empresa,
    String periodoCobrado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoObtenerArbolDetallado,
        data: {"empresa": empresa, "periodoCobrado": periodoCobrado},
      );
      //console('→ Respuesta cruda del backend: ${response.data}'); // Imprime el JSON recibido

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        // console('→ Data parseada como lista: $data'); // Imprime la lista parseada

        final items =
            (data as List<dynamic>)
                .map((json) => TigoEjecutadoModel.fromJson(json))
                .toList();

        final entidades = items.map((model) => model.toEntity()).toList();

        return entidades;
      } else {
        //  console('→ Respuesta vacía o error de status');
        return [];
      }
    } on DioException {
      //console('Error al obtener resumenDetallado Dio: ${e.message}');
      return [];
    } catch (e) {
      //console('Error al obtener resumenDetallado: $e');
      return [];
    }
  }
    //DESCARGAR REPORTE CAMBIOS TIGO
  Future<Uint8List> descargarRptCambiosTigo(String periodoCobrado) async {
    final response = await _dio.post(
      AppConstants.tigoRptCambiosTigo, // Cambia esto por la URL de tu endpoint
      data: {'periodoCobrado': periodoCobrado}, // No envíes parámetros
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el PDF');
    }
  }
  //ACTUALIZAR EMPRESA POR LOTE - TIGO
  @override
Future<bool> actualizarEmpresaLote(TigoEjecutadoEntity tigoEjecutado) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoActualizarEmpresaLote,
      data: tigoEjecutado.toJson(),
    );

    console('Respuesta actualizar lote: ${response.data}');

    if (response.statusCode == 200 && response.data?['ok'] == 'ok') {
      return true;
    } else {
      throw Exception(response.data?['msg'] ?? 'Error desconocido');
    }
  } on DioException catch (e) {
    console('DioException en actualizarEmpresaLote: ${e.message}');
    throw Exception(e.response?.data?['msg'] ?? 'Error de conexión');
  } catch (e) {
    console('Error en actualizarEmpresaLote: $e');
    rethrow;
  }
}
// ═══════════════════════════════════════════════════════════════════════
  // CAMBIOS DE LINEAS CORPORATIVAS TIGO
// ═══════════════════════════════════════════════════════════════════════

  /// Registrar o actualizar un cambio de linea (I o U segun codCambio)
  Future<BigInt> registrarCambioLinea(CambiosTigoEntity entity) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoRegistrarCambioLinea,
        data: CambiosTigoModel.fromEntity(entity).toJson(),
      );

      console('registrarCambioLinea respuesta: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final msg = data?['message'] ?? '';
    
    // Si contiene ADVERTENCIA, lanzar excepción para que el provider la capture
    if (msg.toUpperCase().contains('ADVERTENCIA')) {
      throw Exception(msg);
    }
        if (data != null && data['data'] != null) {
          return BigInt.from(data['data']);
        }
        return BigInt.zero;
      } else {
        throw Exception(
          'Error al registrar cambio de linea: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final res = e.response;
      if (res != null && (res.statusCode == 400 || res.statusCode == 500)) {
        final data = res.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      console('DioException registrarCambioLinea: ${e.message}');
      throw Exception('Error de conexión al registrar cambio de linea.');
    } catch (e) {
      console('Error inesperado registrarCambioLinea: $e');
      rethrow;
    }
  }

  /// Eliminar un cambio pendiente (D)
  Future<BigInt> eliminarCambioLinea(CambiosTigoEntity entity) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoEliminarCambioLinea,
        data: CambiosTigoModel.fromEntity(entity).toJson(),
      );

      console('eliminarCambioLinea respuesta: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BigInt.zero;
      } else {
        throw Exception(
          'Error al eliminar cambio de linea: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final res = e.response;
      if (res != null && (res.statusCode == 400 || res.statusCode == 500)) {
        final data = res.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      console('DioException eliminarCambioLinea: ${e.message}');
      throw Exception('Error de conexión al eliminar cambio de linea.');
    } catch (e) {
      console('Error inesperado eliminarCambioLinea: $e');
      rethrow;
    }
  }

  /// Aplicar todos los cambios pendientes de un periodo (A)
  /// Timeout extendido igual que generarAnticiposTigo
  Future<BigInt> aplicarCambiosLinea(CambiosTigoEntity entity) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoAplicarCambiosLinea,
        data: CambiosTigoModel.fromEntity(entity).toJson(),
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout:    const Duration(seconds: 60),
        ),
      );

      console('aplicarCambiosLinea respuesta: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          return BigInt.from(data['data']); // totalAplicados
        }
        return BigInt.zero;
      } else {
        throw Exception(
          'Error al aplicar cambios: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'El proceso tardó demasiado. Verifique el estado en la lista de cambios.',
        );
      }
      final res = e.response;
      if (res != null && (res.statusCode == 400 || res.statusCode == 500)) {
        final data = res.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      console('DioException aplicarCambiosLinea: ${e.message}');
      throw Exception('Error de conexión al aplicar cambios.');
    } catch (e) {
      console('Error inesperado aplicarCambiosLinea: $e');
      rethrow;
    }
  }

  /// Lista unificada de numeros asignados (empleados + externos)
  /// Filtrable por tipoSocio y search
  Future<List<CambiosTigoEntity>> listarNumerosAsignados(
    CambiosTigoEntity filtro,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoListarNumerosAsignados,
        data: CambiosTigoModel.fromEntity(filtro).toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CambiosTigoModel.fromJson(json))
            .toList();
        return items.map((m) => m.toEntity()).toList();
      }
      return [];
    } on DioException catch (e) {
      console('DioException listarNumerosAsignados: ${e.message}');
      return [];
    } catch (e) {
      console('Error listarNumerosAsignados: $e');
      return [];
    }
  }

  /// Lista de cambios registrados
  /// Filtrable por periodoCobrado, estado, codEmpleado o codCambio
  Future<List<CambiosTigoEntity>> listarCambiosLinea(
    CambiosTigoEntity filtro,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoListarCambiosLinea,
        data: CambiosTigoModel.fromEntity(filtro).toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CambiosTigoModel.fromJson(json))
            .toList();
        return items.map((m) => m.toEntity()).toList();
      }
      return [];
    } on DioException catch (e) {
      console('DioException listarCambiosLinea: ${e.message}');
      return [];
    } catch (e) {
      console('Error listarCambiosLinea: $e');
      return [];
    }
  }

  /// Lista de destinos posibles para el dropdown de reasignacion
  /// Externos + empleados con corporativo + empleados sin corporativo
  /// Filtrable por tipoSocio y search
  Future<List<CambiosTigoEntity>> listarDestinosLinea(
    CambiosTigoEntity filtro,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoListarDestinosLinea,
        data: CambiosTigoModel.fromEntity(filtro).toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CambiosTigoModel.fromJson(json))
            .toList();
        return items.map((m) => m.toEntity()).toList();
      }
      return [];
    } on DioException catch (e) {
      console('DioException listarDestinosLinea: ${e.message}');
      return [];
    } catch (e) {
      console('Error listarDestinosLinea: $e');
      return [];
    }
  }
  //REASIGNAR NUMERO SIN ASIGNAR (EXTERNO O EMPLEADO SIN CORPORATIVO)
  Future<BigInt> reasignarNumeroSinAsignar(CambiosTigoEntity entity) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoReasignarNumeroSinAsignar,
      data: CambiosTigoModel.fromEntity(entity).toJson(),
    );
    final msg = response.data['message'] ?? '';
    if (msg.toUpperCase().contains('ADVERTENCIA')) throw Exception(msg);
    return BigInt.from(response.data['data'] ?? 0);
  } on DioException catch (e) {
    final msg = e.response?.data['message'] ?? e.message;
    throw Exception(msg);
  }
}
// ═══════════════════════════════════════════════════════════════════════
// MÓDULO: TIGO CHIP (CHIPS PERDIDOS / REPOSICIONES)
// ═══════════════════════════════════════════════════════════════════════

// LISTAR PERDIDAS
  @override
  Future<List<ChipTigoEntity>> listarChipsPerdidos(ChipTigoEntity filtro) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoListarPerdidasLinea, // URL: /tigo/listarPerdidas
        data: ChipTigoModel.fromEntity(filtro).toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        return (data as List)
            .map((json) => ChipTigoModel.fromJson(json).toEntity())
            .toList();
      }
      return [];
    } catch (e) {
      console('Error listarChipsPerdidos: $e');
      return [];
    }
  }

  // REGISTRAR O ACTUALIZAR (El Controller decide si es I o U)
 @override
  Future<String> registrarPerdidaChip(ChipTigoEntity entity) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoRegistrarPerdidaLinea,
        data: ChipTigoModel.fromEntity(entity).toJson(),
      );

      // Si todo sale bien (Status 200 o similar)
      final res = ChipTigoResponse.fromJson(response.data);
      return res.message;

    } on DioException catch (e) {
      // Si Java responde con un 400 (Validacion fallida), Dio entra aqui
      if (e.response != null && e.response?.data != null) {
        // Extraemos el JSON del error que mandaste desde el backend
        final resError = ChipTigoResponse.fromJson(e.response!.data);
        throw Exception(resError.message);
      }
      
      // Error de red (servidor caido, timeout, etc.)
      throw Exception('Error de conexion: ${e.message}');
    } catch (e) {
      // Cualquier otro error interno de Dart
      throw Exception('Error inesperado: $e');
    }
  }

  // ELIMINAR
  @override
  Future<bool> eliminarRegistroPerdida(ChipTigoEntity entity) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoEliminarPerdidaLinea, // URL: /tigo/eliminarRegistroPerdida
        data: ChipTigoModel.fromEntity(entity).toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      console('Error eliminarRegistroPerdida: $e');
      return false;
    }
  }
  @override
  Future<List<String>> obtenerPeriodos() async {
    try {
      final response = await _dio.post(
        AppConstants.tigoListarPeriodos, 
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        
        // Convertimos la lista de JSON a modelos y extraemos solo el string 'periodo'
        return data
            .map((json) => ChipTigoModel.fromJson(json).periodo ?? '')
            .where((p) => p.isNotEmpty) // Limpieza por seguridad
            .toList();
      }
      return [];
    } catch (e) {
      console('Error obtenerPeriodos: $e');
      return [];
    }
  }
//OBTENDRA LOS TIPOS RENOVACION DE CHIP TIGO
@override
  Future<List<TipoRenovacionChipTigoEntity>> obtenerTipoRenovacion()async {
    try {
      final response = await _dio.post(AppConstants.tigoObtenerTipoRenovacion);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TipoRenovacionChipModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener Tipo educacion: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener el Tipo educacion: $e');
      return [];
    }
  }
  //RPT : REPORTE PERDIDA LINEA TIGO
@override
Future<Uint8List> descargarRptPerdidaLineas(String periodo) async {
  try {
    // USAMOS TU MÉTODO CENTRALIZADO QUE YA TIENE LAS OPTIONS CORRECTAS
    return await DioClient.descargarReportePdf(
      endpoint: AppConstants.tigoRptPerdidaLineas,
      data: {'periodo': periodo},
    );
  } catch (e) {
    console('Error descargarRptPerdidaLineas: $e');
    throw Exception('No se pudo generar el reporte: $e');
  }
}
//OBTENER LISTA DE PERIODOS PARA FILTRAR EN CAMBIOS TIGO
  @override
  Future<List<String>> obtenerPeriodosCambio() async {
    try {
      final response = await _dio.post(
        AppConstants.tigoListarPeriodosCambio, 
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        
        // Convertimos la lista de JSON a modelos y extraemos solo el string 'periodo'
        return data
            .map((json) => CambiosTigoModel.fromJson(json).periodoCobrado)
            .where((p) => p.isNotEmpty) // Limpieza por seguridad
            .toList();
      }
      return [];
    } catch (e) {
      console('Error obtenerPeriodos: $e');
      return [];
    }
  }
    //RPT : REPORTE CAMBIOS LINEA TIGO
@override
Future<Uint8List> descargarRptCambiosLineaTigo(String periodoCobrado) async {
  try {
    // USAMOS TU MÉTODO CENTRALIZADO QUE YA TIENE LAS OPTIONS CORRECTAS
    return await DioClient.descargarReportePdf(
      endpoint: AppConstants.tigoRptCambiosLineaTigo,
      data: {'periodoCobrado': periodoCobrado},
    );
  } catch (e) {
    console('Error descargarRptPerdidaLineas: $e');
    throw Exception('No se pudo generar el reporte: $e');
  }
}
/// Ejecutar periodo Tigo completo — ACCION='E'
  /// Inserta en tTigo_ejecutado Y en [BOSQUE].dbo.Anticipo_2
  /// en una sola transacción con validaciones SQL.
  ///
  /// Lanza [Exception] con el mensaje del SP si @error > 0.
  /// Devuelve [TigoEjecutadoResponse] con mensaje y total de registros.
  Future<TigoEjecutadoResponse> ejecutarPeriodoTigo(
    TigoEjecutadoEntity entity,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.tigoEjecutarPeriodoTigo,     // '/tigo/ejecutarPeriodoTigo'
        data: TigoEjecutadoModel.fromEntity(entity).toJson(),
        options: Options(
          // El SP puede tardar varios minutos al insertar en ambas BDs
          receiveTimeout: const Duration(seconds: 180),
          sendTimeout:    const Duration(seconds:  60),
        ),
      );
      return TigoEjecutadoResponse.fromJson(response.data as Map<String, dynamic>);
 
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'El proceso tardó demasiado. Verifique el estado del periodo en la base de datos.',
        );
      }
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        // HTTP 400 → error de negocio del SP (@error > 0)
        throw Exception(data['message']);
      }
      throw Exception('Error de conexión al ejecutar el periodo.');
 
    } catch (e) {
      console('Error ejecutarPeriodoTigo: $e');
      rethrow;
    }
  }
  //RPT : LINEAS TIGO PERSONAL
  @override
Future<Uint8List> descargarRptCorporativosPersonal(String periodoCobrado) async {
  try {
    // USAMOS TU MÉTODO CENTRALIZADO QUE YA TIENE LAS OPTIONS CORRECTAS
    return await DioClient.descargarReportePdf(
      endpoint: AppConstants.tigoRptCorporativosPersonal,
      data: {'periodoCobrado': periodoCobrado},
    );
  } catch (e) {
    console('Error descargarRptCorporativosPersonal: $e');
    throw Exception('No se pudo generar el reporte: $e');
  }
}
//RPT : COMPARACION EMPRESAS
@override
Future<Uint8List> descargarRptComparacionEmpresas() async {
  try {
    // USAMOS TU MÉTODO CENTRALIZADO QUE YA TIENE LAS OPTIONS CORRECTAS
    return await DioClient.descargarReportePdf(
      endpoint: AppConstants.tigoRptComparacionEmpresas
    );
  } catch (e) {
    console('Error descargarRptComparacionEmpresas: $e');
    throw Exception('No se pudo generar el reporte: $e');
  }
}

}

