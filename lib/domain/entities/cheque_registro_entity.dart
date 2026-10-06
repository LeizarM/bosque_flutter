import 'package:bosque_flutter/domain/entities/cheque_entity.dart';

/// El formulario del legacy que se uso para registrar o editar. Determina que
/// se acepta y que boton se exige; el servidor ignora lo que ese formulario
/// tenia bloqueado.
enum ModoRegistroCheque {
  /// `chequeModal`. Alta: btnNuevoCH. Edicion: btnEditar1CH con el cheque
  /// abierto; solo cambian cliente, banco, nro de cheque, talonario, recibo y
  /// observacion.
  estandar('ESTANDAR'),

  /// `chequeModalTal`, para cheques cerrados. No hay alta. Edicion:
  /// btnEditar1CH; solo cambian talonario y recibo.
  talonario('TALONARIO'),

  /// `chequeModalMad`, del administrador. Alta: btnNuevo2CH. Edicion:
  /// btnEditar3CH con el cheque abierto; cambia todo menos empresa y sucursal.
  admin('ADMIN');

  const ModoRegistroCheque(this.codigo);

  /// Lo que viaja en el JSON.
  final String codigo;
}

/// Lo que se manda a `/cheque/registrar` (`ChequeRegistro` del contrato): las
/// columnas de tch_cheque mas la observacion y el modo.
///
/// Con [codCheque] en cero es un ALTA: crea el cheque (siempre PEN) y su accion
/// REC con [observacion]. Con [codCheque] mayor a cero es una EDICION.
///
/// **No lleva `estado`, `nroRecibo`, `audUsuario` ni `audFecha`**: el estado lo
/// fija el servidor, el recibo lo calcula el procedimiento y el usuario sale
/// del token. En el alta estandar la fecha de cobro es la del cheque.
///
/// [codEmpleado] en 0 significa que lo dejo el cliente. Casi todo es nulable
/// porque cada [modo] usa una parte; el servidor valida lo obligatorio y
/// responde con todos los mensajes juntos.
class ChequeRegistroEntity {
  final BigInt codCheque;
  final ModoRegistroCheque modo;
  final String? nrocheque;
  final String? codCliente;
  final String? aOrdenDe;
  final DateTime? fechaCheque;
  final DateTime? fechaCobrar;
  final double? monto;
  final String? moneda;
  final String? tipo;
  final int? codBanco;
  final int? codEmpleado;
  final String? reciboManual;
  final int? codSucursal;
  final String? nroTalonario;

  /// Solo en el alta, y obligatoria: la empresa elegida en la pantalla (una de
  /// `/cheque/empresas`), nunca la del login. La [codSucursal] tiene que ser de
  /// esa empresa.
  final int? codEmpresa;

  /// Observacion de la accion REC (2 a 200 caracteres). En una edicion, null =
  /// no se toca y vacia = se borra.
  final String? observacion;

  const ChequeRegistroEntity({
    required this.codCheque,
    this.modo = ModoRegistroCheque.estandar,
    this.nrocheque,
    this.codCliente,
    this.aOrdenDe,
    this.fechaCheque,
    this.fechaCobrar,
    this.monto,
    this.moneda,
    this.tipo,
    this.codBanco,
    this.codEmpleado,
    this.reciboManual,
    this.codSucursal,
    this.nroTalonario,
    this.codEmpresa,
    this.observacion,
  });

  /// El punto de partida de una edicion: los datos actuales del cheque.
  factory ChequeRegistroEntity.desdeCheque(
    ChequeEntity c, {
    ModoRegistroCheque modo = ModoRegistroCheque.estandar,
    String? observacion,
  }) => ChequeRegistroEntity(
    codCheque: c.codCheque,
    modo: modo,
    nrocheque: c.nrocheque,
    codCliente: c.codCliente,
    aOrdenDe: c.aOrdenDe,
    fechaCheque: c.fechaCheque,
    fechaCobrar: c.fechaCobrar,
    monto: c.monto,
    moneda: c.moneda,
    tipo: c.tipo,
    codBanco: c.codBanco,
    codEmpleado: c.codEmpleado,
    reciboManual: c.reciboManual,
    codSucursal: c.codSucursal,
    nroTalonario: c.nroTalonario,
    codEmpresa: c.codEmpresa,
    observacion: observacion,
  );

  bool get esAlta => codCheque == BigInt.zero;
}
