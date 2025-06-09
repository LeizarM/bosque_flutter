import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_montacarga_entity.dart';

abstract class ControlCombustibleMaquinaMontacargaRepository {
  
  Future<bool> registerControlCombustibleMaquinaMontacarga( ControlCombustibleMaquinaMontacargaEntity mb );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> obtenerAlmacenes();

  Future<List<MaquinaMontacargaEntity>> obtenerMaquinasMontacargas();

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> lstRptMovBidonesXTipoTransaccion( DateTime fechaInicio, DateTime fechaFin ); 

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> lstBidonesXSucursal();

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> lstBidonesUltimosMov( );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> listBidonesPendientes( int codSucursalMaqVehiDestino );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> listDetalleBidon( dynamic idCM );

}