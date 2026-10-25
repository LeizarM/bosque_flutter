/// Módulo Tickets (`ttk`): eventos, tipos de vale, participantes y vales.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/ttk_tickets_impl.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';

/// Perezoso y reemplazable: las pruebas lo cambian con `overrideWithValue`.
final ttkTicketsRepositoryProvider = Provider<TtkTicketsRepository>(
  (ref) => TtkTicketsImpl(),
);

typedef FiltroEventosTtk = ({String? estado, int? anio});

final ttkEventosProvider = FutureProvider.autoDispose
    .family<List<TtkEventoEntity>, FiltroEventosTtk>(
      (ref, f) => ref
          .watch(ttkTicketsRepositoryProvider)
          .listarEventos(estado: f.estado, anio: f.anio),
    );

/// Un evento recién leído (el detalle lo vuelve a pedir tras cada acción).
final ttkEventoProvider = FutureProvider.autoDispose
    .family<TtkEventoEntity?, BigInt>((ref, codEvento) async {
      final r = await ref
          .watch(ttkTicketsRepositoryProvider)
          .listarEventos(codEvento: codEvento);
      return r.isEmpty ? null : r.first;
    });

final ttkTiposProvider = FutureProvider.autoDispose
    .family<List<TtkTipoTicketEntity>, BigInt>(
      (ref, codEvento) =>
          ref.watch(ttkTicketsRepositoryProvider).listarTipos(codEvento),
    );

typedef FiltroParticipantesTtk =
    ({BigInt codEvento, String? categoria, String buscar});

final ttkParticipantesProvider = FutureProvider.autoDispose
    .family<List<TtkParticipanteEntity>, FiltroParticipantesTtk>(
      (ref, f) => ref
          .watch(ttkTicketsRepositoryProvider)
          .listarParticipantes(
            f.codEvento,
            categoria: f.categoria,
            buscar: f.buscar,
          ),
    );

final ttkValesParticipanteProvider = FutureProvider.autoDispose
    .family<List<TtkParticipanteTicketEntity>, BigInt>(
      (ref, codParticipante) => ref
          .watch(ttkTicketsRepositoryProvider)
          .listarVales(codParticipante: codParticipante),
    );

typedef FiltroEmpleadosTtk = ({BigInt codEvento, String buscar});

final ttkEmpleadosEventoProvider = FutureProvider.autoDispose
    .family<List<TtkParticipanteEntity>, FiltroEmpleadosTtk>(
      (ref, f) => ref
          .watch(ttkTicketsRepositoryProvider)
          .empleadosDisponibles(f.codEvento, buscar: f.buscar),
    );
