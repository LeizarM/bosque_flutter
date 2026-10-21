/// Dos pantallas de Administración sobre los roles de los módulos:
///
/// - **Funciones por módulo** (tb_funcionesXModulo): reemplaza a
///   `tbFuncionModulo/FuncionesPorModulo.xhtml` (tb_vista codVista 57).
/// - **Asignación de funciones** (tb_asigFunModXEmpl): reemplaza a
///   `tbAsignaFuncXMod/AsignarFuncionPorModulo.xhtml` (codVista 56).
///
/// Ninguna de las dos vistas tiene botones en el ACL: como en el legacy, quien
/// tiene la pantalla en su menú puede escribir. Las asignaciones no se borran:
/// se activan o desactivan.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/funciones_modulo_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';
import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/funciones-modulo/dialogos_funciones.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

Widget _estado(bool activo, {String si = 'Activa', String no = 'Inactiva'}) =>
    PildoraDato(
      activo ? si : no,
      icono: activo ? Icons.check_circle_outline : Icons.pause_circle_outline,
      tono: activo ? TonoDato.principal : TonoDato.neutro,
    );

/// Cada módulo con su ícono: Cheques y Precios se distinguen sin leer.
Widget _modulo(String modulo) {
  final m = modulo.toLowerCase();
  final icono =
      m.contains('cheque')
          ? Icons.request_quote_outlined
          : m.contains('precio')
          ? Icons.sell_outlined
          : Icons.apps_outlined;
  return PildoraDato(
    modulo.isEmpty ? '—' : modulo,
    icono: icono,
    tono: TonoDato.terciario,
  );
}

Widget _negrita(BuildContext c, String t) => Text(
  t,
  style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
);

