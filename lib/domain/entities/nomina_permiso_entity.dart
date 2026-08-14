// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

/// Una fila de la **Nómina de Permisos**: el kardex de `trh_permiso` de una
/// persona, con sus filtros (tipo, rango de fechas, y el «quién estaba de
/// permiso el día X»).
///
/// **Origen:** `POST /permiso-rrhh/permisos/kardex` → `p_list_Permiso
/// @ACCION='Q'`.
///
/// **Se llama `NominaPermiso` y no `Permiso` porque `PermisoEntity` ya existe
/// dos veces** —en `domain/entities/` y en `data/models/`, las dos del flujo
/// del EMPLEADO (pedir su permiso), que tiene otro contrato y otra audiencia—.
/// Un tercer `PermisoEntity` no compilaría junto a ninguno de los dos sin
/// alias, y el alias es la señal de que el nombre está mal elegido.
///
/// ## Las dos columnas de Deuda del legacy NO están, y es a propósito
///
/// La grilla del JSF muestra «Deuda En Día(s)» y «Deuda En Hr(s)» desde
/// `diasAdeudados`, que el SP calcula así:
///
/// ```sql
/// case when tp.tipoPermiso = 'otro' and YEAR(tp.desde) >= 2019
///      then ISNULL((select SUM(b.cantidadDiasRepuestos)
///                   from trh_repper b where b.codPermiso = tp.codPermiso), 0)
///           - tp.cantidadDias
///      else 0 end
/// ```
///
/// **`trh_repper` tiene 0 filas** (verificado contra `BOSQUE-2_0`), así que el
/// `SUM` es siempre 0 y la resta devuelve **el negativo de los días**: la
/// columna mostraría números entre -0,25 y -2 para las 27 filas `'otro'` desde
/// 2019, y 0 fijo para las otras ~8.400. No está vacía: está con el signo al
/// revés. Portarla sería publicar un dato malo sobre días pagados.
///
/// Vuelve el día que exista el módulo de reposición —el que llena
/// `trh_repper`—, que el plan dejó fuera de esta migración.
class NominaPermisoEntity {
  /// La clave de la fila. **No sirve para dar de baja desde acá**: el alta no
  /// devuelve el id generado (`p_abm_Permiso` no tiene `SCOPE_IDENTITY`) y esta
  /// pantalla es de lectura.
  final int codPermiso;

  /// Quién. Va vacío en el kardex de una persona —el nombre ya está en la
  /// cabecera— y se llena en «quién está fuera», que consulta a toda la empresa.
  final int codEmpleado;
  final String datoEmpleado;

  /// El código crudo: `vac`, `pva`, `otro`, `clb`, `libre`, `baja`, `def`,
  /// `pcr`, `sinsuel`. Se guarda además del texto porque la pantalla decide
  /// cosas con él —el aviso de reposición es `tipoPermiso in ('otro','pcr')`—
  /// y comparar contra la descripción sería atarse a cómo esté redactada.
  final String tipoPermiso;

  /// `v_tipos.descripcion` del grupo 13, que es lo que se lee en la columna
  /// «Permiso». Hay 28 filas históricas (2016-2019) con el tipo vacío, residuo
  /// del flujo de «boleta» que el legacy dejó muerto: ahí llega en blanco.
  final String datoTipoPermiso;

  final DateTime? desde;
  final DateTime? hasta;

  /// `trh_permiso.cantidadDias`. **Es un `float` y viene en fracciones**
  /// (0,125 / 0,4375 / 1,125): truncarlo convertiría una hora de permiso en
  /// cero. Ver `permisos_rrhh_json.dart`.
  final double dias;

  /// «En Hr(s)» de la grilla. **La calcula el DTO del backend como
  /// `dias * 8`**, no el SP —`p_list_Permiso` no devuelve ninguna columna de
  /// horas—.
  ///
  /// **Ojo con el horario continuo**: `f_CalcularDiasHabilesPermiso` topea el
  /// día continuo en 600 minutos pero divide siempre entre 480, así que un día
  /// continuo entero da 1,25 «días» y 10 horas. La cuenta cierra; el rótulo
  /// «días» es el que engaña, y es el mismo número que muestra el ERP.
  final double horas;

  final String motivo;

  const NominaPermisoEntity({
    required this.codPermiso,
    this.codEmpleado = 0,
    this.datoEmpleado = '',
    required this.tipoPermiso,
    this.datoTipoPermiso = '',
    this.desde,
    this.hasta,
    this.dias = 0,
    this.horas = 0,
    this.motivo = '',
  });
}
