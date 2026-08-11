import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/automatizacion_entity.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/convocatoria_entity.dart';
import 'package:bosque_flutter/domain/entities/cumple_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/intervencion_entity.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/permiso_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/programacion_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_entity.dart';
import 'package:bosque_flutter/domain/entities/puente_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/rol_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/rrhh_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';

/// Contrato del módulo Rol de Turnos de Sábado.
///
/// Todo pasa por `/rol-sabados`, y todo es POST — incluidas las lecturas, que es
/// la convención de esta API.
abstract class RolSabadosRepository {
  // ── lecturas ──────────────────────────────────────────────────────────

  /// Cabeceras de rol. `codSucursal` y `anio` en 0 = sin filtrar.
  Future<List<RolSabadosEntity>> getRoles({int codSucursal = 0, int anio = 0});

  /// Las columnas de la grilla.
  Future<List<SabadoEntity>> getSabados(int idRol);

  /// Las filas de la grilla. `activo` -1 = todos, 0/1 = filtra.
  Future<List<ParticipanteTurnoEntity>> getParticipantes(
    int idRol, {
    int activo = 1,
  });

  /// Las celdas ocupadas. Ojo: **el libre no viene**, es la ausencia de la fila.
  Future<List<CeldaTurnoEntity>> getAsignaciones(int idRol, {int idSabado = 0});

  /// El catálogo de letras, para la leyenda y los colores.
  Future<List<EstadoTurnoEntity>> getEstadosTurno();

  /// Turnos por persona contra su meta: el SUM de la derecha del Excel.
  Future<List<ParticipanteTurnoEntity>> getTurnosPorParticipante(int idRol);

  /// Cobertura por sábado: el SUBTOTAL de abajo del Excel. `mes` 0 = todos.
  Future<List<SabadoEntity>> getCobertura(int idRol, {int mes = 0});

  /// Sábados cuya marca de feriado no coincide con RR.HH., en los dos sentidos.
  Future<List<SabadoEntity>> getFeriadosDesincronizados(int idRol);

  /// El PDF de UN sábado: la lista de quién viene ese día, para publicarla.
  ///
  /// Devuelve **bytes**, no modelos: el backend arma el reporte con Jasper y
  /// responde `application/pdf`. Por eso es lo único del contrato que no pasa
  /// por `postAndReturnList`.
  Future<Uint8List> getReporteSabadoPdf(int idSabado);

  // ── escrituras ────────────────────────────────────────────────────────

  /// Genera (`CREAR`) o reconcilia (`REGENERAR`) el rol entero.
  /// Devuelve el `idRol`.
  Future<int> generarRol({
    required int anio,
    int codSucursal = 0,
    int codEmpresa = 0,
    String modo = 'CREAR',
    required int audUsuario,
  });

  /// Corrige UNA celda. Se guarda con `origen='M'`, y por eso sobrevive a una
  /// regeneración. `codigoExcel` vacío o 'L' no va acá: para eso está
  /// [liberarCelda].
  Future<void> corregirCelda({
    required int idParticipante,
    required int idSabado,
    required String codigoExcel,
    String observacion = '',
    required int audUsuario,
  });

  /// Libera la celda: esa persona queda LIBRE ese sábado (se borra la fila).
  ///
  /// Se identifica por persona + sábado y NO por `idAsignacion`: el SP delega en
  /// `trs_sp_corregirCelda`, que trabaja sobre ese par. Mandarle el id de la
  /// asignación lo deja sin saber qué celda tocar.
  Future<void> liberarCelda({
    required int idParticipante,
    required int idSabado,
    required int audUsuario,
  });

  /// Declara o quita el evento de un sábado y rehace sus celdas.
  /// `alcanceEvento` null vuelve el sábado a la rotación normal.
  Future<void> marcarEvento({
    required int idSabado,
    String? alcanceEvento,
    String motivoEspecial = '',
    required int audUsuario,
  });

  /// Sincroniza los feriados del rol contra RR.HH. Es el arreglo del caso del
  /// puente (feriado el viernes + sábado declarado después de generar el rol).
  Future<void> refrescarFeriados({
    required int idRol,
    bool soloInformar = false,
    required int audUsuario,
  });

  /// Mueve el estado del rol: `BORRADOR` · `PUBLICADO` · `CERRADO`.
  ///
  /// Qué significa cada uno, que es lo que hay que saber antes de llamar:
  ///  - `BORRADOR` no bloquea nada.
  ///  - `PUBLICADO` bloquea **sólo la rotación**: `generarRol` con
  ///    `modo='REGENERAR'` rebota. Todo el resto —programar, corregir celdas,
  ///    eventos, convocatorias, cambios y los dos refrescos— sigue igual.
  ///  - `CERRADO` congela el rol entero, y **es de ida**: el SP rechaza
  ///    cualquier UPDATE sobre un rol cerrado *antes* de mirar el estado que le
  ///    mandás, así que desde acá no hay vuelta. Ver [cambiarEstadoRol] en la
  ///    implementación.
  ///
  /// **[aplicaAsuetoCumple] no es opcional y no es un descuido.** El endpoint
  /// recibe la cabecera entera y ese campo es un `int` primitivo del lado Java
  /// inicializado en 1: si no se manda, viaja igual como 1 y el SP lo escribe
  /// con `ISNULL`, encendiendo el asueto por cumpleaños de todo el rol sin que
  /// nadie lo pidiera. Se manda el valor que el rol ya tiene, para que la
  /// escritura sea del mismo valor.
  Future<void> cambiarEstadoRol({
    required int idRol,
    required String estado,
    required int aplicaAsuetoCumple,
    required int audUsuario,
  });

