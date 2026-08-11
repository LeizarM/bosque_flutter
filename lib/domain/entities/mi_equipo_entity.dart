// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';

/// **Origen:** no hay tabla ni SP directo. Ver la nota.
///
/// **No sale de un SP.** Lo arma `MiEquipoDto` en el backend combinando
/// `p_list_trs_Programador` @E (quien soy yo para este modulo, resuelto por el
/// login) con @D (mi gente).
///
/// Siempre responde 200, nunca 204: si no sos programador viene
/// `esProgramador=0` con el equipo vacio, que es una respuesta valida.
///
/// Mi permiso para programar, resuelto por el servidor a partir del token.
///
/// El cliente NO decide esto: manda el token y el backend contesta quién es y a
/// quiénes puede mover. Por eso no hay ningún campo para «programar como otro».
class MiEquipoEntity {
  final int codUsuario;
  final int codEmpleado;

  /// 1 = puede programar. Es lo único que decide si la pestaña existe.
  final int esProgramador;

  /// 1 = entra por ser el reemplazo del titular, no por ser el jefe.
  final int esReemplazo;

  /// 1 = está en el padrón de RR.HH., así que puede corregir la celda de
  /// **cualquiera**, sea o no programador.
  ///
  /// Es un permiso distinto de [esProgramador] y no lo incluye: un jefe sólo
  /// puede tocar la celda de su propia gente, y sólo para decidir si viene o no.
  /// Tampoco incluye a ROLE_ADM — eso sale del token, y en esta empresa los
  /// ROLE_ADM son Sistemas, no RR.HH.
  final int esRrhh;
  final int idProgramador;

  /// El jefe de verdad. Si soy el reemplazo, no soy yo.
  final int codEmpleadoTitular;
  final String jefe;

  /// DIRECTOS (sólo los que reportan directo) | SUBARBOL (toda la rama).
  final String alcance;
  final int codSucursal;

  /// Nombre de la sucursal del permiso. Vacío = vale para todas.
  final String sucursal;

  /// Lo que dice el backend que tiene el equipo. Puede diferir de
  /// `equipo.length` si algún día el listado se pagina: para mostrar contá con
  /// éste, para recorrer usá la lista.
  final int cantidadDependientes;
  final List<ProgramadorDependienteEntity> equipo;

  const MiEquipoEntity({
    this.codUsuario = 0,
    this.codEmpleado = 0,
    this.esProgramador = 0,
    this.esReemplazo = 0,
    this.esRrhh = 0,
    this.idProgramador = 0,
    this.codEmpleadoTitular = 0,
    this.jefe = '',
    this.alcance = '',
    this.codSucursal = 0,
    this.sucursal = '',
    this.cantidadDependientes = 0,
    this.equipo = const [],
  });

  bool get puedoProgramar => esProgramador == 1;
  bool get actuaComoReemplazo => esReemplazo == 1;

  /// Puede corregir la celda de cualquiera, con cualquier letra.
  bool get soyRrhh => esRrhh == 1;

  /// Los `codEmpleado` de mi gente, para preguntar rápido si puedo tocarle la
  /// celda a alguien.
  ///
  /// Se arma una vez y no en cada celda: la grilla pregunta esto miles de veces
  /// por pantalla, y recorrer la lista cada vez es cuadrático sobre la matriz.
  Set<int> get codigosDeMiGente =>
      {for (final d in equipo) d.codDependiente};

  /// Tiene el permiso pero el organigrama no le cuelga a nadie. No es un error:
  /// es un jefe sin gente, y hay que decírselo en vez de mostrar una tabla
  /// vacía como si algo se hubiera roto.
  bool get sinEquipo => puedoProgramar && equipo.isEmpty;

  /// La respuesta cuando el servidor no contesta nada (204, o un backend viejo
  /// que todavía no tiene el endpoint). Se comporta como «no sos programador»:
  /// la pestaña no aparece y nadie ve una pantalla rota.
  static const vacio = MiEquipoEntity();
}
