import 'dart:typed_data';

import 'package:bosque_flutter/core/state/notifiers/dependientes_notifier.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/permisos_edicion.dart';
import 'package:bosque_flutter/data/models/Persona_model.dart';
import 'package:bosque_flutter/data/repositories/ficha_trabajador_impl.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
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
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';




final empleadosDependientesProvider = FutureProvider.family<List<EmpleadoEntity>,int>((ref,codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  final empleados = await repo.obtenerListaEmpleadoyDependientes(codEmpleado);
  return empleados;
  
});
final empleadoProvider = FutureProvider.family<EmpleadoEntity, int>((ref, codEmpleado) async {
  final empleados = await ref.watch(empleadosDependientesProvider(codEmpleado).future);
  return empleados.firstWhere(
    (emp) => emp.codEmpleado == codEmpleado,
    orElse: () => throw Exception('Empleado no encontrado'),
  );
});

final dependientesProvider = FutureProvider.family<List<DependienteEntity>,int>((ref, codEmpleado)async{
  final repo = FichaTrabajadorImpl();
  final dependientes = await repo.getDependientes(codEmpleado);
  return dependientes;
});

final parentescosProvider = FutureProvider<List<ParentescoEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final parentescos = await repo.obtenerParentesco();
  return parentescos;
});

final tipoActivoProvider = FutureProvider<List<TipoActivoEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final tipoActivo = await repo.obtenerTipoActivo();
  return tipoActivo;
});

final ciExpedidoProvider = FutureProvider<List<CiExpedidoEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final ciExpedidos = await repo.obtenerCiExp();
  return ciExpedidos;
});

final estadoCivilProvider = FutureProvider<List<EstadoCivilEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final estadoCivil = await repo.obtenerEstadoCivil();
  return estadoCivil;
});

final paisProvider = FutureProvider<List<PaisEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final paises = await repo.obtenerPais();
  return paises;
});

final zonaProvider = FutureProvider.family<List<ZonaEntity>, int>((ref, codCiudad)async{
  final repo = FichaTrabajadorImpl();
  final zonas = await repo.obtenerZona(codCiudad);
  return zonas;
});

final sexoProvider = FutureProvider<List<SexoEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final sexos = await repo.obtenerGenero();
  return sexos;
});


