import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/automatizacion_model.dart';
import 'package:bosque_flutter/data/models/cambio_model.dart';
import 'package:bosque_flutter/data/models/celda_turno_model.dart';
import 'package:bosque_flutter/data/models/convocatoria_model.dart';
import 'package:bosque_flutter/data/models/cumple_sabado_model.dart';
import 'package:bosque_flutter/data/models/estado_turno_model.dart';
import 'package:bosque_flutter/data/models/intervencion_model.dart';
import 'package:bosque_flutter/data/models/mi_equipo_model.dart';
import 'package:bosque_flutter/data/models/participante_turno_model.dart';
import 'package:bosque_flutter/data/models/permiso_sabado_model.dart';
import 'package:bosque_flutter/data/models/programacion_model.dart';
import 'package:bosque_flutter/data/models/programador_dependiente_model.dart';
import 'package:bosque_flutter/data/models/programador_model.dart';
import 'package:bosque_flutter/data/models/puente_vacacion_model.dart';
import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/data/models/rrhh_sabados_model.dart';
import 'package:bosque_flutter/data/models/rol_sabados_model.dart';
import 'package:bosque_flutter/data/models/sabado_model.dart';
import 'package:bosque_flutter/domain/entities/automatizacion_entity.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/convocatoria_entity.dart';
import 'package:bosque_flutter/domain/entities/cumple_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/intervencion_entity.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/permiso_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/programacion_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_entity.dart';
import 'package:bosque_flutter/domain/entities/puente_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/rrhh_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/rol_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/domain/repositories/rol_sabados_repository.dart';

