/// Una empresa (`tb_empresa`). [padre], [sucursales] y [cargos] solo vienen
/// en la pantalla de empresas y sucursales.
class EmpresaEntity {
  final int codEmpresa;
  final String nombre;
  final int codPadre;
  final String sigla;
  final int audUsuario;
  final String padre;
  final int sucursales;
  final int cargos;

  EmpresaEntity({
    required this.codEmpresa,
    required this.nombre,
    required this.codPadre,
    required this.sigla,
    required this.audUsuario,
    this.padre = '',
    this.sucursales = 0,
    this.cargos = 0,
  });
}
