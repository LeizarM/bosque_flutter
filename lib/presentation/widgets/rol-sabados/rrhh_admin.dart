/// El padrón de RR.HH.: quiénes pueden corregir CUALQUIER celda.
///
/// **Por qué existe esta pantalla.** Escribir una celda a mano —el editor que se
/// abre al tocar la grilla— no tenía dueño: alcanzaba con estar logueado, así
/// que cualquiera de los usuarios `ROLE_LIM` podía cambiarle el sábado a
/// cualquier persona, con cualquier letra, y firmarlo con el `audUsuario` que
/// quisiera. Era la puerta de atrás del control de jefes.
///
/// El rol de usuario no servía para taparlo: `ROLE_ADM` son los de Sistemas y
/// `ROLE_LIM` son todos los demás. La gente que de verdad carga vacaciones y
/// bajas no se distingue por su rol, así que hay que nombrarla — y esta pantalla
/// es donde se la nombra.
///
/// **Vive aparte de `programadores_admin.dart`** aunque las dos sean ABM de
/// permisos, porque son permisos distintos y confundirlos es caro: un jefe
/// programador alcanza sólo a su gente y sólo decide si viene o no viene; quien
/// está acá no tiene límite de árbol, de sucursal ni de letra.
library;

import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/rrhh_sabados_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el padrón. Igual que el de programadores: hoja modal topeada en 720 px.
Future<void> mostrarAdminRrhh(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (_) => const _PanelRrhh(),
    );

class _PanelRrhh extends ConsumerWidget {
  const _PanelRrhh();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padron = ref.watch(rrhhSabadosProvider);

    return SizedBox(
      // Alto fijo por el mismo motivo que el otro panel: una hoja que salta de
      // tamaño con cada alta se lee como un error.
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          const _Encabezado(),
          const Divider(height: 1),
          Expanded(
            child: padron.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => MensajeVacio(
                    icono: Icons.error_outline,
                    titulo: 'No se pudo cargar el padrón',
                    detalle: textoParaUsuario(e),
                  ),
              data: (lista) {
                if (lista.isEmpty) {
                  return const MensajeVacio(
                    icono: Icons.badge_outlined,
                    titulo: 'Todavía no hay nadie de RR.HH.',
                    detalle:
                        'Mientras esté vacío, las únicas personas que pueden '
                        'corregir la celda de cualquiera son los usuarios '
                        'administradores. Los jefes siguen pudiendo con su '
                        'propia gente.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: Esp.s),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _Fila(persona: lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.m),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RR.HH.', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Quiénes pueden corregir la celda de cualquiera, con cualquier '
                'letra. Los jefes programadores no necesitan estar aquí: ya '
                'pueden con su propia gente.',
                style: context.apagado(),
              ),
            ],
          ),
        ),
        const SizedBox(width: Esp.s),
        FilledButton.tonalIcon(
          onPressed: () => _abrirAlta(context),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Agregar'),
        ),
      ],
    ),
  );

  void _abrirAlta(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (_) => const _AltaRrhhSheet(),
  );
}

class _Fila extends ConsumerWidget {
  const _Fila({required this.persona});
  final RrhhSabadosEntity persona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baja = !persona.activo;

