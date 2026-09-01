import 'dart:async';

import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/data/repositories/permisos_rrhh_impl.dart';
import 'package:bosque_flutter/domain/entities/bio_empl_bosq_empl_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pestaña "Empleados": el "Verificación Empleados" del legacy — enlazar
/// cada usuario del reloj biométrico con su empleado real de Bosque, y traer
/// los usuarios nuevos que aparecieron en el dispositivo.
///
/// La búsqueda de empleado de Bosque reutiliza `PermisosRrhhImpl.buscarEmpleados`
/// (pega contra `RrhhController.obtenerLstEmpleados`, un endpoint general, no
/// específico de permisos) en vez de duplicar un buscador — ver `CLAUDE.md`.
class TabEmpleados extends ConsumerStatefulWidget {
  const TabEmpleados({super.key});

  @override
  ConsumerState<TabEmpleados> createState() => _TabEmpleadosState();
}

class _TabEmpleadosState extends ConsumerState<TabEmpleados> {
  final _filtro = TextEditingController();
  bool _soloNoEnlazados = false;

  @override
  void dispose() {
    _filtro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(todosLosEmpleadosBiometricoProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.sync),
        label: const Text('Importar nuevos'),
        onPressed: () => _importarNuevos(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filtro,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 18),
                      hintText: 'Filtrar por nombre…',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: Esp.m),
                FilterChip(
                  label: const Text('Sólo no enlazados'),
                  selected: _soloNoEnlazados,
                  onSelected: (v) => setState(() => _soloNoEnlazados = v),
                ),
              ],
            ),
            const SizedBox(height: Esp.m),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => MensajeVacio(
                      icono: Icons.error_outline,
                      titulo: 'No se pudo cargar el padrón',
                      detalle: textoDeError(e),
                    ),
                data: (lista) {
                  final texto = _filtro.text.trim().toLowerCase();
                  final filtrada =
                      lista.where((e) {
                        if (_soloNoEnlazados && e.enlazado) return false;
                        if (texto.isEmpty) return true;
                        return e.datoNombreBiom.toLowerCase().contains(texto) ||
                            e.datoNombreBosq.toLowerCase().contains(texto);
                      }).toList();

                  if (filtrada.isEmpty) {
                    return const MensajeVacio(
                      icono: Icons.people_outline,
                      titulo: 'Sin resultados',
                      detalle: 'Nadie coincide con el filtro elegido.',
                    );
                  }
                  return ListView.separated(
                    itemCount: filtrada.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _Fila(item: filtrada[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importarNuevos(BuildContext context) async {
    final ok = await confirmar(
      context,
      titulo: 'Importar empleados nuevos',
      mensaje: 'Se van a traer los usuarios nuevos que haya en el dispositivo biométrico.',
      accion: 'Importar',
    );
    if (!ok || !context.mounted) return;
    try {
      // Desde el fix de sql/06_fix_p_abm_BioEmplBosqEmpl_ACCION_A.sql este
      // ACCION devuelve la CANTIDAD de empleados nuevos importados (antes
      // siempre 0 — @idGenerado nunca se tocaba en esa rama de la SP, y acá
      // se mostraba un "Importación completada." fijo sin decir si de
      // verdad pasó algo). Si el script todavía no corrió contra la BD, el
      // backend sigue devolviendo 0 igual que antes — no rompe nada, sólo
      // no informa la cantidad real hasta que el script se aplique.
      final cantidad = await ref
          .read(biometricoRepositoryProvider)
          .registrarEmpleado({'idEmpleadBio': 0, 'idEmpleado': 0}, 'A');
      ref.invalidate(todosLosEmpleadosBiometricoProvider);
      ref.invalidate(empleadosBiometricoProvider);
      if (context.mounted) {
        final n = cantidad.toInt();
        avisar(
          context,
          n > 0
              ? 'Se importaron $n empleado(s) nuevo(s).'
              : 'No hay empleados nuevos para importar.',
        );
      }
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

class _Fila extends ConsumerWidget {
  const _Fila({required this.item});
  final BioEmplBosqEmplEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        item.enlazado ? Icons.link : Icons.link_off,
        color: item.enlazado ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(item.datoNombreBiom),
      subtitle: Text(item.enlazado ? item.datoNombreBosq : 'Sin enlazar'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item.enlazado
              ? IconButton(
                tooltip: 'Desenlazar',
                icon: const Icon(Icons.link_off),
                onPressed: () => _desenlazar(context, ref),
              )
              : FilledButton.tonal(
                onPressed: () => _enlazar(context, ref),
                child: const Text('Enlazar'),
              ),
          IconButton(
            tooltip: 'Eliminar este registro',
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: () => _eliminar(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _enlazar(BuildContext context, WidgetRef ref) async {
    final elegido = await showDialog<EmpleadoEntity>(
      context: context,
      builder: (c) => _BuscadorEmpleadoBosque(nombreBiometrico: item.datoNombreBiom),
    );
    if (elegido == null || !context.mounted) return;

    // Acá es donde nace el bug real que hacía que el Resumen mensual y el
    // Detallado-todos mostraran a alguien duplicado, número por número
    // idéntico: un empleado de Bosque enlazado a DOS usuarios del
    // biométrico a la vez (típicamente porque lo volvieron a enrolar en el
    // reloj y quedó un idEmpleadBio viejo sin desenlazar). En vez de dejar
    // que conviertan los dos enlaces, si el empleado elegido ya tiene otro,
    // se ofrece reemplazarlo — desenlazar el viejo en el mismo paso que se
    // crea el nuevo — para que la relación 1 a 1 nunca se rompa desde acá.
    final padron = ref.read(todosLosEmpleadosBiometricoProvider).valueOrNull ?? [];
    final otroEnlace =
        padron
            .where(
              (e) =>
                  e.idEmpleadBio != item.idEmpleadBio &&
                  e.idEmpleado == BigInt.from(elegido.codEmpleado),
            )
            .firstOrNull;

    if (otroEnlace != null) {
      final reemplazar = await confirmar(
        context,
        titulo: 'Ya está enlazado a otro usuario',
        mensaje:
            '"${elegido.datoPersona}" ya está enlazado con '
            '"${otroEnlace.datoNombreBiom}" del biométrico. Dejar los dos '
            'enlaces activos a la vez es lo que hace que el Resumen mensual '
            'y el Detallado lo muestren duplicado. ¿Reemplazar ese enlace '
            'por este nuevo?',
        accion: 'Reemplazar',
      );
      if (!reemplazar || !context.mounted) return;

      try {
        await ref.read(biometricoRepositoryProvider).registrarEmpleado({
          'idEmpleadBio': otroEnlace.idEmpleadBio.toInt(),
          'idEmpleado': 0,
        }, 'U');
      } catch (e) {
        if (context.mounted) avisarError(context, e);
        return;
      }
    }

    try {
      await ref.read(biometricoRepositoryProvider).registrarEmpleado({
        'idEmpleadBio': item.idEmpleadBio.toInt(),
        'idEmpleado': elegido.codEmpleado,
      }, 'U');
      ref.invalidate(todosLosEmpleadosBiometricoProvider);
      ref.invalidate(empleadosBiometricoProvider);
      if (context.mounted) avisar(context, 'Empleado enlazado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  Future<void> _desenlazar(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Desenlazar',
      mensaje:
          '¿Quitar el enlace de "${item.datoNombreBiom}" con '
          '"${item.datoNombreBosq}"?',
      accion: 'Desenlazar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(biometricoRepositoryProvider).registrarEmpleado({
        'idEmpleadBio': item.idEmpleadBio.toInt(),
        'idEmpleado': 0,
      }, 'U');
      ref.invalidate(todosLosEmpleadosBiometricoProvider);
      ref.invalidate(empleadosBiometricoProvider);
      if (context.mounted) avisar(context, 'Enlace quitado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  /// Distinto de "Desenlazar": eso pone `idEmpleado=0` y deja la fila (el
  /// usuario del biométrico sigue en el padrón, sólo sin dueño). Esto borra
  /// la fila entera de `tbio_bioEmplBosqEmpl` — para cuando el problema no es
  /// "está mal enlazado" sino "esta fila no debería existir": el caso real
  /// que lo pidió fue un empleado con DOS filas (dos `idEmpleadBio` con el
  /// mismo `idEmpleado`), que hacía que el Resumen mensual y el Detallado-
  /// todos lo mostraran duplicado, número por número idéntico.
  ///
  /// `p_abm_BioEmplBosqEmpl ACCION='D'` ya soporta esto — no hizo falta SQL
  /// nuevo, sólo faltaba el botón. Esta SP es una de las que quedó fuera de
  /// `tbio_bioBitacora` (ver CLAUDE.md), así que un borrado acá no deja
  /// historial de quién ni por qué — el diálogo de confirmación lo dice.
  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar registro',
      mensaje:
          '¿Borrar del todo "${item.datoNombreBiom}"'
          '${item.enlazado ? ' (enlazado con "${item.datoNombreBosq}")' : ''}? '
          'A diferencia de "Desenlazar", esto borra la fila entera — no '
          'queda historial de este cambio (esta tabla no tiene bitácora). '
          'Usalo para limpiar un enlace duplicado o cargado por error, no '
          'para dar de baja a alguien que sigue trabajando acá.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(biometricoRepositoryProvider).registrarEmpleado({
        'idEmpleadBio': item.idEmpleadBio.toInt(),
        'idEmpleado': item.idEmpleado.toInt(),
      }, 'D');
      ref.invalidate(todosLosEmpleadosBiometricoProvider);
      ref.invalidate(empleadosBiometricoProvider);
      if (context.mounted) avisar(context, 'Registro eliminado.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

/// Buscador modal de empleados de Bosque, para elegir a quién enlazar.
class _BuscadorEmpleadoBosque extends StatefulWidget {
  const _BuscadorEmpleadoBosque({required this.nombreBiometrico});
  final String nombreBiometrico;

  @override
  State<_BuscadorEmpleadoBosque> createState() => _BuscadorEmpleadoBosqueState();
}

class _BuscadorEmpleadoBosqueState extends State<_BuscadorEmpleadoBosque> {
  final _texto = TextEditingController();
  final _repo = PermisosRrhhImpl();
  Timer? _rebote;
  List<EmpleadoEntity> _resultados = [];
  bool _cargando = false;
  // Antes el catch tragaba cualquier error y mostraba "Sin resultados." —
  // indistinguible de una búsqueda genuinamente vacía. `buscarEmpleados` pega
  // contra `RrhhController.obtenerLstEmpleados`, que exige ROLE_ADM/ROLE_LIM
  // (ver CLAUDE.md); si quien enlaza no tiene ese rol, esto es lo único que
  // lo va a decir.
  String? _error;

  @override
  void dispose() {
    _rebote?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _rebote?.cancel();
    if (texto.trim().length < 2) {
      setState(() {
        _resultados = [];
        _error = null;
      });
      return;
    }
    _rebote = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _cargando = true;
        _error = null;
      });
      try {
        final r = await _repo.buscarEmpleados(texto.trim());
        if (mounted) setState(() => _resultados = r);
      } catch (e) {
        if (mounted) {
          setState(() {
            _resultados = [];
            _error = textoDeError(e);
          });
        }
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enlazar "${widget.nombreBiometrico}"'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _texto,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar empleado de Bosque',
                hintText: 'Nombre o apellido…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: _buscar,
            ),
            const SizedBox(height: Esp.m),
            if (_cargando) const LinearProgressIndicator(),
            Expanded(
              child:
                  _resultados.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Esp.m),
                          child: Text(
                            _error ??
                                (_texto.text.trim().length < 2
                                    ? 'Escribí al menos 2 letras.'
                                    : 'Sin resultados.'),
                            textAlign: TextAlign.center,
                            style:
                                _error != null
                                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                                    : context.apagado(),
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _resultados.length,
                        itemBuilder: (context, i) {
                          final e = _resultados[i];
                          return ListTile(
                            title: Text(e.datoPersona),
                            onTap: () => Navigator.pop(context, e),
                          );
                        },
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
      ],
    );
  }
}
