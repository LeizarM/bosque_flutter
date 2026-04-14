import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/data/repositories/nivel_jerarquico_impl.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/descuento_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el repositorio
final rrhhRepositoryProvider = Provider<RRHHRepositoryImpl>((ref) {
  return RRHHRepositoryImpl();
});

// Provider para el repositorio de niveles jerárquicos
final nivelJerarquicoRepositoryProvider = Provider<NivelJerarquicoImpl>((ref) {
  return NivelJerarquicoImpl();
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

// StateNotifier para manejar el estado de la lista de niveles jerárquicos
class NivelesJerarquicosNotifier
    extends StateNotifier<AsyncValue<List<NivelJerarquicoEntity>>> {
  final NivelJerarquicoImpl _repository;

  NivelesJerarquicosNotifier(this._repository)
    : super(const AsyncValue.loading()) {
    _loadNivelesJerarquicos();
  }

  Future<void> _loadNivelesJerarquicos() async {
    state = const AsyncValue.loading();
    try {
      final niveles = await _repository.getNivelesJerarquicos();
      state = AsyncValue.data(niveles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadNivelesJerarquicos();
  }
}

// Provider para los niveles jerárquicos
final nivelesJerarquicosProvider = StateNotifierProvider<
  NivelesJerarquicosNotifier,
  AsyncValue<List<NivelJerarquicoEntity>>
>((ref) {
  final repository = ref.watch(nivelJerarquicoRepositoryProvider);
  return NivelesJerarquicosNotifier(repository);
});

// StateNotifier para manejar las sucursales asignadas a un cargo
class SucursalesXCargoNotifier
    extends StateNotifier<AsyncValue<List<CargoSucursalEntity>>> {
  final RRHHRepositoryImpl _repository;
  final int _codCargo;

  SucursalesXCargoNotifier(this._repository, this._codCargo)
    : super(const AsyncValue.loading()) {
    _loadSucursalesXCargo();
  }

  Future<void> _loadSucursalesXCargo() async {
    state = const AsyncValue.loading();
    try {
      final sucursales = await _repository.lstSucursalesXCargo(_codCargo);
      // Filtrar elementos que no son asignaciones reales (codCargoSucursal > 0)
      final sucursalesReales =
          sucursales.where((s) => s.codCargoSucursal > 0).toList();
      state = AsyncValue.data(sucursalesReales);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadSucursalesXCargo();
  }
}

// Provider para las sucursales asignadas a un cargo específico
final sucursalesXCargoProvider = StateNotifierProvider.family<
  SucursalesXCargoNotifier,
  AsyncValue<List<CargoSucursalEntity>>,
  int
>((ref, codCargo) {
  final repository = ref.watch(rrhhRepositoryProvider);
  return SucursalesXCargoNotifier(repository, codCargo);
});

// StateNotifier para manejar los empleados asignados a un cargo
class EmpleadosXCargoNotifier
    extends StateNotifier<AsyncValue<List<CargoEntity>>> {
  final RRHHRepositoryImpl _repository;
  final int _codCargo;
  bool _isDisposed = false;

  EmpleadosXCargoNotifier(this._repository, this._codCargo)
    : super(const AsyncValue.loading()) {
    _loadEmpleadosXCargo();
  }

  Future<void> _loadEmpleadosXCargo() async {
    if (_isDisposed) return;
    state = const AsyncValue.loading();
    try {
      final empleados = await _repository.obtenerEmpleadosXCargo(_codCargo);
      if (!_isDisposed) {
        state = AsyncValue.data(empleados);
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> refresh() async {
    await _loadEmpleadosXCargo();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

// Provider para los empleados asignados a un cargo específico
// Usando autoDispose para limpiar cuando ya no se usa
final empleadosXCargoProvider = StateNotifierProvider.autoDispose
    .family<EmpleadosXCargoNotifier, AsyncValue<List<CargoEntity>>, int>((
      ref,
      codCargo,
    ) {
      final repository = ref.watch(rrhhRepositoryProvider);
      return EmpleadosXCargoNotifier(repository, codCargo);
    });

// Provider para obtener descuentos de un empleado por mes y año
// Params: (codEmpleado, mes, anio)
final descuentosEmpleadoProvider = FutureProvider.autoDispose
    .family<List<DescuentoEmpleadoEntity>, (int, int, int)>((ref, params) {
      final repository = ref.watch(rrhhRepositoryProvider);
      return repository.obtenerDescuentosEmpleado(
        codEmpleado: params.$1,
        mes: params.$2,
        anio: params.$3,
      );
    });
