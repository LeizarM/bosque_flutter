/// Lo que se manda a `/banco/registrar` (vista 43, tabla tch_banco): alta con
/// [codBanco] en 0, edicion con el codigo del banco.
///
/// El nombre es obligatorio, de 3 a 50 caracteres (letras, numeros, espacio,
/// `-` y `/`); el servidor lo valida. El codigo es `int` para que coincida con
/// `BancoEntity.codBanco`, la entidad de lectura que ya existe.
class BancoRegistroEntity {
  final int codBanco;
  final String nombre;

  const BancoRegistroEntity({required this.codBanco, required this.nombre});

  bool get esAlta => codBanco == 0;
}
