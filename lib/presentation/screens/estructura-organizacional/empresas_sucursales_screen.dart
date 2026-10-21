/// Empresas y sucursales: el ABM que le faltaba a la estructura organizacional
/// (`trhEstructuraOrganizacional/estructuraOrganizacional.xhtml`, vista 12).
/// Se abre desde la pantalla de estructura y usa sus botones del ACL:
/// btnNuevoEO/btnEditarEO/btnEliminarEO y btnNuevoSucXEmp/btnEditSucXEmp/
/// btnDelSucXEmp. Tocar una empresa muestra sus sucursales.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/empresas_sucursales_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/presentation/widgets/estructura-organizacional/dialogos_empresas_sucursales.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

class EmpresasSucursalesScreen extends ConsumerWidget {
  const EmpresasSucursalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El filtro vive mientras viva la pantalla: tocar una empresa lo escribe
    // antes de que el nivel de sucursales lo escuche.
    ref.watch(empresaElegidaProvider);
    return switch (ref.watch(nivelEstructuraProvider)) {
      NivelEstructura.empresas => const _NivelEmpresas(),
      NivelEstructura.sucursales => const _NivelSucursales(),
    };
  }
}

const _subtitulo = 'Las empresas del grupo y sus sucursales';

class _Selector extends ConsumerWidget {
  const _Selector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivel = ref.watch(nivelEstructuraProvider);
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (final (n, etiqueta, icono) in [
          (NivelEstructura.empresas, 'Empresas', Icons.business_outlined),
          (NivelEstructura.sucursales, 'Sucursales', Icons.store_outlined),
        ])
          ChoiceChip(
            avatar: Icon(icono, size: 18),
            label: Text(etiqueta),
            selected: nivel == n,
            onSelected:
                (_) => ref.read(nivelEstructuraProvider.notifier).state = n,
          ),
      ],
    );
  }
}

Widget _negrita(BuildContext c, String t) => Text(
  t,
  style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
);

Widget _numero(BuildContext c, int n) => Text('$n', style: c.numero());

class _NivelEmpresas extends ConsumerWidget {
  const _NivelEmpresas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaEmpresasProvider);
    final empresas = lectura.valueOrNull ?? const <EmpresaEntity>[];
    final ocupado = ref.watch(
      operacionesEmpresasSucursalesProvider.select((s) => s.ocupado),
    );

    return PantallaCatalogo<EmpresaEntity>(
      titulo: 'Empresas y sucursales',
      subtitulo: _subtitulo,
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaEmpresasProvider),
      botonNuevo: 'btnNuevoEO',
      etiquetaNuevo: 'Nueva empresa',
      icono: Icons.domain_outlined,
      resumen:
          (items) => [
            DatoResumen(
              'empresas',
              '${items.length}',
              icono: Icons.domain_outlined,
            ),
            DatoResumen(
              'sucursales',
              '${items.fold<int>(0, (s, e) => s + e.sucursales)}',
              icono: Icons.storefront_outlined,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'cargos',
              '${items.fold<int>(0, (s, e) => s + e.cargos)}',
              icono: Icons.work_outline,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Cargos por empresa',
      ranking:
          (items) => [for (final e in items) BarraResumen(e.nombre, e.cargos)],
      onNuevo: () => abrirFormularioEmpresa(context, empresas: empresas),
      encabezadoCuerpo: const _Selector(),
      vacio: const MensajeVacio(
        icono: Icons.business_outlined,
        titulo: 'Todavía no hay empresas',
        detalle: 'Cuando se registre la primera aparecerá aquí.',
      ),
      contenido:
          (items) => ListaCatalogo<EmpresaEntity>(
            items: items,
            unidad: ('empresa', 'empresas'),
            pistaBusqueda: 'Buscar empresa',
            clave: (e) => 'empresa-${e.codEmpresa}',
            acento:
                (e) => e.sucursales > 0 ? TonoDato.principal : TonoDato.neutro,
            textoBusqueda: (e) => '${e.nombre} ${e.sigla} ${e.padre}',
            tituloTarjeta: (e) => e.nombre,
            detalleTarjeta:
                (e) =>
                    '${e.sucursales} sucursales · ${e.cargos} cargos'
                    '${e.padre.isEmpty ? '' : ' · depende de ${e.padre}'}',
            alTocar: (e) {
              ref.read(empresaElegidaProvider.notifier).state = e.codEmpresa;
              ref.read(nivelEstructuraProvider.notifier).state =
                  NivelEstructura.sucursales;
            },
            columnas: [
              ColumnaCatalogo(
                titulo: 'Empresa',
                flex: 3,
                celda: (c, e) => _negrita(c, e.nombre),
              ),
              ColumnaCatalogo(
                titulo: 'Sigla',
                ancho: 80,
                celda: (c, e) => Text(e.sigla.isEmpty ? '—' : e.sigla),
              ),
              ColumnaCatalogo(
                titulo: 'Depende de',
                flex: 2,
                celda: (c, e) => Text(e.padre.isEmpty ? '—' : e.padre),
              ),
              ColumnaCatalogo(
                titulo: 'Sucursales',
                ancho: 96,
                alineacion: Alignment.centerRight,
                celda: (c, e) => _numero(c, e.sucursales),
              ),
              ColumnaCatalogo(
                titulo: 'Cargos',
                ancho: 80,
                alineacion: Alignment.centerRight,
                celda: (c, e) => _numero(c, e.cargos),
              ),
            ],
            acciones: [
              if (tienePermisoDeBoton(ref, 'btnEditarEO'))
                AccionCatalogo(
                  etiqueta: 'Editar',
                  icono: Icons.edit_outlined,
                  alElegir:
                      (e) => abrirFormularioEmpresa(
                        context,
                        empresas: empresas,
                        existente: e,
                      ),
                ),
              if (tienePermisoDeBoton(ref, 'btnEliminarEO'))
                AccionCatalogo(
                  etiqueta: 'Eliminar',
                  icono: Icons.delete_outline,
                  alElegir: (e) => eliminarEmpresa(context, ref, e),
                ),
            ],
          ),
    );
  }
}

