/// Las 40 entidades `tcpe_*` del CRUD genérico `/examenes/catalogo/{entidad}`.
/// [entidad] es la tabla sin `tcpe_` en camelCase y debe coincidir con el
/// backend (con otra mayúscula la ruta no existe); [filtros] es el `p_list`.
library;

import 'package:bosque_flutter/domain/entities/tcpe_area_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_post_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_capacitacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_capacitador_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_conocimientos_post_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_conocimientos_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_convocatoria_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_curso_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_dpto_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_experiencia_lab_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fases_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_post_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_inscripcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_otros_conocimientos_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_post_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_postulacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_h_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_registro_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_academico_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_academico_post_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_exp_lab_post_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respuesta_h_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rol_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_h_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_u_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_seleccion_fase_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_seleccion_preguntas_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_temario_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_tipo_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_tipo_usuario_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';

class TcpeCatalogo<E> {
  final String entidad;
  final String pk;
  final List<String> filtros;

  const TcpeCatalogo._(this.entidad, this.pk, this.filtros);

  static const area = TcpeCatalogo<TcpeAreaEntity>._(
    'area',
    'codArea',
    ['codArea', 'activo'],
  );
  static const areaPost = TcpeCatalogo<TcpeAreaPostEntity>._(
    'areaPost',
    'codAreaPost',
    ['codAreaPost', 'codTipo'],
  );
  static const capacitacion = TcpeCatalogo<TcpeCapacitacionEntity>._(
    'capacitacion',
    'codCapacitacion',
    ['codCapacitacion'],
  );
  static const capacitador = TcpeCatalogo<TcpeCapacitadorEntity>._(
    'capacitador',
    'codCapacitador',
    ['codCapacitador'],
  );
  static const clasificacion = TcpeCatalogo<TcpeClasificacionEntity>._(
    'clasificacion',
    'codClasificacion',
    ['codClasificacion', 'codArea', 'codCurso', 'activo'],
  );
  static const conocimientosPost = TcpeCatalogo<TcpeConocimientosPostEntity>._(
    'conocimientosPost',
    'codConocimiento',
    ['codConocimiento'],
  );
  static const conocimientos = TcpeCatalogo<TcpeConocimientosEntity>._(
    'conocimientos',
    'codConocimiento',
    ['codConocimiento', 'codConvocatoria'],
  );
  static const convocatoria = TcpeCatalogo<TcpeConvocatoriaEntity>._(
    'convocatoria',
    'codConvocatoria',
    ['codConvocatoria', 'codDpto', 'codArea'],
  );
  static const curso = TcpeCatalogo<TcpeCursoEntity>._(
    'curso',
    'codCurso',
    ['codCurso', 'codCapacitacion'],
  );
  static const dpto = TcpeCatalogo<TcpeDptoEntity>._(
    'dpto',
    'codDpto',
    ['codDpto'],
  );
  static const empleado = TcpeCatalogo<TcpeEmpleadoEntity>._(
    'empleado',
    'codEmpleado',
    ['codEmpleado'],
  );
  static const examen = TcpeCatalogo<TcpeExamenEntity>._(
    'examen',
    'codExamen',
    ['codExamen', 'codPostulacion', 'codRolExamen', 'codUsuario'],
  );
  static const experienciaLab = TcpeCatalogo<TcpeExperienciaLabEntity>._(
    'experienciaLab',
    'codExpLab',
    ['codExpLab', 'codConvocatoria'],
  );
  static const fases = TcpeCatalogo<TcpeFasesEntity>._(
    'fases',
    'codFase',
    ['codFase'],
  );
  static const formacion = TcpeCatalogo<TcpeFormacionEntity>._(
    'formacion',
    'codFormacion',
    ['codFormacion'],
  );
  static const historialPost = TcpeCatalogo<TcpeHistorialPostEntity>._(
    'historialPost',
    'codHistorialPost',
    ['codHistorialPost', 'codFase', 'codPostulacion'],
  );
  static const inscripcion = TcpeCatalogo<TcpeInscripcionEntity>._(
    'inscripcion',
    'codInscripcion',
    ['codInscripcion', 'codCapacitacion', 'codUsuario'],
  );
  static const otrosConocimientos = TcpeCatalogo<TcpeOtrosConocimientosEntity>._(
    'otrosConocimientos',
    'codOtrosCono',
    ['codOtrosCono', 'codConocimiento', 'codPersonaPost'],
  );
  static const personaPost = TcpeCatalogo<TcpePersonaPostEntity>._(
    'personaPost',
    'codPersonaPost',
    ['codPersonaPost'],
  );
  static const postulacion = TcpeCatalogo<TcpePostulacionEntity>._(
    'postulacion',
    'codPostulacion',
    ['codPostulacion', 'codConvocatoria', 'codPersonaPost'],
  );
  static const pregunta = TcpeCatalogo<TcpePreguntaEntity>._(
    'pregunta',
    'codPregunta',
    ['codPregunta', 'codClasificacion', 'activo'],
  );
  static const preguntaH = TcpeCatalogo<TcpePreguntaHEntity>._(
    'preguntaH',
    'codPreguntaH',
    ['codPreguntaH', 'codExamen'],
  );
  // v11: preguntas de la semana y sus respuestas (no vienen de EVALUACION).
  static const preguntaSemana = TcpeCatalogo<TcpePreguntaSemanaEntity>._(
    'preguntaSemana',
    'codPreguntaSemana',
    ['codPreguntaSemana', 'codPregunta', 'activo'],
  );
  static const registroExamen = TcpeCatalogo<TcpeRegistroExamenEntity>._(
    'registroExamen',
    'codRegExamen',
    ['codRegExamen', 'codExamen', 'codRsptaOpcion'],
  );
  static const reqAcademico = TcpeCatalogo<TcpeReqAcademicoEntity>._(
    'reqAcademico',
    'codReqAcademico',
    ['codReqAcademico', 'codConvocatoria', 'codFormacion'],
  );
  static const reqAcademicoPost = TcpeCatalogo<TcpeReqAcademicoPostEntity>._(
    'reqAcademicoPost',
    'codReqAcaPost',
    ['codReqAcaPost', 'codFormacion', 'codPersonaPost'],
  );
  static const reqExpLabPost = TcpeCatalogo<TcpeReqExpLabPostEntity>._(
    'reqExpLabPost',
    'codExpLabPost',
    ['codExpLabPost', 'codPersonaPost'],
  );
  static const respuesta = TcpeCatalogo<TcpeRespuestaEntity>._(
    'respuesta',
    'codRespuesta',
    ['codRespuesta', 'codPregunta'],
  );
  static const respuestaH = TcpeCatalogo<TcpeRespuestaHEntity>._(
    'respuestaH',
    'codRespuestaH',
    ['codRespuestaH', 'codPreguntaH'],
  );
  static const rolExamen = TcpeCatalogo<TcpeRolExamenEntity>._(
    'rolExamen',
    'codRolExamen',
    ['codRolExamen', 'codArea', 'codCapacitacion', 'codConvocatoria', 'codClasificacion'],
  );
  static const rsptaOpcion = TcpeCatalogo<TcpeRsptaOpcionEntity>._(
    'rsptaOpcion',
    'codRsptaOp',
    ['codRsptaOp', 'codRespuesta'],
  );
  static const rsptaOpcionH = TcpeCatalogo<TcpeRsptaOpcionHEntity>._(
    'rsptaOpcionH',
    'codRsptaOpH',
    ['codRsptaOpH', 'codRespuestaH'],
  );
  static const rsptaOpcionU = TcpeCatalogo<TcpeRsptaOpcionUEntity>._(
    'rsptaOpcionU',
    'codRsptaOpU',
    ['codRsptaOpU', 'codRsptaOpH', 'codExamen'],
  );
  static const rsptaSemana = TcpeCatalogo<TcpeRsptaSemanaEntity>._(
    'rsptaSemana',
    'codRsptaSemana',
    ['codRsptaSemana', 'codPreguntaSemana', 'codUsuario', 'codRsptaOp'],
  );
  static const seleccionFase = TcpeCatalogo<TcpeSeleccionFaseEntity>._(
    'seleccionFase',
    'codSeleccionFase',
    ['codSeleccionFase', 'codConvocatoria', 'codFase'],
  );
  static const seleccionPreguntas = TcpeCatalogo<TcpeSeleccionPreguntasEntity>._(
    'seleccionPreguntas',
    'codSeleccionPreguntas',
    ['codSeleccionPreguntas', 'codExamen', 'codPregunta'],
  );
  static const temario = TcpeCatalogo<TcpeTemarioEntity>._(
    'temario',
    'codTemario',
    ['codTemario', 'codCapacitador', 'codCurso'],
  );
  static const tipo = TcpeCatalogo<TcpeTipoEntity>._(
    'tipo',
    'codTipo',
    ['codTipo'],
  );
  static const tipoUsuario = TcpeCatalogo<TcpeTipoUsuarioEntity>._(
    'tipoUsuario',
    'codTipoUsuario',
    ['codTipoUsuario'],
  );
  static const usuario = TcpeCatalogo<TcpeUsuarioEntity>._(
    'usuario',
    'codUsuario',
    ['codUsuario', 'codTipoUsuario', 'codArea', 'codEmpleado', 'activo'],
  );

  static const List<TcpeCatalogo<Object>> todos = [
    area,
    areaPost,
    capacitacion,
    capacitador,
    clasificacion,
    conocimientosPost,
    conocimientos,
    convocatoria,
    curso,
    dpto,
    empleado,
    examen,
    experienciaLab,
    fases,
    formacion,
    historialPost,
    inscripcion,
    otrosConocimientos,
    personaPost,
    postulacion,
    pregunta,
    preguntaH,
    preguntaSemana,
    registroExamen,
    reqAcademico,
    reqAcademicoPost,
    reqExpLabPost,
    respuesta,
    respuestaH,
    rolExamen,
    rsptaOpcion,
    rsptaOpcionH,
    rsptaOpcionU,
    rsptaSemana,
    seleccionFase,
    seleccionPreguntas,
    temario,
    tipo,
    tipoUsuario,
    usuario,
  ];
}
