import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/bono_model.dart';
import 'package:bosque_flutter/data/models/bono_empleado_model.dart';
import 'package:bosque_flutter/domain/entities/bono_entity.dart';
import 'package:bosque_flutter/domain/entities/bono_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/bono_repository.dart';

class BonoImpl extends BaseApiRepository implements BonoRepository {
  @override
  Future<List<BonoEntity>> listarBono({
    required int pagina,
    required int tamanoPagina,
    String? tipoBono,
    String? estado,
    int? filtroMes,
    int? filtroAnio,
  }) async {
    final modelos = await postAndReturnList<BonoModel>(
      endpoint: AppConstants.bonoListarBono,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'tipoBono': tipoBono,
        'estado': estado,
        'filtroMes': filtroMes,
        'filtroAnio': filtroAnio,
      },
      fromJson: (json) => BonoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<BonoEmpleadoEntity>> listarBonoEmpleado({
    required int pagina,
    required int tamanoPagina,
    required int codBono,
    String? search,
    int? soloBono,
  }) async {
    final modelos = await postAndReturnList<BonoEmpleadoModel>(
      endpoint: AppConstants.bonoListarBonoEmpleado,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codBono': codBono,
        'search': search,
        'soloBono': soloBono,
      },
      fromJson: (json) => BonoEmpleadoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BonoResponse> abmBono({int? codBono, required int audUsuarioI}) async {
    final responseMap = await postAndReturnFullResponse<BonoResponse>(
      endpoint: AppConstants.bonoAbmBono,
      data: {'codBono': codBono, 'audUsuarioI': audUsuarioI},
      fromJson: (json) => BonoResponse.fromJson(json),
    );
    return responseMap;
  }
}
