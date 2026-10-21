/// Los diálogos de Funciones por módulo y de Asignación de funciones: alta y
/// edición de una función, su baja, y el alta de una asignación (función,
/// sucursal y empleado). Reglas y textos los ponen los `p_abm_` de cada tabla.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/funciones_modulo_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';
import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FUNCIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// Con [existente] null es un alta en [codModuloInicial] (si lo hay).
Future<void> abrirFormularioFuncion(
  BuildContext context, {
  required List<OpcionEntity> modulos,
  FuncionModuloEntity? existente,
  int? codModuloInicial,
}) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesFuncionesModuloProvider.notifier).limpiarError();
  return abrirFormularioParametro<void>(
    context,
    anchoMaximo: 600,
    contenido:
        (_) => _FormularioFuncion(
          modulos: modulos,
          existente: existente,
          codModuloInicial: codModuloInicial,
        ),
  );
}

class _FormularioFuncion extends ConsumerStatefulWidget {
  const _FormularioFuncion({
    required this.modulos,
    required this.existente,
    required this.codModuloInicial,
  });

  final List<OpcionEntity> modulos;
  final FuncionModuloEntity? existente;
  final int? codModuloInicial;

  @override
  ConsumerState<_FormularioFuncion> createState() => _FormularioFuncionState();
}

class _FormularioFuncionState extends ConsumerState<_FormularioFuncion> {
  late final _funcion = TextEditingController(
    text: widget.existente?.funcion ?? '',
  );
  late final _detalle = TextEditingController(
    text: widget.existente?.detalle ?? '',
  );
  late int? _modulo = widget.existente?.codModulo ?? widget.codModuloInicial;
  late bool _requerido = widget.existente?.requerido ?? false;
  late bool _activo = widget.existente?.activo ?? true;

  bool get _esAlta => widget.existente == null;

  @override
  void dispose() {
    _funcion.dispose();
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final f = FuncionModuloEntity(
      codFuncMod: widget.existente?.codFuncMod ?? BigInt.zero,
      codModulo: _modulo ?? 0,
      funcion: _funcion.text,
      detalle: _detalle.text,
      requerido: _requerido,
      activo: _activo,
    );
    final r = await ref
        .read(operacionesFuncionesModuloProvider.notifier)
        .ejecutar(
          () => ref.read(funcionesModuloRepositoryProvider).registrar(f),
        );
    if (r == null || !mounted) return;
    avisar(context, r.mensaje);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionesFuncionesModuloProvider);
    final e = widget.existente;

    return PanelParametro(
      titulo: _esAlta ? 'Nueva función' : 'Editar función',
      subtitulo:
          _esAlta
              ? 'Un rol que se asigna a empleados dentro del módulo.'
              : '${e!.modulo} · ${e.asignaciones} asignaciones.',
      ocupado: estado.ocupado,
      errorServidor: estado.error,
      etiquetaGuardar: _esAlta ? 'Registrar' : 'Guardar cambios',
      onGuardar: _guardar,
      campos: [
        DropdownButtonFormField<int>(
          key: const ValueKey('campo-modulo'),
          value:
              widget.modulos.any((m) => m.codigo == _modulo) ? _modulo : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Módulo',
            helperText: _esAlta ? null : 'Una función no cambia de módulo.',
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final m in widget.modulos)
              DropdownMenuItem(value: m.codigo, child: Text(m.nombre)),
          ],
          onChanged: _esAlta ? (v) => setState(() => _modulo = v) : null,
        ),
        TextField(
          key: const ValueKey('campo-funcion'),
          controller: _funcion,
          autofocus: _esAlta,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(150)],
          decoration: const InputDecoration(
            labelText: 'Función',
            hintText: 'Por ejemplo: COBRADOR',
            border: OutlineInputBorder(),
          ),
        ),
        TextField(
          key: const ValueKey('campo-detalle'),
          controller: _detalle,
          minLines: 2,
          maxLines: 5,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          decoration: const InputDecoration(
            labelText: 'Detalle',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        SwitchListTile(
          key: const ValueKey('campo-requerido'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Requerida'),
          subtitle: const Text('El módulo la necesita para operar.'),
          value: _requerido,
          onChanged: (v) => setState(() => _requerido = v),
        ),
        SwitchListTile(
          key: const ValueKey('campo-activa'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Activa'),
          subtitle: const Text('Una función inactiva no se puede asignar.'),
          value: _activo,
          onChanged: (v) => setState(() => _activo = v),
        ),
      ],
    );
  }
}

Future<void> eliminarFuncion(
  BuildContext context,
  WidgetRef ref,
  FuncionModuloEntity f,
) => eliminarDeCatalogo(
  context,
  titulo: '¿Eliminar la función ${f.funcion}?',
  detalle:
      'Se elimina «${f.funcion}» de ${f.modulo}. Si tiene asignaciones, no se '
      'podrá eliminar: desactívela en su lugar.',
  textoConfirmar: 'Eliminar función',
  operaciones: ref.read(operacionesFuncionesModuloProvider.notifier),
  errorActual: () => ref.read(operacionesFuncionesModuloProvider).error,
  eliminar:
      () => ref.read(funcionesModuloRepositoryProvider).eliminar(f.codFuncMod),
);

