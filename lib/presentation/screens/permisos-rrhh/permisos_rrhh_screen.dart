import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/reporte_boletas.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/quien_esta_fuera_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/buscador_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/carga_colectiva_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/pestanas_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permisos y Vacaciones de RR.HH.: buscar a una persona, responder **cuántos
/// días tiene y de dónde salen**, y corregirlos.
///
/// **Esta clase es sólo el andamiaje**: la barra de arriba y el reparto de la
/// pantalla. Todo el contenido vive en `widgets/permisos-rrhh/`, un archivo por
/// cosa:
///
/// | qué                | archivo                       | qué resuelve            |
/// |--------------------|-------------------------------|-------------------------|
/// | Maestro            | `buscador_empleado.dart`      | encontrar a la persona  |
/// | Detalle            | `pestanas_empleado.dart`      | las cinco pestañas y su ACL |
/// | Pestaña Saldo      | `ficha_saldo.dart`            | cuántos días tiene (`'C'`) |
/// | Pestaña Desglose   | `desglose_saldo.dart`         | de dónde salen (`'D'`)  |
/// | Pestaña Asignada   | `vacacion_asignada_tab.dart`  | lo que se le debe, con su ABM |
/// | Pestaña Abonos     | `abono_dias_tab.dart`         | días acreditados, con su ABM |
/// | Pestaña Permisos   | `nomina_permisos_tab.dart`    | el kardex (`'Q'`) y las tres altas |
/// | Pestaña Calculadora| `calculadora_antiguedad.dart` | tanteo de antigüedad (`'U'`) |
/// | Hojas de carga     | `*_sheet.dart`                | las escrituras y su confirmación |
///
/// **Las escrituras mueven plata**, así que ninguna se dispara del toque que la
/// pide: todas pasan por un diálogo que dice la cantidad, a quién y con qué
/// fecha. Las colectivas además muestran la simulación antes de habilitar el
/// botón, y no se ofrecen en pantalla chica —el motivo lo explica el bloque de
/// altas de la pestaña «Permisos», que es donde se las busca—.
///
/// **Cómo decide el reparto.** Con `LayoutBuilder` sobre el ancho del **cajón**,
/// no de la ventana: adentro del `DashboardScreen` el sidebar se lleva su parte,
/// así que `MediaQuery.size.width` diría 1280 en un panel de 1000. Y no se usa
/// `getResponsiveValue`: sus `isDesktop` e `isTablet` son ambos `true` en todo el
/// rango 451–1920 px y, como evalúa móvil → tablet → escritorio, el argumento
/// `desktop:` no se alcanza nunca por debajo de 1921 px.
///
/// El único lugar del módulo que mide el **dispositivo** y no el cajón es el
/// aviso de por qué faltan las cargas colectivas, en `nomina_permisos_tab.dart`:
/// ahí la pregunta es «¿es un teléfono?», que el ancho de un panel no contesta.
class PermisosRrhhScreen extends ConsumerWidget {
  const PermisosRrhhScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elegido = ref.watch(empleadoSeleccionadoProvider);

