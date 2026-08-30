/// Unión entre grupo y tipo de talonario. Tabla tmto_talonarioPorGrupo.
///
/// PK compuesta (codGrupo + codTipoRecibo) y sin identity: no hay id propio,
/// se identifica por el par. Solo admite alta y baja; para mover un tipo de
/// grupo hay que quitarlo y volver a asignarlo.
class TalonarioPorGrupoEntity {
  BigInt codGrupo;
  BigInt codTipoRecibo;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura ----
  String datoGrupo;
  String datoTipoNombre;
  String sigla;
  String datoTipo;

  TalonarioPorGrupoEntity({
    required this.codGrupo,
    required this.codTipoRecibo,
    required this.audUsuario,
    this.audFecha,
    this.datoGrupo = '',
    this.datoTipoNombre = '',
    this.sigla = '',
    this.datoTipo = '',
  });
}
