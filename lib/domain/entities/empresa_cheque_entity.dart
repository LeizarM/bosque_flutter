/// Una empresa del combo «Empresa» de la pantalla de cheques
/// (`/cheque/empresas`). De la elegida salen las sucursales, los clientes y la
/// empresa del cheque que se registra.
class EmpresaChequeEntity {
  final int codEmpresa;
  final String nombre;

  const EmpresaChequeEntity({required this.codEmpresa, required this.nombre});
}
