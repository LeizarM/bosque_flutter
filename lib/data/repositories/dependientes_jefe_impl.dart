// Destino final: lib/data/repositories/dependientes_jefe_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/dependiente_cargo_model.dart';
import 'package:bosque_flutter/domain/entities/resultado_dependientes_entity.dart';
import 'package:dio/dio.dart';

class DependientesJefeImpl extends BaseApiRepository {
  /// [profundidad]: "T" todo el subárbol | "D" solo directos.
  /// [alcanceSucursal]: "A" todas las sucursales | "M" solo la del jefe.
  ///
  /// El backend devuelve 403 (no 400) cuando el cargo vigente no califica
  /// como jefe/gerente — no es un error de red, es una respuesta legítima
  /// que hay que mostrar con su propio mensaje, así que se maneja acá en
  /// vez de con los helpers genéricos de BaseApiRepository (pensados para
  /// 200/201/204/400).
  Future<ResultadoDependientesEntity> listarDependientes({
    String profundidad = 'T',
    String alcanceSucursal = 'A',
  }) async {
    try {
      final response = await dio.post(
        AppConstants.tarListarDependientesJefe,
        data: {'profundidad': profundidad, 'alcanceSucursal': alcanceSucursal},
      );
      final status = response.statusCode ?? 0;
      if (status == 204 || response.data == null) {
        return const ResultadoDependientesEntity(
          autorizado: true,
          mensaje: '',
          dependientes: [],
        );
      }
      final raw = response.data;
      final List<dynamic> rawData = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : [];
      final dependientes = rawData
          .map((json) => DependienteCargoModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
      return ResultadoDependientesEntity(
        autorizado: true,
        mensaje: raw is Map ? (raw['message'] ?? '') : '',
        dependientes: dependientes,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 && e.response?.data is Map) {
        return ResultadoDependientesEntity(
          autorizado: false,
          mensaje: e.response!.data['message'] ?? 'No tienes un cargo habilitado para esto.',
          dependientes: const [],
        );
      }
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(e.response!.data['message'] ?? 'Error al obtener los dependientes.');
      }
      throw Exception(DioClient.handleDioError(e, 'Error al obtener los dependientes.'));
    }
  }

  /// Crea una tarea rutinaria y la asigna a los cargos elegidos, en una sola
  /// transacción. codUsuario/modoJefe los resuelve el backend desde el JWT —
  /// no hace falta (ni sirve) mandarlos desde acá.
  ///
  /// [cargos] es la lista de asignaciones — cada mapa con las claves
  /// codCargo (obligatorio), codCargoSucursal/fechaInicio/fechaFin
  /// (opcionales, null = "todas las sucursales"/"hoy"/"permanente").
  Future<BigInt> registrarTareaConCargos({
    required String descripcion,
    required int idFrec,
    int? idArea,
    required DateTime fechaPartida,
    int? idATR,
    required List<Map<String, dynamic>> cargos,
  }) {
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarTareaConCargos,
      data: {
        'descripcion': descripcion,
        'idFrec': idFrec,
        'idArea': idArea,
        'fechaPartida': fechaPartida.toIso8601String(),
        'idATR': idATR,
        'cargos': cargos,
      },
      errorMessage: 'No se pudo registrar la tarea rutinaria.',
    );
  }
}
