import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';

/// Reglas de visibilidad del modulo de cheques: que ve y que habilita cada
/// usuario. Es logica pura, sin Flutter ni Riverpod.
///
/// Reproducen la tabla «Condiciones por componente» de `cheque.xhtml`
/// (`WizardCheque.esAutorizado*`). **Son solo para dibujar**: el servidor repite
/// cada regla y responde 403 o 400 si la pantalla se equivoca.
///
/// **De donde sale cada dato.** Los botones salen de `buttonPermissionsProvider`
/// (la lista de `tb_usuarioBtn` que carga el login, filtrada por `permiso != 0`)
/// y el «es administrador» de `userProvider`: `LoginEntity.tipoUsuario ==
/// 'ROLE_ADM'`, la misma comprobacion de `tienePermisoDeBoton` y del fallback de
/// `Loggin.autorizarBtn()` del ERP viejo. `permisosChequeProvider`
/// (`core/state/cheques_provider.dart`) arma esta clase con las dos fuentes.
///
/// **El administrador pasa siempre**, tambien con el cheque CER y aunque el boton
/// no figure en su ACL. Las variantes con estado ocultan el boton de un cheque
/// cerrado a todos los demas.
///
/// Las cuatro acciones del detalle (Fecha Cobro, Devolver, Cerrar con y sin
/// verificacion) **no se calculan aqui**: las da el backend en `botones`
/// (`BotonesChequeEntity`, rama K).
class PermisosCheque {
  // ── Botones de la vista 42 (tb_vistaBtn) ─────────────────────────────────
  static const String btnNuevo = 'btnNuevoCH';
  static const String btnNuevoAdmin = 'btnNuevo2CH';
  static const String btnEditar = 'btnEditar1CH';
  static const String btnFechaCobro = 'btnEditar2CH';
  static const String btnEditarAdmin = 'btnEditar3CH';
  static const String btnDetalle = 'btnDetalleCH';
  static const String btnEliminarAccion = 'btnEliminarSegCH';
  static const String btnTraspaso = 'btnTraspasoCH';
  static const String btnCustodia = 'btnCustodiaCH';
  static const String btnDarCustodia = 'btnCustodia2CH';
  static const String btnSucursales = 'btnChqSucrs';

  // Paneles del detalle. `btnNuevoNRCH` gobierna el «Nuevo» de los tres (nota
  // de remision, transaccion bancaria y postergacion) y `btnEliminarNRCH` solo
  // el eliminar de la nota de remision.
  static const String btnNuevoPanel = 'btnNuevoNRCH';
  static const String btnEliminarNota = 'btnEliminarNRCH';

  // Reportes en PDF. En el legacy: «Reporte» (1), «Reporte Cheques» (2),
  // «Reporte Custodio» (3), «Recibo del Ultimo Cheque» (4) e «Imp Traspso» (5).
  static const String btnReporteRecibidos = 'btnRpt1CH';
  static const String btnReporteCobranzas = 'btnRpt2CH';
  static const String btnReporteCustodio = 'btnRpt3CH';
  static const String btnReciboUltimoCheque = 'btnRpt4CH';
  static const String btnReimprimirTraspaso = 'btnRpt5CH';

  // ── Botones de la vista 43 (bancos) ──────────────────────────────────────
  static const String btnNuevoBanco = 'btnNuevoB';
  static const String btnEditarBanco = 'btnEditarB';
  static const String btnEliminarBanco = 'btnEliminarB';

  /// Estado del cheque cerrado, el unico que cambia lo que se ve.
  static const String estadoCerrado = 'CER';

  /// Nombres de los botones a los que el usuario tiene acceso.
  final Set<String> botones;

  /// `tipoUsuario == 'ROLE_ADM'`.
  final bool esAdmin;

  const PermisosCheque({required this.botones, required this.esAdmin});

  /// Sin ningun boton y sin ser administrador: lo que se ve mientras llegan los
  /// permisos o si no hay sesion.
  static const PermisosCheque ninguno = PermisosCheque(
    botones: <String>{},
    esAdmin: false,
  );

