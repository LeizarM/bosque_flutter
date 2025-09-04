import 'package:bosque_flutter/data/repositories/ficha_trabajador_impl.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DependientesNotifier extends AsyncNotifier<List<DependienteEntity>> {
  final _repository = FichaTrabajadorImpl();

  @override
  Future<List<DependienteEntity>> build() async {
    return [];
  }

  Future<bool> eliminarDependiente(int codDependiente) async {
    try {
      state = const AsyncValue.loading();

      final resultado = await _repository.eliminarDependiente(codDependiente);
      
      if (resultado) {
        state = AsyncValue.data(
          state.value!.where((d) => d.codDependiente != codDependiente).toList()
        );
        return true;
      } else {
        state = AsyncValue.error(
          'No se pudo eliminar el dependiente',
          StackTrace.current
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  Future<List<DependienteEntity>> editarDependiente(DependienteEntity dependiente) async {
    try {
      state = const AsyncValue.loading();
      final repo = FichaTrabajadorImpl();
      
      print('Enviando dependiente a editar: $dependiente'); // Log para depuración
      
      final result = await repo.editarDep(dependiente);
      
      print('Resultado de edición: $result'); // Log para depuración
      
      state = AsyncValue.data(result);
      return result;
    } catch (e) {
      print('Error en editarDependiente: $e'); // Log para depuración
      state = AsyncValue.error(e, StackTrace.current);
      throw Exception('Error al editar dependiente: $e');
    }
  }
}