  // ── cambios, programaciones y convocatoria ────────────────────────────

  /// Permutas y coberturas. `estado` vacio = todos.
  Future<List<CambioEntity>> getCambios(int idRol, {String estado = ''});

  /// Qué decidió cada jefe y con cuánta antelación.
  Future<List<ProgramacionEntity>> getProgramaciones(
    int idRol, {
    int idSabado = 0,
  });

  /// La lista nominal de un evento, contrastada contra la rotación.
  Future<List<ConvocatoriaEntity>> getDetalleEvento(int idSabado);

  // ── controles ─────────────────────────────────────────────────────────

  /// Todo lo que un humano tocó sobre el default, de las cuatro fuentes.
  Future<List<IntervencionEntity>> getIntervenciones(int idRol);

  /// Cumpleaños que caen sábado y qué pasó con el asueto.
  Future<List<CumpleSabadoEntity>> getCumplesSabado(int idRol);

  /// Cuánto del rol lo resuelve el sistema solo. null si el rol no tiene celdas.
  Future<AutomatizacionEntity?> getAutomatizacion(int idRol);

  // ── escrituras nuevas ─────────────────────────────────────────────────

  /// Registra una permuta o cobertura. Nace SOLICITADO y **no toca la grilla**.
  Future<int> registrarCambio({
    required int idRol,
    required int idSabado,
    required int codEmpleadoTitular,
    int codEmpleadoReemplazo = 0,
    int idSabadoReposicion = 0,
    required String tipo,
    String motivo = '',
    required int audUsuario,
  });

  /// Aprueba y APLICA a la grilla. Es lo único que mueve las celdas de un cambio.
  Future<void> aprobarCambio({
    required int idCambio,
    required int codAprobador,
    required int audUsuario,
  });

  /// Anula la solicitud. Rebota si ya está APROBADA.
  Future<void> anularCambio({required int idCambio, required int audUsuario});

  /// Cambia el grupo de rotación de una persona ('A' o 'B').
  ///
  /// No mueve la grilla: hay que regenerar para que las celdas se rehagan
  /// con el grupo nuevo. Y sobrevive a esa regeneración — el generador sólo
  /// asigna grupo a quien entra por primera vez.
  Future<void> asignarGrupo({
    required int idParticipante,
    required String grupoRotacion,
    required int audUsuario,
  });

  /// Cierra la ventana de sábados de una persona: **no la da de baja**.
  ///
  /// [fechaBaja] es el último día que cuenta como suyo, así que se manda el día
  /// ANTERIOR al primer sábado que ya no viene. Lo que trabajó queda escrito —
  /// el backend borra sólo celdas futuras y de la rotación; lo que programó un
  /// jefe o corrigió RR.HH. sobrevive y se informa en el mensaje de vuelta.
  ///
  /// Anda con el rol PUBLICADO: aplica sus propias celdas, no depende de
  /// regenerar.
  Future<void> sacarDeSabados({
    required int idParticipante,
    required DateTime fechaBaja,
    required int audUsuario,
  });

  /// Devuelve a alguien a los sábados desde [fechaAlta], sin tocar el pasado.
  ///
  /// El backend le rehace las celdas sábado por sábado y **sólo a esta
  /// persona**: reincorporar a uno no puede mover los sábados de los otros
  /// ochenta y cuatro. Rebota si ya no figura en la relación laboral vigente.
  Future<void> reincorporar({
    required int idParticipante,
    required DateTime fechaAlta,
    required int audUsuario,
  });

  /// Los permisos de RR.HH. que la grilla todavía NO refleja.
  Future<List<PermisoSabadoEntity>> getDesfasesPermiso(int idRol);

  /// Cruza el rol con las vacaciones, bajas y permisos de RR.HH. y corrige las
  /// celdas. Va en los dos sentidos y sólo toca lo que puso la rotación.
  Future<void> refrescarPermisos({
    required int idRol,
    bool soloInformar = false,
    required int audUsuario,
  });

  /// Convoca o excusa en bloque. Mandar **uno solo** de los tres criterios.
  Future<void> convocar({
    required int idSabado,
    required String tipo,
    int codEmpleado = 0,
    int codEmpleadoJefe = 0,
    int codCargo = 0,
    String motivo = '',
    required int audUsuario,
  });

  // ── su equipo (jefes) ─────────────────────────────────────────────────

