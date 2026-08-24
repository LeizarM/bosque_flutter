import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';

import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/validadores_comision.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Asigna un grupo a un vendedor con un rango de vigencia.
///
/// Al editar, el vendedor queda fijo: cambiarlo seria mover la historia de un
/// vendedor a otro. Para eso se cierra la asignacion y se crea una nueva.
class DialogoAsignacion extends ConsumerStatefulWidget {
  const DialogoAsignacion({super.key, this.asignacion});

  final GrupoXVendedorEntity? asignacion;

  @override
  ConsumerState<DialogoAsignacion> createState() => _DialogoAsignacionState();
}

class _DialogoAsignacionState extends ConsumerState<DialogoAsignacion> {
  final _fmt = FormatoComision.fecha;

  BigInt? _idVendedor;
  BigInt? _idGrupo;
  late DateTime _desde;
  DateTime? _hasta;
  late bool _ignora;
  String? _errorGeneral;

  bool get _esEdicion => widget.asignacion != null;

  @override
  void initState() {
    super.initState();
    final a = widget.asignacion;
    _idVendedor = a?.idVendedor;
    _idGrupo = a?.idGrupo;
    _desde = a?.fechaInicio ?? DateTime.now();
    _hasta = a?.fechaFinalizacion;
    _ignora = a?.ignora ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(comisionesAccionesProvider);
    final vendedores = ref.watch(vendedoresComisionProvider);
    final ancho = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: Text(_esEdicion ? 'Editar asignacion' : 'Asignar grupo'),
      content: SizedBox(
        width: ancho < 600 ? ancho * 0.9 : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              vendedores.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                error:
                    (e, _) => AvisoError(
                      mensaje:
                          'No se pudo cargar la lista de vendedores. ${e.toString().replaceFirst('Exception: ', '')}',
                    ),
                data:
                    (lista) => DropdownButtonFormField<BigInt>(
                      value: _idVendedor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vendedor',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final v in lista)
                          DropdownMenuItem(
                            value: v.idVendedor,
                            child: Text(
                              v.nomVenSap,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged:
                          _esEdicion
                              ? null
                              : (v) => setState(() {
                                _idVendedor = v;
                                _idGrupo = null;
                              }),
                    ),
              ),
              const SizedBox(height: 16),
              if (_idVendedor == null)
                Text(
                  'Seleccione primero un vendedor para ver los grupos disponibles.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                _SelectorGrupo(
                  idVendedor: _idVendedor!,
                  idSeleccionado: _idGrupo,
                  grupoActual: widget.asignacion?.grupo,
                  alCambiar: (v) => setState(() => _idGrupo = v),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _CampoFecha(
                      etiqueta: 'Desde',
                      valor: _desde,
                      texto: _fmt.format(_desde),
                      alElegir: (f) => setState(() => _desde = f),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CampoFecha(
                      etiqueta: 'Hasta',
                      valor: _hasta,
                      texto:
                          _hasta == null ? 'Sin limite' : _fmt.format(_hasta!),
                      alElegir: (f) => setState(() => _hasta = f),
                      alLimpiar: () => setState(() => _hasta = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _ignora,
                onChanged: (v) => setState(() => _ignora = v),
                title: const Text('No comisiona por este grupo'),
                subtitle: const Text(
                  'Las ventas del grupo se registran pero no generan comision.',
                ),
              ),
              if (_errorGeneral != null) ...[
                const SizedBox(height: 12),
                AvisoError(mensaje: _errorGeneral!),
              ],
              if (estado.huboError) ...[
                const SizedBox(height: 12),
                AvisoError(mensaje: estado.error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: estado.enProceso ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: estado.enProceso ? null : _guardar,
          child:
              estado.enProceso
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(_esEdicion ? 'Guardar cambios' : 'Asignar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _errorGeneral = null);

    if (_idVendedor == null) {
      setState(() => _errorGeneral = 'Seleccione un vendedor.');
      return;
    }
    if (_idGrupo == null) {
      setState(() => _errorGeneral = 'Seleccione un grupo.');
      return;
    }

    final errorFechas = ValidadoresComision.rangoFechas(_desde, _hasta);
    if (errorFechas != null) {
      setState(() => _errorGeneral = errorFechas);
      return;
    }

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final anterior = widget.asignacion;
    final entidad = GrupoXVendedorEntity(
      idGrpVen: anterior?.idGrpVen ?? BigInt.zero,
      idVendedor: _idVendedor!,
      idGrupo: _idGrupo!,
      estado: 1,
      ignoraComision: _ignora ? 1 : 0,
      fechaInicio: _desde,
      fechaFinalizacion: _hasta,
      audUsuario: BigInt.from(uid),
      nomVenSap: anterior?.nomVenSap ?? '',
      grupo: anterior?.grupo ?? '',
      porcentaje: anterior?.porcentaje ?? 0,
      porcenComision: anterior?.porcenComision ?? 0,
      esParaVenta: anterior?.esParaVenta ?? 1,
      esInterno: anterior?.esInterno ?? 1,
      vigente: 1,
    );

    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .guardarAsignacion(entidad);

    if (!mounted || !ok) return;

    Navigator.pop(context);
    avisar(context, _esEdicion ? 'Asignacion actualizada.' : 'Grupo asignado.');
  }
}

/// Lista los grupos que el vendedor todavia no tiene. Al editar agrega el grupo
/// actual, que por definicion ya esta asignado y no vendria en la consulta.
class _SelectorGrupo extends ConsumerWidget {
  const _SelectorGrupo({
    required this.idVendedor,
    required this.idSeleccionado,
    required this.alCambiar,
    this.grupoActual,
  });

  final BigInt idVendedor;
  final BigInt? idSeleccionado;
  final String? grupoActual;
  final ValueChanged<BigInt?> alCambiar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos = ref.watch(gruposAsignablesProvider(idVendedor));

    return grupos.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      error:
          (e, _) => AvisoError(
            mensaje:
                'No se pudieron cargar los grupos. ${e.toString().replaceFirst('Exception: ', '')}',
          ),
      data: (lista) {
        if (lista.isEmpty && grupoActual == null) {
          return AvisoError(
            mensaje:
                'Este vendedor ya pertenece a todos los grupos disponibles.',
          );
        }

        return DropdownButtonFormField<BigInt>(
          value: idSeleccionado,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Grupo',
            border: OutlineInputBorder(),
          ),
          items: [
            if (grupoActual != null && idSeleccionado != null)
              DropdownMenuItem(
                value: idSeleccionado,
                child: Text(grupoActual!, overflow: TextOverflow.ellipsis),
              ),
            for (final g in lista)
              DropdownMenuItem(
                value: g.idGrupo,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(g.grupo, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    ChipPorcentaje(valor: g.porcentajeVisual),
                  ],
                ),
              ),
          ],
          onChanged: alCambiar,
        );
      },
    );
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.etiqueta,
    required this.valor,
    required this.texto,
    required this.alElegir,
    this.alLimpiar,
  });

  final String etiqueta;
  final DateTime? valor;
  final String texto;
  final ValueChanged<DateTime> alElegir;
  final VoidCallback? alLimpiar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: valor ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (elegida != null) alElegir(elegida);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon:
              (alLimpiar != null && valor != null)
                  ? IconButton(
                    tooltip: 'Quitar limite',
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: alLimpiar,
                  )
                  : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(texto),
      ),
    );
  }
}
