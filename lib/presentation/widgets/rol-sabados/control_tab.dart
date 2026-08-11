import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/intervencion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los controles del rol: qué tan bien está funcionando el default.
///
/// El módulo se diseñó para que el sistema resuelva solo y nadie tenga que
/// confirmar nada. Esta pestaña es cómo se verifica esa promesa: si las
/// intervenciones crecen, la regla por defecto no representa cómo se trabaja de
/// verdad, y hay que arreglar la regla — no seguir corrigiendo a mano.
class ControlTab extends ConsumerWidget {
  const ControlTab({super.key, required this.idRol});

  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.xl),
      children: [
        _Automatizacion(idRol: idRol),
        const SizedBox(height: Esp.m),
        _FeriadosDesincronizados(idRol: idRol),
        const SizedBox(height: Esp.m),
        _Permisos(idRol: idRol),
        const SizedBox(height: Esp.m),
        _Programaciones(idRol: idRol),
        const SizedBox(height: Esp.m),
        _Cumples(idRol: idRol),
        const SizedBox(height: Esp.m),
        _Intervenciones(idRol: idRol),
      ],
    );
  }
}

/// Marco común: título, subtítulo explicando qué se está mirando, y contenido.
class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.titulo,
    required this.explicacion,
    required this.hijo,
    this.icono,
    this.accion,
  });

  final String titulo;
  final String explicacion;
  final Widget hijo;
  final IconData? icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icono != null) ...[
                Icon(icono, size: 18, color: Theme.of(context).hintColor),
                const SizedBox(width: Esp.s),
              ],
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (accion != null) Flexible(child: accion!),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            explicacion,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: Esp.m),
          hijo,
        ],
      ),
    ),
  );
}

Widget _cargando() => const Padding(
  padding: EdgeInsets.symmetric(vertical: 12),
  child: Center(child: CircularProgressIndicator()),
);

Widget _error(BuildContext context, Object e) => Text(
  textoParaUsuario(e),
  style: Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
);

