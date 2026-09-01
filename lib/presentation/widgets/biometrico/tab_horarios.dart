import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hrs_entity.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/buscador_empleado_biometrico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/// Pestaña "Horarios": las tres piezas del legacy "Definir Horas de Trabajo
/// en el Día" + "Programación Mensual por Empleado", como tres sub-pestañas
/// porque son tres flujos independientes que comparten sólo el dominio.
class TabHorarios extends StatelessWidget {
  const TabHorarios({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Plantillas de turno'),
              Tab(text: 'Horarios semanales'),
              Tab(text: 'Por empleado'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _SeccionPlantillas(),
                _SeccionSemanales(),
                _SeccionPorEmpleado(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1 · Plantillas de turno (tbio_bioHrs)
// ═══════════════════════════════════════════════════════════════════════════

class _SeccionPlantillas extends ConsumerWidget {
  const _SeccionPlantillas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bioHrsListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva plantilla de turno',
        onPressed: () => _abrirFormulario(context, ref),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => MensajeVacio(
              icono: Icons.error_outline,
              titulo: 'No se pudieron cargar los turnos',
              detalle: textoDeError(e),
            ),
        data: (lista) {
          if (lista.isEmpty) {
            return const MensajeVacio(
              icono: Icons.schedule_outlined,
              titulo: 'Sin plantillas de turno',
              detalle: 'Creá la primera con el botón +.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Esp.l),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = lista[i];
              return ListTile(
                title: Text(t.nombre),
                subtitle: Text(
                  '${horaCorta(t.ingreso)} – ${horaCorta(t.salida)}   '
                  '·   ${t.cantMinutos.toStringAsFixed(0)} min',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Ver historial',
                      icon: const Icon(Icons.history),
                      onPressed:
                          () => mostrarHistorialBitacora(
                            context,
                            tabla: 'BioHrs',
                            idRegistro: t.idHrs.toString(),
                            titulo: 'Historial de "${t.nombre}"',
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _abrirFormulario(context, ref, existente: t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _eliminar(context, ref, t),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    BioHrsEntity t,
  ) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar plantilla',
      mensaje:
          '¿Eliminar "${t.nombre}"? Si algún horario semanal la usa, se '
          'queda sin turno asignado ese día.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(biometricoRepositoryProvider)
          .registrarHorario({'idHrs': t.idHrs.toInt()}, 'D');
      ref.invalidate(bioHrsListProvider);
      if (context.mounted) avisar(context, 'Plantilla eliminada.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  static Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    BioHrsEntity? existente,
  }) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final cantDiasCtrl = TextEditingController(
      text: (existente?.cantDias ?? 1).toString(),
    );
    final cantMinutosCtrl = TextEditingController(
      text: (existente?.cantMinutos ?? 480).toString(),
    );
    final motivoCtrl = TextEditingController();
    TimeOfDay ingreso =
        existente?.ingreso != null
            ? TimeOfDay.fromDateTime(existente!.ingreso!)
            : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay salida =
        existente?.salida != null
            ? TimeOfDay.fromDateTime(existente!.salida!)
            : const TimeOfDay(hour: 17, minute: 0);

    final guardado = await showDialog<bool>(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, setState) => AlertDialog(
                  title: Text(existente == null ? 'Nueva plantilla' : 'Editar plantilla'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                        ),
                        const SizedBox(height: Esp.m),
                        Row(
                          children: [
                            Expanded(
                              child: _CampoHora(
                                etiqueta: 'Ingreso',
                                valor: ingreso,
                                onElegir: (v) => setState(() => ingreso = v),
                              ),
                            ),
                            const SizedBox(width: Esp.m),
                            Expanded(
                              child: _CampoHora(
                                etiqueta: 'Salida',
                                valor: salida,
                                onElegir: (v) => setState(() => salida = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Esp.m),
                        TextField(
                          controller: cantMinutosCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutos de la jornada',
                          ),
                        ),
                        const SizedBox(height: Esp.m),
                        TextField(
                          controller: cantDiasCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Días'),
                        ),
                        const SizedBox(height: Esp.m),
                        TextField(
                          controller: motivoCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Motivo',
                            hintText: 'Por qué se crea/edita esta plantilla',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed:
                          nombreCtrl.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(c, true),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
    if (guardado != true || !context.mounted) return;

    // Mismo ingreso Y misma salida que OTRA plantilla ya cargada — no bloquea
    // (puede haber una razón real para dos nombres distintos con el mismo
    // horario, p.ej. un turno de Admin y uno de Ventas ambos 08:00–17:00),
    // pero avisa antes de guardar en vez de dejar que se acumulen plantillas
    // repetidas sin que nadie se dé cuenta — que es justo lo que se ve en la
    // lista hoy.
    final otras = (ref.read(bioHrsListProvider).valueOrNull ?? []).where(
      (t) => existente == null || t.idHrs != existente.idHrs,
    );
    final duplicada =
        otras
            .where(
              (t) =>
                  t.ingreso != null &&
                  t.salida != null &&
                  t.ingreso!.hour == ingreso.hour &&
                  t.ingreso!.minute == ingreso.minute &&
                  t.salida!.hour == salida.hour &&
                  t.salida!.minute == salida.minute,
            )
            .firstOrNull;
    if (duplicada != null) {
      final seguir = await confirmar(
        context,
        titulo: 'Horario duplicado',
        mensaje:
            'Ya existe "${duplicada.nombre}" con el mismo horario '
            '(${horaCorta(duplicada.ingreso)} – ${horaCorta(duplicada.salida)}). '
            '¿Guardar esta también?',
        accion: 'Guardar igual',
      );
      if (!seguir || !context.mounted) return;
    }

    final hoy = DateTime.now();
    final payload = {
      'idHrs': existente?.idHrs.toInt() ?? 0,
      'nombre': nombreCtrl.text.trim(),
      'ingreso':
          DateTime(
            hoy.year,
            hoy.month,
            hoy.day,
            ingreso.hour,
            ingreso.minute,
          ).toIso8601String(),
      'salida':
          DateTime(
            hoy.year,
            hoy.month,
            hoy.day,
            salida.hour,
            salida.minute,
          ).toIso8601String(),
      'cantDias': double.tryParse(cantDiasCtrl.text) ?? 1,
      'cantMinutos': double.tryParse(cantMinutosCtrl.text) ?? 480,
      'estado': '1',
    };

    try {
      await ref
          .read(biometricoRepositoryProvider)
          .registrarHorario(
            payload,
            existente == null ? 'I' : 'U',
            motivo: motivoCtrl.text,
          );
      ref.invalidate(bioHrsListProvider);
      if (context.mounted) {
        avisar(context, existente == null ? 'Plantilla creada.' : 'Plantilla actualizada.');
      }
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

class _CampoHora extends StatelessWidget {
  const _CampoHora({
    required this.etiqueta,
    required this.valor,
    required this.onElegir,
  });
  final String etiqueta;
  final TimeOfDay valor;
  final ValueChanged<TimeOfDay> onElegir;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final elegido = await showTimePicker(context: context, initialTime: valor);
      if (elegido != null) onElegir(elegido);
    },
    child: InputDecorator(
      decoration: InputDecoration(labelText: etiqueta),
      child: Text(valor.format(context)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · Horarios semanales (tbio_bioHrSemanal + detalle)
// ═══════════════════════════════════════════════════════════════════════════

class _SeccionSemanales extends ConsumerWidget {
  const _SeccionSemanales();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bioHrSemanalListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo horario semanal',
        onPressed: () => _crear(context, ref),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => MensajeVacio(
              icono: Icons.error_outline,
              titulo: 'No se pudieron cargar los horarios semanales',
              detalle: textoDeError(e),
            ),
        data: (lista) {
          if (lista.isEmpty) {
            return const MensajeVacio(
              icono: Icons.calendar_view_week_outlined,
              titulo: 'Sin horarios semanales',
              detalle: 'Creá el primero con el botón +.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(Esp.l),
            itemCount: lista.length,
            itemBuilder:
                (context, i) => _TarjetaSemanal(horario: lista[i]),
          );
        },
      ),
    );
  }

  static Future<void> _crear(BuildContext context, WidgetRef ref) async {
    final nombreCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Nuevo horario semanal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: Esp.m),
                TextField(
                  controller: motivoCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Por qué se crea este horario semanal',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed:
                    nombreCtrl.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(c, true),
                child: const Text('Crear'),
              ),
            ],
          ),
    );
    if (ok != true || !context.mounted) return;

    // Acá no hay un rango horario propio para comparar (un horario semanal
    // recién creado todavía no tiene ningún día asignado — eso se carga
    // después, en "Horarios semanales" — así que el único duplicado
    // detectable en este punto es el nombre repetido).
    final nombre = nombreCtrl.text.trim();
    final duplicado =
        (ref.read(bioHrSemanalListProvider).valueOrNull ?? [])
            .where((s) => s.nombre.trim().toLowerCase() == nombre.toLowerCase())
            .firstOrNull;
    if (duplicado != null) {
      final seguir = await confirmar(
        context,
        titulo: 'Nombre repetido',
        mensaje:
            'Ya existe un horario semanal llamado "${duplicado.nombre}". '
            '¿Crear otro con el mismo nombre?',
        accion: 'Crear igual',
      );
      if (!seguir || !context.mounted) return;
    }

    try {
      await ref.read(biometricoRepositoryProvider).registrarHorarioSemanal({
        'idHrSemanal': 0,
        'nombre': nombre,
        'estado': '1',
      }, 'I', motivo: motivoCtrl.text);
      ref.invalidate(bioHrSemanalListProvider);
      if (context.mounted) avisar(context, 'Horario semanal creado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

class _TarjetaSemanal extends ConsumerStatefulWidget {
  const _TarjetaSemanal({required this.horario});
  final BioHrSemanalEntity horario;

  @override
  ConsumerState<_TarjetaSemanal> createState() => _TarjetaSemanalState();
}

class _TarjetaSemanalState extends ConsumerState<_TarjetaSemanal> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.m),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.horario.nombre),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ver historial',
                  icon: const Icon(Icons.history),
                  onPressed:
                      () => mostrarHistorialBitacora(
                        context,
                        tabla: 'BioHrSemanal',
                        idRegistro: widget.horario.idHrSemanal.toString(),
                        titulo: 'Historial de "${widget.horario.nombre}"',
                      ),
                ),
                IconButton(
                  icon: Icon(_abierto ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _abierto = !_abierto),
                ),
              ],
            ),
            onTap: () => setState(() => _abierto = !_abierto),
          ),
          if (_abierto)
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
              child: _DetalleSemanal(idHrSemanal: widget.horario.idHrSemanal),
            ),
        ],
      ),
    );
  }
}

class _DetalleSemanal extends ConsumerWidget {
  const _DetalleSemanal({required this.idHrSemanal});
  final BigInt idHrSemanal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(bioHrSemanalDetalleProvider(idHrSemanal));
    final turnosAsync = ref.watch(bioHrsListProvider);

    return detalleAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Esp.l),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(textoDeError(e)),
      data: (detalle) {
        final porDia = {for (final d in detalle) d.dia: d};
        return turnosAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(textoDeError(e)),
          data: (turnos) {
            return Column(
              children: [
                for (var dia = 1; dia <= 7; dia++)
                  _FilaDia(
                    dia: dia,
                    detalle: porDia[dia],
                    idHrSemanal: idHrSemanal,
                    turnos: turnos,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilaDia extends ConsumerWidget {
  const _FilaDia({
    required this.dia,
    required this.detalle,
    required this.idHrSemanal,
    required this.turnos,
  });

  final int dia;
  final BioHrSemanalDetalleEntity? detalle;
  final BigInt idHrSemanal;
  final List<BioHrsEntity> turnos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.xs),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(_diasSemana[dia - 1])),
          Expanded(
            child: DropdownButton<BigInt>(
              isExpanded: true,
              value: detalle != null && detalle!.idHrs > BigInt.zero
                  ? detalle!.idHrs
                  : null,
              hint: const Text('Sin asignar'),
              items: [
                for (final t in turnos)
                  DropdownMenuItem(
                    value: t.idHrs,
                    child: Text(
                      '${t.nombre}  (${horaCorta(t.ingreso)}–${horaCorta(t.salida)})',
                    ),
                  ),
              ],
              onChanged:
                  (idHrs) => _asignar(context, ref, idHrs),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _asignar(BuildContext context, WidgetRef ref, BigInt? idHrs) async {
    if (idHrs == null) return;
    try {
      final payload = {
        'idHrDet': detalle?.idHrDet.toInt() ?? 0,
        'idHrSemanal': idHrSemanal.toInt(),
        'idHrs': idHrs.toInt(),
        'dia': dia,
      };
      await ref
          .read(biometricoRepositoryProvider)
          .registrarHorarioSemanalDetalle(payload, detalle == null ? 'I' : 'U');
      ref.invalidate(bioHrSemanalDetalleProvider(idHrSemanal));
      if (context.mounted) avisar(context, 'Día actualizado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · Por empleado — "Programación Mensual por Empleado" del legacy
// ═══════════════════════════════════════════════════════════════════════════

class _SeccionPorEmpleado extends ConsumerWidget {
  const _SeccionPorEmpleado();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elegido = ref.watch(empleadoSeleccionadoBiometricoProvider);

    return Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const BuscadorEmpleadoBiometrico(),
          ),
          const SizedBox(height: Esp.xl),
          if (elegido == null)
            const MensajeVacio(
              icono: Icons.badge_outlined,
              titulo: 'Elegí un empleado',
              detalle: 'Buscá por nombre arriba para ver u otorgarle un horario.',
            )
          else
            Expanded(child: _AsignacionesDelEmpleado(idEmplead: elegido.idEmpleado)),
        ],
      ),
    );
  }
}

class _AsignacionesDelEmpleado extends ConsumerWidget {
  const _AsignacionesDelEmpleado({required this.idEmplead});
  final BigInt idEmplead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bioHrEmpleadoListProvider(idEmplead));
    final semanalesAsync = ref.watch(bioHrSemanalListProvider);
    final mes = ref.watch(mesSeleccionadoBiometricoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Horarios asignados', style: context.tituloSeccion()),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Asignar'),
              onPressed:
                  semanalesAsync.maybeWhen(
                    data: (semanales) =>
                        semanales.isEmpty
                            ? null
                            : () => _asignarNuevo(context, ref, semanales),
                    orElse: () => null,
                  ),
            ),
          ],
        ),
        const SizedBox(height: Esp.m),
        // Mismo `mesSeleccionadoBiometricoProvider` que Reporte/Resumen —
        // elegir el mes acá también lo mueve allá, a propósito: es el mismo
        // "qué mes estoy mirando" en toda la pestaña Biométrica.
        _SelectorDeMesHorarios(mes: mes),
        const SizedBox(height: Esp.m),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => MensajeVacio(
                  icono: Icons.error_outline,
                  titulo: 'No se pudieron cargar las asignaciones',
                  detalle: textoDeError(e),
                ),
            data: (lista) {
              if (lista.isEmpty) {
                return const MensajeVacio(
                  icono: Icons.event_note_outlined,
                  titulo: 'Sin horario asignado',
                  detalle: 'Este empleado no tiene ningún horario cargado todavía.',
                );
              }
              final semanales = semanalesAsync.valueOrNull ?? [];
              return ListView(
                children: [
                  // Por qué esto existe: un empleado puede tener N horarios
                  // distintos dentro del mismo mes (varias filas, cada una
                  // con su `inicio`) — la lista de abajo lo prueba, pero no
                  // deja ver DE UN VISTAZO qué tramo de días le tocó a cada
                  // uno. Esta franja hace exactamente el mismo cálculo
                  // "vigente día por día" que ya usa el reporte
                  // (BiometricoController.horarioVigente), sólo que acá se
                  // ve en vez de leerse en una fila de PDF.
                  _TimelineMensual(
                    asignaciones: lista,
                    mes: mes,
                    semanales: semanales,
                  ),
                  const SizedBox(height: Esp.l),
                  const Divider(height: 1),
                  const SizedBox(height: Esp.s),
                  Text('Historial completo', style: context.apagado()),
                  const SizedBox(height: Esp.xs),
                  for (final a in lista) ...[
                    _FilaAsignacion(
                      a: a,
                      semanal:
                          semanales
                              .where((s) => s.idHrSemanal == a.idHrSemanal)
                              .map((s) => s.nombre)
                              .firstOrNull,
                      onHistorial:
                          () => mostrarHistorialBitacora(
                            context,
                            tabla: 'BioHrEmpleado',
                            idRegistro: a.idHrEmpleado.toString(),
                            titulo: 'Historial de esta asignación',
                          ),
                      onEditar:
                          semanales.isEmpty
                              ? null
                              : () => _editar(context, ref, a, semanales),
                      onInactivar: () => _inactivar(context, ref, a),
                    ),
                    const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _inactivar(
    BuildContext context,
    WidgetRef ref,
    BioHrEmpleadoEntity a,
  ) async {
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Inactivar horario'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Dejar de aplicar este horario a partir de hoy?'),
                const SizedBox(height: Esp.m),
                TextField(
                  controller: motivoCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Por qué se inactiva — queda en el historial',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error,
                  foregroundColor: Theme.of(c).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Inactivar'),
              ),
            ],
          ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(biometricoRepositoryProvider).registrarHorarioEmpleado({
        'idHrEmpleado': a.idHrEmpleado.toInt(),
      }, 'A', motivo: motivoCtrl.text);
      ref.invalidate(bioHrEmpleadoListProvider(idEmplead));
      _sincronizarTrasCambioDeHorario(context, ref);
      if (context.mounted) avisar(context, 'Horario inactivado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  Future<void> _asignarNuevo(
    BuildContext context,
    WidgetRef ref,
    List<BioHrSemanalEntity> semanales,
  ) async {
    final resultado = await showDialog<_HorarioElegido>(
      context: context,
      builder: (c) => _DialogoAsignarHorario(semanales: semanales),
    );
    if (resultado == null || !context.mounted) return;

    try {
      await ref.read(biometricoRepositoryProvider).registrarHorarioEmpleado({
        'idHrEmpleado': 0,
        'idHrSemanal': resultado.semanal.idHrSemanal.toInt(),
        'idEmplead': idEmplead.toInt(),
        'inicio': resultado.inicio.toIso8601String(),
      }, 'I', motivo: resultado.motivo);
      ref.invalidate(bioHrEmpleadoListProvider(idEmplead));
      _sincronizarTrasCambioDeHorario(context, ref);
      if (context.mounted) avisar(context, 'Horario asignado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  /// Editar una asignación YA existente — mismo diálogo que "Asignar", en
  /// modo edición: precargado con su horario semanal y su `inicio` actual, y
  /// graba con ACCION='U' sobre el mismo `idHrEmpleado` en vez de crear una
  /// fila nueva. Cubre dos pedidos con un solo flujo: corregir la "Vigencia
  /// desde" de una asignación activa, y "reactivar" una inactivada — para el
  /// caso inactivo (inicio reseteado a 2000-01-01 por la SP) se le ofrece hoy
  /// como punto de partida en vez de esa fecha, porque mostrar "01/01/2000"
  /// en el selector no comunica nada útil.
  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    BioHrEmpleadoEntity a,
    List<BioHrSemanalEntity> semanales,
  ) async {
    final resultado = await showDialog<_HorarioElegido>(
      context: context,
      builder: (c) => _DialogoAsignarHorario(semanales: semanales, existente: a),
    );
    if (resultado == null || !context.mounted) return;

    try {
      await ref.read(biometricoRepositoryProvider).registrarHorarioEmpleado({
        'idHrEmpleado': a.idHrEmpleado.toInt(),
        'idHrSemanal': resultado.semanal.idHrSemanal.toInt(),
        'idEmplead': idEmplead.toInt(),
        'inicio': resultado.inicio.toIso8601String(),
      }, 'U', motivo: resultado.motivo);
      ref.invalidate(bioHrEmpleadoListProvider(idEmplead));
      _sincronizarTrasCambioDeHorario(context, ref);
      if (context.mounted) avisar(context, 'Horario actualizado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  /// El reporte (`reporteBiometricoProvider`) se cachea por empleado+mes: si
  /// ya se había abierto el mes actual para este empleado antes de
  /// asignar/editar/inactivar un horario, se invalida acá para que no quede
  /// mostrando datos viejos al volver a la pestaña Reporte.
  ///
  /// También dispara la regeneración de `tbio_bioHrXEmplExpandido` para el
  /// mes actual — best-effort, sin `await` (no bloquea el flujo principal,
  /// que ya terminó y avisó "Horario asignado/actualizado/inactivado." antes
  /// de esta línea) contra esa tabla, que sólo lee `p_Rpt_Biometrico` (el
  /// reporte LEGACY, confirmado el 2026-09-01 vía `sys.sql_modules`), no el
  /// reporte nuevo. Un fallo acá sigue sin interrumpir ni tapar el resultado
  /// de la acción principal — pero desde 2026-09-01, a pedido, si TERMINA
  /// bien se avisa con un segundo toast (llega uno o dos segundos después
  /// del primero, es una llamada de red aparte) para que quede constancia de
  /// que la sincronización en segundo plano también se completó.
  void _sincronizarTrasCambioDeHorario(BuildContext context, WidgetRef ref) {
    final mes = ref.read(mesSeleccionadoBiometricoProvider);
    ref.invalidate(
      reporteBiometricoProvider(
        ReporteBiometricoParams(
          codEmpleado: idEmplead,
          anio: mes.year,
          mes: mes.month,
        ),
      ),
    );
    ref
        .read(biometricoRepositoryProvider)
        .regenerarCalendarioExpandido(
          codEmpleado: idEmplead,
          anio: mes.year,
          mes: mes.month,
        )
        .then((_) {
          if (context.mounted) {
            avisar(context, 'Calendario del reporte legacy sincronizado.');
          }
        })
        .catchError((_) {});
  }
}

class _HorarioElegido {
  const _HorarioElegido(this.semanal, this.inicio, this.motivo);
  final BioHrSemanalEntity semanal;
  final DateTime inicio;
  final String? motivo;
}

/// Mismo patrón que `_SelectorDeMes`/`_SelectorDeMesResumen` (Reporte y
/// Resumen mensual): cada pestaña tiene su propia copia chica en vez de una
/// abstracción compartida — pero las tres leen y escriben el mismo
/// `mesSeleccionadoBiometricoProvider`, así que elegir el mes en cualquiera
/// de las tres pestañas queda elegido en todas.
class _SelectorDeMesHorarios extends ConsumerWidget {
  const _SelectorDeMesHorarios({required this.mes});
  final DateTime mes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mesSeleccionadoBiometricoProvider.notifier);
    final esMesActual =
        mes.year == DateTime.now().year && mes.month == DateTime.now().month;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed:
              () => notifier.state = DateTime(mes.year, mes.month - 1, 1),
        ),
        SizedBox(
          width: 170,
          child: Text(
            '${nombresMeses[mes.month - 1]} ${mes.year}',
            textAlign: TextAlign.center,
            style: context.tituloSeccion(),
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed:
              esMesActual
                  ? null
                  : () =>
                      notifier.state = DateTime(mes.year, mes.month + 1, 1),
        ),
      ],
    );
  }
}

/// Una fila del historial completo — separado de `_AsignacionesDelEmpleado`
/// sólo para que el `ListView` de arriba no cargue un `itemBuilder` gigante
/// con toda la lógica de Editar/Inactivar/vista previa adentro.
///
/// **"Editar" reemplaza al viejo "Reactivar" separado**: dar de baja
/// (`onInactivar`) sigue siendo su propia acción porque resetea `inicio` a
/// 2000-01-01 en la SP — no hay otra forma de expresar "dejó de aplicar" —
/// pero volver a activar una fila inactivada es sólo darle una vigencia
/// nueva, que es exactamente lo mismo que corregir la de una activa. Un solo
/// botón cubre los dos casos.
class _FilaAsignacion extends ConsumerStatefulWidget {
  const _FilaAsignacion({
    required this.a,
    required this.semanal,
    required this.onHistorial,
    required this.onEditar,
    required this.onInactivar,
  });

  final BioHrEmpleadoEntity a;
  final String? semanal;
  final VoidCallback onHistorial;
  final VoidCallback? onEditar;
  final VoidCallback onInactivar;

  @override
  ConsumerState<_FilaAsignacion> createState() => _FilaAsignacionState();
}

class _FilaAsignacionState extends ConsumerState<_FilaAsignacion> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final inactivo = a.inicio != null && a.inicio!.year <= 2000;
    return Column(
      children: [
        ListTile(
          leading: Icon(
            inactivo ? Icons.block_outlined : Icons.event_available_outlined,
          ),
          title: Text(widget.semanal ?? 'Horario #${a.idHrSemanal}'),
          subtitle: Text(
            inactivo ? 'Inactivo' : 'Vigente desde ${fechaCorta(a.inicio)}',
          ),
          onTap: () => setState(() => _abierto = !_abierto),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: _abierto ? 'Ocultar horas' : 'Ver horas',
                icon: Icon(_abierto ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _abierto = !_abierto),
              ),
              IconButton(
                tooltip: 'Ver historial',
                icon: const Icon(Icons.history),
                onPressed: widget.onHistorial,
              ),
              IconButton(
                tooltip: inactivo ? 'Reactivar / editar' : 'Editar vigencia',
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: widget.onEditar,
              ),
              if (!inactivo)
                IconButton(
                  tooltip: 'Inactivar',
                  icon: const Icon(Icons.block_outlined),
                  onPressed: widget.onInactivar,
                ),
            ],
          ),
        ),
        // La misma vista previa día-por-día del diálogo "Asignar" — "a lado
        // del nombre que muestre el horario semanal también": acá se pidió
        // exactamente eso, para el historial y no sólo al asignar uno nuevo.
        if (_abierto)
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.xxl, 0, Esp.l, Esp.m),
            child: _VistaPreviaHorario(
              detalleAsync: ref.watch(bioHrSemanalDetalleProvider(a.idHrSemanal)),
              turnosAsync: ref.watch(bioHrsListProvider),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Línea de tiempo del mes — "en el mes puede tener N horarios en distintos
// intervalos" hecho visible, no sólo leíble en una lista plana.
// ═══════════════════════════════════════════════════════════════════════════

/// Un tramo de días consecutivos del mes con el MISMO horario vigente
/// (`asignacion == null` = ningún horario cubre esos días todavía).
class _TramoMes {
  const _TramoMes({
    required this.desde,
    required this.hasta,
    required this.asignacion,
  });

  final DateTime desde;
  final DateTime hasta;
  final BioHrEmpleadoEntity? asignacion;

  int get dias => hasta.difference(desde).inDays + 1;
}

/// El mismo cálculo que `BiometricoController.horarioVigente` en el backend:
/// de todas las asignaciones con `inicio <= dia`, la de `inicio` más
/// reciente. Deliberadamente NO filtra por "activo": una fila "inactivada"
/// (inicio reseteado a 2000-01-01 por la SP) sigue siendo candidata para los
/// días en que ninguna otra asignación aplica todavía — igual que en el
/// reporte real, para que esta franja muestre exactamente lo que el reporte
/// va a calcular, no una versión simplificada.
BioHrEmpleadoEntity? _horarioVigenteEnDia(
  List<BioHrEmpleadoEntity> asignaciones,
  DateTime dia,
) {
  BioHrEmpleadoEntity? mejor;
  DateTime? mejorInicio;
  for (final a in asignaciones) {
    final inicio = a.inicio;
    if (inicio == null) continue;
    final inicioDia = DateTime(inicio.year, inicio.month, inicio.day);
    if (!inicioDia.isAfter(dia) &&
        (mejorInicio == null || inicioDia.isAfter(mejorInicio))) {
      mejor = a;
      mejorInicio = inicioDia;
    }
  }
  return mejor;
}

/// Recorre cada día del mes y agrupa los consecutivos con la misma
/// asignación vigente en un `_TramoMes`.
List<_TramoMes> _tramosDelMes(
  List<BioHrEmpleadoEntity> asignaciones,
  DateTime mes,
) {
  final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
  final tramos = <_TramoMes>[];
  BioHrEmpleadoEntity? actual;
  DateTime? desdeTramo;

  for (var dia = 1; dia <= ultimoDia; dia++) {
    final fecha = DateTime(mes.year, mes.month, dia);
    final vigente = _horarioVigenteEnDia(asignaciones, fecha);
    final mismoQueAntes = vigente?.idHrEmpleado == actual?.idHrEmpleado;
    if (!mismoQueAntes) {
      if (desdeTramo != null) {
        tramos.add(
          _TramoMes(
            desde: desdeTramo,
            hasta: fecha.subtract(const Duration(days: 1)),
            asignacion: actual,
          ),
        );
      }
      desdeTramo = fecha;
      actual = vigente;
    }
  }
  if (desdeTramo != null) {
    tramos.add(
      _TramoMes(
        desde: desdeTramo,
        hasta: DateTime(mes.year, mes.month, ultimoDia),
        asignacion: actual,
      ),
    );
  }
  return tramos;
}

/// Franja proporcional (un `Expanded` por tramo, `flex` = cantidad de días) +
/// leyenda. El color viene de `colorDeCatalogo` — la misma función que ya
/// colorea el cronograma de tipos de permiso en `permisos-rrhh`, por
/// **posición** de la asignación (ordenadas por `inicio`), no un `switch`
/// escrito a mano: acá el "catálogo" es la propia lista de asignaciones de
/// este empleado. `-1` (fuera de catálogo) es a propósito el color de "Sin
/// horario".
class _TimelineMensual extends StatelessWidget {
  const _TimelineMensual({
    required this.asignaciones,
    required this.mes,
    required this.semanales,
  });

  final List<BioHrEmpleadoEntity> asignaciones;
  final DateTime mes;
  final List<BioHrSemanalEntity> semanales;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tramos = _tramosDelMes(asignaciones, mes);

    final ordenadas = [...asignaciones]..sort((a, b) {
      final ai = a.inicio, bi = b.inicio;
      if (ai == null && bi == null) return 0;
      if (ai == null) return -1;
      if (bi == null) return 1;
      return ai.compareTo(bi);
    });
    final indicePorId = <BigInt, int>{
      for (var i = 0; i < ordenadas.length; i++) ordenadas[i].idHrEmpleado: i,
    };
    final nombresPorSemanal = {
      for (final s in semanales) s.idHrSemanal: s.nombre,
    };

    String etiquetaDe(BioHrEmpleadoEntity? a) =>
        a == null
            ? 'Sin horario'
            : (nombresPorSemanal[a.idHrSemanal] ?? 'Horario #${a.idHrSemanal}');

    ColorDeEstado colorDe(BioHrEmpleadoEntity? a) => colorDeCatalogo(
      cs,
      a == null ? -1 : indicePorId[a.idHrEmpleado] ?? -1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cómo se repartió ${nombresMeses[mes.month - 1]} ${mes.year}',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(Esquina.chica),
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                for (final t in tramos)
                  Expanded(
                    flex: t.dias,
                    child: Tooltip(
                      message:
                          '${etiquetaDe(t.asignacion)}\n'
                          '${fechaCorta(t.desde)} – ${fechaCorta(t.hasta)}',
                      child: Container(
                        color: colorDe(t.asignacion).fondo,
                        alignment: Alignment.center,
                        child:
                            t.dias >= 4
                                ? Text(
                                  etiquetaDe(t.asignacion),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorDe(t.asignacion).texto,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Esp.s),
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.xs,
          children: [
            for (final t in tramos)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorDe(t.asignacion).fondo,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Esp.xs),
                  Text(
                    '${fechaCorta(t.desde)}–${fechaCorta(t.hasta)}: '
                    '${etiquetaDe(t.asignacion)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// El diálogo "Asignar horario", con vista previa día-por-día de las horas
/// del horario semanal elegido — antes sólo mostraba el nombre ("ADM CONT 1",
/// "ALM 2"...) y no había forma de saber a qué horas correspondía sin
/// cancelar, ir a la pestaña "Horarios semanales" y volver.
///
/// **También sirve para editar**: con [existente] no null arranca precargado
/// con su horario semanal e `inicio` actuales (o con hoy, si esa fila estaba
/// inactivada — mostrar "01/01/2000", el valor que deja la SP al inactivar,
/// no comunicaría nada útil como punto de partida). El llamador decide si
/// eso termina en ACCION='I' (nueva) o 'U' (edición) — este diálogo sólo
/// junta los datos.
class _DialogoAsignarHorario extends ConsumerStatefulWidget {
  const _DialogoAsignarHorario({required this.semanales, this.existente});
  final List<BioHrSemanalEntity> semanales;
  final BioHrEmpleadoEntity? existente;

  @override
  ConsumerState<_DialogoAsignarHorario> createState() =>
      _DialogoAsignarHorarioState();
}

class _DialogoAsignarHorarioState
    extends ConsumerState<_DialogoAsignarHorario> {
  late BioHrSemanalEntity _elegido = _semanalInicial();
  late DateTime _inicio = _inicioInicial();
  final _motivoCtrl = TextEditingController();

  BioHrSemanalEntity _semanalInicial() {
    final existente = widget.existente;
    if (existente == null) return widget.semanales.first;
    return widget.semanales
        .where((s) => s.idHrSemanal == existente.idHrSemanal)
        .firstOrNull ??
        widget.semanales.first;
  }

  DateTime _inicioInicial() {
    final inicio = widget.existente?.inicio;
    final inactivo = inicio != null && inicio.year <= 2000;
    return inicio == null || inactivo ? DateTime.now() : inicio;
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(
      bioHrSemanalDetalleProvider(_elegido.idHrSemanal),
    );
    final turnosAsync = ref.watch(bioHrsListProvider);
    final editando = widget.existente != null;

    return AlertDialog(
      title: Text(editando ? 'Editar horario asignado' : 'Asignar horario'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<BioHrSemanalEntity>(
              value: _elegido,
              decoration: const InputDecoration(labelText: 'Horario semanal'),
              items: [
                for (final s in widget.semanales)
                  DropdownMenuItem(value: s, child: Text(s.nombre)),
              ],
              onChanged: (v) => setState(() => _elegido = v ?? _elegido),
            ),
            const SizedBox(height: Esp.m),
            Text('A qué hora entra y sale cada día:', style: context.apagado()),
            const SizedBox(height: Esp.xs),
            _VistaPreviaHorario(detalleAsync: detalleAsync, turnosAsync: turnosAsync),
            const SizedBox(height: Esp.m),
            InkWell(
              onTap: () async {
                final f = await showDatePicker(
                  context: context,
                  initialDate: _inicio,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(_inicio.year + 1),
                );
                if (f != null) setState(() => _inicio = f);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Vigente desde'),
                child: Text(fechaCorta(_inicio)),
              ),
            ),
            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivoCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivo',
                hintText:
                    editando
                        ? 'Por qué se cambia — queda en el historial'
                        : 'Por qué se asigna este horario',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(
                context,
                _HorarioElegido(_elegido, _inicio, _motivoCtrl.text),
              ),
          child: Text(editando ? 'Guardar' : 'Asignar'),
        ),
      ],
    );
  }
}

class _VistaPreviaHorario extends StatelessWidget {
  const _VistaPreviaHorario({required this.detalleAsync, required this.turnosAsync});
  final AsyncValue<List<BioHrSemanalDetalleEntity>> detalleAsync;
  final AsyncValue<List<BioHrsEntity>> turnosAsync;

  @override
  Widget build(BuildContext context) {
    if (detalleAsync.isLoading || turnosAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Esp.m),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final detalle = detalleAsync.valueOrNull ?? [];
    final turnos = {for (final t in turnosAsync.valueOrNull ?? []) t.idHrs: t};
    final porDia = {for (final d in detalle) d.dia: d};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var dia = 1; dia <= 7; dia++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(_diasSemana[dia - 1], style: context.apagado()),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final det = porDia[dia];
                        final turno = det != null ? turnos[det.idHrs] : null;
                        return Text(
                          turno == null
                              ? 'Sin asignar'
                              : '${horaCorta(turno.ingreso)} – ${horaCorta(turno.salida)}  (${turno.nombre})',
                          style: context.numero(fuerte: turno != null),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
