/// Ubicación geográfica: países, sus ciudades y sus zonas. Reemplaza a
/// `trhUbicacionGeografica/ubicacionGeografica.xhtml` (tb_vista codVista 26)
/// con la misma dirección y los botones btnNewU, btnEditU y btnEliminarU, que
/// valen para los tres niveles. Tocar un país muestra sus ciudades y tocar una
/// ciudad, sus zonas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ubicacion_geografica_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/ubicacion-geografica/dialogos_ubicacion.dart';

const _btnNuevo = 'btnNewU';
const _btnEditar = 'btnEditU';
const _btnEliminar = 'btnEliminarU';

class UbicacionGeograficaScreen extends ConsumerWidget {
  const UbicacionGeograficaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Los filtros viven mientras viva la pantalla, no solo su nivel: tocar un
    // país los escribe antes de que el nivel de ciudades los escuche.
    ref.watch(paisElegidoProvider);
    ref.watch(ciudadElegidaProvider);
    return switch (ref.watch(nivelUbicacionProvider)) {
      NivelUbicacion.paises => const _NivelPaises(),
      NivelUbicacion.ciudades => const _NivelCiudades(),
      NivelUbicacion.zonas => const _NivelZonas(),
    };
  }
}

/// Las acciones por fila que el ACL deja ver; la decisión es la misma en los
/// tres niveles porque comparten botones.
List<AccionCatalogo<T>> _acciones<T>(
  WidgetRef ref, {
  required void Function(T) editar,
  required void Function(T) eliminar,
}) => [
  if (tienePermisoDeBoton(ref, _btnEditar))
    AccionCatalogo<T>(
      etiqueta: 'Editar',
      icono: Icons.edit_outlined,
      alElegir: editar,
    ),
  if (tienePermisoDeBoton(ref, _btnEliminar))
    AccionCatalogo<T>(
      etiqueta: 'Eliminar',
      icono: Icons.delete_outline,
      alElegir: eliminar,
    ),
];

String _cuenta(int n, String uno, String varios) =>
    '$n ${n == 1 ? uno : varios}';

Widget _numero(BuildContext c, int n) => Text('$n', style: c.numero());

Widget _codigo(BuildContext c, int n) =>
    Text('$n', style: c.apagado()?.copyWith(fontFeatures: cifrasTabulares));

Widget _nombre(BuildContext c, String t) => Text(
  t,
  style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
);

/// Los tres niveles como pestañas que se eligen con chips.
class _SelectorNivel extends ConsumerWidget {
  const _SelectorNivel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivel = ref.watch(nivelUbicacionProvider);
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (final (n, etiqueta, icono) in [
          (NivelUbicacion.paises, 'Países', Icons.public),
          (NivelUbicacion.ciudades, 'Ciudades', Icons.location_city_outlined),
          (NivelUbicacion.zonas, 'Zonas', Icons.place_outlined),
        ])
          ChoiceChip(
            avatar: Icon(icono, size: 18),
            label: Text(etiqueta),
            selected: nivel == n,
            onSelected:
                (_) => ref.read(nivelUbicacionProvider.notifier).state = n,
          ),
      ],
    );
  }
}

/// Un combo para filtrar por el nivel de arriba; 0 = todos.
class _FiltroPadre extends StatelessWidget {
  const _FiltroPadre({
    required this.etiqueta,
    required this.todos,
    required this.valor,
    required this.opciones,
    required this.onElegir,
  });

  final String etiqueta;
  final String todos;
  final int? valor;
  final List<(int, String)> opciones;
  final ValueChanged<int?> onElegir;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      key: ValueKey('$etiqueta-$valor-${opciones.length}'),
      width: 260,
      label: Text(etiqueta),
      initialSelection: valor ?? 0,
      dropdownMenuEntries: [
        DropdownMenuEntry(value: 0, label: todos),
        for (final (cod, texto) in opciones)
          DropdownMenuEntry(value: cod, label: texto),
      ],
      onSelected: (v) => onElegir(v == null || v == 0 ? null : v),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAÍSES
// ═══════════════════════════════════════════════════════════════════════════

class _NivelPaises extends ConsumerWidget {
  const _NivelPaises();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaPaisesProvider);
    final ocupado = ref.watch(
      operacionesUbicacionProvider.select((s) => s.ocupado),
    );

