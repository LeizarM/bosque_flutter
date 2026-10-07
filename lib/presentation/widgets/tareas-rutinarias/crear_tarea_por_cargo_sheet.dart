// Destino final: lib/presentation/widgets/tareas-rutinarias/crear_tarea_por_cargo_sheet.dart
import 'package:bosque_flutter/core/state/frecuencia_provider.dart';
import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/utils/nombres_parecidos.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/elegir_tarea_del_catalogo_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/data/repositories/tareas_por_cargo_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';

/// Una tarea del catálogo que se llama igual o parecido a lo que se escribe.
typedef TareaParecida = ({
  TareaRutinariaEntity tarea,
  NivelParecido nivel,
  double parecido,
});

/// El catálogo preparado para compararlo con lo que se escribe, tecla a tecla.
///
/// Está fuera del widget para poder probarlo. Lo caro es prepararlo (las
/// palabras de ~300 tareas y cuánto distingue cada una); compararlo contra un
/// nombre tarda menos de un milisegundo.
class CatalogoComparable {
  final List<TareaRutinariaEntity> tareas;
  final List<NombreComparable> _nombres;
  final PesoDePalabras _peso;

  CatalogoComparable._(this.tareas, this._nombres, this._peso);

  factory CatalogoComparable(List<TareaRutinariaEntity> tareas) {
    final nombres = [for (final t in tareas) NombreComparable(t.descripcion)];
    return CatalogoComparable._(tareas, nombres, PesoDePalabras(nombres));
  }

  /// Las que se llaman igual o parecido a [descripcion]: primero las iguales
  /// y después las parecidas, de más a menos.
  ///
  /// Devuelve cuáles y no un bool. Con dos "Arqueo de Caja" en el catálogo,
  /// saber que existe no alcanza para decidir: hay que ver su frecuencia. Y
  /// una parecida hay que leerla para saber si es la misma.
  List<TareaParecida> parecidasA(String descripcion) {
    final escrito = NombreComparable(descripcion);
    if (escrito.clave.isEmpty) return const [];

    final r = <TareaParecida>[];
    for (var i = 0; i < tareas.length; i++) {
      final nivel = escrito.comparar(_nombres[i], _peso);
      if (nivel == null) continue;
      r.add((
        tarea: tareas[i],
        nivel: nivel,
        parecido:
            nivel == NivelParecido.igual
                ? 1.0
                : escrito.parecidoCon(_nombres[i], _peso),
      ));
    }
    r.sort((a, b) {
      final porNivel = a.nivel.index.compareTo(b.nivel.index);
      if (porNivel != 0) return porNivel;
      final porParecido = b.parecido.compareTo(a.parecido);
      return porParecido != 0
          ? porParecido
          : a.tarea.idTarRuti.compareTo(b.tarea.idTarRuti);
    });
    return r;
  }
}

/// El título del aviso. Las iguales mandan: si hay alguna, es lo primero que
/// hay que saber.
String tituloDelAviso(List<TareaParecida> parecidas) {
  final iguales =
      parecidas.where((p) => p.nivel == NivelParecido.igual).length;
  if (iguales > 0) {
    return iguales == 1
        ? 'Ya existe una tarea con este nombre'
        : 'Ya existen $iguales tareas con este nombre';
  }
  return parecidas.length == 1
      ? 'Hay una tarea con un nombre parecido'
      : 'Hay ${parecidas.length} tareas con nombres parecidos';
}

/// Cuántas parecidas se listan en el aviso antes de resumir con "y N más".
const _parecidasALaVista = 4;

String _frecuenciaDe(TareaRutinariaEntity t) =>
    TareaPendienteTile.nombreFrecuencia[t.idFrec] ?? 'sin frecuencia';

