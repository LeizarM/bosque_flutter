import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/cambios_tab.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/control_tab.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/evento_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/matriz_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/personal_tab.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/programadores_admin.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rrhh_admin.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/selector_rol.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/su_equipo_tab.dart';

/// Rol de Turnos de Sábado: quién viene a trabajar cada sábado del año.
///
/// **Esta clase es sólo el andamiaje**: el selector de rol, las pestañas, el
/// botón flotante y los cuatro `ScrollController` de la matriz. Todo el
/// contenido vive en `widgets/rol-sabados/`, un archivo por pestaña:
///
/// | pestaña   | archivo             | qué resuelve                          |
/// |-----------|---------------------|---------------------------------------|
/// | Grilla    | `matriz_grilla.dart`| la matriz, o la agenda en pantalla chica |
/// | Grupos    | `personal_tab.dart` | armar los grupos A/B a mano           |
/// | Cambios   | `cambios_tab.dart`  | permutas y coberturas                 |
/// | Control   | `control_tab.dart`  | qué tan bien funciona el default      |
/// | Su equipo | `su_equipo_tab.dart`| un jefe decide quién de los suyos viene |
///
/// **La quinta pestaña no siempre está.** Las cuatro primeras son de RR.HH.;
/// «Su equipo» sólo la ve quien figura en `trs_Programador`, que hoy son dos
/// personas de ciento treinta y cuatro. Y no aparece deshabilitada sino que
/// **no se crea**: una pestaña muerta para el 98% de la gente es ruido puro.
/// Como el permiso llega por red, el `TabController` se rehace cuando llega la
/// respuesta — de ahí el `TickerProviderStateMixin` en plural y el `late` sin
/// `final`.
///
/// Los controladores de scroll se crean acá y no en la matriz porque hay que
/// **atarlos entre sí**: son cuatro ejes —dos horizontales y dos verticales— y
/// si el encabezado se despega de las celdas, la grilla miente. Además tienen
/// que sobrevivir a que la pestaña se reconstruya.
class RolSabadosScreen extends ConsumerStatefulWidget {
  const RolSabadosScreen({super.key});

  @override
  ConsumerState<RolSabadosScreen> createState() => _RolSabadosScreenState();
}

