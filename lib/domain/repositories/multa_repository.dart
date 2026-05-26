import 'package:bosque_flutter/data/models/multas_model.dart';
import 'package:bosque_flutter/domain/entities/multa_entity.dart';

abstract class MultaRepository {
  Future<List<MultaEntity>> getMultas(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    int? mes,
    int? anio,
    bool soloConMulta,
  );

  Future<MultaResponse> generarMultas({
    required int mes,
    required int anio,
    required int audUsuarioI,
  });

  Future<MultaResponse> editarTodasMultasMasivo(
    String xmlMultas,
    int audUsuarioI,
    int mes,
    int anio,
  );
}
