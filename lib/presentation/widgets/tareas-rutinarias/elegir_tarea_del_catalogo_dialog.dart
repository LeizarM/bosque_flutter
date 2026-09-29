// Destino final: lib/presentation/widgets/tareas-rutinarias/elegir_tarea_del_catalogo_dialog.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/utils/nombres_parecidos.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Una descripción del catálogo lista para mostrar: los espacios y saltos de
/// línea seguidos quedan en un solo espacio.
///
/// El catálogo conserva el formato de quien cargó cada tarea en el sistema
/// anterior. En BOSQUE2PRUEBA, 81 de las 292 descripciones separan las
/// palabras con dos espacios y 133 tienen saltos de línea. En una lista eso se
/// ve como texto justificado y como filas de alturas desparejas.
String textoDeTarea(String descripcion) =>
    descripcion.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Lo que se compara al ordenar: sin mayúsculas, sin tildes y con los espacios
/// colapsados.
///
/// Antes se comparaba el texto tal cual. "aplicar o supervisar" no encontraba
/// "Aplicar  o  supervisar" (con dos espacios), "gestion" no encontraba
/// "gestión", y ordenar por código de carácter mandaba al final cualquier
/// tarea que empezara con minúscula o con tilde.
String claveDeBusqueda(String texto) => sinTildes(textoDeTarea(texto));

typedef CatalogoSeparado = ({
  List<TareaRutinariaEntity> disponibles,
  List<TareaRutinariaEntity> inactivas,
});

/// Reparte el catálogo en lo que se puede elegir y lo que no.
///
/// Está fuera del widget para poder probarla: es la regla que impide crear
/// duplicados, y el resto del diálogo es presentación.
///
/// - `disponibles`: el cargo no la tiene. Se pueden elegir.
/// - `inactivas`: el cargo la tiene desactivada. NO se ofrecen para agregar
///   —insertarlas dejaría dos filas para el mismo par tarea/cargo, porque el
///   índice único solo mira las activas— pero se muestran, porque si alguien
///   la está buscando necesita saber que ya está y que lo que corresponde es
///   reactivarla.
/// - Las que el cargo tiene activas no aparecen en ninguna de las dos.
///
/// Las dos listas salen ordenadas por [claveDeBusqueda] y, a igual texto, por
/// id: el catálogo tiene descripciones repetidas y el orden entre ellas no
/// puede depender de cómo llegaron del servidor.
///
/// La búsqueda encuentra también las palabras en otro orden o con un error de
/// tipeo ([NombreComparable.respondeA]): quien busca "caja arqueo" está
/// buscando "Arqueo de Caja", y si no la encuentra termina creándola de nuevo.
CatalogoSeparado separarCatalogo({
  required List<TareaRutinariaEntity> catalogo,
  required Map<int, bool> yaAsignadas,
  String busqueda = '',
}) {
  final consulta = NombreComparable(busqueda);
  final claves = Map<TareaRutinariaEntity, String>.identity();
  String clave(TareaRutinariaEntity t) =>
      claves.putIfAbsent(t, () => claveDeBusqueda(t.descripcion));

  // Las dos listas de abajo no se pisan (una tarea está en una o en la
  // otra), así que cada nombre se prepara una sola vez por búsqueda.
  bool coincide(TareaRutinariaEntity t) =>
      consulta.clave.isEmpty ||
      NombreComparable(t.descripcion).respondeA(consulta);
  int orden(TareaRutinariaEntity a, TareaRutinariaEntity b) {
    final c = clave(a).compareTo(clave(b));
    return c != 0 ? c : a.idTarRuti.compareTo(b.idTarRuti);
  }

  final disponibles =
      catalogo
          .where((t) => !yaAsignadas.containsKey(t.idTarRuti))
          .where(coincide)
          .toList()
        ..sort(orden);

  final inactivas =
      catalogo
          .where((t) => yaAsignadas[t.idTarRuti] == false)
          .where(coincide)
          .toList()
        ..sort(orden);

  return (disponibles: disponibles, inactivas: inactivas);
}