/// Hoja "Nueva Tarea Rutinaria" — crea la tarea y la asigna a uno o más
/// cargos, en modo admin (sin restricción de subárbol).
///
/// Extraída de `_CrearTareaPorCargoSheet` (antes privada y vivía adentro de
/// `tareas_rutinarias_por_cargo_screen.dart`) para poder abrirla también
/// desde el catálogo global, donde no hay "un cargo actual" sino una lista de
/// cargos recién elegidos con [CopiarACargosDialog] en su modo de selección.
///
/// **Por qué [codCargos] y no [codCargo].** El endpoint
/// `registrarTareaRutinariaPorCargoAdmin` (via `TareasPorCargoImpl
/// .registrarPorCargoAdmin`) crea una tarea nueva y la asigna a un cargo en
/// una única transacción, pero solo procesa UN cargo por llamada. Elegir
/// varios cargos aquí arma una tarea rutinaria **independiente** por cada
/// cargo (misma descripción/frecuencia/fecha, filas distintas) — no es "una
/// tarea copiada a varios cargos" (eso ya existe, ver
/// [CopiarACargosDialog]/`TarRuXCargoImpl.registrar`, que reusa un mismo
/// idTarRuti). Por eso se hace un loop client-side, una llamada al repo por
/// codCargo, igual que `_copiarACargos` (en
/// `tareas_rutinarias_catalogo_screen.dart`) y
/// `TareasPorCargoNotifier.copiarACargos` ya loopean sobre sus propios
/// destinos: un solo try/catch alrededor del for, mensaje único al final.
///
/// **Por qué no llama al `StateNotifier` por-cargo.** Ir cargo por cargo vía
/// `tareasRutinariasPorCargoProvider(codCargo).notifier` funciona perfecto
/// cuando ese `codCargo` es el que la pantalla llamante ya tiene con un
/// `ref.watch` activo (así sigue sin cambios el alta de "Agregar tarea" de
/// [tareas_rutinarias_por_cargo_screen.dart]). Pero para cargos elegidos
/// desde el catálogo global nadie más los observa: ese provider es
/// `autoDispose` y, sin un listener vivo, Riverpod lo puede disponer a mitad
/// del `await` de red, dejando el `StateNotifier` "used after dispose". Por
/// eso aquí se llama al repositorio directo (mismo patrón que ya usan las dos
/// implementaciones de "copiar a cargos" en este módulo), y quien abre esta
/// hoja decide qué refrescar/avisar con el resultado — ver [Navigator.pop]
/// con `true`/`false` más abajo, igual que hace `NuevaTareaFormSheet` con su
/// propio llamador ([DependientesJefeScreen]).
class CrearTareaPorCargoSheet extends ConsumerStatefulWidget {
  final List<int> codCargos;

  CrearTareaPorCargoSheet({super.key, required this.codCargos})
    : assert(codCargos.isNotEmpty, 'codCargos no puede venir vacío.');

  @override
  ConsumerState<CrearTareaPorCargoSheet> createState() =>
      _CrearTareaPorCargoSheetState();
}

