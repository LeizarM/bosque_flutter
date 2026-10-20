/// Módulo de exámenes (`tcpe_*`) del lado del empleado: banco, lotes,
/// resultados, informes, usuarios externos y "Mis exámenes".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/notifiers/rendicion_examen_notifier.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/repositories/examenes_impl.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_elegible_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_revision_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';
import 'package:bosque_flutter/domain/repositories/examenes_repository.dart';
import 'package:bosque_flutter/domain/repositories/rendicion_examen_repository.dart';

export 'package:bosque_flutter/core/state/notifiers/rendicion_examen_notifier.dart'
    show ClaveRendicion, OrigenRendicion, RendicionExamenNotifier, RendicionExamenState, esTiempoVencido;

/// Perezoso y reemplazable: las pruebas lo cambian con `overrideWithValue`.
final examenesRepositoryProvider = Provider<ExamenesRepository>(
  (ref) => ExamenesImpl(),
);

// ── Catálogos que comparten varias pantallas ────────────────────────────
final tcpeAreasProvider = FutureProvider.autoDispose<List<TcpeAreaEntity>>(
  (ref) => ref.watch(examenesRepositoryProvider).listarCatalogo(TcpeCatalogo.area),
);

final tcpeCategoriasProvider =
    FutureProvider.autoDispose<List<TcpeClasificacionEntity>>(
      (ref) => ref
          .watch(examenesRepositoryProvider)
          .listarCatalogo(TcpeCatalogo.clasificacion),
    );

// ── Banco de preguntas ──────────────────────────────────────────────────
typedef FiltroPreguntas = ({
  BigInt? codArea,
  BigInt? codClasificacion,
  bool? activo,
  String texto,
});

final tcpePreguntasProvider = FutureProvider.autoDispose
    .family<List<TcpeBancoPreguntaEntity>, FiltroPreguntas>(
      (ref, f) => ref
          .watch(examenesRepositoryProvider)
          .listarPreguntas(
            codArea: f.codArea,
            codClasificacion: f.codClasificacion,
            activo: f.activo,
            texto: f.texto,
          ),
    );

// ── Lotes ───────────────────────────────────────────────────────────────
typedef FiltroLotes = ({BigInt? codArea, BigInt? codClasificacion, String? modalidad});

final tcpeLotesProvider = FutureProvider.autoDispose
    .family<List<TcpeLoteEntity>, FiltroLotes>(
      (ref, f) => ref
          .watch(examenesRepositoryProvider)
          .listarLotes(
            codArea: f.codArea,
            codClasificacion: f.codClasificacion,
            modalidad: f.modalidad,
          ),
    );

/// Las credenciales generadas en esta sesión, por lote. Las claves vienen en
/// claro una sola vez: mientras la app siga abierta se pueden reimprimir.
/// No es autoDispose a propósito.
final tcpeCredencialesSesionProvider =
    StateProvider<Map<BigInt, List<TcpeCredencialEntity>>>((ref) => {});

/// Empleados para elegir en un lote; con el lote, marca a los que ya lo tienen.
final tcpeEmpleadosElegiblesProvider = FutureProvider.autoDispose
    .family<List<TcpeEmpleadoElegibleEntity>, BigInt?>(
      (ref, codRolExamen) =>
          ref.watch(examenesRepositoryProvider).empleadosElegibles(codRolExamen: codRolExamen),
    );

// ── Resultados ──────────────────────────────────────────────────────────
final tcpeResultadosProvider = FutureProvider.autoDispose
    .family<List<TcpeResultadoExamenEntity>, BigInt>(
      (ref, codRolExamen) =>
          ref.watch(examenesRepositoryProvider).listarResultados(codRolExamen),
    );

final tcpeRevisionProvider = FutureProvider.autoDispose
    .family<List<TcpeRevisionItemEntity>, BigInt>(
      (ref, codExamen) => ref.watch(examenesRepositoryProvider).revision(codExamen),
    );

// ── En vivo ─────────────────────────────────────────────────────────────
/// Lotes para monitorear. El panel y el espejo consultan directo al
/// repositorio: se refrescan solos y solo mientras se ven.
final tcpeMonitorLotesProvider = FutureProvider.autoDispose<List<TcpeMonitorLoteEntity>>(
  (ref) => ref.watch(examenesRepositoryProvider).monitorLotes(),
);

// ── Usuarios externos ───────────────────────────────────────────────────
/// Solo los externos: los que no tienen `codEmpleado`.
final tcpeUsuariosExternosProvider =
    FutureProvider.autoDispose<List<TcpeUsuarioEntity>>((ref) async {
      final todos = await ref
          .watch(examenesRepositoryProvider)
          .listarCatalogo(TcpeCatalogo.usuario);
      return [
        for (final u in todos)
          if (u.codEmpleado == null) u,
      ];
    });

// ── Mis exámenes y rendición ────────────────────────────────────────────
final tcpeMisExamenesProvider =
    FutureProvider.autoDispose<List<TcpeEstadoRendicionEntity>>(
      (ref) => ref.watch(examenesRepositoryProvider).listarExamenes(),
    );

RendicionExamenRepository _repoRendicion(Ref ref, OrigenRendicion origen) => switch (origen) {
  OrigenRendicion.empleado => ref.watch(examenesRepositoryProvider),
  OrigenRendicion.postulante => ref.watch(postulanteExamenRepositoryProvider),
};

/// Una rendición por examen y origen. autoDispose: al salir se corta el reloj
/// (el del servidor sigue: volver a entrar retoma donde iba).
final rendicionExamenProvider = StateNotifierProvider.autoDispose
    .family<RendicionExamenNotifier, RendicionExamenState, ClaveRendicion>(
      (ref, clave) => RendicionExamenNotifier(_repoRendicion(ref, clave.origen), clave.codExamen),
    );

/// La configuración del módulo según quién la pide (empleado o postulante). Si
/// el servidor no responde, la de respaldo; se vuelve a pedir en la próxima.
final configExamenesProvider = FutureProvider.autoDispose
    .family<TcpeConfiguracion, OrigenRendicion>((ref, origen) async {
      try {
        final filas = await _repoRendicion(ref, origen).configuracion();
        ref.keepAlive();
        return TcpeConfiguracion.desde(filas);
      } catch (e) {
        console('⚠️ Configuración de exámenes no disponible, se usa la de respaldo: $e');
        return TcpeConfiguracion.respaldo;
      }
    });

/// La devolución de un examen entregado, pregunta por pregunta.
final devolucionExamenProvider = FutureProvider.autoDispose
    .family<List<TcpeDevolucionPreguntaEntity>, ClaveRendicion>((ref, clave) async {
      final filas = await _repoRendicion(ref, clave.origen).devolucionExamen(clave.codExamen);
      return TcpeDevolucionPreguntaEntity.agrupar(filas);
    });
