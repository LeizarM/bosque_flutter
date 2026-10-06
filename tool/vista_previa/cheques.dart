// Vista previa del modulo Cheques con datos de mentira: sin login, permisos ni
// backend.
//   flutter run -d chrome -t tool/vista_previa/cheques.dart
//   flutter build web -t tool/vista_previa/cheques.dart --output build/preview_cheques
//
// Monta la pantalla REAL (ChequesScreen), no una copia: una tabla se juzga junto
// a su resumen, sus filtros y su pie. El panel de arriba cambia ancho, tema,
// color, escala de texto, la vista (listado, detalle o formulario) y cuantos
// cheques hay (14 caben en una pagina; 45 dan tres y muestran los rotulos «en
// esta pagina» del resumen). Usa el tema real de la app y un reloj fijo
// (3/10/2026), asi «Atrasado 12 d» no cambia segun el dia en que se mire.
//
// Para capturar sin tocar nada se puede abrir con parametros en la URL:
//   ?ancho=390&oscuro=1&color=3&texto=1.5&vista=detalle&cheque=12&datos=45&panel=0
// La vista `pdf` abre el dialogo del documento PDF del cheque; `pdf=0` lo deja
// sin PDF cargado (por defecto, con uno). El dialogo cuelga del Navigator raiz:
// toma el tamano real de la ventana, no el simulado por «Ancho» (para verlo en
// movil, achica la ventana del navegador).
// Los paneles del detalle (notas de remision, transacciones y postergaciones) se
// ven en `vista=detalle`: el cheque 14 los trae llenos (con una nota repetida),
// el 13 con una fila de cada uno y el resto vacios. Sus dialogos se abren con
// `vista=notaNueva|transaccionNueva|postergacionNueva|pdfPostergacion|eliminar`
// (`pdfPostergacion` con `pdf=0` abre una postergacion sin PDF).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/actualizar_socios_sap_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/app_scroll_behavior.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/actualizar_datos_sap_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/detalle_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/dialogos_paneles_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_postergacion.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/formulario_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/paneles_cheque.dart';

import 'cheques_datos.dart';

void main() => runApp(const _Raiz());

enum _Ancho {
  auto('Auto', null),
  movil('Móvil', 390),
  tablet('Tablet', 768),
  escritorio('Escritorio', 1280);

  const _Ancho(this.titulo, this.px);
  final String titulo;
  final double? px;
}

enum _Vista {
  listado('Listado'),
  detalle('Detalle'),
  formulario('Formulario'),
  pdf('PDF'),
  notaNueva('Nueva nota'),
  transaccionNueva('Nueva transacción'),
  postergacionNueva('Nueva postergación'),
  pdfPostergacion('PDF postergación'),
  eliminar('Eliminar'),
  datosSap('Datos SAP');

  const _Vista(this.titulo);
  final String titulo;

  /// Los dialogos de los paneles del detalle (notas de remision, transacciones y
  /// postergaciones): van en su propio grupo, al final del panel de controles,
  /// para no empujar fuera de la pantalla a los demas.
  bool get esDialogoDePanel =>
      this == notaNueva ||
      this == transaccionNueva ||
      this == postergacionNueva ||
      this == pdfPostergacion ||
      this == eliminar;

  static List<_Vista> get principales =>
      values.where((v) => !v.esDialogoDePanel).toList();
  static List<_Vista> get dialogosDePanel =>
      values.where((v) => v.esDialogoDePanel).toList();
}

class _Raiz extends StatefulWidget {
  const _Raiz();

  @override
  State<_Raiz> createState() => _RaizState();
}

class _RaizState extends State<_Raiz> {
  late _Ancho _ancho;
  late bool _oscuro;
  late int _color;
  late double _texto;
  late _Vista _vista;
  late int _datos;
  late int _cheque;
  late bool _panel;
  late bool _conPdf;

