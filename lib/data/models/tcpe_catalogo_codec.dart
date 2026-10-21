/// Cómo pasa cada entidad del CRUD genérico de exámenes de JSON a entity y
/// de vuelta, siempre por su model (`JSON → Model → Entity` y al revés).
library;

import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/data/models/tcpe_area_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_area_post_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_post_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_capacitacion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_capacitacion_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_capacitador_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_capacitador_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_clasificacion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_conocimientos_post_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_conocimientos_post_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_conocimientos_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_conocimientos_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_convocatoria_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_convocatoria_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_curso_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_curso_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_dpto_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_dpto_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_empleado_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_examen_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_examen_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_experiencia_lab_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_experiencia_lab_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_fases_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fases_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_formacion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_formacion_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_historial_post_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_post_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_inscripcion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_inscripcion_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_otros_conocimientos_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_otros_conocimientos_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_persona_post_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_post_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_postulacion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_postulacion_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_h_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_h_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_semana_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_registro_examen_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_registro_examen_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_req_academico_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_academico_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_req_academico_post_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_academico_post_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_req_exp_lab_post_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_exp_lab_post_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_respuesta_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respuesta_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_respuesta_h_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respuesta_h_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_rol_examen_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rol_examen_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_rspta_opcion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_rspta_opcion_h_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_h_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_rspta_opcion_u_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_u_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_rspta_semana_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_semana_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_seleccion_fase_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_seleccion_fase_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_seleccion_preguntas_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_seleccion_preguntas_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_temario_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_temario_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_tipo_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_tipo_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_tipo_usuario_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_tipo_usuario_entity.dart';
import 'package:bosque_flutter/data/models/tcpe_usuario_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';

class TcpeCodec<E> {
  final E Function(Map<String, dynamic> json) desdeJson;
  final Map<String, dynamic> Function(E entidad) aJson;
  final BigInt Function(E entidad) idDe;

  const TcpeCodec({required this.desdeJson, required this.aJson, required this.idDe});
}

