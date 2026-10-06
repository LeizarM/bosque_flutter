import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/data/repositories/actualizar_socios_sap_impl.dart';
import 'package:bosque_flutter/domain/entities/actualizar_socios_sap_entity.dart';
import 'package:bosque_flutter/domain/repositories/actualizar_socios_sap_repository.dart';

/// Repositorio de «Actualizar datos SAP». Perezoso y tipado contra la interfaz:
/// una prueba lo sustituye con
/// `actualizarSociosSapRepositoryProvider.overrideWithValue(falso)`.
final actualizarSociosSapRepositoryProvider =
    Provider<ActualizarSociosSapRepository>((ref) => ActualizarSociosSapImpl());

@immutable
class EstadoActualizarSociosSap {
  const EstadoActualizarSociosSap({
    this.ocupado = false,
    this.resultado,
    this.error,
  });

  /// La actualizacion esta en vuelo. Una sola a la vez: un segundo toque no
  /// manda nada (el servidor tambien rechaza una segunda en paralelo).
  final bool ocupado;

  /// La frase del servidor de la ultima actualizacion que salio bien (sin
  /// numero de clientes: no lo informa); null si todavia no hubo una o si la
  /// ultima fallo.
  final ActualizarSociosSapEntity? resultado;

  /// El texto completo del servidor de la ultima actualizacion fallida, tal
  /// cual, listo para mostrar (sin permiso, otra en curso, SAP sin responder).
  final String? error;
}

/// «Actualizar datos SAP»: una escritura que no depende de la empresa ni de la
/// sucursal de la grilla. Al salir bien deja viejo lo que lee los clientes: el
/// combo de cada empresa (`clientesChequeProvider`) y la grilla, donde ahora
/// pueden aparecer cheques cuyo cliente antes no estaba cargado.
///
/// autoDispose: el estado vive lo que vive el dialogo, asi que un error o un
/// resultado de la vez anterior no aparece al abrirlo de nuevo.
class ActualizarSociosSapNotifier
    extends StateNotifier<EstadoActualizarSociosSap> {
  ActualizarSociosSapNotifier(this._ref)
    : super(const EstadoActualizarSociosSap());

  final Ref _ref;

  /// Pide la actualizacion. Devuelve su resultado, o null si fallo (el motivo
  /// queda en `state.error`) o si ya habia una en curso.
  Future<ActualizarSociosSapEntity?> actualizar() async {
    if (state.ocupado) return null;
    state = const EstadoActualizarSociosSap(ocupado: true);
    try {
      final r =
          await _ref.read(actualizarSociosSapRepositoryProvider).actualizar();
      if (!mounted) return r;
      _refrescar();
      state = EstadoActualizarSociosSap(resultado: r);
      return r;
    } catch (e) {
      if (mounted) {
        state = EstadoActualizarSociosSap(error: mensajeDeErrorCheque(e));
      }
      return null;
    }
  }

  /// Los clientes de cada empresa se vuelven a pedir cuando alguien los lee (el
  /// combo del formulario), y la grilla solo se relee si hay una pantalla
  /// usandola.
  void _refrescar() {
    _ref.invalidate(clientesChequeProvider);
    if (_ref.exists(grillaChequesProvider)) {
      _ref.read(grillaChequesProvider.notifier).recargar();
    }
  }
}

final actualizarSociosSapProvider = StateNotifierProvider.autoDispose<
  ActualizarSociosSapNotifier,
  EstadoActualizarSociosSap
>((ref) => ActualizarSociosSapNotifier(ref));
