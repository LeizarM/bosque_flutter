import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/ccr_solicitud_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/item_sap_entity.dart';

abstract class SolicitudCorteRepository {
  /// Solicitudes de un rango de fechas.
  Future<List<CcrSolicitudEntity>> obtenerSolicitudes(
    DateTime desde,
    DateTime hasta,
  );

  /// Los items de una solicitud, con lo que devolvio SAP.
  Future<List<CcrSolicitudDetalleEntity>> obtenerDetalle(int idSolicitud);

  /// Busca en el catalogo de items SAP que se pueden cortar.
  ///
  /// El filtrado lo hace el servidor: son ~1.500 items y traerlos todos eran
  /// 550 KB por cada apertura del formulario.
  Future<List<ItemSapEntity>> buscarItemsSap({
    required String texto,
    int limite = 50,
  });

  /// Cuantos items tiene el catalogo, para poder decir entre cuantos se busca.
  Future<int> totalItemsSap();

  /// Registra la solicitud con todos sus items. Devuelve el id generado.
  ///
  /// Lanza el mensaje del backend como String si la validacion falla, para
  /// mostrarlo tal cual.
  Future<int> registrarSolicitud({
    required CcrSolicitudEntity solicitud,
    required List<CcrSolicitudDetalleEntity> detalle,
  });

  /// Cancela una solicitud con su motivo.
  Future<void> cancelarSolicitud({
    required int idSolicitud,
    required String motivo,
    required int audUsuario,
  });

  /// La boleta de una solicitud en PDF.
  Future<Uint8List> reporteSolicitudPdf(int idSolicitud);

  /// Resumen de solicitudes entre fechas.
  Future<Uint8List> reporteResumenPdf(DateTime desde, DateTime hasta);
}
