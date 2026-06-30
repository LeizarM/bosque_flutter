import 'package:bosque_flutter/domain/entities/bono_entity.dart';
import 'package:bosque_flutter/domain/entities/bono_empleado_entity.dart';
import 'package:bosque_flutter/data/models/bono_model.dart';

abstract class BonoRepository {
  Future<List<BonoEntity>> listarBono({
    required int pagina,
    required int tamanoPagina,
    String? tipoBono,
    String? estado,
    int? filtroMes,
    int? filtroAnio,
  });

  Future<List<BonoEmpleadoEntity>> listarBonoEmpleado({
    required int pagina,
    required int tamanoPagina,
    required int codBono,
    String? search,
    int? soloBono,
  });

  Future<BonoResponse> abmBono({int? codBono, required int audUsuarioI});
}