class _CrearTareaPorCargoSheetState
    extends ConsumerState<CrearTareaPorCargoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // El catálogo hace falta para avisar si el nombre ya existe. Esta hoja
    // se abre desde el organigrama, donde nadie lo cargó todavía.
    Future.microtask(() {
      if (mounted && ref.read(tareaRutinariaProvider).items.isEmpty) {
        ref.read(tareaRutinariaProvider.notifier).cargar();
      }
    });
  }

  final _repo = TareasPorCargoImpl();
  int? _idFrec;
  DateTime _fechaPartida = DateTime.now();

  /// Vigencia de la ASIGNACION al cargo (tac_tarRuXCargo.fechaInicio/fechaFin),
  /// distinta de [_fechaPartida] — que es de la TAREA (tac_tareaRutinaria) y
  /// dice desde cuando se calcula su repeticion.
  ///
  /// La diferencia importa: la misma tarea puede estar asignada a un cargo
  /// desde marzo y a otro desde julio. El generador ya respeta las dos:
  ///   and trxc.fechaInicio <= CAST(GETDATE() AS DATE)
  ///   and (trxc.fechaFin IS NULL OR trxc.fechaFin >= CAST(GETDATE() AS DATE))
  /// Lo unico que faltaba era que este formulario las dejara elegir; hasta
  /// ahora mandaba solo el codCargo y el SP les ponia "hoy" y NULL.
  DateTime _fechaInicioAsignacion = DateTime.now();
  DateTime? _fechaFinAsignacion;

  /// Sin fecha de fin. Arranca en `true` a proposito: una tarea rutinaria se
  /// crea para repetirse indefinidamente —sobre todo las diarias— y ponerle
  /// vencimiento es la excepcion, no la regla. Se apaga para elegir una fecha.
  bool _permanente = true;

  bool _guardando = false;

  /// El catálogo preparado para el aviso de parecidas. Se rehace solo cuando
  /// el provider trae otra lista, no en cada tecla.
  CatalogoComparable? _preparado;

  CatalogoComparable _catalogo(List<TareaRutinariaEntity> items) {
    final actual = _preparado;
    if (actual != null && identical(actual.tareas, items)) return actual;
    return _preparado = CatalogoComparable(items);
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  /// Crea la tarea una vez por cargo elegido. Mismo criterio de
  /// error-aggregation que `_copiarACargos`: un solo try/catch alrededor del
  /// for — la primera llamada que falla corta el loop (las anteriores ya
  /// quedaron creadas, no hace falta deshacerlas: cada una es una tarea
  /// rutinaria independiente, igual que cada asignación de "copiar a
  /// cargos" es independiente entre sí). Quien abrió la hoja se entera del
  /// resultado por el valor de [Navigator.pop], no por un aviso propio aquí:
  /// esta hoja no sabe si la pantalla llamante tiene su propio
  /// `ref.listen` para el caso de éxito (la pantalla de un cargo puntual sí
  /// lo tiene) o si tiene que avisar ella misma (el catálogo no lo tiene).
  Future<void> _guardar() async {
    // Descripción, frecuencia y que el fin no sea anterior al inicio los
    // valida p_registrar_tac_tareaRutinariaConCargos (errores 10, 11 y 18):
    // las reglas de registro van en SQL. Aquí queda solo lo que el servidor
    // no puede ver: el interruptor "permanente" de esta hoja.

    // Red de seguridad para quien no miró el aviso de arriba. No bloquea:
    // dos tareas pueden llamarse igual o parecido por buenos motivos (el
    // catálogo tiene "Arqueo de Caja" en diaria y en mensual, y son
    // distintas). Lo que no puede pasar es crearla sin enterarse.
    final parecidas = _catalogo(
      ref.read(tareaRutinariaProvider).items,
    ).parecidasA(_descripcionCtrl.text);
    if (parecidas.isNotEmpty) {
      final seguir = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(tituloDelAviso(parecidas)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in parecidas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '· ${textoDeTarea(p.tarea.descripcion)}  '
                          '(${p.nivel == NivelParecido.parecido ? 'parecida, ' : ''}'
                          '${_frecuenciaDe(p.tarea)}, tarea ${p.tarea.idTarRuti})',
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Si es la misma, cancela y agrégala desde "Elegir del '
                      'catálogo": así este cargo comparte la tarea en vez de '
                      'crear una copia.',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Crear de todos modos'),
                ),
              ],
            ),
      );
      if (seguir != true) return;
    }

    // Sin fecha de fin, al servidor le llega una asignación permanente: no
    // tiene cómo saber que el interruptor dice lo contrario.
    if (!_permanente && _fechaFinAsignacion == null) {
      HapticFeedback.lightImpact();
      mostrarAviso(
        context,
        'Elige la fecha de fin, o márcala como permanente.',
        tono: TonoAviso.aviso,
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      for (final codCargo in widget.codCargos) {
        await _repo.registrarPorCargoAdmin(
          descripcion: _descripcionCtrl.text.trim(),
          idFrec: _idFrec,
          fechaPartida: _fechaPartida,
          cargos: [
            {
              'codCargo': codCargo,
              // Las claves son las de CargoAsignacionDto; el SP las lee del
              // XML como @fi/@ff. Si el fin es null viaja null y la asignacion
              // queda permanente, que es lo que el generador entiende.
              'fechaInicio':
                  _fechaInicioAsignacion.toIso8601String().substring(0, 10),
              'fechaFin':
                  _fechaFinAsignacion?.toIso8601String().substring(0, 10),
            },
          ],
        );
      }
      if (mounted) cerrarRuta(context, true);
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tono: TonoAviso.error,
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frecuenciaState = ref.watch(frecuenciaProvider);
    final multiple = widget.codCargos.length > 1;

    // `watch` y no `read`: a esta hoja se llega desde la pantalla de un
    // cargo, donde el catálogo puede no estar cargado todavía. Con `read`, el
    // aviso se quedaría dormido para siempre en el caso más común.
    final parecidas = _catalogo(
      ref.watch(tareaRutinariaProvider).items,
    ).parecidasA(_descripcionCtrl.text);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nueva tarea rutinaria',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (multiple) ...[
                const SizedBox(height: 4),
                Text(
                  'Se asignará a ${widget.codCargos.length} cargo(s) elegido(s).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcionCtrl,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Qué hay que hacer',
                  border: OutlineInputBorder(),
                ),
                // Se avisa MIENTRAS escribe, no al guardar: decirlo después
                // de llenar frecuencia, fechas y vigencia llega tarde, y la
                // salida barata (cancelar y usar el catálogo) ya se sintió
                // cara.
                onChanged: (_) => setState(() {}),
              ),
              if (parecidas.isNotEmpty) _AvisoRepetida(parecidas: parecidas),
              const SizedBox(height: 16),
              Text(
                'Con qué frecuencia',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (frecuenciaState.cargando)
                const LinearProgressIndicator()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      frecuenciaState.items.map((f) {
                        final elegido = _idFrec == f.idFrec;
                        return ChoiceChip(
                          selected: elegido,
                          onSelected: (_) => setState(() => _idFrec = f.idFrec),
                          label: Text(f.descripcion ?? 'Sin nombre'),
                          backgroundColor: TareasColors.frecuencia(
                            context,
                            f.idFrec,
                          ),
                          selectedColor: TareasColors.frecuencia(
                            context,
                            f.idFrec,
                          ),
                          labelStyle: TextStyle(
                            color: TareasColors.frecuenciaTexto(
                              context,
                              f.idFrec,
                            ),
                            fontWeight:
                                elegido ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 16),
              Text(
                'Empieza a repetirse desde',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaPartida,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (elegida != null) setState(() => _fechaPartida = elegida);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(FormatearFecha.formatearFecha(_fechaPartida)),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Vigencia de la asignación',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Desde cuándo y hasta cuándo este cargo tiene esta tarea.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicioAsignacion,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (elegida != null) {
                    setState(() => _fechaInicioAsignacion = elegida);
                  }
                },
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  'Rige desde '
                  '${FormatearFecha.formatearFecha(_fechaInicioAsignacion)}',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _permanente,
                onChanged:
                    (v) => setState(() {
                      _permanente = v;
                      // Apagar el fin al volver a permanente y no solo
                      // ocultarlo: si quedara guardado, la asignacion se
                      // crearia con vencimiento sin que se vea en pantalla.
                      if (v) _fechaFinAsignacion = null;
                    }),
                title: const Text('Permanente'),
                subtitle: Text(
                  _permanente
                      ? 'Se sigue generando hasta que la desactives.'
                      : 'Deja de generarse después de una fecha.',
                ),
              ),
              if (!_permanente)
                OutlinedButton.icon(
                  onPressed: () async {
                    final elegida = await showDatePicker(
                      context: context,
                      initialDate:
                          _fechaFinAsignacion ?? _fechaInicioAsignacion,
                      firstDate: _fechaInicioAsignacion,
                      lastDate: DateTime(2100),
                    );
                    if (elegida != null) {
                      setState(() => _fechaFinAsignacion = elegida);
                    }
                  },
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(
                    _fechaFinAsignacion == null
                        ? 'Elegir fecha de fin'
                        : 'Hasta '
                            '${FormatearFecha.formatearFecha(_fechaFinAsignacion!)}',
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon:
                      _guardando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check),
                  label: Text(_guardando ? 'Guardando…' : 'Crear tarea'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El aviso bajo el campo de descripción.
///
/// Es un aviso, no un error: crear dos tareas con el mismo nombre, o con uno
/// parecido, es legítimo a veces. Lo que no era legítimo es hacerlo sin
/// saberlo, que es como el catálogo llegó a tener 7 descripciones repetidas.
class _AvisoRepetida extends StatelessWidget {
  final List<TareaParecida> parecidas;

  const _AvisoRepetida({required this.parecidas});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final chico = tema.textTheme.bodySmall;
    final apagado = chico?.copyWith(color: tema.colorScheme.onSurfaceVariant);
    final iguales = [
      for (final p in parecidas)
        if (p.nivel == NivelParecido.igual) p.tarea,
    ];
    final similares = [
      for (final p in parecidas)
        if (p.nivel == NivelParecido.parecido) p.tarea,
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TareasColors.pendiente(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: TareasColors.pendienteTexto(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloDelAviso(parecidas),
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TareasColors.pendienteTexto(context),
                  ),
                ),
                if (iguales.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // Con el mismo nombre, lo único que las distingue a la
                  // vista es la frecuencia.
                  Text(
                    iguales
                        .map(
                          (t) =>
                              TareaPendienteTile.nombreFrecuencia[t.idFrec] ??
                              'tarea ${t.idTarRuti}',
                        )
                        .join(' · '),
                    style: chico,
                  ),
                ],
                if (similares.isNotEmpty) ...[
                  if (iguales.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      similares.length == 1
                          ? 'Y una con un nombre parecido:'
                          : 'Y ${similares.length} con nombres parecidos:',
                      style: chico?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 2),
                  // Con un nombre parecido hay que leerlo entero: puede ser
                  // la misma o no.
                  for (final t in similares.take(_parecidasALaVista))
                    Text(
                      '· ${textoDeTarea(t.descripcion)} · ${_frecuenciaDe(t)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: chico,
                    ),
                  if (similares.length > _parecidasALaVista)
                    Text(
                      'y ${similares.length - _parecidasALaVista} más',
                      style: apagado,
                    ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Si es la misma, mejor agrégala desde "Elegir del catálogo".',
                  style: apagado,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
