import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/chip_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_renovacion_chip_tigo_entity.dart';

abstract class ConsumoTigoRepository {
  Future<Map<String, dynamic>> subirExcel(
    Uint8List fileBytes,
    String fileName,
    int audUsuario,
  );
  Future<List<FacturaTigoEntity>> obtenerFacturaTigo();
  Future<Map<String, dynamic>> subirExcelSocios(
    Uint8List fileBytes,
    String fileName,
    int audUsuario,
  );
  Future<List<TigoEjecutadoEntity>> obtenerTotalXcuenta(String periodoCobrado);
  Future<List<SocioTigoEntity>> obtenerSociosTigo();
  Future<List<SocioTigoEntity>> registrarSocio(SocioTigoEntity socio);
  Future<List<TigoEjecutadoEntity>> obtenerResumenDetallado(
    String periodoCobrado,
  );
  Future<List<TigoEjecutadoEntity>> obtenerResumenCuentas(
    String periodoCobrado,
  );
  Future<bool> generarAnticiposTigo(String periodoCobrado);
  Future<List<SocioTigoEntity>> obtenerGruposTigo(String periodoCobrado);
  Future<bool> eliminarGrupo(int codCuenta);
  Future<bool> insertarTigoEjectuado(String periodoCobrado, int audUsuario);
  Future<List<TigoEjecutadoEntity>> obtenerTigoEjecutado(
    String? empresa,
    String periodoCobrado,
    String? search,
  );
  Future<List<SocioTigoEntity>> obtenerNroSinAsignar(String periodoCobrado);
  Future<List<TigoEjecutadoEntity>> obtenerArbolDetallado(
    String? empresa,
    String periodoCobrado,
    String? search,
  );
  Future<bool> actualizarEmpresaLote(TigoEjecutadoEntity tigoEjecutado);
  //nuevo
  Future<String> registrarPerdidaChip(ChipTigoEntity entity);
  Future<bool> eliminarRegistroPerdida(ChipTigoEntity entity);
  Future<List<ChipTigoEntity>> listarChipsPerdidos(ChipTigoEntity filtro);
  Future<List<String>> obtenerPeriodos();
  Future<List<TipoRenovacionChipTigoEntity>> obtenerTipoRenovacion();
  Future<Uint8List> descargarRptPerdidaLineas(String periodo);
  Future<List<String>> obtenerPeriodosCambio();
  Future<Uint8List> descargarRptCambiosLineaTigo(String periodo);
  Future<Uint8List> descargarRptCorporativosPersonal(String periodoCobrado);
  Future<Uint8List> descargarRptComparacionEmpresas();
  Future<List<String>> obtenerPeriodosFactura();
  Future<List<String>> listarEmpresasTigo();
}
