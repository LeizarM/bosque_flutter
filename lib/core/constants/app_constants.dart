import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Variables de compilación para web con fallback
  static const String _compiledBaseUrlProd = String.fromEnvironment(
    'BASE_URL_PROD',
    defaultValue: 'https://app.esppapel.com:8443',
  );

  static const String _compiledBaseUrlDev = String.fromEnvironment(
    'BASE_URL_DEV',
    defaultValue: 'http://192.168.3.107:9223',
  );

  // Selector inteligente de URL base
  static String get baseUrl {
    if (kIsWeb) {
      // Para web: usa variables de compilación
      return kReleaseMode ? _compiledBaseUrlProd : _compiledBaseUrlDev;
    } else {
      // Para móvil/desktop: usa .env con fallback a variables de compilación
      return kReleaseMode
          ? (dotenv.env['BASE_URL_PROD'] ?? _compiledBaseUrlProd)
          : (dotenv.env['BASE_URL_DEV'] ?? _compiledBaseUrlDev);
    }
  }

  static const String APP_VERSION = "1.0.1";

  static const String loginEndpoint = '/auth/login';
  static const String menuEndpoint = '/view/vistaDinamica';
  static const String registroVistaUsuario = '/auth/registroVistaUsuario';
  static const String registroLogin =
      '/auth/registroUsuario'; //registro login o usuario
  static const String listaEmpleados = '/auth/lstEmpleados';
  static const String verificarDuplicadoUsuario =
      '/auth/verificarDuplicadoUsuario';

  static const String cargarPermisosUsuario = '/auth/lstUsuarioPermisosTree';
  static const String actualizarPermisos = '/auth/actualizarPermisos';

  static const String articulosEndpoint = '/paginaXApp/articulosX';
  static const String articulosAlmacenEndpoint =
      '/paginaXApp/articulosXAlmacen';
  // Ciudades del catálogo de Ventas. El backend decide cuáles ve cada usuario
  // (admin: todas; con excepciones: las asignadas; resto: la del login).
  static const String ventasCiudadesPermitidas =
      '/paginaXApp/ciudadesPermitidas';
  // Gestión de excepciones por usuario (solo ROLE_ADM).
  static const String ventasUsuarioCiudadCiudadesVenta =
      '/paginaXApp/usuarioCiudad/ciudadesVenta';
  static const String ventasUsuarioCiudadAsignaciones =
      '/paginaXApp/usuarioCiudad/asignaciones';
  static const String ventasUsuarioCiudadRegistrar =
      '/paginaXApp/usuarioCiudad/registrar';
  static const String ventasUsuarioCiudadEliminar =
      '/paginaXApp/usuarioCiudad/eliminar';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: ENTREGAS Y RUTAS DE CHOFERES
  // ═══════════════════════════════════════════════════════════════════════════════

  static const String entregasEndpoint = '/entregas/chofer-entrega';
  static const String marcarEntregaCompletada =
      '/entregas/registro-entrega-chofer';
  static const String inicioEntregaYFinEndpoint =
      '/entregas/registro-inicio-fin-entrega';
  static const String rutaChoferEndpoint = '/entregas/entregas-fecha';
  static const String choferesEndPoint = '/entregas/choferes';
  static const String entregasRutasChoferes = '/entregas/extracto';
  static const String pendientesDeEntrega = '/entregas/pendientes-entrega';

  static const String usuariosEndPoint = '/auth/lstUsers';
  static const String changePasswordEndPoint = '/auth/changePasswordDefault';
  static const String registrarCombustibleEndPoint =
      '/gasolina/registrar-gasolina';
  static const String listarCoches = '/gasolina/lst-coches';
  static const String listarKilometrajeCoches = '/gasolina/lst-kilometraje';
  static const String listar = '/gasolina/lst-combustibles';
  static const String listarObtenerConsumo = '/gasolina/obtenerConsumo';

  //Endpoints para la gestion de bidones
  static const String registrarControlCombustibleMaqMont =
      '/gasolinaMaquina/registrarMaquina';
  static const String listarAlmacenes = '/gasolinaMaquina/lst-almacenes';
  static const String listarMaquinaMontacarga =
      '/gasolinaMaquina/lst-maqmontacarga';
  static const String listarBidones = '/gasolinaMaquina/lstMovBidones';
  static const String listarBidonesXSucursales =
      '/gasolinaMaquina/lstSaldosBidones';
  static const String listarUltimosMovBidones =
      '/gasolinaMaquina/lstUltimoMovBidones';

  //***********Endpoints para la gestion de bidones segunda parte
  static const String lstContenedores = '/gasolinaMaquina/lstContenedores';
  static const String registerMovimiento =
      '/gasolinaMaquina/registrarMovimiento';
  static const String registerCompraGarrafa =
      '/gasolinaMaquina/registrarGarrafa';
  static const String listarSucural = '/gasolinaMaquina/lstSucursal';
  static const String lstTipoContenedor = '/gasolinaMaquina/lstTipoContenedor';
  static const String lstMovimientos = '/gasolinaMaquina/lstMovimientos';
  static const String lstSaldosActuales = '/gasolinaMaquina/lstSaldoActuales';
  static const String listarBidonesPendientes =
      '/gasolinaMaquina/lstBidonesPendientes';
  static const String listarDetalleBidon = '/gasolinaMaquina/lstDetalleBidon';

  // Endpoints para la gestión de depósitos de cheques
  static const String deplstEmpresas = '/deposito-cheque/lst-empresas';
  static const String deplstSocioNegocio =
      '/deposito-cheque/lst-socios-negocio';
  static const String deplstBancos = '/deposito-cheque/lst-banco';
  static const String deplstNotaRemision = '/deposito-cheque/lst-notaRemision';
  static const String depRegister = '/deposito-cheque/registro';
  static const String depRegisterNotaRemision =
      '/deposito-cheque/registrar-nota-remision';
  static const String depListarDepositos = '/deposito-cheque/listar';
  static const String depListDepositosIde =
      '/deposito-cheque/listar-dep-identificar';
  static const String depGenPdfDeposito = '/deposito-cheque/pdf/';
  static const String depObtImagen = '/deposito-cheque/descargar/';
  static const String depActualizarNotaRemision =
      '/deposito-cheque/registrar-nroTransaccion';
  static const String depRechazarNotaRemision =
      '/deposito-cheque/rechazar-deposito';

  // Endpoints para el prestamos de vehículos
  static const String preRegister = '/prestamo-coches/registroSolicitud';
  static const String preTipoSolicitudes = '/prestamo-coches/tipoSolicitudes';
  static const String preCoches = '/prestamo-coches/coches';
  static const String preSolicitudesXEmp = '/prestamo-coches/solicitudes';
  static const String preListarSolicitudesPrestamos =
      '/prestamo-coches/solicitudesPrestamo';
  static const String preEstados = '/prestamo-coches/estados';
  static const String preRegistrarPrestamo =
      '/prestamo-coches/registroPrestamo';
  static const String preActualizarSolicitud =
      '/prestamo-coches/actualizarSolicitud';

  // Endpoints para la gestion de empleados y dependientes
  static const String empListarEmpleadosDependientes =
      '/fichaTrabajador/obtenerDep';
  static const String empLstDependientes = '/fichaTrabajador/dependientes';
  static const String depLstParentesco = '/fichaTrabajador/tiposParentesco';
  static const String depLstActivo = '/fichaTrabajador/tipoActivo';
  static const String perLstCiExpedido = '/rrhh/tiposCiExp';
  static const String perLstEstadoCivil = '/rrhh/tiposEstCivil';
  static const String perLstPais = '/rrhh/paises';
  static const String perLstZona = '/rrhh/zonas';
  static const String perLstGenero = '/rrhh/tiposSexo';
  static const String perLstTelefono = '/rrhh/telfPersona';
  static const String perObtenerPersona = '/rrhh/datosPersonales';
  static const String depEliminarDependiente = '/fichaTrabajador/dependiente';
  static const String depEditarDependiente =
      '/fichaTrabajador/registrarDependiente';
  static const String perLstCiudad = '/rrhh/ciudadxPais';
  static const String perRegistrarPersona = '/rrhh/registroPersona';
  static const String perObtenerTelefono = '/rrhh/telfPersona';
  static const String perObtenerTipoTelefono = '/rrhh/tipoTelefono';
  static const String perRegistrarTelefono = '/rrhh/registroTelefono';
  static const String perEliminarTelefono = '/rrhh/telefono';
  static const String perObtenerEmmail = '/rrhh/emailPersona';
  static const String perRegistrarEmail = '/rrhh/registroEmail';
  static const String perEliminarEmail = '/rrhh/correo';
  static const String perObtenerFormacion = '/rrhh/formacionEmpleado';
  static const String perRegistrarFormacion = '/rrhh/registrarFormacion';
  static const String perEliminarFormacion = '/rrhh/formacion';
  static const String perObtenerTipoFormacion = '/rrhh/tiposFormacion';
  static const String perObtenerTipoDuracionFormacion =
      '/rrhh/tiposDuracionFor';
  static const String perObtenerExperienciaLaboral = '/rrhh/expLabEmpleado';
  static const String perRegistrarExperienciaLaboral =
      '/rrhh/registrarExpLaboral';
  static const String perEliminarExperienciaLaboral = '/rrhh/expLaboral';
  static const String empObtenerGaranteReferencia =
      '/fichaTrabajador/garanteReferencia';
  static const String empRegistrarGaranteReferencia =
      '/fichaTrabajador/registrarGaranteReferencia';
  static const String empEliminarGaranteReferencia = '/fichaTrabajador/garante';
  static const String empObtenerTipoGaranteReferencia =
      '/fichaTrabajador/tiposGarRef';
  static const String perObtenerRelacionLaboral =
      '/rrhh/obtenerRelacionLaboral';
  static const String empSubirImagen = '/fichaTrabajador/upload';
  static const String empObtenerDatosEmpleado =
      '/fichaTrabajador/obtenerDatosEmp';
  static const String perObtenerLstPersonas = '/rrhh/obtenerListaPersonas';
  static const String perRegistrarZona = '/rrhh/registroZona';
  static const String perRegistrarCiudad = '/rrhh/registroCiudad';
  static const String perRegistrarPais = '/rrhh/registroPais';
  static const String empSubirDocs = '/fichaTrabajador/uploads/documentos';
  static const String admLstDocs = '/fichaTrabajador/uploads/pendientes/all';
  static const String admAprobarDcos =
      '/fichaTrabajador/uploads/pendientes/aprobar';
  static const String admRechazarDocs =
      '/fichaTrabajador/uploads/pendientes/rechazar';
  static const String empExportarPdf = '/fichaTrabajador/pdf';
  static const String empObtenerCumpleanios = '/fichaTrabajador/cumples';
  static const String ubBloquearUsuario = '/bloqueo/advertencia';
  static const String ubDesbloquearUsuario = '/bloqueo/desbloqueo';
  static const String ubVerUsuarioBloqueado = '/bloqueo/usuarioBloqueado';
  static const String depExportarPdfDependientes = '/rrhh/pdfDependientes';
  static const String depExportarPdfDependientesHijos =
      '/rrhh/pdfDependientesHijos';
  static const String perObtenerPersonaXCarnet = '/rrhh/obtenerPersonaXCarnet';

  static const String obtenerDatosEmpleado =
      '/fichaTrabajador/obtenerDatosEmpleado';
  static const String perObtenerCoprorativoEmpleado =
      '/rrhh/obtenerCorporativoXEmpleado';
  static const String verInfoEmpXJerarquia = '/fichaTrabajador/datosXJerarquia';

  // = = = = = = = = = = = = = = = = = = = = = = = = = Endpoints para la gestion de RRHH = = = = = = = = = = = = = = = = = =

  //  **** Para la estructura organizacional *********/
  static const String lstEmpresa = '/rrhh/lst-empresas';
  static const String lstCargos = '/rrhh/lst-cargos';
  static const String lstCargosXEmpresaNew = '/rrhh/lstOrganigramaNew';
  static const String lstNivelesJerarquicos = '/rrhh/lstNivelesJerarquicos';
  static const String registrarCargo = '/rrhh/registroCargo';
  static const String lstSucursales = '/rrhh/sucXEmpresa';
  static const String lstSucursalesXCargo = '/rrhh/sucXCargo';
  static const String registrarCargoSucursal = '/rrhh/registroCargoSucursal';
  static const String eliminarCargoSucursal = '/rrhh/eliminarCargoSuc';
  static const String obtenerEmpleadosXCargo = '/rrhh/lstEmpleadosXCargo';

  //endpoints para la gestion de facturas TIGO
  static const String tigoCargarFacturas = '/tigo/SubirExcel';
  static const String tigoVerFactura = '/tigo/obtenerDetalleDeudaTigo';
  static const String tigoCargarSocios = '/tigo/registroSocioTigo';
  static const String tigoVerSocios = '/tigo/obtenerSociosTigo';
  static const String tigoTotalXCuenta = '/tigo/obtenerTotalCobradoXCuenta';
  static const String tigoResumenCuentas = '/tigo/obtenerResumenCuentas';
  static const String tigoResumenDetallado = '/tigo/obtenerResumenDetallado';
  static const String tigoInsertarAnticipo = '/tigo/generarAnticiposTigo';
  static const String tigoExportarPdf = '/tigo/pdfTigo';
  static const String tigoObtenerGrupos = '/tigo/obtenerListaGruposTigo';
  static const String tigoEliminarGrupo = '/tigo/grupo';
  static const String tigoEjecutarTigo = '/tigo/ejecutarTigo';
  static const String tigoObtenerEjecutado = '/tigo/obtenerTigoEjecutado';
  static const String tigoObtenerNrosSinAsignar = '/tigo/obtenerNroSinAsignar';
  static const String tigoObtenerArbolDetallado = '/tigo/obtenerArboldetallado';
  static const String tigoRptCambiosTigo = '/tigo/RptCambiosTigo';
  static const String tigoActualizarEmpresaLote = '/tigo/actualizarEmpresaLote';
  // NUEVOS ENDPOINTS PARA TIGO
  static const String tigoRegistrarCambioLinea = '/tigo/registrarCambioLinea';
  static const String tigoEliminarCambioLinea = '/tigo/eliminarCambioLinea';
  static const String tigoAplicarCambiosLinea = '/tigo/aplicarCambiosLinea';
  static const String tigoListarNumerosAsignados =
      '/tigo/listarNumerosAsignados';
  static const String tigoListarCambiosLinea = '/tigo/listarCambiosLinea';
  static const String tigoListarDestinosLinea = '/tigo/listarDestinosLinea';
  static const String tigoReasignarNumeroSinAsignar =
      '/tigo/reasignarNumeroSinAsignar';
  static const String tigoListarPerdidasLinea = '/tigo/listarPerdidas';
  static const String tigoRegistrarPerdidaLinea = '/tigo/registrarPerdidaChip';
  static const String tigoEliminarPerdidaLinea =
      '/tigo/eliminarRegistroPerdida';
  static const String tigoListarPeriodos = '/tigo/listarPeriodos';
  static const String tigoObtenerTipoRenovacion = '/tigo/tipoRenovacion';
  static const String tigoRptPerdidaLineas = '/tigo/RptPerdidaLineas';
  static const String tigoListarPeriodosCambio = '/tigo/listarPeriodosCambio';
  static const String tigoRptCambiosLineaTigo = '/tigo/RptCambiosLineaTigo';
  static const String tigoEjecutarPeriodoTigo = '/tigo/ejecutarPeriodoTigo';
  static const String tigoRptCorporativosPersonal =
      '/tigo/RptCorporativosPersonal';
  static const String tigoRptComparacionEmpresas =
      '/tigo/RptComparacionEmpresas';
  static const String tigoListarPeriodoFactura = '/tigo/listarPeriodoFactura';
  static const String tigoListarEmpresas = '/tigo/listarEmpresas';
  //ENDPOINT PARA LA GESTION DE EMPLEADOS - RRHH
  static const String rrhhObtenerLstEmpleados = '/rrhh/obtenerLstEmpleados';
  static const String rrhhRegistroEmpleado = '/rrhh/registroEmpleado';
  static const String rrhhObtenerLstPersonas =
      '/rrhh/obtenerLstPersonaNoEmpleado';
  static const String rrhhObtenerDatoPersona = '/rrhh/datosPersonales';
  static const String rrhhRegistroEducacion = '/rrhh/registroEducacion';
  static const String rrhhObtenerEducacion = '/rrhh/obtenerEducacion';
  static const String rrhhEliminarEducacion = '/rrhh/eliminarEducacion';
  static const String rrhhObtenerTipoEducacion = '/rrhh/tiposEducacion';
  static const String rrhhObtenerSucXEmpresa = '/rrhh/sucursalXEmpresa';
  static const String rrhhObtenerCargoXSucursal = '/rrhh/cargoXSuc';
  static const String empresaRegistroEmpresa = '/empresa/registroEmpresa';
  static const String empresaEliminarEmpresa = '/empresa/eliminarEmpresa';
  static const String rrhhRegistroSucursal = '/rrhh/registroSucursal';
  static const String rrhhEliminarSucursal = '/rrhh/eliminarSucursal';
  static const String rrhhObtenerCargosXEmpresa = '/rrhh/cargoXSucursal';
  static const String rrhhRegistrarRelacionLaboral = '/rrhh/registroRelEmp';
  static const String bncGetBancos = '/banco/bancosX';
  static const String bncGetBancosPlanilla = '/banco/bancosPlanilla';
  // Escrituras de bancos (vista 43). 201, data = codBanco. Las lecturas de
  // arriba devuelven una lista pelada y su forma no cambia.
  static const String bncRegistrar = '/banco/registrar';
  static const String bncEliminar = '/banco/eliminar';
  static const String rrhhGetCuentaBancoXEmpleado =
      '/rrhh/obtenerNroCuentaBanco';
  static const String rrhhRegistrarCuentaBancaria = '/rrhh/registroCuentaBanco';
  static const String rrhhEliminarCuentaBancaria =
      '/rrhh/eliminarCuentaBancaria';
  static const String rrhhTipoRealacionLaboral = '/rrhh/tipoRelacionLaboral';
  static const String pdfRptNominaEmpleados = '/rrhh/pdfNominaEmpleados';
  static const String pdfRptPermVacTotal = '/rrhh/pdfRptPermVacTotal';
  static const String excelRptPermVacTotal = '/rrhh/excelRptPermVacTotal';
  static const String rrhhRegistrarEmpleadoCargo =
      '/rrhh/registroEmpleadoCargo';
  static const String rrhhObtenerUltimoCodEmpleado = '/rrhh/ultimoCodEmpleado';
  static const String rrhhEliminarRelacionLaboral =
      '/rrhh/eliminarRelacionLaboral';
  static const String rrhhDetalleEmpleado = '/rrhh/detalleEmpleado';
  static const String rrhhObtenerCargoActual = '/rrhh/ultimoCargoEmpleado';
  static const String rrhhObtenerHistorialCargosEmpleado =
      '/rrhh/obtenerCargosEmpleado';
  static const String rrhhObtenerHistorialRelacionLaboral =
      '/rrhh/fechasBeneficio';
  static const String rrhhEliminarEmpleadoCargo = '/rrhh/eliminarCargoEmpleado';
  static const String rrhhObtenerUltimaRelacionLaboral =
      '/rrhh/obtenerUltimaRelacionLaboral';
  static const String licenciasConducir = '/rrhh/licenciaPersona';
  static const String registrarLicencia = '/rrhh/registrarLicencia';
  static const String eliminarLicencia = '/rrhh/eliminarLicenciaConducir';
  static const String tiposLicencia = '/rrhh/tipoLicencia';
  static const String eliminarFoto = '/rrhh/eliminarFoto';
  static const String cargoXempresa = '/rrhh/obtenerCargosXEmpresa';
  static const String obtenerSeguro = '/rrhh/obtenerSeguros';
  static const String obtenerAfiliacionSeguro = '/rrhh/obtenerAfiliacionSeguro';
  static const String registrarAfiliacionSeguro =
      '/rrhh/registroAfiliacionSeguro';
  static const String eliminarAfiliacionSeguro =
      '/rrhh/eliminarAfiliacionSeguro';
  static const String registrarAseguradora = '/rrhh/registroAseguradora';
  static const String eliminarAseguradora = '/rrhh/eliminarAseguradora';
  static const String obtenerTipoSeguro = '/rrhh/tipoSeguro';
  static const String obtenerHaberBasico = '/rrhh/obtenerHaberBasico';
  //ENDPOINTS AREA
  static const String obtenerArea = '/rrhh/obtenerArea';
  static const String registroArea = '/rrhh/registrarArea';
  static const String docsVencidos = '/rrhh/docsVencidos';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO DE PAGOS AL EXTRANJERO
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String guardarSolicitudCompleta =
      '/pagos-extranjeros/guardar-solicitud-completa';
  static const String lstProveedoresXEmpresa =
      '/pagos-extranjeros/obtener-proveedores-empresa';
  static const String lstFacProvYOrdCompra =
      '/pagos-extranjeros/obtener-docnum-empresa';
  static const String lstDocumentosProyecto =
      '/pagos-extranjeros/obtener-documentos-proyecto';

  static const String lstSolPagosRegistrados =
      '/pagos-extranjeros/reporte-solicitudes-fechas';

  // ── TPEX: escrituras ACID ──────────────────────────────────────────────────
  static const String tpexAprobarSolicitud =
      '/pagos-extranjeros/aprobar-solicitud';
  // Aprobación granular: por cuota y por proveedor
  static const String tpexAprobarCuota = '/pagos-extranjeros/aprobar-cuota';
  static const String tpexRevertirCuota =
      '/pagos-extranjeros/revertir-aprobacion-cuota';
  static const String tpexAprobarProveedor =
      '/pagos-extranjeros/aprobar-proveedor';
  static const String tpexRechazarProveedor =
      '/pagos-extranjeros/rechazar-proveedor';
  static const String tpexGuardarCotizacion =
      '/pagos-extranjeros/guardar-cotizacion-completa';
  static const String tpexAceptarCotizacion =
      '/pagos-extranjeros/aceptar-cotizacion';
  static const String tpexGuardarTransaccion =
      '/pagos-extranjeros/guardar-transaccion-completa';
  static const String tpexCambiarEstadoTransaccion =
      '/pagos-extranjeros/cambiar-estado-transaccion';
  static const String tpexConfirmarPago = '/pagos-extranjeros/confirmar-pago';
  static const String tpexSubirVoucher = '/pagos-extranjeros/transacciones';

  // ── TPEX: lecturas ─────────────────────────────────────────────────────────
  static const String tpexObtenerSolicitudes =
      '/pagos-extranjeros/obtener-solicitudes';
  static const String tpexObtenerSolicitudProveedor =
      '/pagos-extranjeros/obtener-solicitud-proveedor';
  static const String tpexObtenerDetalleSolicitud =
      '/pagos-extranjeros/obtener-detalle-solicitud';
  static const String tpexObtenerCotizaciones =
      '/pagos-extranjeros/obtener-cotizaciones-solicitud';
  static const String tpexObtenerCargosCotizacion =
      '/pagos-extranjeros/obtener-cargos-cotizacion';
  static const String tpexObtenerTransaccionesSolicitud =
      '/pagos-extranjeros/obtener-transacciones-solicitud';
  static const String tpexObtenerTransaccion =
      '/pagos-extranjeros/obtener-transaccion';
  static const String tpexReporteTransaccionesFechas =
      '/pagos-extranjeros/reporte-transacciones-fechas';
  static const String tpexObtenerCargosTransaccion =
      '/pagos-extranjeros/obtener-cargos-transaccion';
  static const String tpexObtenerLogSolicitud =
      '/pagos-extranjeros/obtener-log-solicitud';
  static const String tpexObtenerLogTransaccion =
      '/pagos-extranjeros/obtener-log-transaccion';
  static const String tpexObtenerTimelineSolicitud =
      '/pagos-extranjeros/obtener-timeline-solicitud';

  // ── TPEX: catálogos ────────────────────────────────────────────────────────
  static const String tpexObtenerCanales =
      '/pagos-extranjeros/obtener-canales-pago';
  static const String tpexRegistrarCanal =
      '/pagos-extranjeros/registrar-canal-pago';
  static const String tpexEliminarCanal =
      '/pagos-extranjeros/eliminar-canal-pago';
  static const String tpexObtenerMonedas = '/pagos-extranjeros/obtener-monedas';
  static const String tpexRegistrarMoneda =
      '/pagos-extranjeros/registrar-moneda';
  static const String tpexEliminarMoneda = '/pagos-extranjeros/eliminar-moneda';
  static const String tpexObtenerTipoCambioBanco =
      '/pagos-extranjeros/obtener-tipos-cambio-banco';
  static const String tpexObtenerTCVigenteRef =
      '/pagos-extranjeros/obtener-tc-vigente-ref'; // ACCION='V' — último BCB
  static const String tpexRegistrarTipoCambio =
      '/pagos-extranjeros/registrar-tipo-cambio';
  static const String tpexEliminarTipoCambio =
      '/pagos-extranjeros/eliminar-tipo-cambio';
  static const String tpexObtenerTiposCargo =
      '/pagos-extranjeros/obtener-tipos-cargo';
  static const String tpexRegistrarTipoCargo =
      '/pagos-extranjeros/registrar-tipo-cargo';
  static const String tpexEliminarTipoCargo =
      '/pagos-extranjeros/eliminar-tipo-cargo';
  static const String tpexObtenerTiposTransaccion =
      '/pagos-extranjeros/obtener-tipos-transaccion';
  static const String tpexRegistrarTipoTransaccion =
      '/pagos-extranjeros/registrar-tipo-transaccion';
  static const String tpexEliminarTipoTransaccion =
      '/pagos-extranjeros/eliminar-tipo-transaccion';
  static const String tpexObtenerConfigBanco =
      '/pagos-extranjeros/obtener-config-comisiones-banco';
  static const String tpexRegistrarConfig =
      '/pagos-extranjeros/registrar-config-comisiones';
  static const String tpexEliminarConfig =
      '/pagos-extranjeros/eliminar-config-comisiones';

  // ── TPEX: asientos contables ───────────────────────────────────────────────
  static const String tpexCorregirComprobante =
      '/pagos-extranjeros/corregir-comprobante';
  static const String tpexRegistrarAsiento =
      '/pagos-extranjeros/registrar-asiento';
  static const String tpexEliminarAsiento =
      '/pagos-extranjeros/eliminar-asiento';
  static const String tpexObtenerAsientosTransaccion =
      '/pagos-extranjeros/obtener-asientos-transaccion';
  static const String tpexValidarCuadreAsientos =
      '/pagos-extranjeros/validar-cuadre-asientos';

  // ── TPEX: participantes (split de transacción) ─────────────────────────────
  static const String tpexRegistrarParticipante =
      '/pagos-extranjeros/registrar-participante';
  static const String tpexEliminarParticipante =
      '/pagos-extranjeros/eliminar-participante';
  static const String tpexObtenerParticipantesTransaccion =
      '/pagos-extranjeros/obtener-participantes-transaccion';
  static const String tpexValidarCuadreParticipantes =
      '/pagos-extranjeros/validar-cuadre-participantes';

  // ── TDESC: Descuentos empleados ────────────────────────────────────────────────────────

  static const String descObtenerDescuentosEmpleado = '/rrhh/prestamos-multas';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: LOTES DE PRODUCCION
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String obtenerLotesProduccion =
      '/loteProduccion/newLoteProduccion';
  static const String obtenerArticulos = '/loteProduccion/articulos';
  static const String registrarLoteProduccion =
      '/loteProduccion/registroLoteProduccion';
  static const String registrarMaterialIngreso =
      '/loteProduccion/registroIngreso';
  static const String registrarMaterialSalida =
      '/loteProduccion/registroSalida';
  static const String registrarMerma = '/loteProduccion/registroMerma';
  static const String obtenerMaquinas = '/loteProduccion/maquina';
  static const String obtenerEmpresas = '/loteProduccion/lst-empresas';
  static const String obtenerDocNumOrdFabXEmpresa =
      '/loteProduccion/lstDocNumOrdFabXEmpresa';

  // ── Ver lote de produccion ─────────────────────────────────────────────────
  static const String listaLotesProduccion = '/loteProduccion/listaLotes';
  static const String obtenerMaterialIngresoXLote =
      '/loteProduccion/materialIngreso';
  static const String obtenerMaterialSalidaXLote =
      '/loteProduccion/materialSalida';
  static const String obtenerMermaXLote = '/loteProduccion/merma';

  // ── Reportes de produccion ─────────────────────────────────────────────────
  static const String reporteLotePdf = '/loteProduccion/reporte-lote-pdf';
  static const String reporteResumenProduccionPdf =
      '/loteProduccion/reporte-resumen-pdf';
  static const String reporteResmadoPdf = '/loteProduccion/reporte-resmado-pdf';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: REGISTRO DE RESMADO
  // ═══════════════════════════════════════════════════════════════════════════════

  static const String obtenerArticulosRes = '/resmado/articulos';
  static const String obtenerGrupoProduccion = '/resmado/grupoProduccion';
  static const String registrarResmado = '/resmado/registroResmado';
  static const String registrarDetalleResmado = '/resmado/registroDetResmado';

  // ── Ver resmado ────────────────────────────────────────────────────────────
  static const String listaResmados = '/resmado/listaResmados';
  static const String obtenerDetalleResmado = '/resmado/detalleResmado';
  static const String actualizarOrdenFabricacionResmado =
      '/resmado/actualizarOrdenFabricacion';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: SOLICITUD DE CORTE
  // ═══════════════════════════════════════════════════════════════════════════════

  static const String listadoSolicitudesCorte = '/solicitud-corte/listado';
  static const String detalleSolicitudCorte = '/solicitud-corte/detalle';
  static const String itemsSapCorte = '/solicitud-corte/items-sap';
  static const String itemsSapCorteTotal = '/solicitud-corte/items-sap-total';
  static const String registrarSolicitudCorte = '/solicitud-corte/registrar';
  static const String cancelarSolicitudCorte = '/solicitud-corte/cancelar';
  static const String reporteSolicitudCortePdf =
      '/solicitud-corte/reporte-solicitud-pdf';
  static const String reporteResumenCortePdf =
      '/solicitud-corte/reporte-resumen-pdf';

  /// Consolidado de corte por maquina, que vive en la pantalla de lotes.
  static const String reporteConsolidadoCortePdf =
      '/loteProduccion/reporte-corte-pdf';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: PERMISOS / VACACION
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String vacDiasDisponibles = '/vacacion/diasDisponibles';
  static const String obtenerHorario = '/vacacion/obtener-horario';
  //-----------------
  // ENDPOINTS PARA SOLOCITUD DE PERMISO/VACACION DE CADA EMPLEADO
  //-----------------
  static const String solicitarVacacion = '/vacacion/solicitar';
  static const String aprobarVacacion = '/vacacion/aprobar';
  static const String rechazarVacacion = '/vacacion/rechazar';
  static const String anularVacacion = '/vacacion/anular';
  static const String pendientesVacacion = '/vacacion/pendientes';
  static const String solicitudesIndividuales =
      '/vacacion/solicitudesIndividuales';
  static const String tipoPermisoSolicitudVacacion = '/vacacion/tipoPermiso';
  static const String rptPermisoVacacion = '/vacacion/RptPermisoVacacion';
  static const String feriados = '/vacacion/feriados';
  static const String previsualizarSaldo = '/vacacion/previsualizarSaldo';
  static const String proximosDashboard = '/vacacion/proximosPermisos';

  //====================
  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: ANTICIPOS
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String antListarAnticipoSAP = '/anticipo/listarAnticiposSAP';
  static const String antListarAnticiposBosque = '/anticipo/obtenerAnticipos';
  static const String antListarAnticipoDetallado =
      '/anticipo/obtenerAnticipoDetalle';
  static const String antAnticiposUnificados = '/anticipo/listAnticipos';
  static const String antTipoAsignacion = '/anticipo/tipoAsigAnticipo';
  static const String antRegistrarAnticipo = '/anticipo/registrarAnticipo';
  static const String antAnticipoNoAsignado = '/anticipo/anticipoNoAsignado';
  static const String antPrevisualizarAsignacion =
      '/anticipo/previsualizarAsignacion';
  static const String antAnularAnticipo = '/anticipo/anularAnticipo';
  static const String antEditarAsignacion = '/anticipo/editarAsignacion';
  static const String antEstadoAnticipo = '/anticipo/estadoAnticipo';
  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: PRESTAMOS (PERSONAL)
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String prestamoListarSAP = '/prestamos/listarPrestamosSAP';
  static const String prestamoListarVigentes = '/prestamos/listarVigentes';
  static const String prestamoListarVigentesPorEmpleado =
      '/prestamos/listarVigentesPorEmpleado';
  static const String prestamoTotalPrestamos = '/prestamos/totalPrestamos';
  static const String prestamoTotalPrestamosSAP =
      '/prestamos/totalPrestamosSAP';
  static const String prestamoAsignarPagos = '/prestamos/asignarPagos';
  static const String prestamoAsignarMasivo =
      '/prestamos/asignarPrestamosMasivo';
  static const String prestamoAsignarPagosMasivo =
      '/prestamos/asignar-pagos-masivo';
  static const String prestamoRevertirPagoMasivo =
      '/prestamos/revertirPagoMasivo';
  static const String prestamoEditarMasivo = '/prestamos/editarPrestamoMasivo';
  static const String prestamoActualizarDetalle =
      '/prestamos/actualizarDetalle';
  static const String prestamoAdelantarCuota = '/prestamos/adelantarCuota';
  static const String prestamoAnular = '/prestamos/anularPrestamo';
  static const String prestamoListarDetalles = '/prestamos/listarDetalles';
  static const String prestamoListarEmpleadosAsignados =
      '/prestamos/listarEmpleadosAsignados';
  static const String prestamoEstados = '/prestamos/estados';
  static const String prestamoTiposPago = '/prestamos/tiposPago';
  static const String prestamoPrevisualizarCuotas =
      '/prestamos/previsualizarCuotas';
  static const String prestamoReporteCuotas = '/prestamos/reporteCuotas';
  static const String prestamoReportePersonal = '/prestamos/reportePersonal';
  static const String prestamoReporteMayorGlobalResumido =
      '/prestamos/reporteMayorGlobalResumido';
  static const String prestamoReporteGlobalDetallado =
      '/prestamos/reporteGlobalDetallado';
  static const String prestamoReporteCortoLargoPlazo =
      '/prestamos/reporteCortoLargoPlazo';
  static const String prestamoReporteMayorGeneral =
      '/prestamos/reporteMayorGeneral';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: MULTAS
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String mulListasMultas = '/multas/listarMultas';
  static const String mulGenerarMultas = '/multas/generarMultas';
  static const String mulEditarMulta = '/multas/editarMulta';
  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: BONOS
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String bonoListarBono = '/bono/listarBono';
  static const String bonoListarBonoEmpleado = '/bono/listarBonoEmpleado';
  static const String bonoAbmBono = '/bono/abmBono';
  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: PLANILLAS
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String planillaListarPlanilla = '/planilla/listarPlanilla';
  static const String planillaListarDetalle = '/planilla/listarPlanillaDetalle';
  static const String planillaGenerar = '/planilla/generarPlanilla';
  static const String planillaEjecutar = '/planilla/ejecutarPlanilla';
  static const String planillaPagosBancarios = '/planilla/pagosBancarios';
  static const String planillaPdfEstimadoPagoBanco =
      '/planilla/pdfEstimadoPagoBanco';
  static const String planillaPdfCompacta = '/planilla/pdfPlanillaCompacta';
  static const String planillaExcelCompacta = '/planilla/excelPlanillaCompacta';
  static const String planillaPdfExtendida = '/planilla/pdfPlanillaExtendida';
  static const String planillaPdfPapeletaPago = '/planilla/pdfPapeletaPago';

  // ==========================================================================
  // ROL DE TURNOS DE SABADO (modulo trs_)
  // ==========================================================================
  static const String _rolSab = '/rol-sabados';

  // Generacion (SPs de proceso)
  static const String rolSabGenerarRol = '$_rolSab/generar-rol';
  static const String rolSabRegenerarSabado = '$_rolSab/regenerar-sabado';
  static const String rolSabRefrescarFeriados = '$_rolSab/refrescar-feriados';

  // Cabecera
  static const String rolSabObtenerRoles = '$_rolSab/obtener-roles';
  static const String rolSabObtenerRol = '$_rolSab/obtener-rol';
  // Es un UPDATE de la cabecera, no un alta: el backend manda 'I' solo cuando
  // idRol viene en 0, y el alta de un rol va por generar-rol. Hoy lo usa el
  // cambio de estado (publicar / reabrir / cerrar).
  static const String rolSabRegistrarRol = '$_rolSab/registrar-rol';
  static const String rolSabObtenerIntervenciones =
      '$_rolSab/obtener-intervenciones';

  // Sabados
  static const String rolSabMarcarEvento = '$_rolSab/marcar-evento';
  static const String rolSabObtenerSabados = '$_rolSab/obtener-sabados';
  static const String rolSabObtenerCobertura = '$_rolSab/obtener-cobertura';
  static const String rolSabObtenerFeriadosDesincronizados =
      '$_rolSab/obtener-feriados-desincronizados';
  static const String rolSabObtenerDiasNoLaborables =
      '$_rolSab/obtener-dias-no-laborables';

  // Participantes
  static const String rolSabObtenerParticipantes =
      '$_rolSab/obtener-participantes';
  static const String rolSabObtenerTurnosPorParticipante =
      '$_rolSab/obtener-turnos-por-participante';
  static const String rolSabObtenerCumplesSabado =
      '$_rolSab/obtener-cumples-sabado';

  // Convocatoria (eventos)
  static const String rolSabConvocar = '$_rolSab/convocar';
  static const String rolSabObtenerDetalleEvento =
      '$_rolSab/obtener-detalle-evento';

  // Celdas
  static const String rolSabObtenerAsignaciones =
      '$_rolSab/obtener-asignaciones';
  static const String rolSabCorregirCelda = '$_rolSab/corregir-celda';
  static const String rolSabLiberarCelda = '$_rolSab/liberar-celda';
  static const String rolSabObtenerEstadosTurno =
      '$_rolSab/obtener-estados-turno';
  static const String rolSabObtenerAutomatizacion =
      '$_rolSab/obtener-automatizacion';

  // Cambios
  static const String rolSabRegistrarCambio = '$_rolSab/registrar-cambio';
  static const String rolSabAprobarCambio = '$_rolSab/aprobar-cambio';
  static const String rolSabObtenerCambios = '$_rolSab/obtener-cambios';

  static const String rolSabObtenerProgramaciones =
      '$_rolSab/obtener-programaciones';
  static const String rolSabAnularCambio = '$_rolSab/anular-cambio';

  // La ventana de sabados de una persona: desde y hasta cuando hace sabados.
  //
  // El primero es el endpoint que ya existia (/eliminar-participante) con la
  // semantica arreglada: NO da de baja al empleado — le cierra la ventana. Lo
  // que ya trabajo queda en la grilla; se liberan los sabados de adelante.
  static const String rolSabSacarDeSabados = '$_rolSab/eliminar-participante';
  static const String rolSabReincorporar = '$_rolSab/reincorporar-participante';

  // Vacaciones y permisos de RR.HH. (trh_permiso)
  static const String rolSabAsignarGrupo = '$_rolSab/asignar-grupo';
  static const String rolSabRefrescarPermisos = '$_rolSab/refrescar-permisos';
  static const String rolSabObtenerDesfasesPermiso =
      '$_rolSab/obtener-desfases-permiso';

  // El biométrico (tbio_) pisa al rol: excusa por cuota de horas cumplida.
  static const String rolSabRefrescarExcusasHorario =
      '$_rolSab/refrescar-excusas-horario';

  // Su Equipo: lo que usa un jefe para decidir quien de su gente viene.
  // mi-equipo y programar NO llevan identidad en el body: el servidor la saca
  // del token, asi que nadie puede programar a nombre de otro.
  static const String rolSabMiEquipo = '$_rolSab/mi-equipo';
  static const String rolSabProgramar = '$_rolSab/programar';

  // ABM de programadores (solo ROLE_ADM)
  static const String rolSabObtenerProgramadores =
      '$_rolSab/obtener-programadores';
  static const String rolSabRegistrarProgramador =
      '$_rolSab/registrar-programador';
  static const String rolSabEliminarProgramador =
      '$_rolSab/eliminar-programador';

  /// A quiénes le quedaría a cargo un permiso que **todavía no existe**: lo que
  /// se mira antes de dar de alta.
  ///
  /// No es lo mismo que `/obtener-dependientes`, que sólo sabe de permisos ya
  /// guardados. Los dos salen del mismo árbol del organigrama, que es lo que
  /// hace que lo previsualizado sea lo que después se acepta.
  static const String rolSabPrevisualizarDependientes =
      '$_rolSab/previsualizar-dependientes';

  // Puente a cuenta de vacación: la empresa cierra el sábado y se lo cobra a la
  // vacación de todos. Simular NO escribe; aplicar da de alta los permisos en
  // trh_permiso y deja las celdas en 'V'.
  static const String rolSabSimularPuente = '$_rolSab/simular-puente-vacacion';
  static const String rolSabAplicarPuente = '$_rolSab/aplicar-puente-vacacion';

  // El padrón de RR.HH.: quiénes pueden corregir CUALQUIER celda (solo ROLE_ADM)
  static const String rolSabObtenerRrhh = '$_rolSab/obtener-rrhh';
  static const String rolSabRegistrarRrhh = '$_rolSab/registrar-rrhh';
  static const String rolSabEliminarRrhh = '$_rolSab/eliminar-rrhh';

  // Reportes
  // Devuelve el PDF en bytes (application/pdf), no JSON: se baja con
  // DioClient.descargarReportePdf y no con el BaseApiRepository.
  // El backend la expone con el sufijo del formato: deja lugar a que mañana
  // haya un '/reporte-sabado-excel' sin renombrar ésta.
  static const String rolSabReporteSabado = '$_rolSab/reporte-sabado-pdf';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: PERMISOS RR.HH. (consola administrativa de trh_permiso)
  // ═══════════════════════════════════════════════════════════════════════════════
  //
  // Es la consola de RR.HH., NO el flujo del empleado: por eso NO reutiliza el
  // prefijo '/vacacion/...' de más arriba, que tiene otro contrato y otra
  // audiencia. kebab-case adentro del módulo, siguiendo a '/rol-sabados'.
  //
  // El buscador de empleados NO tiene constante propia: reutiliza
  // `rrhhObtenerLstEmpleados` (más arriba en este archivo), que ya pagina en SQL.
  static const String _permRrhh = '/permiso-rrhh';
  static const String permRrhhSaldoFicha = '$_permRrhh/saldo/ficha';
  static const String permRrhhSaldoDesglose = '$_permRrhh/saldo/desglose';

  /// Los permisos que suman un tramo del desglose. El cuerpo lleva la clave del
  /// tramo (`SALDO_PENULTIMO`, `UTILIZADA`, `PROGRAMADA`) y **no** las fechas:
  /// ésas las resuelve el servidor con la misma consulta que dio el monto, así
  /// el detalle no puede discrepar del total.
  static const String permRrhhSaldoDetalleTramo =
      '$_permRrhh/saldo/detalle-tramo';

  /// El «DETALLE COMPLETO» del sistema anterior: el estado de cuenta del
  /// empleado en PDF. La variante fiscal oculta los días abonados, y ese flag
  /// vive dentro del `.jrxml`, no aquí: son dos rutas y no un parámetro.
  static const String permRrhhEstadoCuenta =
      '$_permRrhh/reportes/estado-cuenta';
  static const String permRrhhEstadoCuentaFiscal =
      '$_permRrhh/reportes/estado-cuenta-fiscal';

  /// Los días del rango que NO descuentan: feriados de la sucursal del
  /// empleado y sábados que el rol dice que no le tocan. Los domingos no
  /// vienen — la UI los deduce de la fecha.
  /// «Quién está fuera»: los permisos de TODA la empresa en una fecha o rango.
  /// Es la única consulta del módulo que no es por empleado.
  /// El buscador global de boletas entre fechas, para cuando alguien pide una
  /// copia y no se sabe de quién era.
  static const String permRrhhBoletas = '$_permRrhh/permisos/boletas';
  static const String permRrhhQuienEstaFuera =
      '$_permRrhh/permisos/quien-esta-fuera';
  static const String permRrhhDiasNoHabiles =
      '$_permRrhh/permisos/dias-no-habiles';
  static const String permRrhhCalculoAntiguedad =
      '$_permRrhh/herramientas/calculo-antiguedad';

  // ── Escrituras (Fase 2) ────────────────────────────────────────────────
  //
  // El alta y la edición son la MISMA ruta, como en el legacy: la acción la
  // decide el id (0 = 'I', > 0 = 'U'), no un flag ni un endpoint aparte.
  //
  // La baja va por ruta propia y no por un `eliminar: true` en el cuerpo: es un
  // DELETE físico (lo archiva el trigger `dad_`), y una operación que borra no
  // comparte URL con una que guarda.
  //
  // **Estas rutas son las que expone `PermisoRrhhController`, letra por letra.**
  // Hasta la corrección de agosto de 2026 seis de las diez apuntaban a un
  // camino que no existe (`/abonos/...` en vez de `/abono-dias/...`,
  // `/colectivas/...` en vez de `/colectivo/...`): la escritura daba 404 y la
  // pantalla lo mostraba como «error de conexión». `permisos_rrhh_contrato_test`
  // las compara contra la lista canónica para que no vuelva a pasar en silencio.
  static const String permRrhhVacAsigHistorial =
      '$_permRrhh/vacacion-asignada/historial';
  static const String permRrhhVacAsigRegistrar =
      '$_permRrhh/vacacion-asignada/registrar';
  static const String permRrhhVacAsigEliminar =
      '$_permRrhh/vacacion-asignada/eliminar';

  // `historial` y no `detalle`: es el listado de una persona, el mismo papel
  // que su hermano de vacación asignada. El detalle de UNA fila no tiene
  // endpoint porque no hace falta — el alta y la edición devuelven la fila
  // releída.
  static const String permRrhhAbonoHistorial =
      '$_permRrhh/abono-dias/historial';
  static const String permRrhhAbonoRegistrar =
      '$_permRrhh/abono-dias/registrar';
  static const String permRrhhAbonoEliminar = '$_permRrhh/abono-dias/eliminar';

  // Cargas colectivas. `/empleados` es el padrón para tildar (p_list_Permiso
  // 'E'); `simular` no escribe nada y `aplicar` escribe N filas en una sola
  // transacción del lado de Java.
  //
  // **Las dos tienen `simular`.** La vacación porque los días salen distintos
  // por sucursal; el abono porque —aunque los días sean uno solo para todos— el
  // servidor es el único que sabe quién tiene relación activa y quién ya cobró
  // ese día. Armar la confirmación con la selección local decía «3 días a 40
  // personas» sin saber a cuántas alcanzaba de verdad.
  static const String permRrhhColectivaEmpleados =
      '$_permRrhh/colectivo/empleados';
  static const String permRrhhColectivaAbonoSimular =
      '$_permRrhh/colectivo/abono-dias/simular';
  static const String permRrhhColectivaAbonoAplicar =
      '$_permRrhh/colectivo/abono-dias/aplicar';
  static const String permRrhhColectivaVacacionSimular =
      '$_permRrhh/colectivo/vacacion/simular';
  static const String permRrhhColectivaVacacionAplicar =
      '$_permRrhh/colectivo/vacacion/aplicar';

  // ── El permiso individual (Fase 3) ─────────────────────────────────────
  //
  // Las cuatro pantallas del kardex legacy: la Nómina de Permisos y los tres
  // modales que escriben en `trh_permiso`.
  //
  // **Los nombres son los del backend, letra por letra** (`/permisos/...` en
  // plural para lo que cuelga del kardex, `/vacacion/...` para las dos que son
  // de vacación). Hasta la corrección de agosto de 2026 las cinco apuntaban a
  // `/permiso/...`, que no existe de aquel lado: 404 en las cuatro pantallas,
  // que `DioClient` muestra como «error de conexión». Es exactamente la falla
  // que documenta el bloque de arriba, repetida.
  //
  // **`registrar` son DOS rutas y no una.** El servidor partió el alta con dos
  // botones de ACL distintos —`btnProgramarPermiso` (4 usuarios) contra
  // `btnProgramarVacacion` (5)— y `/permisos/registrar` rechaza `tipoPermiso:
  // 'vac'` con un 400 explícito. La vacación va por `/vacacion/registrar`, que
  // pone el tipo del lado del servidor: si viniera del cuerpo, esa ruta sería
  // un segundo camino para dar de alta cualquier permiso salteándose el botón
  // del otro. Del otro lado igual terminan las dos en el mismo `p_abm_Permiso`.
  //
  // **`vacacion/pagar` va aparte**, aunque escriba en la misma tabla: el
  // servidor le fuerza `tipoPermiso='pva'` y `hasta = desde`, no pasa por el
  // cálculo de días —los tipea el usuario— y es la única de las tres que paga
  // plata sin que ningún SP valide nada.
  //
  // **`calcular` no escribe**: alimenta «Horas de permiso» / «Días de permiso» /
  // «Total días de vacación» en vivo y devuelve además si el alta va a poder
  // guardarse. Es el equivalente individual de `/colectivo/vacacion/simular`.
  //
  // **`vacaciones-ganadas` es el otro botón de la nómina** (`p_list_vacacionAsignada`
  // ACCION 'D'): un SELECT por rango sobre las filas REALES. No se recorta el
  // historial (ACCION 'B') en memoria, porque aquel además inventa filas
  // sintéticas por aniversario y se pide con una fecha de corte: sería otro
  // conjunto de partida y otra respuesta para el mismo botón.
  static const String permRrhhPermisoHistorial = '$_permRrhh/permisos/kardex';
  static const String permRrhhPermisoSimular = '$_permRrhh/permisos/calcular';
  static const String permRrhhPermisoRegistrar =
      '$_permRrhh/permisos/registrar';
  static const String permRrhhVacacionRegistrar =
      '$_permRrhh/vacacion/registrar';
  static const String permRrhhPermisoVacacionPagada =
      '$_permRrhh/vacacion/pagar';
  static const String permRrhhVacacionesGanadas =
      '$_permRrhh/permisos/vacaciones-ganadas';

  // El combo de tipos (`v_tipos` grupo 13). `incluirVacacionYPago: false`
  // replica `Tipos.cargarList13A()` —los 7 del modal de permiso, sin 'vac' ni
  // 'pva'—; `true` devuelve los 9 para el filtro de la Nómina.
  //
  // **No se reutiliza `tipoPermisoSolicitudVacacion`**: aquel filtra por
  // `codEmpleado` + `codUsuarioLogueado` (los tipos que ESA persona puede
  // pedirse) y esto es la consola de RR.HH., que carga a nombre de otro.
  static const String permRrhhPermisoTipos = '$_permRrhh/permisos/tipos';

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: CARTAS CITE  (tcrDocumento)
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String citeListar = '/cartas-cite/listar';
  static const String citeObtener = '/cartas-cite/obtener';
  static const String citeSiguienteCite = '/cartas-cite/siguiente-cite';
  static const String citeTiposDocumento = '/cartas-cite/tipos-documento';
  static const String citeAreas = '/cartas-cite/areas';
  static const String citeEmpleados = '/cartas-cite/empleados';
  static const String citeEmpleado = '/cartas-cite/empleado';
  static const String citeFirmaUsuario = '/cartas-cite/firma-usuario';
  static const String citeGestiones = '/cartas-cite/gestiones';
  static const String citePrepararGestion = '/cartas-cite/preparar-gestion';
  static const String citeGuardar = '/cartas-cite/guardar';
  static const String citeAnular = '/cartas-cite/anular';
  static const String citeGenerarPdf = '/cartas-cite/generar-pdf';
  static const String citeReporteMensual = '/cartas-cite/reporte-mensual';

  //Para cargar permisos de botones por usuario
  static const String ubtnPermisosBotones = '/view/vistaBtn';

  // Constantes para el servicio de geocodificación de Nominatim
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimReverseEndpoint = '/reverse';
  static const String nominatimUserAgent = 'Bosque';

  // Constante para Google Maps Search
  static const String googleMapsSearchBaseUrl =
      'https://www.google.com/maps/search/?api=1&query';
  static const String googleMapsOpenStreetMaps =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Constante para la URL de las imágenes de los empleados
  static const String getImageUrl = '/fichaTrabajador/uploads/img';
  static const String getDocImageUrl = '/fichaTrabajador/uploads/documentos/';
  static const String getDocPendienteImageUrl =
      '/fichaTrabajador/uploads/pendientes/';

  // ==================== COMISIONES (tcom) ====================
  // Migración de la pantalla Comisiones.xhtml de Bosque v2.

  // Grupos
  static const String comRegistrarGrupo = '/comisiones/registrar-grupo';
  static const String comEliminarGrupo = '/comisiones/eliminar-grupo';
  static const String comObtenerGrupos = '/comisiones/obtener-grupos';
  static const String comObtenerGruposAsignables =
      '/comisiones/obtener-grupos-asignables';
  static const String comObtenerGruposTodos =
      '/comisiones/obtener-grupos-todos';

  // Vendedores
  static const String comRegistrarVendedor = '/comisiones/registrar-vendedor';
  static const String comEliminarVendedor = '/comisiones/eliminar-vendedor';
  static const String comObtenerVendedores = '/comisiones/obtener-vendedores';
  static const String comObtenerVendedoresEmpresa =
      '/comisiones/obtener-vendedores-empresa';
  static const String comObtenerVendedoresTodos =
      '/comisiones/obtener-vendedores-todos';

  // Asignación grupo / vendedor
  static const String comRegistrarGrupoVendedor =
      '/comisiones/registrar-grupo-vendedor';
  static const String comEliminarGrupoVendedor =
      '/comisiones/eliminar-grupo-vendedor';
  static const String comObtenerGruposVendedor =
      '/comisiones/obtener-grupos-vendedor';
  static const String comObtenerAsignacionesVigentes =
      '/comisiones/obtener-asignaciones-vigentes';

  // Vistas preliminares. Llaman al SP heredado p_list_paraPagar (ramas F, I,
  // J, K, E, H): mismos números que Bosque v2.
  static const String comPreliminarInterno = '/comisiones/preliminar-interno';
  static const String comPreliminarExterno = '/comisiones/preliminar-externo';
  static const String comPreliminarDinamicaAnterior =
      '/comisiones/preliminar-dinamica-anterior';
  static const String comPreliminarDinamicaVigente =
      '/comisiones/preliminar-dinamica-vigente';
  // Carga y ejecución del período
  static const String comEstadoPeriodo = '/comisiones/estado-periodo';
  static const String comSincronizarNotas = '/comisiones/sincronizar-notas';
  static const String comCargarNotas = '/comisiones/cargar-notas';
  static const String comEjecutarPago = '/comisiones/ejecutar-pago';

  // Comisión por rango de días. La escritura exige ROLE_ADM en el backend.
  static const String comObtenerRangosComision =
      '/comisiones/obtener-rangos-comision';
  static const String comRegistrarRangoComision =
      '/comisiones/registrar-rango-comision';
  static const String comEliminarRangoComision =
      '/comisiones/eliminar-rango-comision';

  // Detalle de una fila del preliminar: las notas que la componen.
  // Rama G1 del mismo SP, la que abria «Ver Notas a Pagar» en Bosque v2.
  static const String comNotasPreliminar = '/comisiones/notas-preliminar';

  // Ítems congelados al ejecutar el pago: p_list_tcom_PagadoItem.
  //
  // Es el otro lado del preliminar —lo que YA se pagó—, y por eso no vive en
  // el bloque de preliminares: el preliminar lista notas cerradas y SIN pagar,
  // y al ejecutar el período esas notas pasan a tcom_pagado.
  /// La acción va en la ruta, igual que en comDescuentoDetalle: L listado por
  /// ítem, R resumen por motivo de exclusión.
  static const String comItemsPagados = '/comisiones/items-pagados';

  /// El sello del período congelado: p_list_tcom_PagadoItemCorte. Es lo único
  /// que distingue «no había nada que congelar» de «el congelado no corrió»,
  /// así que sin esto un cero no se puede mostrar.
  static const String comItemsPagadosCorte = '/comisiones/items-pagados-corte';

  // Política del descuento por familia. Todo el bloque exige btnComPolitica:
  // define cuánto se le paga a la fuerza de ventas.
  /// Detalle de lo descontado. La acción va en la ruta: P período abierto,
  /// H histórico ya pagado, R resumen por vendedor y familia.
  static const String comDescuentoDetalle = '/comisiones/descuento-detalle';

  static const String comPoliticaFamiliasSap =
      '/comisiones/politica-familias-sap';
  static const String comPoliticaFamiliasDisponibles =
      '/comisiones/politica-familias-disponibles';
  static const String comPoliticaFamilias = '/comisiones/politica-familias';
  static const String comPoliticaFamiliasVigentes =
      '/comisiones/politica-familias-vigentes';
  static const String comRegistrarPoliticaFamilia =
      '/comisiones/registrar-politica-familia';
  static const String comEliminarPoliticaFamilia =
      '/comisiones/eliminar-politica-familia';
  static const String comPoliticaExentos = '/comisiones/politica-exentos';
  static const String comRegistrarPoliticaExento =
      '/comisiones/registrar-politica-exento';
  static const String comEliminarPoliticaExento =
      '/comisiones/eliminar-politica-exento';
  static const String comPoliticaClientesExcluidos =
      '/comisiones/politica-clientes-excluidos';
  static const String comRegistrarPoliticaCliente =
      '/comisiones/registrar-politica-cliente';
  static const String comEliminarPoliticaCliente =
      '/comisiones/eliminar-politica-cliente';

  // Notas pendientes
  static const String comNotasPendientes =
      '/comisiones/obtener-notas-pendientes';

  static const String comObtenerTipoCambio = '/comisiones/obtener-tipo-cambio';

  // Reportes PDF
  static const String comRptPagadasInternas =
      '/comisiones/reporte-pagadas-internas';
  static const String comRptPagadasExternas =
      '/comisiones/reporte-pagadas-externas';
  static const String comRptImportaciones = '/comisiones/reporte-importaciones';
  static const String comRptPagadasEpp = '/comisiones/reporte-pagadas-epp';
  static const String comRptNotasPendientes =
      '/comisiones/reporte-notas-pendientes';
  static const String comRptPorVendedor = '/comisiones/reporte-por-vendedor';

  // Comisión dinámica
  static const String comRegistrarComisionDinamica =
      '/comisiones/registrar-comision-dinamica';
  static const String comEliminarComisionDinamica =
      '/comisiones/eliminar-comision-dinamica';
  static const String comObtenerComisionesDinamicas =
      '/comisiones/obtener-comisiones-dinamicas';
  static const String comObtenerComisionesDinamicasVigentes =
      '/comisiones/obtener-comisiones-dinamicas-vigentes';

  // ==================== TALONARIOS (tmto_*) ====================
  // Cinco tablas, un par ABM/LIST por tabla. Ver ClaudeTalonarios/sql/00-LEEME.md

  // Tipos de recibo (catálogo)
  static const String talRegistrarTipo = '/talonarios/registrar-tipo';
  static const String talEliminarTipo = '/talonarios/eliminar-tipo';
  static const String talObtenerTipo = '/talonarios/obtener-tipo';
  static const String talListarTipos = '/talonarios/listar-tipos';

  // Grupos
  static const String talRegistrarGrupo = '/talonarios/registrar-grupo';
  static const String talEliminarGrupo = '/talonarios/eliminar-grupo';
  static const String talObtenerGrupo = '/talonarios/obtener-grupo';
  static const String talListarGrupos = '/talonarios/listar-grupos';

  // Tipos por grupo (tabla de unión, solo alta y baja)
  static const String talAsignarTipoGrupo = '/talonarios/asignar-tipo-grupo';
  static const String talQuitarTipoGrupo = '/talonarios/quitar-tipo-grupo';
  static const String talListarTiposPorGrupo =
      '/talonarios/listar-tipos-por-grupo';
  static const String talListarTiposDisponibles =
      '/talonarios/listar-tipos-disponibles';

  // Talonarios
  static const String talRegistrarTalonario = '/talonarios/registrar-talonario';
  static const String talEliminarTalonario = '/talonarios/eliminar-talonario';
  static const String talObtenerTalonario = '/talonarios/obtener-talonario';
  static const String talListarTalonarios = '/talonarios/listar-talonarios';
  static const String talListarDisponibles = '/talonarios/listar-disponibles';

  // Alta masiva: simular no escribe nada, aplicar es todo o nada
  static const String talSimularLote = '/talonarios/simular-lote';
  static const String talAplicarLote = '/talonarios/aplicar-lote';

  // Eventos (log de estados)
  static const String talRegistrarEvento = '/talonarios/registrar-evento';
  static const String talEliminarEvento = '/talonarios/eliminar-evento';
  static const String talListarEventos = '/talonarios/listar-eventos';

  // Entrega masiva: todo o nada
  static const String talEntregarLote = '/talonarios/entregar-lote';

  // Reportes del módulo. Devuelven bytes de PDF, no ApiResponse: se piden con
  // DioClient.descargarReportePdf y no con postAndReturn*.
  static const String talRptInventario = '/talonarios/reporte-inventario';
  static const String talRptTrazabilidad = '/talonarios/reporte-trazabilidad';
  static const String talRptFicha = '/talonarios/reporte-ficha';
  static const String talRptCustodia = '/talonarios/reporte-custodia';
  static const String talRptConciliacionSap =
      '/talonarios/reporte-conciliacion-sap';

  // ── Biométrico (tbio_) ──────────────────────────────────────────────────
  // Todos POST. Los "registrar*" van con acc ('I'/'U'/'D') como query param
  // en el propio endpoint (ver BiometricoImpl) porque el backend lo recibe
  // por @RequestParam, no en el body.
  static const String biometricoListarMarcaciones =
      '/biometrico/marcaciones/listar';
  static const String biometricoImportarMarcacionesMensual =
      '/biometrico/marcaciones/importar-mensual';
  static const String biometricoListarMarcacionesAdicionales =
      '/biometrico/marcaciones-adicionales/listar';
  static const String biometricoRegistrarMarcacionAdicional =
      '/biometrico/marcaciones-adicionales/registrar';
  static const String biometricoListarEmpleados =
      '/biometrico/empleados/listar';
  static const String biometricoRegistrarEmpleado =
      '/biometrico/empleados/registrar';
  static const String biometricoListarHorarios = '/biometrico/horarios/listar';
  static const String biometricoRegistrarHorario =
      '/biometrico/horarios/registrar';
  static const String biometricoListarHorariosSemanales =
      '/biometrico/horarios-semanales/listar';
  static const String biometricoRegistrarHorarioSemanal =
      '/biometrico/horarios-semanales/registrar';
  static const String biometricoListarHorariosSemanalesDetalle =
      '/biometrico/horarios-semanales-detalle/listar';
  static const String biometricoRegistrarHorarioSemanalDetalle =
      '/biometrico/horarios-semanales-detalle/registrar';
  static const String biometricoListarHorarioEmpleado =
      '/biometrico/horario-empleado/listar';
  static const String biometricoRegistrarHorarioEmpleado =
      '/biometrico/horario-empleado/registrar';
  static const String biometricoListarCalendarioExpandido =
      '/biometrico/calendario-expandido/listar';
  static const String biometricoRegistrarCalendarioExpandido =
      '/biometrico/calendario-expandido/registrar';
  static const String biometricoRegenerarCalendarioExpandido =
      '/biometrico/calendario-expandido/regenerar';
  static const String biometricoListarBitacora = '/biometrico/bitacora/listar';
  static const String biometricoReporteMensual = '/biometrico/reporte-mensual';
  static const String biometricoReporteMensualPdf =
      '/biometrico/reporte-mensual-pdf';
  static const String biometricoReporteMensualResumen =
      '/biometrico/reporte-mensual-resumen';
  static const String biometricoReporteMensualResumenPdf =
      '/biometrico/reporte-mensual-resumen-pdf';
  static const String biometricoReporteMensualDetalladoTodosPdf =
      '/biometrico/reporte-mensual-detallado-todos-pdf';
  static const String biometricoHorarioVigentePorEmpleadoPdf =
      '/biometrico/horario-vigente-por-empleado-pdf';
  static const String biometricoReporteDetalladoRangoPdf =
      '/biometrico/reporte-detallado-rango-pdf';

  // ── TAREAS RUTINARIAS ────────────────────────────────────────────────────
  // Prefijo "tar" (no "tpex"/"mul"/etc.) — módulo nuevo, procs p_abm_tac_*/
  // p_list_tac_* en Bosque Spring. Ver TareasRutinariasController.java.

  // Especiales: jefe → dependientes
  static const String tarListarDependientesJefe =
      '/tareas-rutinarias/listar-dependientes-jefe';
  static const String tarRegistrarTareaConCargos =
      '/tareas-rutinarias/registrar-tarea-rutinaria-con-cargos';

  // Admin "Tareas Rutinarias por Cargo" (reemplaza dlgTarFunXCargo de
  // WizardEstOrg.java — solo el lado de Tareas Rutinarias, no FUNCIONES).
  static const String tarRegistrarTareaPorCargoAdmin =
      '/tareas-rutinarias/admin/registrar-tarea-rutinaria-por-cargo';
  static const String tarObtenerTareasPorCargo =
      '/tareas-rutinarias/admin/obtener-tareas-rutinarias-por-cargo';

  // Documentación (catálogo)
  static const String tarRegistrarDocumentacion =
      '/tareas-rutinarias/registrar-documentacion';
  static const String tarEliminarDocumentacion =
      '/tareas-rutinarias/eliminar-documentacion';
  static const String tarObtenerDocumentacion =
      '/tareas-rutinarias/obtener-documentacion';

  // Tarea rutinaria (definición)
  static const String tarRegistrarTareaRutinaria =
      '/tareas-rutinarias/registrar-tarea-rutinaria';
  static const String tarEliminarTareaRutinaria =
      '/tareas-rutinarias/eliminar-tarea-rutinaria';
  static const String tarObtenerTareaRutinaria =
      '/tareas-rutinarias/obtener-tarea-rutinaria';

  // Llegada (caja fuerte)
  static const String tarRegistrarLlegada =
      '/tareas-rutinarias/registrar-llegada';
  static const String tarEliminarLlegada =
      '/tareas-rutinarias/eliminar-llegada';
  static const String tarObtenerLlegada = '/tareas-rutinarias/obtener-llegada';

  // Traspaso de movimiento de caja
  static const String tarRegistrarTraspasoMovCaja =
      '/tareas-rutinarias/registrar-traspaso-mov-caja';
  static const String tarEliminarTraspasoMovCaja =
      '/tareas-rutinarias/eliminar-traspaso-mov-caja';
  static const String tarObtenerTraspasoMovCaja =
      '/tareas-rutinarias/obtener-traspaso-mov-caja';

  // Tarea 295, "Verificar traspaso Caja AXA contra movimiento de caja"
  // (idATR 12). Las rutas dicen "traspaso-entre-sistemas" por historia: al
  // principio se creyó que era la 289, que es TesBase (ver el archivo SQL 51).
  // El listado NO lee la tabla: el servidor consulta SAP y cruza contra lo ya
  // verificado, asi que puede tardar y puede fallar si el enlace no responde.
  static const String tarTraspasoEntreSistemasDelDia =
      '/tareas-rutinarias/traspaso-entre-sistemas/del-dia';
  static const String tarTraspasoEntreSistemasVerificar =
      '/tareas-rutinarias/traspaso-entre-sistemas/verificar';
  static const String tarTraspasoEntreSistemasSinNovedad =
      '/tareas-rutinarias/traspaso-entre-sistemas/sin-novedad';

  // Tarea 289, "Verificar Traspaso de Efectivo Entre Sistemas" (idATR 11,
  // TesBase / ttes_TesBase). Solo la verificación; el registro sigue en el
  // sistema anterior. Archivo SQL 56.
  static const String tarTesBasePendientes =
      '/tareas-rutinarias/traspaso-efectivo-tesbase/pendientes';
  static const String tarTesBaseCerrar =
      '/tareas-rutinarias/traspaso-efectivo-tesbase/cerrar';
  static const String tarTesBaseSinPendientes =
      '/tareas-rutinarias/traspaso-efectivo-tesbase/sin-pendientes';
  // Qué día revisa la ocurrencia (el hábil anterior, con los feriados de la
  // sucursal) y las transferencias de un día. Archivo SQL 58.
  static const String tarTesBaseDiaRevisado =
      '/tareas-rutinarias/traspaso-efectivo-tesbase/dia-revisado';
  static const String tarTesBaseDelDia =
      '/tareas-rutinarias/traspaso-efectivo-tesbase/del-dia';

  // Bitácoras de tareas rutinarias (vista tacTareas/Bitacora, archivo SQL 55).
  // El alcance —toda la empresa o el equipo propio— lo decide el servidor
  // desde el token; nada de lo que se mande aquí lo amplía.
  static const String tarBitacoraCumplimiento =
      '/tareas-rutinarias/bitacora/cumplimiento';
  static const String tarBitacoraCumplimientoPdf =
      '/tareas-rutinarias/bitacora/cumplimiento-pdf';
  static const String tarBitacoraGeneracion =
      '/tareas-rutinarias/bitacora/generacion';
  static const String tarBitacoraPorQue = '/tareas-rutinarias/bitacora/por-que';

  // Acción de tarea rutinaria (catálogo idATR)
  static const String tarRegistrarAccionTareaRutinaria =
      '/tareas-rutinarias/registrar-accion-tarea-rutinaria';
  static const String tarEliminarAccionTareaRutinaria =
      '/tareas-rutinarias/eliminar-accion-tarea-rutinaria';
  static const String tarObtenerAccionTareaRutinaria =
      '/tareas-rutinarias/obtener-accion-tarea-rutinaria';

  // Arqueo de caja de sucursales
  static const String tarRegistrarArqueoCajaSucursales =
      '/tareas-rutinarias/registrar-arqueo-caja-sucursales';
  static const String tarEliminarArqueoCajaSucursales =
      '/tareas-rutinarias/eliminar-arqueo-caja-sucursales';
  static const String tarObtenerArqueoCajaSucursales =
      '/tareas-rutinarias/obtener-arqueo-caja-sucursales';

  // Monto de caja chica por sucursal
  static const String tarRegistrarMontoCajaChicaXSuc =
      '/tareas-rutinarias/registrar-monto-caja-chica-x-suc';
  static const String tarEliminarMontoCajaChicaXSuc =
      '/tareas-rutinarias/eliminar-monto-caja-chica-x-suc';
  static const String tarObtenerMontoCajaChicaXSuc =
      '/tareas-rutinarias/obtener-monto-caja-chica-x-suc';

  // Caja chica
  static const String tarRegistrarCajaChica =
      '/tareas-rutinarias/registrar-caja-chica';
  static const String tarEliminarCajaChica =
      '/tareas-rutinarias/eliminar-caja-chica';
  static const String tarObtenerCajaChica =
      '/tareas-rutinarias/obtener-caja-chica';

  // Sucursal × movimiento de caja
  static const String tarRegistrarSucXMovCaja =
      '/tareas-rutinarias/registrar-suc-x-mov-caja';
  static const String tarEliminarSucXMovCaja =
      '/tareas-rutinarias/eliminar-suc-x-mov-caja';
  static const String tarObtenerSucXMovCaja =
      '/tareas-rutinarias/obtener-suc-x-mov-caja';

  // Bitácora de tarea rutinaria
  static const String tarRegistrarBitTareaRuti =
      '/tareas-rutinarias/registrar-bit-tarea-ruti';
  static const String tarEliminarBitTareaRuti =
      '/tareas-rutinarias/eliminar-bit-tarea-ruti';
  // Lo único que se le hace a una tarea ya hecha (archivo SQL 75).
  static const String tarAgregarObservacionTarea =
      '/tareas-rutinarias/agregar-observacion';
  static const String tarObtenerBitTareaRuti =
      '/tareas-rutinarias/obtener-bit-tarea-ruti';

  // Movimiento de caja
  static const String tarRegistrarMovCaja =
      '/tareas-rutinarias/registrar-mov-caja';
  static const String tarEliminarMovCaja =
      '/tareas-rutinarias/eliminar-mov-caja';
  static const String tarObtenerMovCaja = '/tareas-rutinarias/obtener-mov-caja';

  // Frecuencia (catálogo)
  static const String tarRegistrarFrecuencia =
      '/tareas-rutinarias/registrar-frecuencia';
  static const String tarEliminarFrecuencia =
      '/tareas-rutinarias/eliminar-frecuencia';
  static const String tarObtenerFrecuencia =
      '/tareas-rutinarias/obtener-frecuencia';

  // Corte (catálogo: denominaciones)
  static const String tarRegistrarCorte = '/tareas-rutinarias/registrar-corte';
  static const String tarEliminarCorte = '/tareas-rutinarias/eliminar-corte';
  static const String tarObtenerCorte = '/tareas-rutinarias/obtener-corte';

  // Asignación de cargo a tarea rutinaria (CRUD estándar; el alta con
  // validación de subárbol es tarRegistrarTareaConCargos, arriba)
  static const String tarRegistrarTarRuXCargo =
      '/tareas-rutinarias/registrar-tar-ru-x-cargo';
  static const String tarEliminarTarRuXCargo =
      '/tareas-rutinarias/eliminar-tar-ru-x-cargo';
  static const String tarObtenerTarRuXCargo =
      '/tareas-rutinarias/obtener-tar-ru-x-cargo';

  // Detalle de arqueo de caja de sucursales
  static const String tarRegistrarDetArqueoCajaSucursales =
      '/tareas-rutinarias/registrar-det-arqueo-caja-sucursales';
  static const String tarEliminarDetArqueoCajaSucursales =
      '/tareas-rutinarias/eliminar-det-arqueo-caja-sucursales';
  static const String tarObtenerDetArqueoCajaSucursales =
      '/tareas-rutinarias/obtener-det-arqueo-caja-sucursales';

  // Vale
  static const String tarRegistrarVale = '/tareas-rutinarias/registrar-vale';
  static const String tarEliminarVale = '/tareas-rutinarias/eliminar-vale';
  static const String tarObtenerVale = '/tareas-rutinarias/obtener-vale';

  // Detalle de documentación
  static const String tarRegistrarDetDocumentacion =
      '/tareas-rutinarias/registrar-det-documentacion';
  static const String tarEliminarDetDocumentacion =
      '/tareas-rutinarias/eliminar-det-documentacion';
  static const String tarObtenerDetDocumentacion =
      '/tareas-rutinarias/obtener-det-documentacion';

  // Llegada de coche
  static const String tarRegistrarCocheLlegadas =
      '/tareas-rutinarias/registrar-coche-llegadas';
  static const String tarEliminarCocheLlegadas =
      '/tareas-rutinarias/eliminar-coche-llegadas';
  static const String tarObtenerCocheLlegadas =
      '/tareas-rutinarias/obtener-coche-llegadas';

  // Coche (catálogo de vehículos)
  static const String tarRegistrarCoche = '/tareas-rutinarias/registrar-coche';
  static const String tarEliminarCoche = '/tareas-rutinarias/eliminar-coche';
  static const String tarObtenerCoche = '/tareas-rutinarias/obtener-coche';

  // Flujo especial: Coches del día (idATR=6) — p_coches_*, no CRUD estándar.
  static const String tarCochesListarDelDia =
      '/tareas-rutinarias/coches/listar-del-dia';
  static const String tarCochesMarcarLlegada =
      '/tareas-rutinarias/coches/marcar-llegada';

  // Flujo especial: Caja Fuerte (idATR=4) — p_cajaFuerte_registrar.
  static const String tarCajaFuerteRegistrar =
      '/tareas-rutinarias/caja-fuerte/registrar';

  // Flujo especial: Arqueo de Caja (idATR=2) — p_arqueo_registrar.
  static const String tarArqueoCajaRegistrar =
      '/tareas-rutinarias/arqueo-caja/registrar';
  // Contexto real (no manual): saldo SAP por caja, tipo de cambio hoy/ayer,
  // arqueo anterior — ver ACCIONes 'A'/'T'/'H' de p_list_tac_SucXMovCaja y
  // p_list_tac_ArqueoCajaSucursales.
  static const String tarArqueoCajaSaldoSap =
      '/tareas-rutinarias/arqueo-caja/saldo-sap';
  static const String tarArqueoCajaTipoCambio =
      '/tareas-rutinarias/arqueo-caja/tipo-cambio';
  static const String tarArqueoCajaAnterior =
      '/tareas-rutinarias/arqueo-caja/anterior';
  // PDF del arqueo ya registrado (RptArqueoDeCaja del legacy) — idAC es el
  // id que devuelve tarArqueoCajaRegistrar al guardar.
  static const String tarArqueoCajaReportePdf =
      '/tareas-rutinarias/arqueo-caja/reporte-pdf';

  // Historial de tareas rutinarias de un empleado (RptTareaXDia del legacy,
  // p_list_bitTareaRuti ACCION='A'). Sin body = el del propio usuario; con
  // codEmpleado = el de otro, y ahí el backend exige el botón btnEmpAll.
  static const String tarMisTareasReportePdf =
      '/tareas-rutinarias/mis-tareas/reporte-pdf';

  // Traspaso de tareas por cambio de cargo (archivo SQL 39). El generador solo
  // mira el cargo mas reciente del empleado, asi que al cambiarle el cargo las
  // tareas del anterior dejan de generarse en silencio. Estos dos endpoints
  // hacen visible esa perdida y dejan decidirla, tarea por tarea.
  static const String tarTraspasosPendientes =
      '/tareas-rutinarias/admin/traspasos-pendientes';
  static const String tarTraspasarTarea =
      '/tareas-rutinarias/admin/traspasar-tarea';

  // Abrir un flujo a requerimiento (archivo SQL 40). Caja Fuerte, Coches, Caja
  // Chica y Cierre de Operaciones ya no son tareas rutinarias: el Job dejo de
  // generarlas y ahora son submodulos de la vista 87. La ocurrencia
  // (tac_bitTareaRuti) nace cuando alguien entra a hacer el trabajo, y este
  // endpoint la crea o devuelve la de hoy si ya existe. El empleado lo resuelve
  // el backend desde el token.
  static const String tarAbrirFlujo = '/tareas-rutinarias/abrir-flujo';

  // PDF del kardex de caja fuerte de HOY para el propio chofer que lo acaba
  // de registrar (RptCajaFuerteCO). Distinto de la variante bajo
  // /verificar-cierre/, que es del supervisor y exige el boton plCajaFuerte:
  // este verifica que el idBitTarea sea de quien llama.
  static const String tarCajaFuerteReportePdf =
      '/tareas-rutinarias/caja-fuerte/reporte-pdf';

  // Lo que ya se registro hoy en caja fuerte, para mostrarlo en la misma
  // pantalla donde se carga. Misma consulta que el panel del supervisor, pero
  // con la ocurrencia propia como permiso en vez del boton plCajaFuerte.
  static const String tarCajaFuerteDelDia =
      '/tareas-rutinarias/caja-fuerte/del-dia';

  // Flujo especial: Caja Chica (idATR=7) — p_cajaChica_*.
  static const String tarCajaChicaListarDelLote =
      '/tareas-rutinarias/caja-chica/listar-del-lote';
  static const String tarCajaChicaRegistrarEgreso =
      '/tareas-rutinarias/caja-chica/registrar-egreso';
  static const String tarCajaChicaFinalizar =
      '/tareas-rutinarias/caja-chica/finalizar';
  // Cierra el lote vigente de la sucursal y abre uno nuevo con su saldo
  // inicial ya sembrado — reemplaza la mitad "reiniciar caja chica" del
  // legacy "Generar PDF" (el reporte en sí se migra aparte).
  static const String tarCajaChicaCerrarLote =
      '/tareas-rutinarias/caja-chica/cerrar-lote';
  // "Ver Cajas Chicas" del legacy — histórico de lotes por sucursal.
  static const String tarCajaChicaHistorialLotes =
      '/tareas-rutinarias/caja-chica/historial-lotes';
  // Picker "Empleado Destino" — búsqueda real por nombre+cargo (el legacy
  // usa un <p:selectOneMenu filter="true">, no un id numérico crudo).
  static const String tarCajaChicaBuscarEmpleados =
      '/tareas-rutinarias/caja-chica/buscar-empleados';
  // PDF "Caja Chica" (RptCajaChica) — botón "Generar PDF" por fila del
  // diálogo "Ver Cajas Chicas". lote y codSucursal viajan desde la propia
  // fila del histórico (tarCajaChicaHistorialLotes ya resuelve codSucursal
  // server-side), nunca de un valor tipeado a mano.
  static const String tarCajaChicaReportePdf =
      '/tareas-rutinarias/caja-chica/reporte-pdf';

  // Flujo especial: Cierre de Operaciones (idATR 3 y 5) — la revisión del día.
  // Reemplaza el diálogo dlgRevArqueo del sistema anterior: arqueos, traspasos
  // de Caja AXA, caja fuerte, cheques y las tareas que generó el Job. Cada
  // panel tiene su endpoint; los de arqueos y caja fuerte viven bajo
  // /verificar-cierre/ porque nacieron para la tarea 39 (ver más abajo).
  //
  // El listado de traspasos es el del día de Caja AXA
  // (tarTraspasoEntreSistemasDelDia): SAP cruzado con lo verificado, siempre
  // con fecha. Hasta el 2026-09-11 usaba tarObtenerTraspasoMovCaja, que sin
  // fecha devolvía la tabla entera.
  static const String tarCierreOperacionesConfirmar =
      '/tareas-rutinarias/cierre-operaciones/confirmar';
  // Los cheques del día cruzados contra SAP (p_SAP_Rpt_ImpChequesPR 'A', el
  // panel plCheques del sistema anterior). Falla si SAP no contesta: una lista
  // vacía diría "no hubo cheques".
  static const String tarCierreOperacionesCheques =
      '/tareas-rutinarias/cierre-operaciones/cheques';
  // Las tareas que generó el Job ese día en la sucursal de la ocurrencia
  // (p_list_tac_BitTareaRuti 'R', archivo SQL 60): lo que quien cierra revisa
  // que los demás hayan hecho. Mismo cuerpo que los otros paneles
  // (idBitTarea + fecha + todasSucursales).
  static const String tarCierreOperacionesTareasDelDia =
      '/tareas-rutinarias/cierre-operaciones/tareas-del-dia';

  // Flujo especial: Verificar Cierre de Operaciones (idATR=5) — el paso
  // supervisor. Los paneles de arqueos/llegadas de HOY ahora vienen
  // enriquecidos (empleado/sucursal/tarea) y soportan "mostrar otras
  // sucursales" — antes reutilizaban tarObtenerArqueoCajaSucursales/
  // tarObtenerLlegada crudos, sin esos datos.
  static const String tarVerificarCierreArqueosDeHoy =
      '/tareas-rutinarias/verificar-cierre/arqueos-de-hoy';
  static const String tarVerificarCierreLlegadasDeHoy =
      '/tareas-rutinarias/verificar-cierre/llegadas-de-hoy';
  static const String tarVerificarCierreMarcarArqueoRevisado =
      '/tareas-rutinarias/verificar-cierre/marcar-arqueo-revisado';
  static const String tarVerificarCierreMarcarLlegadaVerificada =
      '/tareas-rutinarias/verificar-cierre/marcar-llegada-verificada';
  static const String tarVerificarCierreConfirmar =
      '/tareas-rutinarias/verificar-cierre/confirmar';
  // PDF consolidado "Cierre de Operaciones" (RptCierreOperaciones del
  // legacy, botón de cabecera de dlgRevArqueo, solo idATR=5) — junta los 6
  // flujos del día (arqueos, vales, caja fuerte, traspasos, cheques SAP,
  // coches) en un solo PDF. Mismo body que tarVerificarCierreArqueosDeHoy/
  // LlegadasDeHoy (idBitTarea + todasSucursales) — se pide con
  // DioClient.descargarReportePdf y no con BaseApiRepository.postAndReturn*.
  static const String tarVerificarCierreReporteCierreOperacionesPdf =
      '/tareas-rutinarias/verificar-cierre/reporte-cierre-operaciones-pdf';
  // PDF "Caja Fuerte" (RptCajaFuerteCO del legacy, comandLink
  // "DESCARGAR PDF" dentro del panel plCajaFuerte de dlgRevArqueo) —
  // mismo body que tarVerificarCierreArqueosDeHoy/LlegadasDeHoy
  // (idBitTarea + todasSucursales); se pide con
  // DioClient.descargarReportePdf, no con BaseApiRepository.postAndReturn*.
  static const String tarVerificarCierreReporteCajaFuertePdf =
      '/tareas-rutinarias/verificar-cierre/reporte-caja-fuerte-pdf';

  // ── Dias No Laborables (ABM admin) ──────────────────────────────────────
  // Reemplaza al modulo JSF legacy tbDiaNoLaborable. Backend: bloque
  // /dias-no-laborables/* en DiaNoLaborableAdminController. No confundir con
  // `feriados` (linea 532) ni `rolSabObtenerDiasNoLaborables` (linea 635),
  // que son lecturas de otros modulos.
  static const String _diasNoLab = '/dias-no-laborables';
  static const String diasNoLabRegistrar =
      '$_diasNoLab/registrar-dia-no-laborable';
  static const String diasNoLabEliminar =
      '$_diasNoLab/eliminar-dia-no-laborable';
  static const String diasNoLabObtener =
      '$_diasNoLab/obtener-dias-no-laborables';
  static const String diasNoLabObtenerSucursales =
      '$_diasNoLab/obtener-sucursales-dia-no-laborable';

  // ==================== PRECIOS (tpr) ====================
  // Migracion de la pantalla tprAutorizacion/Autorizacion.xhtml de Bosque v2.
  // Backend: PrecioController (prefijo /price) y CatalogoPreciosController
  // (prefijo /price/catalogo). Todos los endpoints son POST, incluidas las
  // lecturas, y responden el envelope {message, data, status}.
  static const String _precios = '/price';
  static const String _preciosCatalogo = '$_precios/catalogo';

  // --- Propuestas: lecturas ---
  // Propuestas pendientes de autorizacion, con estado y quien las genero.
  static const String preciosAutorizacion = '$_precios/autorizacion';
  // Estados posibles de una propuesta (v_tipos grupo 38).
  static const String preciosEstadoPropuesta = '$_precios/estadoPropuesta';
  // Costo de flete de transporte por sucursal.
  static const String preciosCostoFlete = '$_precios/costoFlete';
  static const String preciosProveedoresSap = '$_precios/lstProveedor';
  // Familias con su descripcion resuelta. El cuerpo es el filtro: los campos
  // que no viajan no filtran, pero un 0 SI filtra (no es lo mismo que ausente).
  static const String preciosFamilias = '$_precios/listFamilia';
  static const String preciosFamiliasPorGrupo = '$_precios/listFamiliaXGrupo';
  // Articulos de varias familias. El cuerpo lleva codCad: los codigos
  // separados por coma y con coma final ("12,13,14,").
  static const String preciosArticulosPorFamilias =
      '$_precios/listFamiliaXArticulo';
  static const String preciosCargarFamilia = '$_precios/cargarProducto';
  // Alta y edicion de una familia (tpr_producto). Exigen la pantalla Familias.
  static const String preciosFamiliaRegistrar = '$_precios/familia/registrar';
  static const String preciosFamiliaActualizar = '$_precios/familia/actualizar';
  // Las listas de precio activas con el porcentaje en 0: la grilla
  // "Porcentaje por familia" del alta.
  static const String preciosFamiliaListasParaPorcentaje =
      '$_precios/familia/listasParaPorcentaje';
  // Acciones de la fila, sin abrir la ficha. Exigen la pantalla Familias.
  static const String preciosFamiliaCambiarEstado =
      '$_precios/familia/cambiarEstado';
  static const String preciosFamiliaEliminar = '$_precios/familia/eliminar';
  static const String preciosFamiliaAsignarSap = '$_precios/familia/asignarSap';
  // Trae de SAP los proveedores y grupos de familia nuevos (p_abm_producto
  // 'H'). Exige la pantalla Familias o la de Catalogos.
  static const String preciosFamiliaSincronizarSap =
      '$_precios/familia/sincronizarSap';
  // Historial del costo de una familia (p_list_bitCostoProducto).
  static const String preciosFamiliaHistorialCosto =
      '$_precios/familia/historialCosto';
  static const String preciosPrecioTonPorFamilia =
      '$_precios/lstPrecioTonXFamilia';
  // La vista preliminar con las mismas filas que el PDF de la propuesta y los
  // precios por unidad del Excel. Reemplaza a lstArticulosXPropuesta.
  static const String preciosVistaPropuesta = '$_precios/vistaPropuesta';

  // --- Propuestas: escrituras ---
  // Las escrituras sueltas (registrarPropuesta, registrarCostoIncre,
  // registrarPrecioPropuesta, registrarCostoSug) se quitaron el 2026-09-25 junto con sus endpoints: ninguna pantalla las
  // usaba -todo pasa por el asistente- y en el servidor no pedian permiso.

  // --- Armado de una propuesta (asistente "Nueva propuesta") ---
  // Reemplaza a dlgNuevo, dlgProd, dlgVista y dlgArtD. El precio lo calcula
  // siempre el servidor: calcularFamilia es la vista previa y no escribe;
  // guardarFamilia vuelve a calcular y graba cabecera, fletes, precios y costo
  // en una sola transaccion. La propuesta nace con la primera familia (o el
  // primer articulo) que se guarda, como en el sistema anterior.
  static const String _preciosArmado = '$_precios/armado';
  static const String preciosArmadoFletes = '$_preciosArmado/fletes';
  static const String preciosArmadoFamilias = '$_preciosArmado/familias';
  static const String preciosArmadoCalcularFamilia =
      '$_preciosArmado/calcularFamilia';
  static const String preciosArmadoGuardarFamilia =
      '$_preciosArmado/guardarFamilia';
  // Carga en lote: varias familias, cada una con su costo. calcularFamilias no
  // escribe y dice por familia si se puede guardar; guardarFamilias graba todo
  // el pedido en una transaccion.
  static const String preciosArmadoCalcularFamilias =
      '$_preciosArmado/calcularFamilias';
  static const String preciosArmadoGuardarFamilias =
      '$_preciosArmado/guardarFamilias';
  // Cambiar un flete recalcula todas las familias de la propuesta.
  static const String preciosArmadoGuardarFletes =
      '$_preciosArmado/guardarFletes';
  static const String preciosArmadoArticulos = '$_preciosArmado/articulos';
  static const String preciosArmadoAgregarArticulos =
      '$_preciosArmado/agregarArticulos';
  static const String preciosArmadoQuitarArticulo =
      '$_preciosArmado/quitarArticulo';
  // Trae de SAP los articulos nuevos: puede tardar varios minutos.
  static const String preciosArmadoSincronizarArticulosSap =
      '$_preciosArmado/sincronizarArticulosSap';

  // Reportes PDF del modulo (reemplazan a los Jasper del JSF). Devuelven el PDF
  // crudo; un error de negocio llega como 400 con el JSON de siempre.
  static const String _preciosReporte = '$_precios/reporte';
  // Puede tardar: consulta en otro servidor los articulos no creados.
  static const String preciosReportePropuesta = '$_preciosReporte/propuesta';
  static const String preciosReportePreciosGrupo =
      '$_preciosReporte/preciosGrupo';
  static const String preciosReportePreciosTodas =
      '$_preciosReporte/preciosTodas';
  static const String preciosReporteFamiliasActivas =
      '$_preciosReporte/familiasActivas';

  // --- Circuito de autorizacion ---
  // resolverPropuesta es la operacion mas sensible del modulo: al aprobar, los
  // precios propuestos pasan a ser los precios de venta vigentes de toda la
  // empresa. El backend exige el boton btnAprobar y corre en una transaccion.
  static const String preciosResolverPropuesta = '$_precios/resolverPropuesta';
  static const String preciosMarcarEnEspera = '$_precios/marcarEnEspera';
  // Generar: devuelve CambioDePrecios.xlsx (bytes, como los PDF) y registra
  // quien lo genero. Exige btnGen y una propuesta aprobada.
  static const String preciosGenerarPropuesta = '$_precios/generarPropuesta';

  // --- Porcentajes por familia y lista de precios (tpr_porcentaje) ---
  // El margen que se aplica sobre el costo para calcular el precio de cada
  // familia en cada lista de precios: es parte del calculo y por eso cuelga de
  // /price y no de /price/catalogo. Reemplaza a los dialogos dlgPorcen y
  // dlgPorcGrupo de Autorizacion.xhtml.

  // La grilla de dlgPorcen: una fila por sucursal y lista de precios, con el
  // porcentaje vigente. Cuerpo: codigoFamilia. Las listas que la familia
  // todavia no tiene vuelven con idPorcen y porcentaje en 0: eso es un alta
  // pendiente, no un error.
  static const String preciosPorcentajePorFamilia =
      '$_precios/lstPorcentajeXFamilia';
  // La grilla de destinos de dlgPorcGrupo: las sucursales con sus listas de
  // precios activas, con el porcentaje en 0. Cuerpo: id = idGrpFamiliaSap.
  //
  // OJO: la grilla NO depende del grupo -el backend lista todas las
  // clasificaciones activas-, pero el id se exige igual porque sin el la
  // edicion masiva no tiene destino. Las familias afectadas salen de
  // preciosFamiliasPorGrupo. El backend tampoco ordena esta rama: el orden por
  // vpp y sucursal lo aplica la pantalla.
  static const String preciosPorcentajeParaGrupo =
      '$_precios/lstPorcentajeParaGrupo';
  // Listas de precios que todavia no tienen porcentaje para una familia.
  static const String preciosPorcentajeFaltante =
      '$_precios/lstPorcentajeFaltante';
  // Las filas crudas de tpr_porcentaje. A diferencia de la grilla no completa
  // las listas faltantes: devuelve solo lo que existe en la tabla.
  static const String preciosPorcentajeListar = '$_precios/lstPorcentaje';

  // Alta o modificacion de UNA fila por llamada, que es lo que soporta el
  // procedimiento: la grilla completa se guarda con una llamada por lista de
  // precios, igual que hacia actualizaPorcen() en el legacy.
  static const String preciosRegistrarPorcentaje =
      '$_precios/registrarPorcentaje';
  // La baja (eliminarPorcentaje) se quitaron el 2026-09-25 junto con sus endpoints: ninguna pantalla las
  // usaba -todo pasa por el asistente- y en el servidor no pedian permiso.

  // --- Catalogo: color (tpr_color) ---
  static const String preciosColorListar = '$_preciosCatalogo/color/listar';
  static const String preciosColorActivos = '$_preciosCatalogo/color/activos';
  static const String preciosColorRegistrar =
      '$_preciosCatalogo/color/registrar';
  static const String preciosColorEliminar = '$_preciosCatalogo/color/eliminar';

  // --- Catalogo: tipo de papel (tpr_tipo) ---
  static const String preciosTipoListar = '$_preciosCatalogo/tipo/listar';
  static const String preciosTipoActivos = '$_preciosCatalogo/tipo/activos';
  static const String preciosTipoRegistrar = '$_preciosCatalogo/tipo/registrar';
  static const String preciosTipoEliminar = '$_preciosCatalogo/tipo/eliminar';

  // --- Catalogo: presentacion (tpr_presentacion) ---
  static const String preciosPresentacionListar =
      '$_preciosCatalogo/presentacion/listar';
  static const String preciosPresentacionBuscar =
      '$_preciosCatalogo/presentacion/buscar';
  static const String preciosPresentacionActivas =
      '$_preciosCatalogo/presentacion/activas';
  static const String preciosPresentacionObtener =
      '$_preciosCatalogo/presentacion/obtener';
  static const String preciosPresentacionRegistrar =
      '$_preciosCatalogo/presentacion/registrar';
  static const String preciosPresentacionEliminar =
      '$_preciosCatalogo/presentacion/eliminar';

  // --- Catalogo: rango de gramaje (tpr_RangoGramaje) ---
  static const String preciosRangoGramajeListar =
      '$_preciosCatalogo/rango-gramaje/listar';
  static const String preciosRangoGramajeObtener =
      '$_preciosCatalogo/rango-gramaje/obtener';
  // Los mismos rangos con la etiqueta "[ min - max ]" ya armada por el backend.
  static const String preciosRangoGramajeCombo =
      '$_preciosCatalogo/rango-gramaje/combo';
  // Cuerpo: la clave natural (idGrpFamiliaSap, idTipo) de la tabla puente.
  static const String preciosRangoGramajePorGrupoFamiliaTipo =
      '$_preciosCatalogo/rango-gramaje/por-grupo-familia-tipo';
  static const String preciosRangoGramajeRegistrar =
      '$_preciosCatalogo/rango-gramaje/registrar';
  static const String preciosRangoGramajeEliminar =
      '$_preciosCatalogo/rango-gramaje/eliminar';

  // --- Catalogo: grupo de familia SAP (tpr_grupoFamiliaSap) ---
  static const String preciosGrupoFamiliaSapListar =
      '$_preciosCatalogo/grupo-familia-sap/listar';
  // Devuelve una lista de una sola fila, no un objeto.
  static const String preciosGrupoFamiliaSapObtener =
      '$_preciosCatalogo/grupo-familia-sap/obtener';
  static const String preciosGrupoFamiliaSapBuscar =
      '$_preciosCatalogo/grupo-familia-sap/buscar';
  static const String preciosGrupoFamiliaSapRegistrar =
      '$_preciosCatalogo/grupo-familia-sap/registrar';
  static const String preciosGrupoFamiliaSapEliminar =
      '$_preciosCatalogo/grupo-familia-sap/eliminar';

  // --- Catalogo: proveedor externo SAP (tpr_proveedorExtSap) ---
  static const String preciosProveedorSapListar =
      '$_preciosCatalogo/proveedor-sap/listar';
  static const String preciosProveedorSapBuscar =
      '$_preciosCatalogo/proveedor-sap/buscar';
  static const String preciosProveedorSapObtener =
      '$_preciosCatalogo/proveedor-sap/obtener';
  static const String preciosProveedorSapRegistrar =
      '$_preciosCatalogo/proveedor-sap/registrar';
  static const String preciosProveedorSapEliminar =
      '$_preciosCatalogo/proveedor-sap/eliminar';

  // --- Catalogo: parametros de gramaje (tpr_grupoFamTipoRangoGram) ---
  // La tabla es un HEAP: no tiene PK ni IDENTITY. La fila se identifica por su
  // clave natural (idGrpFamiliaSap, idTipo) y el alta siempre devuelve id 0.
  static const String preciosGrupoFamTipoRangoListar =
      '$_preciosCatalogo/grupo-fam-tipo-rango/listar';
  static const String preciosGrupoFamTipoRangoPorGrupoFamilia =
      '$_preciosCatalogo/grupo-fam-tipo-rango/por-grupo-familia';
  static const String preciosGrupoFamTipoRangoObtener =
      '$_preciosCatalogo/grupo-fam-tipo-rango/obtener';
  // La tabla pivoteada: un renglon por grupo de familia con sus columnas
  // Liviano / Mediano / Pesado.
  static const String preciosGrupoFamTipoRangoParametros =
      '$_preciosCatalogo/grupo-fam-tipo-rango/parametros-gramaje';
  static const String preciosGrupoFamTipoRangoRegistrar =
      '$_preciosCatalogo/grupo-fam-tipo-rango/registrar';
  static const String preciosGrupoFamTipoRangoEliminar =
      '$_preciosCatalogo/grupo-fam-tipo-rango/eliminar';

  // --- Catalogo: listas de precios (tpr_clasificacionPrecio) ---
  static const String preciosClasificacionListar =
      '$_preciosCatalogo/clasificacion-precio/listar';
  static const String preciosClasificacionConSucursal =
      '$_preciosCatalogo/clasificacion-precio/con-sucursal';
  // Devuelve una lista de enteros crudos, no de objetos.
  static const String preciosClasificacionVpps =
      '$_preciosCatalogo/clasificacion-precio/vpps';
  // Devuelve un booleano crudo y siempre 200: que el vpp exista no es un error.
  static const String preciosClasificacionExisteVpp =
      '$_preciosCatalogo/clasificacion-precio/existe-vpp';
  static const String preciosClasificacionRegistrar =
      '$_preciosCatalogo/clasificacion-precio/registrar';
  static const String preciosClasificacionCambiarEstado =
      '$_preciosCatalogo/clasificacion-precio/cambiar-estado';
  static const String preciosClasificacionEliminar =
      '$_preciosCatalogo/clasificacion-precio/eliminar';

  // --- Catalogo: IVA / IT (tpr_costoIvaIt, singleton) ---
  static const String preciosCostoIvaItListar =
      '$_preciosCatalogo/costo-iva-it/listar';
  // La fila vigente, con totalIvaIt ya sumado por el backend.
  static const String preciosCostoIvaItVigente =
      '$_preciosCatalogo/costo-iva-it/vigente';
  static const String preciosCostoIvaItPorPropuesta =
      '$_preciosCatalogo/costo-iva-it/por-propuesta';
  // El backend prefiere actualizar antes que insertar: la tabla tiene que
  // quedarse en una sola fila porque los calculos la leen con SELECT TOP 1
  // sin ORDER BY.
  static const String preciosCostoIvaItRegistrar =
      '$_preciosCatalogo/costo-iva-it/registrar';

  // --- Catalogo: ancla del tipo de cambio (tpr_tcAncla) ---
  // SOLO LECTURA a proposito: la configuracion del reprecio nocturno la maneja
  // un job externo y escribirla desde la aplicacion lo descalibraria.
  static const String preciosTcAnclaListar =
      '$_preciosCatalogo/tc-ancla/listar';
  static const String preciosTcAnclaObtener =
      '$_preciosCatalogo/tc-ancla/obtener';

  // ==================== PRECIOS (tpr): direcciones de pantalla ============
  // La `direccion` de tb_vista, TAL CUAL esta en la base: el sidebar arma el
  // destino como '/' + direccion, y el router registra la misma cadena bajo
  // '/dashboard/'. Por eso viven aca y no sueltas en router.dart.
  //
  // La primera es la del modulo legacy (codVista 66, padre 65 'Cambio de
  // Precios'): se conserva exacta para reemplazar la pantalla JSF sin tocar
  // el menu ni los permisos que los usuarios ya tienen.
  static const String rutaPreciosPropuestas = 'tprAutorizacion/Autorizacion';
  // Las seis siguientes son pantallas nuevas, cuelgan del mismo padre 65.
  // Hubo una septima, 'tprPropuestaDetalle/Detalle' (Detalle de Propuesta):
  // se quito el 2026-09-25 porque desde el menu se abria vacia; el detalle se
  // ve con la vista preliminar del listado. Su baja en tb_vista esta en
  // sql/tpr_99b_quitar_detalle_propuesta.sql del directorio de la migracion.
  static const String rutaPreciosFamilias = 'tprFamilias/Familias';
  static const String rutaPreciosPrecios = 'tprPrecios/Precios';
  static const String rutaPreciosListas = 'tprListasPrecio/Listas';
  static const String rutaPreciosCatalogos = 'tprCatalogos/Catalogos';
  static const String rutaPreciosParametros = 'tprParametros/Parametros';
  // Porcentajes por familia y lista de precios (tpr_porcentaje). Reemplaza a
  // los dialogos dlgPorcen y dlgPorcGrupo de la pantalla legacy.
  static const String rutaPreciosPorcentajes = 'tprPorcentajes/Porcentajes';

  // ==================== GARANTIAS DE COBRANZA (tcbr) ======================
  // Contrato: API_GARANTIAS.md del proyecto de migracion. Todos POST, tambien
  // las lecturas. Las escrituras y los PDF exigen ademas el boton de la vista
  // 45 que corresponde; el backend responde 403 sin el.
  static const String _garantias = '/garantias';

  // --- Lecturas ---
  static const String garantiasResumenClientes = '$_garantias/resumen-clientes';
  static const String garantiasListar = '$_garantias/listar';
  static const String garantiasObtener = '$_garantias/obtener';
  // Minimo 3 caracteres; devuelve hasta 50 clientes.
  static const String garantiasClientesSap = '$_garantias/clientes-sap';
  static const String garantiasDetalles = '$_garantias/detalles';
  static const String garantiasAcciones = '$_garantias/acciones';
  static const String garantiasTraspasosPendientes =
      '$_garantias/traspasos-pendientes';
  static const String garantiasTiposGarantia = '$_garantias/tipos-garantia';
  static const String garantiasEstadosAccion = '$_garantias/estados-accion';

  // --- Escrituras (201, data = id; en /traspaso, data = cantidad) ---
  static const String garantiasRegistrar = '$_garantias/registrar';
  static const String garantiasActualizar = '$_garantias/actualizar';
  static const String garantiasExtension = '$_garantias/extension';
  static const String garantiasDetalleRegistrar =
      '$_garantias/detalle/registrar';
  static const String garantiasDetalleEliminar = '$_garantias/detalle/eliminar';
  static const String garantiasAccionRegistrar = '$_garantias/accion/registrar';
  static const String garantiasAccionEliminar = '$_garantias/accion/eliminar';
  static const String garantiasTraspaso = '$_garantias/traspaso';

  // --- Reportes: application/pdf en bytes crudos. Se bajan con
  // DioClient.descargarReportePdf, no con BaseApiRepository.postAndReturn*.
  static const String garantiasReporteRecibo = '$_garantias/reporte/recibo';
  static const String garantiasReporteTraspaso = '$_garantias/reporte/traspaso';
  static const String garantiasReporteBusqueda = '$_garantias/reporte/busqueda';

  // --- Direccion de pantalla ---
  // tb_vista codVista 45, TAL CUAL esta en la base (padre 44 'Cobranza'): la
  // misma direccion de la pantalla JSF, asi el item de menu y los permisos
  // que los usuarios ya tienen siguen sirviendo sin tocar tb_vista.
  static const String rutaGarantias = 'tcbrGarantia/garantia';

  // ========================= CHEQUES (tch) ===============================
  // Contrato: API_CHEQUES.md del proyecto de migracion. Todos POST, tambien
  // las lecturas. El usuario de auditoria sale del token: nunca se manda
  // audUsuario. Los botones de la vista 42 los exige el servidor (403 sin
  // ellos); la pantalla solo los usa para dibujar. Un 400 trae el mensaje de
  // negocio en message, varios errores separados por salto de linea.
  static const String _cheque = '/cheque';

  // --- Apoyo y catalogos ---
  static const String chqCatalogos = '$_cheque/catalogos';
  // Sin cuerpo. Las empresas del combo «Empresa» de la pantalla (hoy IMPEXPAP
  // y ESPPAPEL), ordenadas por codEmpresa. De ahi salen sucursales, clientes y
  // la empresa del cheque nuevo: NUNCA la empresa de la sesion de login.
  static const String chqEmpresas = '$_cheque/empresas';
  // Cuerpo opcional {id: codEmpresa}. data = long; 0 = el usuario no tiene
  // sucursal en esa empresa.
  static const String chqSucursalInicial = '$_cheque/sucursal-inicial';
  // Cuerpo {id: codEmpresa}: las sucursales de esa empresa que el usuario puede
  // ver.
  static const String chqSucursales = '$_cheque/sucursales';
  // Cuerpo {id: codEmpresa}.
  static const String chqClientes = '$_cheque/clientes';
  // Sin cuerpo. «Actualizar datos SAP»: trae los clientes nuevos de SAP (las
  // cuatro empresas a la vez). Exige btnNuevoCH. 201, data = cuantos clientes
  // nuevos; message = la frase para el usuario.
  static const String chqActualizarClientesSap =
      '$_cheque/clientes/actualizar-sap';
  // Cuerpo {id: codSucursal}.
  static const String chqPersonalEntregan = '$_cheque/personal/entregan';
  static const String chqPersonalCustodia = '$_cheque/personal/custodia';

  // --- Cheques ---
  static const String chqListar = '$_cheque/listar';
  // Cuerpo {id: codCheque}. Exige btnDetalleCH.
  static const String chqDetalle = '$_cheque/detalle';
  // 201, data = codCheque.
  static const String chqRegistrar = '$_cheque/registrar';
  // Solo consulta, no escribe ni necesita sucursal. Cuerpo {codEmpresa,
  // nroTalonario, reciboManual}; data = {valido, mensaje?, detalle?}. Un par
  // incorrecto es valido=false con el motivo en mensaje (200, no 400); el 400
  // es solo para una empresa ausente o que no figura en /cheque/empresas.
  static const String chqTalonarioValidar = '$_cheque/talonario/validar';

  // --- Acciones del detalle (201, data = codAccion) ---
  static const String chqAccionFechaCobro = '$_cheque/accion/fecha-cobro';
  static const String chqAccionDevolver = '$_cheque/accion/devolver';
  static const String chqAccionCerrar = '$_cheque/accion/cerrar';
  // Cuerpo {id: codAccion}. Exige btnEliminarSegCH.
  static const String chqAccionEliminar = '$_cheque/accion/eliminar';

  // --- Traspaso y custodia. Cuerpo {id: codSucursal} salvo donde se indica ---
  static const String chqTraspasoPendientes = '$_cheque/traspaso/pendientes';
  // 201, data = cuantos se traspasaron (400 si ninguno).
  static const String chqTraspaso = '$_cheque/traspaso';
  static const String chqCustodiaCheques = '$_cheque/custodia/cheques';
  // Cuerpo CustodiaChequeRequest. 201, data = cuantos.
  static const String chqCustodia = '$_cheque/custodia';
  static const String chqDarCustodiaCheques = '$_cheque/dar-custodia/cheques';
  // Cuerpo {codSucursal, fecha}.
  static const String chqDarCustodiaEntregas =
      '$_cheque/dar-custodia/entregas';
  // Cuerpo DarCustodiaRequest. 201, data = codAccion nuevo.
  static const String chqDarCustodia = '$_cheque/dar-custodia';

  // --- Reportes: application/pdf en bytes crudos. Se bajan con
  // DioClient.descargarReportePdf, no con BaseApiRepository.postAndReturn*; un
  // error de negocio o de permiso llega como JSON y ese metodo rescata su
  // mensaje. Todos piden codEmpresa y codSucursal, y los dos salen de la
  // pantalla (empresa activa del combo y sucursal de la grilla), nunca del
  // login. Las fechas viajan yyyy-MM-dd y las claves opcionales se omiten. ---
  // {codEmpresa, codSucursal, fechaDesde?, fechaHasta?}. Exige btnRpt1CH.
  static const String chqReporteRecibidos = '$_cheque/reporte/recibidos';
  // {codEmpresa, codSucursal, fechaDesde?, fechaHasta?, estado?, codCliente?}.
  // Exige btnRpt2CH.
  static const String chqReporteCobranzas = '$_cheque/reporte/cobranzas';
  // {codEmpresa, codSucursal, fecha?, codEmpleado?}. Exige btnRpt3CH.
  static const String chqReporteCustodio = '$_cheque/reporte/custodio';
  // {codEmpresa, codSucursal}: el ultimo cheque que registro ESTE usuario en la
  // sucursal (400 si no hay). Exige btnRpt4CH.
  static const String chqReporteUltimoRecibo = '$_cheque/reporte/ultimo-recibo';
  // {codEmpresa, codSucursal}: la nomina del ultimo traspaso. Exige
  // btnTraspasoCH.
  static const String chqReporteTraspaso = '$_cheque/reporte/traspaso';
  // {codEmpresa, codSucursal, codAccion}. Exige btnRpt5CH.
  static const String chqReporteReimpresionTraspaso =
      '$_cheque/reporte/reimpresion-traspaso';
  // Esta NO es un PDF: cuerpo {codSucursal, fecha}, data = [{codAccion, hora}]
  // con los traspasos de ese dia (204 = ninguno). Exige btnRpt5CH.
  static const String chqTraspasoHoras = '$_cheque/traspaso/horas';

  // --- Documento PDF del cheque. Un PDF por cheque y sin boton de ACL: como en
  // el legacy lo ve y lo usa cualquiera que vea la fila. El servidor lo guarda
  // como <codCheque>.pdf y lo baja como <codCheque>_.pdf. ---
  // Cuerpo {codCheque}. data = {existe, nombreArchivo, tamanoBytes?,
  // fechaModificacion?}.
  static const String chqPdfEstado = '$_cheque/pdf/estado';
  // multipart/form-data: parte de texto codCheque y el archivo en la parte
  // archivo. data = {nombreArchivo, tamanoBytes, reemplazo}. Un PDF nuevo
  // reemplaza al anterior.
  static const String chqPdfSubir = '$_cheque/pdf/subir';
  // Cuerpo {codCheque}. Responde application/pdf en bytes crudos (se baja con
  // DioClient.descargarReportePdf); sin archivo, un error con su mensaje.
  static const String chqPdfDescargar = '$_cheque/pdf/descargar';

  // --- Paneles del detalle: notas de remision, transacciones bancarias y
  // postergaciones. Seccion «Paneles del detalle» de API_CHEQUES.md. Listar,
  // registrar y eliminar de cada una. Leer no pide boton (basta ver la sucursal
  // del cheque). Registrar pide btnNuevoNRCH en las tres y eliminar una nota,
  // btnEliminarNRCH; eliminar una transaccion o una postergacion y todo el PDF
  // de la postergacion no tienen boton, como en el legacy. ---
  // Cuerpo {codCheque}. data = [{fila, codCheque, notaRemision, nroFactura,
  // fechaFactura, audUsuario, audFecha}].
  static const String chqNotaRemisionListar = '$_cheque/nota-remision/listar';
  // Cuerpo {codCheque, notaRemision, nroFactura, fechaFactura}. 201, data = 1.
  static const String chqNotaRemisionRegistrar =
      '$_cheque/nota-remision/registrar';
  // Cuerpo {codCheque, notaRemision}. 201, data = cuantas filas elimino (si la
  // nota estaba repetida, todas, como el legacy).
  static const String chqNotaRemisionEliminar =
      '$_cheque/nota-remision/eliminar';
  // Cuerpo {codCheque}. data = [{fila, codCheque, nroTransaccion, codBanco,
  // fechaTransaccion, datoBanco}].
  static const String chqTransaccionListar = '$_cheque/transaccion/listar';
  // Cuerpo {codCheque, nroTransaccion, codBanco, fechaTransaccion}. 201, data = 1.
  static const String chqTransaccionRegistrar =
      '$_cheque/transaccion/registrar';
  // Cuerpo {codCheque, nroTransaccion}. 201, data = filas eliminadas.
  static const String chqTransaccionEliminar = '$_cheque/transaccion/eliminar';
  // Cuerpo {codCheque}. data = [{fila, codPostergacion, codCheque, fecha,
  // observacion, nombreArchivo, audUsuario, audFecha, tienePdf}]; tienePdf es
  // true, false o null (la carpeta de PDF del servidor no esta disponible).
  static const String chqPostergacionListar = '$_cheque/postergacion/listar';
  // Cuerpo {codCheque, fecha, observacion}. 201, data = codPostergacion.
  static const String chqPostergacionRegistrar =
      '$_cheque/postergacion/registrar';
  // Cuerpo {codCheque, codPostergacion}: la postergacion tiene que ser de ese
  // cheque. 201, data = codPostergacion. No borra el PDF.
  static const String chqPostergacionEliminar =
      '$_cheque/postergacion/eliminar';
  // Cuerpo {codPostergacion}. data = {existe, nombreArchivo, tamanoBytes?,
  // fechaModificacion?}, la misma forma que chqPdfEstado.
  static const String chqPostergacionPdfEstado =
      '$_cheque/postergacion/pdf/estado';
  // multipart/form-data: parte de texto codPostergacion y el archivo en la
  // parte archivo. data = {nombreArchivo, tamanoBytes, reemplazo}.
  static const String chqPostergacionPdfSubir =
      '$_cheque/postergacion/pdf/subir';
  // Cuerpo {codPostergacion}. Responde application/pdf en bytes crudos; sin
  // archivo, un error con su mensaje. Se baja como Posterg_<cod>_.pdf.
  static const String chqPostergacionPdfDescargar =
      '$_cheque/postergacion/pdf/descargar';

  // --- Verificar cheques (vista 77). Sin boton de ACL: el servidor exige solo
  // el rol. Contrato: seccion «Verificar Cheques» de API_CHEQUES.md. ---
  // Cuerpo {fechaBanco?, pagina, tamanio}. data = {total, pagina, tamanio,
  // filas}: las verificaciones, paginadas por el servidor.
  static const String chqVerificacionListar = '$_cheque/verificacion/listar';
  // Cuerpo {estado?, soloCobranzaHoy?, pagina, tamanio}. El modal «Cheques
  // pendientes sin regularizar». Misma forma de pagina.
  static const String chqVerificacionPendientes =
      '$_cheque/verificacion/pendientes';
  // Cuerpo {id: codCheque}. data = {cheque, fechaBanco}; 400 si el cheque ya
  // tiene una verificacion valida o esta cerrado.
  static const String chqVerificacionPreparar =
      '$_cheque/verificacion/preparar';
  // Cuerpo {codvd, codCheque, codBanco, fechaBanco, observacion}. 201, data =
  // codvd. codvd 0 = alta.
  static const String chqVerificacionRegistrar =
      '$_cheque/verificacion/registrar';
  // Cuerpo {id: codvd}. 201, data = codvd, y el message dice si ya estaba
  // anulada. No borra: pasa la verificacion a Anulada.
  static const String chqVerificacionAnular = '$_cheque/verificacion/anular';

  // --- Direccion de pantalla ---
  // tb_vista codVista 42, TAL CUAL esta en la base (padre 41 'modCheques'): la
  // misma direccion de la pantalla JSF, asi el item de menu y los permisos que
  // los usuarios ya tienen siguen sirviendo sin tocar tb_vista.
  static const String rutaCheques = 'tchCheque/cheque';

  // tb_vista codVista 43 (padre 140), tal cual esta en la base: la pantalla de
  // Bancos del JSF viejo. Mismo motivo que la de arriba.
  static const String rutaBancos = 'tchBanco/banco';

  // tb_vista codVista 77 (padre 41 'modCheques'), tal cual esta en la base: la
  // pantalla «Verificar Cheques» del JSF viejo (verificarDepositos.xhtml). No
  // tiene botones en tb_vistaBtn: el menu decide quien la ve.
  static const String rutaVerificarCheques = 'tchCheque/verificarDepositos';
}
