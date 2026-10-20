/// El postulante externo de exámenes: su sesión y sus exámenes, con su propio
/// token (ver `DioPostulante`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/postulante_examen_impl.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_sesion_postulante_entity.dart';
import 'package:bosque_flutter/domain/repositories/postulante_examen_repository.dart';

/// Perezoso y reemplazable: las pruebas lo cambian con `overrideWithValue`.
final postulanteExamenRepositoryProvider = Provider<PostulanteExamenRepository>(
  (ref) => PostulanteExamenImpl(),
);

/// La sesión guardada si sigue vigente (null = hay que ingresar).
final sesionPostulanteProvider =
    FutureProvider.autoDispose<TcpeSesionPostulanteEntity?>(
      (ref) => ref.watch(postulanteExamenRepositoryProvider).sesionVigente(),
    );

final examenesPostulanteProvider =
    FutureProvider.autoDispose<List<TcpeEstadoRendicionEntity>>(
      (ref) => ref.watch(postulanteExamenRepositoryProvider).listarExamenes(),
    );

/// El estado de un examen del postulante, para la pantalla de resultado.
final estadoExamenPostulanteProvider = FutureProvider.autoDispose
    .family<TcpeEstadoRendicionEntity?, BigInt>(
      (ref, codExamen) =>
          ref.watch(postulanteExamenRepositoryProvider).estadoExamen(codExamen),
    );
