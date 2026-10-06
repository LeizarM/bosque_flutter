// Datos de mentira para la vista previa de «Verificar Cheques»: verificaciones
// de hoy (validas y anuladas, en las dos monedas, de cheques abiertos y
// cerrados, con nombres largos), cheques pendientes de verificar y el repositorio
// falso que los sirve.
//
// Va en `tool/` y no en `lib/`: no entra en la app. Reusa el repositorio falso de
// las pruebas (`test/fakes/repositorio_verificaciones.dart`, que no importa
// flutter_test) y solo cambia los datos.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart'
    show relojChequesProvider;
import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';

import '../../test/fakes/repositorio_verificaciones.dart';

/// «Hoy» de la vista previa. Fijo: la lista abre en este dia y no cambia segun
/// cuando se mire.
final DateTime hoyDeLaVista = DateTime(2026, 10, 3, 9, 30);

/// Los bancos del combo del formulario (los mismos nombres de los datos).
final List<BancoEntity> bancosDeLaVista = [
  BancoEntity(codBanco: 7, nombre: 'BANCO UNION', audUsuario: 1, fila: 1),
  BancoEntity(
    codBanco: 8,
    nombre: 'BANCO MERCANTIL SANTA CRUZ',
    audUsuario: 1,
    fila: 2,
  ),
  BancoEntity(
    codBanco: 9,
    nombre: 'BANCO NACIONAL DE BOLIVIA',
    audUsuario: 1,
    fila: 3,
  ),
  BancoEntity(codBanco: 10, nombre: 'BANCO BISA', audUsuario: 1, fila: 4),
  BancoEntity(codBanco: 11, nombre: 'BANCO ECONOMICO', audUsuario: 1, fila: 5),
  BancoEntity(codBanco: 12, nombre: 'BANCO FIE', audUsuario: 1, fila: 6),
  BancoEntity(
    codBanco: 13,
    nombre: 'BANCO DE CREDITO DE BOLIVIA',
    audUsuario: 1,
    fila: 7,
  ),
];

String _nombreDe(int cod) =>
    bancosDeLaVista.firstWhere((b) => b.codBanco == cod).nombre;

DateTime _hace(int dias) =>
    DateTime(hoyDeLaVista.year, hoyDeLaVista.month, hoyDeLaVista.day - dias);

VerificacionFilaEntity _verificacion(
  int codvd, {
  required int bancoCheque,
  required int bancoVerificacion,
  required double monto,
  String nroCheque = '',
  bool dolares = false,
  String estado = 'Y',
  String observacion = '',
  bool cerrado = false,
  bool sinMoneda = false,
  int cobranzaHace = 0,
}) => verificacionFalsa(
  codvd,
  codCheque: 9000 + codvd,
  nroCheque: nroCheque,
  monto: monto,
  moneda: sinMoneda ? null : (dolares ? 'SUS' : 'BS'),
  banco: _nombreDe(bancoCheque),
  bancoVerificacion: _nombreDe(bancoVerificacion),
  codBancoVerificacion: bancoVerificacion,
  fechaBanco: hoyDeLaVista,
  fechaCobranza: _hace(cobranzaHace),
  estado: estado,
  observacion: observacion,
  chequeCerrado: cerrado,
);

