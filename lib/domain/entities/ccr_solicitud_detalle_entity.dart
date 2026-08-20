import 'package:bosque_flutter/domain/entities/item_sap_entity.dart';

/// Un item de una solicitud de corte (`tccr_ccrSolicitudDetalle`).
///
/// Tres bloques:
///
/// - **Base**: el articulo que entra a cortarse, copiado del catalogo SAP.
/// - **Salida**: como sale. En las solicitudes ESPECIALES la salida es el mismo
///   articulo que entra, asi que estos campos se copian de los Base — la tabla
///   los exige NOT NULL. Lo que define el corte especial son [anchoSalidaEsp],
///   [largoSalidaEsp], [cantHojasSalidaEsp] y [nroCortes].
/// - **sap***: los llena SAP cuando toma la solicitud. Aqui son de solo lectura.
class CcrSolicitudDetalleEntity {
  final int idSolicitudDetalle;
  final int idSolicitud;

  // ── Articulo que entra ────────────────────────────────────────────────────
  final String codigoSAPBase;
  final String datoSAPBase;
  final double stockDisponibleSAPBase;
  final int codTipoItemSAPBase;
  final String datoTipoItemSAPBase;
  final int codFabricanteSAPBase;
  final String datoFabricanteSAPBase;
  final double gramajeSAPBase;
  final double largoSAPBase;
  final double anchoSAPBase;
  final double utmSAPBase;
  final String empaqueSAPBase;

  // ── Articulo que sale ─────────────────────────────────────────────────────
  final String codigoSAPSalida;
  final String datoSAPSalida;
  final int codTipoItemSAPSalida;
  final String datoTipoItemSAPSalida;
  final int codFabricanteSAPSalida;
  final String datoFabricanteSAPSalida;
  final double gramajeSAPSalida;
  final double largoSAPSalida;
  final double anchoSAPSalida;
  final double utmSAPSalida;
  final double cantHojasSAPSalida;
  final String empaqueSAPSalida;

  // ── Lo que se pide ────────────────────────────────────────────────────────
  final double cantPaquetesSolicitados;
  final double cantToneladasSolicitados;
  final DateTime? fechaEntrega;

  // ── El corte especial ─────────────────────────────────────────────────────
  final double anchoSalidaEsp;
  final double largoSalidaEsp;
  final int cantHojasSalidaEsp;
  final int nroCortes;

  // ── Lo que devuelve SAP ───────────────────────────────────────────────────
  final int sapDocNum;
  final String sapItemCode;
  final String sapProdName;
  final String sapEstado;
  final double sapPlannedQty;
  final String sapComments;
  final String sapTipoCorte;
  final String datoFecInicioStr;
  final String datoFecCierreStr;
  final String datoFechaEntregaStr;

  final int audUsuario;

  const CcrSolicitudDetalleEntity({
    this.idSolicitudDetalle = 0,
    this.idSolicitud = 0,
    required this.codigoSAPBase,
    required this.datoSAPBase,
    this.stockDisponibleSAPBase = 0,
    this.codTipoItemSAPBase = 0,
    this.datoTipoItemSAPBase = '',
    this.codFabricanteSAPBase = 0,
    this.datoFabricanteSAPBase = '',
    this.gramajeSAPBase = 0,
    this.largoSAPBase = 0,
    this.anchoSAPBase = 0,
    this.utmSAPBase = 0,
    this.empaqueSAPBase = '',
    this.codigoSAPSalida = '',
    this.datoSAPSalida = '',
    this.codTipoItemSAPSalida = 0,
    this.datoTipoItemSAPSalida = '',
    this.codFabricanteSAPSalida = 0,
    this.datoFabricanteSAPSalida = '',
    this.gramajeSAPSalida = 0,
    this.largoSAPSalida = 0,
    this.anchoSAPSalida = 0,
    this.utmSAPSalida = 0,
    this.cantHojasSAPSalida = 0,
    this.empaqueSAPSalida = '',
    this.cantPaquetesSolicitados = 0,
    required this.cantToneladasSolicitados,
    this.fechaEntrega,
    this.anchoSalidaEsp = 0,
    this.largoSalidaEsp = 0,
    this.cantHojasSalidaEsp = 0,
    this.nroCortes = 0,
    this.sapDocNum = 0,
    this.sapItemCode = '',
    this.sapProdName = '',
    this.sapEstado = '',
    this.sapPlannedQty = 0,
    this.sapComments = '',
    this.sapTipoCorte = '',
    this.datoFecInicioStr = '',
    this.datoFecCierreStr = '',
    this.datoFechaEntregaStr = '',
    this.audUsuario = 0,
  });

