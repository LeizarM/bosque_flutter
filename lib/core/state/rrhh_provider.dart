import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el repositorio
final rrhhRepositoryProvider = Provider<RRHHRepositoryImpl>((ref) {
  return RRHHRepositoryImpl();
});

// StateNotifier para manejar el estado de la lista de empresas
class EmpresasNotifier extends StateNotifier<AsyncValue<List<EmpresaEntity>>> {
  final RRHHRepositoryImpl _repository;

  EmpresasNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    state = const AsyncValue.loading();
    try {
      final empresas = await _repository.lstEmpresas();
      state = AsyncValue.data(empresas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadEmpresas();
  }
}

// Provider para el StateNotifier
final empresasProvider =
    StateNotifierProvider<EmpresasNotifier, AsyncValue<List<EmpresaEntity>>>((
      ref,
    ) {
      final repository = ref.watch(rrhhRepositoryProvider);
      return EmpresasNotifier(repository);
    });

// StateNotifier para manejar la empresa seleccionada
class SelectedEmpresaNotifier extends StateNotifier<EmpresaEntity?> {
  SelectedEmpresaNotifier() : super(null);

  void selectEmpresa(EmpresaEntity empresa) {
    state = empresa;
  }

  void clearSelection() {
    state = null;
  }
}

// Provider para la empresa seleccionada
final selectedEmpresaProvider =
    StateNotifierProvider<SelectedEmpresaNotifier, EmpresaEntity?>((ref) {
      return SelectedEmpresaNotifier();
    });

// StateNotifier para manejar el estado de la lista de cargos
class CargosNotifier extends StateNotifier<AsyncValue<List<CargoEntity>>> {
  final RRHHRepositoryImpl _repository;
  final int _codEmpresa;

  CargosNotifier(this._repository, this._codEmpresa)
    : super(const AsyncValue.loading()) {
    _loadCargos();
  }

  Future<void> _loadCargos() async {
    state = const AsyncValue.loading();
    try {
      final cargos = await _repository.lstCargos(_codEmpresa);
      state = AsyncValue.data(cargos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadCargos();
  }
}

// Provider para los cargos de una empresa
final cargosProvider = StateNotifierProvider.family<
  CargosNotifier,
  AsyncValue<List<CargoEntity>>,
  int
>((ref, codEmpresa) {
  final repository = ref.watch(rrhhRepositoryProvider);
  return CargosNotifier(repository, codEmpresa);
});

// StateNotifier para manejar el estado de la lista de sucursales
class SucursalesNotifier
    extends StateNotifier<AsyncValue<List<SucursalEntity>>> {
  final RRHHRepositoryImpl _repository;
  final int _codEmpresa;

  SucursalesNotifier(this._repository, this._codEmpresa)
    : super(const AsyncValue.loading()) {
    _loadSucursales();
  }

  Future<void> _loadSucursales() async {
    state = const AsyncValue.loading();
    try {
      final sucursales = await _repository.lstSucursales(_codEmpresa);
      state = AsyncValue.data(sucursales);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadSucursales();
  }
}

// Provider para las sucursales de una empresa
final sucursalesProvider = StateNotifierProvider.family<
  SucursalesNotifier,
  AsyncValue<List<SucursalEntity>>,
  int
>((ref, codEmpresa) {
  final repository = ref.watch(rrhhRepositoryProvider);
  return SucursalesNotifier(repository, codEmpresa);
});

// StateNotifier para manejar el estado de la lista de cargos con detalles
class CargosXEmpresaNotifier
    extends StateNotifier<AsyncValue<List<CargoEntity>>> {
  final RRHHRepositoryImpl _repository;
  final int _codEmpresa;

  CargosXEmpresaNotifier(this._repository, this._codEmpresa)
    : super(const AsyncValue.loading()) {
    _loadCargosXEmpresa();
  }

  Future<void> _loadCargosXEmpresa() async {
    state = const AsyncValue.loading();
    try {
      final cargos = await _repository.lstCargosXEmpresa(_codEmpresa);
      state = AsyncValue.data(cargos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadCargosXEmpresa();
  }
}

// Provider para los cargos detallados de una empresa (con jerarquía)
final cargosXEmpresaProvider = StateNotifierProvider.family<
  CargosXEmpresaNotifier,
  AsyncValue<List<CargoEntity>>,
  int
>((ref, codEmpresa) {
  final repository = ref.watch(rrhhRepositoryProvider);
  return CargosXEmpresaNotifier(repository, codEmpresa);
});
