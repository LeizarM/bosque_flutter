/// Las tres reglas que configuran el descuento por familia.
///
/// Van juntas en un archivo porque se administran desde la misma pantalla y se
/// leen de a tres; separarlas en tres archivos de veinte lineas cada uno hacia
/// mas dificil ver que son partes de la misma politica.
library;

/// Cuanto se paga de una familia SAP (tabla tcom_familiaPolitica).
///
/// [porcentajePago] es LO QUE SE PAGA, no lo que se descuenta: 50 significa que
/// ese item entra a la mitad, y 100 es no descontar nada. Es como lo pidio el
/// negocio -«se les va a dar el 50%»- y ademas hace que apagar la regla sea
/// poner 100, que se lee solo.
class FamiliaPoliticaEntity {
  const FamiliaPoliticaEntity({
    required this.idFamPolitica,
    required this.idGrpFamiliaSap,
    required this.grpFam,
    this.alias,
    required this.porcentajePago,
    required this.vigenteDesde,
    this.vigenteHasta,
    required this.activo,
    this.audFecha,
  });

  final int idFamPolitica;
  final int idGrpFamiliaSap;

  /// Nombre de la familia, p. ej. «Papel Bond Blanco».
  final String grpFam;
  final String? alias;

  /// En puntos porcentuales: 50 es la mitad.
  final double porcentajePago;

  final DateTime vigenteDesde;
  final DateTime? vigenteHasta;
  final int activo;
  final DateTime? audFecha;

  bool get estaActiva => activo == 1;

  /// Cuanto se descuenta, que es el complemento de lo que se paga.
  double get porcentajeDescuento => 100 - porcentajePago;

  /// Si con esta politica no se descuenta nada. Es el estado «apagada» sin
  /// tener que borrar la fila ni perder el historial.
  bool get sinEfecto => !estaActiva || porcentajePago >= 100;

  FamiliaPoliticaEntity copyWith({
    double? porcentajePago,
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
    bool limpiarVigenteHasta = false,
    int? activo,
  }) => FamiliaPoliticaEntity(
    idFamPolitica: idFamPolitica,
    idGrpFamiliaSap: idGrpFamiliaSap,
    grpFam: grpFam,
    alias: alias,
    porcentajePago: porcentajePago ?? this.porcentajePago,
    vigenteDesde: vigenteDesde ?? this.vigenteDesde,
    vigenteHasta:
        limpiarVigenteHasta ? null : (vigenteHasta ?? this.vigenteHasta),
    activo: activo ?? this.activo,
    audFecha: audFecha,
  );
}

/// Vendedor al que NO se le aplica el descuento (tabla tcom_vendedorExentoBond).
///
/// Para los supervisores la exencion se evalua sobre el que cobra, no sobre el
/// vendedor de la nota: por eso Alexandro Zaballa comisiona sobre el total sin
/// descontar mientras Paolo y Alvaro no.
class VendedorExentoEntity {
  const VendedorExentoEntity({
    required this.idVenExento,
    required this.idVendedor,
    this.nomVenSAP,
    required this.vigenteDesde,
    this.vigenteHasta,
    required this.activo,
    this.motivo,
  });

  final int idVenExento;
  final int idVendedor;
  final String? nomVenSAP;
  final DateTime vigenteDesde;
  final DateTime? vigenteHasta;
  final int activo;
  final String? motivo;

  bool get estaActiva => activo == 1;
}

/// Cliente cuyas notas no cuentan para el total de un vendedor
/// (tabla tcom_vendedorClienteExcluido).
///
/// No tiene nada que ver con el descuento por familia: es otra regla. Vivia
/// escrita a mano dentro de p_list_paraPagar y se trajo a tabla para que el
/// proximo cliente sea una fila y no un ALTER PROCEDURE.
class ClienteExcluidoEntity {
  const ClienteExcluidoEntity({
    required this.idVenCliExc,
    required this.idVendedor,
    this.nomVenSAP,
    required this.cardCode,
    this.origen,
    required this.vigenteDesde,
    this.vigenteHasta,
    required this.activo,
    this.motivo,
  });

  final int idVenCliExc;
  final int idVendedor;
  final String? nomVenSAP;
  final String cardCode;

  /// Empresa. En null significa «en todas»: el mismo cardCode puede existir en
  /// IMPEXPAP y en ESPPAPEL.
  final String? origen;

  final DateTime vigenteDesde;
  final DateTime? vigenteHasta;
  final int activo;
  final String? motivo;

  bool get estaActiva => activo == 1;
  String get empresa => origen ?? 'Todas';
}

/// Una familia de SAP como opcion para elegir al crear una politica.
///
/// Los tres codigos son el mismo grupo en cada empresa: SAP les da numeros
/// distintos en IMPEXPAP, ESPPAPEL y PRODUCTIVA PAPEL.
class FamiliaSapOpcionEntity {
  const FamiliaSapOpcionEntity({
    required this.idGrpFamiliaSap,
    required this.grpFam,
    this.alias,
    this.codIpx,
    this.codEpp,
    this.codPrp,
    required this.tienePolitica,
  });

  final int idGrpFamiliaSap;
  final String grpFam;
  final String? alias;
  final String? codIpx;
  final String? codEpp;
  final String? codPrp;

  /// Si ya tiene una politica activa. Se muestra pero no se ofrece.
  final bool tienePolitica;

  /// Los codigos SAP en una linea, para mostrar de que grupo se habla.
  String get codigos => [
    if (codIpx != null) 'IPX $codIpx',
    if (codEpp != null) 'EPP $codEpp',
    if (codPrp != null) 'PRP $codPrp',
  ].join(' · ');
}

/// Una linea de lo que se descuenta por familia.
///
/// Es la union de dos vistas del mismo hecho, por eso casi todo es nullable:
///   - periodo abierto (P): lo que esta por pagarse, con el porcentaje resuelto
///     contra la politica vigente el dia de la factura;
///   - historico (H): lo que quedo congelado al pagar, que es lo unico que
///     reconstruye el pasado si hoy los porcentajes son otros.
class DescuentoDetalleEntity {
  const DescuentoDetalleEntity({
    this.docNum,
    this.empresa,
    this.fechaDoc,
    this.idVendedor,
    this.nombreVen,
    this.cardCode,
    this.grupoFamilia,
    this.codGrupoSap,
    this.itemCode,
    this.itemName,
    this.cantidad,
    this.montoItemBs,
    this.porcentajePago,
    this.porcentajeDescuento,
    this.descuentoBs,
    this.montoBaseNotaBs,
    this.montoNotaAjustadoBs,
    this.comisionBs,
    this.detalleBond,
    this.vendedorExento = false,
    this.esHistorico = false,
    this.notas,
    this.items,
    this.unidades,
    this.montoItemsBs,
  });

  final int? docNum;
  final String? empresa;
  final DateTime? fechaDoc;
  final int? idVendedor;
  final String? nombreVen;
  final String? cardCode;

  final String? grupoFamilia;
  final int? codGrupoSap;
  final String? itemCode;
  final String? itemName;
  final double? cantidad;
  final double? montoItemBs;

  final double? porcentajePago;
  final double? porcentajeDescuento;
  final double? descuentoBs;

  final double? montoBaseNotaBs;
  final double? montoNotaAjustadoBs;
  final double? comisionBs;
  final String? detalleBond;

  /// El descuento se calcula igual, pero no se le aplica a este vendedor.
  final bool vendedorExento;

  final bool esHistorico;

  // Solo en el resumen.
  final int? notas;
  final int? items;
  final double? unidades;
  final double? montoItemsBs;
}
