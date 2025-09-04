import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/data/models/Persona_model.dart';
import 'package:bosque_flutter/data/models/ciExpedido_model.dart';
import 'package:bosque_flutter/data/models/ciudad_model.dart';
import 'package:bosque_flutter/data/models/dependiente_model.dart';
import 'package:bosque_flutter/data/models/email_model.dart';
import 'package:bosque_flutter/data/models/empleado_model.dart';
import 'package:bosque_flutter/data/models/estado_civil_model.dart';
import 'package:bosque_flutter/data/models/experiencia_laboral_model.dart';
import 'package:bosque_flutter/data/models/formacion_model.dart';
import 'package:bosque_flutter/data/models/garante_referencia_model.dart';
import 'package:bosque_flutter/data/models/pais_model.dart';
import 'package:bosque_flutter/data/models/parentesco_model.dart';
import 'package:bosque_flutter/data/models/relacion_laboral_model.dart';
import 'package:bosque_flutter/data/models/sexo_model.dart';
import 'package:bosque_flutter/data/models/telefono_model.dart';
import 'package:bosque_flutter/data/models/tipo_activo_model.dart';
import 'package:bosque_flutter/data/models/tipo_duracion_formacion_model.dart';
import 'package:bosque_flutter/data/models/tipo_formacion_model.dart';
import 'package:bosque_flutter/data/models/tipo_garante_referencia_model.dart';
import 'package:bosque_flutter/data/models/tipo_telefono_model.dart';
import 'package:bosque_flutter/data/models/usuario_bloqueado_model.dart';
import 'package:bosque_flutter/data/models/zona_model.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';
import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/garante_referencia.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/parentesco_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/sexo_entity.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_activo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_garante_referencia_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/usuario_bloqueado_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/domain/repositories/ficha_trabajador_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:printing/printing.dart'; // Añade esta importación


class FichaTrabajadorImpl implements FichaTrabajadorRepository {
  final Dio _dio = DioClient.getInstance();

@override
Future<List<EmpleadoEntity>> obtenerListaEmpleadoyDependientes() async {
  try {
    final response = await _dio.post(AppConstants.empListarEmpleadosDependientes);
    
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data ?? [];
      final items = (data as List<dynamic>)
          .map((json) => EmpleadoModel.fromJson(json))
          .toList();
     
      return items.map((model) => model.toEntity()).toList();
    } else {
      return [];
    }
  } catch (e) {
    print('Error al obtener empleados: $e');
    return [];
  }
}
 @override
  Future<List<DependienteEntity>> getDependientes(int codEmpleado) async {
    try {
      final response = await _dio.post(
        AppConstants.empLstDependientes,
        data: {'codEmpleado': codEmpleado},
      );

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => DependienteModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        // Si el backend responde con error, retorna lista vacía en vez de lanzar excepción
        return [];
      }
    } on DioException catch (e) {
      // Si hay error de red o servidor, retorna lista vacía
      return [];
    } catch (e) {
      // Si hay cualquier otro error, retorna lista vacía
      return [];
    }
  }
   @override
  Future<List<CiExpedidoEntity>> obtenerCiExp()async {
    try{
      final response = await  _dio.post(AppConstants.perLstCiExpedido);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CiExpedidoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener CiExpedido: ${e.message}');
      return [];
    } 
    catch (e) {
      print('Error al obtener CiExpedido: $e');
      return [];
    }
   
  }
  @override
  Future<List<TipoActivoEntity>> obtenerTipoActivo() async {
    try {
      final response = await _dio.post(AppConstants.depLstActivo);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TipoActivoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Tipo Activo: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Tipo Activo: $e');
      return [];
    }
  }
   @override
  Future<List<EstadoCivilEntity>> obtenerEstadoCivil()async {
    try{
      final response= await _dio.post(AppConstants.perLstEstadoCivil);
      if (response.statusCode == 200 && response.data != null){
        final data = response.data?? [];
        final items = (data as List<dynamic>)
            .map((json)=> EstadoCivilModel.fromJson(json)).toList();
            return items.map ((model)=> model.toEntity()).toList();
      }else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener Estado Civil: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Estado Civil: $e');
      return [];
    }
  }
  @override
  Future<List<PaisEntity>> obtenerPais()async {
    try{
      final response = await _dio.post(AppConstants.perLstPais);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => PaisModel.fromJson(json))
            .toList();
        return items.map((model)=> model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Países: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Países: $e');
      return [];
    }
  }
  @override
  Future<List<ZonaEntity>> obtenerZona(int codCiudad)async {
    try{
      final response = await _dio.post(AppConstants.perLstZona,
        data: {'codCiudad':codCiudad});
        if (response.statusCode ==200 && response.data != null) {
          final data = response.data ?? [];
          final items = (data as List<dynamic>)
              .map((json) => ZonaModel.fromJson(json))
              .toList();
          return items.map((model) => model.toEntity()).toList();
        } else {
          return [];
        }
    }on DioException catch (e) {
      print('Error al obtener Zonas: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Zonas: $e');
      return [];
    }
  }
  @override
  Future<List<SexoEntity>> obtenerGenero()async {
    try{
      final response = await _dio.post(AppConstants.perLstGenero);
      if (response.statusCode == 200 && response.data != null){
        final data = response.data ??[];
        final items = (data as List<dynamic>)
            .map((json)=>SexoModel.fromJson(json))
            .toList();
                return items.map((model) => model.toEntity()).toList();
      }else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener Géneros: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Géneros: $e');
      return [];
    }
  }
  @override
  Future<List<TelefonoEntity>> obtenerTelefono(int codPersona)async {
    try{
      final response = await _dio.post(AppConstants.perLstTelefono,
        data: {'codPersona': codPersona});
    if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TelefonoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Teléfonos: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Teléfonos: $e');
      return [];
    }
    
  }
   @override
  Future<bool> eliminarDependiente(int codDependiente)async {
    try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.depEliminarDependiente}/$codDependiente',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
    

    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
  }
  @override
  Future<PersonaEntity> obtenerPersona(int codPersona)async {
   try{
    final response = await _dio.post(
      AppConstants.perObtenerPersona,
      data: {'codPersona': codPersona},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final personaModel = PersonaModel.fromJson(response.data);
      return personaModel.toEntity();
    } else {
      throw Exception('Error al obtener persona: ${response.statusCode}');
    }
   }catch (e) {
    throw Exception('Error al obtener persona: $e');
   }
  }

  

 @override
