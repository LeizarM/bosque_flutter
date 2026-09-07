// Destino final: lib/presentation/screens/tareas-rutinarias/mis_tareas_rutinarias_screen.dart
import 'package:bosque_flutter/core/state/bit_tarea_ruti_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reemplaza al wizard único "Tareas.xhtml" del sistema legacy: ahí un mismo
/// bean god-object (`WizardTareas`) mostraba, fila por fila, un botón
/// distinto según `idATR` (tipo de acción) y abría un diálogo embebido
/// distinto por tipo. Acá se mantiene la misma idea — la fila decide a
/// dónde navega — pero cada destino es su propia pantalla en vez de un
/// diálogo dentro de un formulario de 1800 líneas.
///
/// idBitTarea vive en `dbo.tb_vista` como codVista=78 ("tacTareas/Tareas"):
/// se reutiliza esa vista/ACL en vez de crear una nueva, así los 134
/// usuarios que ya tienen acceso hoy lo conservan sin que Marcelo tenga que
/// tocar `tb_vistaUsuario`.
class MisTareasRutinariasScreen extends ConsumerStatefulWidget {
  const MisTareasRutinariasScreen({super.key});

  @override
  ConsumerState<MisTareasRutinariasScreen> createState() =>
      _MisTareasRutinariasScreenState();
}

