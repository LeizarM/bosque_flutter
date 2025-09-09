import 'package:bosque_flutter/domain/entities/compra_garrafa_entity.dart';
import 'package:bosque_flutter/domain/entities/contenedor_entity.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_contenedor_entity.dart';

abstract class ControlCombustibleMaquinaMontacargaRepository {
  Future<bool> registerControlCombustibleMaquinaMontacarga(
    ControlCombustibleMaquinaMontacargaEntity mb,
  );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> obtenerAlmacenes();

  Future<List<MaquinaMontacargaEntity>> obtenerMaquinasMontacargas();

  Future<List<ControlCombustibleMaquinaMontacargaEntity>>
  lstRptMovBidonesXTipoTransaccion(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codSucursal,
  );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> lstBidonesXSucursal();

  Future<List<ControlCombustibleMaquinaMontacargaEntity>>
  lstBidonesUltimosMov();

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> listBidonesPendientes(
    int codSucursalMaqVehiDestino,
  );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> listDetalleBidon(
    dynamic idCM,
  );

  /// ==============================
  /// ======= NUEVOS METODOS PARA REGISTRAR LOS BIDONES
  /// ==============================

  Future<List<ContenedorEntity>> lstContenedores();

  Future<bool> registerMovimiento(MovimientoEntity mb);

  Future<List<SucursalEntity>> lstSucursal();

  Future<bool> registerCompraGarrafa(CompraGarrafaEntity garrafa);

  Future<List<TipoContenedorEntity>> lstTipoContenedor();

  Future<List<MovimientoEntity>> lstMovimientos(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codSucursal,
    int idTipo,
  );

  Future<List<MovimientoEntity>> lstSaldosActuales();
}
