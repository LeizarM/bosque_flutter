import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';

abstract class ConsumoTigoRepository{
Future<Map<String, dynamic>> subirExcel(Uint8List fileBytes, String fileName, int audUsuario);
  Future<List<FacturaTigoEntity>> obtenerFacturaTigo();
  Future<Map<String, dynamic>> subirExcelSocios(Uint8List fileBytes, String fileName, int audUsuario);
  Future<List<TigoEjecutadoEntity>> obtenerTotalXcuenta(String periodoCobrado);
  Future<List<SocioTigoEntity>> obtenerSociosTigo();
  Future<List<SocioTigoEntity>> registrarSocio(SocioTigoEntity socio);
  Future<List<TigoEjecutadoEntity>> obtenerResumenDetallado(String periodoCobrado);
  Future<List<TigoEjecutadoEntity>> obtenerResumenCuentas(String periodoCobrado);
  Future<bool> generarAnticiposTigo(String periodoCobrado);
  Future<List<SocioTigoEntity>> obtenerGruposTigo(String periodoCobrado);
  Future<bool> eliminarGrupo(int codCuenta);
   Future<bool> insertarTigoEjectuado(String periodoCobrado,int audUsuario);
  Future<List<TigoEjecutadoEntity>> obtenerTigoEjecutado(String empresa,String periodoCobrado);
  Future<List<SocioTigoEntity>> obtenerNroSinAsignar(String periodoCobrado);
  Future<List<TigoEjecutadoEntity>> obtenerArbolDetallado(String empresa,String periodoCobrado);
}