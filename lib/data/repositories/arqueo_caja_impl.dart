// Destino final: lib/data/repositories/arqueo_caja_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/domain/entities/vale_arqueo_entity.dart';
import 'package:bosque_flutter/domain/repositories/arqueo_caja_repository.dart';

class ArqueoCajaImpl extends BaseApiRepository implements ArqueoCajaRepository {
  @override
  Future<void> registrar({
    required int idTarRuti,
    required int idBitTarea,
    required double saldoMovSap,
    required double tc,
    String? obs,
    required Map<int, int> cantidadPorCorte,
    required Map<int, double> montoPorDoc,
    required List<ValeArqueoEntity> vales,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarArqueoCajaRegistrar,
      data: {
        'idTarRuti': idTarRuti,
        'idBitTarea': idBitTarea,
        'saldoMovSap': saldoMovSap,
        'tc': tc,
        'obs': obs,
        'cortes':
            cantidadPorCorte.entries
                .where((e) => e.value > 0)
                .map((e) => {'idCorte': e.key, 'cantidad': e.value})
                .toList(),
        'documentacion':
            montoPorDoc.entries
                .where((e) => e.value > 0)
                .map((e) => {'idDoc': e.key, 'monto': e.value})
                .toList(),
        'vales':
            vales
                .where((v) => v.esValido)
                .map(
                  (v) => {
                    'numVale': v.numVale,
                    'nombre': v.nombre,
                    'monto': v.monto,
                    'obs': v.obs.isEmpty ? null : v.obs,
                  },
                )
                .toList(),
      },
      errorMessage: 'No se pudo registrar el arqueo de caja.',
    );
  }

  /// Desglose de saldo SAP por caja de la sucursal de esta ocurrencia — el
  /// legacy lo muestra como una tabla, no un solo número manual.
  Future<List<Map<String, dynamic>>> saldoSap(int idBitTarea) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarArqueoCajaSaldoSap,
      data: {'idBitTarea': idBitTarea},
      fromJson: (json) => json,
    );
  }

  /// Tipo de cambio Hoy/Ayer (misma fuente real del legacy). Lista vacía si
  /// el servidor de tipo de cambio no está disponible — no es un error para
  /// el usuario, solo no hay con qué autocompletar.
  Future<List<Map<String, dynamic>>> tipoCambio() {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarArqueoCajaTipoCambio,
      fromJson: (json) => json,
    );
  }

  /// El arqueo anterior de esta sucursal (más reciente antes de hoy), como
  /// contexto/comparación. Lista vacía si es el primero.
  Future<List<Map<String, dynamic>>> arqueoAnterior(int idBitTarea) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarArqueoCajaAnterior,
      data: {'idBitTarea': idBitTarea},
      fromJson: (json) => json,
    );
  }
}
