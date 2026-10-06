import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';

/// Todos los combos fijos de la pantalla de cheques, en una sola respuesta
/// (`/cheque/catalogos`). Son copias de v_tipos grupos 21 a 24 y de los combos
/// por boton del legacy.
class CatalogosChequeEntity {
  /// Vacio, para mostrar algo mientras llega la respuesta.
  static const CatalogosChequeEntity vacio = CatalogosChequeEntity(
    tiposCheque: [],
    monedas: [],
    estadosCheque: [],
    estadosAccion: [],
    accionesFechaCobro: [],
    accionesCierreConVerificacion: [],
    accionesCierreSinVerificacion: [],
  );

  /// PAG (pago) y RES (respaldo).
  final List<OpcionChequeEntity> tiposCheque;

  /// BS y la moneda extranjera.
  final List<OpcionChequeEntity> monedas;

  /// PEN y CER.
  final List<OpcionChequeEntity> estadosCheque;

  /// Todos los estados de accion (grupo 22), para las etiquetas del historial.
  final List<OpcionChequeEntity> estadosAccion;

  /// Lo que deja elegir «Fecha Cobro»: VEN y ADE.
  final List<OpcionChequeEntity> accionesFechaCobro;

  /// Lo que deja elegir «Cerrar con verificacion»: COB.
  final List<OpcionChequeEntity> accionesCierreConVerificacion;

  /// Lo que deja elegir «Cerrar sin verificacion»: CEF, CCH, PAP y DPR.
  final List<OpcionChequeEntity> accionesCierreSinVerificacion;

  const CatalogosChequeEntity({
    required this.tiposCheque,
    required this.monedas,
    required this.estadosCheque,
    required this.estadosAccion,
    required this.accionesFechaCobro,
    required this.accionesCierreConVerificacion,
    required this.accionesCierreSinVerificacion,
  });

  /// Nombre de un estado de accion, o el codigo mismo si no esta en el
  /// catalogo.
  String nombreEstadoAccion(String codigo) =>
      OpcionChequeEntity.nombreDe(estadosAccion, codigo) ?? codigo;
}
