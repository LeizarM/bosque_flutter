// Vista previa del módulo Comisiones con datos de mentira: sin login, permisos
// ni backend.
//   flutter run -d chrome -t tool/vista_previa/comisiones.dart
//   flutter build web -t tool/vista_previa/comisiones.dart --output build/preview
//
// Monta las pestañas reales (una tabla se juzga junto a su filtro y su pie, no
// aislada) con el tema, el locale y los breakpoints de main.dart. El panel de
// arriba cambia ancho, tema, color y escala de texto. Falta «Ejecutar»: depende
// de un StateNotifier que habla con el backend.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/theme/app_scroll_behavior.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_pestanas.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_asignaciones.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_grupos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_pendientes.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_politica.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_preliminar.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_rangos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_vendedores.dart';

import 'comisiones_datos.dart';

void main() => runApp(
  ProviderScope(overrides: overridesComisiones(), child: const _Estudio()),
);

enum _Ancho {
  auto('Auto', null),
  movil('Móvil', 390),
  tablet('Tablet', 768),
  escritorio('Escritorio', 1280);

  const _Ancho(this.titulo, this.px);
  final String titulo;
  final double? px;
}

class _Estudio extends StatefulWidget {
  const _Estudio();

  @override
  State<_Estudio> createState() => _EstudioState();
}

class _EstudioState extends State<_Estudio> {
  _Ancho _ancho = _Ancho.auto;
  bool _oscuro = false;
  int _color = 2;
  double _texto = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              _Controles(
                ancho: _ancho,
                oscuro: _oscuro,
                color: _color,
                texto: _texto,
                alAncho: (v) => setState(() => _ancho = v),
                alOscuro: (v) => setState(() => _oscuro = v),
                alColor: (v) => setState(() => _color = v),
                alTexto: (v) => setState(() => _texto = v),
              ),
              const Divider(height: 1),
              Expanded(
                child: _Marco(
                  ancho: _ancho.px,
                  texto: _texto,
                  child: const _Modulo(),
                ),
              ),
            ],
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
    required this.alAncho,
    required this.alOscuro,
    required this.alColor,
    required this.alTexto,
  });

  final _Ancho ancho;
  final bool oscuro;
  final int color;
  final double texto;
  final ValueChanged<_Ancho> alAncho;
  final ValueChanged<bool> alOscuro;
  final ValueChanged<int> alColor;
  final ValueChanged<double> alTexto;

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
          // 1,3 es el tope que main.dart le pone al texto del sistema.
          SegmentedButton<double>(
            showSelectedIcon: false,
            style: _compacto,
            segments: const [
              ButtonSegment(value: 1, label: Text('Texto 1×')),
              ButtonSegment(value: 1.3, label: Text('1,3×')),
            ],
            selected: {texto},
            onSelectionChanged: (s) => alTexto(s.first),
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
/// `isMobile`/`isTablet` del módulo seguirían leyendo la ventana real.
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

class _Pestana {
  const _Pestana(this.titulo, this.icono, this.contenido);
  final String titulo;
  final IconData icono;
  final Widget contenido;
}

class _Modulo extends StatelessWidget {
  const _Modulo();

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    // Mismo orden que comisiones_screen.dart.
    final pestanas = <_Pestana>[
      const _Pestana('Vendedores', Icons.badge_outlined, TabVendedores()),
      const _Pestana('Grupos', Icons.folder_outlined, TabGrupos()),
      const _Pestana('Asignaciones', Icons.link_outlined, TabAsignaciones()),
      const _Pestana('Escala por días', Icons.timeline_outlined, TabRangos()),
      const _Pestana('Política', Icons.rule_outlined, TabPolitica()),
      _Pestana(
        'Preliminar',
        Icons.calculate_outlined,
        TabPreliminar(modalidades: ModalidadPreliminar.values),
      ),
      const _Pestana(
        'Pendientes',
        Icons.pending_actions_outlined,
        TabPendientes(),
      ),
      // No es una pestaña real: es el diálogo del detalle congelado montado
      // como pestaña. En la app se abre desde Ejecutar y desde el Preliminar de
      // un periodo ya pagado, y ambos caminos exigen un backend.
      const _Pestana(
        'Detalle congelado',
        Icons.rule_folder_outlined,
        DialogoItemsPagados(
          filtro: FiltroItemsPagados(mes: 8, anio: 2026, esInterno: 1),
        ),
      ),
    ];

    return Theme(
      data: ComisionesTema.temaModulo(context),
      // Builder: sin él, el Scaffold pinta con el ColorScheme de AFUERA del
      // Theme del módulo (igual que en comisiones_screen.dart).
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;
          return Scaffold(
            backgroundColor: cs.surface,
            body: SafeArea(
              child: DefaultTabController(
                length: pestanas.length,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 16, padding, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Comisiones', style: tt.headlineSmall),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure vendedores y escalas, revise el '
                              'preliminar y ejecute el mes.',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    BarraPestanas(
                      items: [
                        for (final p in pestanas)
                          ItemPestana(p.titulo, p.icono),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ComisionesTema.anchoMaximo,
                          ),
                          child: TabBarView(
                            children: [for (final p in pestanas) p.contenido],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
