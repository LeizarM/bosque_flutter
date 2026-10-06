import 'dart:async';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/constants/tareas_a_requerimiento.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/apertura_flujo.dart';

// Controlador global para forzar redirecciones
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Proveedor para detectar si la sesión está activa
final authStateProvider = StateProvider<bool>((ref) => false);

// Referencia global para el router
GoRouter? _router;

/// Envuelve una pantalla para que la pestaña del navegador muestre un
/// título real en vez de quedarse siempre en "bosque_flutter" (el fijo de
/// web/index.html, que nunca cambiaba al navegar).
///
/// [Title] resuelve esto sola: llama a
/// `SystemChrome.setApplicationSwitcherDescription`, que en Flutter Web
/// actualiza `document.title` (en la app nativa, en cambio, es la tarjeta
/// del selector de apps de Android). `color` tiene que ser opaco — el
/// primary de un ColorScheme armado con `ColorScheme.fromSeed` siempre lo
/// es, así que se pasa directo sin reprocesarlo.
///
/// Por qué aquí y no en cada pantalla: go_router arma cada ruta como un
/// `MaterialPage` a partir de este `builder`, así que ruta y título quedan
/// juntos en un solo lugar en vez de duplicar el mapeo ruta→título en cada
/// archivo de pantalla.
///
/// Cobertura: por ahora sólo el módulo Tareas Rutinarias (el que originó
/// este hallazgo). Extenderlo a las demás ~50 rutas de este archivo es
/// mecánico — repetir este mismo wrapper en cada builder — pero se dejó
/// afuera de este cambio para no tocar cada ruta existente en un ajuste
/// pensado como theme-level.
Widget _pantallaConTitulo(BuildContext context, String titulo, Widget child) {
  return Title(
    title: titulo,
    color: Theme.of(context).colorScheme.primary,
    child: child,
  );
}

