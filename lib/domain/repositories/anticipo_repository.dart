import 'package:bosque_flutter/data/models/anticipo_model.dart';
import 'package:bosque_flutter/domain/entities/anticipo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';

abstract class AnticipoRepository {
  Future<List<AnticipoEntity>> getAnticiposSAP(
    int pagina,
    int tamanoPagina,
    int codEmpresa,
    String? search,
    String? mes,
    String? anio,
  );
  Future<List<AnticipoEntity>> getAnticiposBosque(
    int pagina,
    int tamanoPagina,
    int codEmpresa,
    String? search,
    String? estado,
  );
  Future<List<AnticipoDetalleEntity>> getAnticipoDetallado(
    int codAnticipo,
    int? pagina,
    int? tamanoPagina,
    String? search,
  );
  Future<List<AnticipoEntity>> getAnticipos(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    String? estado,
    String? mes,
    String? anio,
  );
  // --- ABMs (Ahora devuelven AnticipoResponse) ---
  Future<AnticipoResponse> asignarAnticipo({
    required AnticipoEntity cabecera,
    required List<int> codAntDetalles,
    required int audUsuarioI,
  });

  Future<AnticipoResponse> asignarAnticipoManual({
    required AnticipoEntity cabecera,
    required String xmlEmpleados,
    required int audUsuarioI,
  });

  Future<AnticipoResponse> editarAsignacionManual({
    required AnticipoEntity cabecera,
    required String xmlEmpleados,
    required int audUsuarioI,
  });

  Future<AnticipoResponse> anularAnticipo({
    required int codAnticipo,
    required int audUsuarioI,
  });
}