final Map<String, TcpeCodec<Object>> _codecs = {
  'area': TcpeCodec<TcpeAreaEntity>(
    desdeJson: (j) => TcpeAreaModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeAreaModel.fromEntity(e).toJson(),
    idDe: (e) => e.codArea,
  ),
  'areaPost': TcpeCodec<TcpeAreaPostEntity>(
    desdeJson: (j) => TcpeAreaPostModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeAreaPostModel.fromEntity(e).toJson(),
    idDe: (e) => e.codAreaPost,
  ),
  'capacitacion': TcpeCodec<TcpeCapacitacionEntity>(
    desdeJson: (j) => TcpeCapacitacionModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeCapacitacionModel.fromEntity(e).toJson(),
    idDe: (e) => e.codCapacitacion,
  ),
  'capacitador': TcpeCodec<TcpeCapacitadorEntity>(
    desdeJson: (j) => TcpeCapacitadorModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeCapacitadorModel.fromEntity(e).toJson(),
    idDe: (e) => e.codCapacitador,
  ),
  'clasificacion': TcpeCodec<TcpeClasificacionEntity>(
    desdeJson: (j) => TcpeClasificacionModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeClasificacionModel.fromEntity(e).toJson(),
    idDe: (e) => e.codClasificacion,
  ),
  'conocimientosPost': TcpeCodec<TcpeConocimientosPostEntity>(
    desdeJson: (j) => TcpeConocimientosPostModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeConocimientosPostModel.fromEntity(e).toJson(),
    idDe: (e) => e.codConocimiento,
  ),
  'conocimientos': TcpeCodec<TcpeConocimientosEntity>(
    desdeJson: (j) => TcpeConocimientosModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeConocimientosModel.fromEntity(e).toJson(),
    idDe: (e) => e.codConocimiento,
  ),
  'convocatoria': TcpeCodec<TcpeConvocatoriaEntity>(
    desdeJson: (j) => TcpeConvocatoriaModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeConvocatoriaModel.fromEntity(e).toJson(),
    idDe: (e) => e.codConvocatoria,
  ),
  'curso': TcpeCodec<TcpeCursoEntity>(
    desdeJson: (j) => TcpeCursoModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeCursoModel.fromEntity(e).toJson(),
    idDe: (e) => e.codCurso,
  ),
  'dpto': TcpeCodec<TcpeDptoEntity>(
    desdeJson: (j) => TcpeDptoModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeDptoModel.fromEntity(e).toJson(),
    idDe: (e) => e.codDpto,
  ),
  'empleado': TcpeCodec<TcpeEmpleadoEntity>(
    desdeJson: (j) => TcpeEmpleadoModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeEmpleadoModel.fromEntity(e).toJson(),
    idDe: (e) => e.codEmpleado,
  ),
  'examen': TcpeCodec<TcpeExamenEntity>(
    desdeJson: (j) => TcpeExamenModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeExamenModel.fromEntity(e).toJson(),
    idDe: (e) => e.codExamen,
  ),
  'experienciaLab': TcpeCodec<TcpeExperienciaLabEntity>(
    desdeJson: (j) => TcpeExperienciaLabModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeExperienciaLabModel.fromEntity(e).toJson(),
    idDe: (e) => e.codExpLab,
  ),
  'fases': TcpeCodec<TcpeFasesEntity>(
    desdeJson: (j) => TcpeFasesModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeFasesModel.fromEntity(e).toJson(),
    idDe: (e) => e.codFase,
  ),
  'formacion': TcpeCodec<TcpeFormacionEntity>(
    desdeJson: (j) => TcpeFormacionModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeFormacionModel.fromEntity(e).toJson(),
    idDe: (e) => e.codFormacion,
  ),
  'historialPost': TcpeCodec<TcpeHistorialPostEntity>(
    desdeJson: (j) => TcpeHistorialPostModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeHistorialPostModel.fromEntity(e).toJson(),
    idDe: (e) => e.codHistorialPost,
  ),
  'inscripcion': TcpeCodec<TcpeInscripcionEntity>(
    desdeJson: (j) => TcpeInscripcionModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeInscripcionModel.fromEntity(e).toJson(),
    idDe: (e) => e.codInscripcion,
  ),
  'otrosConocimientos': TcpeCodec<TcpeOtrosConocimientosEntity>(
    desdeJson: (j) => TcpeOtrosConocimientosModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeOtrosConocimientosModel.fromEntity(e).toJson(),
    idDe: (e) => e.codOtrosCono,
  ),
  'personaPost': TcpeCodec<TcpePersonaPostEntity>(
    desdeJson: (j) => TcpePersonaPostModel.fromJson(j).toEntity(),
    aJson: (e) => TcpePersonaPostModel.fromEntity(e).toJson(),
    idDe: (e) => e.codPersonaPost,
  ),
  'postulacion': TcpeCodec<TcpePostulacionEntity>(
    desdeJson: (j) => TcpePostulacionModel.fromJson(j).toEntity(),
    aJson: (e) => TcpePostulacionModel.fromEntity(e).toJson(),
    idDe: (e) => e.codPostulacion,
  ),
  'pregunta': TcpeCodec<TcpePreguntaEntity>(
    desdeJson: (j) => TcpePreguntaModel.fromJson(j).toEntity(),
    aJson: (e) => TcpePreguntaModel.fromEntity(e).toJson(),
    idDe: (e) => e.codPregunta,
  ),
  'preguntaH': TcpeCodec<TcpePreguntaHEntity>(
    desdeJson: (j) => TcpePreguntaHModel.fromJson(j).toEntity(),
    aJson: (e) => TcpePreguntaHModel.fromEntity(e).toJson(),
    idDe: (e) => e.codPreguntaH,
  ),
  'preguntaSemana': TcpeCodec<TcpePreguntaSemanaEntity>(
    desdeJson: (j) => TcpePreguntaSemanaModel.fromJson(j).toEntity(),
    aJson: (e) => TcpePreguntaSemanaModel.fromEntity(e).toJson(),
    idDe: (e) => e.codPreguntaSemana,
  ),
  'registroExamen': TcpeCodec<TcpeRegistroExamenEntity>(
    desdeJson: (j) => TcpeRegistroExamenModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRegistroExamenModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRegExamen,
  ),
  'reqAcademico': TcpeCodec<TcpeReqAcademicoEntity>(
    desdeJson: (j) => TcpeReqAcademicoModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeReqAcademicoModel.fromEntity(e).toJson(),
    idDe: (e) => e.codReqAcademico,
  ),
  'reqAcademicoPost': TcpeCodec<TcpeReqAcademicoPostEntity>(
    desdeJson: (j) => TcpeReqAcademicoPostModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeReqAcademicoPostModel.fromEntity(e).toJson(),
    idDe: (e) => e.codReqAcaPost,
  ),
  'reqExpLabPost': TcpeCodec<TcpeReqExpLabPostEntity>(
    desdeJson: (j) => TcpeReqExpLabPostModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeReqExpLabPostModel.fromEntity(e).toJson(),
    idDe: (e) => e.codExpLabPost,
  ),
  'respuesta': TcpeCodec<TcpeRespuestaEntity>(
    desdeJson: (j) => TcpeRespuestaModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRespuestaModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRespuesta,
  ),
  'respuestaH': TcpeCodec<TcpeRespuestaHEntity>(
    desdeJson: (j) => TcpeRespuestaHModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRespuestaHModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRespuestaH,
  ),
  'rolExamen': TcpeCodec<TcpeRolExamenEntity>(
    desdeJson: (j) => TcpeRolExamenModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRolExamenModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRolExamen,
  ),
  'rsptaOpcion': TcpeCodec<TcpeRsptaOpcionEntity>(
    desdeJson: (j) => TcpeRsptaOpcionModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRsptaOpcionModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRsptaOp,
  ),
  'rsptaOpcionH': TcpeCodec<TcpeRsptaOpcionHEntity>(
    desdeJson: (j) => TcpeRsptaOpcionHModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRsptaOpcionHModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRsptaOpH,
  ),
  'rsptaOpcionU': TcpeCodec<TcpeRsptaOpcionUEntity>(
    desdeJson: (j) => TcpeRsptaOpcionUModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRsptaOpcionUModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRsptaOpU,
  ),
  'rsptaSemana': TcpeCodec<TcpeRsptaSemanaEntity>(
    desdeJson: (j) => TcpeRsptaSemanaModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeRsptaSemanaModel.fromEntity(e).toJson(),
    idDe: (e) => e.codRsptaSemana,
  ),
  'seleccionFase': TcpeCodec<TcpeSeleccionFaseEntity>(
    desdeJson: (j) => TcpeSeleccionFaseModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeSeleccionFaseModel.fromEntity(e).toJson(),
    idDe: (e) => e.codSeleccionFase,
  ),
  'seleccionPreguntas': TcpeCodec<TcpeSeleccionPreguntasEntity>(
    desdeJson: (j) => TcpeSeleccionPreguntasModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeSeleccionPreguntasModel.fromEntity(e).toJson(),
    idDe: (e) => e.codSeleccionPreguntas,
  ),
  'temario': TcpeCodec<TcpeTemarioEntity>(
    desdeJson: (j) => TcpeTemarioModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeTemarioModel.fromEntity(e).toJson(),
    idDe: (e) => e.codTemario,
  ),
  'tipo': TcpeCodec<TcpeTipoEntity>(
    desdeJson: (j) => TcpeTipoModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeTipoModel.fromEntity(e).toJson(),
    idDe: (e) => e.codTipo,
  ),
  'tipoUsuario': TcpeCodec<TcpeTipoUsuarioEntity>(
    desdeJson: (j) => TcpeTipoUsuarioModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeTipoUsuarioModel.fromEntity(e).toJson(),
    idDe: (e) => e.codTipoUsuario,
  ),
  'usuario': TcpeCodec<TcpeUsuarioEntity>(
    desdeJson: (j) => TcpeUsuarioModel.fromJson(j).toEntity(),
    aJson: (e) => TcpeUsuarioModel.fromEntity(e).toJson(),
    idDe: (e) => e.codUsuario,
  ),
};

/// El codec de [catalogo]. Hay uno por cada entrada de [TcpeCatalogo.todos].
TcpeCodec<E> codecTcpe<E>(TcpeCatalogo<E> catalogo) =>
    _codecs[catalogo.entidad]! as TcpeCodec<E>;
