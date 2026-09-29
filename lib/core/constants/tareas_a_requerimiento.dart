// Destino final: lib/core/constants/tareas_a_requerimiento.dart

/// Los `idTarRuti` de los flujos que dejaron de ser tareas rutinarias.
///
/// Hasta el archivo SQL 40 el Job generaba una ocurrencia por persona y por día
/// para estos cuatro, aparecieran o no en la lista de alguien. Los números
/// medidos contra la base el 2026-09-08 explican por qué salieron:
///
///     Caja Chica              5.957 ocurrencias, 0,0% cerradas (nunca, en 4 años)
///     Cierre de Operaciones   8.359 ocurrencias, 11,1% cerradas
///     Caja Fuerte            11.003 ocurrencias, 64,2% cerradas
///     Revisar Autos           3.259 ocurrencias, 72,0% cerradas
///
/// Ahora son submódulos de la vista 87 y se entra por el menú. La ocurrencia se
/// sigue creando —todas sus tablas cuelgan de ella— pero recién cuando alguien
/// entra a hacer el trabajo (`AperturaFlujo`).
///
/// **Estos ids tienen que coincidir con tres lugares más**, y si se desincronizan
/// el síntoma es silencioso (una pantalla que abre en el vacío o una tarea que se
/// genera dos veces):
///   * `tac_tareaRutinaria.esARequerimiento = 1` (archivo SQL 40, Parte B)
///   * `TareasRutinariasController.BOTON_POR_FLUJO` (el permiso por botón)
///   * el catálogo del archivo SQL 41 (las vistas hijas de la 87)
class TareasARequerimiento {
  const TareasARequerimiento._();

  /// idATR 4 — `tac_llegada`.
  static const int cajaFuerte = 40;

  /// idATR 6 — `tac_cocheLlegadas` / `tac_coche`.
  static const int coches = 41;

  /// idATR 7 — `tac_cajaChica` / `tac_montoCajaChicaXSuc`.
  static const int cajaChica = 42;

  /// idATR 3. **Ojo:** el idATR 3 tiene DOS tareas y solo salió esta. La otra
  /// (idTarRuti 3, "Verficar Arqueo de Caja") sigue siendo tarea rutinaria, y
  /// por eso todo el corte se hace por idTarRuti y nunca por idATR.
  ///
  /// **2026-09-11: ya no está en [todas].** Cierre de Operaciones salió del
  /// menú (archivo SQL 63): la revisión del día se abre desde "Mis tareas
  /// rutinarias" con la ocurrencia de "Verificar Cierre de Operaciones" (39),
  /// que genera el Job. La constante se queda como registro y porque el
  /// catálogo del archivo SQL 41 todavía la nombra.
  static const int cierreOperaciones = 2;

  static const Set<int> todas = {cajaFuerte, coches, cajaChica};

  /// Si esta tarea ya no se marca desde "Mis tareas rutinarias".
  static bool contiene(int? idTarRuti) =>
      idTarRuti != null && todas.contains(idTarRuti);
}
