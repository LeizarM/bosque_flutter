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
  static const String reporteResmadoPdf =
      '/loteProduccion/reporte-resmado-pdf';

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
  /// vive dentro del `.jrxml`, no acá: son dos rutas y no un parámetro.
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
}