// ═══════════════════════════════════════════════════════════════════════════
// ASIGNACIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// Alta de una asignación: función, sucursal y un empleado vigente de ella.
Future<void> abrirFormularioAsignacion(
  BuildContext context, {
  required List<FuncionModuloEntity> funciones,
  required List<OpcionEntity> sucursales,
  int? codFuncModInicial,
  int? codSucursalInicial,
}) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesAsignacionProvider.notifier).limpiarError();
  return abrirFormularioParametro<void>(
    context,
    anchoMaximo: 600,
    contenido:
        (_) => _FormularioAsignacion(
          funciones: [
            for (final f in funciones)
              if (f.activo) f,
          ],
          sucursales: sucursales,
          codFuncModInicial: codFuncModInicial,
          codSucursalInicial: codSucursalInicial,
        ),
  );
}

class _FormularioAsignacion extends ConsumerStatefulWidget {
  const _FormularioAsignacion({
    required this.funciones,
    required this.sucursales,
    required this.codFuncModInicial,
    required this.codSucursalInicial,
  });

  final List<FuncionModuloEntity> funciones;
  final List<OpcionEntity> sucursales;
  final int? codFuncModInicial;
  final int? codSucursalInicial;

  @override
  ConsumerState<_FormularioAsignacion> createState() =>
      _FormularioAsignacionState();
}

class _FormularioAsignacionState extends ConsumerState<_FormularioAsignacion> {
  late int? _funcion =
      widget.funciones.any((f) => f.codFuncMod.toInt() == widget.codFuncModInicial)
          ? widget.codFuncModInicial
          : null;
  late int? _sucursal =
      widget.sucursales.any((s) => s.codigo == widget.codSucursalInicial)
          ? widget.codSucursalInicial
          : null;
  int? _empleado;
  bool _activo = true;

  Future<void> _guardar() async {
    final a = AsignacionFuncionEntity(
      codAsignacion: BigInt.zero,
      codFuncMod: _funcion ?? 0,
      codEmpleado: _empleado ?? 0,
      codSucursal: _sucursal ?? 0,
      activo: _activo,
    );
    final r = await ref
        .read(operacionesAsignacionProvider.notifier)
        .ejecutar(
          () => ref.read(asignacionFuncionesRepositoryProvider).registrar(a),
        );
    if (r == null || !mounted) return;
    avisar(context, r.mensaje);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionesAsignacionProvider);
    final empleados =
        _sucursal == null
            ? null
            : ref.watch(empleadosDeSucursalProvider(_sucursal!));

    return PanelParametro(
      titulo: 'Nueva asignación',
      subtitulo: 'Una función de un módulo para un empleado en una sucursal.',
      ocupado: estado.ocupado,
      errorServidor: estado.error,
      etiquetaGuardar: 'Asignar',
      onGuardar: _guardar,
      campos: [
        DropdownButtonFormField<int>(
          key: const ValueKey('campo-funcion'),
          value: _funcion,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Función',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final f in widget.funciones)
              DropdownMenuItem(
                value: f.codFuncMod.toInt(),
                child: Text(
                  '${f.funcion} · ${f.modulo}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) => setState(() => _funcion = v),
        ),
        DropdownButtonFormField<int>(
          key: const ValueKey('campo-sucursal'),
          value: _sucursal,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sucursal',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final s in widget.sucursales)
              DropdownMenuItem(
                value: s.codigo,
                child: Text(
                  s.grupo.isEmpty ? s.nombre : '${s.nombre} · ${s.grupo}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged:
              (v) => setState(() {
                _sucursal = v;
                _empleado = null;
              }),
        ),
        if (empleados == null)
          const NotaDelDato(
            texto: 'Elija la sucursal para ver sus empleados vigentes.',
          )
        else
          empleados.when(
            loading: () => const LinearProgressIndicator(),
            error:
                (e, _) => MensajeError(
                  error: e,
                  compacto: true,
                  onReintentar:
                      () => ref.invalidate(
                        empleadosDeSucursalProvider(_sucursal!),
                      ),
                ),
            data:
                (lista) =>
                    lista.isEmpty
                        ? const NotaDelDato(
                          texto: 'Esa sucursal no tiene empleados vigentes.',
                          tono: TonoNota.aviso,
                        )
                        : DropdownButtonFormField<int>(
                          key: ValueKey('campo-empleado-$_sucursal'),
                          value: _empleado,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Empleado',
                            helperText: '${lista.length} empleados vigentes',
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final e in lista)
                              DropdownMenuItem(
                                value: e.codigo,
                                child: Text(
                                  e.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _empleado = v),
                        ),
          ),
        SwitchListTile(
          key: const ValueKey('campo-activa'),
          contentPadding: const EdgeInsets.symmetric(horizontal: Esp.xs),
          title: const Text('Activa'),
          value: _activo,
          onChanged: (v) => setState(() => _activo = v),
        ),
      ],
    );
  }
}

/// Activa o desactiva una asignación: en el legacy era su única edición.
Future<void> cambiarEstadoAsignacion(
  BuildContext context,
  WidgetRef ref,
  AsignacionFuncionEntity a,
) async {
  final activar = !a.activo;
  final ops = ref.read(operacionesAsignacionProvider.notifier);
  final r = await ops.ejecutar(
    () => ref
        .read(asignacionFuncionesRepositoryProvider)
        .registrar(
          AsignacionFuncionEntity(
            codAsignacion: a.codAsignacion,
            codFuncMod: a.codFuncMod,
            codEmpleado: a.codEmpleado,
            codSucursal: a.codSucursal,
            activo: activar,
          ),
        ),
  );
  if (!context.mounted) return;
  if (r == null) {
    final texto =
        ref.read(operacionesAsignacionProvider).error ??
        'No se pudo cambiar el estado.';
    ops.limpiarError();
    await mostrarErrorParametro(context, 'No se pudo cambiar', texto);
    return;
  }
  avisar(context, r.mensaje);
}