  @override
  void initState() {
    super.initState();
    final p = Uri.base.queryParameters;
    _ancho = _Ancho.values.firstWhere(
      (a) => a.px != null && '${a.px!.toInt()}' == p['ancho'],
      orElse: () => _Ancho.auto,
    );
    _oscuro = p['oscuro'] == '1';
    _color = (int.tryParse(p['color'] ?? '') ?? 2).clamp(0, colorList.length - 1);
    _texto = double.tryParse(p['texto'] ?? '') ?? 1;
    _vista = _Vista.values.firstWhere(
      (v) => v.name == p['vista'],
      orElse: () => _Vista.listado,
    );
    _datos = int.tryParse(p['datos'] ?? '') == 45 ? 45 : 14;
    _cheque = int.tryParse(p['cheque'] ?? '') ?? 14;
    _panel = p['panel'] != '0';
    _conPdf = p['pdf'] != '0';
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // Cambiar la cantidad de cheques o el PDF arma un repositorio nuevo.
      key: ValueKey('datos-$_datos-$_conPdf'),
      overrides: overridesDeLaVista(total: _datos, conPdf: _conPdf),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme(isDarkMode: _oscuro, selectedColor: _color).getTheme(),
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (_panel) ...[
                  _Controles(
                    ancho: _ancho,
                    oscuro: _oscuro,
                    color: _color,
                    texto: _texto,
                    vista: _vista,
                    datos: _datos,
                    conPdf: _conPdf,
                    alAncho: (v) => setState(() => _ancho = v),
                    alOscuro: (v) => setState(() => _oscuro = v),
                    alColor: (v) => setState(() => _color = v),
                    alTexto: (v) => setState(() => _texto = v),
                    alVista: (v) => setState(() => _vista = v),
                    alDatos: (v) => setState(() => _datos = v),
                    alPdf: (v) => setState(() => _conPdf = v),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: _Marco(
                    ancho: _ancho.px,
                    texto: _texto,
                    child: KeyedSubtree(
                      key: ValueKey('$_vista-$_cheque-$_datos-$_conPdf'),
                      child: switch (_vista) {
                        _Vista.listado => const ChequesScreen(),
                        _Vista.detalle => _Detalle(codCheque: _cheque),
                        _Vista.formulario => const _ConFormulario(),
                        _Vista.pdf => _ConDocumentoPdf(codCheque: _cheque),
                        _Vista.notaNueva => _DetalleConDialogo(
                          codCheque: _cheque,
                          abrir:
                              (ctx, ref, c) =>
                                  abrirNuevaNotaRemision(ctx, cheque: c),
                        ),
                        _Vista.transaccionNueva => _DetalleConDialogo(
                          codCheque: _cheque,
                          abrir:
                              (ctx, ref, c) =>
                                  abrirNuevaTransaccion(ctx, cheque: c),
                        ),
                        _Vista.postergacionNueva => _DetalleConDialogo(
                          codCheque: _cheque,
                          abrir:
                              (ctx, ref, c) =>
                                  abrirNuevaPostergacion(ctx, cheque: c),
                        ),
                        _Vista.pdfPostergacion => _DetalleConDialogo(
                          codCheque: _cheque,
                          abrir: (ctx, ref, c) async {
                            final posts = await ref.read(
                              postergacionesChequeProvider(c.codCheque).future,
                            );
                            if (!ctx.mounted || posts.isEmpty) return;
                            final cod =
                                _conPdf
                                    ? postergacionConPdfDeLaVista
                                    : postergacionSinPdfDeLaVista;
                            final p = posts.firstWhere(
                              (x) => x.codPostergacion == cod,
                              orElse: () => posts.first,
                            );
                            await abrirDocumentoPdfPostergacion(
                              ctx,
                              cheque: c,
                              postergacion: p,
                            );
                          },
                        ),
                        _Vista.datosSap => const _ConDatosSap(),
                        _Vista.eliminar => _DetalleConDialogo(
                          codCheque: _cheque,
                          abrir: (ctx, ref, c) async {
                            final notas = await ref.read(
                              notasRemisionChequeProvider(c.codCheque).future,
                            );
                            if (!ctx.mounted || notas.length < 2) return;
                            // La nota repetida: avisa que se eliminan todas.
                            await eliminarNotaRemisionCheque(
                              ctx,
                              ref,
                              nota: notas[1],
                              veces: 2,
                            );
                          },
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Controles extends StatelessWidget {
  const _Controles({
    required this.ancho,
    required this.oscuro,
    required this.color,
    required this.texto,
    required this.vista,
    required this.datos,
    required this.conPdf,
    required this.alAncho,
    required this.alOscuro,
    required this.alColor,
    required this.alTexto,
    required this.alVista,
    required this.alDatos,
    required this.alPdf,
  });

  final _Ancho ancho;
  final bool oscuro;
  final int color;
  final double texto;
  final _Vista vista;
  final int datos;
  final bool conPdf;
  final ValueChanged<_Ancho> alAncho;
  final ValueChanged<bool> alOscuro;
  final ValueChanged<int> alColor;
  final ValueChanged<double> alTexto;
  final ValueChanged<_Vista> alVista;
  final ValueChanged<int> alDatos;
  final ValueChanged<bool> alPdf;

  static final _compacto = SegmentedButton.styleFrom(
    visualDensity: VisualDensity.compact,
  );

  @override
  Widget build(BuildContext context) {
    const separacion = SizedBox(width: 16);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SegmentedButton<_Ancho>(
            showSelectedIcon: false,
            style: _compacto,
            segments: [
              for (final a in _Ancho.values)
                ButtonSegment(value: a, label: Text(a.titulo)),
            ],
            selected: {ancho},
            onSelectionChanged: (s) => alAncho(s.first),
          ),
          separacion,
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: _compacto,
            segments: const [
              ButtonSegment(value: false, label: Text('Claro')),
              ButtonSegment(value: true, label: Text('Oscuro')),
            ],
            selected: {oscuro},
            onSelectionChanged: (s) => alOscuro(s.first),
          ),
          separacion,
          // 1,3 es el tope que main.dart le pone al texto del sistema; 1,5 es el
          // que piden las pruebas de desborde.
          SegmentedButton<double>(
            showSelectedIcon: false,
            style: _compacto,
            segments: const [
              ButtonSegment(value: 1, label: Text('Texto 1×')),
              ButtonSegment(value: 1.3, label: Text('1,3×')),
              ButtonSegment(value: 1.5, label: Text('1,5×')),
            ],
            selected: {texto},
            onSelectionChanged: (s) => alTexto(s.first),
          ),
          separacion,
          SegmentedButton<_Vista>(
            showSelectedIcon: false,
            style: _compacto,
            emptySelectionAllowed: true,
            segments: [
              for (final v in _Vista.principales)
                ButtonSegment(value: v, label: Text(v.titulo)),
            ],
            selected: vista.esDialogoDePanel ? <_Vista>{} : {vista},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) alVista(s.first);
            },
          ),
          separacion,
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: _compacto,
            segments: const [
              ButtonSegment(value: 14, label: Text('14 cheques')),
              ButtonSegment(value: 45, label: Text('45 (3 págs.)')),
            ],
            selected: {datos},
            onSelectionChanged: (s) => alDatos(s.first),
          ),
          separacion,
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: _compacto,
            segments: const [
              ButtonSegment(value: false, label: Text('Sin PDF')),
              ButtonSegment(value: true, label: Text('Con PDF')),
            ],
            selected: {conPdf},
            onSelectionChanged: (s) => alPdf(s.first),
          ),
          separacion,
          for (var i = 0; i < colorList.length; i++)
            _Punto(
              color: colorList[i],
              activo: i == color,
              alTocar: () => alColor(i),
            ),
          separacion,
          // Los dialogos de los paneles del detalle (notas, transacciones y
          // postergaciones), con el detalle debajo.
          SegmentedButton<_Vista>(
            showSelectedIcon: false,
            style: _compacto,
            emptySelectionAllowed: true,
            segments: [
              for (final v in _Vista.dialogosDePanel)
                ButtonSegment(value: v, label: Text(v.titulo)),
            ],
            selected: vista.esDialogoDePanel ? {vista} : <_Vista>{},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) alVista(s.first);
            },
          ),
        ],
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({
    required this.color,
    required this.activo,
    required this.alTocar,
  });

  final Color color;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: alTocar,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  activo
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simula un dispositivo: `ancho` fijo (o el disponible si es null) y escala de
/// texto. El MediaQuery se pisa ANTES de montar los breakpoints; si no, los
/// `isMobile`/`isTablet` del modulo seguirian leyendo la ventana real.
class _Marco extends StatelessWidget {
  const _Marco({required this.ancho, required this.texto, required this.child});

  final double? ancho;
  final double texto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borde = Theme.of(context).colorScheme.outlineVariant;
    return LayoutBuilder(
      builder: (context, c) {
        final w = ancho == null ? c.maxWidth : math.min(ancho!, c.maxWidth);
        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border:
                  ancho == null
                      ? null
                      : Border.symmetric(vertical: BorderSide(color: borde)),
            ),
            child: SizedBox(
              width: w,
              height: c.maxHeight,
              child: ClipRect(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(w, c.maxHeight),
                    textScaler: TextScaler.linear(texto),
                  ),
                  child: ResponsiveBreakpoints.builder(
                    breakpoints: ResponsiveUtilsBosque.breakpoints,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// El detalle de un cheque, como lo monta la pantalla al pulsar «Completar»: la
/// pantalla real lo alterna adentro de su propio estado y aqui se abre directo.
class _Detalle extends StatelessWidget {
  const _Detalle({required this.codCheque});

  final int codCheque;

  @override
  Widget build(BuildContext context) => ChequesScope(
    child: Scaffold(
      body: DetalleCheque(codCheque: BigInt.from(codCheque), onVolver: () {}),
    ),
  );
}

/// La pantalla con el formulario de registro de administrador ya abierto, para
/// ver la tipografia de los dialogos (que cuelgan del Navigator raiz).
class _ConFormulario extends StatefulWidget {
  const _ConFormulario();

  @override
  State<_ConFormulario> createState() => _ConFormularioState();
}

class _ConFormularioState extends State<_ConFormulario> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      abrirFormularioCheque(
        context,
        modo: ModoRegistroCheque.admin,
        codSucursal: 3,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const ChequesScreen();
}

/// La pantalla con el dialogo del documento PDF del cheque ya abierto, para ver
/// el estado con y sin PDF y la carga con el selector de archivos real.
class _ConDocumentoPdf extends StatefulWidget {
  const _ConDocumentoPdf({required this.codCheque});

  final int codCheque;

  @override
  State<_ConDocumentoPdf> createState() => _ConDocumentoPdfState();
}

class _ConDocumentoPdfState extends State<_ConDocumentoPdf> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cheques = chequesDeLaVista();
      abrirDocumentoPdfCheque(
        context,
        cheque: cheques.firstWhere(
          (c) => c.codCheque == BigInt.from(widget.codCheque),
          orElse: () => cheques.first,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const ChequesScreen();
}

/// El detalle de un cheque con un dialogo ya abierto encima: los «Nuevo» de los
/// paneles, el PDF de una postergacion o la confirmacion de eliminar. El dialogo
/// cuelga del Navigator raiz y toma el tamano real de la ventana.
class _DetalleConDialogo extends ConsumerStatefulWidget {
  const _DetalleConDialogo({required this.codCheque, required this.abrir});

  final int codCheque;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    ChequeFilaEntity cheque,
  )
  abrir;

  @override
  ConsumerState<_DetalleConDialogo> createState() => _DetalleConDialogoState();
}

class _DetalleConDialogoState extends ConsumerState<_DetalleConDialogo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cheques = chequesDeLaVista();
      final cheque = cheques.firstWhere(
        (c) => c.codCheque == BigInt.from(widget.codCheque),
        orElse: () => cheques.first,
      );
      await widget.abrir(context, ref, cheque);
    });
  }

  @override
  Widget build(BuildContext context) => _Detalle(codCheque: widget.codCheque);
}

/// La pantalla con el dialogo de «Actualizar datos SAP» abierto. Con el
/// parametro `sap` en la URL (`ok`, `error` o `lento`; ver
/// `sociosSapDeLaVista`) ademas lo pide solo, para ver el resultado, el error o
/// el «Actualizando…» sin tocar nada.
class _ConDatosSap extends StatefulWidget {
  const _ConDatosSap();

  @override
  State<_ConDatosSap> createState() => _ConDatosSapState();
}

class _ConDatosSapState extends State<_ConDatosSap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final contenedor = ProviderScope.containerOf(context);
      abrirActualizarDatosSap(context);
      if (Uri.base.queryParameters['sap'] == null) return;
      // Deja que el dialogo se dibuje y arme su estado antes de pedirlo.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      contenedor.read(actualizarSociosSapProvider.notifier).actualizar();
    });
  }

  @override
  Widget build(BuildContext context) => const ChequesScreen();
}
