class AppConstants {
  //static const String baseUrl = 'https://app.esppapel.com:8443';
  static const String baseUrl = 'http://192.168.3.107:9223';
  
  static const String APP_VERSION = "1.0.0";

  static const String loginEndpoint = '/auth/login';
  static const String menuEndpoint = '/view/vistaDinamica';
  static const String articulosEndpoint = '/paginaXApp/articulosX';
  static const String articulosAlmacenEndpoint = '/paginaXApp/articulosXAlmacen';
  static const String entregasEndpoint = '/entregas/chofer-entrega';
  static const String marcarEntregaCompletada = '/entregas/registro-entrega-chofer';
  static const String inicioEntregaYFinEndpoint = '/entregas/registro-inicio-fin-entrega';
  static const String rutaChoferEndpoint = '/entregas/entregas-fecha';
  static const String choferesEndPoint = '/entregas/choferes';
  static const String entregasRutasChoferes = '/entregas/extracto';
  static const String usuariosEndPoint = '/auth/lstUsers';
  static const String changePasswordEndPoint = '/auth/changePasswordDefault';
  static const String registrarCombustibleEndPoint = '/gasolina/registrar-gasolina';
  static const String listarCoches = '/gasolina/lst-coches';
  static const String listarKilometrajeCoches = '/gasolina/lst-kilometraje';
  static const String listar = '/gasolina/lst-combustibles';
  static const String listarObtenerConsumo = '/gasolina/obtenerConsumo';


  
  //Endpoints para la gestion de bidones
  static const String registrarControlCombustibleMaqMont = '/gasolinaMaquina/registrarMaquina';
  static const String listarAlmacenes = '/gasolinaMaquina/lst-almacenes';
  static const String listarMaquinaMontacarga = '/gasolinaMaquina/lst-maqmontacarga';
  static const String listarBidones = '/gasolinaMaquina/lstMovBidones';
  static const String listarBidonesXSucursales = '/gasolinaMaquina/lstSaldosBidones';
  static const String listarUltimosMovBidones = '/gasolinaMaquina/lstUltimoMovBidones';
  static const String listarBidonesPendientes = '/gasolinaMaquina/lstBidonesPendientes';
  

  // Endpoints para la gestión de depósitos de cheques
  static const String deplstEmpresas = '/deposito-cheque/lst-empresas';
  static const String deplstSocioNegocio = '/deposito-cheque/lst-socios-negocio';
  static const String deplstBancos = '/deposito-cheque/lst-banco';
  static const String deplstNotaRemision = '/deposito-cheque/lst-notaRemision';
  static const String depRegister = '/deposito-cheque/registro';
  static const String depRegisterNotaRemision = '/deposito-cheque/registrar-nota-remision';
  static const String depListarDepositos = '/deposito-cheque/listar';
  static const String depListDepositosIde = '/deposito-cheque/listar-dep-identificar';
  static const String depGenPdfDeposito = '/deposito-cheque/pdf/';
  static const String depObtImagen = '/deposito-cheque/descargar/';
  static const String depActualizarNotaRemision = '/deposito-cheque/registrar-nroTransaccion';
  static const String depRechazarNotaRemision = '/deposito-cheque/rechazar-deposito';

  // Endpoints para el prestamos de vehículos
  static const String preRegister = '/prestamo-coches/registroSolicitud';
  static const String preTipoSolicitudes = '/prestamo-coches/tipoSolicitudes';
  static const String preCoches = '/prestamo-coches/coches';
  static const String preSolicitudesXEmp = '/prestamo-coches/solicitudes';
  static const String preListarSolicitudesPrestamos = '/prestamo-coches/solicitudesPrestamo';
  static const String preEstados = '/prestamo-coches/estados';
  static const String preRegistrarPrestamo= '/prestamo-coches/registroPrestamo';
  static const String preActualizarSolicitud = '/prestamo-coches/actualizarSolicitud';




  //Para cargar permisos de botones por usuario
  static const String ubtnPermisosBotones = '/view/vistaBtn';




  // Constantes para el servicio de geocodificación de Nominatim
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimReverseEndpoint = '/reverse';
  static const String nominatimUserAgent = 'Bosque';

  // Constante para Google Maps Search
  static const String googleMapsSearchBaseUrl = 'https://www.google.com/maps/search/?api=1&query';
  static const String googleMapsOpenStreetMaps = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
}