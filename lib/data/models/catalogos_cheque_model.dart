import 'package:bosque_flutter/data/models/opcion_cheque_model.dart';
import 'package:bosque_flutter/domain/entities/catalogos_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';

/// CatalogosChequeDto del backend: siete listas de `{ codigo, nombre }`.
class CatalogosChequeModel {
  final List<OpcionChequeModel> tiposCheque;
  final List<OpcionChequeModel> monedas;
  final List<OpcionChequeModel> estadosCheque;
  final List<OpcionChequeModel> estadosAccion;
  final List<OpcionChequeModel> accionesFechaCobro;
  final List<OpcionChequeModel> accionesCierreConVerificacion;
  final List<OpcionChequeModel> accionesCierreSinVerificacion;

  const CatalogosChequeModel({
    required this.tiposCheque,
    required this.monedas,
    required this.estadosCheque,
    required this.estadosAccion,
    required this.accionesFechaCobro,
    required this.accionesCierreConVerificacion,
    required this.accionesCierreSinVerificacion,
  });

  factory CatalogosChequeModel.fromJson(Map<String, dynamic> json) =>
      CatalogosChequeModel(
        tiposCheque: _lista(json['tiposCheque']),
        monedas: _lista(json['monedas']),
        estadosCheque: _lista(json['estadosCheque']),
        estadosAccion: _lista(json['estadosAccion']),
        accionesFechaCobro: _lista(json['accionesFechaCobro']),
        accionesCierreConVerificacion: _lista(
          json['accionesCierreConVerificacion'],
        ),
        accionesCierreSinVerificacion: _lista(
          json['accionesCierreSinVerificacion'],
        ),
      );

  static List<OpcionChequeModel> _lista(dynamic crudo) => [
    for (final o in (crudo as List<dynamic>?) ?? const [])
      OpcionChequeModel.fromJson(o as Map<String, dynamic>),
  ];

  static List<Map<String, dynamic>> _aJson(List<OpcionChequeModel> l) => [
    for (final o in l) o.toJson(),
  ];

  Map<String, dynamic> toJson() => {
    'tiposCheque': _aJson(tiposCheque),
    'monedas': _aJson(monedas),
    'estadosCheque': _aJson(estadosCheque),
    'estadosAccion': _aJson(estadosAccion),
    'accionesFechaCobro': _aJson(accionesFechaCobro),
    'accionesCierreConVerificacion': _aJson(accionesCierreConVerificacion),
    'accionesCierreSinVerificacion': _aJson(accionesCierreSinVerificacion),
  };

  static List<OpcionChequeModel> _deEntidad(List<OpcionChequeEntity> l) => [
    for (final o in l) OpcionChequeModel.fromEntity(o),
  ];

  CatalogosChequeEntity toEntity() => CatalogosChequeEntity(
    tiposCheque: [for (final o in tiposCheque) o.toEntity()],
    monedas: [for (final o in monedas) o.toEntity()],
    estadosCheque: [for (final o in estadosCheque) o.toEntity()],
    estadosAccion: [for (final o in estadosAccion) o.toEntity()],
    accionesFechaCobro: [for (final o in accionesFechaCobro) o.toEntity()],
    accionesCierreConVerificacion: [
      for (final o in accionesCierreConVerificacion) o.toEntity(),
    ],
    accionesCierreSinVerificacion: [
      for (final o in accionesCierreSinVerificacion) o.toEntity(),
    ],
  );

  factory CatalogosChequeModel.fromEntity(
    CatalogosChequeEntity e,
  ) => CatalogosChequeModel(
    tiposCheque: _deEntidad(e.tiposCheque),
    monedas: _deEntidad(e.monedas),
    estadosCheque: _deEntidad(e.estadosCheque),
    estadosAccion: _deEntidad(e.estadosAccion),
    accionesFechaCobro: _deEntidad(e.accionesFechaCobro),
    accionesCierreConVerificacion: _deEntidad(e.accionesCierreConVerificacion),
    accionesCierreSinVerificacion: _deEntidad(e.accionesCierreSinVerificacion),
  );
}
