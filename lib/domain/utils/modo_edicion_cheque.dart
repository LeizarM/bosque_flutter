import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/domain/utils/reglas_cheque.dart';

/// Con que formulario se edita un cheque desde el lapiz de la fila.
///
/// La fila tiene **un solo lapiz** y este es el unico lugar que decide a que modo
/// del contrato (`ESTANDAR` / `TALONARIO` / `ADMIN`) corresponde. Logica pura,
/// sin Flutter ni Riverpod. El servidor sigue decidiendo por el modo del cuerpo y
/// por el boton de la vista 42: esto solo elige el formulario que se dibuja.
class ModoEdicionCheque {
  /// El formulario que abre el lapiz.
  final ModoRegistroCheque modo;

  /// Se pidio el modo de administrador pero el cheque esta cerrado y su fecha de
  /// cobro quedo fuera de +-28 dias de la del cheque: se abre en [modo]
  /// `talonario` y el formulario lo explica arriba. No es un error.
  final bool avisoCobroFueraDeRango;

  const ModoEdicionCheque(this.modo, {this.avisoCobroFueraDeRango = false});

  @override
  bool operator ==(Object other) =>
      other is ModoEdicionCheque &&
      other.modo == modo &&
      other.avisoCobroFueraDeRango == avisoCobroFueraDeRango;

  @override
  int get hashCode => Object.hash(modo, avisoCobroFueraDeRango);

  @override
  String toString() =>
      'ModoEdicionCheque(${modo.codigo}'
      '${avisoCobroFueraDeRango ? ', aviso' : ''})';
}

/// El formulario con el que [permisos] edita un cheque en [estado], o null si no
/// puede editarlo de ninguna forma.
///
/// - Con `puedeEditarComoAdmin` (btnEditar3CH con el cheque abierto, o el
///   administrador siempre) abre el formulario **de administrador**, sin campos
///   bloqueados salvo empresa y sucursal.
///   - **Excepcion**: un cheque **cerrado** con la fecha de cobro fuera de +-28
///     dias de la del cheque abre en modo **talonario**, con aviso. El servidor
///     exige ese rango en el modo `ADMIN`; en el modo talonario no lo
///     valida, y quien solo quiere corregir el talonario no tendria por que
///     tocar una fecha. Solo se aplica cuando las dos fechas se conocen: sin
///     alguna no hay rango que comprobar y se deja el modo de administrador.
/// - Si no, con `puedeEditar` (btnEditar1CH, cheque abierto): **estandar**.
/// - Si no, con `puedeEditarTalonario` (btnEditar1CH, cheque cerrado):
///   **talonario**.
ModoEdicionCheque? modoDeEdicionCheque(
  PermisosCheque permisos, {
  required String? estado,
  required DateTime? fechaCheque,
  required DateTime? fechaCobrar,
}) {
  if (permisos.puedeEditarComoAdmin(estado)) {
    final cobroFuera =
        PermisosCheque.estaCerrado(estado) &&
        fechaCheque != null &&
        fechaCobrar != null &&
        !ReglasCheque.cobroEnRango(fechaCobrar, fechaCheque);
    return cobroFuera
        ? const ModoEdicionCheque(
          ModoRegistroCheque.talonario,
          avisoCobroFueraDeRango: true,
        )
        : const ModoEdicionCheque(ModoRegistroCheque.admin);
  }
  if (permisos.puedeEditar(estado)) {
    return const ModoEdicionCheque(ModoRegistroCheque.estandar);
  }
  if (permisos.puedeEditarTalonario(estado)) {
    return const ModoEdicionCheque(ModoRegistroCheque.talonario);
  }
  return null;
}
