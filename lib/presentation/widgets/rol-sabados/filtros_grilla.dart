import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Barra de filtros de la grilla: mes y buscador de personas.
///
/// **No es sólo comodidad, es lo que hace que la vista rinda.** Un rol de 87
/// personas × 52 sábados son 4.524 cruces; con el mes puesto son unos 400. El
/// filtro arranca en el mes actual justamente por eso: dibujar el año entero de
/// entrada es pedirle al navegador diez veces más de lo que nadie va a mirar.
///
/// El año no tiene selector propio porque **el rol ya es de un año** — cambiarlo
/// es cambiar de rol, y para eso está el combo de al lado.
class FiltrosGrilla extends ConsumerWidget {
  const FiltrosGrilla({super.key, required this.grilla});

  final GrillaRol grilla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(filtroMesProvider);
    final chico = Aire.de(MediaQuery.sizeOf(context).width).esChico;

    final buscador = _Buscador(grilla: grilla);
    final selectorMes = _SelectorMes(grilla: grilla, mes: mes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s),
      child:
          chico
              ? Column(
                children: [
                  selectorMes,
                  const SizedBox(height: Esp.s),
                  buscador,
                ],
              )
              : Row(
                children: [
                  SizedBox(width: 210, child: selectorMes),
                  const SizedBox(width: Esp.m),
                  Expanded(child: buscador),
                ],
              ),
    );
  }
}

class _SelectorMes extends ConsumerWidget {
  const _SelectorMes({required this.grilla, required this.mes});

  final GrillaRol grilla;
  final int mes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cuántos sábados tiene cada mes en ESTE rol: se muestra al lado del nombre
    // para que se entienda qué se va a dibujar antes de elegirlo.
    final porMes = <int, int>{};
    for (final s in grilla.sabados) {
      final m = s.fecha?.month ?? 0;
      if (m > 0) porMes[m] = (porMes[m] ?? 0) + 1;
    }

    return DropdownButtonFormField<int>(
      value: mes,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Mes de ${grilla.rol.anio}',
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
      ),
      items: [
        DropdownMenuItem(
          value: 0,
          child: Text('Todo el año (${grilla.sabados.length})'),
        ),
        for (var m = 1; m <= 12; m++)
          DropdownMenuItem(
            value: m,
            child: Text('${mesLargo(m)} (${porMes[m] ?? 0})'),
          ),
      ],
      onChanged: (v) => ref.read(filtroMesProvider.notifier).state = v ?? 0,
    );
  }
}

class _Buscador extends ConsumerStatefulWidget {
  const _Buscador({required this.grilla});
  final GrillaRol grilla;

  @override
  ConsumerState<_Buscador> createState() => _BuscadorState();
}

class _BuscadorState extends ConsumerState<_Buscador> {
  late final TextEditingController _texto;

  @override
  void initState() {
    super.initState();
    _texto = TextEditingController(text: ref.read(busquedaPersonaProvider));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = ref.watch(busquedaPersonaProvider);
    final total = widget.grilla.participantes.length;
    final visibles =
        filtrarPersonas(widget.grilla.participantes, busqueda).length;

    return TextField(
      controller: _texto,
      decoration: InputDecoration(
        hintText: 'Buscar persona…',
        // El contador dice cuánto quedó: sin él, una búsqueda sin resultados se
        // confunde con una grilla que no cargó.
        labelText:
            busqueda.isEmpty
                ? '$total personas'
                : '$visibles de $total personas',
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon:
            busqueda.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _texto.clear();
                    ref.read(busquedaPersonaProvider.notifier).state = '';
                  },
                ),
      ),
      onChanged: (v) => ref.read(busquedaPersonaProvider.notifier).state = v,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOS FILTROS EN SÍ
// ═══════════════════════════════════════════════════════════════════════════

/// Los sábados del mes elegido. `mes` 0 devuelve todos.
List<SabadoEntity> filtrarSabados(List<SabadoEntity> sabados, int mes) {
  if (mes == 0) return sabados;
  return sabados.where((s) => s.fecha?.month == mes).toList();
}

/// Las personas cuyo nombre contiene [texto], sin distinguir mayúsculas.
///
/// Busca también por código de empleado: en RR.HH. es común tener el número a
/// mano y no el apellido exacto.
List<ParticipanteTurnoEntity> filtrarPersonas(
  List<ParticipanteTurnoEntity> personas,
  String texto,
) {
  final t = texto.trim().toLowerCase();
  if (t.isEmpty) return personas;
  return personas
      .where(
        (p) =>
            p.nombreRol.toLowerCase().contains(t) ||
            p.codEmpleado.toString().contains(t),
      )
      .toList();
}
