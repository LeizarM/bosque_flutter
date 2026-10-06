import 'dart:async';

import 'package:bosque_flutter/core/state/planilla_incapacidad_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/formato_incapacidad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rango de fechas (con atajos), estado de revisión y búsqueda.
///
/// El rango vuelve a consultar; estado y búsqueda filtran lo ya cargado.
class FiltrosIncapacidad extends ConsumerStatefulWidget {
  const FiltrosIncapacidad({super.key});

  @override
  ConsumerState<FiltrosIncapacidad> createState() => _FiltrosIncapacidadState();
}

class _FiltrosIncapacidadState extends ConsumerState<FiltrosIncapacidad> {
  late final TextEditingController _busqueda;
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    _busqueda = TextEditingController(
      text: ref.read(planillaIncapacidadProvider).busqueda,
    );
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _espera?.cancel();
    _espera = Timer(
      const Duration(milliseconds: 250),
      () => ref.read(planillaIncapacidadProvider.notifier).buscar(texto),
    );
  }

  Future<void> _aplicarRango(DateTime desde, DateTime hasta) async {
    final motivo = await ref
        .read(planillaIncapacidadProvider.notifier)
        .cambiarRango(desde, hasta);
    if (motivo != null && mounted) {
      mostrarAviso(context, motivo, tono: TonoAviso.aviso);
    }
  }

  Future<void> _elegirRango() async {
    final s = ref.read(planillaIncapacidadProvider);
    final r = await pedirRangoDeFechas(
      context,
      titulo: 'Rango de la planilla',
      explicacion: 'Se listan las bajas que empiezan entre estas fechas.',
      desde: s.desde,
      hasta: s.hasta,
      textoAceptar: 'Aplicar',
      iconoAceptar: Icons.check,
      minima: DateTime(2020),
    );
    if (r != null) await _aplicarRango(r.desde, r.hasta);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(planillaIncapacidadProvider);
    final notifier = ref.read(planillaIncapacidadProvider.notifier);
    final atajos = atajosRangoIncapacidad(DateTime.now());

    // Al limpiar filtros desde el estado vacío, el campo también se vacía.
    if (s.busqueda.isEmpty && _busqueda.text.isNotEmpty && _espera?.isActive != true) {
      _busqueda.clear();
    }

    return LayoutBuilder(
      builder: (context, cajon) {
        final angosto = Aire.de(cajon.maxWidth).esChico;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _elegirRango,
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(
                    rangoFiltro(s.desde, s.hasta),
                    style: const TextStyle(fontFeatures: cifrasTabulares),
                  ),
                ),
                for (final a in atajos)
                  ChoiceChip(
                    label: Text(a.nombre),
                    selected: a.desde == s.desde && a.hasta == s.hasta,
                    onSelected: (_) => _aplicarRango(a.desde, a.hasta),
                  ),
              ],
            ),
            const SizedBox(height: Esp.m),
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<FiltroRevision>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: FiltroRevision.todas,
                      label: Text('Todas ${s.total}'),
                    ),
                    ButtonSegment(
                      value: FiltroRevision.pendientes,
                      label: Text('Pendientes ${s.pendientes}'),
                    ),
                    ButtonSegment(
                      value: FiltroRevision.revisadas,
                      label: Text('Revisadas ${s.revisadas}'),
                    ),
                  ],
                  selected: {s.filtro},
                  onSelectionChanged: (v) => notifier.filtrar(v.first),
                ),
                SizedBox(
                  width: angosto ? double.infinity : 340,
                  child: TextField(
                    controller: _busqueda,
                    onChanged: _buscar,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Nombre, motivo o Nº de seguro',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Esquina.chica),
                      ),
                      suffixIcon:
                          s.busqueda.isEmpty
                              ? null
                              : IconButton(
                                tooltip: 'Borrar búsqueda',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _espera?.cancel();
                                  _busqueda.clear();
                                  notifier.buscar('');
                                },
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