// Proveedor para el router que se crea una sola vez
final routerProvider = Provider<GoRouter>((ref) {
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  // Observar el estado de autenticación sin leer directamente durante redirecciones
  ref.listen(authStateProvider, (_, __) {
    // Solo escuchar cambios, no hacer nada aquí
  });

  // Crear el router si no existe
  if (_router == null) {
    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/login',
      debugLogDiagnostics:
          true, // Habilitar logs de diagnóstico para depuración
      refreshListenable: GoRouterRefreshStream(
        ref.read(authStateProvider.notifier).stream,
      ),
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Shell route for dashboard
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return DashboardScreen(child: child);
          },
          routes: [
            // Dashboard home
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardHomeContent(),
            ),
            // Ventas module
            GoRoute(
              path: '/dashboard/ventas',
              name: 'ventas',
              builder: (context, state) => const VentasHomeScreen(),
            ),
            // Entregas
            GoRoute(
              path: '/dashboard/Revision',
              name:
                  'revision', // Cambié el nombre para que coincida mejor con la ruta
              builder: (context, state) => const EntregasHomeScreen(),
            ),
            // Nueva ruta para trch_choferEntrega/Revision bajo dashboard
            GoRoute(
              path: '/dashboard/trch_choferEntrega/Revision',
              name: 'trch_chofer_revision',
              builder: (context, state) => const EntregasHomeScreen(),
            ),
            // Ruta para ver las entregas de uno o varios choferes
            GoRoute(
              path: '/dashboard/trch_choferEntrega/Resumen',
              name: 'trch_chofer_resumen',
              builder: (context, state) => const EntregasDashboardScreen(),
            ),
            // Pendientes de entrega
            GoRoute(
              path: '/dashboard/trch_choferEntrega/Pendientes',
              name: 'trch_choferEntrega_Pendientes',
              builder: (context, state) => const PendientesEntregaScreen(),
            ),
            //Ruta para ver los usuarios del sistema
            GoRoute(
              path: '/dashboard/tbUsuario/usuario',
              name: 'tbUsuario',
              builder: (context, state) => const UsuariosHomeScreen(),
            ),
            //Ruta para el registro de gasolina
            GoRoute(
              path: '/dashboard/tgas_ControlCombustible/Registro',
              name: 'tgas_ControlCombustible',
              builder: (context, state) => const ControlCombustibleScreen(),
            ),
            //ruta para ver el historial de gasolina de los coches
            GoRoute(
              path: '/dashboard/tgas_ControlCombustible/View',
              name: 'tgas_ControlCombustibleView',
              builder: (context, state) => const ControlCombustibleViewScreen(),
            ),

            // Para el registro de bidones
            GoRoute(
              path: '/dashboard/tgas_ControlCombustibleMaqMont/Registro',
              name: 'tgas_ControlCombustibleMaqMont',
              builder:
                  (context, state) =>
                      const ControlContenedoresCombustibleScreen(),
            ),
            //Para ver el historial de bidones
            GoRoute(
              path: '/dashboard/tgas_ControlCombustibleMaqMont/View',
              name: 'tgas_ControlCombustibleMaqMontView',
              builder: (context, state) => const ControlCombustibleMainScreen(),
            ),

            //Para el registro de garrafas
            GoRoute(
              path: '/dashboard/tgas_RegistroGarrafa/Registro',
              name: 'tgas_RegistroGarrafa',
              builder:
                  (context, state) => const ControlGarrafasRegistroScreen(),
            ),

            //Para registrar los depositos
            GoRoute(
              path: '/dashboard/tdep_Deposito/Registro',
              name: 'tdep_DepositoReg',
              builder: (context, state) => const DepositoChequeRegisterScreen(),
            ),
            //Para ver el registro de depositos
            GoRoute(
              path: '/dashboard/tdep_Deposito/View',
              name: 'tdep_DepositoView',
              builder: (context, state) => const DepositoChequeViewScreen(),
            ),
            //Para el registro de depositos sin identificar
            GoRoute(
              path: '/dashboard/tdep_DepositoIde/Registro',
              name: 'tdep_DepositoIdeReg',
              builder:
                  (context, state) => const DepositoChequeIdentificarScreen(),
            ),
            //para ver depositos sin identificar
            GoRoute(
              path: '/dashboard/tdep_DepositoIde/View',
              name: 'tdep_DepositoIdeView',
              builder:
                  (context, state) =>
                      const DepositoChequeIdentificarViewScreen(),
            ),
            //Para el prestamo de vehiculos
            GoRoute(
              path: '/dashboard/tpre_Solicitud/Solicitud',
              name: 'tpre_Solicitud',
              builder: (context, state) => const PrestamoDashboardScreen(),
            ),
            GoRoute(
              path: '/dashboard/tpre_Solicitud/VerSolicitud',
              name: 'tpre_SolicitudView',
              builder: (context, state) => const PrestamoViewScreen(),
            ),
            // Para la gestion de empleados y dependientes
            GoRoute(
              path: '/dashboard/ted_EmpleadoDependiente/register',
              name: 'ted_EmpleadoDependienteRegister',
              builder: (context, state) => const EmpleadosDependientesView(),
            ),

            GoRoute(
              path:
                  '/dashboard/trhEstructuraOrganizacional/estructuraOrganizacional',
              name: 'trh_EstructuraOrganizacional',
              builder:
                  (context, state) =>
                      const EstructuraOrganizacionalEmpresaScreen(),
            ),

            GoRoute(
              path: '/dashboard/tb_facturasTigo',
              name: 'tb_facturasTigo',
              builder: (context, state) => const FacturasEjecutadasView(),
            ),
            GoRoute(
              path: '/dashboard/tbEmpleado/registroEmpleado',
              name: 'tbEmpleado/registroEmpleado',
              builder: (context, state) => const ListaEmpleados(),
            ),
            // Pagos al extranjero Registro
            // Talonarios — vista 91 de tb_vista.
            // La ruta es '/dashboard/' + tb_vista.direccion LITERAL: el menú se
            // arma desde la BD y navega con ese valor, así que no se puede
            // inventar. El JSF viejo usa la misma columna para su navegación,
            // por eso no se toca en la BD y se adapta la ruta aquí.
            GoRoute(
              path: '/dashboard/tmtoTalonario/talonario',
              name: 'tmtoTalonario',
              builder: (context, state) => const TalonariosScreen(),
            ),
            GoRoute(
              path: '/dashboard/tpex_RegistroSolicitud/Registro',
              name: 'tpex_RegistroSolicitud',
              builder: (context, state) => const PagosExtranjerosScreen(),
            ),
            // Pagos al extranjero Vista
            GoRoute(
              path: '/dashboard/tpex_RegistroVer/View',
              name: 'tpex_RegistroVerView',
              builder: (context, state) => const PagosAlExtranjerosViewScreen(),
            ),
            // Aprobación de solicitudes (ROLE_GER)
            GoRoute(
              path: '/dashboard/tpex_Aprobacion/Gerencia',
              name: 'tpex_AprobacionGerencia',
              builder: (context, state) => const GerenciaAprobacionScreen(),
            ),
            // Asientos contables / Cobranzas (ROLE_COB)
            GoRoute(
              path: '/dashboard/tpex_Asientos/Cobranzas',
              name: 'tpex_AsientosCobranzas',
              builder: (context, state) => const CobranzasAsientosScreen(),
            ),
            // Descuentos Empleado
            GoRoute(
              path: '/dashboard/tdesc_EmpleadosDescuento/View',
              name: 'tdesc_EmpleadosDescuentoView',
              builder: (context, state) => const InformeEmpDescuentosScreen(),
            ),
            // Comisiones de vendedores.
            // La ruta replica tb_vista.direccion (codVista 82), que es
            // 'tcomComisiones/Comisiones': el menú la construye desde ahí.
            GoRoute(
              path: '/dashboard/tcomComisiones/Comisiones',
              name: 'tcomComisiones',
              builder: (context, state) => const ComisionesScreen(),
            ),

            // Lote de producción
            GoRoute(
              path: '/dashboard/tprod_loteProduccion/loteProduccion',
              name: 'tprod_loteProduccion',
              builder: (context, state) => const LoteProduccionRegistroScreen(),
            ),

            //Registro de resmado
            GoRoute(
              path: '/dashboard/tprod_loteProduccion/Resmado',
              name: 'tprod_loteProduccionResmado',
              builder: (context, state) => const ResmadoRegistroScreen(),
            ),

            // Ver lote de producción
            GoRoute(
              path: '/dashboard/tprod_loteProduccion/ViewLoteProduccion',
              name: 'tprod_loteProduccionView',
              builder: (context, state) => const VerLoteProduccionScreen(),
            ),

            // Ver resmado
            GoRoute(
              path: '/dashboard/tprod_loteProduccion/ViewResmado',
              name: 'tprod_loteProduccionViewResmado',
              builder: (context, state) => const VerResmadoScreen(),
            ),

            // Solicitud de corte
            // La ruta es EXACTAMENTE tb_vista.direccion (codVista 100 =
            // 'tccrControlCorteResmado/solicitudCorte').
            GoRoute(
              path: '/dashboard/tccrControlCorteResmado/solicitudCorte',
              name: 'tccrSolicitudCorte',
              builder: (context, state) => const SolicitudCorteScreen(),
            ),
            //Anticipos Empleados
            GoRoute(
              path: '/dashboard/tplAnticipo/anticipo',
              name: 'tplAnticipo',
              builder: (context, state) => const AnticiposScreen(),
            ),
            //Multas
            GoRoute(
              path: '/dashboard/tplMulta/multas',
              name: 'tplMulta',
              builder: (context, state) => const MultasScreen(),
            ),
            //Bonos
            GoRoute(
              path: '/dashboard/tplBono/bono',
              name: 'tplBono',
              builder: (context, state) => const BonosScreen(),
            ),
            //Planillas
            GoRoute(
              path: '/dashboard/tplPlanilla/planilla',
              name: 'tplPlanilla',
              builder: (context, state) => const PlanillasScreen(),
            ),
            //Prestamos
            GoRoute(
              path: '/dashboard/tplPrestamo/prestamo',
              name: 'tplPrestamo',
              builder: (context, state) => const PrestamosScreen(),
            ),
            // Permisos y Vacaciones
            GoRoute(
              path: '/dashboard/trhPermiso/permiso',
              name: 'trhPermiso',
              builder: (context, state) => const PermisosRrhhScreen(),
            ),
            // Turno Sabados
            GoRoute(
              path: '/dashboard/trs_Sabados/Main',
              name: 'trsSabados',
              builder: (context, state) => const RolSabadosScreen(),
            ),
            // Dias No Laborables (ABM admin) — reemplaza al modulo JSF legacy.
            // La ruta es EXACTAMENTE tb_vista.direccion (codVista 14 =
            // 'tbDiaNoLaborable/diaNoLaborable'), misma regla que las demas
            // rutas de este archivo. La vista, sus 4 botones (tb_vistaBtn:
            // btnNuevoDNL, btnEditarDNL, btnEliminarDNL — btnEditarPEDNL es
            // del ABM por-empresa legacy que no se migro) y el acceso de los
            // 194 usuarios ya existen en tb_vista/tb_vistaUsuario: no hace
            // falta darlos de alta.
            GoRoute(
              path: '/dashboard/tbDiaNoLaborable/diaNoLaborable',
              name: 'tbDiaNoLaborable',
              builder: (context, state) => const DiasNoLaborablesScreen(),
            ),
            // Biométrico — la ruta es tb_vista.direccion (codVista 106 =
            // 'tbioBiometrico/biometrico'), misma regla que Cartas CITE.
            GoRoute(
              path: '/dashboard/tbioBiometrico/biometrico',
              name: 'tbioBiometrico',
              builder: (context, state) => const BiometricoScreen(),
            ),

            // Cartas CITE — la correspondencia numerada.
            // Misma regla que las dos de arriba: la ruta es EXACTAMENTE
            // tb_vista.direccion (codVista 70 = 'tcrDocumento/Documento'),
            // porque el sidebar arma el destino con '/'+direccion.
            GoRoute(
              path: '/dashboard/tcrDocumento/Documento',
              name: 'tcrDocumento',
              builder: (context, state) => const CartasCiteScreen(),
            ),

            // MODULO DE PRECIOS (tpr).
            // Misma regla que Cartas CITE y Biometrico: la ruta es
            // EXACTAMENTE '/dashboard/' + tb_vista.direccion, porque el
            // sidebar arma el destino con '/' + direccion y cae en el
            // redirect de primer nivel de mas abajo. Las direcciones viven en
            // AppConstants para no repetirlas entre el router y el SQL de
            // alta.
            //
            // Propuestas reemplaza al modulo JSF legacy (codVista 66,
            // 'tprAutorizacion/Autorizacion', bajo el padre 65 'Cambio de
            // Precios'): conserva la direccion tal cual, asi el item de menu y
            // los permisos que los usuarios ya tienen siguen funcionando sin
            // tocar tb_vista ni tb_vistaUsuario.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosPropuestas}',
              name: 'tprAutorizacion',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Propuestas de Precio',
                    const PropuestasScreen(),
                  ),
            ),
            // Repreciacion por familia: el arbol de grupo/familia con su
            // precio por tonelada.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosFamilias}',
              name: 'tprFamilias',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Familias de Precio',
                    const FamiliasScreen(),
                  ),
            ),
            // Consulta de precios vigentes por articulo, sucursal y lista.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosPrecios}',
              name: 'tprPrecios',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Precios Vigentes',
                    const PreciosScreen(),
                  ),
            ),
            // Listas de precio: clasificaciones y sus porcentajes.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosListas}',
              name: 'tprListasPrecio',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Listas de Precio',
                    const ListasPrecioScreen(),
                  ),
            ),
            // ABM de los catalogos del modulo: colores, tipos,
            // presentaciones, rangos de gramaje, grupos y proveedores SAP.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosCatalogos}',
              name: 'tprCatalogos',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Catalogos de Precios',
                    const CatalogosPreciosScreen(),
                  ),
            ),
            // Parametros del calculo: impuestos, gramaje y ancla del tipo de
            // cambio.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosParametros}',
              name: 'tprParametros',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Parametros de Precios',
                    const ParametrosPreciosScreen(),
                  ),
            ),
            // Porcentajes por familia y lista de precios: el margen sobre el
            // costo. Reemplaza a los dialogos dlgPorcen y dlgPorcGrupo.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaPreciosPorcentajes}',
              name: 'tprPorcentajes',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Porcentajes de Precios',
                    const PorcentajesScreen(),
                  ),
            ),
            // MODULO DE GARANTIAS DE COBRANZA (tcbr). Reemplaza al JSF legacy
            // (codVista 45, 'tcbrGarantia/garantia', padre 44 'Cobranza') con
            // la direccion tal cual: el item de menu y los permisos que los
            // usuarios ya tienen siguen sirviendo sin tocar tb_vista.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaGarantias}',
              name: 'tcbrGarantia',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Garantías de Cobranza',
                    const GarantiasScreen(),
                  ),
            ),
            // MODULO DE CHEQUES (tch). Reemplaza al JSF legacy (codVista 42,
            // 'tchCheque/cheque', padre 41 'modCheques') con la direccion tal
            // cual: el item de menu y los permisos que los usuarios ya tienen
            // siguen sirviendo sin tocar tb_vista.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaCheques}',
              name: 'tchCheque',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Cheques',
                    const ChequesScreen(),
                  ),
            ),
            // Bancos (tch_banco). Reemplaza a tchBanco/banco.xhtml (codVista 43,
            // padre 140) con la direccion tal cual, por el mismo motivo.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaBancos}',
              name: 'tchBanco',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Bancos',
                    const BancosScreen(),
                  ),
            ),
            // Verificar Cheques (tch_verificacionDeposito). Reemplaza a
            // tchCheque/verificarDepositos.xhtml (codVista 77, padre 41) con la
            // direccion tal cual, por el mismo motivo.
            GoRoute(
              path: '/dashboard/${AppConstants.rutaVerificarCheques}',
              name: 'tchVerificarCheques',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Verificar Cheques',
                    const VerificarChequesScreen(),
                  ),
            ),
            // Tareas Rutinarias — reutiliza la vista legacy 78
            // ('tacTareas/Tareas'), misma regla de siempre: la ruta es
            // EXACTAMENTE tb_vista.direccion. Los 134 usuarios que ya
            // tienen acceso a esa vista la conservan sin tocar
            // tb_vistaUsuario (ver memoria del proyecto).
            GoRoute(
              path: '/dashboard/tacTareas/Tareas',
              name: 'tacTareasMisTareas',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Mis Tareas',
                    const MisTareasRutinariasScreen(),
                  ),
            ),
            // Programar tarea a mi equipo (jefe → dependientes) — capacidad
            // nueva, sin pantalla equivalente en el JSF viejo. Desde el
            // archivo SQL 59 no está en el menú: se abre con el botón "Mi
            // equipo" de "Mis tareas rutinarias", que solo aparece si el cargo
            // vigente tiene codNivel <= nivelMaximoJefe.
            GoRoute(
              path: '/dashboard/tacTareas/Dependientes',
              name: 'tacTareasDependientes',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Tareas de mi Equipo',
                    const DependientesJefeScreen(),
                  ),
            ),
            // Coches (41) y Caja Fuerte (40) — desde el archivo SQL 40/41 son
            // submódulos con fila propia en tb_vista bajo la 87, así que se
            // llega por el sidebar y NO desde "Mis tareas rutinarias" (el Job
            // dejó de generarlas). Cuando se entra por el menú no viene ningún
            // `extra`, así que AperturaFlujo pide al backend la ocurrencia del
            // día antes de construir la pantalla.
            GoRoute(
              path: '/dashboard/tacTareas/Coches',
              name: 'tacTareasCoches',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ?? 'Revisión de Autos';
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  AperturaFlujo(
                    idTarRuti: TareasARequerimiento.coches,
                    nombreFlujo: nombreTarea,
                    idBitTareaExistente: extra['idBitTarea'] as int?,
                    construir:
                        (idBitTarea) => CochesScreen(
                          idTarRuti:
                              (extra['idTarRuti'] as int?) ??
                              TareasARequerimiento.coches,
                          idBitTarea: idBitTarea,
                          nombreTarea: nombreTarea,
                        ),
                  ),
                );
              },
            ),
            GoRoute(
              path: '/dashboard/tacTareas/CajaFuerte',
              name: 'tacTareasCajaFuerte',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ?? 'Caja Fuerte';
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  AperturaFlujo(
                    idTarRuti: TareasARequerimiento.cajaFuerte,
                    nombreFlujo: nombreTarea,
                    idBitTareaExistente: extra['idBitTarea'] as int?,
                    construir:
                        (idBitTarea) => CajaFuerteScreen(
                          idTarRuti:
                              (extra['idTarRuti'] as int?) ??
                              TareasARequerimiento.cajaFuerte,
                          idBitTarea: idBitTarea,
                          nombreTarea: nombreTarea,
                        ),
                  ),
                );
              },
            ),
            GoRoute(
              path: '/dashboard/tacTareas/ArqueoCaja',
              name: 'tacTareasArqueoCaja',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ?? 'Arqueo de Caja';
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  ArqueoCajaScreen(
                    idTarRuti: (extra['idTarRuti'] as int?) ?? 0,
                    idBitTarea: (extra['idBitTarea'] as int?) ?? 0,
                    nombreTarea: nombreTarea,
                  ),
                );
              },
            ),
            GoRoute(
              path: '/dashboard/tacTareas/CajaChica',
              name: 'tacTareasCajaChica',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ?? 'Caja Chica';
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  AperturaFlujo(
                    idTarRuti: TareasARequerimiento.cajaChica,
                    nombreFlujo: nombreTarea,
                    idBitTareaExistente: extra['idBitTarea'] as int?,
                    construir:
                        (idBitTarea) => CajaChicaScreen(
                          idBitTarea: idBitTarea,
                          nombreTarea: nombreTarea,
                        ),
                  ),
                );
              },
            ),
            // Cierre de Operaciones ya no tiene ruta propia (archivo SQL 63):
            // su pantalla es la revisión del día y vive en la ruta de
            // "Verificar Cierre de Operaciones", más abajo.
            // Tarea 295 - "Verificar traspaso Caja AXA contra movimiento de
            // caja" (idATR 12). NO usa AperturaFlujo, a diferencia de los
            // submodulos de la vista 87: esta tarea es automatica, la genera
            // el Job todos los dias, asi que la ocurrencia YA existe y su
            // idBitTarea llega desde la tarjeta de "Mis tareas rutinarias".
            // Abrir una a demanda duplicaria la del dia.
            GoRoute(
              path: '/dashboard/tacTareas/TraspasoCajaAxa',
              name: 'tacTareasTraspasoCajaAxa',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ??
                    'Verificar traspaso Caja AXA';
                final idBitTarea = extra['idBitTarea'] as int?;
                if (idBitTarea == null) {
                  // Sin ocurrencia no hay contra que registrar. Pasa si
                  // alguien entra por URL en vez de por la tarjeta.
                  return _pantallaConTitulo(
                    context,
                    'Bosque - $nombreTarea',
                    const Scaffold(
                      body: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Esta tarea se abre desde "Mis tareas rutinarias", '
                            'tocando la tarea del dia.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  TraspasoEntreSistemasScreen(
                    idBitTarea: idBitTarea,
                    nombreTarea: nombreTarea,
                    fecha: (extra['fecha'] as DateTime?) ?? DateTime.now(),
                  ),
                );
              },
            ),
            // Bitacoras de tareas rutinarias (archivo SQL 55): la fila de
            // tb_vista es 'tacTareas/Bitacora', bajo la 87, con los mismos
            // permisos que esa vista.
            GoRoute(
              path: '/dashboard/tacTareas/Bitacora',
              name: 'tacTareasBitacora',
              builder:
                  (context, state) => _pantallaConTitulo(
                    context,
                    'Bosque - Bitácora de Tareas',
                    const BitacoraTareasScreen(),
                  ),
            ),
            // Tarea 289 - "Verificar Traspaso de Efectivo Entre Sistemas"
            // (idATR 11, TesBase). Igual que Caja AXA: la genera el Job, asi
            // que la ocurrencia ya existe y llega desde la tarjeta.
            GoRoute(
              path: '/dashboard/tacTareas/TraspasoEfectivoTesBase',
              name: 'tacTareasTraspasoEfectivoTesBase',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ??
                    'Verificar traspaso de efectivo entre sistemas';
                final idBitTarea = extra['idBitTarea'] as int?;
                if (idBitTarea == null) {
                  return _pantallaConTitulo(
                    context,
                    'Bosque - $nombreTarea',
                    const Scaffold(
                      body: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Esta tarea se abre desde "Mis tareas rutinarias", '
                            'tocando la tarea del dia.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  TraspasoEfectivoTesBaseScreen(
                    idBitTarea: idBitTarea,
                    nombreTarea: nombreTarea,
                    fecha: (extra['fecha'] as DateTime?) ?? DateTime.now(),
                  ),
                );
              },
            ),
            // La revisión del día, y su única dirección. La contiene la tarea
            // 39 "Verificar Cierre de Operaciones" (idATR 5), que genera el
            // Job; por aquí entran también las de idATR 3 ("Verficar Arqueo de
            // Caja" y las ocurrencias viejas de Cierre de Operaciones), que
            // usan la misma pantalla —como el diálogo del sistema anterior— y
            // solo se diferencian en cómo cierran.
            GoRoute(
              path: '/dashboard/tacTareas/VerificarCierre',
              name: 'tacTareasVerificarCierre',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final nombreTarea =
                    (extra['nombreTarea'] as String?) ??
                    'Verificar Cierre de Operaciones';
                // 'cierre' cierra SU ocurrencia; el modo por defecto, el de la
                // 39, cierra las de todos ese día.
                final modo =
                    extra['modo'] == 'cierre'
                        ? ModoCierre.cierre
                        : ModoCierre.verificacion;
                final idBitTarea = extra['idBitTarea'] as int?;
                if (idBitTarea == null) {
                  // La genera el Job: sin ocurrencia no hay nada que cerrar.
                  return _pantallaConTitulo(
                    context,
                    'Bosque - $nombreTarea',
                    const Scaffold(
                      body: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Esta tarea se abre desde "Mis tareas rutinarias", '
                            'tocando la tarea del dia.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _pantallaConTitulo(
                  context,
                  'Bosque - $nombreTarea',
                  CierreOperacionesScreen(
                    idBitTarea: idBitTarea,
                    nombreTarea: nombreTarea,
                    modo: modo,
                    fecha: extra['fecha'] as DateTime?,
                  ),
                );
              },
            ),
          ],
        ),

        // En caso de que vengan sin el parámetro
        GoRoute(
          path: '/tven_ventas',
          redirect: (context, state) => '/dashboard/ventas',
        ),
        GoRoute(
          path: '/trch_choferEntrega',
          redirect:
              (context, state) => '/dashboard/trch_choferEntrega/Revision',
        ),
        GoRoute(
          path: '/trch_choferEntrega/Revision',
          redirect:
              (context, state) => '/dashboard/trch_choferEntrega/Revision',
        ),
        GoRoute(
          path: '/trch_choferEntrega/Resumen',
          redirect: (context, state) => '/dashboard/trch_choferEntrega/Resumen',
        ),
        // Pendientes de entrega
        GoRoute(
          path: '/trch_choferEntrega/Pendientes',
          redirect:
              (context, state) => '/dashboard/trch_choferEntrega/Pendientes',
        ),
        GoRoute(
          path: '/tbUsuario/Usuario',
          redirect: (context, state) => '/dashboard/tbUsuario/usuario',
        ),
        GoRoute(
          path: '/tgas_ControlCombustible/Registro',
          redirect:
              (context, state) => '/dashboard/tgas_ControlCombustible/Registro',
        ),
        GoRoute(
          path: '/tgas_ControlCombustible/View',
          redirect:
              (context, state) => '/dashboard/tgas_ControlCombustible/View',
        ),
        GoRoute(
          path: '/tgas_ControlCombustibleMaqMont/Registro',
          redirect:
              (context, state) =>
                  '/dashboard/tgas_ControlCombustibleMaqMont/Registro',
        ),
        GoRoute(
          path: '/tgas_ControlCombustibleMaqMont/View',
          redirect:
              (context, state) =>
                  '/dashboard/tgas_ControlCombustibleMaqMont/View',
        ),

        // Para el registro de garrafas
        GoRoute(
          path: '/tgas_RegistroGarrafa/Registro',
          redirect:
              (context, state) => '/dashboard/tgas_RegistroGarrafa/Registro',
        ),

        GoRoute(
          path: '/tdep_Deposito/Registro',
          redirect: (context, state) => '/dashboard/tdep_Deposito/Registro',
        ),
        GoRoute(
          path: '/tdep_Deposito/View',
          redirect: (context, state) => '/dashboard/tdep_Deposito/View',
        ),
        GoRoute(
          path: '/tdep_DepositoIde/Registro',
          redirect: (context, state) => '/dashboard/tdep_DepositoIde/Registro',
        ),
        GoRoute(
          path: '/tdep_DepositoIde/View',
          redirect: (context, state) => '/dashboard/tdep_DepositoIde/View',
        ),
        // Ruta para prestamo de vehiculos
        GoRoute(
          path: '/tpre_Solicitud/Solicitud',
          redirect: (context, state) => '/dashboard/tpre_Solicitud/Solicitud',
        ),
        //Para ver el prestamo de vehiculos
        GoRoute(
          path: '/tpre_Solicitud/VerSolicitud',
          redirect:
              (context, state) => '/dashboard/tpre_Solicitud/VerSolicitud',
        ),

        GoRoute(
          path: '/ted_EmpleadoDependiente/register',
          redirect:
              (context, state) => '/dashboard/ted_EmpleadoDependiente/register',
        ),
        // Ruta para la estructura organizacional y creacion de empresas
        GoRoute(
          path: '/trhEstructuraOrganizacional/estructuraOrganizacional',
          redirect:
              (context, state) =>
                  '/dashboard/trhEstructuraOrganizacional/estructuraOrganizacional',
        ),

        GoRoute(
          path: '/tb_facturasTigo',
          redirect: (context, state) => '/dashboard/tb_facturasTigo',
        ),
        GoRoute(
          path: '/tbEmpleado/registroEmpleado',
          redirect:
              (context, state) => '/dashboard/tbEmpleado/registroEmpleado',
        ),

        // Pagos al extranjero Registro Solicitud
        GoRoute(
          path: '/tpex_RegistroSolicitud/Registro',
          redirect:
              (context, state) => '/dashboard/tpex_RegistroSolicitud/Registro',
        ),

        // Pagos al extranjero Registro Ver
        GoRoute(
          path: '/tpex_RegistroVer/View',
          redirect: (context, state) => '/dashboard/tpex_RegistroVer/View',
        ),
        // Aprobación Gerencia
        GoRoute(
          path: '/tpex_Aprobacion/Gerencia',
          redirect: (context, state) => '/dashboard/tpex_Aprobacion/Gerencia',
        ),
        // Asientos Cobranzas
        GoRoute(
          path: '/tpex_Asientos/Cobranzas',
          redirect: (context, state) => '/dashboard/tpex_Asientos/Cobranzas',
        ),
        // Empleados Descuentos
        GoRoute(
          path: '/tdesc_EmpleadosDescuento/View',
          redirect:
              (context, state) => '/dashboard/tdesc_EmpleadosDescuento/View',
        ),
        // Permisos y Vacaciones
        GoRoute(
          path: '/trhPermiso/permiso',
          redirect: (context, state) => '/dashboard/trhPermiso/permiso',
        ),
        // Modulo Turno Sabados
        GoRoute(
          path: '/trs_Sabados/Main',
          redirect: (context, state) => '/dashboard/trs_Sabados/Main',
        ),
        // Dias No Laborables
        GoRoute(
          path: '/tbDiaNoLaborable/diaNoLaborable',
          redirect:
              (context, state) => '/dashboard/tbDiaNoLaborable/diaNoLaborable',
        ),
        // Lote de producción
        GoRoute(
          path: '/tprod_loteProduccion/loteProduccion',
          redirect:
              (context, state) =>
                  '/dashboard/tprod_loteProduccion/loteProduccion',
        ),
        // Registro de resmado
        GoRoute(
          path: '/tprod_loteProduccion/Resmado',
          redirect:
              (context, state) => '/dashboard/tprod_loteProduccion/Resmado',
        ),
        // Ver lote de producción
        GoRoute(
          path: '/tprod_loteProduccion/ViewLoteProduccion',
          redirect:
              (context, state) =>
                  '/dashboard/tprod_loteProduccion/ViewLoteProduccion',
        ),
        // Ver resmado
        GoRoute(
          path: '/tprod_loteProduccion/ViewResmado',
          redirect:
              (context, state) => '/dashboard/tprod_loteProduccion/ViewResmado',
        ),
        // Solicitud de corte
        GoRoute(
          path: '/tccrControlCorteResmado/solicitudCorte',
          redirect:
              (context, state) =>
                  '/dashboard/tccrControlCorteResmado/solicitudCorte',
        ),
        // ANTICIPOS EMPLEADOS
        GoRoute(
          path: '/tplAnticipo/anticipo',
          redirect: (context, state) => '/dashboard/tplAnticipo/anticipo',
        ),
        // MULTAS EMPLEADO
        GoRoute(
          path: '/tplMulta/multas',
          redirect: (context, state) => '/dashboard/tplMulta/multas',
        ),
        // BONOS MENSUALES
        GoRoute(
          path: '/tplBono/bono',
          redirect: (context, state) => '/dashboard/tplBono/bono',
        ),
        // PLANILLAS
        GoRoute(
          path: '/tplPlanilla/planilla',
          redirect: (context, state) => '/dashboard/tplPlanilla/planilla',
        ),
        // PRESTAMOS
        GoRoute(
          path: '/tplPrestamo/prestamo',
          redirect: (context, state) => '/dashboard/tplPrestamo/prestamo',
        ),
        // CARTAS CITE
        GoRoute(
          path: '/tcrDocumento/Documento',
          redirect: (context, state) => '/dashboard/tcrDocumento/Documento',
        ),
        // BIOMÉTRICO — el sidebar arma el destino como '/'+direccion (sin
        // /dashboard), igual que los demás módulos de esta lista.
        GoRoute(
          path: '/tbioBiometrico/biometrico',
          redirect: (context, state) => '/dashboard/tbioBiometrico/biometrico',
        ),
        // MODULO DE PRECIOS (tpr) - sin estas entradas el item del menu no
        // llega a ninguna parte: el sidebar navega a '/' + tb_vista.direccion,
        // sin el prefijo /dashboard.
        GoRoute(
          path: '/${AppConstants.rutaPreciosPropuestas}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosPropuestas}',
        ),
        GoRoute(
          path: '/${AppConstants.rutaPreciosFamilias}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosFamilias}',
        ),
        GoRoute(
          path: '/${AppConstants.rutaPreciosPrecios}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosPrecios}',
        ),
        GoRoute(
          path: '/${AppConstants.rutaPreciosListas}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosListas}',
        ),
        GoRoute(
          path: '/${AppConstants.rutaPreciosCatalogos}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosCatalogos}',
        ),
        GoRoute(
          path: '/${AppConstants.rutaPreciosParametros}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosParametros}',
        ),
        GoRoute(
          path: '/${AppConstants.rutaPreciosPorcentajes}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaPreciosPorcentajes}',
        ),
        // MODULO DE GARANTIAS DE COBRANZA (tcbr): el sidebar navega a
        // '/' + tb_vista.direccion, sin /dashboard.
        GoRoute(
          path: '/${AppConstants.rutaGarantias}',
          redirect:
              (context, state) => '/dashboard/${AppConstants.rutaGarantias}',
        ),
        // MODULO DE CHEQUES (tch): el sidebar navega a '/' + tb_vista.direccion,
        // sin /dashboard.
        GoRoute(
          path: '/${AppConstants.rutaCheques}',
          redirect:
              (context, state) => '/dashboard/${AppConstants.rutaCheques}',
        ),
        // BANCOS (tch_banco): igual que el de cheques.
        GoRoute(
          path: '/${AppConstants.rutaBancos}',
          redirect: (context, state) => '/dashboard/${AppConstants.rutaBancos}',
        ),
        // VERIFICAR CHEQUES (tch_verificacionDeposito): igual que el de cheques.
        GoRoute(
          path: '/${AppConstants.rutaVerificarCheques}',
          redirect:
              (context, state) =>
                  '/dashboard/${AppConstants.rutaVerificarCheques}',
        ),
        // TAREAS RUTINARIAS
        GoRoute(
          path: '/tacTareas/Tareas',
          redirect: (context, state) => '/dashboard/tacTareas/Tareas',
        ),
        GoRoute(
          path: '/tacTareas/Dependientes',
          redirect: (context, state) => '/dashboard/tacTareas/Dependientes',
        ),
        // Los cuatro submódulos a requerimiento (archivos SQL 40/41). Sus filas
        // de tb_vista cuelgan de la 87 y su `direccion` es exactamente estas
        // rutas, así que sin estos redirects el ítem del menú no llega a
        // ninguna parte.
        GoRoute(
          path: '/tacTareas/CajaFuerte',
          redirect: (context, state) => '/dashboard/tacTareas/CajaFuerte',
        ),
        GoRoute(
          path: '/tacTareas/Coches',
          redirect: (context, state) => '/dashboard/tacTareas/Coches',
        ),
        GoRoute(
          path: '/tacTareas/CajaChica',
          redirect: (context, state) => '/dashboard/tacTareas/CajaChica',
        ),
        // Bitácora de tareas (vista 164 bajo la 87, archivo SQL 55). Salió sin
        // esta entrada y el ítem del menú caía en «Página no encontrada».
        GoRoute(
          path: '/tacTareas/Bitacora',
          redirect: (context, state) => '/dashboard/tacTareas/Bitacora',
        ),

        GoRoute(
          path: '/change-password',
          name: 'change-password',
          builder: (context, state) {
            final user = state.extra as LoginEntity?;
            if (user == null) {
              // Si no hay usuario, redirigir al login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/login');
              });
              return const SizedBox.shrink();
            }
            return ChangePasswordScreen(user: user);
          },
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Página no encontrada')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48.0,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No se encontró la página: ${state.uri}',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Volver al dashboard'),
                  ),
                ],
              ),
            ),
          ),
      redirect: (BuildContext context, GoRouterState state) async {
        final storage = SecureStorage();
        // Timeout de seguridad: si SecureStorage cuelga, asumir token expirado
        // para que el usuario pueda ver el login y no se quede en pantalla blanca
        bool isTokenExpired;
        try {
          isTokenExpired = await storage.isTokenExpired().timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              console(
                '⚠️ Router redirect: timeout verificando token, asumiendo expirado',
              );
              return true;
            },
          );
        } catch (e) {
          console('⚠️ Router redirect: error verificando token: $e');
          isTokenExpired = true;
        }
        final isGoingToLogin = state.fullPath == '/login';

        // Si el token NO está expirado y está yendo al login, redirigir al dashboard
        if (!isTokenExpired && isGoingToLogin) {
          console('Token válido encontrado, redirigiendo al dashboard');
          return '/dashboard';
        }

        // Si el token está expirado y NO está en login, redirigir al login
        if (isTokenExpired && !isGoingToLogin && state.fullPath != '/') {
          console('Token expirado, redirigiendo al login');
          return '/login';
        }

        if (state.fullPath == '/') {
          return '/login';
        }
        return null;
      },
    );

    // Configurar el callback de error de autenticación para redireccionar.
    // IMPORTANTE: usamos el `ref` REAL del routerProvider (no un
    // ProviderContainer aislado, que no afectaba el estado vivo de la app),
    // para que la limpieza de sesión sea efectiva antes de navegar al login.
    DioClient.setAuthErrorCallback(() {
      try {
        ref.read(userProvider.notifier).clearUser();
        ref.read(buttonPermissionsProvider.notifier).clearPermisos();
        ref.invalidate(asyncUserProvider);
        // «Su Equipo» sabe quién es el jefe y a quiénes manda. Ese provider no
        // es autoDispose (la pestaña se arma con él y se consulta seguido), así
        // que sin esta línea el próximo login hereda el equipo del anterior.
        ref.invalidate(miEquipoProvider);
        ref.read(authStateProvider.notifier).state = false;
      } catch (e) {
        console('⚠️ Error limpiando sesión tras 401: $e');
      }
      _router?.go('/login');
    });
  }

  return _router!;
});

