// Destino final: lib/data/repositories/caja_fuerte_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/cierre_operaciones_model.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';
import 'package:bosque_flutter/domain/repositories/caja_fuerte_repository.dart';

class CajaFuerteImpl extends BaseApiRepository implements CajaFuerteRepository {
  @override
  Future<int> registrar({
    required List<LlegadaCajaFuerteEntity> llegadas,
  }) async {
    final resultado = await postAndReturnId(
      endpoint: AppConstants.tarCajaFuerteRegistrar,
      data: {
        'llegadas':
            llegadas
                .map(
                  (l) => {
                    'cliente': l.cliente,
                    'moneda': l.moneda,
                    'importe': l.importe,
                    'tipo': l.tipo,
                    'destino': l.destino.isEmpty ? null : l.destino,
                    'obs': l.obs.isEmpty ? null : l.obs,
                  },
                )
                .toList(),
      },
      errorMessage: 'No se pudo registrar la caja fuerte.',
    );
    return resultado.toInt();
  }

  @override
  Future<List<LlegadaDelCierre>> registradasHoy() => postAndReturnList(
    endpoint: AppConstants.tarCajaFuerteDelDia,
    data: const {},
    fromJson: CierreOperacionesModel.llegada,
  );
}
