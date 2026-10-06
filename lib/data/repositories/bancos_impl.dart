import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/banco_model.dart';
import 'package:bosque_flutter/data/models/banco_registro_model.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/repositories/bancos_repository.dart';

/// Bancos (vista 43) contra el backend Spring.
///
/// `listar` lee `bncGetBancos`, que devuelve una lista pelada (no `ApiResponse`);
/// `postAndReturnList` acepta las dos formas y deja pasar los errores, a
/// diferencia de `RegistroEmpleadoImpl.getBancos`. El `message` de un 400 es
/// texto de negocio y llega tal cual.
class BancosImpl extends BaseApiRepository implements BancosRepository {
  @override
  Future<List<BancoEntity>> listar() async {
    final modelos = await postAndReturnList<BancoModel>(
      endpoint: AppConstants.bncGetBancos,
      fromJson: BancoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(BancoRegistroEntity registro) => postAndReturnId(
    endpoint: AppConstants.bncRegistrar,
    data: BancoRegistroModel.fromEntity(registro).toJson(),
    errorMessage: 'No se pudo guardar el banco.',
  );

  @override
  Future<BigInt> eliminar(int codBanco) => postAndReturnId(
    endpoint: AppConstants.bncEliminar,
    data: {'id': codBanco},
    errorMessage: 'No se pudo eliminar el banco.',
  );
}