  /// Arma un item nuevo a partir de un articulo del catalogo SAP.
  ///
  /// La salida se copia de la base: en una solicitud especial el articulo que
  /// sale es el mismo que entra, solo cambia como se corta. La tabla exige esos
  /// campos NOT NULL, asi que no alcanza con dejarlos vacios.
  factory CcrSolicitudDetalleEntity.desdeItemSap(
    ItemSapEntity item, {
    required double cantToneladasSolicitados,
    required double anchoSalidaEsp,
    required double largoSalidaEsp,
    required int cantHojasSalidaEsp,
    required int nroCortes,
    required DateTime fechaEntrega,
  }) {
    return CcrSolicitudDetalleEntity(
      codigoSAPBase: item.codItem,
      datoSAPBase: item.datoItem,
      stockDisponibleSAPBase: item.cantidadDisponible,
      codTipoItemSAPBase: item.codTipo,
      datoTipoItemSAPBase: item.datoTipo,
      codFabricanteSAPBase: item.codFabricante,
      datoFabricanteSAPBase: item.datoFabricante,
      gramajeSAPBase: item.gramaje,
      largoSAPBase: item.largo,
      anchoSAPBase: item.ancho,
      utmSAPBase: item.utm,
      empaqueSAPBase: item.empaque,
      // Salida = base.
      codigoSAPSalida: item.codItem,
      datoSAPSalida: item.datoItem,
      codTipoItemSAPSalida: item.codTipo,
      datoTipoItemSAPSalida: item.datoTipo,
      codFabricanteSAPSalida: item.codFabricante,
      datoFabricanteSAPSalida: item.datoFabricante,
      gramajeSAPSalida: item.gramaje,
      largoSAPSalida: item.largo,
      anchoSAPSalida: item.ancho,
      utmSAPSalida: item.utm,
      cantHojasSAPSalida: item.cantHojas,
      empaqueSAPSalida: item.empaque,
      cantToneladasSolicitados: cantToneladasSolicitados,
      cantPaquetesSolicitados: calcularPaquetes(
        cantidad: cantToneladasSolicitados,
        gramaje: item.gramaje,
        ancho: anchoSalidaEsp,
        largo: largoSalidaEsp,
        cantHojas: cantHojasSalidaEsp.toDouble(),
      ),
      fechaEntrega: fechaEntrega,
      anchoSalidaEsp: anchoSalidaEsp,
      largoSalidaEsp: largoSalidaEsp,
      cantHojasSalidaEsp: cantHojasSalidaEsp,
      nroCortes: nroCortes,
    );
  }

  /// Paquetes que salen de los kilos pedidos, con la formula del sistema
  /// anterior: kilos / (gramaje/1000 * ancho/100 * largo/100 * hojas).
  ///
  /// Devuelve 0 si algun factor es cero, en vez de infinito.
  static double calcularPaquetes({
    required double cantidad,
    required double gramaje,
    required double ancho,
    required double largo,
    required double cantHojas,
  }) {
    final divisor = (gramaje / 1000) * (ancho / 100) * (largo / 100) * cantHojas;
    if (divisor <= 0) return 0;
    return cantidad / divisor;
  }
}
