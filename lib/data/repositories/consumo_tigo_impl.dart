
import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/factura_tigo_model.dart';
import 'package:bosque_flutter/data/models/socios_tigo_model.dart';
import 'package:bosque_flutter/data/models/tigo_ejecutado_model.dart';
import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:bosque_flutter/domain/repositories/Consumo_tigo_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ConsumoTigoImpl implements ConsumoTigoRepository {
  final Dio _dio = DioClient.getInstance();
//subir excel factura tigo
@override
Future<Map<String, dynamic>> subirExcel(Uint8List fileBytes, String fileName, int audUsuario) async {
  try {
    print('Subiendo archivo Excel: $fileName, usuario: $audUsuario');

    final formData = FormData.fromMap({
      'audUsuario': audUsuario,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final response = await _dio.post(
      AppConstants.tigoCargarFacturas,
      data: formData,
    );

    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception(
        'Error al subir archivo: ${response.statusCode} - ${response.data}',
      );
    }
  } on DioException catch (e) {
    print('DioException: ${e.response?.data}');
    throw Exception('Error de conexión: ${e.message}');
  } catch (e) {
    print('Error inesperado: $e');
    throw Exception('Error inesperado: $e');
  }
}
//ver excel factura tigo
@override
  Future<List<FacturaTigoEntity>> obtenerFacturaTigo()async {
    try{
      final response = await _dio.post(
  AppConstants.tigoVerFactura,
  data: {}, // Envía un JSON vacío
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => FacturaTigoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener facturaTigo Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener facturaTigo: $e');
      return [];
    }
   
  }
  //subir excel socios tigo
  @override
Future<Map<String, dynamic>> subirExcelSocios(Uint8List fileBytes, String fileName, int audUsuario) async {
  try {
    print('Subiendo archivo Excel de socios: $fileName, usuario: $audUsuario');

    final formData = FormData.fromMap({
      'audUsuario': audUsuario,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final response = await _dio.post(
      AppConstants.tigoCargarSocios,
      data: formData,
    );

    print('Respuesta del servidor (socios): ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception(
        'Error al subir archivo de socios: ${response.statusCode} - ${response.data}',
      );
    }
  } on DioException catch (e) {
    print('DioException: ${e.response?.data}');
    throw Exception('Error de conexión: ${e.message}');
  } catch (e) {
    print('Error inesperado: $e');
    throw Exception('Error inesperado: $e');
  }
}
//OBTENER TOTAL COBRADO X CUENTA 
@override
  Future<List<TigoEjecutadoEntity>> obtenerTotalXcuenta(String periodoCobrado)async {
    try{
      final response = await _dio.post(
  AppConstants.tigoTotalXCuenta,
  data: {
'periodoCobrado': periodoCobrado
  }, // Envía un JSON vacío
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TigoEjecutadoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener tigoTotalCobradoXCuenta Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener tigoTotalXCuenta: $e');
      return [];
    }
   
  }

//obtener socios tigo
@override
  Future<List<SocioTigoEntity>> obtenerSociosTigo()async {
    try{
      final response = await _dio.post(
  AppConstants.tigoVerSocios,
  data: {}, // Envía un JSON vacío
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => SociosTigoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener asociadosTigo Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener sociosTigo: $e');
      return [];
    }
   
  }
// registrar socios tigo
@override
  Future<List<SocioTigoEntity>> registrarSocio(SocioTigoEntity socio)async {
    try {

      final response = await _dio.post(
        AppConstants.tigoCargarSocios,
        data: socio.toJson(),
       
      );

      // Log para depuración
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después de registrar exitosamente, obtener la lista actualizada
        return await obtenerSociosTigo();
      } else {
        throw Exception(
          'Error al registrar socio: ${response.statusCode} - ${response.data}',
        );
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}');
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      print('Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }
  //OBTENER RESUMEN CUENTAS TIGO
@override
  Future<List<TigoEjecutadoEntity>> obtenerResumenCuentas(String periodoCobrado)async {
    try{
      final response = await _dio.post(
  AppConstants.tigoResumenCuentas,
  data: {'periodoCobrado': periodoCobrado},
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TigoEjecutadoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener resumenxcuenta Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener tigoresumencuenta: $e');
      return [];
    }
   
  }
  //OBTENER RESUMEN DETALLADO TIGO
  @override
Future<List<TigoEjecutadoEntity>> obtenerResumenDetallado(String periodoCobrado) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoResumenDetallado,
      data: {
        "periodoCobrado": periodoCobrado
      },
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data ?? [];
      final items = (data as List<dynamic>)
          .map((json) => TigoEjecutadoModel.fromJson(json))
          .toList();
      return items.map((model) => model.toEntity()).toList();
    } else {
      return [];
    }
  } on DioException catch (e) {
    print('Error al obtener resumenDetallado Dio: ${e.message}');
    return [];
  } catch (e) {
    print('Error al obtener resumenDetallado: $e');
    return [];
  }
}
  //INSERTAR ANTICIPO TIGO tigoInsertarAnticipo
@override
Future<bool> generarAnticiposTigo(String periodoCobrado) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoInsertarAnticipo, // URL del endpoint backend
      data: {'periodoCobrado': periodoCobrado},
    );

    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Error al generar anticipos: ${response.statusCode} - ${response.data}',
      );
    }
  } on DioException catch (e) {
    print('DioException: ${e.response?.data}');
    throw Exception('Error de conexión: ${e.message}');
  } catch (e) {
    print('Error inesperado: $e');
    throw Exception('Error inesperado: $e');
  }
}
//DESCARGAR REPORTE TIGO 
Future<Uint8List> descargarReporteFacturasTigo(String periodoCobrado) async {
  final response = await _dio.post(
    AppConstants.tigoExportarPdf, // Cambia esto por la URL de tu endpoint
    data: {'periodoCobrado': periodoCobrado }, // No envíes parámetros
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al descargar el PDF: $e')),
    );
  }
}
//obtener lista grupos tigo
//obtener socios tigo
@override
  Future<List<SocioTigoEntity>> obtenerGruposTigo(String periodoCobrado)async {
    try{
      final response = await _dio.post(
  AppConstants.tigoObtenerGrupos,
  data: {
    'periodoCobrado': periodoCobrado
  }, // Envía un JSON vacío
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => SociosTigoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener asociadosTigo Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener sociosTigo: $e');
      return [];
    }
   
  }
  //ELIMINAR GRUPO
  @override
  Future<bool> eliminarGrupo(int codCuenta)async {
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
Future<bool> insertarTigoEjectuado(String periodoCobrado,int audUsuario) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoEjecutarTigo, 
      data: {'periodoCobrado': periodoCobrado,
      'audUsuario': audUsuario
      },
    );

    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
  return true;
} else {
  throw Exception(
    'Error al generar anticipos: ${response.statusCode} - ${response.data}',
  );
}
  } on DioException catch (e) {
    print('DioException: ${e.response?.data}');
    throw Exception('Error de conexión: ${e.message}');
  } catch (e) {
    print('Error inesperado: $e');
    throw Exception('Error inesperado: $e');
  }
}
//obtener tigo ejecutado
@override
  Future<List<TigoEjecutadoEntity>> obtenerTigoEjecutado(String? empresa,String periodoCobrado)async {
    try{
      final response = await _dio.post(
  AppConstants.tigoObtenerEjecutado,
  data: {
    'empresa': empresa,
'periodoCobrado': periodoCobrado
  },
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TigoEjecutadoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener tigoEjecutado Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener obTigoEjecutado: $e');
      return [];
    }
   
  }
  //OBTENER NUMERO SIN ASIGNAR TIGO
  @override
  Future<List<SocioTigoEntity>> obtenerNroSinAsignar(String periodoCobrado)async {
    try{
      final response = await _dio.post(
  AppConstants.tigoObtenerNrosSinAsignar,
  data: {
'periodoCobrado': periodoCobrado
  },
);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => SociosTigoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener obtenerNroSinAsignar Dio: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener obtenerNroSinAsignar: $e');
      return [];
    }
   
  }
  //obtener arbol detallado
  @override
   Future<List<TigoEjecutadoEntity>> obtenerArbolDetallado(String? empresa, String periodoCobrado) async {
  try {
    final response = await _dio.post(
      AppConstants.tigoObtenerArbolDetallado,
      data: {
        "empresa": empresa,
        "periodoCobrado": periodoCobrado
      },
    );
    //print('→ Respuesta cruda del backend: ${response.data}'); // Imprime el JSON recibido

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data ?? [];
     // print('→ Data parseada como lista: $data'); // Imprime la lista parseada

      final items = (data as List<dynamic>)
          .map((json) => TigoEjecutadoModel.fromJson(json))
          .toList();

      //print('→ Total items mapeados: ${items.length}');
      for (final item in items) {
       // print('→ Item: ${item.toJson()}');
      }

      final entidades = items.map((model) => model.toEntity()).toList();
     // print('→ Total entidades convertidas: ${entidades.length}');
      for (final entidad in entidades) {
        //print('→ Entidad: ${entidad.nombreCompleto} | Empresa: ${entidad.empresa} | Hijos: ${entidad.items.length}');
      }

      return entidades;
    } else {
    //  print('→ Respuesta vacía o error de status');
      return [];
    }
  } on DioException catch (e) {
    //print('Error al obtener resumenDetallado Dio: ${e.message}');
    return [];
  } catch (e) {
    //print('Error al obtener resumenDetallado: $e');
    return [];
  }
}
}