final dependientesNotifierProvider = 
    AsyncNotifierProvider<DependientesNotifier, List<DependienteEntity>>(() {
  return DependientesNotifier();
});
final ciudadProvider = FutureProvider.family<List<CiudadEntity>, int>((ref, codPais )async{
  final repo = FichaTrabajadorImpl();
  final ciudades = await repo.obtenerCiudad(codPais);
  return ciudades;
});
final editarDependienteProvider = StateProvider.family<Future<List<DependienteEntity>>, DependienteEntity>(
  (ref, dependiente) => ref.read(dependientesNotifierProvider.notifier)
      .editarDependiente(dependiente)
);
final registrarPersonaProvider = FutureProvider.family<PersonaEntity, PersonaEntity>(
  (ref, persona) async {
    try {
      final repo = FichaTrabajadorImpl();
      // Convertir PersonaEntity a PersonaModel antes de enviarlo
      final personaModel = PersonaModel.fromEntity(persona);
      final result = await repo.registrarPersona(personaModel);
      return result;
    } catch (e) {
      throw Exception('Error al registrar persona: $e');
    }
  },
);
final obtenerPersonaProvider = FutureProvider.family<PersonaEntity, int>(
  (ref, codPersona) async {
    final repo = FichaTrabajadorImpl();
    return await repo.obtenerPersona(codPersona);
  },
);
final editarDepProvider = FutureProvider.family<List<DependienteEntity>, DependienteEntity>(
  (ref, dependiente) async {
    final repo = FichaTrabajadorImpl();
    return await repo.editarDep(dependiente);
  },
);
// providers para manejar telefono
final telefonoProvider = FutureProvider.family<List<TelefonoEntity>,int>((ref, codPersona)async{
 final repo = FichaTrabajadorImpl();
  final telefonos = await repo.obtenerTelefono(codPersona);
  return telefonos;
});
final tipoTelefonoProvider = FutureProvider<List<TipoTelefonoEntity>>((ref)async{
  final repo = FichaTrabajadorImpl();
  final tiposTelefono = await repo.obtenerTipoTelefono();
  return tiposTelefono;
});
final registrarTelefonoProvider = FutureProvider.family<List<TelefonoEntity>, TelefonoEntity>(
  (ref, telefono) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarTelefono(telefono);
  },
);
final eliminarTelefonoProvider = FutureProvider.family<void, int>(
  (ref, codTelefono) async {
    final repo = FichaTrabajadorImpl();
    await repo.eliminarTelefono(codTelefono);
  },
);
// providers para manejar email
final registrarEmailProvider = FutureProvider.family<List<EmailEntity>, EmailEntity>(
  (ref, email) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarEmail(email);
  },
);
final emailProvider = FutureProvider.family<List<EmailEntity>, int>((ref, codPersona) async {
  final repo = FichaTrabajadorImpl();
  final emails = await repo.obtenerEmail(codPersona);
  return emails;
});
final eliminarEmailProvider = FutureProvider.family<void, int>(
  (ref, codEmail) async {
    final repo = FichaTrabajadorImpl();
    await repo.eliminarEmail(codEmail);
  },
);
//providers para manejar formacion
final formacionProvider = FutureProvider.family<List<FormacionEntity>, int>((ref, codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  final formacion = await repo.obtenerFormacion(codEmpleado);
  return formacion;
});
final registrarFormacionProvider = FutureProvider.family<List<FormacionEntity>, FormacionEntity>(
  (ref, formacion) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarFormacion(formacion);
  },
);
final eliminarFormacionProvider = FutureProvider.family<void, int>(
  (ref, codFormacion) async {
    final repo = FichaTrabajadorImpl();
    await repo.eliminarFormacion(codFormacion);
  },
); 
final obtenerTipoFormacionProvider = FutureProvider<List<TipoFormacionEntity>>((ref) async {
  final repo = FichaTrabajadorImpl();
  final tipoFormacion = await repo.obtenerTipoFormacion();
  return tipoFormacion;
});
final obtenerTipoDuracionFormacionProvider = FutureProvider<List<TipoDuracionFormacionEntity>>((ref) async {
  final repo = FichaTrabajadorImpl();
  final tipoDuracionFormacion = await repo.obtenerTipoDuracionFor();
  return tipoDuracionFormacion;
});
//providers para manejar experiencia laboral
final experienciaLaboralProvider = FutureProvider.family<List<ExperienciaLaboralEntity>, int>((ref, codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  final experienciaLaboral = await repo.obtenerExperienciaLaboral(codEmpleado);
  return experienciaLaboral;
});
final registrarExperienciaLaboralProvider = FutureProvider.family<List<ExperienciaLaboralEntity>, ExperienciaLaboralEntity>(
  (ref, experienciaLaboral) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarExpLaboral(experienciaLaboral);
  },
);
final eliminarExperienciaLaboralProvider = FutureProvider.family<void, int>(
  (ref, codExpLaboral) async {
    final repo = FichaTrabajadorImpl();
    await repo.eliminarExpLab(codExpLaboral);
  },
);
//providers para manejar garante y referencias
final obtenerTipoGaranteReferenciaProvider = FutureProvider<List<TipoGaranteReferenciaEntity>>((ref) async {
  final repo = FichaTrabajadorImpl();
  final tipoGaranteReferencia = await repo.obtenerTipoGaranteRef();
  return tipoGaranteReferencia;
});
final obtenerGaranteReferenciaProvider = FutureProvider.family<List<GaranteReferenciaEntity>, int>((ref, codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  final garanteReferencia = await repo.obtenerGaranteReferencia(codEmpleado);
  return garanteReferencia;
});
final registrarGaranteReferenciaProvider = FutureProvider.family<List<GaranteReferenciaEntity>, GaranteReferenciaEntity>(
  (ref, garanteReferencia) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarGaranteReferencia(garanteReferencia);
  },
);
final eliminarGaranteReferenciaProvider = FutureProvider.family<void, int>(
  (ref, codGarante) async {
    final repo = FichaTrabajadorImpl();
    await repo.eliminarGarRef(codGarante);
  },
);
//provider para manejar relacion laboral
final relacionLaboralProvider = FutureProvider.family<List<RelacionLaboralEntity>, int>((ref, codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  final relacionLaboral = await repo.obtenerRelEmp(codEmpleado);
  return relacionLaboral;
});  
//providers para manejar datos del empleado
final empObtenerDatosEmpleado = FutureProvider.family<EmpleadoEntity, int>((ref, codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  final empleado = await repo.obtenerDatosEmp(codEmpleado);
  return empleado.first;
});
//providers para manejar datos del empleado
final empObtenerDatosEmpleados = FutureProvider.family<int, int>((ref, codEmpleado) async {
  print('⭐ Provider empObtenerDatosEmpleados - Iniciando con codEmpleado: $codEmpleado');
  final repo = FichaTrabajadorImpl();
  final empleado = await repo.obtenerDatosEmp(codEmpleado);
  
  print('⭐ Provider empObtenerDatosEmpleados - Respuesta del repo: $empleado');
  
  if (empleado.isEmpty) {
    print('❌ Provider empObtenerDatosEmpleados - Lista vacía');
    throw Exception('No se encontró el empleado');
  }

  final codPersona = empleado.first.codPersona;
  print('⭐ Provider empObtenerDatosEmpleados - codPersona obtenido: $codPersona');
  
  return codPersona ?? (throw Exception('El empleado no tiene código de persona asociado'));
});
//provider para manejar foto del empleado
// Provider para manejar fotos
final subirFotoProvider = FutureProvider.family<bool, (int, Uint8List)>(
  (ref, params) async {
    final repository = FichaTrabajadorImpl();
    return await repository.uploadImg(params.$1, params.$2);
  },
);
final subirFotoDocProvider = FutureProvider.family<bool, (int, String, Uint8List, String)>(
  (ref, params) async {
    final repository = FichaTrabajadorImpl();
    return await repository.subirFotoDocs(
      codEmpleado: params.$1,
      tipoDocumento: params.$2,
      archivo: params.$3,
      lado: params.$4, // <--- nuevo
    );
  },
);

