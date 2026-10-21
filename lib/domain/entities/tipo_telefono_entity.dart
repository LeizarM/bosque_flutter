/// Un tipo de teléfono (`trh_tipoTelefono`). [usos] solo viene en el listado
/// de la pantalla de mantenimiento: cuántos teléfonos lo usan.
class TipoTelefonoEntity {
  final int codTipoTel;
  final String tipo;
  final int audUsuario;
  final int usos;
  TipoTelefonoEntity({
    required this.codTipoTel,
    required this.tipo,
    required this.audUsuario,
    this.usos = 0,
  });
}
