/// Cheques: la pantalla principal del modulo (tablas `tch_`).
///
/// Reemplaza a `tchCheque/cheque.xhtml` (tb_vista codVista 42). Es la misma
/// pantalla de dos vistas del legacy —el listado y el detalle «Completar»—, con
/// tres cambios:
///
/// - **Paginacion y filtros en el servidor**: el legacy traia todos los cheques
///   de la sucursal y los paginaba en memoria.
/// - **Los permisos solo dibujan**: que botones se ven lo resuelve
///   `PermisosCheque`; la puerta que cierra de verdad es la del servidor.
/// - **Tabla en escritorio, tarjetas en movil**, sin scroll horizontal en movil.
///
/// Todo lo que escribe vive en `widgets/cheques/`; esta pantalla lista, filtra y
/// abre. El estado de la grilla (sucursal, filtros, pagina) esta en
/// `grillaChequesProvider` y por eso «Ir atras» desde el detalle vuelve donde se
/// estaba.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/utils/modo_edicion_cheque.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/actualizar_datos_sap_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/detalle_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/dialogos_accion_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/dialogos_custodia_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/filtros_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/formulario_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/lista_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/resumen_cheques.dart';

class ChequesScreen extends ConsumerStatefulWidget {
  const ChequesScreen({super.key});

