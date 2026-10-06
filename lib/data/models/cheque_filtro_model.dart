import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';

/// Cuerpo de `/cheque/listar`. Solo de ida.
///
/// Las claves sin valor no viajan: el backend las toma como «sin filtro». Las
/// fechas van como `yyyy-MM-dd`.
class ChequeFiltroModel {
  final ChequeFiltroEntity filtro;

  const ChequeFiltroModel._(this.filtro);

  factory ChequeFiltroModel.fromEntity(ChequeFiltroEntity e) =>
      ChequeFiltroModel._(e);

  Map<String, dynamic> toJson() {
    final f = filtro;
    final m = <String, dynamic>{
      'codSucursal': f.codSucursal,
      'nroCheque': _texto(f.nroCheque),
      'cliente': _texto(f.cliente),
      'tipo': _texto(f.tipo),
      'estado': _texto(f.estado),
      'codBanco': (f.codBanco == null || f.codBanco! <= 0) ? null : f.codBanco,
      'fechaCobro': f.fechaCobro == null ? null : fechaParaSql(f.fechaCobro!),
      'fechaRecepcionDesde':
          f.fechaRecepcionDesde == null
              ? null
              : fechaParaSql(f.fechaRecepcionDesde!),
      'fechaRecepcionHasta':
          f.fechaRecepcionHasta == null
              ? null
              : fechaParaSql(f.fechaRecepcionHasta!),
      'orden': f.orden.codigo,
      'pagina': f.pagina < 1 ? 1 : f.pagina,
      'tamanio': f.tamanio.clamp(1, ChequeFiltroEntity.tamanioMaximo),
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }

  static String? _texto(String? t) =>
      (t == null || t.trim().isEmpty) ? null : t.trim();
}
