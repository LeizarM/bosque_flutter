import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/abono_dias_tab.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/calculadora_antiguedad.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/desglose_saldo.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/ficha_saldo.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/nomina_permisos_tab.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/vacacion_asignada_tab.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **La pestaña «Permisos» está apagada.** No se usa por ahora.
///
/// Para volver a encenderla: poner esto en `true` y listo. **Es lo único que hay
/// que tocar**: de acá salen el largo del `TabController`, la pestaña, su
/// contenido y —lo importante— el índice de la calculadora.
///
/// **Por qué un interruptor y no el bloque comentado.** El índice de una pestaña
/// es posicional: apagar una del medio corre a todas las de la derecha. La
/// calculadora se abre por índice desde la barra de la pantalla
/// (`permisos_rrhh_screen.dart`), así que con los bloques comentados a mano
/// habría que acordarse de cambiar además `length` y ese índice —y de
/// devolverlos— o el `initialIndex` queda fuera de rango. Ya hay un comentario
/// en esa pantalla advirtiendo de esta misma trampa, de la vez que la pestaña
/// «Permisos» entró en el medio y movió el número.
const bool mostrarPestanaPermisos = false;

/// Las pestañas de lo que se sabe —y de lo que se corrige— de una persona:
/// qué saldo tiene, de dónde sale, qué se le asignó, qué se le abonó, qué
/// permisos tiene cargados —si [mostrarPestanaPermisos] está en `true`— y la
/// calculadora de tanteo.
///
/// Es el mismo widget en las dos formas de la pantalla: hasta 1000 px adentro de
/// una página empujada, y de ahí para arriba en el panel derecho. Así las
/// pestañas no se escriben dos veces ni se van separando.
///
/// **El nombre no dice «detalle» a propósito.** `DetalleEmpleado` ya existe en
/// `screens/registro_empleado/detalle_empleado.dart` y es otra cosa —la ficha
/// completa del legajo—; dos clases con el mismo nombre en el mismo barrel es
/// la trampa que ya tiene `PermisoEntity`.
class PestanasDelEmpleado extends ConsumerWidget {
  const PestanasDelEmpleado({super.key, this.pestanaInicial = 0});

  /// Dónde queda la calculadora, que se corre con [mostrarPestanaPermisos].
  ///
  /// **Nunca escribir el número a mano** en quien abra esta pantalla: es lo que
  /// se rompe cada vez que una pestaña entra o sale del medio.
  static const int indiceCalculadora = mostrarPestanaPermisos ? 5 : 4;

  /// Cuántas hay. La sigue el `TabController`, así que no puede desfasarse.
  static const int cantidad = mostrarPestanaPermisos ? 6 : 5;

