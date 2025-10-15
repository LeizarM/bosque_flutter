import 'package:bosque_flutter/data/models/Persona_model.dart';
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
import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_garante_referencia_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/usuario_bloqueado_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';

abstract class FichaTrabajadorRepository{
  Future<List<EmpleadoEntity>>obtenerListaEmpleadoyDependientes(int codEmpleado); 
  
  Future<List<DependienteEntity>>getDependientes(int codEmpleado);
  Future<List<DependienteEntity>>editarDep(DependienteEntity dep);
  Future<List<ParentescoEntity>>obtenerParentesco();
  Future<bool>eliminarDependiente(int codDependiente);

  Future<List<EmpleadoEntity>>obtenerDatosEmp(int codEmpleado);
  Future<List<EmpleadoEntity>>obtenerCumples();

 

  Future<PersonaEntity>obtenerPersona(int codPersona);
  Future<PersonaEntity>editarPersona(PersonaEntity per);
  Future<PersonaEntity>registrarPersona(PersonaModel persona);

  Future<List<PersonaEntity>>obtenerListaPersonas();
  

  Future<List<SexoEntity>>obtenerGenero();
  Future<List<EstadoCivilEntity>>obtenerEstadoCivil();
  Future<List<CiExpedidoEntity>>obtenerCiExp();
  Future<List<PaisEntity>>obtenerPais();
  Future<List<CiudadEntity>>obtenerCiudad(int codPais);
  Future<List<ZonaEntity>>obtenerZona(int codCiudad);

  //para tipos formacion
  Future<List<TipoFormacionEntity>>obtenerTipoFormacion();
  Future<List<TipoDuracionFormacionEntity>>obtenerTipoDuracionFor();
  //para tipos gar ref
  Future<List<TipoGaranteReferenciaEntity>>obtenerTipoGaranteRef();
  Future<List<GaranteReferenciaEntity>>obtenerListaGarRef();
  Future<bool>eliminarGarRef(int codgarante);



  Future<List<FormacionEntity>>obtenerFormacion(int codEmpleado);
  Future<List<FormacionEntity>>registrarFormacion(FormacionEntity fr);
  Future<bool>eliminarFormacion(int codFormacion);

  Future<List<TelefonoEntity>>obtenerTelefono(int codPersona);
  Future<List<TelefonoEntity>>registrarTelefono(TelefonoEntity tel);
  Future<bool>eliminarTelefono(int codTelefono);
  Future<List<TipoTelefonoEntity>>obtenerTipoTelefono();

  Future<List<ExperienciaLaboralEntity>> obtenerExperienciaLaboral(int codEmpleado);
  Future<List<ExperienciaLaboralEntity>>registrarExpLaboral(ExperienciaLaboralEntity expl);
  Future<bool>eliminarExpLab(int codExperienciaLaboral);


  Future<List<EmailEntity>> obtenerEmail(int codPersona);
  Future<List<EmailEntity>> registrarEmail(EmailEntity email);
  Future<bool> eliminarEmail(int codEmail);

  Future<List<GaranteReferenciaEntity>> obtenerGaranteReferencia(int codEmpleado);
  Future<List<GaranteReferenciaEntity>> registrarGaranteReferencia(GaranteReferenciaEntity garRef);

  Future<List<RelacionLaboralEntity>> registrarRelEmp(RelacionLaboralEntity ree);
  Future<List<RelacionLaboralEntity>> obtenerRelEmp(int codEmpleado);

  Future<bool> uploadImg(int codEmpleado, dynamic imagen);
  Future<List<ZonaEntity>> registrarZona(ZonaEntity zona);
  Future<List<CiudadEntity>> registrarCiudad(CiudadEntity ciudad);
  Future<List<PaisEntity>> registrarPais(PaisEntity pais);
  Future<Map<String, List<String>>> obtenerTodosLosDocumentos(int codPersona);
  Future<List<Map<String, dynamic>>> obtenerDocumentosPendientes();
  Future<void> rechazarDocumentoPendiente(Map<String, dynamic> doc);
  Future<void> aprobarDocumentoPendiente(Map<String, dynamic> doc);
  Future<bool> desbloquearUsuario({required int codUsuario});
  Future<UsuarioBloqueadoEntity> obtenerUsuarioBloqueado(int codUsuario);
}