class _RolSabadosScreenState extends ConsumerState<RolSabadosScreen>
    with TickerProviderStateMixin {
  /// Índices de las pestañas, en el orden en que se arman abajo:
  /// 0 Grilla · 1 Grupos · 2 Cambios · 3 Control · 4 Su equipo (si aparece).
  /// Con números sueltos, mover una de lugar rompería el botón flotante sin que
  /// nada avise. «Su equipo» va última justamente por eso: agregarla no corre a
  /// ninguna de las que ya tienen acción.
  static const int _tabGrupos = 1;
  static const int _tabCambios = 2;

  // Uno por eje visible. El cuerpo manda; los otros lo siguen.
  final _hCuerpo = ScrollController();
  final _hCabecera = ScrollController();
  final _vCuerpo = ScrollController();
  final _vNombres = ScrollController();

  bool _sincronizando = false;

  /// Sin `final`: se reemplaza cuando aparece o desaparece la quinta pestaña.
  /// Reasignar un `late final` lanza `LateInitializationError`.
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _atar(_hCuerpo, _hCabecera);
    _atar(_hCabecera, _hCuerpo);
    _atar(_vCuerpo, _vNombres);
    _atar(_vNombres, _vCuerpo);
  }

  /// Rehace el controlador cuando cambia la cantidad de pestañas.
  ///
  /// El viejo se descarta **después del frame** y no en el acto: la `TabBar` y
  /// el `TabBarView` que todavía están montados se dan de baja del controlador
  /// anterior recién cuando se reconstruyen, y si para entonces ya lo
  /// destruimos, tocan una animación que no existe. Por eso viven dos a la vez
  /// y por eso el mixin es el plural.
  void _ajustarPestanas(int cantidad) {
    if (_tabs.length == cantidad) return;
    final viejo = _tabs;
    // Se conserva la pestaña donde estaba parado, salvo que ya no exista.
    final indice = viejo.index >= cantidad ? cantidad - 1 : viejo.index;
    _tabs = TabController(
      length: cantidad,
      initialIndex: indice,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => viejo.dispose());
  }

  /// Replica el offset de [origen] en [destino].
  ///
  /// El flag corta la recursión: sin él, mover A dispara a B, que vuelve a
  /// disparar a A, y el scroll se traba.
  void _atar(ScrollController origen, ScrollController destino) {
    origen.addListener(() {
      if (_sincronizando) return;
      if (!destino.hasClients || !origen.hasClients) return;
      if (destino.offset == origen.offset) return;
      _sincronizando = true;
      destino.jumpTo(origen.offset);
      _sincronizando = false;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _hCuerpo.dispose();
    _hCabecera.dispose();
    _vCuerpo.dispose();
    _vNombres.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idRol = ref.watch(rolSeleccionadoProvider);

    // `valueOrNull` y no un `when`: mientras el permiso viaja, la pantalla se
    // arma con las cuatro de siempre y la quinta entra sola al llegar.
    final equipo = ref.watch(miEquipoProvider).valueOrNull;
    final programa = equipo?.puedoProgramar == true;
    _ajustarPestanas(programa ? 5 : 4);

    // Los ABM y la regeneración son de RR.HH., no del jefe: deciden quién puede
    // decidir, y eso no se delega en quien va a usar el permiso. Un jefe
    // programador queda afuera, aunque tenga la pestaña «Su Equipo».
    final administra = ref.watch(administraRolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol de Turnos de Sábado'),
        actions: [
          if (administra)
            IconButton(
              tooltip: 'Programadores',
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () => mostrarAdminProgramadores(context),
            ),
          // Dos botones y no un menú con dos entradas: son los DOS permisos del
          // módulo y conviene que se vean como cosas separadas. Juntarlos invita
          // a leerlos como grados de lo mismo, y no lo son — un jefe alcanza a
          // su gente y sólo decide si viene o no; RR.HH. alcanza a todos y con
          // cualquier letra.
          if (administra)
            IconButton(
              tooltip: 'RR.HH.',
              icon: const Icon(Icons.badge_outlined),
              onPressed: () => mostrarAdminRrhh(context),
            ),
          // La varita entra en el mismo grupo que los dos ABM y no en el de
          // «Actualizar»: rehace el año de las 85 personas de una sola vez. Es
          // la escritura más ancha del módulo, no un refresco de pantalla.
          if (administra)
            IconButton(
              tooltip: 'Generar o regenerar un rol',
              icon: const Icon(Icons.auto_fix_high),
              onPressed: () => _abrirGenerar(idRol),
            ),
          if (idRol != null)
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: () => _recargar(idRol),
            ),
        ],
        bottom: idRol == null ? null : _barraDePestanas(context, programa),
      ),
      floatingActionButton: _botonFlotante(idRol, administra: administra),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SelectorDeRol(),
          const Divider(height: 1),
          Expanded(
            child:
                idRol == null
                    ? MensajeVacio(
                      icono: Icons.calendar_month_outlined,
                      titulo: 'Elige un rol',
                      // Es la primera pantalla del módulo para los 134 usuarios
                      // —`rolSeleccionadoProvider` arranca en null—, así que es
                      // el texto que más se lee. Nombrar la varita a quien no la
                      // tiene lo manda a buscar un botón que no está.
                      detalle:
                          administra
                              ? 'Selecciona el año arriba para ver la grilla, o '
                                  'genera uno nuevo con la varita.'
                              : 'Selecciona el año arriba para ver la grilla.',
                    )
                    : TabBarView(
                      controller: _tabs,
                      children: [
                        GrillaTab(
                          idRol: idRol,
                          hCuerpo: _hCuerpo,
                          hCabecera: _hCabecera,
                          vCuerpo: _vCuerpo,
                          vNombres: _vNombres,
                        ),
                        PersonalTab(idRol: idRol),
                        CambiosTab(idRol: idRol),
                        ControlTab(idRol: idRol),
                        if (programa) SuEquipoTab(idRol: idRol),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  /// En pantalla chica el icono sobre el texto se come 26 px de alto que le
  /// hacen falta al contenido.
  ///
  /// Las dos listas dejaron de ser `const` para poder meter la quinta pestaña
  /// con una condición que se resuelve en tiempo de ejecución. Y va en LAS DOS:
  /// una lista con cuatro y la otra con cinco dejaría al `TabController` sin la
  /// pestaña que el `TabBarView` sí tiene.
  TabBar _barraDePestanas(BuildContext context, bool programa) {
    final chico = Aire.de(MediaQuery.sizeOf(context).width).esChico;
    return TabBar(
      controller: _tabs,
      // Cinco pestañas fijas en 360 px son 72 px cada una, y de esos 32 se los
      // lleva el padding del rótulo: «Su equipo» se parte en dos renglones y
      // desborda el alto de la barra. Scrolleable sólo en ese caso: con cuatro
      // entran, y una barra que se arrastra sin necesidad esconde pestañas.
      isScrollable: chico && programa,
      tabs:
          chico
              ? [
                const Tab(text: 'Grilla'),
                const Tab(text: 'Grupos'),
                const Tab(text: 'Cambios'),
                const Tab(text: 'Control'),
                if (programa) const Tab(text: 'Su equipo'),
              ]
              : [
                const Tab(icon: Icon(Icons.grid_on), text: 'Grilla'),
                const Tab(icon: Icon(Icons.groups_outlined), text: 'Grupos'),
                const Tab(icon: Icon(Icons.swap_horiz), text: 'Cambios'),
                const Tab(
                  icon: Icon(Icons.fact_check_outlined),
                  text: 'Control',
                ),
                if (programa)
                  const Tab(
                    icon: Icon(Icons.supervisor_account_outlined),
                    text: 'Su equipo',
                  ),
              ],
    );
  }

  void _recargar(int idRol) {
    ref.invalidate(grillaRolProvider(idRol));
    ref.invalidate(cambiosProvider(idRol));
    ref.invalidate(intervencionesProvider(idRol));
    ref.invalidate(desfasesPermisoProvider(idRol));
    // Un alta o una baja de programador tiene que verse sin cerrar sesión: es
    // la única forma de que aparezca o desaparezca la quinta pestaña.
    ref.invalidate(miEquipoProvider);
  }

  /// Cada pestaña tiene su propia acción, o ninguna.
  ///
  /// En un rol CERRADO no aparece nada: el backend rebota toda escritura, y
  /// ofrecer el botón sería prometer algo que no se puede cumplir.
  ///
  /// [administra] sólo apaga el de Grupos. «Nuevo cambio» lo pide cualquiera —
  /// un cambio se solicita y después alguien lo aprueba, que es justo lo que lo
  /// hace inofensivo.
  Widget? _botonFlotante(int? idRol, {required bool administra}) {
    if (idRol == null) return null;
    return AnimatedBuilder(
      animation: _tabs,
      builder: (context, _) {
        if (_tabs.index != _tabGrupos && _tabs.index != _tabCambios) {
          return const SizedBox.shrink();
        }
        return ref
            .watch(grillaRolProvider(idRol))
            .maybeWhen(
              data: (g) {
                if (g.rol.estaCerrado) return const SizedBox.shrink();
                if (_tabs.index == _tabGrupos) {
                  // Esconder la varita y dejar este botón sería teatro: hace
                  // exactamente lo mismo —`generarRol(modo: 'REGENERAR')`— y
                  // encima a la vista, en un FAB que dice qué hace.
                  return administra
                      ? BotonRegenerar(grilla: g)
                      : const SizedBox.shrink();
                }
                return FloatingActionButton.extended(
                  onPressed:
                      () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => NuevoCambioSheet(grilla: g),
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo cambio'),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
      },
    );
  }

  void _abrirGenerar(int? idRol) {
    final grilla =
        idRol == null ? null : ref.read(grillaRolProvider(idRol)).valueOrNull;
    showDialog<void>(
      context: context,
      builder:
          (_) => GenerarRolDialog(
            idRolExistente: idRol,
            anioExistente: grilla?.rol.anio,
          ),
    );
  }
}