class RolSabadosImpl extends BaseApiRepository implements RolSabadosRepository {
  // ══════════════════════════════════════════════════════════════════════
  // LECTURAS
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<List<RolSabadosEntity>> getRoles({
    int codSucursal = 0,
    int anio = 0,
  }) async {
    final r = await postAndReturnList<RolSabadosModel>(
      endpoint: AppConstants.rolSabObtenerRoles,
      data: {'codSucursal': codSucursal, 'anio': anio},
      fromJson: RolSabadosModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<SabadoEntity>> getSabados(int idRol) async {
    final r = await postAndReturnList<SabadoModel>(
      endpoint: AppConstants.rolSabObtenerSabados,
      data: {'idRol': idRol},
      fromJson: SabadoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<ParticipanteTurnoEntity>> getParticipantes(
    int idRol, {
    int activo = 1,
  }) async {
    final r = await postAndReturnList<ParticipanteTurnoModel>(
      endpoint: AppConstants.rolSabObtenerParticipantes,
      data: {'idRol': idRol, 'activo': activo},
      fromJson: ParticipanteTurnoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<CeldaTurnoEntity>> getAsignaciones(
    int idRol, {
    int idSabado = 0,
  }) async {
    final r = await postAndReturnList<CeldaTurnoModel>(
      endpoint: AppConstants.rolSabObtenerAsignaciones,
      data: {'idRol': idRol, 'idSabado': idSabado},
      fromJson: CeldaTurnoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<EstadoTurnoEntity>> getEstadosTurno() async {
    // Este endpoint no recibe body: el catálogo es uno solo.
    final r = await postAndReturnList<EstadoTurnoModel>(
      endpoint: AppConstants.rolSabObtenerEstadosTurno,
      fromJson: EstadoTurnoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<ParticipanteTurnoEntity>> getTurnosPorParticipante(
    int idRol,
  ) async {
    final r = await postAndReturnList<ParticipanteTurnoModel>(
      endpoint: AppConstants.rolSabObtenerTurnosPorParticipante,
      data: {'idRol': idRol},
      fromJson: ParticipanteTurnoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<SabadoEntity>> getCobertura(int idRol, {int mes = 0}) async {
    final r = await postAndReturnList<SabadoModel>(
      endpoint: AppConstants.rolSabObtenerCobertura,
      data: {'idRol': idRol, 'mes': mes},
      fromJson: SabadoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<SabadoEntity>> getFeriadosDesincronizados(int idRol) async {
    final r = await postAndReturnList<SabadoModel>(
      endpoint: AppConstants.rolSabObtenerFeriadosDesincronizados,
      data: {'idRol': idRol},
      fromJson: SabadoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  /// **No usa `postAndReturnList` a propósito.** Ese camino parsea la respuesta
  /// como JSON y devuelve modelos; acá el cuerpo es un PDF binario. Se baja con
  /// el helper de siempre para reportes Jasper, que pide `ResponseType.bytes`
  /// y comparte el interceptor del token con el resto de la app.
  @override
  Future<Uint8List> getReporteSabadoPdf(int idSabado) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.rolSabReporteSabado,
        data: {'idSabado': idSabado},
      );

  // ══════════════════════════════════════════════════════════════════════
  // ESCRITURAS
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<int> generarRol({
    required int anio,
    int codSucursal = 0,
    int codEmpresa = 0,
    String modo = 'CREAR',
    required int audUsuario,
  }) async {
    // 0 significa "sin filtrar" y el backend lo espera como null, no como 0:
    // un codSucursal=0 no existe en tb_sucursal y haría fallar la validación.
    final id = await postAndReturnId(
      endpoint: AppConstants.rolSabGenerarRol,
      data: {
        'anio': anio,
        'codSucursal': codSucursal == 0 ? null : codSucursal,
        'codEmpresa': codEmpresa == 0 ? null : codEmpresa,
        'modo': modo,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al generar el rol',
    );
    return id.toInt();
  }

  @override
  Future<void> corregirCelda({
    required int idParticipante,
    required int idSabado,
    required String codigoExcel,
    String observacion = '',
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabCorregirCelda,
      data: {
        'idParticipante': idParticipante,
        'idSabado': idSabado,
        'codigoExcel': codigoExcel,
        'observacion': observacion,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al corregir la celda',
    );
  }

  @override
  Future<void> liberarCelda({
    required int idParticipante,
    required int idSabado,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabLiberarCelda,
      // El par persona+sábado, no el idAsignacion: es lo que espera
      // trs_sp_corregirCelda, al que delega el ABM.
      data: {
        'idParticipante': idParticipante,
        'idSabado': idSabado,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al liberar la celda',
    );
  }

  @override
  Future<void> marcarEvento({
    required int idSabado,
    String? alcanceEvento,
    String motivoEspecial = '',
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabMarcarEvento,
      data: {
        'idSabado': idSabado,
        // null acá NO es "no cambiar": es "volvé a ser un sábado normal".
        'alcanceEvento': alcanceEvento,
        'motivoEspecial': motivoEspecial,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al marcar el evento',
    );
  }

  @override
  Future<void> refrescarFeriados({
    required int idRol,
    bool soloInformar = false,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabRefrescarFeriados,
      data: {
        'idRol': idRol,
        // El backend lee la simulación de este campo; ver RolSabadosController.
        'observacion': soloInformar ? 'INFORMAR' : '',
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al refrescar los feriados',
    );
  }

  @override
  Future<void> cambiarEstadoRol({
    required int idRol,
    required String estado,
    required int aplicaAsuetoCumple,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabRegistrarRol,
      // Se manda lo MÍNIMO y nada más. El SP actualiza cada columna con
      // `ISNULL(@campo, campo)`, así que lo que no viaja queda como estaba: el
      // nombre, las metas A/B y la cobertura objetivo no se tocan.
      //
      // La excepción es `aplicaAsuetoCumple`, y por eso va explícito: del lado
      // Java es un `int` primitivo inicializado en 1 —no un `Integer`— así que
      // NO puede llegar como null. Omitirlo lo manda en 1 igual, y un rol que
      // tuviera el asueto por cumpleaños apagado se prendería solo al
      // publicarlo. Se reenvía el valor actual: el UPDATE lo pisa con lo mismo.
      data: {
        'idRol': idRol,
        'estado': estado,
        'aplicaAsuetoCumple': aplicaAsuetoCumple,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al cambiar el estado del rol',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CAMBIOS · PROGRAMACIONES · CONVOCATORIA
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<List<CambioEntity>> getCambios(int idRol, {String estado = ''}) async {
    final r = await postAndReturnList<CambioModel>(
      endpoint: AppConstants.rolSabObtenerCambios,
      data: {'idRol': idRol, 'estado': estado},
      fromJson: CambioModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<ProgramacionEntity>> getProgramaciones(
    int idRol, {
    int idSabado = 0,
  }) async {
    final r = await postAndReturnList<ProgramacionModel>(
      endpoint: AppConstants.rolSabObtenerProgramaciones,
      data: {'idRol': idRol, 'idSabado': idSabado},
      fromJson: ProgramacionModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<ConvocatoriaEntity>> getDetalleEvento(int idSabado) async {
    final r = await postAndReturnList<ConvocatoriaModel>(
      endpoint: AppConstants.rolSabObtenerDetalleEvento,
      data: {'idSabado': idSabado},
      fromJson: ConvocatoriaModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  // ══════════════════════════════════════════════════════════════════════
  // CONTROLES
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<List<IntervencionEntity>> getIntervenciones(int idRol) async {
    final r = await postAndReturnList<IntervencionModel>(
      endpoint: AppConstants.rolSabObtenerIntervenciones,
      data: {'idRol': idRol},
      fromJson: IntervencionModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<CumpleSabadoEntity>> getCumplesSabado(int idRol) async {
    final r = await postAndReturnList<CumpleSabadoModel>(
      endpoint: AppConstants.rolSabObtenerCumplesSabado,
      data: {'idRol': idRol},
      fromJson: CumpleSabadoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<AutomatizacionEntity?> getAutomatizacion(int idRol) async {
    final r = await postAndReturnObject<AutomatizacionModel>(
      endpoint: AppConstants.rolSabObtenerAutomatizacion,
      data: {'idRol': idRol},
      fromJson: AutomatizacionModel.fromJson,
      errorMessage: 'Error al leer la automatización',
    );
    return r?.toEntity();
  }

  // ══════════════════════════════════════════════════════════════════════
  // ESCRITURAS NUEVAS
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<int> registrarCambio({
    required int idRol,
    required int idSabado,
    required int codEmpleadoTitular,
    int codEmpleadoReemplazo = 0,
    int idSabadoReposicion = 0,
    required String tipo,
    String motivo = '',
    required int audUsuario,
  }) async {
    final id = await postAndReturnId(
      endpoint: AppConstants.rolSabRegistrarCambio,
      data: {
        'idRol': idRol,
        'idSabado': idSabado,
        'codEmpleadoTitular': codEmpleadoTitular,
        // Una COBERTURA puede no tener a nadie que cubra todavía; 0 no es un
        // empleado válido y rompería la FK, así que va null.
        'codEmpleadoReemplazo':
            codEmpleadoReemplazo == 0 ? null : codEmpleadoReemplazo,
        'idSabadoReposicion':
            idSabadoReposicion == 0 ? null : idSabadoReposicion,
        'tipo': tipo,
        'motivo': motivo,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al registrar el cambio',
    );
    return id.toInt();
  }

  @override
  Future<void> aprobarCambio({
    required int idCambio,
    required int codAprobador,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabAprobarCambio,
      data: {
        'idCambio': idCambio,
        'codAprobador': codAprobador,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al aprobar el cambio',
    );
  }

  @override
  Future<void> anularCambio({
    required int idCambio,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabAnularCambio,
      data: {'idCambio': idCambio, 'audUsuario': audUsuario},
      errorMessage: 'Error al anular el cambio',
    );
  }

  @override
  Future<void> asignarGrupo({
    required int idParticipante,
    required String grupoRotacion,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabAsignarGrupo,
      data: {
        'idParticipante': idParticipante,
        'grupoRotacion': grupoRotacion,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al cambiar el grupo',
    );
  }

  @override
  Future<void> sacarDeSabados({
    required int idParticipante,
    required DateTime fechaBaja,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabSacarDeSabados,
      data: {
        'idParticipante': idParticipante,
        'fechaBaja': _dia(fechaBaja),
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al sacar de los sabados',
    );
  }

  @override
  Future<void> reincorporar({
    required int idParticipante,
    required DateTime fechaAlta,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabReincorporar,
      data: {
        'idParticipante': idParticipante,
        'fechaAlta': _dia(fechaAlta),
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al devolver a los sabados',
    );
  }

  @override
  Future<List<PermisoSabadoEntity>> getDesfasesPermiso(int idRol) async {
    final r = await postAndReturnList<PermisoSabadoModel>(
      endpoint: AppConstants.rolSabObtenerDesfasesPermiso,
      data: {'idRol': idRol},
      fromJson: PermisoSabadoModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> refrescarPermisos({
    required int idRol,
    bool soloInformar = false,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabRefrescarPermisos,
      data: {
        'idRol': idRol,
        'observacion': soloInformar ? 'INFORMAR' : '',
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al cruzar las vacaciones y permisos',
    );
  }

  @override
  Future<void> convocar({
    required int idSabado,
    required String tipo,
    int codEmpleado = 0,
    int codEmpleadoJefe = 0,
    int codCargo = 0,
    String motivo = '',
    required int audUsuario,
  }) async {
    // El backend exige EXACTAMENTE uno de los tres: si van dos, el SP aplica
    // el primero y el otro se pierde en silencio. Por eso los ceros van null.
    await postAndReturnId(
      endpoint: AppConstants.rolSabConvocar,
      data: {
        'idSabado': idSabado,
        'tipo': tipo,
        'codEmpleado': codEmpleado == 0 ? null : codEmpleado,
        'codEmpleadoJefe': codEmpleadoJefe == 0 ? null : codEmpleadoJefe,
        'codCargo': codCargo == 0 ? null : codCargo,
        'motivo': motivo,
        'codEmpleadoAutoriza': audUsuario,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al convocar',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SU EQUIPO
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<MiEquipoEntity> getMiEquipo() async {
    final r = await postAndReturnObject<MiEquipoModel>(
      endpoint: AppConstants.rolSabMiEquipo,
      // Sin body: la identidad la resuelve el servidor con el token. Mandarle
      // un codEmpleado sería ofrecerle al cliente elegir de quién es el equipo.
      data: const {},
      fromJson: MiEquipoModel.fromJson,
      errorMessage: 'Error al leer tu equipo',
    );
    // null = 204, o un backend que todavía no tiene el endpoint. En los dos
    // casos la respuesta correcta es «no sos programador»: la pestaña no
    // aparece y nadie ve un error que no puede resolver.
    return r?.toEntity() ?? MiEquipoEntity.vacio;
  }

  @override
  Future<void> programar({
    required int idSabado,
    required int codEmpleadoDependiente,
    required String codigoExcel,
    String motivo = '',
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabProgramar,
      // Van sólo los cuatro datos de la decisión: quién programa lo pone el
      // controller con el token, y pisa cualquier cosa que mandemos de más.
      data: {
        'idSabado': idSabado,
        'codEmpleadoDependiente': codEmpleadoDependiente,
        'codigoExcel': codigoExcel,
        'motivo': motivo,
      },
      errorMessage: 'Error al programar el sábado',
    );
  }

  @override
  Future<List<ProgramadorEntity>> getProgramadores({
    int codSucursal = 0,
    String estado = 'A',
  }) async {
    final r = await postAndReturnList<ProgramadorModel>(
      endpoint: AppConstants.rolSabObtenerProgramadores,
      data: {'codSucursal': codSucursal, 'estado': estado},
      fromJson: ProgramadorModel.fromJson,
    );
    return r.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> registrarProgramador({
    required int idProgramador,
    required int codEmpleado,
    int codSucursal = 0,
    String alcance = 'DIRECTOS',
    int codEmpleadoReemplazo = 0,
    String observacion = '',
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabRegistrarProgramador,
      data: {
        'idProgramador': idProgramador,
        'codEmpleado': codEmpleado,
        // Las dos son FK nullables: 0 no existe ni en tb_sucursal ni en
        // tb_empleado y haría fallar la validación del SP.
        'codSucursal': codSucursal == 0 ? null : codSucursal,
        // OJO con el reemplazo: en la rama 'U' el SP lo toma con ISNULL, así
        // que null significa «dejalo como está», NO «borralo». Hoy no hay forma
        // de sacarle el reemplazo a alguien desde acá; si algún día hace falta,
        // el cambio va en el SP y no en esta línea.
        'codEmpleadoReemplazo':
            codEmpleadoReemplazo == 0 ? null : codEmpleadoReemplazo,
        'alcance': alcance,
        'observacion': observacion,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al registrar al programador',
    );
  }

  @override
  Future<void> eliminarProgramador({
    required int idProgramador,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabEliminarProgramador,
      data: {'idProgramador': idProgramador, 'audUsuario': audUsuario},
      errorMessage: 'Error al dar de baja al programador',
    );
  }

  @override
  Future<List<ProgramadorDependienteEntity>> previsualizarDependientes({
    required int codEmpleado,
    required int codSucursal,
    required String alcance,
    required int idRol,
  }) async {
    final r = await postAndReturnList<ProgramadorDependienteModel>(
      endpoint: AppConstants.rolSabPrevisualizarDependientes,
      data: {
        'codEmpleado': codEmpleado,
        // El 0 viaja tal cual y el SP lo traduce con NULLIF: allá 0 y NULL
        // significan lo mismo que en `trs_Programador.codSucursal`, o sea TODAS.
        // Se deja el mismo idioma a los dos lados para que lo que se
        // previsualiza sea, campo por campo, lo que después se guarda.
        'codSucursal': codSucursal,
        'alcance': alcance,
        'idRol': idRol,
      },
      fromJson: ProgramadorDependienteModel.fromJson,
    );
    return r.map((m) => m.toEntity()).toList();
  }

  // ── El padrón de RR.HH. ───────────────────────────────────────────────

  @override
  Future<List<RrhhSabadosEntity>> getRrhh({String estado = ''}) async {
    final r = await postAndReturnList<RrhhSabadosModel>(
      endpoint: AppConstants.rolSabObtenerRrhh,
      data: {'estado': estado},
      fromJson: RrhhSabadosModel.fromJson,
    );
    return r.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarRrhh({
    required int idRrhh,
    required int codEmpleado,
    String observacion = '',
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabRegistrarRrhh,
      data: {
        'idRrhh': idRrhh,
        'codEmpleado': codEmpleado,
        'observacion': observacion,
        'audUsuario': audUsuario,
      },
      errorMessage: 'Error al agregar a RR.HH.',
    );
  }

  @override
  Future<void> eliminarRrhh({
    required int idRrhh,
    required int audUsuario,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.rolSabEliminarRrhh,
      data: {'idRrhh': idRrhh, 'audUsuario': audUsuario},
      errorMessage: 'Error al sacar de RR.HH.',
    );
  }

  // ── Puente a cuenta de vacación ───────────────────────────────────────

  /// El cuerpo de las dos llamadas. Las horas y el motivo vacíos **no se
  /// mandan**: así el SP aplica su propio default en vez de recibir una cadena
  /// vacía, que rebotaría como hora inválida.
  Map<String, dynamic> _cuerpoPuente(
    int idSabado,
    String horaDesde,
    String horaHasta,
    String motivo,
  ) => {
    'idSabado': idSabado,
    if (horaDesde.trim().isNotEmpty) 'horaDesde': horaDesde.trim(),
    if (horaHasta.trim().isNotEmpty) 'horaHasta': horaHasta.trim(),
    if (motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
  };

  @override
  Future<List<PuenteVacacionEntity>> simularPuente({
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  }) async {
    final r = await postAndReturnList<PuenteVacacionModel>(
      endpoint: AppConstants.rolSabSimularPuente,
      data: _cuerpoPuente(idSabado, horaDesde, horaHasta, motivo),
      fromJson: PuenteVacacionModel.fromJson,
    );
    return r.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> aplicarPuente({
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  }) async {
    // `postAndReturnFullResponse` y no `postAndReturnId`: acá el `message` del
    // servidor ES el resultado —«42 permisos por 18.375 días, se saltearon 3»—
    // y con el id solo no habría forma de contarle a nadie qué pasó.
    final r = await postAndReturnFullResponse<Map<String, dynamic>>(
      endpoint: AppConstants.rolSabAplicarPuente,
      data: _cuerpoPuente(idSabado, horaDesde, horaHasta, motivo),
      fromJson: (json) => json,
      errorMessage: 'Error al aplicar el puente',
    );
    return rsStr(r['message']);
  }
}

/// `yyyy-MM-dd`, que es lo que la ventana de sábados necesita: un día, no un
/// instante.
///
/// Con `toIso8601String()` viajaría también la hora en horario local y del otro
/// lado la columna es `date`: un `2026-07-04T00:00:00` de un dispositivo con el
/// reloj corrido termina siendo el 3 de julio, y el corte se movería un sábado.
/// Sin `intl`, igual que el `fechaCorta` del módulo.
String _dia(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-'
    '${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')}';
