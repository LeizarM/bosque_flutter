import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_pestanas.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_asignaciones.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_ejecutar.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_grupos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_pendientes.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_politica.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_preliminar.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_rangos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_vendedores.dart';

/// Pantalla del módulo de Comisiones; sustituye a Comisiones.xhtml de Bosque v2,
/// que mezclaba configuración y ejecución del mes (aquí cada pestaña tiene una
/// sola responsabilidad). Las pestañas siguen los permisos de tb_vistaBtn de la
/// vista 82, los que el XHTML consultaba con `wComision.esAutorizado(...)`.
class ComisionesScreen extends ConsumerWidget {
  const ComisionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esMovil = ResponsiveUtilsBosque.isMobile(context);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    // La regla de permisos vive en un solo lugar, junto a PermissionWidget. Se
    // sigue observando el provider (tienePermisoDeBoton hace ref.watch): los
    // permisos llegan después del primer dibujo y las pestañas deben rehacerse.
    final permisos = ref.watch(buttonPermissionsProvider);
    bool tiene(String nombre) => tienePermisoDeBoton(ref, nombre);

    // La regla de acceso vive en superficiesComision(), pura y probada contra filas
    // reales de tb_usuarioBtn en test/permisos_comisiones_test.dart. Aquí solo se
    // mapea cada superficie a su widget.
    final superficies = superficiesComision(tiene);

    // Toda pestaña pasa por `tiene(...)`, como el `rendered` de cada tab de
    // Comisiones.xhtml. Orden: configuración (Política junto a Escala por días,
    // ambas mueven dinero) y luego el ciclo del mes: revisar, ejecutar, ver lo
    // pendiente.
    final pestanas = [
      for (final p in superficies.pestanias)
        switch (p) {
          PestanaComision.vendedores => const _Pestana(
            'Vendedores',
            Icons.badge_outlined,
            TabVendedores(),
          ),
          PestanaComision.grupos => const _Pestana(
            'Grupos',
            Icons.folder_outlined,
            TabGrupos(),
          ),
          PestanaComision.asignaciones => const _Pestana(
            'Asignaciones',
            Icons.link_outlined,
            TabAsignaciones(),
          ),
          // Solo lectura; el mantenimiento lo restringe el backend a ROLE_ADM.
          PestanaComision.escala => const _Pestana(
            'Escala por dias',
            Icons.timeline_outlined,
            TabRangos(),
          ),
          PestanaComision.politica => const _Pestana(
            'Politica',
            Icons.rule_outlined,
            TabPolitica(),
          ),
          PestanaComision.preliminar => _Pestana(
            'Preliminar',
            Icons.calculate_outlined,
            TabPreliminar(modalidades: superficies.modalidades),
          ),
          PestanaComision.ejecutar => const _Pestana(
            'Ejecutar',
            Icons.payments_outlined,
            TabEjecutar(),
          ),
          PestanaComision.pendientes => const _Pestana(
            'Pendientes',
            Icons.pending_actions_outlined,
            TabPendientes(),
          ),
        },
    ];

    // El módulo corre bajo su propio Theme, derivado del de la app (el acento y el
    // modo oscuro los sigue eligiendo el usuario). Agrega tipografía, jerarquía y
    // densidad a las ocho pestañas sin que cada una lo repita.
    return Theme(
      data: ComisionesTema.temaModulo(context),
      // Builder para que el Scaffold lea el ColorScheme del Theme del módulo y no el
      // de la app; si no, el fondo queda teñido y con costura frente a las tarjetas.
      child: Builder(
        builder: (context) {
          final csMod = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: csMod.surface,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Encabezado(padding: padding, esMovil: esMovil),
                if (permisos.isLoading)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  const SizedBox(height: 2),
                Expanded(
                  // La lista puede quedar vacía y TabController con length 0 falla
                  // en el assert.
                  child:
                      pestanas.isEmpty
                          ? _SinPermisos(cargando: permisos.isLoading)
                          : DefaultTabController(
                            // La clave incluye la cantidad de pestañas: al llegar
                            // los permisos cambia y el controlador debe rehacerse
                            // (si no, length y children se desajustan).
                            key: ValueKey('comisiones-${pestanas.length}'),
                            length: pestanas.length,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BarraPestanas(
                                  items: [
                                    for (final p in pestanas)
                                      ItemPestana(p.titulo, p.icono),
                                  ],
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  // Tope de ancho: en un monitor ancho se pierde el
                                  // renglón entre nombre e importe. Las tablas
                                  // anchas lo ignoran con su propio scroll
                                  // horizontal.
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: ComisionesTema.anchoMaximo,
                                      ),
                                      child: TabBarView(
                                        children: [
                                          for (final p in pestanas) p.contenido,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pestana {
  const _Pestana(this.titulo, this.icono, this.contenido);
  final String titulo;
  final IconData icono;
  final Widget contenido;
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.padding, required this.esMovil});

  final double padding;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        padding,
        ComisionesTema.esp4,
        padding,
        ComisionesTema.esp3,
      ),
      color: cs.surface,
      // Título y bajada en una línea en escritorio; apilados ocupaban ~90px de
      // alto útil.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ComisionesTema.esp3,
        runSpacing: ComisionesTema.esp1,
        children: [
          Text(
            'Comisiones',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          // En teléfono la bajada cuesta un tercio del alto útil y no aporta desde
          // la segunda visita.
          if (!esMovil)
            Text(
              'Configure vendedores y escalas, revise el preliminar y ejecute el mes.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Estado para el usuario sin ningún permiso de la vista 82. Se distingue de la
/// carga: mostrar "no tiene acceso" mientras los permisos siguen en vuelo sería
/// mentir.
class _SinPermisos extends StatelessWidget {
  const _SinPermisos({required this.cargando});

  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Sin permisos en Comisiones',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Su usuario no tiene habilitada ninguna seccion de este modulo. '
              'Solicite el permiso en la pantalla de Usuarios.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