  /// Quién soy y a quiénes puedo mover.
  ///
  /// **No lleva audUsuario a propósito**: el servidor resuelve la identidad con
  /// el token y no con lo que mande el cliente, así que no hay forma de pedir
  /// «el equipo de otro». Si le agregás un parámetro de usuario, lo rompés.
  ///
  /// Nunca devuelve null: si no soy programador viene [MiEquipoEntity.vacio].
  Future<MiEquipoEntity> getMiEquipo();

  /// Un jefe decide si alguien de su equipo viene ('1') o no ('L') ese sábado.
  ///
  /// **No lleva audUsuario a propósito**, por lo mismo que [getMiEquipo]: quién
  /// programa sale del token. Se manda el empleado del que aprieta —no el del
  /// titular— para que quede la traza cuando el que entra es el reemplazo.
  ///
  /// El backend rebota lo demás: no se pueden pisar celdas de RR.HH.
  /// (V, B, X, P) ni tocar sábados pasados o desactivados.
  Future<void> programar({
    required int idSabado,
    required int codEmpleadoDependiente,
    required String codigoExcel,
    String motivo = '',
  });

  /// El ABM de quién tiene permiso para programar. Sólo ROLE_ADM.
  /// `codSucursal` 0 = todas · `estado` vacío = activos y dados de baja.
  Future<List<ProgramadorEntity>> getProgramadores({
    int codSucursal = 0,
    String estado = 'A',
  });

  /// Alta o modificación de un programador. `idProgramador` 0 = alta.
  ///
  /// El alcance por defecto es DIRECTOS: SUBARBOL se da a mano, cuando alguien
  /// lo pide y se sabe qué tan grande es la rama que está abriendo.
  Future<void> registrarProgramador({
    required int idProgramador,
    required int codEmpleado,
    int codSucursal = 0,
    String alcance = 'DIRECTOS',
    int codEmpleadoReemplazo = 0,
    String observacion = '',
    required int audUsuario,
  });

  /// Baja lógica (`estado='I'`). Lo que ese jefe ya programó no se toca.
  Future<void> eliminarProgramador({
    required int idProgramador,
    required int audUsuario,
  });

  /// A quiénes le quedaría a cargo ese permiso **antes** de darlo de alta.
  ///
  /// Sale del mismo árbol del organigrama con el que `trs_sp_programar` valida
  /// después, así que lo que se muestra acá es exactamente lo que el sistema va
  /// a aceptar. Si fueran dos recorridos distintos, la pantalla prometería un
  /// equipo y el sistema aceptaría otro.
  ///
  /// `codSucursal` **0 = todas las sucursales**, igual que el `NULL` que guarda
  /// la tabla. Es a propósito el mismo idioma: lo que se previsualiza tiene que
  /// ser exactamente lo que se va a guardar.
  Future<List<ProgramadorDependienteEntity>> previsualizarDependientes({
    required int codEmpleado,
    required int codSucursal,
    required String alcance,
    required int idRol,
  });

  // ── El padrón de RR.HH. Sólo ROLE_ADM. ────────────────────────────────
  //
  // Son los que pueden corregir la celda de CUALQUIERA con CUALQUIER letra.
  // Un jefe programador, en cambio, sólo toca la de su gente y sólo entre
  // '1' y 'L'.

  /// `estado` vacío trae activos y dados de baja: el ABM necesita ver los dos
  /// para poder reactivar a alguien.
  Future<List<RrhhSabadosEntity>> getRrhh({String estado = ''});

  /// Alta o actualización. `idRrhh` 0 = alta, y el alta **reactiva** si esa
  /// persona ya estuvo (no crea una segunda fila).
  Future<void> registrarRrhh({
    required int idRrhh,
    required int codEmpleado,
    String observacion = '',
    required int audUsuario,
  });

  /// Baja lógica (`estado='I'`). Lo que ya corrigió no se toca.
  Future<void> eliminarRrhh({required int idRrhh, required int audUsuario});

  // ── Puente a cuenta de vacación ───────────────────────────────────────
  //
  // La empresa declara que ese sábado no se trabaja y se lo cobra a la
  // vacación de cada uno. Son dos llamadas a propósito: primero se mira,
  // después se aplica.

  /// Qué pasaría: una fila por persona con los días que se le descontarían, y
  /// para quien se saltea, el motivo. **No escribe nada.**
  ///
  /// Las horas vacías dejan que el backend ponga su default (08:30–12:30).
  Future<List<PuenteVacacionEntity>> simularPuente({
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  });

  /// Lo aplica: crea el permiso de vacación de todos los que ese sábado tenían
  /// que venir y deja sus celdas en `V`.
  ///
  /// **Escribe en `trh_permiso`, que es de RR.HH.**, y le consume saldo de
  /// vacación a cada persona. Sólo ROLE_ADM o quien esté en el padrón de
  /// RR.HH.; el backend lo resuelve del token, no del body.
  ///
  /// Devuelve el mensaje del servidor, que dice cuántos entraron y cuántos se
  /// saltearon.
  Future<String> aplicarPuente({
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  });
}