    // El `LayoutBuilder` envuelve al `Scaffold` y no al revés: la barra de
    // arriba también cambia con el ancho —en el celular lleva el acceso a la
    // calculadora, que allá no está a la vista— y necesita la misma medida.
    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);
        // Sólo arriba de 1000 px entran el panel maestro de 400 y el detalle
        // uno al lado del otro; ver `_cuerpo`.
        final partido = aire == Aire.amplio;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Permisos y Vacaciones'),
            // ── SUPUESTO D4 — pendiente de confirmación de RR.HH. (plan §5) ──
            //
            // **Dos botones del ACL, no uno.** El backend exige `btnApoyoCalc`
            // en el endpoint de la calculadora y `btnDetalles` en los otros dos,
            // y los padrones no coinciden (5 y 6 usuarios con `nivelAcceso != 0`
            // medidos en la base). Ofrecer el atajo de la calculadora a quien no
            // tiene `btnApoyoCalc` es mandarlo a elegir dos fechas para recibir
            // un 403. **Esconder no es autorizar**: el gate de verdad está en el
            // backend; esto es sólo no ofrecer un callejón.
            actions: [
              // «Quién está fuera» no depende del empleado elegido, así que va
              // en la barra y no en las pestañas: la pregunta es «¿quién falta
              // hoy?», no «¿cuántos días tiene Fulano?».
              PermissionWidget(
                buttonName: btnConsultaSaldo,
                child: IconButton(
                  tooltip: 'Quién está fuera',
                  icon: const Icon(Icons.groups_outlined),
                  onPressed: () => mostrarQuienEstaFuera(context),
                ),
              ),

              // Buscar una boleta tampoco depende del empleado elegido: es
              // justamente la búsqueda que se hace cuando no se sabe de quién
              // era. Gate propio, el mismo que exige el PDF.
              PermissionWidget(
                buttonName: btnBoleta,
                child: IconButton(
                  tooltip: 'Reporte de boletas',
                  icon: const Icon(Icons.receipt_long_outlined),
                  onPressed: () => mostrarReporteBoletas(context),
                ),
              ),

              // Cuando el detalle es otra página, la calculadora —que no
              // necesita empleado— quedaría escondida detrás de elegir a
              // alguien. Abre la misma página en su pestaña.
              if (!partido)
                PermissionWidget(
                  buttonName: btnCalculadora,
                  child: IconButton(
                    tooltip: 'Calculadora de antigüedad',
                    icon: const Icon(Icons.calculate_outlined),
                    // El índice sale de `PestanasDelEmpleado` y no escrito acá:
                    // es posicional, así que cualquier pestaña que entre o salga
                    // del medio lo mueve. Pasó cuando entró «Permisos» —la
                    // calculadora quedó en 5— y volvería a pasar ahora que
                    // «Permisos» está apagada, que la devuelve a 4.
                    onPressed:
                        () => _abrirDetalle(
                          context,
                          elegido,
                          pestana: PestanasDelEmpleado.indiceCalculadora,
                        ),
                  ),
                ),

              // ── LAS CARGAS COLECTIVAS, SÓLO CON PANTALLA ANCHA ──────────
              //
              // **No es una limitación de ancho, es de seguridad.** Marcar
              // gente en una lista táctil de 360 px se dispara de un roce, y
              // acá cada roce de más es una persona cobrando días que no le
              // tocaban. Escribe N filas de una sola vez y no hay «deshacer»:
              // revertir es borrar N filas a mano.
              //
              // Se esconde en vez de deshabilitarse porque el bloque de altas
              // de la pestaña «Permisos» ya explica por qué no está —un botón
              // apagado sin motivo se lee como que el sistema falla—.
              if (partido) ...[
                PermissionWidget(
                  buttonName: btnAbonoGrupal,
                  child: IconButton(
                    tooltip: 'Abono de días a varias personas',
                    icon: const Icon(Icons.group_add_outlined),
                    onPressed:
                        () => mostrarCargaColectivaSheet(
                          context: context,
                          tipo: TipoCargaColectiva.abonoDias,
                        ),
                  ),
                ),
                PermissionWidget(
                  buttonName: btnVacacionGrupal,
                  child: IconButton(
                    tooltip: 'Vacación colectiva',
                    icon: const Icon(Icons.beach_access_outlined),
                    onPressed:
                        () => mostrarCargaColectivaSheet(
                          context: context,
                          tipo: TipoCargaColectiva.vacacion,
                        ),
                  ),
                ),
              ],

              if (elegido != null)
                PermissionWidget(
                  buttonName: btnConsultaSaldo,
                  child: IconButton(
                    tooltip: 'Actualizar',
                    icon: const Icon(Icons.refresh),
                    onPressed:
                        () => ref
                            .read(permisosRrhhAccionesProvider)
                            .refrescar(elegido.codEmpleado),
                  ),
                ),
            ],
          ),
          body: _cuerpo(context, aire),
        );
      },
    );
  }

  /// El buscador solo, o el buscador y el detalle lado a lado.
  ///
  /// **El corte es 1000 px, no 600.** Es el que asigna la tabla de §6.5: el
  /// panel maestro es de la columna «Desktop / Web (`Aire.amplio`)»; para tablet
  /// (600–1000) pide buscador a pantalla completa. Con el corte en 600, a 800 px
  /// —uno de los cuatro anchos del criterio #11— al detalle le quedaban 399 px,
  /// que vuelven a caer en `Aire.justo`: adentro se dibujaba el layout de móvil
  /// con las etiquetas de 95 caracteres del SP envolviendo en cinco renglones.
  /// No desborda —por eso el test de layout no lo veía— pero es exactamente la
  /// lectura apretada que el corte de 1000 existe para evitar.
  Widget _cuerpo(BuildContext context, Aire aire) {
    if (aire != Aire.amplio) {
      // Móvil y tablet: el buscador ocupa todo y el detalle se **empuja**.
      // Partir 360 px en maestro y detalle deja dos columnas donde no se lee
      // ninguna, y 800 px no alcanzan para las dos.
      return BuscadorDeEmpleados(onElegir: (e) => _abrirDetalle(context, e));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 400 px es lo que necesita un nombre completo con su empresa y su
        // cargo debajo sin puntos suspensivos. Fijo y no proporcional: si
        // creciera con el monitor, el panel de un 1920 se llevaría 600 px para
        // mostrar la misma línea de texto.
        const SizedBox(width: 400, child: BuscadorDeEmpleados(onElegir: _nada)),
        const VerticalDivider(width: 1),
        const Expanded(child: PestanasDelEmpleado()),
      ],
    );
  }

  static void _abrirDetalle(
    BuildContext context,
    EmpleadoEntity? empleado, {
    int pestana = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => Scaffold(
              appBar: AppBar(
                // `persona.datoPersona` y no el de nivel raíz: el endpoint del
                // buscador sólo llena el de adentro (ver `buscador_empleado`).
                // Con el otro, esta página se abría sin título.
                title: Text(empleado?.persona.datoPersona ?? 'Herramientas'),
              ),
              body: PestanasDelEmpleado(pestanaInicial: pestana),
            ),
      ),
    );
  }

  // El `_recargar` que vivía acá se mudó a `PermisosRrhhAcciones.refrescar`,
  // como decía su propio comentario: ahora invalida lo mismo que toda escritura
  // del módulo, así que el botón «Actualizar» y guardar una fila no pueden
  // dejar la pantalla en dos estados distintos.

  /// Con el panel al lado, elegir ya cambió el detalle: no hay nada más que
  /// hacer. El provider global lo escribió el buscador.
  static void _nada(EmpleadoEntity _) {}
}
