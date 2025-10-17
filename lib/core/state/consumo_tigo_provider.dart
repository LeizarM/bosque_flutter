import 'dart:typed_data';
import 'package:bosque_flutter/data/repositories/consumo_tigo_impl.dart';
import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subirExcelFacturasTigoProvider = FutureProvider.family<Map<String, dynamic>, (Uint8List, String, int)>(
  (ref, params) async {
    final repo = ConsumoTigoImpl();
    final resultado = await repo.subirExcel(params.$1, params.$2, params.$3);
    return resultado;
  },
);
//obtener excel de facturas tigo
final facturasTigoProvider = FutureProvider<List<FacturaTigoEntity>>((ref) async {
  final repo = ConsumoTigoImpl();
  final facturas = await repo.obtenerFacturaTigo();
  return facturas;
});
//subir socios tigo
final subirExcelSociosTigoProvider = FutureProvider.family<Map<String, dynamic>, (Uint8List, String, int)>(
  (ref, params) async {
    final repo = ConsumoTigoImpl();
    final resultado = await repo.subirExcelSocios(params.$1, params.$2, params.$3);
    return resultado;
  },
);
//obtener excel de facturas tigo
final tigoTotalXCuenta = FutureProvider.family<List<TigoEjecutadoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final totalXCuenta = await repo.obtenerTotalXcuenta(periodoCobrado);
  return totalXCuenta;
});
//OBTENER GRUPOS (SOCIOS TIGO)

final obtenerSociosTigo = FutureProvider<List<SocioTigoEntity>>((ref) async {
  final repo = ConsumoTigoImpl();
  final sociosTigo = await repo.obtenerSociosTigo();
  return sociosTigo;
});
//registrar socio tigo
final registrarSocioTigo = FutureProvider.family<List<SocioTigoEntity>, SocioTigoEntity>(
  (ref, socio) async {
    final repo = ConsumoTigoImpl();
    return await repo.registrarSocio(socio);
  },
);
//obtener resumen por cuenta tigo
final tigoResumenXCuenta = FutureProvider.family<List<TigoEjecutadoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final resumenXCuenta = await repo.obtenerResumenCuentas(periodoCobrado);
  return resumenXCuenta;
});
//obtener resumen DETALLADO por cuenta tigo
final tigoResumenDetallado = FutureProvider.family<List<TigoEjecutadoEntity>, String>((ref, periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final resumenDetallado = await repo.obtenerResumenDetallado(periodoCobrado);
  return resumenDetallado;
});
//INSERTAR ANTICIPOS TIGO
final insertarAnticipoTigo = FutureProvider.family<bool, String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  return await repo.generarAnticiposTigo(periodoCobrado);
});
//descargar reporte tigo
final jasperPdfFacturasTigoProvider = FutureProvider.family<Uint8List,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  return await repo.descargarReporteFacturasTigo(periodoCobrado); // Este método debe retornar Uint8List
});
//OBTENER grupos TIGO
final obtenerGruposTigo = FutureProvider.family<List<SocioTigoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final sociosTigo = await repo.obtenerGruposTigo(periodoCobrado);
  return sociosTigo;
});
//ELIMINAR GRUPO TIGO
final eliminarGrupoTigo = FutureProvider.family<void, int>(
  (ref, codCuenta) async {
    final repo = ConsumoTigoImpl();
    await repo.eliminarGrupo(codCuenta);
  },
);
//INSERTAR TIGO EJECUTADO
final ejecutarTigo = FutureProvider.family<bool, (String,int)>((ref,params) async {
  final repo = ConsumoTigoImpl();
  return await repo.insertarTigoEjectuado(params.$1,params.$2);
});
//obtener tigo ejecutado
final obtenerTigoEjecutado= FutureProvider.family<List<TigoEjecutadoEntity>,(String?, String)>((ref,params) async {
  final repo = ConsumoTigoImpl();
  final getTigoEjecutado = await repo.obtenerTigoEjecutado(params.$1,params.$2);
  return getTigoEjecutado;
});
//obtener nros sin asignar
final obtenerNroSinAsignar= FutureProvider.family<List<SocioTigoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final getNrosSinAsignar = await repo.obtenerNroSinAsignar(periodoCobrado);
  return getNrosSinAsignar;
});
final tigoArbolDetallado = FutureProvider.family<List<TigoEjecutadoEntity>,(String?, String)>((ref, params) async {
  final repo = ConsumoTigoImpl();
  final arbolResumenDetallado = await repo.obtenerArbolDetallado(params.$1,params.$2);
  return arbolResumenDetallado;
});