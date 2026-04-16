import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/models/Persona_model.dart';
import 'package:bosque_flutter/data/models/afiliacion_seguro_model.dart';
import 'package:bosque_flutter/data/models/banco_model.dart';
import 'package:bosque_flutter/data/models/cargo_sucursal_model.dart';
import 'package:bosque_flutter/data/models/educacion_model.dart';
import 'package:bosque_flutter/data/models/empleado_model.dart';
import 'package:bosque_flutter/data/models/licencia_conducir_model.dart';
import 'package:bosque_flutter/data/models/nro_cuenta_bancaria_model.dart';
import 'package:bosque_flutter/data/models/relacion_laboral_model.dart';
import 'package:bosque_flutter/data/models/seguro_model.dart';
import 'package:bosque_flutter/data/models/telefono_model.dart';
import 'package:bosque_flutter/data/models/tipo_educacion_model.dart';
import 'package:bosque_flutter/data/models/tipo_licencia_model.dart';
import 'package:bosque_flutter/data/models/tipo_relacion_laboral_model.dart';
import 'package:bosque_flutter/data/models/tipo_seguro_model.dart';
import 'package:bosque_flutter/domain/entities/afiliacion_seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';
import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_seguro_entity.dart';
import 'package:bosque_flutter/domain/repositories/registro_empleado_repository.dart';
import 'package:dio/dio.dart';

class RegistroEmpleadoImpl implements RegistroEmpleadoRepository {
  final Dio _dio = DioClient.getInstance();
  //OBTENDRA LA LISTA DE EMPLEADOS SEGUN FILTROS
  @override
  Future<List<EmpleadoEntity>> getLstEmpleados(
    String? search,
    int? esActivo,
    int pageNumber,
    int pageSize,
    int? codEmpresa,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerLstEmpleados,
        data: {
          'search': search,
          'esActivo': esActivo,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          'codEmpresa': codEmpresa,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => EmpleadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } catch (e) {
      console('Error en getLstEmpleados: $e');
      return [];
    }
  }