String _detalleDeTarea(TareaRutinariaEntity t) {
  // La frecuencia no es decoración: el catálogo tiene descripciones repetidas,
  // y cuando dos filas dicen lo mismo es lo único a la vista que permite
  // elegir la correcta.
  final frecuencia = TareaPendienteTile.nombreFrecuencia[t.idFrec];
  return frecuencia == null
      ? 'Tarea ${t.idTarRuti}'
      : '$frecuencia · tarea ${t.idTarRuti}';
}

/// Elegir tareas que YA existen en el catálogo y engancharlas a un cargo.
///
/// Es el camino que faltaba. Hasta ahora, desde la pantalla de un cargo el
/// único botón era "Agregar tarea rutinaria", que siempre **creaba una
/// nueva**: quien quería reusar una existente terminaba duplicándola en el
/// catálogo.
///
/// **Rendimiento.** El catálogo tiene cerca de 300 tareas. La primera versión
/// armaba las 300 filas en cada reconstrucción —cada casilla tildada y cada
/// letra de la búsqueda— y volvía a filtrar y ordenar todo el catálogo. En
/// Chrome en modo debug eso se sentía como un cuelgue. Ahora la lista es
/// perezosa (solo existen las filas que se ven), el filtrado se recalcula
/// solo cuando cambian el catálogo, la búsqueda o las asignaciones, y la
/// búsqueda espera a que dejes de escribir.
///
/// **Inactivas.** Iban al final, deshabilitadas, con la explicación en una
/// línea que a esa altura ya había quedado fuera de la vista. Con el cargo 144
/// (19 inactivas) quien bajaba hasta el fondo encontraba filas grises que no
/// respondían al clic. Ahora van arriba, plegadas y con cuántas son, y cada
/// una tiene su botón para reactivarla sin salir del diálogo.
class ElegirTareaDelCatalogoDialog extends ConsumerStatefulWidget {
  /// Las que este cargo ya tiene, con su estado. Clave `idTarRuti`, valor
  /// `true` si la asignación está activa.
  final Map<int, bool> yaAsignadas;

  final String nombreCargo;

  /// Recibe los `idTarRuti` elegidos y desde cuándo rige la asignación.
  final void Function(List<int>, DateTime) onElegidas;

  /// Reactiva la asignación inactiva de esa tarea en este cargo y devuelve si
  /// se pudo. Nulo: las inactivas se muestran, pero sin botón.
  final Future<bool> Function(int idTarRuti)? onReactivar;

  const ElegirTareaDelCatalogoDialog({
    super.key,
    required this.yaAsignadas,
    required this.nombreCargo,
    required this.onElegidas,
    this.onReactivar,
  });

  @override
  ConsumerState<ElegirTareaDelCatalogoDialog> createState() =>
      _ElegirTareaDelCatalogoDialogState();
}

