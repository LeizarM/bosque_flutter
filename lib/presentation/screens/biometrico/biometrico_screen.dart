import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/tab_empleados.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/tab_horarios.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/tab_marcaciones_olvidadas.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/tab_reporte.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/tab_resumen_mensual.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asistencia Biométrica: las cinco funciones del módulo legacy
/// (`tbioBiometrico/biometrico.xhtml`) que quedan vigentes en el rebuild —
/// ver `CLAUDE.md` para el mapeo completo y por qué "Ver Permisos Empleado"
/// no tiene pestaña propia (ya lo cubre el reporte).
///
/// **Esta clase es sólo el andamiaje**, mismo criterio que
/// `PermisosRrhhScreen`: la barra de arriba y las pestañas. Todo el
/// contenido vive en `widgets/biometrico/`.
///
/// El empleado elegido (`empleadoSeleccionadoBiometricoProvider`) es
/// compartido entre Reporte, Horarios→Por empleado y Marcaciones olvidadas
/// a propósito: es el mismo criterio del wizard legacy — elegís una vez,
/// trabajás sobre esa persona en cualquier pestaña. "Resumen mensual" toca
/// ese mismo provider cuando tocás "ver detalle" de una fila, y salta a la
/// pestaña Reporte (índice 0) con ese empleado ya elegido.
///
/// ## Permisos — `tb_vistaBtn` de `codVista=106`, replicados tal cual
///
/// Cuatro botones (`verEmp`/`defHrs`/`marBio`/`marOlv`), verificados contra
/// la base el 2026-09-01 (`nombreBtn` es el string real, no `codBtn`):
///
/// | `nombreBtn` | Detalle                | Dónde queda acá                       |
/// |---|---|---|
/// | `verEmp`    | Ver Empleado            | pestaña Empleados                     |
/// | `defHrs`    | Definir Horarios        | pestaña Horarios                      |
/// | `marBio`    | Marcaciones Biometrico  | botón "Importar marcaciones" (arriba) |
/// | `marOlv`    | Marcaciones Olvidadas   | pestaña Marcaciones olvidadas         |
///
/// Reporte y Resumen mensual **no tienen botón propio** — quedan cubiertos
/// por el acceso a la vista en sí (`tb_vistaUsuario`, ya resuelto por el
/// menú lateral antes de poder llegar acá), igual que en el legacy: los
/// cuatro botones gatean acciones administrativas puntuales, no la lectura
/// del reporte.
///
/// **Por qué las pestañas NO usan `PermissionWidget` directo** (que sí se
/// usa para el botón de Importar): un `TabController` exige que la cantidad
/// de `Tab`s y de hijos del `TabBarView` coincidan siempre. Envolver una
/// `Tab` en un widget que a veces se reduce a `SizedBox.shrink()` deja el
/// `TabBar` con 5 pestañas contadas pero menos widgets reales — el mismo bug
/// real que tuvo Comisiones, ya documentado en el comentario de
/// `tienePermisoDeBoton` (`permission_widget.dart`). Acá se resuelven los
/// tres booleanos UNA sola vez y se usan igual en `TabBar` y `TabBarView`,
/// así el largo nunca puede desincronizarse entre las dos.
class BiometricoScreen extends ConsumerWidget {
  const BiometricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrarHorarios = tienePermisoDeBoton(ref, 'defHrs');
    final mostrarEmpleados = tienePermisoDeBoton(ref, 'verEmp');
    final mostrarOlvidadas = tienePermisoDeBoton(ref, 'marOlv');
    final cantidadPestanas =
        2 +
        (mostrarHorarios ? 1 : 0) +
        (mostrarEmpleados ? 1 : 0) +
        (mostrarOlvidadas ? 1 : 0);

    return DefaultTabController(
      length: cantidadPestanas,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Asistencia Biométrica'),
          actions: [
            PermissionWidget(
              buttonName: 'marBio',
              child: IconButton(
                tooltip: 'Importar marcaciones del mes desde el biométrico',
                icon: const Icon(Icons.sync),
                onPressed: () => _confirmarImportar(context, ref),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Reporte'),
              const Tab(text: 'Resumen mensual'),
              if (mostrarHorarios) const Tab(text: 'Horarios'),
              if (mostrarEmpleados) const Tab(text: 'Empleados'),
              if (mostrarOlvidadas) const Tab(text: 'Marcaciones olvidadas'),
            ],
          ),
        ),
        body: Builder(
          // El Builder da un context POR DEBAJO del DefaultTabController, que
          // es lo que necesita `DefaultTabController.of` para cambiar de
          // pestaña desde "ver detalle" del resumen — sin este Builder, el
          // context de arriba (el de este `build`) queda por ENCIMA del
          // controller y `DefaultTabController.of` no lo encuentra.
          builder:
              (context) => TabBarView(
                children: [
                  const TabReporte(),
                  TabResumenMensual(
                    onVerDetalle:
                        () => DefaultTabController.of(context).animateTo(0),
                  ),
                  if (mostrarHorarios) const TabHorarios(),
                  if (mostrarEmpleados) const TabEmpleados(),
                  if (mostrarOlvidadas) const TabMarcacionesOlvidadas(),
                ],
              ),
        ),
      ),
    );
  }

  static Future<void> _confirmarImportar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final mes = ref.read(mesSeleccionadoBiometricoProvider);
    final ok = await confirmar(
      context,
      titulo: 'Importar marcaciones',
      mensaje:
          'Se van a traer del dispositivo biométrico las marcaciones de '
          '${nombresMeses[mes.month - 1]} de ${mes.year}. Puede tardar unos '
          'segundos.',
      accion: 'Importar',
    );
    if (!ok || !context.mounted) return;

    try {
      final repo = ref.read(biometricoRepositoryProvider);
      final detalle = await repo.importarMarcacionesMensual(mes);
      if (!context.mounted) return;
      avisar(context, detalle.isEmpty ? 'Importación completada.' : detalle);
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}
