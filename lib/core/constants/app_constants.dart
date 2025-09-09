class AppConstants {
  //static const String baseUrl = 'https://app.esppapel.com:8443';
  static const String baseUrl = 'http://192.168.3.107:9223';

  static const String APP_VERSION = "1.0.0";

  static const String loginEndpoint = '/auth/login';
  static const String menuEndpoint = '/view/vistaDinamica';
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
  static const String listarBidonesPendientes =
      '/gasolinaMaquina/lstBidonesPendientes';
  static const String listarDetalleBidon = '/gasolinaMaquina/lstDetalleBidon';

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
  static const String perObtenerRelacionLaboral = '/rrhh/fechasBeneficio';
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