class _ElegirTareaDelCatalogoDialogState
    extends ConsumerState<ElegirTareaDelCatalogoDialog> {
  final _buscarCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _seleccionadas = <int>{};

  /// Copia propia: reactivar una tarea la saca de las inactivas sin esperar a
  /// que la pantalla de atrás vuelva a abrir el diálogo.
  late final Map<int, bool> _asignadas = Map.of(widget.yaAsignadas);

  /// Desde cuándo rige la asignación. Hoy por defecto.
  DateTime _desde = DateTime.now();

  /// El texto que filtra la lista. No es el del campo: cambia 250 ms después
  /// de la última tecla.
  String _busqueda = '';
  Timer? _espera;

  bool _inactivasAbiertas = false;
  final _reactivando = <int>{};
  final _fallaAlReactivar = <int>{};
  String? _ultimaReactivada;

  // Memo de separarCatalogo. Tildar una casilla no cambia qué se ofrece, así
  // que no hay motivo para volver a filtrar y ordenar el catálogo entero.
  List<TareaRutinariaEntity>? _catalogoMedido;
  String? _busquedaMedida;
  int _versionAsignadas = 0;
  int _versionMedida = -1;
  CatalogoSeparado _partes = (disponibles: const [], inactivas: const []);

  @override
  void dispose() {
    _espera?.cancel();
    _buscarCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  CatalogoSeparado _partesPara(List<TareaRutinariaEntity> catalogo) {
    if (!identical(catalogo, _catalogoMedido) ||
        _busqueda != _busquedaMedida ||
        _versionAsignadas != _versionMedida) {
      _partes = separarCatalogo(
        catalogo: catalogo,
        yaAsignadas: _asignadas,
        busqueda: _busqueda,
      );
      _catalogoMedido = catalogo;
      _busquedaMedida = _busqueda;
      _versionMedida = _versionAsignadas;
    }
    return _partes;
  }

  void _alEscribir(String texto) {
    _espera?.cancel();
    _espera = Timer(
      const Duration(milliseconds: 250),
      () => _aplicarBusqueda(texto),
    );
  }

  void _aplicarBusqueda(String texto) {
    if (!mounted) return;
    final nueva = texto.trim();
    if (nueva == _busqueda) return;
    setState(() => _busqueda = nueva);
    // Los resultados empiezan arriba: quedarse a mitad de una lista que
    // acaba de cambiar muestra filas que no tienen nada que ver.
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _limpiarBusqueda() {
    _espera?.cancel();
    _buscarCtrl.clear();
    _aplicarBusqueda('');
  }

  void _alternar(int idTarRuti) => setState(() {
    if (!_seleccionadas.remove(idTarRuti)) _seleccionadas.add(idTarRuti);
  });

  Future<void> _reactivar(TareaRutinariaEntity t) async {
    final accion = widget.onReactivar;
    if (accion == null || _reactivando.contains(t.idTarRuti)) return;
    setState(() {
      _reactivando.add(t.idTarRuti);
      _fallaAlReactivar.remove(t.idTarRuti);
    });
    final ok = await accion(t.idTarRuti);
    if (!mounted) return;
    setState(() {
      _reactivando.remove(t.idTarRuti);
      if (ok) {
        // Ahora está activa: sale de las inactivas y tampoco se ofrece para
        // agregar.
        _asignadas[t.idTarRuti] = true;
        _versionAsignadas++;
        _ultimaReactivada = textoDeTarea(t.descripcion);
      } else {
        _fallaAlReactivar.add(t.idTarRuti);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tareaRutinariaProvider);
    final alto = math.min(460.0, MediaQuery.sizeOf(context).height * 0.6);

    return AlertDialog(
      title: Text('Agregar tarea existente a ${widget.nombreCargo}'),
      content: SizedBox(
        width: 560,
        height: alto,
        child: Column(
          children: [
            _CampoDesde(
              valor: _desde,
              onCambio: (d) => setState(() => _desde = d),
            ),
            const SizedBox(height: 8),
            _CampoBuscar(
              controller: _buscarCtrl,
              onCambio: _alEscribir,
              onLimpiar: _limpiarBusqueda,
            ),
            const SizedBox(height: 8),
            if (_ultimaReactivada != null)
              _AvisoReactivada(texto: _ultimaReactivada!),
            Expanded(child: _cuerpo(context, state)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _seleccionadas.isEmpty
                  ? null
                  : () {
                    Navigator.of(context).pop();
                    widget.onElegidas(_seleccionadas.toList(), _desde);
                  },
          child: Text(
            _seleccionadas.isEmpty
                ? 'Agregar'
                : 'Agregar ${_seleccionadas.length}',
          ),
        ),
      ],
    );
  }

  Widget _cuerpo(BuildContext context, TareaRutinariaState state) {
    if (!state.cargado) {
      // Una falla sin nada cargado no puede verse como "el cargo ya tiene
      // todas las tareas": son dos cosas opuestas.
      return state.mensajeError != null && !state.cargando
          ? _SinCatalogo(
            onReintentar:
                () => ref.read(tareaRutinariaProvider.notifier).cargar(),
          )
          : const Center(child: CircularProgressIndicator());
    }

    final partes = _partesPara(state.items);
    final disponibles = partes.disponibles;
    final inactivas = partes.inactivas;
    final hayBusqueda = _busqueda.isNotEmpty;

    if (disponibles.isEmpty && inactivas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            hayBusqueda
                ? 'Ninguna tarea del catálogo coincide con la búsqueda.'
                : 'Este cargo ya tiene todas las tareas del catálogo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Con una búsqueda escrita las inactivas que coinciden se muestran
    // siempre: si la que buscas está inactiva, tiene que aparecer.
    final verInactivas = _inactivasAbiertas || hayBusqueda;
    final bloqueInactivas =
        inactivas.isEmpty ? 0 : 1 + (verInactivas ? inactivas.length : 0);
    final cabeceraDisponibles = inactivas.isEmpty ? 0 : 1;

    Widget filaDisponible(TareaRutinariaEntity t) => _FilaDisponible(
      key: ValueKey('d${t.idTarRuti}'),
      tarea: t,
      elegida: _seleccionadas.contains(t.idTarRuti),
      onCambio: () => _alternar(t.idTarRuti),
    );

    return ListView.builder(
      controller: _scroll,
      // Ninguna fila guarda estado propio: mantenerlas vivas fuera de la
      // vista solo ocupa memoria.
      addAutomaticKeepAlives: false,
      itemCount: bloqueInactivas + cabeceraDisponibles + disponibles.length,
      itemBuilder: (context, i) {
        if (inactivas.isEmpty) return filaDisponible(disponibles[i]);

        if (i == 0) {
          return _CabeceraInactivas(
            cantidad: inactivas.length,
            abierta: verInactivas,
            fijadaPorBusqueda: hayBusqueda,
            onAlternar:
                () => setState(() => _inactivasAbiertas = !_inactivasAbiertas),
          );
        }
        if (i < bloqueInactivas) {
          final t = inactivas[i - 1];
          return _FilaInactiva(
            key: ValueKey('i${t.idTarRuti}'),
            tarea: t,
            trabajando: _reactivando.contains(t.idTarRuti),
            fallo: _fallaAlReactivar.contains(t.idTarRuti),
            onReactivar: widget.onReactivar == null ? null : () => _reactivar(t),
          );
        }
        if (i == bloqueInactivas) {
          return _CabeceraDisponibles(
            cantidad: disponibles.length,
            hayBusqueda: hayBusqueda,
          );
        }
        return filaDisponible(disponibles[i - bloqueInactivas - 1]);
      },
    );
  }
}

class _CampoBuscar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCambio;
  final VoidCallback onLimpiar;

  const _CampoBuscar({
    required this.controller,
    required this.onCambio,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onCambio,
      decoration: InputDecoration(
        hintText: 'Buscar en el catálogo...',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        // Solo la X se entera de cada tecla; la lista espera.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder:
              (context, valor, _) =>
                  valor.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: onLimpiar,
                      ),
        ),
      ),
    );
  }
}

/// Una tarea que se puede agregar.
///
/// No es un `CheckboxListTile`: ese widget arma un `ListTile` completo por
/// fila, con su propio tema y un layout de dos pasadas, y aquí hay cientos.
class _FilaDisponible extends StatelessWidget {
  final TareaRutinariaEntity tarea;
  final bool elegida;
  final VoidCallback onCambio;

  const _FilaDisponible({
    super.key,
    required this.tarea,
    required this.elegida,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return MergeSemantics(
      child: InkWell(
        onTap: onCambio,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: elegida,
                onChanged: (_) => onCambio(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textoDeTarea(tarea.descripcion),
                        style: tema.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _detalleDeTarea(tarea),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabeceraInactivas extends StatelessWidget {
  final int cantidad;
  final bool abierta;

  /// Con búsqueda escrita no se puede plegar: las que coinciden se muestran.
  final bool fijadaPorBusqueda;
  final VoidCallback onAlternar;

  const _CabeceraInactivas({
    required this.cantidad,
    required this.abierta,
    required this.fijadaPorBusqueda,
    required this.onAlternar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final atenuado = tema.colorScheme.onSurfaceVariant;
    final titulo =
        cantidad == 1
            ? '1 tarea de este cargo está inactiva'
            : '$cantidad tareas de este cargo están inactivas';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: !fijadaPorBusqueda,
        expanded: abierta,
        child: Material(
          color: tema.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: fijadaPorBusqueda ? null : onAlternar,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Icon(Icons.pause_circle_outline, size: 20, color: atenuado),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: tema.textTheme.titleSmall),
                        Text(
                          'No se agregan de nuevo: se reactivan.',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: atenuado,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!fijadaPorBusqueda)
                    Icon(abierta ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaInactiva extends StatelessWidget {
  final TareaRutinariaEntity tarea;
  final bool trabajando;
  final bool fallo;
  final VoidCallback? onReactivar;

  const _FilaInactiva({
    super.key,
    required this.tarea,
    required this.trabajando,
    required this.fallo,
    required this.onReactivar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final atenuado = tema.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textoDeTarea(tarea.descripcion),
                  style: tema.textTheme.bodyMedium?.copyWith(color: atenuado),
                ),
                const SizedBox(height: 2),
                Text(
                  onReactivar == null
                      ? '${_detalleDeTarea(tarea)} · actívala desde la lista del cargo'
                      : _detalleDeTarea(tarea),
                  style: tema.textTheme.bodySmall?.copyWith(color: atenuado),
                ),
                if (fallo)
                  Text(
                    'No se pudo reactivar. Inténtalo de nuevo.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          if (onReactivar != null) ...[
            const SizedBox(width: 8),
            trabajando
                ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : TextButton.icon(
                  onPressed: onReactivar,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Reactivar'),
                ),
          ],
        ],
      ),
    );
  }
}

class _CabeceraDisponibles extends StatelessWidget {
  final int cantidad;
  final bool hayBusqueda;

  const _CabeceraDisponibles({
    required this.cantidad,
    required this.hayBusqueda,
  });

  @override
  Widget build(BuildContext context) {
    final texto =
        cantidad > 0
            ? 'Para agregar ($cantidad)'
            : hayBusqueda
            ? 'Ninguna tarea para agregar coincide con la búsqueda.'
            : 'No queda ninguna otra tarea del catálogo para agregar.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(texto, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _AvisoReactivada extends StatelessWidget {
  final String texto;

  const _AvisoReactivada({required this.texto});

  @override
  Widget build(BuildContext context) {
    final color = TareasColors.realizadoTexto(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reactivada: $texto',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinCatalogo extends StatelessWidget {
  final VoidCallback onReintentar;

  const _SinCatalogo({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No se pudo cargar el catálogo de tareas.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Desde cuándo rige la asignación que se está por crear.
///
/// Antes no se preguntaba: se mandaba nulo y el procedimiento resolvía con
/// CAST(GETDATE() AS DATE). Funcionaba, pero no dejaba adelantar ni atrasar
/// el arranque, que es justo lo que hace falta cuando se prepara un cambio de
/// cargo o se carga algo que empezó la semana pasada.
class _CampoDesde extends StatelessWidget {
  final DateTime valor;
  final void Function(DateTime) onCambio;

  const _CampoDesde({required this.valor, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final esHoy =
        valor.year == hoy.year &&
        valor.month == hoy.month &&
        valor.day == hoy.day;

    return InkWell(
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: valor,
          // Hacia atrás para cargar algo que ya empezó, hacia adelante para
          // dejar preparada una asignación que arranca el mes que viene.
          firstDate: DateTime(2020),
          lastDate: DateTime(hoy.year + 2),
        );
        if (elegida != null) onCambio(elegida);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Asignada desde',
          border: const OutlineInputBorder(),
          isDense: true,
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
          helperText:
              esHoy
                  ? 'Hoy: empieza a generarse en la próxima corrida.'
                  : 'Distinta de hoy.',
        ),
        child: Text(
          '${valor.day.toString().padLeft(2, '0')}/'
          '${valor.month.toString().padLeft(2, '0')}/${valor.year}',
        ),
      ),
    );
  }
}
