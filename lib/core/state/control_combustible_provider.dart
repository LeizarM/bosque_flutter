import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_entity.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_repository.dart';
import 'package:bosque_flutter/data/repositories/control_combustible_impl.dart';


final controlCombustibleRepositoryProvider = Provider<ControlCombustibleRepository>((ref) {
  return ControlCombustibleImpl();
});

final controlCombustibleProvider = StateNotifierProvider<ControlCombustibleNotifier, AsyncValue<bool>>((ref) {
  final repo = ref.watch(controlCombustibleRepositoryProvider);
  return ControlCombustibleNotifier(repo);
});

final combustiblesPorCocheProvider = FutureProvider.family<List<CombustibleControlEntity>, int>((ref, idCoche) async {
  final repo = ref.read(controlCombustibleRepositoryProvider);
  return await repo.getCombustiblesPorCoche(idCoche);
});

class ControlCombustibleNotifier extends StateNotifier<AsyncValue<bool>> {
  final ControlCombustibleRepository _repo;
  ControlCombustibleNotifier(this._repo) : super(const AsyncData(false));

  Future<void> createControlCombustible(CombustibleControlEntity entity) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.createControlCombustible(entity);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