    return ListTile(
      leading: Icon(
        baja ? Icons.person_off_outlined : Icons.badge_outlined,
        color: baja ? Theme.of(context).hintColor : context.cs.primary,
      ),
      title: Text(
        persona.persona.isEmpty ? '#${persona.codEmpleado}' : persona.persona,
        style: baja ? TextStyle(color: Theme.of(context).hintColor) : null,
      ),
      subtitle: Text(
        [
          if (persona.cargo.isNotEmpty) persona.cargo,
          if (persona.sucursal.isNotEmpty) persona.sucursal,
          if (baja) 'dado de baja',
          if (persona.observacion.isNotEmpty) persona.observacion,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          baja
              // Un dado de baja no se borra: se vuelve a agregar, y el SP
              // reactiva la misma fila. Por eso acá no hay botón de alta —
              // se usa «Agregar» de arriba y se elige a la misma persona.
              ? null
              : IconButton(
                tooltip: 'Sacar de RR.HH.',
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: () => _confirmarBaja(context, ref),
              ),
    );
  }

  Future<void> _confirmarBaja(BuildContext context, WidgetRef ref) async {
    final nombre =
        persona.persona.isEmpty ? '#${persona.codEmpleado}' : persona.persona;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('¿Sacar de RR.HH.?'),
            content: Text(
              'Desde que se guarde, $nombre ya no va a poder corregir la celda '
              'de nadie —salvo la de su propia gente, si además es jefe '
              'programador—.\n\nLo que ya corrigió no se toca.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Sacar'),
              ),
            ],
          ),
    );
    if (ok != true || !context.mounted) return;

    await ejecutarAccion(
      context,
      () => ref.read(rolSabadosAccionesProvider).eliminarRrhh(persona.idRrhh),
      exito: 'Listo: ya no puede corregir celdas ajenas.',
    );
  }
}

class _AltaRrhhSheet extends ConsumerStatefulWidget {
  const _AltaRrhhSheet();

  @override
  ConsumerState<_AltaRrhhSheet> createState() => _AltaRrhhState();
}

class _AltaRrhhState extends ConsumerState<_AltaRrhhSheet> {
  int? _codEmpleado;
  final _observacion = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idRol = ref.watch(rolSeleccionadoProvider);
    if (idRol == null) {
      return const SizedBox(
        height: 240,
        child: MensajeVacio(
          icono: Icons.calendar_month_outlined,
          titulo: 'Elige un rol primero',
          detalle:
              'La lista de gente sale de los participantes del rol. '
              'Selecciona el año arriba y vuelve a abrir esta pantalla.',
        ),
      );
    }

    final grilla = ref.watch(grillaRolProvider(idRol));

    return Padding(
      padding: EdgeInsets.only(
        left: Esp.xl,
        right: Esp.xl,
        top: Esp.s,
        bottom: MediaQuery.of(context).viewInsets.bottom + Esp.xl,
      ),
      child: grilla.when(
        loading:
            () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => SizedBox(
              height: 240,
              child: MensajeVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudo cargar el personal',
                detalle: textoParaUsuario(e),
              ),
            ),
        data: (g) => _formulario(context, g.participantes),
      ),
    );
  }

  Widget _formulario(
    BuildContext context,
    List<ParticipanteTurnoEntity> gente,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar a RR.HH.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Va a poder corregir la celda de cualquier persona del rol, con '
            'cualquier letra: vacaciones, bajas, feriados y permisos incluidos.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.l),

          ComboBuscable<int>(
            etiqueta: 'Quién',
            valor: _codEmpleado,
            ayuda: '${gente.length} personas del rol',
            opciones: entradasDePersonas(gente, mostrarGrupo: false),
            onElegir: (v) => setState(() => _codEmpleado = v),
          ),
          const _Nota(
            'Si esa persona ya estuvo y se la sacó, agregarla de nuevo reactiva '
            'la misma fila: no se duplica.',
          ),

          const SizedBox(height: Esp.l),
          TextField(
            controller: _observacion,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Observación',
              helperText: 'Por qué se le da el permiso. Queda en la ficha.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: Esp.s),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_guardando || _codEmpleado == null || _codEmpleado == 0)
                      ? null
                      : _guardar,
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              label: const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final ok = await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .registrarRrhh(
            codEmpleado: _codEmpleado!,
            observacion: _observacion.text.trim(),
          ),
      exito: 'Listo: ya puede corregir la celda de cualquiera.',
      cerrar: true,
    );
    if (!ok && mounted) setState(() => _guardando = false);
  }
}

/// Texto chico de apoyo, igual que en el panel de programadores.
class _Nota extends StatelessWidget {
  const _Nota(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.xs, left: 2),
    child: Text(texto, style: context.apagado()),
  );
}
