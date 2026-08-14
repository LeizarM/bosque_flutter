// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

/// Una persona dentro de una **carga colectiva**: lo que le tocaría si el lote
/// se aplica.
///
/// **Un solo tipo para el padrón y para la simulación**, y no dos casi iguales:
/// las dos listas tienen la misma fila —quién es, de qué relación y de qué
/// sucursal, cuántos días y si entra—. El padrón (`/colectivo/empleados`) llega
/// con [dias] en 0 y [entra] en `true`; las dos simulaciones llegan con los días
/// ya resueltos y con los excluidos marcados en [detalle].
///
/// **Por qué la simulación existe.** En la vacación colectiva el número del
/// cabezal **no es el que se graba**: el legacy calcula el total con
/// `calcularHrsEnDias()` (sin feriados) y después graba cada fila con
/// `calcularHrsPorEmpleado(desde, hasta, codSucursal)`, que descuenta los
/// feriados **de la sucursal de esa persona**. «5 días a 40 personas» puede
/// terminar siendo 4,5 para los de una sucursal. Confirmar sobre el número del
/// cabezal es confirmar un número que nadie va a ver en la tabla.
///
/// **Pedir esto no escribe nada.** Aplicar es otra llamada, y en el medio va la
/// confirmación: es el doble paso del asistente legacy (sub-vista 1 elegir,
/// sub-vista 2 confirmar), la única barrera que hay hoy antes de escribir N
/// filas de una.
class SimulacionColectivaEntity {
  final int codEmpleado;
  final String datoEmpleado;

  /// La relación laboral de esa persona. **La resuelve el servidor**, no el
  /// cliente: el legacy graba el `codRelEmplEmpr` de cada empleado y no el del
  /// cabezal, y dejar que viaje desde el teléfono sería dejar mover una fila de
  /// relación —y con ella, el saldo de dos persona-relación a la vez—.
  final int codRelEmplEmpr;

  /// De dónde salen los feriados que se le descuentan. Ver el javadoc de clase.
  final int codSucursal;
  final String datoSucursal;
  final String datoEmpresa;

  /// Lo que le tocaría a **esta** persona. En el abono colectivo es el mismo
  /// número para todos; en la vacación colectiva, no.
  final double dias;

  /// Formateado por el backend (`Fmt.dias`), como en el resto del módulo.
  final String diasTxt;

  /// Entra en el lote. Cuando es `false`, [detalle] dice por qué.
  final bool entra;

  /// Por qué se saltea, cuando se saltea: «ya tiene un abono idéntico ese día»,
  /// «no tiene relación laboral activa». Vacío si entra.
  final String detalle;

  const SimulacionColectivaEntity({
    required this.codEmpleado,
    required this.datoEmpleado,
    required this.codRelEmplEmpr,
    this.codSucursal = 0,
    this.datoSucursal = '',
    this.datoEmpresa = '',
    this.dias = 0,
    this.diasTxt = '',
    this.entra = true,
    this.detalle = '',
  });
}
