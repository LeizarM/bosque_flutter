/// Opcion de los catalogos del modulo de garantias (v_tipos): grupo 28, tipos
/// de garantia; grupo 29, estados de accion.
///
/// El backend los sirve como constantes (utils.Tipos), con el mismo formato
/// que el resto de catalogos de la casa.
class TipoCbrEntity {
  final String codTipos;
  final String nombre;
  final int codGrupo;

  const TipoCbrEntity({
    required this.codTipos,
    required this.nombre,
    required this.codGrupo,
  });
}