  //REGISTRARA UN NUEVO EMPLEADO
  @override
  Future<EmpleadoEntity> registrarEmpleado(EmpleadoEntity empleado) async {
    try {
      console('========== REGISTRAR EMPLEADO ==========');
      console('📤 Enviando empleado: ${empleado.toJson()}');

      final response = await _dio.post(
        AppConstants.rrhhRegistroEmpleado,
        data: empleado.toJson(),
      );

      console('📥 Respuesta del servidor (código: ${response.statusCode})');
      console('📥 Datos: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null &&
          response.data['ok'] == 'ok') {
        console('✅ [PASO 1] Empleado registrado en BD correctamente');
        console('⏳ [PASO 2] Esperando 500ms para asegurar insert...');

        // Pausa importante para que el insert termine
        await Future.delayed(Duration(milliseconds: 500));

        console('🔍 [PASO 3] Obteniendo último codEmpleado registrado...');

        try {
          final response2 = await _dio.post(
            AppConstants.rrhhObtenerUltimoCodEmpleado,
            data: {'codPersona': empleado.codPersona},
          );

          console('📥 Respuesta de ultimoCodEmpleado:');
          console('   - statusCode: ${response2.statusCode}');
          console('   - data: ${response2.data}');
          console('   - tipo: ${response2.data.runtimeType}');

          if (response2.statusCode == 200 && response2.data != null) {
            int codEmpleado = 0;

            // INTENTO 1: Si es un mapa
            if (response2.data is Map) {
              final dataMap = response2.data as Map<String, dynamic>;
              console('   - Claves del mapa: ${dataMap.keys.toList()}');

              if (dataMap.containsKey('codEmpleado')) {
                codEmpleado = dataMap['codEmpleado'] as int? ?? 0;
                console('   ✅ Encontrado como "codEmpleado": $codEmpleado');
              } else if (dataMap.containsKey('id')) {
                codEmpleado = dataMap['id'] as int? ?? 0;
                console('   ✅ Encontrado como "id": $codEmpleado');
              } else if (dataMap.containsKey('empleadoId')) {
                codEmpleado = dataMap['empleadoId'] as int? ?? 0;
                console('   ✅ Encontrado como "empleadoId": $codEmpleado');
              } else {
                // Buscar el primer valor numérico
                for (final entry in dataMap.entries) {
                  if (entry.value is int && entry.value > 0) {
                    codEmpleado = entry.value as int;
                    console(
                      '   ✅ Encontrado como "${entry.key}": $codEmpleado',
                    );
                    break;
                  }
                }
              }
            }
            // INTENTO 2: Si es un número directo
            else if (response2.data is int) {
              codEmpleado = response2.data as int;
              console('   ✅ Es un número directo: $codEmpleado');
            }

            if (codEmpleado > 0) {
              console('🎉 [PASO 4] ÉXITO - codEmpleado obtenido: $codEmpleado');

              return EmpleadoEntity(
                fila: empleado.fila,
                codPersona: empleado.codPersona,
                codZona: empleado.codZona,
                nombres: empleado.nombres,
                apPaterno: empleado.apPaterno,
                apMaterno: empleado.apMaterno,
                ciExpedido: empleado.ciExpedido,
                ciFechaVencimiento: empleado.ciFechaVencimiento,
                ciNumero: empleado.ciNumero,
                direccion: empleado.direccion,
                estadoCivil: empleado.estadoCivil,
                fechaNacimiento: empleado.fechaNacimiento,
                lugarNacimiento: empleado.lugarNacimiento,
                nacionalidad: empleado.nacionalidad,
                sexo: empleado.sexo,
                lat: empleado.lat,
                lng: empleado.lng,
                audUsuarioI: empleado.audUsuarioI,
                datoPersona: empleado.datoPersona,
                codEmpleado: codEmpleado,
                numCuenta: empleado.numCuenta,
                codRelBeneficios: empleado.codRelBeneficios,
                codRelPlanilla: empleado.codRelPlanilla,
                codDependiente: empleado.codDependiente,
                esActivoString: empleado.esActivoString,
                persona: empleado.persona,
                empleadoCargo: empleado.empleadoCargo,
                dependiente: empleado.dependiente,
                empresa: empleado.empresa,
                sucursal: empleado.sucursal,
                relEmpEmpr: empleado.relEmpEmpr,
              );
            } else {
              console('❌ codEmpleado NO es válido (valor: $codEmpleado)');
            }
          } else {
            console(
              '❌ Respuesta inválida - statusCode: ${response2.statusCode}',
            );
          }
        } catch (e) {
          console('❌ Exception en ultimoCodEmpleado: $e');
          console('   StackTrace: ${StackTrace.current}');
        }

        // FALLBACK: Si endpoint falla, usar la lista
        console(
          '⏳ [FALLBACK] Buscando en lista de empleados por codPersona...',
        );
        try {
          final respLst = await _dio.post(
            AppConstants.rrhhObtenerLstEmpleados,
            data: {
              'search': '${empleado.codPersona}',
              'esActivo': null,
              'pageNumber': 1,
              'pageSize': 50,
            },
          );

          // console('📥 Respuesta de lista: statusCode=${respLst.statusCode}, items=${respLst.data.length if respLst.data is List else 0}');

          if (respLst.statusCode == 200 && respLst.data is List) {
            final items =
                (respLst.data as List<dynamic>)
                    .map((json) => EmpleadoModel.fromJson(json))
                    .toList();

            console('📋 Encontrados ${items.length} empleados en búsqueda');

            for (final emp in items) {
              console(
                '   - codPersona=${emp.codPersona}, codEmpleado=${emp.codEmpleado}',
              );
              if (emp.codPersona == empleado.codPersona &&
                  emp.codEmpleado > 0) {
                console(
                  '✅ [FALLBACK-OK] Empleado encontrado: codEmpleado=${emp.codEmpleado}',
                );
                return emp.toEntity();
              }
            }

            console(
              '❌ No se encontró empleado en lista con codPersona=${empleado.codPersona}',
            );
          }
        } catch (e) {
          console('❌ Error en fallback: $e');
        }

        console('❌ FALLO FINAL: No se pudo obtener codEmpleado');
        throw Exception(
          'El empleado se registró pero no se pudo obtener su código',
        );
      } else {
        console('❌ Error en registro: statusCode=${response.statusCode}');
        console('   Mensaje: ${response.data?['msg'] ?? 'desconocido'}');
        throw Exception(
          '${response.data?['msg'] ?? 'Error desconocido en registro'}',
        );
      }
    } on DioException catch (e) {
      console('❌ DioException: ${e.message}');

      String errorServidor = "Error de conexión";

      // Si el servidor respondió (ej: el 400 Bad Request que pusimos en Java)
      if (e.response != null && e.response?.data != null) {
        console('   Response Data: ${e.response?.data}');
        // Extraemos el mensaje que mandamos en el Map de Java
        errorServidor =
            e.response?.data['msg'] ?? "Error desconocido en el servidor";
      }

      throw Exception(
        errorServidor,
      ); // Lanzamos el mensaje limpio: "El sueldo es menor al..."
    } catch (e) {
      console('❌ Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  //OBTENDRA UNA LISTA DE PERSONAS QUE NO SON EMPLEADOS
  @override
  Future<List<PersonaEntity>> getLstPersonas(String buscarPersona) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerLstPersonas,
        data: {'buscarPersona': buscarPersona},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => PersonaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } catch (e) {
      console('Error en getLstPersonas: $e');
      return [];
    }
  }

  //OBTENDRA LOS DATOS DE UNA PERSONA SEGUN SU CODPERSONA
  @override
  Future<PersonaEntity> obtenerPersona(int codPersona) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerDatoPersona,
        data: {'codPersona': codPersona},
      );

