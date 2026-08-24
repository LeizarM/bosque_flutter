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

/// Pantalla del modulo de Comisiones.
///
/// Sustituye a Comisiones.xhtml de Bosque v2. Aquella pantalla mezclaba en un
/// mismo tabView la configuracion y la ejecucion del mes; aca cada pestana
/// tiene una sola responsabilidad.
///
/// Las pestanas se arman segun los permisos de tb_vistaBtn para la vista 82,
/// los mismos que el XHTML consultaba con `wComision.esAutorizado(...)`.
class ComisionesScreen extends ConsumerWidget {
  const ComisionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esMovil = ResponsiveUtilsBosque.isMobile(context);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    // La regla vive en un solo lugar, junto a PermissionWidget. Este modulo
    // tenia su propia copia y no decia lo mismo: mientras los permisos viajaban
    // por red, el widget compartido ya dejaba pasar al administrador y esta
    // copia le devolvia false, asi que el admin veia el modulo sin ninguna
    // pestana hasta que llegaba la respuesta.
    //
    // Se sigue observando el provider -tienePermisoDeBoton hace ref.watch-
    // porque los permisos llegan despues del primer dibujo y las pestanas
    // tienen que rehacerse cuando llegan.
    final permisos = ref.watch(buttonPermissionsProvider);
    bool tiene(String nombre) => tienePermisoDeBoton(ref, nombre);

    // La regla de acceso vive en superficiesComision(), que es pura y se prueba
    // contra filas reales de tb_usuarioBtn en
    // test/permisos_comisiones_test.dart. Aca solo se mapea cada superficie a
    // su widget.
    final superficies = superficiesComision(tiene);

    // Toda pestana pasa por `tiene(...)`. En Comisiones.xhtml no quedaba
    // superficie sin permiso: las cinco pestanas del tabView llevaban su
    // `rendered` y el unico control suelto era btnGrpVen. Aca se sostiene lo
    // mismo, incluidas las pestanas que el legacy tenia dentro de un tab ya
    // protegido y que al partirse en primer nivel se habian quedado sin gate.
    // El orden agrupa por naturaleza, no por historia. Arriba lo que se
    // configura una vez y rara vez se toca; abajo el ciclo del mes en el orden
    // en que se hace: se revisa, se ejecuta, y se mira lo que quedo abierto.
    //
    // No se copia el orden del ERP viejo, que ponia EJECUTAR primero y los
    // cuatro preliminares despues: ahi cada preliminar era su propia pestana y
    // el orden salio de como se fueron agregando. Aca los cuatro son
    // modalidades de una sola pestana, y ejecutar antes de revisar no es el
    // orden en que se trabaja.
    //
    // Politica sube al bloque de configuracion, con Escala por dias. Las dos
    // mueven plata y estaban separadas solo porque Politica se agrego despues.
    //
    // Toda pestana pasa por `tiene(...)`. En Comisiones.xhtml no quedaba
    // superficie sin permiso: las cinco pestanas del tabView llevaban su
    // `rendered` y el unico control suelto era btnGrpVen. Aca se sostiene lo
    // mismo, incluidas las pestanas que el legacy tenia dentro de un tab ya
    // protegido y que al partirse en primer nivel se habian quedado sin gate.
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

    // El modulo corre bajo su propio Theme. No se toca el de la app: el color
    // de acento y el modo oscuro los sigue eligiendo el usuario en ajustes, y
    // este Theme se deriva de aquel. Lo que agrega es lo que la app nunca
    // definio -tipografia, jerarquia, densidad-, y aplica de una vez a las
    // ocho pestanas sin que cada una lo repita.
    return Theme(
      data: ComisionesTema.temaModulo(context),
      // Builder para que el Scaffold lea el ColorScheme del Theme del modulo y
      // no el de la app. El `cs` de arriba se capturo ANTES de este Theme: con
      // el, la pagina se pintaba con el gris teñido de la app mientras las
      // tarjetas y el encabezado ya usaban la escala neutra, y quedaba un
      // costuron entre el fondo y todo lo demas.
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
                  // Ahora que toda pestana lleva permiso la lista puede quedar
                  // vacia, y TabController con length 0 revienta en el assert.
                  child:
                      pestanas.isEmpty
                          ? _SinPermisos(cargando: permisos.isLoading)
                          : DefaultTabController(
                            // La clave incluye la cantidad de pestanas: al llegar los permisos
                            // ese numero cambia y el controlador debe rehacerse, si no falla
                            // por desajuste entre length y children.
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
                                  // Tope de ancho: en un monitor ancho la fila se
                                  // estira tanto que el ojo pierde el renglon entre el
                                  // nombre y el importe. Las tablas anchas lo ignoran
                                  // y usan su propio scroll horizontal.
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
      // Titulo y bajada en una linea en escritorio. Apilados ocupaban unos 90px
      // de alto util en una herramienta donde lo que importa esta mas abajo.
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
          // En un telefono la bajada cuesta un tercio del alto util y no dice
          // nada que el usuario no sepa a la segunda visita.
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

/// Estado para el usuario que llega al modulo sin ningun permiso de la vista
/// 82. Se distingue de la carga porque los permisos viajan por red: mostrar
/// "no tiene acceso" mientras todavia estan en vuelo seria mentir.
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
