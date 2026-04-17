import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/domain/entities/pendiente_entrega_entity.dart';
import 'package:bosque_flutter/domain/repositories/entregas_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/entregas_provider.dart';

// Estado para pendientes de entrega
class PendientesEntregaState {
  final bool isLoading;
  final List<PendienteEntregaEntity> pendientes;
  final String? error;

  const PendientesEntregaState({
    this.isLoading = false,
    this.pendientes = const [],
    this.error,
  });

  PendientesEntregaState copyWith({
    bool? isLoading,
    List<PendienteEntregaEntity>? pendientes,
    String? error,
  }) {
    return PendientesEntregaState(
      isLoading: isLoading ?? this.isLoading,
      pendientes: pendientes ?? this.pendientes,
      error: error,
    );
  }
}

// Notifier para pendientes de entrega
class PendientesEntregaNotifier extends StateNotifier<PendientesEntregaState> {
  final EntregasRepository _repository;

  PendientesEntregaNotifier(this._repository)
    : super(const PendientesEntregaState());

  Future<void> cargarPendientes() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final pendientes = await _repository.getPendientesEntrega();
      state = state.copyWith(isLoading: false, pendientes: pendientes);
      console(
        '📦 Pendientes de entrega cargados: ${pendientes.length} registros',
      );
    } catch (e) {
      console('❌ Error cargando pendientes de entrega: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider para pendientes de entrega
final pendientesEntregaProvider =
    StateNotifierProvider<PendientesEntregaNotifier, PendientesEntregaState>((
      ref,
    ) {
      final repository = ref.watch(entregasRepositoryProvider);
      return PendientesEntregaNotifier(repository);
    });