class _NivelSucursales extends ConsumerWidget {
  const _NivelSucursales();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaSucursalesProvider);
    final empresas = ref.watch(listaEmpresasProvider).valueOrNull ?? const [];
    final ciudades =
        ref.watch(ciudadesParaSucursalProvider).valueOrNull ?? const [];
    final codEmpresa = ref.watch(empresaElegidaProvider);
    final ocupado = ref.watch(
      operacionesEmpresasSucursalesProvider.select((s) => s.ocupado),
    );

    return PantallaCatalogo<SucursalEntity>(
      titulo: 'Empresas y sucursales',
      subtitulo: _subtitulo,
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaSucursalesProvider),
      botonNuevo: 'btnNuevoSucXEmp',
      etiquetaNuevo: 'Nueva sucursal',
      icono: Icons.storefront_outlined,
      resumen:
          (items) => [
            DatoResumen(
              'sucursales activas',
              '${items.where((s) => s.estado == 1).length}',
              icono: Icons.storefront_outlined,
            ),
            DatoResumen(
              'cargos asignados',
              '${items.fold<int>(0, (s, x) => s + x.cargos)}',
              icono: Icons.work_outline,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'ciudades',
              '${items.map((s) => s.codCiudad).toSet().length}',
              icono: Icons.location_city_outlined,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Cargos por sucursal',
      ranking:
          (items) => [for (final s in items) BarraResumen(s.nombre, s.cargos)],
      onNuevo:
          () => abrirFormularioSucursal(
            context,
            empresas: empresas,
            ciudades: ciudades,
            codEmpresaInicial: codEmpresa,
          ),
      encabezadoCuerpo: const _Selector(),
      vacio: const MensajeVacio(
        icono: Icons.store_outlined,
        titulo: 'Todavía no hay sucursales',
        detalle: 'Cuando se registre la primera aparecerá aquí.',
      ),
      contenido: (todas) {
        final items =
            codEmpresa == null
                ? todas
                : todas.where((s) => s.codEmpresa == codEmpresa).toList();
        return ListaCatalogo<SucursalEntity>(
          key: ValueKey('sucursales-$codEmpresa'),
          items: items,
          unidad: ('sucursal', 'sucursales'),
          pistaBusqueda: 'Buscar sucursal o ciudad',
          filtros: [
            DropdownMenu<int>(
              key: ValueKey('empresa-$codEmpresa-${empresas.length}'),
              width: 240,
              label: const Text('Empresa'),
              initialSelection: codEmpresa ?? 0,
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: 0, label: 'Todas las empresas'),
                for (final e in empresas)
                  DropdownMenuEntry(value: e.codEmpresa, label: e.nombre),
              ],
              onSelected:
                  (v) =>
                      ref.read(empresaElegidaProvider.notifier).state =
                          v == null || v == 0 ? null : v,
            ),
          ],
          clave: (s) => 'sucursal-${s.codSucursal}',
          acento: (s) => s.estado == 1 ? TonoDato.principal : TonoDato.neutro,
          textoBusqueda:
              (s) => '${s.nombre} ${s.nombreEmpresa} ${s.nombreCiudad}',
          tituloTarjeta: (s) => s.nombre,
          detalleTarjeta:
              (s) =>
                  '${s.nombreEmpresa} · ${s.nombreCiudad} · ${s.cargos} cargos',
          pieTarjeta:
              (_, s) =>
                  s.estado == 1
                      ? null
                      : const Etiqueta(
                        texto: 'Inactiva',
                        tono: TonoEtiqueta.neutro,
                      ),
          columnas: [
            ColumnaCatalogo(
              titulo: 'Sucursal',
              flex: 3,
              celda: (c, s) => _negrita(c, s.nombre),
            ),
            ColumnaCatalogo(
              titulo: 'Empresa',
              flex: 2,
              celda: (c, s) => Text(s.nombreEmpresa),
            ),
            ColumnaCatalogo(
              titulo: 'Ciudad',
              flex: 2,
              celda: (c, s) => Text(s.nombreCiudad),
            ),
            ColumnaCatalogo(
              titulo: 'Cargos',
              ancho: 80,
              alineacion: Alignment.centerRight,
              celda: (c, s) => _numero(c, s.cargos),
            ),
            ColumnaCatalogo(
              titulo: 'Estado',
              ancho: 96,
              celda:
                  (_, s) => Etiqueta(
                    texto: s.estado == 1 ? 'Activa' : 'Inactiva',
                    tono:
                        s.estado == 1 ? TonoEtiqueta.exito : TonoEtiqueta.neutro,
                  ),
            ),
          ],
          acciones: [
            if (tienePermisoDeBoton(ref, 'btnEditSucXEmp'))
              AccionCatalogo(
                etiqueta: 'Editar',
                icono: Icons.edit_outlined,
                alElegir:
                    (s) => abrirFormularioSucursal(
                      context,
                      empresas: empresas,
                      ciudades: ciudades,
                      existente: s,
                    ),
              ),
            if (tienePermisoDeBoton(ref, 'btnDelSucXEmp'))
              AccionCatalogo(
                etiqueta: 'Eliminar',
                icono: Icons.delete_outline,
                alElegir: (s) => eliminarSucursal(context, ref, s),
              ),
          ],
        );
      },
    );
  }
}
