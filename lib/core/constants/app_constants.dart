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
  static const String entregasEndpoint = '/entregas/chofer-entrega';
  static const String marcarEntregaCompletada =
      '/entregas/registro-entrega-chofer';
  static const String inicioEntregaYFinEndpoint =
      '/entregas/registro-inicio-fin-entrega';
  static const String rutaChoferEndpoint = '/entregas/entregas-fecha';
  static const String choferesEndPoint = '/entregas/choferes';
  static const String entregasRutasChoferes = '/entregas/extracto';
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
  static const String rrhhGetCuentaBancoXEmpleado =
      '/rrhh/obtenerNroCuentaBanco';
  static const String rrhhRegistrarCuentaBancaria = '/rrhh/registroCuentaBanco';
  static const String rrhhEliminarCuentaBancaria =
      '/rrhh/eliminarCuentaBancaria';
  static const String rrhhTipoRealacionLaboral = '/rrhh/tipoRelacionLaboral';
  static const String pdfRptNominaEmpleados = '/rrhh/pdfNominaEmpleados';
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO DE PAGOS AL EXTRANJERO
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String guardarSolicitudCompleta =
      '/pagos-extranjeros/guardar-solicitud-completa';
  static const String lstProveedoresXEmpresa =
      '/pagos-extranjeros/obtener-proveedores-empresa';
  static const String lstFacProvYOrdCompra =
      '/pagos-extranjeros/obtener-docnum-empresa';

  static const String lstSolPagosRegistrados =
      '/pagos-extranjeros/reporte-solicitudes-fechas';

  // ── TPEX: escrituras ACID ──────────────────────────────────────────────────
  static const String tpexAprobarSolicitud =
      '/pagos-extranjeros/aprobar-solicitud';
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // RUTAS MODULO: PERMISOS / VACACION
  // ═══════════════════════════════════════════════════════════════════════════════
  static const String vacDiasDisponibles = '/vacacion/diasDisponibles';

  // ── TPROD: Lote de Produccion ────────────────────────────────────────────────────────────

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