  /// Arma los permisos con las dos fuentes del frontend: el `tipoUsuario` del
  /// usuario y su lista de botones. Un boton cuenta si `permiso != 0`, la
  /// condicion literal de `Loggin.autorizarBtn()`.
  factory PermisosCheque.desde({
    required String? tipoUsuario,
    required Iterable<UsuarioBtnEntity> botones,
  }) => PermisosCheque(
    botones: {
      for (final b in botones)
        if (b.permiso != 0) b.boton,
    },
    esAdmin: tipoUsuario == 'ROLE_ADM',
  );

  /// El ACL del boton, con el fallback del administrador.
  bool tiene(String boton) => esAdmin || botones.contains(boton);

  /// El cheque esta cerrado (`CER`). Tolera espacios y nulo, como el legacy.
  static bool estaCerrado(String? estado) =>
      (estado ?? '').trim() == estadoCerrado;

  // ── Barra superior ───────────────────────────────────────────────────────

  /// Alta con el formulario estandar (`btnNuevoCH`).
  bool get puedeRegistrar => tiene(btnNuevo);

  /// Alta con el formulario de administrador (`btnNuevo2CH`).
  bool get puedeRegistrarComoAdmin => tiene(btnNuevoAdmin);

  /// Hay un «Registrar» que ofrecer: la barra tiene un solo boton y alcanza con
  /// cualquiera de los dos permisos de alta.
  bool get puedeVerRegistrar => puedeRegistrar || puedeRegistrarComoAdmin;

  /// Con que formulario abre el «Registrar» unico: el de administrador si el
  /// usuario tiene `btnNuevo2CH` (el administrador siempre), con la fecha de
  /// cobro editable de entrada; si no, el estandar. El servidor exige el boton
  /// de cada modo, asi que el modo elegido nunca pide mas de lo que se tiene.
  ModoRegistroCheque get modoDeRegistro =>
      puedeRegistrarComoAdmin
          ? ModoRegistroCheque.admin
          : ModoRegistroCheque.estandar;

  /// Traspaso masivo a cobranza.
  bool get puedeTraspasar => tiene(btnTraspaso);

  /// «A Custodio».
  bool get puedeEntregarACustodia => tiene(btnCustodia);

  /// «Dar Custodia» (administrador).
  bool get puedeDarCustodia => tiene(btnDarCustodia);

  /// El combo de sucursal solo se habilita con este boton; sin el, el usuario
  /// trabaja en su sucursal inicial.
  bool get puedeElegirSucursal => tiene(btnSucursales);

  /// «Actualizar datos SAP»: traer los clientes nuevos de SAP. El legacy lo
  /// evalua con `esAutorizado('btnNuevoCH')`, el boton de «Registrar»; **solo
  /// ese**: `btnNuevo2CH` no alcanza, y es lo que exige el servidor. Tampoco
  /// depende de la sucursal ni de la empresa: el servidor trae todas.
  bool get puedeActualizarDatosSap => tiene(btnNuevo);

  // ── Reportes en PDF (barra superior) ─────────────────────────────────────
  //
  // Como el resto de la barra, dependen solo del ACL del boton, no del
  // registro. La nomina del traspaso no tiene boton propio: la gobierna
  // `puedeTraspasar`.

  /// «Reporte»: cheques recibidos en caja.
  bool get puedeReporteRecibidos => tiene(btnReporteRecibidos);

  /// «Reporte Cheques»: cheques de cobranza.
  bool get puedeReporteCobranzas => tiene(btnReporteCobranzas);

  /// «Reporte Custodio»: cheques en custodia.
  bool get puedeReporteCustodio => tiene(btnReporteCustodio);

  /// «Recibo del Ultimo Cheque».
  bool get puedeReciboUltimoCheque => tiene(btnReciboUltimoCheque);

  /// «Imp Traspso»: reimprimir un traspaso anterior.
  bool get puedeReimprimirTraspaso => tiene(btnReimprimirTraspaso);

