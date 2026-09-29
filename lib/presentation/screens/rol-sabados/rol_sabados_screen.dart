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
/// Sólo andamiaje: selector, pestañas, botón flotante y los cuatro
/// `ScrollController` de la matriz (se crean aquí para **atarlos**). «Su equipo»
/// sólo se crea para quien figura en `trs_Programador`; como el permiso llega
/// por red, el `TabController` se rehace (de ahí el `TickerProviderStateMixin`).
class RolSabadosScreen extends ConsumerStatefulWidget {
  const RolSabadosScreen({super.key});

  @override
  ConsumerState<RolSabadosScreen> createState() => _RolSabadosScreenState();
}

class _RolSabadosScreenState extends ConsumerState<RolSabadosScreen>
    with TickerProviderStateMixin {
  /// Índices de las pestañas, en el orden en que se arman abajo: 0 Grilla ·
  /// 1 Grupos · 2 Cambios · 3 Control · 4 Su equipo (si aparece). Con números
  /// sueltos, mover una rompería el botón flotante; «Su equipo» va última para
  /// que agregarla no corra a las que tienen acción.
  static const int _tabGrupos = 1;
  static const int _tabCambios = 2;

  // Uno por eje visible. El cuerpo manda; los otros lo siguen.
  final _hCuerpo = ScrollController();
  final _hCabecera = ScrollController();
  final _vCuerpo = ScrollController();
  final _vNombres = ScrollController();

  bool _sincronizando = false;

  /// Sin `final`: se reemplaza al aparecer o desaparecer la quinta pestaña
  /// (reasignar un `late final` lanza `LateInitializationError`).
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
  /// El viejo se descarta **después del frame**: la `TabBar` y el `TabBarView`
  /// aún montados se dan de baja del anterior al reconstruirse, y destruirlo antes
  /// los haría tocar una animación inexistente. Por eso conviven dos a la vez.
  void _ajustarPestanas(int cantidad) {
    if (_tabs.length == cantidad) return;
    final viejo = _tabs;
    // Se conserva la pestaña actual, salvo que ya no exista.
    final indice = viejo.index >= cantidad ? cantidad - 1 : viejo.index;
    _tabs = TabController(length: cantidad, initialIndex: indice, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => viejo.dispose());
  }

  /// Replica el offset de [origen] en [destino]. El flag corta la recursión (A
  /// dispara a B y B a A).
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

    // El biométrico pisa al rol EN CUANTO se entra al módulo (sin job ni botón).
    // El provider es `autoDispose.family` y cachea por `idRol`: no reintenta la
    // escritura en cada rebuild. No se lee su valor ni su error a propósito (ver
    // el javadoc del provider).
    if (idRol != null) ref.watch(aplicarExcusasHorarioAlEntrarProvider(idRol));

    // `valueOrNull` y no `when`: mientras el permiso viaja se arma con las cuatro
    // de siempre y la quinta entra al llegar.
    final equipo = ref.watch(miEquipoProvider).valueOrNull;
    final programa = equipo?.puedoProgramar == true;
    _ajustarPestanas(programa ? 5 : 4);

    // Los ABM y la regeneración son de RR.HH.: deciden quién puede decidir, y eso
    // no se delega. Un jefe programador queda afuera aunque tenga «Su Equipo».
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
          // Dos botones y no un menú: son los DOS permisos del módulo y no grados de lo
          // mismo (un jefe alcanza a su gente y sólo decide si viene; RR.HH. alcanza a
          // todos y con cualquier letra).
          if (administra)
            IconButton(
              tooltip: 'RR.HH.',
              icon: const Icon(Icons.badge_outlined),
              onPressed: () => mostrarAdminRrhh(context),
            ),
          // La varita va con los ABM y no con «Actualizar»: rehace el año de las 85
          // personas de una vez; es la escritura más ancha del módulo, no un refresco.
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
                      // Primera pantalla del módulo para los 134 usuarios (`rolSeleccionadoProvider`
                      // arranca en null): nombrar la varita a quien no la tiene lo manda a buscar un
                      // botón que no está.
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

  /// En pantalla chica el icono sobre el texto se come 26 px de alto que hacen
  /// falta al contenido. Las dos listas de `tabs` deben tener la misma cantidad
  /// que el `TabBarView`, o el `TabController` queda sin una pestaña.
  TabBar _barraDePestanas(BuildContext context, bool programa) {
    final chico = Aire.de(MediaQuery.sizeOf(context).width).esChico;
    return TabBar(
      controller: _tabs,
      // Cinco pestañas en 360 px son 72 px cada una y el padding del rótulo se lleva
      // 32: «Su equipo» se parte en dos renglones y desborda. Scrolleable sólo en ese
      // caso (una barra que se arrastra sin necesidad esconde pestañas).
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
    // Un alta o baja de programador debe verse sin cerrar sesión: es lo que hace
    // aparecer o desaparecer la quinta pestaña.
    ref.invalidate(miEquipoProvider);
  }

  /// Cada pestaña tiene su propia acción, o ninguna.
  ///
  /// En un rol CERRADO no aparece nada: el backend rebota toda escritura.
  /// [administra] sólo apaga el de Grupos; «Nuevo cambio» lo pide cualquiera (se
  /// solicita y luego alguien aprueba, lo que lo hace inofensivo).
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
                  // Esconder la varita y dejar este botón sería teatro: hace lo mismo
                  // (`generarRol(modo: 'REGENERAR')`) pero a la vista, diciendo qué hace.
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
