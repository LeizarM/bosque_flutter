import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_maquina_montacarga_repository.dart';
import 'package:bosque_flutter/data/repositories/control_combustible_maquina_montacarga_impl.dart';

final controlCombustibleMaquinaMontacargaProvider = Provider<ControlCombustibleMaquinaMontacargaRepository>((ref) {
  return ControlCombustibleMaquinaMontacargaImpl();
});


enum RegistroStatus {
  initial,
  loading,
  success,
  error,
}

class RegistroState {
  final RegistroStatus status;
  final String? errorMessage;
  
  RegistroState({
    required this.status,
    this.errorMessage,
  });
  
  RegistroState copyWith({
    RegistroStatus? status,
    String? errorMessage,
  }) {
    return RegistroState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  factory RegistroState.initial() => RegistroState(status: RegistroStatus.initial);
}

class ControlCombustibleMaquinaMontacargaNotifier extends StateNotifier<RegistroState> {
  final ControlCombustibleMaquinaMontacargaRepository _repository;
  
  ControlCombustibleMaquinaMontacargaNotifier(this._repository) : super(RegistroState.initial());
  
  Future<void> registrarControlCombustible(ControlCombustibleMaquinaMontacargaEntity datos) async {
    state = state.copyWith(status: RegistroStatus.loading);
    
    try {
      final result = await _repository.registerControlCombustibleMaquinaMontacarga(datos);
      
      if (result) {
        state = state.copyWith(status: RegistroStatus.success);
      } else {
        state = state.copyWith(
          status: RegistroStatus.error,
          errorMessage: 'Error al registrar el control de combustible',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: RegistroStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  void resetState() {
    state = RegistroState.initial();
  }
}

final controlCombustibleMaquinaMontacargaNotifierProvider = StateNotifierProvider<ControlCombustibleMaquinaMontacargaNotifier, RegistroState>((ref) {
  final repository = ref.watch(controlCombustibleMaquinaMontacargaProvider);
  return ControlCombustibleMaquinaMontacargaNotifier(repository);
});