  /// Hay al menos un reporte que ofrecer: si no, la barra no dibuja nada.
  bool get puedeVerReportes =>
      puedeReporteRecibidos ||
      puedeReporteCobranzas ||
      puedeReporteCustodio ||
      puedeReciboUltimoCheque ||
      puedeReimprimirTraspaso;

  // ── Fila de la grilla (dependen del estado del cheque) ───────────────────

  /// Editar un cheque abierto: `btnEditar1CH` y estado distinto de CER.
  bool puedeEditar(String? estado) =>
      esAdmin || (botones.contains(btnEditar) && !estaCerrado(estado));

  /// Editar solo el talonario y el recibo de un cheque cerrado: `btnEditar1CH`
  /// y estado CER. El administrador tambien pasa, pero la pantalla le muestra un
  /// solo lapiz (ver `modoDeEdicionCheque`).
  bool puedeEditarTalonario(String? estado) =>
      esAdmin || (botones.contains(btnEditar) && estaCerrado(estado));

  /// «Fecha Cobro» de la fila: `btnEditar2CH` y estado distinto de CER.
  bool puedeCambiarFechaCobro(String? estado) =>
      esAdmin || (botones.contains(btnFechaCobro) && !estaCerrado(estado));

  /// Variante de administrador de «Editar»: `btnEditar3CH` y estado distinto de
  /// CER. El formulario que abre no bloquea campos (salvo empresa y sucursal).
  bool puedeEditarComoAdmin(String? estado) =>
      esAdmin || (botones.contains(btnEditarAdmin) && !estaCerrado(estado));

  /// Variante de administrador de «Fecha Cobro»: `btnEditar3CH` y estado
  /// distinto de CER.
  bool puedeCambiarFechaCobroComoAdmin(String? estado) =>
      esAdmin || (botones.contains(btnEditarAdmin) && !estaCerrado(estado));

  /// «Completar»: entrar al detalle. Vale en cualquier estado.
  bool get puedeCompletar => tiene(btnDetalle);

  // ── Detalle ──────────────────────────────────────────────────────────────

  /// Eliminar una accion del historial. **No mira el estado del cheque ni el de
  /// la accion**, como el legacy: se conserva a proposito.
  bool get puedeEliminarAccion => tiene(btnEliminarAccion);

  /// La nueva fecha de cobro no tiene el limite de +-28 dias respecto de la
  /// fecha del cheque.
  bool get fechaCobroSinLimite => tiene(btnEditarAdmin);

  /// «Fecha Cobro» desde el detalle: el servidor acepta `btnEditar2CH`,
  /// `btnEditar3CH` o `btnDetalleCH`. Ademas hace falta que la rama K la
  /// habilite (`BotonesChequeEntity.fechaCobro`).
  bool get puedeFechaCobroDesdeDetalle =>
      tiene(btnFechaCobro) || tiene(btnEditarAdmin) || tiene(btnDetalle);

  // ── Paneles del detalle (notas, transacciones y postergaciones) ──────────
  //
  // **No dependen del estado del cheque**: en el legacy «Nuevo» se dibuja con el
  // cheque cerrado y el eliminar de la nota tiene el estado comentado
  // (`esAutorizadoB`). Eliminar una transaccion o una postergacion y todo lo del
  // PDF de la postergacion no tienen boton: se dibujan siempre.

  /// «Nuevo» de los tres paneles (`btnNuevoNRCH`).
  bool get puedeRegistrarEnPaneles => tiene(btnNuevoPanel);

  /// «Eliminar» una nota de remision (`btnEliminarNRCH`).
  bool get puedeEliminarNotaRemision => tiene(btnEliminarNota);

  // ── Bancos (vista 43) ────────────────────────────────────────────────────

  bool get puedeCrearBanco => tiene(btnNuevoBanco);
  bool get puedeEditarBanco => tiene(btnEditarBanco);
  bool get puedeEliminarBanco => tiene(btnEliminarBanco);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermisosCheque &&
          other.esAdmin == esAdmin &&
          other.botones.length == botones.length &&
          other.botones.containsAll(botones);

  @override
  int get hashCode => Object.hash(esAdmin, botones.length);
}