Widget _todoBien(BuildContext context, String texto) => Row(
  children: [
    Icon(
      Icons.check_circle_outline,
      size: 16,
      color: Theme.of(context).colorScheme.primary,
    ),
    const SizedBox(width: Esp.s),
    Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════

class _Automatizacion extends ConsumerWidget {
  const _Automatizacion({required this.idRol});
  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(automatizacionProvider(idRol));

    return _Bloque(
      icono: Icons.auto_awesome_outlined,
      titulo: 'Cuánto resuelve el sistema solo',
      explicacion:
          'Si "con decisión humana" crece, el default no le está sirviendo a '
          'nadie y conviene revisar la regla.',
      hijo: datos.when(
        loading: _cargando,
        error: (e, _) => _error(context, e),
        data: (a) {
          if (a == null || a.celdasTotales == 0) {
            return Text(
              'El rol todavía no tiene celdas.',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          final pct = a.porcentajeAutomatico;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: Peso.dato),
                  ),
                  const SizedBox(width: Esp.s),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'automático',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Esp.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct / 100, minHeight: 8),
              ),
              const SizedBox(height: Esp.m),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Metrica('celdas', a.celdasTotales),
                  _Metrica('generadas solas', a.generadasSolas),
                  _Metrica('con decisión humana', a.conDecisionHumana),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica(this.etiqueta, this.valor);
  final String etiqueta;
  final int valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$valor',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: Peso.titulo,
          fontFeatures: cifrasTabulares,
        ),
      ),
      Text(
        etiqueta,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════

class _FeriadosDesincronizados extends ConsumerStatefulWidget {
  const _FeriadosDesincronizados({required this.idRol});
  final int idRol;

  @override
  ConsumerState<_FeriadosDesincronizados> createState() =>
      _FeriadosDesincronizadosState();
}

class _FeriadosDesincronizadosState
    extends ConsumerState<_FeriadosDesincronizados> {
  bool _sincronizando = false;

  @override
  Widget build(BuildContext context) {
    final datos = ref.watch(feriadosDesincronizadosProvider(widget.idRol));

    return _Bloque(
      icono: Icons.event_busy_outlined,
      titulo: 'Feriados fuera de sincronía',
      explicacion:
          'El caso del puente: el feriado cae viernes, RR.HH. declara además el '
          'sábado, y el rol ya estaba generado. Nada lo avisa solo.',
      accion: datos.maybeWhen(
        data:
            (lista) =>
                lista.isEmpty
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                      onPressed: _sincronizando ? null : _sincronizar,
                      icon:
                          _sincronizando
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.sync, size: 16),
                      label: const Text('Sincronizar'),
                    ),
        orElse: () => const SizedBox.shrink(),
      ),
      hijo: datos.when(
        loading: _cargando,
        error: (e, _) => _error(context, e),
        data: (lista) {
          if (lista.isEmpty) {
            return _todoBien(
              context,
              'Los feriados del rol coinciden con lo que dice RR.HH. hoy.',
            );
          }
          return Column(
            children: [
              for (final s in lista)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.priority_high,
                    color: Theme.of(context).colorScheme.error,
                    size: 18,
                  ),
                  title: Text(fechaCorta(s.fecha)),
                  subtitle: Text(
                    s.motivoEspecial.isEmpty
                        ? 'Marcado en el rol: ${s.esFeriadoBool ? 'sí' : 'no'}'
                        : s.motivoEspecial,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    await ejecutarAccion(context, () async {
      await ref
          .read(rolSabadosAccionesProvider)
          .refrescarFeriados(idRol: widget.idRol);
      ref.invalidate(feriadosDesincronizadosProvider(widget.idRol));
    }, exito: 'Feriados sincronizados con RR.HH.');
    if (mounted) setState(() => _sincronizando = false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════

/// Vacaciones, bajas y permisos que la grilla todavía no refleja.
///
/// Es el control más caro de ignorar: la rotación A/B sabe a quién le toca, pero
/// no sabe quién está de vacaciones. Sin cruzar, la grilla dice que alguien viene
/// un sábado que RR.HH. ya le dio libre — y eso se descubre el sábado.
class _Permisos extends ConsumerStatefulWidget {
  const _Permisos({required this.idRol});
  final int idRol;

  @override
  ConsumerState<_Permisos> createState() => _PermisosState();
}

class _PermisosState extends ConsumerState<_Permisos> {
  bool _aplicando = false;

  @override
  Widget build(BuildContext context) {
    final datos = ref.watch(desfasesPermisoProvider(widget.idRol));

    return _Bloque(
      icono: Icons.beach_access_outlined,
      titulo: 'Vacaciones y permisos sin aplicar',
      explicacion:
          'Gente que figura trabajando un sábado que RR.HH. ya le dio libre. '
          'Los permisos se cargan después de generar el rol, así que hay que '
          'cruzarlos.',
      accion: datos.maybeWhen(
        data:
            (lista) =>
                lista.isEmpty
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                      onPressed: _aplicando ? null : _aplicar,
                      icon:
                          _aplicando
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.sync, size: 16),
                      label: const Text('Aplicar'),
                    ),
        orElse: () => const SizedBox.shrink(),
      ),
      hijo: datos.when(
        loading: _cargando,
        error: (e, _) => _error(context, e),
        data: (lista) {
          if (lista.isEmpty) {
            return _todoBien(
              context,
              'La grilla ya refleja todas las vacaciones y permisos cargados.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lista.length} celda(s) para corregir.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: Peso.titulo,
                ),
              ),
              const SizedBox(height: Esp.s),
              for (final d in lista.take(25))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.beach_access,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(d.nombreRol),
                  subtitle: Text(
                    '${fechaCorta(d.fecha)} · está de ${d.queDice}, '
                    'pero la grilla dice "${d.letraActual}"',
                  ),
                  trailing: Etiqueta(
                    texto: d.letraQueCorresponde,
                    tono: TonoEtiqueta.aviso,
                  ),
                ),
              if (lista.length > 25)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Se muestran 25 de ${lista.length}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _aplicar() async {
    setState(() => _aplicando = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .refrescarPermisos(idRol: widget.idRol),
      exito: 'Vacaciones y permisos aplicados a la grilla.',
    );
    if (mounted) setState(() => _aplicando = false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _Programaciones extends ConsumerWidget {
  const _Programaciones({required this.idRol});
  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(programacionesProvider(idRol));

    return _Bloque(
      icono: Icons.manage_accounts_outlined,
      titulo: 'Lo que decidieron los jefes',
      explicacion:
          'Un jefe le cambió el sábado a un dependiente. Lo que importa es la '
          'antelación: avisar el viernes no es lo mismo que avisar con un mes.',
      hijo: datos.when(
        loading: _cargando,
        error: (e, _) => _error(context, e),
        data: (lista) {
          if (lista.isEmpty) {
            return _todoBien(
              context,
              'Ningún jefe reprogramó a nadie: se está cumpliendo la rotación.',
            );
          }
          return Column(
            children: [
              for (final p in lista)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    p.avisoTardio ? Icons.warning_amber : Icons.check_circle,
                    size: 18,
                    color:
                        p.avisoTardio
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Sábado ${fechaCorta(p.sabado)} · '
                    '${p.celdasAfectadas} celda(s)',
                  ),
                  subtitle: Text(
                    '${p.diasAntelacion} días de antelación'
                    '${p.motivo.isEmpty ? '' : ' · ${p.motivo}'}',
                  ),
                  trailing:
                      p.vigente
                          ? null
                          : const Etiqueta(
                            texto: 'ANULADA',
                            tono: TonoEtiqueta.error,
                          ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _Cumples extends ConsumerWidget {
  const _Cumples({required this.idRol});
  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(cumplesSabadoProvider(idRol));

    return _Bloque(
      icono: Icons.cake_outlined,
      titulo: 'Cumpleaños que caen sábado',
      explicacion:
          'A quién le corresponde asueto y a quién se lo anuló un evento. Es la '
          'lista que RR.HH. necesita para saber a quién compensar.',
      hijo: datos.when(
        loading: _cargando,
        error: (e, _) => _error(context, e),
        data: (lista) {
          if (lista.isEmpty) {
            return _todoBien(
              context,
              'A nadie le cae el cumpleaños un sábado de este rol.',
            );
          }
          return Column(
            children: [
              for (final c in lista)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.nombreRol),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fechaCorta(c.fechaSabado)} · celda "${c.estadoActual}"',
                      ),
                      const SizedBox(height: Esp.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Etiqueta(
                          texto: c.situacionAsueto,
                          tono:
                              c.situacionAsueto == 'ASUETO'
                                  ? TonoEtiqueta.exito
                                  : TonoEtiqueta.aviso,
                        ),
                      ),
                    ],
                  ),
                  // La situación puede decir "ASUETO ANULADO POR EVENTO": como
                  // trailing aplastaría el nombre, va debajo del subtítulo.
                  isThreeLine: true,
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _Intervenciones extends ConsumerWidget {
  const _Intervenciones({required this.idRol});
  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(intervencionesProvider(idRol));

    return _Bloque(
      icono: Icons.edit_note_outlined,
      titulo: 'Intervenciones sobre el default',
      explicacion:
          'Las cuatro fuentes juntas: programaciones, cambios, convocatorias y '
          'correcciones manuales. Pocas filas = el default está bien calibrado.',
      hijo: datos.when(
        loading: _cargando,
        error: (e, _) => _error(context, e),
        data: (lista) {
          if (lista.isEmpty) {
            return _todoBien(
              context,
              'Nadie tocó nada: el rol se está cumpliendo tal como salió.',
            );
          }

          // Agrupar por tipo dice más que la lista cruda: si 40 de 45 son
          // CORRECCION MANUAL, el problema es la regla, no la gente.
          final porTipo = <String, int>{};
          for (final i in lista) {
            porTipo[i.tipoIntervencion] =
                (porTipo[i.tipoIntervencion] ?? 0) + 1;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final e in porTipo.entries)
                    Etiqueta(texto: '${e.key}: ${e.value}'),
                ],
              ),
              const SizedBox(height: Esp.m),
              for (final i in lista.take(30)) _FilaIntervencion(item: i),
              if (lista.length > 30)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Se muestran 30 de ${lista.length}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilaIntervencion extends StatelessWidget {
  const _FilaIntervencion({required this.item});
  final IntervencionEntity item;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text('${item.nombreRol} → "${item.quedoEn}"'),
    subtitle: Text(
      '${fechaCorta(item.fechaSabado)} · ${item.tipoIntervencion}'
      '${item.motivo.isEmpty ? '' : ' · ${item.motivo}'}',
    ),
  );
}