final imageVersionProvider = StateProvider<int>((ref) => 0);
// provider para manejar lista de personas
final personaLstProvider = FutureProvider<List<PersonaEntity>>((ref) async {
  final repo = FichaTrabajadorImpl();
  final personas = await repo.obtenerListaPersonas();
  return personas;
});
// para manejar persmisos de edición
final permissionServiceProvider = Provider<PermissionVerificationService>((ref) {
  return PermissionVerificationService(ref);
});
//provider para manejar zona
final registrarZonaProvider = FutureProvider.family<List<ZonaEntity>, ZonaEntity>(
  (ref, zona) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarZona(zona);
  },
);
final registrarCiudadProvider = FutureProvider.family<List<CiudadEntity>, CiudadEntity>(
  (ref, ciudad) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarCiudad(ciudad);
  },
);
final registrarPaisProvider = FutureProvider.family<List<PaisEntity>, PaisEntity>(
  (ref, pais) async {
    final repo = FichaTrabajadorImpl();
    return await repo.registrarPais(pais);
  },
);
final todosLosDocumentosProvider = FutureProvider.family<Map<String, List<String>>, int>((ref, codPersona) async {
  final repository = FichaTrabajadorImpl();
  return await repository.obtenerTodosLosDocumentos(codPersona);
});
final documentosPendientesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = FichaTrabajadorImpl();
  return await repo.obtenerDocumentosPendientes();
});

class WarningCounterNotifier extends StateNotifier<int> {
  final int codEmpleado;

  WarningCounterNotifier(this.codEmpleado, int initialValue) : super(initialValue);

  Future<void> increment() async {
    state++;
    
  }

  Future<void> reset() async {
    state = 0;
    
  }
}

final warningCounterProvider = StateNotifierProvider<WarningCounterNotifier, int>((ref) {
  final user = ref.watch(userProvider);
  final codEmpleado = user?.codEmpleado ?? 0;
  final initial = 0; 
  return WarningCounterNotifier(codEmpleado, initial);
});


final warningLimitProvider = Provider<int>((ref) => 5);
final warningCounterInitialProvider = Provider<int>((ref) => 0);

//reportes
final jasperPdfProvider = FutureProvider.family<Uint8List, int>((ref, codEmpleado) async {
  final repo = FichaTrabajadorImpl();
  return await repo.descargarReporteJasper(codEmpleado);
});
//cumpleaños
final cumpleanosProvider = FutureProvider<List<EmpleadoEntity>>((ref) async {
  final repo = FichaTrabajadorImpl();
  return await repo.obtenerCumples();
});
final cumpleMensajesProvider = StateProvider<List<String>>((ref) => []);

final cumpleMensajesInitProvider = FutureProvider<void>((ref) async {
  final cumpleanios = await ref.read(cumpleanosProvider.future);
  final hoy = DateTime.now();
  final mensajes = <String>[];

  for (final emp in cumpleanios) {
    if (emp.persona.fechaNacimiento.day == hoy.day &&
        emp.persona.fechaNacimiento.month == hoy.month) {
      final nacimiento = emp.persona.fechaNacimiento;
      int edad = hoy.year - nacimiento.year;
      if (hoy.month < nacimiento.month ||
          (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
        edad--;
      }
      mensajes.add(
        '🎉 ${emp.persona.datoPersona} de la Agencia: ${emp.sucursal.nombre ?? "-"} cumple $edad años'
      );
    }
  }
  ref.read(cumpleMensajesProvider.notifier).state = mensajes;
});
//bloqueo de usuario
final registrarBloqueoUsuarioProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final repo = FichaTrabajadorImpl();
  return await repo.registrarAdvertenciaUsuario(
    codUsuario: data['codUsuario'] as int,
    fechaAdvertencia: data['fechaAdvertencia'] as DateTime,
    fechaLimite: data['fechaLimite'] as DateTime,
    bloqueado: data['bloqueado'] as int,
    audUsuario: data['audUsuario'] as int,
  );
});
//desbloqueo de usuario
final desbloquearUsuarioProvider = FutureProvider.family<bool, int>((ref, codUsuario) async {
  final repo = FichaTrabajadorImpl();
  return await repo.desbloquearUsuario(codUsuario: codUsuario);
});
//ver usuario bloqueado
final usuarioBloqueadoProvider = FutureProvider.family<UsuarioBloqueadoEntity, int>((ref, codUsuario) async {
  final repo = FichaTrabajadorImpl();
  return await repo.obtenerUsuarioBloqueado(codUsuario);
});
//Reporte de los dependientes
final jasperPdfDependientesXEdad = FutureProvider<Uint8List>((ref) async {
  final repo = FichaTrabajadorImpl();
  return await repo.descargarRptDependientesXEdad();
});
//REPORTE DEPENDIENTES SOLO HIJOS
final jasperPdfDependientesHijos = FutureProvider<Uint8List>((ref) async {
  final repo = FichaTrabajadorImpl();
  return await repo.descargarRptDependientesHijos();
});