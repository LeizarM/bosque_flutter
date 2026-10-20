import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/tcpe_empleado_elegible_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_espejo_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fila_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_informe_categoria_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_generado_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_importar_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_revision_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_solucionario_item_entity.dart';
import 'package:bosque_flutter/domain/repositories/rendicion_examen_repository.dart';

/// Endpoints `/examenes/**` del módulo de exámenes, con token de empleado.
/// Los de [RendicionExamenRepository] son "Mis exámenes": el empleado rinde
/// con la misma pantalla que el postulante.
abstract class ExamenesRepository implements RendicionExamenRepository {
  // ── CRUD genérico de las 38 tablas ────────────────────────────────────
  /// `p_list_tcpe_<Entidad>`. [filtros] admite las claves de
  /// [TcpeCatalogo.filtros]; null es "sin filtro".
  Future<List<E>> listarCatalogo<E>(
    TcpeCatalogo<E> catalogo, {
    Map<String, Object?> filtros = const {},
  });

  /// Alta si el PK es 0, si no actualización completa. Devuelve `idGenerado`.
  Future<BigInt> guardarCatalogo<E>(TcpeCatalogo<E> catalogo, E registro);

  Future<BigInt> eliminarCatalogo<E>(TcpeCatalogo<E> catalogo, BigInt id);

  // ── Banco de preguntas ────────────────────────────────────────────────
  Future<List<TcpeBancoPreguntaEntity>> listarPreguntas({
    BigInt? codPregunta,
    BigInt? codClasificacion,
    BigInt? codArea,
    bool? activo,
    String? texto,
  });

  /// Opciones de una pregunta o de todas las de una categoría.
  Future<List<TcpeBancoOpcionEntity>> listarOpciones({
    BigInt? codPregunta,
    BigInt? codClasificacion,
  });

  /// Guarda pregunta, respuesta y opciones en una sola operación. Devuelve
  /// `codPregunta`.
  Future<BigInt> guardarPregunta(
    TcpeBancoPreguntaEntity pregunta,
    List<TcpeBancoOpcionEntity> opciones,
  );

  Future<void> eliminarPregunta(BigInt codPregunta);

  Future<void> activarPregunta(BigInt codPregunta, bool activo);

  /// `p_list_tcpe_Banco` D: las iguales (`igual`) y hasta 5 parecidas de la
  /// categoría. Lista vacía si no hay ninguna.
  Future<List<TcpeDuplicadoPreguntaEntity>> buscarDuplicados(
    BigInt codClasificacion,
    String texto,
  );

  /// `p_list_tcpe_BancoLote` V: valida sin escribir, una fila por pregunta en
  /// el orden enviado (la fila 1 es la primera).
  Future<List<TcpeFilaImportacionEntity>> validarImportacion(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  );

  /// `p_abm_tcpe_BancoLote` I: inserta solo las filas OK y devuelve el resumen
  /// del SP.
  Future<TcpeResultadoImportacionEntity> importarPreguntas(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  );

  // ── Lotes ─────────────────────────────────────────────────────────────
  Future<List<TcpeLoteEntity>> listarLotes({
    BigInt? codRolExamen,
    BigInt? codArea,
    BigInt? codClasificacion,
    String? modalidad,
  });

  /// Preguntas que se pueden sortear de una categoría.
  Future<int> preguntasDisponibles(BigInt codClasificacion);

  /// Empleados vigentes con CI y cargo actual. Con [codRolExamen], los que
  /// ya tienen examen en ese lote vienen con `puedeRendir` en falso.
  Future<List<TcpeEmpleadoElegibleEntity>> empleadosElegibles({BigInt? codRolExamen});

  /// Crea el lote y un examen por cada destinatario del [pedido]: anónimos
  /// (cantidad), personas con CI y empleados, juntos si hace falta.
  Future<TcpeLoteGeneradoEntity> generarLote(
    TcpeLoteEntity lote,
    TcpePedidoExamenesEntity pedido,
  );

  Future<TcpeLoteGeneradoEntity> agregarExamenes(
    BigInt codRolExamen,
    TcpePedidoExamenesEntity pedido,
  );

  Future<void> actualizarLote(TcpeLoteEntity lote);

  Future<void> eliminarLote(BigInt codRolExamen);

  /// PDF armado en el backend: el examen escrito o el solucionario, de todo el
  /// lote o de un examen ([codExamen]). Null = 204, no hay nada que imprimir.
  Future<Uint8List?> pdfEscrito({
    required BigInt codRolExamen,
    BigInt? codExamen,
    bool solucionario = false,
  });

  // ── Resultados y calificación ─────────────────────────────────────────
  /// Antes de listar, el backend entrega los vencidos del lote.
  Future<List<TcpeResultadoExamenEntity>> listarResultados(BigInt codRolExamen);

  Future<List<TcpeRevisionItemEntity>> revision(BigInt codExamen);

  /// De un examen ([codExamen]) o de todo el lote ([codRolExamen]).
  Future<List<TcpeSolucionarioItemEntity>> solucionario({
    BigInt? codExamen,
    BigInt? codRolExamen,
  });

  Future<List<TcpeHistorialExamenEntity>> historial(String ci);

  Future<List<TcpeInformeCategoriaEntity>> informe({
    BigInt? codClasificacion,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  // Las tres devuelven el mensaje del SP (`errormsg`), que la UI muestra tal cual.
  Future<String?> marcarRespuesta({
    required BigInt codExamen,
    required BigInt codRespuestaH,
    required bool esCorrecta,
  });

  Future<String?> cerrarCalificacion(BigInt codExamen);

  /// Nota manual de un escrito; el rango lo valida `p_abm_tcpe_Calificacion` N.
  Future<String?> notaManual(BigInt codExamen, double resultado);

  // ── En vivo ───────────────────────────────────────────────────────────
  /// `p_list_tcpe_Monitor` D: lotes con exámenes en curso o la ventana abierta.
  Future<List<TcpeMonitorLoteEntity>> monitorLotes();

  /// `p_list_tcpe_Monitor` L: el panel de un lote, primero los que están en curso.
  Future<List<TcpeMonitorExamenEntity>> monitorExamenes(BigInt codRolExamen);

  /// `p_list_tcpe_Monitor` E: la pregunta que tiene delante, una fila por opción.
  Future<List<TcpeEspejoItemEntity>> espejo(BigInt codExamen);

  // ── Usuarios externos ─────────────────────────────────────────────────
  /// Clave temporal nueva, al azar: viene en claro una sola vez.
  Future<TcpeCredencialEntity> regenerarClave(BigInt codUsuario);

  /// Solo `ROLE_ADM`. Devuelve cuántas claves pasaron a hash.
  Future<int> migrarClaves();
}