class _MisTareasRutinariasScreenState
    extends ConsumerState<MisTareasRutinariasScreen> {
  bool _soloPendientes = true;

  void _navegarPorTipo(BuildContext context, BitTareaRutiEntity tarea) {
    // fueRealizado==12 es "en curso"/pendiente de hacer (ver hallazgo de
    // WizardTareas.xhtml: los botones de Arqueo/Coches se deshabilitan
    // cuando fueRealizado!=12). Ya completada, no se vuelve a navegar.
    if (tarea.fueRealizado == 13) {
      mostrarAviso(context, 'Esta tarea ya fue completada.', tono: TonoAviso.aviso);
      return;
    }
    switch (tarea.idATR) {
      case 6:
        context.push(
          '/dashboard/tacTareas/Coches',
          extra: {
            'idTarRuti': tarea.idTarRuti,
            'idBitTarea': tarea.idBitTarea,
            'nombreTarea': tarea.nombreTareaRutinaria ?? 'Coches',
          },
        );
        break;
      case 4:
        context.push(
          '/dashboard/tacTareas/CajaFuerte',
          extra: {
            'idTarRuti': tarea.idTarRuti,
            'idBitTarea': tarea.idBitTarea,
            'nombreTarea': tarea.nombreTareaRutinaria ?? 'Caja Fuerte',
          },
        );
        break;
      case 2:
        context.push(
          '/dashboard/tacTareas/ArqueoCaja',
          extra: {
            'idTarRuti': tarea.idTarRuti,
            'idBitTarea': tarea.idBitTarea,
            'nombreTarea': tarea.nombreTareaRutinaria ?? 'Arqueo de Caja',
          },
        );
        break;
      case 7:
        context.push(
          '/dashboard/tacTareas/CajaChica',
          extra: {
            'idBitTarea': tarea.idBitTarea,
            'nombreTarea': tarea.nombreTareaRutinaria ?? 'Caja Chica',
          },
        );
        break;
      case 3:
        context.push(
          '/dashboard/tacTareas/CierreOperaciones',
          extra: {
            'idBitTarea': tarea.idBitTarea,
            'nombreTarea':
                tarea.nombreTareaRutinaria ?? 'Cierre de Operaciones',
          },
        );
        break;
      case 5:
        context.push(
          '/dashboard/tacTareas/VerificarCierre',
          extra: {
            'idBitTarea': tarea.idBitTarea,
            'nombreTarea':
                tarea.nombreTareaRutinaria ?? 'Verificar Cierre de Operaciones',
          },
        );
        break;
      case 8:
      case 9:
      case 10:
      case 11:
        // Planilla de Incapacidad / Evaluación Gerencia (Actas) y Verificar
        // Traspaso de Efectivo Entre Sistemas (TesBase, tesorería): las tres
        // viven en subsistemas fuera del alcance de esta migración de 19
        // tablas — 11 se creía tac_traspasoMovCaja hasta que el code-review
        // del legacy confirmó que en realidad es TesBaseManagedBean, sin
        // relación con ninguna tabla tac_*.
        mostrarAviso(
          context,
          'Este tipo de tarea se gestiona todavía desde el sistema anterior.',
          tono: TonoAviso.aviso,
        );
        break;
      default:
        _confirmarSimple(context, tarea);
    }
  }

  Future<void> _confirmarSimple(
    BuildContext context,
    BitTareaRutiEntity tarea,
  ) async {
    final resultado = await showDialog<int>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Se realizó esta tarea?'),
            content: Text(tarea.nombreTareaRutinaria ?? 'Tarea rutinaria'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(14),
                child: const Text('No aplica'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(0),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(13),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    if (resultado == null || !context.mounted) return;

    final codUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(bitTareaRutiProvider.notifier)
        .guardar(
          tarea.copyWith(fueRealizado: resultado, audUsuario: codUsuario),
        );
    if (!context.mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact(); // un solo haptic, en el frame del commit real
      mostrarAviso(context, 'Tarea actualizada.');
    } else {
      HapticFeedback.lightImpact(); // rechazo, nunca heavyImpact
      mostrarAviso(
        context,
        'No se pudo actualizar la tarea.',
        tono: TonoAviso.error,
      );
    }
  }

  /// Agrupa en Vencidas / Pendientes / Completadas, en ese orden — lo más
  /// urgente siempre arriba, sin importar cómo esté ordenada la lista de
  /// entrada. Solo agrega un encabezado si el grupo tiene algo: con el
  /// filtro "solo pendientes" activo (el caso más común) nunca aparece
  /// "Completadas", así que no se le resta lugar a lo que sí importa hoy.
  List<Object> _agruparPorUrgencia(List<BitTareaRutiEntity> items) {
    final ahora = DateTime.now();
    final vencidas = <BitTareaRutiEntity>[];
    final pendientes = <BitTareaRutiEntity>[];
    final completadas = <BitTareaRutiEntity>[];

    for (final t in items) {
      if (t.fueRealizado == 13 || t.fueRealizado == 14) {
        completadas.add(t);
      } else if (t.fechaPresentacion != null && t.fechaPresentacion!.isBefore(ahora)) {
        vencidas.add(t);
      } else {
        pendientes.add(t);
      }
    }

    final filas = <Object>[];
    void agregarGrupo(String titulo, IconData icono, Color Function(BuildContext) tono, List<BitTareaRutiEntity> grupo) {
      if (grupo.isEmpty) return;
      filas.add(_Encabezado(titulo, icono, tono, grupo.length));
      filas.addAll(grupo.map(_Fila.new));
    }

    agregarGrupo('Vencidas', Icons.error_outline, TareasColors.vencidoTexto, vencidas);
    agregarGrupo('Pendientes', Icons.schedule_outlined, TareasColors.pendienteTexto, pendientes);
    agregarGrupo('Completadas', Icons.check_circle_outline, TareasColors.realizadoTexto, completadas);
    return filas;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bitTareaRutiProvider);
    final notifier = ref.read(bitTareaRutiProvider.notifier);
    final miCodEmpleado = ref.watch(userProvider)?.codEmpleado;

    // El listado es genérico (mismo endpoint que usaría un supervisor viendo
    // todo el organigrama); acá se filtra del lado del cliente a "las mías",
    // igual que el resto de listados operativos de esta app (multas,
    // talonarios, etc. tampoco segmentan por usuario en el backend).
    final propias =
        state.items
            .where(
              (t) => miCodEmpleado == null || t.codEmpleado == miCodEmpleado,
            )
            .where((t) => !_soloPendientes || t.fueRealizado != 13)
            .toList()
          ..sort((a, b) {
            final fa = a.fechaPresentacion ?? DateTime(2100);
            final fb = b.fechaPresentacion ?? DateTime(2100);
            return fa.compareTo(fb);
          });

    // Antes era una sola lista plana, ordenada solo por fecha — con varias
    // "Vencida" seguidas se leía como una pared roja sin estructura. Agrupar
    // por urgencia real (vencidas primero, siempre) le da al ojo un punto de
    // entrada: "esto ya" vs "esto viene" vs "esto ya quedó atrás".
    final filas = _agruparPorUrgencia(propias);

    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas rutinarias'),
        actions: [
          PermissionWidget(
            buttonName: 'btnEmpAll',
            child: IconButton(
              tooltip: 'Ver de todos los empleados',
              icon: const Icon(Icons.groups_outlined),
              onPressed:
                  () => mostrarAviso(
                    context,
                    'El reporte por todos los empleados está en construcción.',
                    tono: TonoAviso.aviso,
                  ),
            ),
          ),
          IconButton(
            tooltip: _soloPendientes ? 'Mostrar todas' : 'Solo pendientes',
            icon: Icon(
              _soloPendientes ? Icons.filter_alt : Icons.filter_alt_off,
            ),
            onPressed: () => setState(() => _soloPendientes = !_soloPendientes),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.cargar,
        // AnimatedSwitcher: pasar de "cargando" a la lista (o al vacío) es un
        // cambio de estado real — un cross-fade evita el salto seco que se
        // siente como que la pantalla "parpadeó" en vez de haber cargado.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child:
              state.cargando && state.items.isEmpty
                  ? const Center(
                    key: ValueKey('cargando'),
                    child: CircularProgressIndicator(),
                  )
                  : propias.isEmpty
                  ? _EstadoVacio(
                    key: const ValueKey('vacio'),
                    soloPendientes: _soloPendientes,
                  )
                  : ListView.builder(
                    key: const ValueKey('lista'),
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: esAncho ? (anchoDisponible - 900) / 2 : 0,
                    ),
                    itemCount: filas.length,
                    itemBuilder: (context, i) {
                      final fila = filas[i];
                      if (fila is _Encabezado) {
                        final color = fila.tono(context);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, i == 0 ? 4 : 20, 16, 8),
                          child: Row(
                            children: [
                              Icon(fila.icono, size: 16, color: color),
                              const SizedBox(width: 6),
                              Text(
                                '${fila.titulo} (${fila.cantidad})',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final t = (fila as _Fila).tarea;
                      // Entrada suave y acotada — fade + deslizamiento corto,
                      // sin AnimationController propio: TweenAnimationBuilder
                      // resuelve solo una vez por ítem insertado y se queda
                      // en su valor final ante cualquier rebuild posterior.
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('tarea-${t.idBitTarea}'),
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: 200 + (i.clamp(0, 8) * 20),
                        ),
                        curve: Curves.easeOut,
                        builder:
                            (context, valor, child) => Opacity(
                              opacity: valor,
                              child: Transform.translate(
                                offset: Offset(0, (1 - valor) * 8),
                                child: child,
                              ),
                            ),
                        child: TareaPendienteTile(
                          tarea: t,
                          onTap: () => _navegarPorTipo(context, t),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/tacTareas/Dependientes'),
        icon: const Icon(Icons.supervisor_account_outlined),
        label: const Text('Mi equipo'),
      ),
    );
  }
}

/// Una fila de tarea dentro de un grupo — wrapper mínimo para que
/// `ListView.builder` distinga tarea vs. encabezado con un solo `is`.
class _Fila {
  final BitTareaRutiEntity tarea;
  const _Fila(this.tarea);
}

/// El título de un grupo (Vencidas/Pendientes/Completadas), con su color
/// semántico resuelto recién en `build` (necesita `BuildContext` por el
/// tema claro/oscuro — ver `TareasColors`).
class _Encabezado {
  final String titulo;
  final IconData icono;
  final Color Function(BuildContext) tono;
  final int cantidad;
  const _Encabezado(this.titulo, this.icono, this.tono, this.cantidad);
}

class _EstadoVacio extends StatelessWidget {
  final bool soloPendientes;

  const _EstadoVacio({super.key, required this.soloPendientes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Al día" es una noticia buena — se lo dice también con color,
            // no solo con el ícono, igual que el resto del módulo.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    soloPendientes
                        ? TareasColors.realizado(context)
                        : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                soloPendientes ? Icons.task_alt : Icons.inbox_outlined,
                size: 40,
                color:
                    soloPendientes
                        ? TareasColors.realizadoTexto(context)
                        : scheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              soloPendientes
                  ? 'Estás al día'
                  : 'Todavía no tienes tareas rutinarias',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              soloPendientes
                  ? 'No tienes tareas pendientes por hacer.'
                  : 'Cuando te asignen una, va a aparecer acá.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
