import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart'
    show mensajeDeErrorCheque;
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart'
    show obtenerBancos, obtenerBancosPlanilla;
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/bancos_impl.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/repositories/bancos_repository.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';

/// Bancos (tch_banco, vista 43).
///
/// Perezoso y tipado contra la interfaz: `main.dart` no lo conoce y una prueba
/// lo sustituye con `bancosRepositoryProvider.overrideWithValue(falso)`.
final bancosRepositoryProvider = Provider<BancosRepository>(
  (ref) => BancosImpl(),
);

/// Lo que el usuario puede hacer en la pantalla de Bancos. Sale de dos fuentes:
/// los botones de `buttonPermissionsProvider` y el `tipoUsuario` de
/// `userProvider` (`ROLE_ADM` = administrador, que pasa siempre). Mientras
/// llegan los permisos o sin sesion no hay ningun boton.
final permisosBancoProvider = Provider<PermisosBanco>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return PermisosBanco.ninguno;
  final botones =
      ref.watch(buttonPermissionsProvider).valueOrNull ??
      const <UsuarioBtnEntity>[];
  return PermisosBanco.desde(tipoUsuario: user.tipoUsuario, botones: botones);
});

/// Los bancos de la pantalla. A diferencia de `obtenerBancos` (el combo de otros
/// modulos, que traga los errores y devuelve `[]`), un fallo llega como error
/// para que la pantalla pueda decirlo y ofrecer reintentar. autoDispose: cada
/// visita empieza con una lectura nueva.
final listaBancosProvider = FutureProvider.autoDispose<List<BancoEntity>>(
  (ref) => ref.watch(bancosRepositoryProvider).listar(),
);

@immutable
class EstadoOperacionBanco {
  const EstadoOperacionBanco({this.ocupado = false, this.error});

  /// Hay una escritura en vuelo.
  final bool ocupado;

  /// El mensaje del backend de la ultima escritura fallida, tal cual.
  final String? error;
}

/// Alta, edicion y baja de bancos. Al salir bien invalida la lista de la
/// pantalla y las dos listas de lectura (`obtenerBancos` y
/// `obtenerBancosPlanilla`, que viven en el modulo de registro de empleados y no
/// se tocan) para que el combo de bancos del filtro y del formulario de cheques
/// vea el cambio.
///
/// Tocar un banco afecta a Depositos y a Pagos al Exterior: borrar uno que ellos
/// usan lo rechaza el backend con un 400.
class OperacionesBancosNotifier extends StateNotifier<EstadoOperacionBanco> {
  OperacionesBancosNotifier(this._ref) : super(const EstadoOperacionBanco());

  final Ref _ref;

  BancosRepository get _repo => _ref.read(bancosRepositoryProvider);

  Future<BigInt?> _ejecutar(Future<BigInt> Function() accion) async {
    if (state.ocupado) return null;
    state = const EstadoOperacionBanco(ocupado: true);
    try {
      final r = await accion();
      if (!mounted) return r;
      state = const EstadoOperacionBanco();
      _ref.invalidate(listaBancosProvider);
      _ref.invalidate(obtenerBancos);
      _ref.invalidate(obtenerBancosPlanilla);
      return r;
    } catch (e) {
      if (mounted) state = EstadoOperacionBanco(error: mensajeDeErrorCheque(e));
      return null;
    }
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoOperacionBanco();
  }

  /// Alta ([BancoRegistroEntity.codBanco] 0) o edicion. Devuelve el codBanco.
  Future<BigInt?> registrar(BancoRegistroEntity registro) =>
      _ejecutar(() => _repo.registrar(registro));

  /// Devuelve el codBanco eliminado.
  Future<BigInt?> eliminar(int codBanco) =>
      _ejecutar(() => _repo.eliminar(codBanco));
}

final operacionesBancosProvider =
    StateNotifierProvider<OperacionesBancosNotifier, EstadoOperacionBanco>(
      (ref) => OperacionesBancosNotifier(ref),
    );