  @override
  ConsumerState<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends ConsumerState<ChequesScreen> {
  final _scroll = ScrollController();

  /// El cheque cuyo detalle se esta viendo; null = el listado. Es estado de la
  /// pantalla y no una ruta: el legacy tambien alternaba dos vistas, y asi
  /// volver conserva filtros y pagina sin armar nada.
  BigInt? _codDetalle;

  @override
  void initState() {
    super.initState();
    // Pide la sucursal inicial y la primera pagina. Despues del primer dibujo:
    // un provider no se toca mientras el arbol se arma.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(grillaChequesProvider.notifier).iniciar();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GrillaChequesNotifier get _grilla =>
      ref.read(grillaChequesProvider.notifier);

  void _recargar() {
    final e = ref.read(grillaChequesProvider);
    // Si ni la sucursal inicial llego, se reintenta desde el principio.
    e.iniciado ? _grilla.recargar() : _grilla.iniciar();
  }

  /// El «Registrar» unico: el formulario de administrador si el usuario tiene
  /// btnNuevo2CH (el administrador siempre), el estandar si no.
  Future<void> _registrar() => abrirFormularioCheque(
    context,
    modo: ref.read(permisosChequeProvider).modoDeRegistro,
    codSucursal: ref.read(grillaChequesProvider).codSucursal,
  );

  // Traspaso, custodia y reportes trabajan sobre la sucursal elegida en la
  // grilla.
  int get _sucursal => ref.read(grillaChequesProvider).codSucursal;

  /// La empresa activa del combo «Empresa» (nunca la del login); null si todavia
  /// no se resolvio.
  int? get _empresa => ref.read(empresaChequeActivaProvider)?.codEmpresa;

  void _traspaso() => abrirTraspasoCheques(
    context,
    codSucursal: _sucursal,
    codEmpresa: _empresa,
  );

  /// Abre un reporte con la empresa activa y la sucursal de la grilla.
  void _reporte(
    Future<void> Function(
      BuildContext context, {
      required int codEmpresa,
      required int codSucursal,
    })
    abrir,
  ) {
    final empresa = _empresa;
    if (empresa == null) {
      avisar(context, 'Todavía no se cargó la empresa.', esError: true);
      return;
    }
    abrir(context, codEmpresa: empresa, codSucursal: _sucursal);
  }

  void _custodia() => abrirCustodiaCheques(context, codSucursal: _sucursal);

  void _darCustodia() =>
      abrirDarCustodiaCheques(context, codSucursal: _sucursal);

  /// «Actualizar datos SAP»: no depende de la sucursal ni de la empresa.
  void _actualizarDatosSap() => abrirActualizarDatosSap(context);

  /// El lapiz de la fila: el formulario lo decide `modoDeEdicionCheque` (el de
  /// administrador, el estandar o el de talonario con un aviso).
  void _editar(ChequeFilaEntity cheque) {
    final c = cheque.cheque;
    final edicion = modoDeEdicionCheque(
      ref.read(permisosChequeProvider),
      estado: c.estado,
      fechaCheque: c.fechaCheque,
      fechaCobrar: c.fechaCobrar,
    );
    if (edicion == null) return;
    abrirFormularioCheque(
      context,
      modo: edicion.modo,
      codSucursal: ref.read(grillaChequesProvider).codSucursal,
      existente: cheque,
      avisoCobroFueraDeRango: edicion.avisoCobroFueraDeRango,
    );
  }

  void _alElegirAccion(AccionFilaCheque accion, ChequeFilaEntity cheque) {
    switch (accion) {
      case AccionFilaCheque.editar:
        _editar(cheque);
      case AccionFilaCheque.editarTalonario:
        abrirFormularioCheque(
          context,
          modo: ModoRegistroCheque.talonario,
          codSucursal: ref.read(grillaChequesProvider).codSucursal,
          existente: cheque,
        );
      case AccionFilaCheque.fechaCobro:
        abrirAccionCheque(
          context,
          cheque: cheque,
          tipo: TipoAccionCheque.fechaCobro,
        );
      case AccionFilaCheque.completar:
        setState(() => _codDetalle = cheque.codCheque);
      case AccionFilaCheque.documentoPdf:
        abrirDocumentoPdfCheque(context, cheque: cheque);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se observa aunque se este en el detalle: la grilla es autoDispose y, sin
    // un oyente, se destruiria y «Ir atras» volveria a la primera pagina sin
    // filtros.
    final grilla = ref.watch(grillaChequesProvider);
    final permisos = ref.watch(permisosChequeProvider);
    final ocupado = ref.watch(
      operacionesChequesProvider.select((s) => s.ocupado),
    );

    // Al cambiar de pagina se vuelve arriba: en el telefono el boton «siguiente»
    // esta al final de una pagina larga.
    ref.listen(grillaChequesProvider.select((s) => s.pagina), (_, __) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });

    final enDetalle = _codDetalle != null;

    // ChequesScope: tipografia y colores de estado del modulo (ver ChequesTema).
    // Los paneles lo reciben tambien, desde abrirPanelCheque.
    return ChequesScope(
      child: PopScope(
      // El atras del sistema vuelve al listado, no sale del modulo.
      canPop: !enDetalle,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) setState(() => _codDetalle = null);
      },
      child: Scaffold(
        body:
            enDetalle
                ? DetalleCheque(
                  key: ValueKey('detalle-$_codDetalle'),
                  codCheque: _codDetalle!,
                  onVolver: () => setState(() => _codDetalle = null),
                )
                : LayoutBuilder(
                  builder: (context, restricciones) {
                    final aire = Aire.de(restricciones.maxWidth);
                    final chico = aire == Aire.justo;
                    final margen = chico ? Esp.m : Esp.xl;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Cabecera(
                          chico: chico,
                          permisos: permisos,
                          haySucursal: grilla.haySucursal,
                          onRecargar: _recargar,
                          onRegistrar: _registrar,
                          onTraspaso: _traspaso,
                          onCustodia: _custodia,
                          onDarCustodia: _darCustodia,
                          onActualizarDatosSap: _actualizarDatosSap,
                          onReporteRecibidos:
                              () => _reporte(abrirReporteRecibidos),
                          onReporteCobranzas:
                              () => _reporte(abrirReporteCobranzas),
                          onReporteCustodio:
                              () => _reporte(abrirReporteCustodio),
                          onReciboUltimoCheque:
                              () => _reporte(abrirReciboUltimoCheque),
                          onReimprimirTraspaso:
                              () => _reporte(abrirReimprimirTraspaso),
                        ),
                        SizedBox(
                          height: 2,
                          child:
                              (grilla.cargando || ocupado)
                                  ? const LinearProgressIndicator(minHeight: 2)
                                  : null,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scroll,
                            padding: EdgeInsets.fromLTRB(
                              margen,
                              Esp.l,
                              margen,
                              Esp.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Siempre: sin sucursal en una empresa todavia se
                                // puede pasar a la otra.
                                const FiltrosCheques(),
                                const RangoActivoCheques(),
                                const SizedBox(height: Esp.l),
                                _Cuerpo(
                                  estado: grilla,
                                  permisos: permisos,
                                  onAccion: _alElegirAccion,
                                  onReintentar: _recargar,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.chico,
    required this.permisos,
    required this.haySucursal,
    required this.onRecargar,
    required this.onRegistrar,
    required this.onTraspaso,
    required this.onCustodia,
    required this.onDarCustodia,
    required this.onActualizarDatosSap,
    required this.onReporteRecibidos,
    required this.onReporteCobranzas,
    required this.onReporteCustodio,
    required this.onReciboUltimoCheque,
    required this.onReimprimirTraspaso,
  });

  final bool chico;
  final PermisosCheque permisos;

  /// Sin sucursal el cheque nuevo no tiene donde quedar y el traspaso, la
  /// custodia y los reportes no tienen sobre que trabajar: esos botones se
  /// apagan.
  final bool haySucursal;

  final VoidCallback onRecargar;
  final VoidCallback onRegistrar;
  final VoidCallback onTraspaso;
  final VoidCallback onCustodia;
  final VoidCallback onDarCustodia;
  final VoidCallback onActualizarDatosSap;
  final VoidCallback onReporteRecibidos;
  final VoidCallback onReporteCobranzas;
  final VoidCallback onReporteCustodio;
  final VoidCallback onReciboUltimoCheque;
  final VoidCallback onReimprimirTraspaso;

  /// Sin sucursal las opciones no hacen nada; el menu o el boton ya estan
  /// apagados.
  VoidCallback _si(VoidCallback f) => haySucursal ? f : () {};

  /// Traspaso, «A Custodio» y «Dar Custodia» que este usuario puede hacer, en el
  /// orden del legacy. Vacia si no tiene ninguna: entonces no se dibuja nada.
  List<OpcionMenuCheque> _opcionesDeCustodia() => [
    if (permisos.puedeTraspasar)
      OpcionMenuCheque(
        'Traspaso',
        Icons.move_to_inbox_outlined,
        _si(onTraspaso),
      ),
    if (permisos.puedeEntregarACustodia)
      OpcionMenuCheque(
        'A Custodio',
        Icons.how_to_reg_outlined,
        _si(onCustodia),
      ),
    if (permisos.puedeDarCustodia)
      OpcionMenuCheque(
        'Dar Custodia',
        Icons.assignment_ind_outlined,
        _si(onDarCustodia),
      ),
  ];

  /// Los reportes que este usuario puede pedir, en el orden de los botones del
  /// legacy. Vacia si no tiene ninguno: entonces no se dibuja nada.
  List<OpcionMenuCheque> _opcionesDeReportes() => [
    if (permisos.puedeReporteRecibidos)
      OpcionMenuCheque(
        'Cheques recibidos',
        Icons.picture_as_pdf_outlined,
        _si(onReporteRecibidos),
      ),
    if (permisos.puedeReporteCobranzas)
      OpcionMenuCheque(
        'Cheques de cobranza',
        Icons.picture_as_pdf_outlined,
        _si(onReporteCobranzas),
      ),
    if (permisos.puedeReporteCustodio)
      OpcionMenuCheque(
        'Cheques en custodia',
        Icons.picture_as_pdf_outlined,
        _si(onReporteCustodio),
      ),
    if (permisos.puedeReciboUltimoCheque)
      OpcionMenuCheque(
        'Recibo del último cheque',
        Icons.receipt_long_outlined,
        _si(onReciboUltimoCheque),
      ),
    if (permisos.puedeReimprimirTraspaso)
      OpcionMenuCheque(
        'Reimprimir traspaso',
        Icons.print_outlined,
        _si(onReimprimirTraspaso),
      ),
  ];

  /// «Actualizar datos SAP» si el usuario tiene `btnNuevoCH`; null si no. No
  /// depende de la sucursal: es la unica opcion que sigue disponible sin ella.
  OpcionMenuCheque? _opcionDatosSap() =>
      permisos.puedeActualizarDatosSap
          ? OpcionMenuCheque(
            'Actualizar datos SAP',
            Icons.cloud_download_outlined,
            onActualizarDatosSap,
          )
          : null;

  /// El nombre del menu del telefono: dice lo que de verdad trae.
  static String _nombreDelMenu({
    required bool custodia,
    required bool reportes,
    required bool datosSap,
  }) {
    // Los nombres de siempre, para quien no tiene los datos de SAP.
    if (!datosSap) {
      if (!reportes) return 'Traspaso y custodia';
      return custodia ? 'Traspaso, custodia y reportes' : 'Reportes';
    }
    if (!custodia && !reportes) return 'Actualizar datos SAP';
    final partes = [
      if (custodia) 'custodia',
      if (reportes) 'reportes',
      'datos SAP',
    ];
    final texto =
        partes.length == 1
            ? partes.single
            : '${partes.sublist(0, partes.length - 1).join(', ')} y '
                '${partes.last}';
    final nombre = custodia ? 'Traspaso, $texto' : texto;
    return nombre[0].toUpperCase() + nombre.substring(1);
  }

  /// La custodia en la barra de escritorio: un menu «Custodia» con las acciones,
  /// o directamente el boton de la unica que el usuario tiene (un menu de un
  /// solo elemento seria un clic de mas). Null si no tiene ninguna.
  Widget? _botonCustodia(List<OpcionMenuCheque> custodia) {
    if (custodia.isEmpty) return null;
    if (custodia.length == 1) {
      final o = custodia.single;
      return OutlinedButton.icon(
        onPressed: haySucursal ? o.alElegir : null,
        icon: Icon(o.icono, size: 18),
        label: Text(o.etiqueta),
      );
    }
    return BotonMenuCheque(
      etiqueta: 'Custodia',
      icono: Icons.inventory_2_outlined,
      habilitado: haySucursal,
      opciones: custodia,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custodia = _opcionesDeCustodia();
    final reportes = _opcionesDeReportes();
    final hayCustodia = custodia.isNotEmpty;
    final datosSap = _opcionDatosSap();

    // Insignia con el icono del modulo en un circulo del primario-contenedor,
    // junto al titulo y el subtitulo.
    final insignia = DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: chico ? 38 : 44,
        child: Icon(
          Icons.payments_outlined,
          size: chico ? 20 : 24,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
    final titulo = Row(
      // Solo toma lo que necesita: lo que sobra es de los botones.
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        insignia,
        SizedBox(width: chico ? Esp.s : Esp.m),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cheques',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: Peso.dato,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cheques recibidos de los clientes',
                style: context.apagado(),
              ),
            ],
          ),
        ),
      ],
    );

    final recargar = IconButton(
      onPressed: onRecargar,
      icon: const Icon(Icons.refresh),
      tooltip: 'Actualizar',
    );

    final List<Widget> acciones;
    if (chico) {
      // Telefono: un solo boton para registrar y un menu con el traspaso, las
      // custodias, los reportes y «Actualizar datos SAP», cada grupo separado
      // del anterior por una linea. El menu se nombra por lo que de verdad trae.
      acciones = [
        recargar,
        if (hayCustodia || reportes.isNotEmpty)
          MenuAccionesCheque(
            tooltip: _nombreDelMenu(
              custodia: hayCustodia,
              reportes: reportes.isNotEmpty,
              datosSap: datosSap != null,
            ),
            icono:
                (hayCustodia || reportes.isEmpty)
                    ? Icons.swap_horiz
                    : Icons.picture_as_pdf_outlined,
            // El menu se apaga entero solo si no queda nada que se pueda
            // usar: sin sucursal siguen disponibles las opciones que no la
            // necesitan («Actualizar datos SAP», que en el legacy tampoco
            // depende de ella: auditoria de permisos, diferencia #5).
            habilitado: haySucursal || datosSap != null,
            opciones: [
              for (final o in custodia)
                OpcionMenuCheque(
                  o.etiqueta,
                  o.icono,
                  o.alElegir,
                  habilitada: haySucursal,
                ),
              for (final (i, o) in reportes.indexed)
                OpcionMenuCheque(
                  o.etiqueta,
                  o.icono,
                  o.alElegir,
                  separadorAntes: i == 0 && hayCustodia,
                  habilitada: haySucursal,
                ),
              if (datosSap != null)
                OpcionMenuCheque(
                  datosSap.etiqueta,
                  datosSap.icono,
                  datosSap.alElegir,
                  separadorAntes: true,
                ),
            ],
          )
        else if (datosSap != null)
          // Sin traspaso, custodia ni reportes el menu es solo este; no depende
          // de la sucursal, asi que no se apaga sin ella.
          MenuAccionesCheque(
            tooltip: _nombreDelMenu(
              custodia: false,
              reportes: false,
              datosSap: true,
            ),
            icono: Icons.more_horiz,
            opciones: [datosSap],
          ),
        if (permisos.puedeVerRegistrar)
          IconButton.filled(
            onPressed: haySucursal ? onRegistrar : null,
            icon: const Icon(Icons.add),
            tooltip: 'Registrar cheque',
          ),
      ];
    } else {
      // Escritorio: Custodia ▾, Reportes ▾, un ⋯ discreto con «Actualizar datos
      // SAP» (solo con el permiso, sin etiqueta: no es un boton mas de la barra)
      // y el unico «Registrar» (el primario).
      final botonCustodia = _botonCustodia(custodia);
      acciones = [
        recargar,
        if (botonCustodia != null) botonCustodia,
        if (reportes.isNotEmpty)
          BotonMenuCheque(
            etiqueta: 'Reportes',
            icono: Icons.picture_as_pdf_outlined,
            habilitado: haySucursal,
            opciones: reportes,
          ),
        if (datosSap != null)
          MenuAccionesCheque(
            tooltip: 'Más acciones',
            icono: Icons.more_horiz,
            opciones: [datosSap],
          ),
        if (permisos.puedeVerRegistrar)
          FilledButton.icon(
            onPressed: haySucursal ? onRegistrar : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar'),
          ),
      ];
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        chico ? Esp.m : Esp.xl,
        Esp.l,
        chico ? Esp.s : Esp.xl,
        Esp.m,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.05),
          cs.surfaceContainerLow,
        ),
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // En escritorio el titulo solo toma lo que necesita (con tope): lo
          // que sobra es de los botones, que con los reportes son muchos.
          if (chico)
            Expanded(child: titulo)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: titulo,
            ),
          if (chico)
            Row(mainAxisSize: MainAxisSize.min, children: acciones)
          else ...[
            const SizedBox(width: Esp.m),
            // Wrap y no Row: si los botones no entran bajan de linea en vez de
            // aplastar el titulo.
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Esp.s,
                  runSpacing: Esp.s,
                  children: acciones,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUERPO: LISTADO O EL ESTADO QUE CORRESPONDA
// ═══════════════════════════════════════════════════════════════════════════

/// Alto de los mensajes de estado dentro del scroll de la pantalla: son
/// `Center(SingleChildScrollView)` y piden una altura acotada.
const double _altoMensaje = 320;

class _Cuerpo extends ConsumerWidget {
  const _Cuerpo({
    required this.estado,
    required this.permisos,
    required this.onAccion,
    required this.onReintentar,
  });

  final EstadoGrillaCheques estado;
  final PermisosCheque permisos;
  final AlElegirAccionCheque onAccion;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grilla = ref.read(grillaChequesProvider.notifier);

    // Un fallo no es «sin cheques»: se dice cual fue y se ofrece reintentar.
    if (estado.error != null) {
      return SizedBox(
        height: _altoMensaje,
        child: ErrorCheques(
          titulo: 'No se pudieron cargar los cheques',
          texto: estado.error!,
          onReintentar: onReintentar,
        ),
      );
    }

    // Todavia no se sabe cual es la sucursal del usuario.
    if (!estado.iniciado) return const _EsqueletoGrilla();

    if (!estado.haySucursal) {
      // No es un error tecnico: el usuario no tiene sucursal en esta empresa o
      // no eligio una.
      final puedeElegir = permisos.puedeElegirSucursal;
      return SizedBox(
        height: _altoMensaje,
        child: MensajeVacio(
          icono: Icons.store_mall_directory_outlined,
          titulo:
              puedeElegir
                  ? 'Elige una sucursal'
                  : 'Tu usuario no tiene una sucursal asignada en esta empresa',
          detalle:
              puedeElegir
                  ? 'Selecciona la sucursal en el filtro para ver sus cheques.'
                  : 'Prueba con otra empresa o pide a Sistemas que te asignen '
                      'una sucursal para poder trabajar con cheques.',
        ),
      );
    }

    if (estado.resultado == null) return const _EsqueletoGrilla();

    if (estado.filas.isEmpty) {
      final f = estado.filtro;
      final hayFiltro = f.tieneCriteriosSalvoRecepcion;

      // Solo el rango de recepcion (el de por defecto u otro): no es «no hay
      // cheques», es que no hay en esas fechas.
      if (!hayFiltro && f.tieneRangoRecepcion) {
        return SizedBox(
          height: _altoMensaje,
          child: Column(
            children: [
              const Expanded(
                child: MensajeVacio(
                  icono: Icons.date_range_outlined,
                  titulo: 'No hay cheques recibidos en esas fechas',
                  detalle:
                      'Cambia «Recibido desde» y «Recibido hasta», o quita las '
                      'fechas para ver también los cheques anteriores.',
                ),
              ),
              TextButton.icon(
                // Sin criterios ni fechas: se piden todos.
                onPressed: () => grilla.aplicarCriterios(),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Ver todos los cheques'),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: _altoMensaje,
        child: Column(
          children: [
            Expanded(
              child: MensajeVacio(
                icono: hayFiltro ? Icons.filter_alt_off : Icons.inbox_outlined,
                titulo:
                    hayFiltro
                        ? 'Ningún cheque coincide con la búsqueda'
                        : 'Todavía no hay cheques en esta sucursal',
                detalle:
                    hayFiltro
                        ? 'Prueba con otro nro. de cheque, cliente o fecha, o '
                            'quita los filtros.'
                        : 'Cuando se registre el primero aparecerá aquí.',
              ),
            ),
            if (hayFiltro)
              TextButton.icon(
                onPressed: grilla.limpiarCriterios,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Quitar filtros'),
              ),
          ],
        ),
      );
    }

    // El mismo dia para el resumen y para cada fila: el reloj es inyectable.
    final hoy = ref.read(relojChequesProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResumenCheques(
          filas: estado.filas,
          total: estado.total,
          totalPaginas: estado.totalPaginas,
          hoy: hoy,
        ),
        const SizedBox(height: Esp.l),
        ListaCheques(
          filas: estado.filas,
          primerNumero: (estado.pagina - 1) * estado.filtro.tamanio + 1,
          permisos: permisos,
          onAccion: onAccion,
          hoy: hoy,
          pie: PaginadorCheques(
            pagina: estado.pagina,
            totalPaginas: estado.totalPaginas,
            total: estado.total,
            onAnterior: estado.hayAnterior ? grilla.anterior : null,
            onSiguiente: estado.haySiguiente ? grilla.siguiente : null,
          ),
        ),
      ],
    );
  }
}

/// Bloques grises del alto de las filas que van a llegar: la pagina no salta
/// cuando llegan los datos. Sin animacion: es solo para la primera carga.
class _EsqueletoGrilla extends StatelessWidget {
  const _EsqueletoGrilla();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('esqueleto-grilla'),
      children: [
        for (var i = 0; i < 6; i++) ...[
          Opacity(
            opacity: 1 - (i * 0.12).clamp(0.0, 0.6),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Esquina.media),
              ),
            ),
          ),
          const SizedBox(height: Esp.s),
        ],
      ],
    );
  }
}