/// Las verificaciones de hoy: [total] 14 las muestra todas en una pagina; 45 dan
/// tres y muestran los rotulos «en esta pagina» del resumen.
List<VerificacionFilaEntity> verificacionesDeLaVista({int total = 14}) {
  final base = <VerificacionFilaEntity>[
    _verificacion(
      1,
      bancoCheque: 7,
      bancoVerificacion: 7,
      monto: 15400.5,
      nroCheque: '4800137',
      observacion: 'Cobrado en ventanilla',
    ),
    _verificacion(
      2,
      bancoCheque: 8,
      bancoVerificacion: 8,
      monto: 8200,
      nroCheque: '4800274',
    ),
    _verificacion(
      3,
      bancoCheque: 9,
      bancoVerificacion: 13,
      monto: 2350,
      nroCheque: '4800411',
      dolares: true,
      observacion: 'Deposito a cuenta del BCP',
      cobranzaHace: 1,
    ),
    _verificacion(
      4,
      bancoCheque: 10,
      bancoVerificacion: 10,
      monto: 41999.99,
      nroCheque: '4800548',
      estado: 'N',
      observacion: 'Anulada: el banco rechazo el deposito',
      cobranzaHace: 2,
    ),
    _verificacion(
      5,
      bancoCheque: 13,
      bancoVerificacion: 13,
      monto: 960,
      nroCheque: '4800685',
      dolares: true,
      cerrado: true,
      cobranzaHace: 6,
    ),
    _verificacion(
      6,
      bancoCheque: 7,
      bancoVerificacion: 8,
      monto: 3120.4,
      nroCheque: '12-34?56',
      observacion: 'Verificado por telefono',
    ),
    _verificacion(
      7,
      bancoCheque: 11,
      bancoVerificacion: 11,
      monto: 18750,
      nroCheque: '4800959',
      cerrado: true,
      cobranzaHace: 11,
    ),
    _verificacion(
      8,
      bancoCheque: 12,
      bancoVerificacion: 12,
      monto: 540,
      nroCheque: '4801096',
      sinMoneda: true,
    ),
    _verificacion(
      9,
      bancoCheque: 8,
      bancoVerificacion: 7,
      monto: 12345678.9,
      nroCheque: '4801233',
      observacion: 'Cheque de gerencia, monto grande',
      cobranzaHace: 3,
    ),
    _verificacion(
      10,
      bancoCheque: 9,
      bancoVerificacion: 9,
      monto: 7000,
      nroCheque: '4801370',
      estado: 'N',
      cobranzaHace: 4,
    ),
    _verificacion(
      11,
      bancoCheque: 10,
      bancoVerificacion: 10,
      monto: 2260.75,
      nroCheque: '4801507',
    ),
    _verificacion(
      12,
      bancoCheque: 7,
      bancoVerificacion: 7,
      monto: 880,
      nroCheque: '4801644',
      dolares: true,
      observacion: 'Verificado',
    ),
    _verificacion(
      13,
      bancoCheque: 13,
      bancoVerificacion: 8,
      monto: 5400,
      nroCheque: '4801781',
      cobranzaHace: 5,
    ),
    _verificacion(
      14,
      bancoCheque: 12,
      bancoVerificacion: 12,
      monto: 19900,
      nroCheque: '4801918',
      observacion: 'Sin novedad',
    ),
  ];
  if (total <= base.length) return base.take(total).toList();
  // Mas de una pagina: se repiten los casos con otros numeros.
  return [
    ...base,
    for (var i = base.length; i < total; i++)
      _verificacion(
        i + 1,
        bancoCheque: 7 + (i % 7),
        bancoVerificacion: 7 + ((i * 3) % 7),
        monto: 400.0 + i * 137.35,
        nroCheque: '${4800000 + (i + 1) * 137}',
        dolares: i % 5 == 0,
        estado: i % 9 == 0 ? 'N' : 'Y',
        cobranzaHace: i % 4,
      ),
  ];
}

ChequePendienteVerificacionEntity _pendiente(
  int cod, {
  required int banco,
  required double monto,
  bool dolares = false,
  bool cerrado = false,
  int cobranzaHace = 0,
  String nroCheque = '',
}) => pendienteFalso(
  cod,
  nroCheque: nroCheque,
  monto: monto,
  moneda: dolares ? 'SUS' : 'BS',
  banco: _nombreDe(banco),
  codBanco: banco,
  fechaCobranza: _hace(cobranzaHace),
  chequeCerrado: cerrado,
);

/// Los cheques sin verificacion valida: los de cobranza de hoy (lo que muestra el
/// modal al abrir), los de dias anteriores y uno cerrado.
List<ChequePendienteVerificacionEntity> pendientesDeLaVista() => [
  _pendiente(201, banco: 7, monto: 15400.5, nroCheque: '4802055'),
  _pendiente(202, banco: 8, monto: 8200, nroCheque: '4802192'),
  _pendiente(203, banco: 9, monto: 2350, dolares: true, nroCheque: '4802329'),
  _pendiente(204, banco: 10, monto: 6120.8, nroCheque: '4802466'),
  _pendiente(205, banco: 13, monto: 31000, nroCheque: '4802603'),
  _pendiente(206, banco: 11, monto: 750, dolares: true, nroCheque: '4802740'),
  _pendiente(
    207,
    banco: 12,
    monto: 9900,
    nroCheque: '4802877',
    cobranzaHace: 3,
  ),
  _pendiente(
    208,
    banco: 8,
    monto: 1280,
    nroCheque: '4803014',
    cobranzaHace: 8,
  ),
  _pendiente(
    209,
    banco: 7,
    monto: 22500,
    nroCheque: '12-34?56',
    cobranzaHace: 15,
    cerrado: true,
  ),
];

/// El repositorio falso con los datos de la vista previa.
RepositorioVerificacionesFalso repositorioDeLaVista({int total = 14}) {
  final repo = RepositorioVerificacionesFalso(
    verificaciones: verificacionesDeLaVista(total: total),
    pendientes: pendientesDeLaVista(),
    hoy: DateTime(
      hoyDeLaVista.year,
      hoyDeLaVista.month,
      hoyDeLaVista.day,
    ),
  );
  repo.nombresDeBancos = {for (final b in bancosDeLaVista) b.codBanco: b.nombre};
  return repo;
}

/// Los providers que la vista previa sustituye: el repositorio, el reloj y los
/// bancos del combo.
List<Override> overridesDeLaVista({
  int total = 14,
  RepositorioVerificacionesFalso? repo,
}) {
  final r = repo ?? repositorioDeLaVista(total: total);
  return [
    verificacionesRepositoryProvider.overrideWithValue(r),
    relojChequesProvider.overrideWithValue(() => hoyDeLaVista),
    listaBancosProvider.overrideWith((ref) async => bancosDeLaVista),
  ];
}