Future<List<DependienteEntity>> editarDep(DependienteEntity dep) async {
  try {
    final response = await _dio.post(
      AppConstants.depEditarDependiente,
      data: dep.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Después de editar exitosamente, obtener la lista actualizada
      return await getDependientes(dep.codEmpleado);
    } else {
      throw Exception(
        'Error al editar dependiente: ${response.statusCode} - ${response.data}',
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
 @override
  Future<List<CiudadEntity>> obtenerCiudad(int codPais)async {
     try{
      final response = await _dio.post(AppConstants.perLstCiudad,
        data: {'codPais': codPais});
    if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CiudadModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Ciudad: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Ciudad: $e');
      return [];
    }
  }
  @override
Future<PersonaEntity> registrarPersona(PersonaModel persona) async {
  try {
    print('Enviando datos de persona: ${persona.toJson()}'); // Log para depuración

    final response = await _dio.post(
      AppConstants.perRegistrarPersona,
      data: persona.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    print('Respuesta del servidor: ${response.data}'); // Log para depuración

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Si la respuesta es exitosa, retornamos la persona original
      // ya que el servidor podría no devolver los datos actualizados
      return persona.toEntity();
    } else {
      throw Exception(
        'Error al registrar persona: ${response.statusCode} - ${response.data}',
      );
    }
  } on DioException catch (e) {
    print('DioException: ${e.response?.data}'); // Log para depuración
    String errorMessage = 'Error de conexión: ${e.message}';
    if (e.response != null && e.response!.data != null) {
      errorMessage = 'Error del servidor: ${e.response!.statusCode} - ${e.response!.data}';
    }
    throw Exception(errorMessage);
  } catch (e) {
    print('Error inesperado: $e'); // Log para depuración
    throw Exception('Error inesperado: $e');
  }
}
   @override
  Future<List<ParentescoEntity>> obtenerParentesco()async {
    try {
      final response = await _dio.post(AppConstants.depLstParentesco);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => ParentescoModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Parentesco: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Parentesco: $e');
      return [];
    }
  }
  @override
Future<List<TelefonoEntity>> registrarTelefono(TelefonoEntity tel) async {
  try {
    // Log para depuración
    print('Enviando teléfono: ${tel.toJson()}');

    final response = await _dio.post(
      AppConstants.perRegistrarTelefono,
      data: tel.toJson(),
      
    );

    // Log para depuración
    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Después de registrar exitosamente, obtener la lista actualizada
      return await obtenerTelefono(tel.codPersona);
    } else {
      throw Exception(
        'Error al registrar teléfono: ${response.statusCode} - ${response.data}',
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
 @override
  Future<List<TipoTelefonoEntity>> obtenerTipoTelefono()async {
     try{
      final response = await _dio.post(AppConstants.perObtenerTipoTelefono,);
      if (response.statusCode == 200 && response.data != null){
        final data = response.data ??[];
        final items = (data as List<dynamic>)
            .map((json)=>TipoTelefonoModel.fromJson(json))
            .toList();
                return items.map((model) => model.toEntity()).toList();
      }else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener TELEFONOS: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener TELF: $e');
      return [];
    }
  }
  @override
  Future<bool> eliminarTelefono(int codTelefono)async {
    try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.perEliminarTelefono}/$codTelefono',
      
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
  }
  @override
  Future<PersonaEntity> editarPersona(PersonaEntity per) {
    // TODO: implement editarPersona
    throw UnimplementedError();
  }

 

  @override
  Future<bool> eliminarEmail(int codEmail)async {
    try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.perEliminarEmail}/$codEmail',
      
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
  }

  @override
  Future<bool> eliminarExpLab(int codExperienciaLaboral)async {
    try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.perEliminarExperienciaLaboral}/$codExperienciaLaboral',
      
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
  }

  @override
  Future<bool> eliminarFormacion(int codFormacion)async {
    try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.perEliminarFormacion}/$codFormacion',
      
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
  }

  @override
  Future<bool> eliminarGarRef(int codGarante)async {
    try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.empEliminarGaranteReferencia}/$codGarante',
      
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
  }

  @override
  Future<List<EmpleadoEntity>> obtenerDatosEmp(int codEmpleado)async {
    try{
final response = await _dio.post(
      AppConstants.empObtenerDatosEmpleado,
      data: {
        'codEmpleado': codEmpleado  // Agregar el codEmpleado en el body
      },
    );      if (response.statusCode == 200 && response.data != null){
        final data = response.data ??[];
        final items = (data as List<dynamic>)
            .map((json)=>EmpleadoModel.fromJson(json))
            .toList();
                return items.map((model) => model.toEntity()).toList();
      }else {
        return [];
      }
    }on DioException catch (e) {
      print('Error al obtener datos del empleado: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener empleado: $e');
      return [];
    }
  }

 

 

  @override
  Future<List<EmpleadoEntity>> obtenerCumples()async {
      try {
    final response = await _dio.post(AppConstants.empObtenerCumpleanios);
    
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data ?? [];
      final items = (data as List<dynamic>)
          .map((json) => EmpleadoModel.fromJson(json))
          .toList();
     
      return items.map((model) => model.toEntity()).toList();
    } else {
      return [];
    }
  } catch (e) {
    print('Error al obtener empleados: $e');
    return [];
  }
  }

  

  @override
  Future<List<EmailEntity>> obtenerEmail(int codPersona)async {
    try{
      final response = await _dio.post(
        AppConstants.perObtenerEmmail,
        data: {'codPersona': codPersona},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => EmailModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al cargar Emails: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Emails: $e');
      return [];
 
    }
  }

 

  @override
  Future<List<ExperienciaLaboralEntity>> obtenerExperienciaLaboral(int codEmpleado)async {
    try{
      final response = await _dio.post(
        AppConstants.perObtenerExperienciaLaboral,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => ExperienciaLaboralModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al cargar Experiencia Laboral: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Experiencia Laboral: $e');
      return [];
    }
  }

  @override
  Future<List<FormacionEntity>> obtenerFormacion(int codEmpleado)async {
    try{
      final response = await _dio.post(
        AppConstants.perObtenerFormacion,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => FormacionModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al cargar Formación: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Formación: $e');
      return [];
    }
  }

  @override
  Future<List<GaranteReferenciaEntity>> obtenerGaranteReferencia(int codEmpleado)async {
    try{
      final response = await _dio.post(
        AppConstants.empObtenerGaranteReferencia,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => GaranteReferenciaModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al cargar Garante Referencia: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Garante Referencia: $e');
      return [];
    }
  }

  

  @override
  Future<List<GaranteReferenciaEntity>> obtenerListaGarRef() {
    // TODO: implement obtenerListaGarRef
    throw UnimplementedError();
  }

  @override
  Future<List<PersonaEntity>> obtenerListaPersonas()async {
    try {
      final response = await _dio.post(AppConstants.perObtenerLstPersonas);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => PersonaModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener lista de personas: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener lista de personas: $e');
      return [];
    }
  }

  @override
  Future<List<RelacionLaboralEntity>> obtenerRelEmp(int codEmpleado)async {
    try {
      final response = await _dio.post(
        AppConstants.perObtenerRelacionLaboral,
        data: {'codEmpleado': codEmpleado},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => RelacionLaboralModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al cargar Relaciones Laborales: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Relaciones Laborales: $e');
      return [];
    }
  }

  

  @override
  Future<List<TipoDuracionFormacionEntity>> obtenerTipoDuracionFor()async {
    try {
      final response = await _dio.post(AppConstants.perObtenerTipoDuracionFormacion);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TipoDuracionFormacionModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Tipo Duración Formación: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Tipo Duración Formación: $e');
      return [];
    }
  }

  @override
  Future<List<TipoFormacionEntity>> obtenerTipoFormacion()async {
    try {
      final response = await _dio.post(AppConstants.perObtenerTipoFormacion);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TipoFormacionModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Tipo Formación: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Tipo Formación: $e');
      return [];
    }
  }

  @override
  Future<List<TipoGaranteReferenciaEntity>> obtenerTipoGaranteRef()async {
    try {
      final response = await _dio.post(AppConstants.empObtenerTipoGaranteReferencia);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data ?? [];
        final items = (data as List<dynamic>)
            .map((json) => TipoGaranteReferenciaModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error al obtener Tipo Garante Referencia: ${e.message}');
      return [];
    } catch (e) {
      print('Error al obtener Tipo Garante Referencia: $e');
      return [];
    }
  }

  

  @override
  Future<List<EmailEntity>> registrarEmail(EmailEntity email)async {
    try {
      // Log para depuración
      print('Enviando email: ${email.toJson()}');

      final response = await _dio.post(
        AppConstants.perRegistrarEmail,
        data: email.toJson(),
       
      );

      // Log para depuración
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después de registrar exitosamente, obtener la lista actualizada
        return await obtenerEmail(email.codPersona);
      } else {
        throw Exception(
          'Error al registrar email: ${response.statusCode} - ${response.data}',
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

  @override
  Future<List<ExperienciaLaboralEntity>> registrarExpLaboral(ExperienciaLaboralEntity expl)async {
    try {
      // Log para depuración
      print('Enviando experiencia laboral: ${expl.toJson()}');

      final response = await _dio.post(
        AppConstants.perRegistrarExperienciaLaboral,
        data: expl.toJson(),
        
      );

      // Log para depuración
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después de registrar exitosamente, obtener la lista actualizada
        return await obtenerExperienciaLaboral(expl.codEmpleado);
      } else {
        throw Exception(
          'Error al registrar experiencia laboral: ${response.statusCode} - ${response.data}',
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

  @override
  Future<List<FormacionEntity>> registrarFormacion(FormacionEntity fr) async{
    try {
      // Log para depuración
      print('Enviando formación: ${fr.toJson()}');

      final response = await _dio.post(
        AppConstants.perRegistrarFormacion,
        data: fr.toJson(),
        
      );

      // Log para depuración
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después de registrar exitosamente, obtener la lista actualizada
        return await obtenerFormacion(fr.codEmpleado);
      } else {
        throw Exception(
          'Error al registrar formación: ${response.statusCode} - ${response.data}',
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

  @override
  Future<List<GaranteReferenciaEntity>> registrarGaranteReferencia(GaranteReferenciaEntity garRef)async {
    try {
      // Log para depuración
      print('Enviando garante referencia: ${garRef.toJson()}');

      final response = await _dio.post(
        AppConstants.empRegistrarGaranteReferencia,
        data: garRef.toJson(),
        
      );

      // Log para depuración
      print('Respuesta del servidor: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después de registrar exitosamente, obtener la lista actualizada
        return await obtenerGaranteReferencia(garRef.codEmpleado);
      } else {
        throw Exception(
          'Error al registrar garante referencia: ${response.statusCode} - ${response.data}',
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

  

  @override
  Future<List<RelacionLaboralEntity>> registrarRelEmp(RelacionLaboralEntity ree) {
    // TODO: implement registrarRelEmp
    throw UnimplementedError();
  }

  

 @override
Future<bool> uploadImg(int codEmpleado, dynamic imagen) async {
  try {
    final fileName = "$codEmpleado.jpg";
    MultipartFile multipartFile;

   if (imagen is Uint8List) {
      multipartFile = MultipartFile.fromBytes(
        imagen,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'), // Ahora MediaType está disponible
      );
    } else if (imagen is File) {
      multipartFile = await MultipartFile.fromFile(
        imagen.path,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );
    } else {
      throw Exception('Formato de imagen no soportado');
    }

    final formData = FormData.fromMap({
      'codEmpleado': codEmpleado,
      'file': multipartFile,
    });

    final response = await _dio.post(
      AppConstants.empSubirImagen,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 409) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data['message'] ?? 'Error de validación en el servidor',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al subir imagen: ${response.statusCode}');
    }

    return true;
  } on DioException catch (e) {
    print('Error DioException al subir imagen: ${e.message}');
    throw Exception('Error de conexión: ${e.message}');
  } catch (e) {
    print('Error al subir imagen: $e');
    throw Exception('Error inesperado: $e');
  }
}

@override
Future<List<ZonaEntity>> registrarZona(ZonaEntity zona) async {
  try {
    // Log para depuración
    print('Enviando zona: ${zona.toJson()}');

    final response = await _dio.post(
      AppConstants.perRegistrarZona,
      data: zona.toJson(),
      
    );

    // Log para depuración
    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Después de registrar exitosamente, obtener la lista actualizada
      return await obtenerZona(zona.codCiudad);
    } else {
      throw Exception(
        'Error al registrar teléfono: ${response.statusCode} - ${response.data}',
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
@override
Future<List<CiudadEntity>> registrarCiudad(CiudadEntity ciudad) async {
  try {
    // Log para depuración
    print('Enviando ciudad: ${ciudad.toJson()}');

    final response = await _dio.post(
      AppConstants.perRegistrarCiudad,
      data: ciudad.toJson(),
    );

    // Log para depuración
    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Después de registrar exitosamente, obtener la lista actualizada
      return await obtenerCiudad(ciudad.codCiudad);
    } else {
      throw Exception(
        'Error al registrar ciudad: ${response.statusCode} - ${response.data}',
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
@override
Future<List<PaisEntity>> registrarPais(PaisEntity pais) async {
  try {
    // Log para depuración
    print('Enviando país: ${pais.toJson()}');

    final response = await _dio.post(
      AppConstants.perRegistrarPais,
      data: pais.toJson(),
    );

    // Log para depuración
    print('Respuesta del servidor: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Después de registrar exitosamente, obtener la lista actualizada
      return await obtenerPais();
    } else {
      throw Exception(
        'Error al registrar país: ${response.statusCode} - ${response.data}',
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
Future<bool> subirFotoDocs({
  required int codEmpleado,
  required String tipoDocumento,
  required dynamic archivo,
  required String lado,
}) async {
  try {
    // Generar nombre de archivo genérico (el backend lo renombrará)
    final fileName = "$codEmpleado-${tipoDocumento.toLowerCase()}.jpg";
    MultipartFile multipartFile;

    if (archivo is Uint8List) {
      multipartFile = MultipartFile.fromBytes(
        archivo,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );
    } else if (archivo is File) {
      multipartFile = await MultipartFile.fromFile(
        archivo.path,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );
    } else {
      throw Exception('Formato de archivo no soportado');
    }

    final formData = FormData.fromMap({
      'codEmpleado': codEmpleado,
      'tipoDocumento': tipoDocumento,
      'lado': lado,
      'file': multipartFile,
    });

    final response = await _dio.post(
      AppConstants.empSubirDocs, // Asegúrate de definir esta constante
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
    print ('Respuesta del servidor: ${response.data}'); // Log para depuración

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al subir documento: ${response.statusCode}');
    }

    return true;
  } on DioException catch (e) {
    print('Error DioException al subir documento: ${e.message}');
    throw Exception('Error de conexión: ${e.message}');
  } catch (e) {
    print('Error al subir documento: $e');
    throw Exception('Error inesperado: $e');
  }
}
@override
  Future<Map<String, List<String>>> obtenerTodosLosDocumentos(int codPersona) async {
  try {
    final response = await _dio.get(
      '${AppConstants.baseUrl+AppConstants.getDocImageUrl}$codPersona/all',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = Map<String, dynamic>.from(response.data);
      return data.map((k, v) => MapEntry(k, List<String>.from(v)));
    }
    return {};
  } catch (e) {
    print('Error al obtener todos los documentos: $e');
    return {};
  }
}

@override
Future<List<Map<String, dynamic>>> obtenerDocumentosPendientes() async {
  print('Llamando a obtenerDocumentosPendientes()');
  try {
    final response = await _dio.get(
      AppConstants.admLstDocs,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );
    print('Respuesta: ${response.statusCode} - ${response.data}');
    if (response.statusCode == 200 && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  } catch (e) {
    print('Error al obtener documentos pendientes: $e');
    return [];
  }
}
@override
  Future<void> aprobarDocumentoPendiente(Map<String, dynamic> doc) async {
    print ('Aprobando documento pendiente: ${doc['nombreArchivo']}');
  final response = await _dio.post(
    AppConstants.admAprobarDcos,
    data: {
      'codEmpleado': doc['codEmpleado'],
      'tipoDocumento': doc['tipoDocumento'],
      'nombreArchivo': doc['nombreArchivo'],
    },
    options: Options(
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status! < 500,
    ),
  );
  if (response.statusCode != 200) {
    throw Exception('Error al aprobar documento');
  }
}

@override
  Future<void> rechazarDocumentoPendiente(Map<String, dynamic> doc) async {
  final response = await _dio.post(
    AppConstants.admRechazarDocs,
    data: {
      'codEmpleado': doc['codEmpleado'],
      'tipoDocumento': doc['tipoDocumento'],
      'nombreArchivo': doc['nombreArchivo'],
    },
    options: Options(
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status! < 500,
    ),
  );
  if (response.statusCode != 200) {
    throw Exception('Error al rechazar documento');
  }
}
Future<Uint8List> descargarReporteJasper(int codEmpleado) async {
  final response = await _dio.post(
    AppConstants.empExportarPdf,
    data: jsonEncode({'codEmpleado': codEmpleado}),
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
//reportes
Future<void> descargarYMostrarReporteJasper({
  required BuildContext context,
  required int codEmpleado,
  required FichaTrabajadorImpl repo, // Usa tu repo para mantener la arquitectura
}) async {
  try {
    // Usamos el método ya existente en tu repo para obtener los bytes del PDF
    final pdfBytes = await repo.descargarReporteJasper(codEmpleado);

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'FichaTrabajador_$codEmpleado.pdf',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al descargar el PDF: $e')),
    );
  }
}
//bloqueo usuario
Future<bool> registrarAdvertenciaUsuario({
  required int codUsuario,
  required DateTime fechaAdvertencia,
  required DateTime fechaLimite,
  required int bloqueado,
  required int audUsuario,
}) async {
  try {
    final response = await _dio.post(
      AppConstants.ubBloquearUsuario,
      data: {
        'codUsuario': codUsuario,
        'fechaAdvertencia': fechaAdvertencia.toIso8601String(),
        'fechaLimite': fechaLimite.toIso8601String(),
        'bloqueado': bloqueado,
        'audUsuario': audUsuario,
      },
      
    );

    // El backend responde con 201 (CREATED) si fue exitoso
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print('Error al registrar advertencia/bloqueo: ${response.statusCode} - ${response.data}');
      return false;
    }
  } on DioException catch (e) {
    print('DioException al registrar advertencia/bloqueo: ${e.message}');
    return false;
  } catch (e) {
    print('Error inesperado al registrar advertencia/bloqueo: $e');
    return false;
  }
}
//desbloqueo de usuario
@override
Future<bool> desbloquearUsuario({required int codUsuario}) async {
  try {
    final response = await _dio.delete(
      '${AppConstants.baseUrl}${AppConstants.ubDesbloquearUsuario}/$codUsuario',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );
    return response.statusCode == 200;
  } catch (e) {
    print('Error al desbloquear usuario: $e');
    return false;
  }
}
//ver usuario bloqueado
@override
Future<UsuarioBloqueadoEntity> obtenerUsuarioBloqueado(int codUsuario) async {
  try {
    final response = await _dio.post(
      AppConstants.ubVerUsuarioBloqueado,
      data: {'codUsuario': codUsuario},
    );
    if (response.statusCode == 200 && response.data != null) {
      final usuarioBloqueadoModel = UsuarioBloqueadoModel.fromJson(response.data);
      return usuarioBloqueadoModel.toEntity();
    } else {
       throw Exception('Error al obtener usuario bloqueado: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al obtener usuario bloqueado: $e');
     throw Exception('Error al obtener usuario-bloqueado: $e');
  }
}


}