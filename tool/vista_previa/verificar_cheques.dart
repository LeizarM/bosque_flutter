// Vista previa de «Verificar Cheques» con datos de mentira: sin login, permisos
// ni backend.
//   flutter run -d chrome -t tool/vista_previa/verificar_cheques.dart
//   flutter build web -t tool/vista_previa/verificar_cheques.dart --output build/preview_verificar
//
// Monta la pantalla REAL (VerificarChequesScreen), no una copia: una tabla se
// juzga junto a su resumen, su filtro y su pie. El panel de arriba cambia ancho,
// tema, color, escala de texto, la vista (listado, modal de pendientes, formulario
// de alta o de edicion) y cuantas verificaciones hay (14 caben en una pagina; 45
// dan tres y muestran los rotulos «en esta pagina» del resumen). Usa el tema real
// de la app y un reloj fijo (3/10/2026). Las escrituras funcionan en memoria:
// registrar, editar y cancelar cambian la lista.
//
// Para capturar sin tocar nada se puede abrir con parametros en la URL:
//   ?ancho=390&oscuro=1&color=3&texto=1.5&vista=pendientes&datos=45&panel=0
// Las vistas `pendientes`, `regularizar` y `editar` abren su dialogo, que cuelga
// del Navigator raiz: toma el tamano real de la ventana, no el simulado por
// «Ancho» (para verlo en movil, achica la ventana del navegador).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/core/theme/app_scroll_behavior.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/presentation/screens/verificaciones/verificar_cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/dialogo_pendientes_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/dialogo_verificacion.dart';

import 'verificar_cheques_datos.dart';

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
  pendientes('Nuevo'),
  regularizar('Regularizar'),
  editar('Editar');

  const _Vista(this.titulo);
  final String titulo;
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
  late bool _panel;

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
    _panel = p['panel'] != '0';
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // Cambiar la cantidad de datos arma un repositorio nuevo.
      key: ValueKey('datos-$_datos'),
      overrides: overridesDeLaVista(total: _datos),
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
                    alAncho: (v) => setState(() => _ancho = v),
                    alOscuro: (v) => setState(() => _oscuro = v),
                    alColor: (v) => setState(() => _color = v),
                    alTexto: (v) => setState(() => _texto = v),
                    alVista: (v) => setState(() => _vista = v),
                    alDatos: (v) => setState(() => _datos = v),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: _Marco(
                    ancho: _ancho.px,
                    texto: _texto,
                    child: KeyedSubtree(
                      key: ValueKey('$_vista-$_datos'),
                      child: _Escena(vista: _vista),
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
    required this.alAncho,
    required this.alOscuro,
    required this.alColor,
    required this.alTexto,
    required this.alVista,
    required this.alDatos,
  });

  final _Ancho ancho;
  final bool oscuro;
  final int color;
  final double texto;
  final _Vista vista;
  final int datos;
  final ValueChanged<_Ancho> alAncho;
  final ValueChanged<bool> alOscuro;
  final ValueChanged<int> alColor;
  final ValueChanged<double> alTexto;
  final ValueChanged<_Vista> alVista;
  final ValueChanged<int> alDatos;

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
            segments: [
              for (final v in _Vista.values)
                ButtonSegment(value: v, label: Text(v.titulo)),
            ],
            selected: {vista},
            onSelectionChanged: (s) => alVista(s.first),
          ),
          separacion,
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: _compacto,
            segments: const [
              ButtonSegment(value: 14, label: Text('14 verificaciones')),
              ButtonSegment(value: 45, label: Text('45 (3 págs.)')),
            ],
            selected: {datos},
            onSelectionChanged: (s) => alDatos(s.first),
          ),
          separacion,
          for (var i = 0; i < colorList.length; i++)
            _Punto(
              color: colorList[i],
              activo: i == color,
              alTocar: () => alColor(i),
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

/// La pantalla, y para las vistas con dialogo, la pantalla con el dialogo ya
/// abierto (los dialogos cuelgan del Navigator raiz).
class _Escena extends ConsumerStatefulWidget {
  const _Escena({required this.vista});

  final _Vista vista;

  @override
  ConsumerState<_Escena> createState() => _EscenaState();
}

class _EscenaState extends ConsumerState<_Escena> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      switch (widget.vista) {
        case _Vista.listado:
          break;
        case _Vista.pendientes:
          abrirPendientesVerificacion(context);
        case _Vista.regularizar:
          final preparada = await ref
              .read(verificacionesRepositoryProvider)
              .preparar(BigInt.from(201));
          if (mounted) abrirVerificacionNueva(context, preparada);
        case _Vista.editar:
          // Las de hoy, como la lista; se edita la primera que vale.
          final pagina = await ref
              .read(verificacionesRepositoryProvider)
              .listar(VerificacionFiltroEntity(fechaBanco: hoyDeLaVista));
          if (mounted) {
            abrirVerificacionEditar(
              context,
              pagina.filas.firstWhere((f) => f.esValida),
            );
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) => const VerificarChequesScreen();
}
