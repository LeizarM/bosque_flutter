import 'package:bosque_flutter/domain/entities/ccr_solicitud_detalle_entity.dart';
import 'package:intl/intl.dart';

class CcrSolicitudDetalleModel {
  final CcrSolicitudDetalleEntity e;

  const CcrSolicitudDetalleModel(this.e);

  static double _d(dynamic v) => (v ?? 0).toDouble();
  static int _i(dynamic v) => (v ?? 0).toInt();
  static String _s(dynamic v) => v ?? '';

  static DateTime? _fecha(dynamic v) {
    if (v == null || v == '') return null;
    return DateTime.tryParse(v.toString());
  }

  factory CcrSolicitudDetalleModel.fromJson(Map<String, dynamic> j) =>
      CcrSolicitudDetalleModel(
        CcrSolicitudDetalleEntity(
          idSolicitudDetalle: _i(j['idSolicitudDetalle']),
          idSolicitud: _i(j['idSolicitud']),
          codigoSAPBase: _s(j['codigoSAPBase']),
          datoSAPBase: _s(j['datoSAPBase']),
          stockDisponibleSAPBase: _d(j['stockDisponibleSAPBase']),
          codTipoItemSAPBase: _i(j['codTipoItemSAPBase']),
          datoTipoItemSAPBase: _s(j['datoTipoItemSAPBase']),
          codFabricanteSAPBase: _i(j['codFabricanteSAPBase']),
          datoFabricanteSAPBase: _s(j['datoFabricanteSAPBase']),
          gramajeSAPBase: _d(j['gramajeSAPBase']),
          largoSAPBase: _d(j['largoSAPBase']),
          anchoSAPBase: _d(j['anchoSAPBase']),
          utmSAPBase: _d(j['utmSAPBase']),
          empaqueSAPBase: _s(j['empaqueSAPBase']),
          codigoSAPSalida: _s(j['codigoSAPSalida']),
          datoSAPSalida: _s(j['datoSAPSalida']),
          codTipoItemSAPSalida: _i(j['codTipoItemSAPSalida']),
          datoTipoItemSAPSalida: _s(j['datoTipoItemSAPSalida']),
          codFabricanteSAPSalida: _i(j['codFabricanteSAPSalida']),
          datoFabricanteSAPSalida: _s(j['datoFabricanteSAPSalida']),
          gramajeSAPSalida: _d(j['gramajeSAPSalida']),
          largoSAPSalida: _d(j['largoSAPSalida']),
          anchoSAPSalida: _d(j['anchoSAPSalida']),
          utmSAPSalida: _d(j['utmSAPSalida']),
          cantHojasSAPSalida: _d(j['cantHojasSAPSalida']),
          empaqueSAPSalida: _s(j['empaqueSAPSalida']),
          cantPaquetesSolicitados: _d(j['cantPaquetesSolicitados']),
          cantToneladasSolicitados: _d(j['cantToneladasSolicitados']),
          fechaEntrega: _fecha(j['fechaEntrega']),
          anchoSalidaEsp: _d(j['anchoSalidaEsp']),
          largoSalidaEsp: _d(j['largoSalidaEsp']),
          cantHojasSalidaEsp: _i(j['cantHojasSalidaEsp']),
          nroCortes: _i(j['nroCortes']),
          sapDocNum: _i(j['sapDocNum']),
          sapItemCode: _s(j['sapItemCode']),
          sapProdName: _s(j['sapProdName']),
          sapEstado: _s(j['sapEstado']),
          sapPlannedQty: _d(j['sapPlannedQty']),
          sapComments: _s(j['sapComments']),
          sapTipoCorte: _s(j['sapTipoCorte']),
          datoFecInicioStr: _s(j['datoFecInicioStr']),
          datoFecCierreStr: _s(j['datoFecCierreStr']),
          datoFechaEntregaStr: _s(j['datoFechaEntregaStr']),
          audUsuario: _i(j['audUsuario']),
        ),
      );

  /// Solo lo que el SP escribe: los campos `sap*` los llena SAP, no la app.
  Map<String, dynamic> toJson() {
    final fmt = DateFormat("yyyy-MM-dd'T'00:00:00.000");
    return {
      'idSolicitudDetalle': e.idSolicitudDetalle,
      'idSolicitud': e.idSolicitud,
      'codigoSAPBase': e.codigoSAPBase,
      'datoSAPBase': e.datoSAPBase,
      'stockDisponibleSAPBase': e.stockDisponibleSAPBase,
      'codTipoItemSAPBase': e.codTipoItemSAPBase,
      'datoTipoItemSAPBase': e.datoTipoItemSAPBase,
      'codFabricanteSAPBase': e.codFabricanteSAPBase,
      'datoFabricanteSAPBase': e.datoFabricanteSAPBase,
      'gramajeSAPBase': e.gramajeSAPBase,
      'largoSAPBase': e.largoSAPBase,
      'anchoSAPBase': e.anchoSAPBase,
      'utmSAPBase': e.utmSAPBase,
      'empaqueSAPBase': e.empaqueSAPBase,
      'codigoSAPSalida': e.codigoSAPSalida,
      'datoSAPSalida': e.datoSAPSalida,
      'codTipoItemSAPSalida': e.codTipoItemSAPSalida,
      'datoTipoItemSAPSalida': e.datoTipoItemSAPSalida,
      'codFabricanteSAPSalida': e.codFabricanteSAPSalida,
      'datoFabricanteSAPSalida': e.datoFabricanteSAPSalida,
      'gramajeSAPSalida': e.gramajeSAPSalida,
      'largoSAPSalida': e.largoSAPSalida,
      'anchoSAPSalida': e.anchoSAPSalida,
      'utmSAPSalida': e.utmSAPSalida,
      'cantHojasSAPSalida': e.cantHojasSAPSalida,
      'empaqueSAPSalida': e.empaqueSAPSalida,
      'cantPaquetesSolicitados': e.cantPaquetesSolicitados,
      'cantToneladasSolicitados': e.cantToneladasSolicitados,
      'fechaEntrega': e.fechaEntrega == null
          ? null
          : fmt.format(e.fechaEntrega!),
      'anchoSalidaEsp': e.anchoSalidaEsp,
      'largoSalidaEsp': e.largoSalidaEsp,
      'cantHojasSalidaEsp': e.cantHojasSalidaEsp,
      'nroCortes': e.nroCortes,
      'audUsuario': e.audUsuario,
    };
  }

  CcrSolicitudDetalleEntity toEntity() => e;

  factory CcrSolicitudDetalleModel.fromEntity(CcrSolicitudDetalleEntity e) =>
      CcrSolicitudDetalleModel(e);
}
