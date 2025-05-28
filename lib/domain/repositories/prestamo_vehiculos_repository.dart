import 'package:bosque_flutter/domain/entities/estado_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';

abstract class PrestamoVehiculosRepository {
  
  Future<bool> registerSolicitudChofer(SolicitudChoferEntity mb);

  
  Future<List<SolicitudChoferEntity>> obtainSolicitudes(  int codEmpleado );


  Future<List<EstadoChoferEntity>> lstEstados();
  
  
  Future<bool> registerPrestamo(PrestamoChoferEntity mb);


  Future<List<SolicitudChoferEntity>> obtainCoches();

  Future<List<PrestamoChoferEntity>> lstSolicitudesPretamos( int codSucursal, int codEmpEntregadoPor );

  Future<bool> actualizarSolicitud( SolicitudChoferEntity mb );

  Future<List<TipoSolicitudEntity>> lstTipoSolicitudes();



}