/// Un combo de filtro con «Todos» (valor 0 = sin filtro).
class _Combo extends StatelessWidget {
  const _Combo({
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
  Widget build(BuildContext context) => DropdownMenu<int>(
    key: ValueKey('$etiqueta-$valor-${opciones.length}'),
    width: 240,
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

// ═══════════════════════════════════════════════════════════════════════════
// FUNCIONES POR MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class FuncionesModuloScreen extends ConsumerWidget {
  const FuncionesModuloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaFuncionesModuloProvider);
    final modulos =
        ref.watch(modulosFuncionesProvider).valueOrNull ??
        const <OpcionEntity>[];
    final codModulo = ref.watch(moduloElegidoProvider);
    final ocupado = ref.watch(
      operacionesFuncionesModuloProvider.select((s) => s.ocupado),
    );

    return PantallaCatalogo<FuncionModuloEntity>(
      titulo: 'Funciones por módulo',
      subtitulo: 'Los roles que se asignan a los empleados en Cheques y Precios',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () {
        ref.invalidate(listaFuncionesModuloProvider);
        ref.invalidate(modulosFuncionesProvider);
      },
      etiquetaNuevo: 'Nueva función',
      icono: Icons.badge_outlined,
      resumen:
          (todas) => [
            DatoResumen(
              'funciones activas de ${todas.length}',
              '${todas.where((f) => f.activo).length}',
              icono: Icons.check_circle_outline,
            ),
            DatoResumen(
              'requeridas para operar',
              '${todas.where((f) => f.requerido).length}',
              icono: Icons.priority_high_rounded,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'asignaciones a empleados',
              '${todas.fold<int>(0, (s, f) => s + f.asignaciones)}',
              icono: Icons.group_outlined,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Asignaciones por función',
      ranking:
          (todas) => [
            for (final f in todas) BarraResumen(f.funcion, f.asignaciones),
          ],
      onNuevo:
          () => abrirFormularioFuncion(
            context,
            modulos: modulos,
            codModuloInicial: codModulo,
          ),
      vacio: const MensajeVacio(
        icono: Icons.badge_outlined,
        titulo: 'Todavía no hay funciones',
        detalle: 'Cuando se registre la primera aparecerá aquí.',
      ),
      contenido: (todas) {
        final items =
            codModulo == null
                ? todas
                : todas.where((f) => f.codModulo == codModulo).toList();
        return ListaCatalogo<FuncionModuloEntity>(
          key: ValueKey('funciones-$codModulo'),
          items: items,
          unidad: ('función', 'funciones'),
          pistaBusqueda: 'Buscar función',
          filtros: [
            _Combo(
              etiqueta: 'Módulo',
              todos: 'Todos los módulos',
              valor: codModulo,
              opciones: [for (final m in modulos) (m.codigo, m.nombre)],
              onElegir:
                  (v) => ref.read(moduloElegidoProvider.notifier).state = v,
            ),
          ],
          clave: (f) => '${f.codFuncMod}',
          acento: (f) => f.activo ? TonoDato.principal : TonoDato.neutro,
          textoBusqueda: (f) => '${f.funcion} ${f.modulo} ${f.detalle}',
          tituloTarjeta: (f) => f.funcion,
          detalleTarjeta:
              (f) =>
                  '${f.modulo} · ${f.asignaciones} '
                  '${f.asignaciones == 1 ? 'asignación' : 'asignaciones'}',
          pieTarjeta:
              (_, f) => Wrap(
                spacing: Esp.s,
                runSpacing: Esp.xs,
                children: [
                  _estado(f.activo),
                  if (f.requerido)
                    const Etiqueta(
                      texto: 'Requerida',
                      tono: TonoEtiqueta.aviso,
                    ),
                ],
              ),
          columnas: [
            ColumnaCatalogo(
              titulo: 'Módulo',
              flex: 2,
              celda: (c, f) => _modulo(f.modulo),
            ),
            ColumnaCatalogo(
              titulo: 'Función',
              flex: 3,
              celda:
                  (c, f) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _negrita(c, f.funcion),
                      if (f.detalle.isNotEmpty)
                        Text(
                          f.detalle,
                          style: c.apagado(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Requerida',
              ancho: 120,
              celda:
                  (c, f) => PildoraDato(
                    f.requerido ? 'Requerida' : 'Opcional',
                    icono:
                        f.requerido
                            ? Icons.priority_high_rounded
                            : Icons.remove,
                    tono: f.requerido ? TonoDato.terciario : TonoDato.neutro,
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Estado',
              ancho: 104,
              celda: (_, f) => _estado(f.activo),
            ),
            ColumnaCatalogo(
              titulo: 'Asignaciones',
              ancho: 120,
              alineacion: Alignment.centerRight,
              celda:
                  (c, f) => PildoraDato(
                    '${f.asignaciones}',
                    icono: Icons.group_outlined,
                    tono:
                        f.asignaciones > 0
                            ? TonoDato.principal
                            : TonoDato.neutro,
                  ),
            ),
          ],
          acciones: [
            AccionCatalogo(
              etiqueta: 'Editar',
              icono: Icons.edit_outlined,
              alElegir:
                  (f) => abrirFormularioFuncion(
                    context,
                    modulos: modulos,
                    existente: f,
                  ),
            ),
            AccionCatalogo(
              etiqueta: 'Eliminar',
              icono: Icons.delete_outline,
              alElegir: (f) => eliminarFuncion(context, ref, f),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ASIGNACIÓN DE FUNCIONES
// ═══════════════════════════════════════════════════════════════════════════

class AsignacionFuncionesScreen extends ConsumerWidget {
  const AsignacionFuncionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaAsignacionesProvider);
    final funciones =
        ref.watch(funcionesParaAsignarProvider).valueOrNull ??
        const <FuncionModuloEntity>[];
    final sucursales =
        ref.watch(sucursalesParaAsignarProvider).valueOrNull ??
        const <OpcionEntity>[];
    final filtro = ref.watch(filtroAsignacionesProvider);
    final ocupado = ref.watch(
      operacionesAsignacionProvider.select((s) => s.ocupado),
    );
    void cambiar(FiltroAsignaciones f) =>
        ref.read(filtroAsignacionesProvider.notifier).state = f;

    final filtros = <Widget>[
      _Combo(
        etiqueta: 'Función',
        todos: 'Todas las funciones',
        valor: filtro.codFuncMod,
        opciones: [
          for (final f in funciones) (f.codFuncMod.toInt(), f.funcion),
        ],
        onElegir:
            (v) => cambiar(
              FiltroAsignaciones(
                codFuncMod: v,
                codSucursal: filtro.codSucursal,
                activas: filtro.activas,
              ),
            ),
      ),
      _Combo(
        etiqueta: 'Sucursal',
        todos: 'Todas las sucursales',
        valor: filtro.codSucursal,
        opciones: [for (final s in sucursales) (s.codigo, s.nombre)],
        onElegir:
            (v) => cambiar(
              FiltroAsignaciones(
                codFuncMod: filtro.codFuncMod,
                codSucursal: v,
                activas: filtro.activas,
              ),
            ),
      ),
      Wrap(
        spacing: Esp.s,
        runSpacing: Esp.s,
        children: [
          for (final (valor, etiqueta) in [
            (true, 'Activas'),
            (false, 'Inactivas'),
            (null, 'Todas'),
          ])
            ChoiceChip(
              label: Text(etiqueta),
              selected: filtro.activas == valor,
              onSelected:
                  (_) => cambiar(
                    FiltroAsignaciones(
                      codFuncMod: filtro.codFuncMod,
                      codSucursal: filtro.codSucursal,
                      activas: valor,
                    ),
                  ),
            ),
        ],
      ),
    ];

    return PantallaCatalogo<AsignacionFuncionEntity>(
      titulo: 'Asignación de funciones',
      subtitulo: 'Quién cumple cada función de Cheques y Precios, por sucursal',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaAsignacionesProvider),
      etiquetaNuevo: 'Nueva asignación',
      icono: Icons.assignment_ind_outlined,
      resumen: (todas) {
        final activas = todas.where((a) => a.activo).toList();
        return [
          DatoResumen(
            'asignaciones activas',
            '${activas.length}',
            icono: Icons.check_circle_outline,
          ),
          DatoResumen(
            'empleados con alguna función',
            '${activas.map((a) => a.codEmpleado).toSet().length}',
            icono: Icons.person_outline,
            tono: TonoDato.terciario,
          ),
          DatoResumen(
            'inactivas',
            '${todas.length - activas.length}',
            icono: Icons.pause_circle_outline,
            tono: TonoDato.neutro,
          ),
        ];
      },
      tituloRanking: 'Activas por función',
      ranking: (todas) {
        final cuenta = <String, int>{};
        for (final a in todas.where((a) => a.activo)) {
          cuenta[a.funcion] = (cuenta[a.funcion] ?? 0) + 1;
        }
        return [for (final e in cuenta.entries) BarraResumen(e.key, e.value)];
      },
      onNuevo:
          () => abrirFormularioAsignacion(
            context,
            funciones: funciones,
            sucursales: sucursales,
            codFuncModInicial: filtro.codFuncMod,
            codSucursalInicial: filtro.codSucursal,
          ),
      vacio: const MensajeVacio(
        icono: Icons.assignment_ind_outlined,
        titulo: 'Todavía no hay asignaciones',
        detalle: 'Cuando se asigne la primera función aparecerá aquí.',
      ),
      contenido: (todas) {
        final items = todas.where(filtro.deja).toList();
        return ListaCatalogo<AsignacionFuncionEntity>(
          key: ValueKey(
            'asig-${filtro.codFuncMod}-${filtro.codSucursal}-${filtro.activas}',
          ),
          items: items,
          unidad: ('asignación', 'asignaciones'),
          pistaBusqueda: 'Buscar empleado o función',
          filtros: filtros,
          clave: (a) => '${a.codAsignacion}',
          acento: (a) => a.activo ? TonoDato.principal : TonoDato.neutro,
          textoBusqueda:
              (a) => '${a.empleado} ${a.funcion} ${a.sucursal} ${a.modulo}',
          tituloTarjeta: (a) => a.empleado,
          detalleTarjeta: (a) => '${a.funcion} · ${a.modulo}\n${a.sucursal}',
          pieTarjeta: (_, a) => _estado(a.activo),
          columnas: [
            ColumnaCatalogo(
              titulo: 'Empleado',
              flex: 3,
              celda: (c, a) => _negrita(c, a.empleado),
            ),
            ColumnaCatalogo(
              titulo: 'Función',
              flex: 2,
              celda:
                  (c, a) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.funcion,
                        style: Theme.of(
                          c,
                        ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                      ),
                      const SizedBox(height: Esp.xs),
                      _modulo(a.modulo),
                    ],
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Sucursal',
              flex: 2,
              celda:
                  (c, a) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.sucursal),
                      Text(a.empresa, style: c.apagado()),
                    ],
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Estado',
              ancho: 104,
              celda: (_, a) => _estado(a.activo),
            ),
          ],
          acciones: [
            AccionCatalogo(
              etiqueta: 'Desactivar',
              icono: Icons.toggle_on_outlined,
              visible: (a) => a.activo,
              alElegir: (a) => cambiarEstadoAsignacion(context, ref, a),
            ),
            AccionCatalogo(
              etiqueta: 'Activar',
              icono: Icons.toggle_off_outlined,
              visible: (a) => !a.activo,
              alElegir: (a) => cambiarEstadoAsignacion(context, ref, a),
            ),
          ],
        );
      },
    );
  }
}
