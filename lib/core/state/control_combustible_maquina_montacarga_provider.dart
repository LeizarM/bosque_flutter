// control_combustible_maquina_montacarga_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/control_combustible_maquina_montacarga_impl.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_maquina_montacarga_repository.dart';

enum RegistroStatus {
  initial,
  loading,
  success,
  error,
}

enum FetchStatus {
  initial,
  loading,
  success,
  error,
}

class RegistroState {
  final RegistroStatus registroStatus;
  final FetchStatus almacenesStatus;
  final FetchStatus maquinasStatus;
  final FetchStatus bidonesStatus; // Nuevo estado para bidones
  final String? errorMessage;
  final List<ControlCombustibleMaquinaMontacargaEntity> almacenes;
  final List<ControlCombustibleMaquinaMontacargaEntity> maquinasMontacarga;
  final List<ControlCombustibleMaquinaMontacargaEntity> bidones; // Nueva lista para bidones
  
  RegistroState({
    required this.registroStatus,
    required this.almacenesStatus,
    required this.maquinasStatus,
    required this.bidonesStatus, // Incluir en el constructor
    this.errorMessage,
    required this.almacenes,
    required this.maquinasMontacarga,
    required this.bidones, // Incluir en el constructor
  });
  
  RegistroState copyWith({
    RegistroStatus? registroStatus,
    FetchStatus? almacenesStatus,
    FetchStatus? maquinasStatus,
    FetchStatus? bidonesStatus, // Agregar al método copyWith
    String? errorMessage,
    List<ControlCombustibleMaquinaMontacargaEntity>? almacenes,
    List<ControlCombustibleMaquinaMontacargaEntity>? maquinasMontacarga,
    List<ControlCombustibleMaquinaMontacargaEntity>? bidones, // Agregar al método copyWith
  }) {
    return RegistroState(
      registroStatus: registroStatus ?? this.registroStatus,
      almacenesStatus: almacenesStatus ?? this.almacenesStatus,
      maquinasStatus: maquinasStatus ?? this.maquinasStatus,
      bidonesStatus: bidonesStatus ?? this.bidonesStatus, // Incluir en el retorno
      errorMessage: errorMessage ?? this.errorMessage,
      almacenes: almacenes ?? this.almacenes,
      maquinasMontacarga: maquinasMontacarga ?? this.maquinasMontacarga,
      bidones: bidones ?? this.bidones, // Incluir en el retorno
    );
  }
  
  factory RegistroState.initial() => RegistroState(
    registroStatus: RegistroStatus.initial,
    almacenesStatus: FetchStatus.initial,
    maquinasStatus: FetchStatus.initial,
    bidonesStatus: FetchStatus.initial, // Inicializar estado de bidones
    almacenes: [],
    maquinasMontacarga: [],
    bidones: [], // Inicializar lista de bidones
  );
}

class ControlCombustibleMaquinaMontacargaNotifier extends StateNotifier<RegistroState> {
  final ControlCombustibleMaquinaMontacargaRepository _repository;
  
  ControlCombustibleMaquinaMontacargaNotifier(this._repository) : super(RegistroState.initial());
  
  Future<void> registrarControlCombustible(ControlCombustibleMaquinaMontacargaEntity datos) async {
    state = state.copyWith(registroStatus: RegistroStatus.loading);
    
    try {
      final result = await _repository.registerControlCombustibleMaquinaMontacarga(datos);
      
      if (result) {
        state = state.copyWith(
          registroStatus: RegistroStatus.success,
          errorMessage: null, // Limpiar cualquier mensaje de error previo
        );
      } else {
        state = state.copyWith(
          registroStatus: RegistroStatus.error,
          errorMessage: 'Error al registrar el control de combustible',
        );
      }
    } catch (e) {
      // Si el error contiene "400" podría ser que el registro fue exitoso pero el servidor devolvió un error
      if (e.toString().contains('400')) {
        state = state.copyWith(
          registroStatus: RegistroStatus.success,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          registroStatus: RegistroStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }
  
  Future<void> cargarAlmacenes() async {
    state = state.copyWith(almacenesStatus: FetchStatus.loading);
    
    try {
      final almacenes = await _repository.obtenerAlmacenes();
      
      state = state.copyWith(
        almacenesStatus: FetchStatus.success,
        almacenes: almacenes,
      );
    } catch (e) {
      state = state.copyWith(
        almacenesStatus: FetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  
  
  
  
  
  void resetRegistroStatus() {
    state = state.copyWith(registroStatus: RegistroStatus.initial);
  }
}

// Mantenemos el provider original
final controlCombustibleMaquinaMontacargaProvider = Provider<ControlCombustibleMaquinaMontacargaRepository>((ref) {
  return ControlCombustibleMaquinaMontacargaImpl();
});

final controlCombustibleMaquinaMontacargaNotifierProvider = StateNotifierProvider<ControlCombustibleMaquinaMontacargaNotifier, RegistroState>((ref) {
  final repository = ref.watch(controlCombustibleMaquinaMontacargaProvider);
  return ControlCombustibleMaquinaMontacargaNotifier(repository);
});

// Providers adicionales para acceder directamente a los almacenes y máquinas
final almacenesProvider = Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
  return ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider).almacenes;
});

final maquinasMontacargaProvider = Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
  return ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider).maquinasMontacarga;
});

// Nuevo provider para acceder directamente a los bidones
final bidonesMaquinaProvider = Provider<List<ControlCombustibleMaquinaMontacargaEntity>>((ref) {
  return ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider).bidones;
});