  final int pestanaInicial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleado = ref.watch(empleadoSeleccionadoProvider);

    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);

        // ── SUPUESTO D4 — pendiente de confirmación de RR.HH. (ver plan §5) ──
        //
        // El ACL que ya existe (`tb_vistaBtn` / `tb_usuarioBtn`), sin inventar
        // uno nuevo. **Esconder no es autorizar**: el gate de verdad está en el
        // backend, que resuelve la identidad desde el token. Esto sólo evita
        // ofrecer una pantalla que va a devolver 403.
        //
        // **Un gate por pestaña, porque el backend pide dos botones distintos:**
        // `btnDetalles` para saldo y desglose, `btnApoyoCalc` para la
        // calculadora. Envolver las tres con `btnDetalles` tenía las dos fallas
        // en espejo: quien tiene `btnDetalles` y no `btnApoyoCalc` llegaba al
        // 403 después de elegir dos fechas, y a quien tiene `btnApoyoCalc` sin
        // `btnDetalles` se le escondía entero el módulo —incluida la
        // calculadora, que no necesita ni empleado ni saldo—.
        //
        // Y va un mensaje en vez de una pantalla en blanco: quien no tiene el
        // botón necesita saber que le falta un permiso, no creer que el módulo
        // está roto.
        return DefaultTabController(
          length: cantidad,
          initialIndex: pestanaInicial,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                // Sin iconos en pantalla chica: el icono sobre el texto se
                // come 26 px de alto que le hacen falta al contenido.
                // `isScrollable` **siempre desde que son cinco**:
                // repartidas a partes iguales dejan «Calculadora» en dos
                // renglones hasta en un monitor.
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs:
                    aire.esChico
                        ? const [
                          Tab(text: 'Saldo'),
                          Tab(text: 'Desglose'),
                          Tab(text: 'Asignada'),
                          Tab(text: 'Abonos'),
                          if (mostrarPestanaPermisos) Tab(text: 'Permisos'),
                          Tab(text: 'Calculadora'),
                        ]
                        : const [
                          Tab(
                            icon: Icon(Icons.account_balance_wallet_outlined),
                            text: 'Saldo',
                          ),
                          Tab(
                            icon: Icon(Icons.account_tree_outlined),
                            text: 'Desglose',
                          ),
                          Tab(
                            icon: Icon(Icons.event_available_outlined),
                            text: 'Asignada',
                          ),
                          Tab(
                            icon: Icon(Icons.add_card_outlined),
                            text: 'Abonos',
                          ),
                          if (mostrarPestanaPermisos)
                            Tab(
                              icon: Icon(Icons.event_note_outlined),
                              text: 'Permisos',
                            ),
                          Tab(
                            icon: Icon(Icons.calculate_outlined),
                            text: 'Calculadora',
                          ),
                        ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _pestanaConPermiso(
                      btnConsultaSaldo,
                      'Detalles',
                      'ver el saldo',
                      empleado == null
                          ? const _SinEmpleado()
                          : SaldoTab(codEmpleado: empleado.codEmpleado),
                    ),
                    _pestanaConPermiso(
                      btnConsultaSaldo,
                      'Detalles',
                      'ver el desglose',
                      empleado == null
                          ? const _SinEmpleado()
                          : DesgloseTab(codEmpleado: empleado.codEmpleado),
                    ),
                    // ── Las dos pestañas que además escriben ─────────────
                    //
                    // **Leer y escribir son dos permisos, y la pestaña es el
                    // de LEER.** El backend exige `btnDetalles` en los dos
                    // historiales (`/vacacion-asignada/historial` y
                    // `/abono-dias/historial`) y el botón de la ABM sólo en
                    // `registrar` y `eliminar`. Envolver la pestaña entera con
                    // el de escritura le escondía la consulta —que sí puede
                    // hacer— a quien tiene `btnDetalles` y no la ABM.
                    //
                    // Los botones de adentro llevan su propio gate, igual que
                    // se hizo con `btnDetalles`/`btnApoyoCalc` en la Fase 1.
                    _pestanaConPermiso(
                      btnConsultaSaldo,
                      'Detalles',
                      'ver la vacación asignada',
                      empleado == null
                          ? const _SinEmpleado()
                          : VacacionAsignadaTab(
                            codEmpleado: empleado.codEmpleado,
                          ),
                    ),
                    _pestanaConPermiso(
                      btnConsultaSaldo,
                      'Detalles',
                      'ver los abonos de días',
                      empleado == null
                          ? const _SinEmpleado()
                          : AbonoDiasTab(codEmpleado: empleado.codEmpleado),
                    ),
                    // El kardex y sus tres altas. **La pestaña es de lectura**
                    // (`btnDetalles`, el mismo que exige el backend en
                    // `/permiso/historial`); los tres botones de adentro llevan
                    // cada uno el suyo, que no son el mismo padrón: 4 usuarios
                    // tienen «Programar permiso» y 5 los otros dos.
                    if (mostrarPestanaPermisos)
                      _pestanaConPermiso(
                        btnConsultaSaldo,
                        'Detalles',
                        'ver la nómina de permisos',
                        empleado == null
                            ? const _SinEmpleado()
                            : NominaPermisosTab(
                              codEmpleado: empleado.codEmpleado,
                            ),
                      ),
                    // La calculadora no necesita empleado: es una herramienta
                    // de tanteo sobre dos fechas cualesquiera. Y pide su
                    // propio botón del ACL, que es el que exige el backend.
                    _pestanaConPermiso(
                      btnCalculadora,
                      'Apoyo Cálculo',
                      'usar la calculadora',
                      const CalculadoraTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// El contenido de una pestaña, o el motivo por el que no se ve.
  ///
  /// [boton] es el `nombreBtn` de `tb_vistaBtn` que el backend exige para el
  /// endpoint de esa pestaña; [botonHumano] es cómo se llama en la pantalla de
  /// permisos, que es lo que hay que pedirle a Sistemas.
  Widget _pestanaConPermiso(
    String boton,
    String botonHumano,
    String queHace,
    Widget hijo,
  ) => PermissionWidget(
    buttonName: boton,
    placeholder: MensajeVacio(
      icono: Icons.lock_outline,
      titulo: 'No tiene permiso para $queHace',
      detalle:
          'Solicite a Sistemas el botón «$botonHumano» de la vista Permisos / '
          'Vacaciones. Tener la vista en el menú no alcanza.',
    ),
    child: hijo,
  );
}

class _SinEmpleado extends StatelessWidget {
  const _SinEmpleado();

  @override
  Widget build(BuildContext context) => const MensajeVacio(
    icono: Icons.person_search_outlined,
    titulo: 'Seleccione un empleado',
    // Sin «a la izquierda»: en el celular esta misma pantalla se llega desde la
    // calculadora, donde no hay ninguna lista al costado.
    detalle:
        'Búsquelo por nombre o apellido en la lista para ver su saldo y de '
        'dónde sale.',
  );
}