// Clase para notificar cambios de estado de autenticación al router
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<bool> stream) {
    notifyListeners();
    _subscription = stream.listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Mantenemos la clase AppRouter para compatibilidad con código existente
class AppRouter {
  // Este método ahora es solo por compatibilidad
  static GoRouter getRouter({String? initialToken}) {
    // Create the shell branch
    final shellNavigatorKey = GlobalKey<NavigatorState>();

    // Si ya tenemos un router global, usarlo
    if (_router != null) {
      return _router!;
    }

    final router = GoRouter(
      initialLocation: initialToken != null ? '/dashboard' : '/login',
      debugLogDiagnostics:
          true, // Habilitar logs de diagnóstico para depuración
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Shell route for dashboard
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return DashboardScreen(child: child);
          },
          routes: [
            // Dashboard home
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardHomeContent(),
            ),
            // Ventas module
            GoRoute(
              path: '/dashboard/ventas',
              name: 'ventas',
              builder: (context, state) => const VentasHomeScreen(),
            ),
            // Disponibilidad detallada
            GoRoute(
              path: '/dashboard/disponibilidad/:codArticulo',
              name: 'disponibilidad',
              redirect: (context, state) {
                // Si no hay extra, significa que se recargó la página
                // o se accedió directamente por URL
                if (state.extra == null) {
                  // Redireccionar a ventas porque necesitamos el objeto completo
                  return '/dashboard/ventas';
                }
                return null; // No redireccionar si tenemos el objeto
              },
            ),
            // Add more module routes here as needed
          ],
        ),

        // En caso de que vengan sin el parámetro
        GoRoute(
          path: '/tven_ventas',
          redirect: (context, state) => '/dashboard/ventas',
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Página no encontrada')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48.0,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No se encontró la página: ${state.uri}',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Volver al dashboard'),
                  ),
                ],
              ),
            ),
          ),
      redirect: (BuildContext context, GoRouterState state) async {
        // Verificar si el token está expirado
        final secureStorage = SecureStorage();
        final isTokenExpired = await secureStorage.isTokenExpired();

        // Si el token expiró, limpiar datos y redirigir al login
        if (isTokenExpired) {
          console('🔑 Token expirado detectado en AppRouter.getRouter');
          // Limpiar datos de sesión
          await secureStorage.clearSession();

          // Solo redirigir si no estamos ya en el login
          if (state.uri.toString() != '/login') {
            return '/login';
          }
        }

        // Usar Riverpod para verificar si hay un usuario logueado
        // Con un container propio para evitar dependencias
        final container = ProviderContainer();
        bool isLoggedIn;

        try {
          final user = container.read(userProvider);
          final token = await SecureStorage().getToken();
          isLoggedIn = (user != null || token != null) && !isTokenExpired;
        } finally {
          container.dispose();
        }

        final isOnLoginPage = state.uri.toString() == '/login';

        if (!isLoggedIn && !isOnLoginPage) {
          return '/login'; // Redirigir al login si no hay sesión
        } else if (isLoggedIn && isOnLoginPage) {
          return '/dashboard'; // Redirigir al dashboard si hay sesión
        }
        return null; // No redirigir si la ruta es correcta
      },
    );

    // Guardar referencia global
    _router = router;

    return router;
  }
}