    return PantallaCatalogo<PaisEntity>(
      titulo: 'Ubicación geográfica',
      subtitulo: 'Países, ciudades y zonas que usan las direcciones y sucursales',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaPaisesProvider),
      botonNuevo: _btnNuevo,
      etiquetaNuevo: 'Nuevo país',
      icono: Icons.public,
      resumen:
          (items) => [
            DatoResumen('países', '${items.length}', icono: Icons.public),
            DatoResumen(
              'ciudades',
              '${items.fold<int>(0, (s, p) => s + p.ciudades)}',
              icono: Icons.location_city_outlined,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'personas con nacionalidad',
              '${items.fold<int>(0, (s, p) => s + p.personas)}',
              icono: Icons.badge_outlined,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Personas por nacionalidad',
      ranking:
          (items) => [for (final p in items) BarraResumen(p.pais, p.personas)],
      onNuevo: () => abrirFormularioPais(context),
      encabezadoCuerpo: const _SelectorNivel(),
      vacio: const MensajeVacio(
        icono: Icons.public_off,
        titulo: 'Todavía no hay países',
        detalle: 'Cuando se registre el primero aparecerá aquí.',
      ),
      contenido:
          (items) => ListaCatalogo<PaisEntity>(
            items: items,
            unidad: ('país', 'países'),
            pistaBusqueda: 'Buscar país',
            clave: (p) => 'pais-${p.codPais}',
            acento:
                (p) =>
                    p.ciudades + p.personas > 0
                        ? TonoDato.principal
                        : TonoDato.neutro,
            textoBusqueda: (p) => p.pais,
            tituloTarjeta: (p) => p.pais,
            detalleTarjeta:
                (p) =>
                    '${_cuenta(p.ciudades, 'ciudad', 'ciudades')} · '
                    '${_cuenta(p.personas, 'persona', 'personas')}',
            alTocar: (p) {
              ref.read(paisElegidoProvider.notifier).state = p.codPais;
              ref.read(nivelUbicacionProvider.notifier).state =
                  NivelUbicacion.ciudades;
            },
            columnas: [
              ColumnaCatalogo(
                titulo: 'Código',
                ancho: 80,
                celda: (c, p) => _codigo(c, p.codPais),
              ),
              ColumnaCatalogo(
                titulo: 'País',
                flex: 3,
                celda: (c, p) => _nombre(c, p.pais),
              ),
              ColumnaCatalogo(
                titulo: 'Ciudades',
                ancho: 96,
                alineacion: Alignment.centerRight,
                celda: (c, p) => _numero(c, p.ciudades),
              ),
              ColumnaCatalogo(
                titulo: 'Nacionalidad de',
                ancho: 130,
                alineacion: Alignment.centerRight,
                celda:
                    (c, p) => Text(
                      _cuenta(p.personas, 'persona', 'personas'),
                      style: c.numero(),
                    ),
              ),
            ],
            acciones: _acciones<PaisEntity>(
              ref,
              editar: (p) => abrirFormularioPais(context, existente: p),
              eliminar: (p) => eliminarPais(context, ref, p),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CIUDADES
// ═══════════════════════════════════════════════════════════════════════════

class _NivelCiudades extends ConsumerWidget {
  const _NivelCiudades();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaCiudadesProvider);
    final paises = ref.watch(listaPaisesProvider).valueOrNull ?? const [];
    final codPais = ref.watch(paisElegidoProvider);
    final ocupado = ref.watch(
      operacionesUbicacionProvider.select((s) => s.ocupado),
    );

    return PantallaCatalogo<CiudadEntity>(
      titulo: 'Ubicación geográfica',
      subtitulo: 'Países, ciudades y zonas que usan las direcciones y sucursales',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaCiudadesProvider),
      botonNuevo: _btnNuevo,
      etiquetaNuevo: 'Nueva ciudad',
      icono: Icons.location_city_outlined,
      resumen:
          (items) => [
            DatoResumen(
              'ciudades',
              '${items.length}',
              icono: Icons.location_city_outlined,
            ),
            DatoResumen(
              'zonas',
              '${items.fold<int>(0, (s, c) => s + c.zonas)}',
              icono: Icons.place_outlined,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'sucursales',
              '${items.fold<int>(0, (s, c) => s + c.sucursales)}',
              icono: Icons.storefront_outlined,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Zonas por ciudad',
      ranking:
          (items) => [for (final c in items) BarraResumen(c.ciudad, c.zonas)],
      onNuevo:
          () => abrirFormularioCiudad(
            context,
            paises: paises,
            codPaisInicial: codPais,
          ),
      encabezadoCuerpo: const _SelectorNivel(),
      vacio: const MensajeVacio(
        icono: Icons.location_city_outlined,
        titulo: 'Todavía no hay ciudades',
        detalle: 'Cuando se registre la primera aparecerá aquí.',
      ),
      contenido: (todas) {
        final items =
            codPais == null
                ? todas
                : todas.where((c) => c.codPais == codPais).toList();
        return ListaCatalogo<CiudadEntity>(
          key: ValueKey('ciudades-$codPais'),
          items: items,
          unidad: ('ciudad', 'ciudades'),
          pistaBusqueda: 'Buscar ciudad',
          filtros: [
            _FiltroPadre(
              etiqueta: 'País',
              todos: 'Todos los países',
              valor: codPais,
              opciones: [for (final p in paises) (p.codPais, p.pais)],
              onElegir:
                  (v) => ref.read(paisElegidoProvider.notifier).state = v,
            ),
          ],
          clave: (c) => 'ciudad-${c.codCiudad}',
          acento:
              (c) => c.sucursales > 0 ? TonoDato.terciario : TonoDato.principal,
          textoBusqueda: (c) => '${c.ciudad} ${c.pais}',
          tituloTarjeta: (c) => c.ciudad,
          detalleTarjeta:
              (c) =>
                  '${c.pais} · ${_cuenta(c.zonas, 'zona', 'zonas')} · '
                  '${_cuenta(c.sucursales, 'sucursal', 'sucursales')}',
          alTocar: (c) {
            ref.read(ciudadElegidaProvider.notifier).state = c.codCiudad;
            ref.read(nivelUbicacionProvider.notifier).state =
                NivelUbicacion.zonas;
          },
          columnas: [
            ColumnaCatalogo(
              titulo: 'Código',
              ancho: 80,
              celda: (c, x) => _codigo(c, x.codCiudad),
            ),
            ColumnaCatalogo(
              titulo: 'Ciudad',
              flex: 3,
              celda: (c, x) => _nombre(c, x.ciudad),
            ),
            ColumnaCatalogo(
              titulo: 'País',
              flex: 2,
              celda: (c, x) => Text(x.pais),
            ),
            ColumnaCatalogo(
              titulo: 'Zonas',
              ancho: 80,
              alineacion: Alignment.centerRight,
              celda: (c, x) => _numero(c, x.zonas),
            ),
            ColumnaCatalogo(
              titulo: 'Sucursales',
              ancho: 96,
              alineacion: Alignment.centerRight,
              celda: (c, x) => _numero(c, x.sucursales),
            ),
          ],
          acciones: _acciones<CiudadEntity>(
            ref,
            editar:
                (c) => abrirFormularioCiudad(
                  context,
                  paises: paises,
                  existente: c,
                ),
            eliminar: (c) => eliminarCiudad(context, ref, c),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONAS
// ═══════════════════════════════════════════════════════════════════════════

class _NivelZonas extends ConsumerWidget {
  const _NivelZonas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaZonasProvider);
    final ciudades = ref.watch(listaCiudadesProvider).valueOrNull ?? const [];
    final codCiudad = ref.watch(ciudadElegidaProvider);
    final ocupado = ref.watch(
      operacionesUbicacionProvider.select((s) => s.ocupado),
    );

    return PantallaCatalogo<ZonaEntity>(
      titulo: 'Ubicación geográfica',
      subtitulo: 'Países, ciudades y zonas que usan las direcciones y sucursales',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaZonasProvider),
      botonNuevo: _btnNuevo,
      etiquetaNuevo: 'Nueva zona',
      icono: Icons.place_outlined,
      resumen:
          (items) => [
            DatoResumen('zonas', '${items.length}', icono: Icons.place_outlined),
            DatoResumen(
              'personas con dirección',
              '${items.fold<int>(0, (s, z) => s + z.personas)}',
              icono: Icons.home_outlined,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'zonas sin uso',
              '${items.where((z) => z.personas == 0).length}',
              icono: Icons.remove_circle_outline,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Personas por zona',
      ranking:
          (items) => [for (final z in items) BarraResumen(z.zona, z.personas)],
      onNuevo:
          () => abrirFormularioZona(
            context,
            ciudades: ciudades,
            codCiudadInicial: codCiudad,
          ),
      encabezadoCuerpo: const _SelectorNivel(),
      vacio: const MensajeVacio(
        icono: Icons.place_outlined,
        titulo: 'Todavía no hay zonas',
        detalle: 'Cuando se registre la primera aparecerá aquí.',
      ),
      contenido: (todas) {
        final items =
            codCiudad == null
                ? todas
                : todas.where((z) => z.codCiudad == codCiudad).toList();
        return ListaCatalogo<ZonaEntity>(
          key: ValueKey('zonas-$codCiudad'),
          items: items,
          unidad: ('zona', 'zonas'),
          pistaBusqueda: 'Buscar zona',
          filtros: [
            _FiltroPadre(
              etiqueta: 'Ciudad',
              todos: 'Todas las ciudades',
              valor: codCiudad,
              opciones: [for (final c in ciudades) (c.codCiudad, c.ciudad)],
              onElegir:
                  (v) => ref.read(ciudadElegidaProvider.notifier).state = v,
            ),
          ],
          clave: (z) => 'zona-${z.codZona}',
          acento: (z) => z.personas > 0 ? TonoDato.principal : TonoDato.neutro,
          textoBusqueda: (z) => '${z.zona} ${z.ciudad}',
          tituloTarjeta: (z) => z.zona,
          detalleTarjeta:
              (z) =>
                  '${z.ciudad} · la tienen '
                  '${_cuenta(z.personas, 'persona', 'personas')}',
          columnas: [
            ColumnaCatalogo(
              titulo: 'Código',
              ancho: 80,
              celda: (c, z) => _codigo(c, z.codZona),
            ),
            ColumnaCatalogo(
              titulo: 'Zona',
              flex: 3,
              celda: (c, z) => _nombre(c, z.zona),
            ),
            ColumnaCatalogo(
              titulo: 'Ciudad',
              flex: 2,
              celda: (c, z) => Text(z.ciudad),
            ),
            ColumnaCatalogo(
              titulo: 'Personas',
              ancho: 96,
              alineacion: Alignment.centerRight,
              celda: (c, z) => _numero(c, z.personas),
            ),
          ],
          acciones: _acciones<ZonaEntity>(
            ref,
            editar:
                (z) => abrirFormularioZona(
                  context,
                  ciudades: ciudades,
                  existente: z,
                ),
            eliminar: (z) => eliminarZona(context, ref, z),
          ),
        );
      },
    );
  }
}