      if (response.statusCode == 200 && response.data != null) {
        final personaModel = PersonaModel.fromJson(response.data);
        return personaModel.toEntity();
      } else {
        throw Exception('Error al obtener persona: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener persona: $e');
    }
  }

  //OBTENDRA LOS TELEFONOS DE UNA PERSONA SEGUN SU CODPERSONA
  @override
  Future<List<TelefonoEntity>> obtenerTelefono(int codPersona) async {
    try {
      final response = await _dio.post(
        AppConstants.perLstTelefono,
        data: {'codPersona': codPersona},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TelefonoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener Teléfonos: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener Teléfonos: $e');
      return [];
    }
  }

  //OBTENDRA UNA LISTA DE EDUCACION SEGUN EL CODIGO DE EMPLEADO
  @override
  Future<List<EducacionEntity>> obtenerEducacion(int codEmpleado) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerEducacion,
        data: {'codEmpleado': codEmpleado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => EducacionModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener educacion: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener la educacion: $e');
      return [];
    }
  }

  //REGISTRARA UNA NUEVA EDUCACION PARA UN EMPLEADO
  @override
  Future<EducacionEntity> registrarEducacion(EducacionEntity educacion) async {
    try {
      console('Enviando empleado: ${educacion.toJson()}');

      final response = await _dio.post(
        AppConstants.rrhhRegistroEducacion,
        data: educacion.toJson(),
      );

      console('Respuesta del servidor: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        // El backend solo confirma éxito, no retorna el empleado completo
        // Por eso retornamos la misma entidad que enviamos
        if (response.data['ok'] == 'ok') {
          return educacion; // Retornar el empleado que ya tenemos
        } else {
          throw Exception('${response.data['msg'] ?? 'Error desconocido'}');
        }
      } else {
        throw Exception(
          'Error al registrar educacion: ${response.statusCode} - ${response.data}',
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

  //ELIMINARA UNA EDUCACION SEGUN SU CODIGO
  @override
  Future<bool> eliminarEducacion(int codEducacion) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.baseUrl}${AppConstants.rrhhEliminarEducacion}/$codEducacion',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //OBTENDRA LOS TIPOS DE EDUCACION
  @override
  Future<List<TipoEducacionEntity>> obtenerTipoEducacion() async {
    try {
      final response = await _dio.post(AppConstants.rrhhObtenerTipoEducacion);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TipoEducacionModel.fromJson(json))
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

  //OBTENER LISTA DE CARGOS POR SUCURSAL
  @override
  Future<List<CargoSucursalEntity>> obtenerCargoXsucursal(
    int codSucursal,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerCargoXSucursal,
        data: {'codSucursal': codSucursal},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => CargoSucursalModel.fromJson(json))
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

  // REGISTRAR RELACION LABORAL
  // REGISTRAR RELACION LABORAL
  @override
  Future<RelacionLaboralEntity> registrarRelacionLaboral(
    RelacionLaboralEntity relLab, {
    bool validar = false,
    bool esHistorico = false,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhRegistrarRelacionLaboral,
        data: {
          ...relLab.toJson(),
          'validar': validar,
          'esHistorico': esHistorico,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data['ok'] == 'ok') {
          return relLab;
        } else {
          throw Exception(response.data['msg'] ?? 'Error desconocido');
        }
      }
      throw Exception('Error del servidor');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['msg'] ?? 'Error de conexión');
    }
  }

  //OBTENER LISTA DE BANCOS
  @override
  Future<List<BancoEntity>> getBancos() async {
    try {
      final response = await _dio.post(AppConstants.bncGetBancos);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => BancoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener lista de bancos: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener los bancos: $e');
      return [];
    }
  }
  //REGISTRAR NUEVO BANCO (PENDIENTE)

  //OBTENER NROCUENTABANCARIA X EMPLEADO
  @override
  Future<List<NroCuentaBancariaEntity>> getCuentaBancoXEmpleado(
    int codEmpleado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhGetCuentaBancoXEmpleado,
        data: {'codEmpleado': codEmpleado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => NroCuentaBancariaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener nro de cuenta bancaria: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener el nro de cuenta: $e');
      return [];
    }
  }

  //REGISTRAR NRO DE CUENTA BANCARIA
  @override
  Future<NroCuentaBancariaEntity> registrarCuentaBancaria(
    NroCuentaBancariaEntity cuenta,
  ) async {
    try {
      console('Enviando cuenta bancaria: ${cuenta.toJson()}');

      final response = await _dio.post(
        AppConstants.rrhhRegistrarCuentaBancaria,
        data: cuenta.toJson(),
      );

      console('Respuesta del servidor: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        // El backend solo confirma éxito, no retorna el empleado completo
        // Por eso retornamos la misma entidad que enviamos
        if (response.data['ok'] == 'ok') {
          return cuenta; // Retornar el empleado que ya tenemos
        } else {
          throw Exception('${response.data['msg'] ?? 'Error desconocido'}');
        }
      } else {
        throw Exception(
          'Error al registrar empleado: ${response.statusCode} - ${response.data}',
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

  //ELIMINAR CUENTA BANCARIA
  @override
  Future<bool> eliminarCuentaBancaria(int codCuenta) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.baseUrl}${AppConstants.rrhhEliminarCuentaBancaria}/$codCuenta',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //OBTENDRA LOS TIPOS DE RELACION LABORAL
  @override
  Future<List<TipoRelacionLaboralEntity>> getTipoRelacionLaboral() async {
    try {
      final response = await _dio.post(AppConstants.rrhhTipoRealacionLaboral);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TipoRelacionLaboralModel.fromJson(json))
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

  //RPT nomina de empleados
  Future<Uint8List> rptNominaEmpleados() async {
    return DioClient.descargarReportePdf(
      endpoint: AppConstants.pdfRptNominaEmpleados,
    );
  }

  //REGISTRARA UN NUEVO EMPLEADO
  @override
  Future<EmpleadoCargoEntity> registroEmpleadoCargo(
    EmpleadoCargoEntity empleadoCargo,
  ) async {
    try {
      console('Enviando empleado: ${empleadoCargo.toJson()}');

      final response = await _dio.post(
        AppConstants.rrhhRegistrarEmpleadoCargo,
        data: empleadoCargo.toJson(),
      );

      console('Respuesta del servidor: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        final msg = response.data['msg']?.toString().toLowerCase() ?? '';
        final ok = response.data['ok']?.toString().toLowerCase() ?? '';

        if (ok == 'ok' ||
            msg.contains('exitosa') ||
            msg.contains('actualizados')) {
          return empleadoCargo;
        } else {
          throw Exception(response.data['msg'] ?? 'Error desconocido');
        }
      } else {
        throw Exception(response.data?['msg'] ?? 'Error al registrar empleado');
      }
    } on DioException catch (e) {
      // Error de red o respuesta de error del servidor (400, 500, etc.)
      final errorMsg =
          e.response?.data?['msg'] ?? e.message ?? 'Error de conexión';
      console('DioException en Repositorio: ${e.response?.data}');
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      // Error de código (Null pointers, errores de casteo, etc.)
      console('ERROR INESPERADO: $e');
      console('STACKTRACE: $stackTrace');

      // Al usuario le damos un mensaje amigable
      throw Exception('Ocurrió un error inesperado al procesar los datos');
    }
  }

  //ELIMINAR RELACION LABORAL
  @override
  Future<bool> eliminarRelacionLaboral(int codRelEmplEmpr) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.baseUrl}${AppConstants.rrhhEliminarRelacionLaboral}/$codRelEmplEmpr',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //obtener detalle empleado
  @override
  Future<EmpleadoEntity> obtenerDetalleEmpleado(int codEmpleado) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhDetalleEmpleado,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final empleadoModel = EmpleadoModel.fromJson(response.data);
        return empleadoModel.toEntity();
      } else {
        throw Exception(
          'Error al obtener detalle empleado: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener detalle del empleado: $e');
    }
  }

  //obtener  cargo actual del empleado
  @override
  Future<EmpleadoEntity> obtenerCargoActual(int codEmpleado) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerCargoActual,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final empleadoModel = EmpleadoModel.fromJson(response.data);
        return empleadoModel.toEntity();
      } else {
        throw Exception(
          'Error al obtener cargo actual del empleado: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener cargo del empleado: $e');
    }
  }

  //obtener historial de cargos del empleado
  @override
  Future<List<EmpleadoEntity>> obtenerHistorialCargosEmpleado(
    int codEmpleado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerHistorialCargosEmpleado,
        data: {'codEmpleado': codEmpleado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => EmpleadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener cargos del empleado: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener el historial de cargos del empleado: $e');
      return [];
    }
  }

  //obtener historial de relaciones laborales del empleado
  @override
  Future<List<RelacionLaboralEntity>> obtenerHistorialRelLabEmpleado(
    int codEmpleado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.rrhhObtenerHistorialRelacionLaboral,
        data: {'codEmpleado': codEmpleado},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => RelacionLaboralModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console(
        'Error al obtener relaciones laborales del empleado: ${e.message}',
      );
      return [];
    } catch (e) {
      console(
        'Error al obtener el historial de relaciones laborales del empleado: $e',
      );
      return [];
    }
  }

  //eliminar empleado cargo
  @override
  Future<bool> eliminarEmpleadoCargo(
    int codEmpleado,
    int codCargoSucursal,
    DateTime fechaIni,
    int codCargoSucPlanilla,
  ) async {
    try {
      String fechaLimpia = fechaIni.toIso8601String().split('T')[0];

      // console de parámetros
      console('========== ELIMINAR EMPLEADO CARGO ==========');
      console('📤 codEmpleado: $codEmpleado');
      console('📤 codCargoSucursal: $codCargoSucursal');
      console('📤 fechaIni: $fechaLimpia');
      console('📤 codCargoSucPlanilla: $codCargoSucPlanilla');
      console(
        '📤 URL: ${AppConstants.baseUrl}${AppConstants.rrhhEliminarEmpleadoCargo}/$codEmpleado/$codCargoSucursal/$fechaLimpia/$codCargoSucPlanilla',
      );
      console('==========================================');

      final response = await _dio.delete(
        '${AppConstants.baseUrl}${AppConstants.rrhhEliminarEmpleadoCargo}/$codEmpleado/$codCargoSucursal/$fechaLimpia/$codCargoSucPlanilla',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // OBTENER ÚLTIMA RELACIÓN LABORAL REGISTRADA
  @override
  Future<RelacionLaboralEntity> obtenerUltimaRelacionLaboral(
    int codEmpleado,
  ) async {
    try {
      console(
        '🔍 Obteniendo última relación laboral para codEmpleado: $codEmpleado',
      );

      final response = await _dio.post(
        AppConstants.rrhhObtenerUltimaRelacionLaboral,
        data: {'codEmpleado': codEmpleado},
      );

      console('📥 Respuesta: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final relModel = RelacionLaboralModel.fromJson(response.data);
        final relEntity = relModel.toEntity();

        if (relEntity.codRelEmplEmpr > 0) {
          console(
            '✅ Relación obtenida: codRelEmplEmpr=${relEntity.codRelEmplEmpr}',
          );
          return relEntity;
        } else {
          throw Exception('No se encontró relación laboral registrada');
        }
      } else {
        throw Exception(
          'Error al obtener relación laboral: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      console('❌ DioException: ${e.message}');
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      console('❌ Error: $e');
      throw Exception('Error al obtener relación laboral: $e');
    }
  }

  // OBTENER LICENCIAS DE CONDUCIR SEGUN CODPERSONA (LicenciaConducirEntity)
  @override
  Future<List<LicenciaConducirEntity>> obtenerLicenciasConducir(
    int codPersona,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.licenciasConducir,
        data: {'codPersona': codPersona},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => LicenciaConducirModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener licencias de conducir: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener las licencias de conducir: $e');
      return [];
    }
  }

  // REGISTRAR LICENCIA DE CONDUCIR
  @override
  Future<LicenciaConducirEntity> registrarLicenciaConducir(
    LicenciaConducirEntity licencia,
  ) async {
    final model = LicenciaConducirModel.fromEntity(licencia);
    try {
      console('Enviando licencia de conducir: $licencia');

      final response = await _dio.post(
        AppConstants.registrarLicencia,
        data: model.toJson(),
      );

      console('Respuesta del servidor: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        if (response.data['ok'] == 'ok') {
          return licencia; // Retornar la licencia que ya tenemos
        } else {
          throw Exception('${response.data['msg'] ?? 'Error desconocido'}');
        }
      } else {
        throw Exception(
          'Error al registrar licencia de conducir: ${response.statusCode} - ${response.data}',
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

  // ELIMINAR LICENCIA DE CONDUCIR PASANDO EL CODIGO EN EL DATA
  @override
  Future<bool> eliminarLicenciaConducir(int codLicencia) async {
    try {
      final response = await _dio.post(
        AppConstants.eliminarLicencia,
        data: {'codLicencia': codLicencia},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //OBTENER TIPO DE LICENCIA DE CONDUCIR
  @override
  Future<List<TipoLicenciaEntity>> obtenerTipoLicenciaConducir() async {
    try {
      final response = await _dio.post(AppConstants.tiposLicencia);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TipoLicenciaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error al obtener tipo de licencia de conducir: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener el tipo de licencia de conducir: $e');
      return [];
    }
  }

  // ELIMINAR FOTO DE PERFIL O DOCUMENTOS
  @override
  Future<bool> eliminarFoto(
    int codEmpleado,
    String tipoDocumento,
    String nombreArchivo,
  ) async {
    try {
      console('========== ELIMINAR FOTO ==========');
      console('📤 codEmpleado: $codEmpleado');
      console('📤 tipoDocumento: $tipoDocumento');
      console('📤 nombreArchivo: $nombreArchivo');

      final response = await _dio.delete(
        '${AppConstants.baseUrl}${AppConstants.eliminarFoto}',
        queryParameters: {
          'codEmpleado': codEmpleado,
          'tipoDocumento': tipoDocumento,
          'nombreArchivo': nombreArchivo,
        },
      );

      console('📥 Respuesta: ${response.data}');

      if (response.statusCode == 200) {
        console('✅ Foto eliminada correctamente');
        return true;
      } else if (response.statusCode == 404) {
        console('⚠️ Archivo no encontrado (404)');
        return false;
      } else {
        console('❌ Error: ${response.statusCode} - ${response.data?['msg']}');
        return false;
      }
    } on DioException catch (e) {
      console('❌ DioException: ${e.message}');
      console('   Response: ${e.response?.data}');
      return false;
    } catch (e) {
      console('❌ Error inesperado: $e');
      return false;
    }
  }

  //OBTENDRA LISTA DE CARGOS X EMPRESA
  @override
  Future<List<EmpleadoEntity>> getCargosXEmpresa(
    String? search,
    int? codEmpresa,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.cargoXempresa,
        data: {'search': search, 'codEmpresa': codEmpresa},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => EmpleadoModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } catch (e) {
      console('Error en cargo por empresa: $e');
      return [];
    }
  }

  //OBTENER LISTA DE SEGUROS
  @override
  Future<List<SeguroEntity>> obtenerSeguros() async {
    try {
      final response = await _dio.post(AppConstants.obtenerSeguro);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SeguroModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      console('Error Dio al obtener lista de seguros: ${e.message}');
      return [];
    } catch (e) {
      console('Error al obtener los seguros: $e');
      return [];
    }
  }

  //OBTENER AFILIACION SEGURO DE UN EMPLEADO
  @override
  Future<AfiliacionSeguroEntity?> obtenerAfiliacionSeguro(
    int codEmpleado,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerAfiliacionSeguro,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final empleadoModel = AfiliacionSeguroModel.fromJson(response.data);
        return empleadoModel.toEntity();
      }
      return null;
    } on DioException catch (e) {
      console('Error Dio al obtener afiliacion de seguro: ${e.message}');
      return null;
    } catch (e) {
      console('Error al obtener afiliacion de seguro: $e');
      return null;
    }
  }

  //REGISTRARA UNA NUEVA AFILIACION DE SEGURO PARA UN EMPLEADO
  @override
  Future<AfiliacionSeguroEntity> registrarAfiliacionSeguro(
    AfiliacionSeguroEntity afiliacion,
  ) async {
    final model = AfiliacionSeguroModel.fromEntity(afiliacion);
    try {
      console('Enviando afiliacion: $afiliacion');

      final response = await _dio.post(
        AppConstants.registrarAfiliacionSeguro,
        data: model.toJson(),
      );

      console('Respuesta del servidor: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        if (response.data['ok'] == 'ok') {
          return afiliacion; // Retornar la licencia que ya tenemos
        } else {
          throw Exception('${response.data['msg'] ?? 'Error desconocido'}');
        }
      } else {
        throw Exception(
          'Error al registrar afiliacion al seguro: ${response.statusCode} - ${response.data}',
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

  //ELIMINAR AFILIACION DE SEGURO
  @override
  Future<bool> eliminarAfiliacionSeguro(int codAfiliacion) async {
    try {
      final response = await _dio.post(
        AppConstants.eliminarAfiliacionSeguro,
        data: {'codAfiliacion': codAfiliacion},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //REGISTRARA UNA NUEVA ASEGURADORA
  @override
  Future<SeguroEntity> registrarAseguradora(SeguroEntity seguro) async {
    final model = SeguroModel.fromEntity(seguro);
    try {
      console('Enviando seguro: $seguro');

      final response = await _dio.post(
        AppConstants.registrarAseguradora,
        data: model.toJson(),
      );

      console('Respuesta del servidor: ${response.data}');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        if (response.data['ok'] == 'ok') {
          return seguro; // Retornar la licencia que ya tenemos
        } else {
          throw Exception('${response.data['msg'] ?? 'Error desconocido'}');
        }
      } else {
        throw Exception(
          'Error al registrar aseguradora: ${response.statusCode} - ${response.data}',
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

  //ELIMINAR AFILIACION DE SEGURO
  @override
  Future<bool> eliminarAseguradora(int codSeguro) async {
    try {
      final response = await _dio.post(
        AppConstants.eliminarAseguradora,
        data: {'codSeguro': codSeguro},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //OBTENDRA LOS TIPOS DE SEGURO
  @override
  Future<List<TipoSeguroEntity>> obtenerTipoSeguro() async {
    try {
      final response = await _dio.post(AppConstants.obtenerTipoSeguro);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TipoSeguroModel.fromJson(json))
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

  //OBTENER HABER BASICO DEL EMPLEADO
  @override
  Future<EmpleadoEntity> obtenerHaberBasico(int codEmpleado) async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerHaberBasico,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final empleadoModel = EmpleadoModel.fromJson(response.data);
        return empleadoModel.toEntity();
      } else {
        throw Exception(
          'Error al obtener haber basico: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener haber basico empleado: $e');
    }
  }
}
