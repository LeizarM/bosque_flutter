import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_evento_detalle.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_eventos_dialogos.dart';

/// `ttkEventos/Eventos` (RRHH): eventos con sus vales. La lista abre el
/// detalle en la misma pantalla; el estado de cada evento decide sus acciones.
class TtkEventosScreen extends ConsumerStatefulWidget {
  const TtkEventosScreen({super.key});

  @override
  ConsumerState<TtkEventosScreen> createState() => _TtkEventosScreenState();
}

class _TtkEventosScreenState extends ConsumerState<TtkEventosScreen> {
  final _buscador = TextEditingController();
  String _buscar = '';
  String? _estado;
  int? _anio;
  BigInt? _abierto;

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  Future<void> _nuevo() async {
    final id = await editarEventoTtk(context, ref);
    if (id != null && id > BigInt.zero && mounted) {
      setState(() => _abierto = id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          if (_abierto != null) {
            return DetalleEventoTtk(
              codEvento: _abierto!,
              alVolver: () => setState(() => _abierto = null),
            );
          }
          final compacto = Aire.de(c.maxWidth).esChico;
          final relleno = compacto ? Esp.m : Esp.xl;
          return Padding(
            padding: EdgeInsets.fromLTRB(relleno, relleno, relleno, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoTtk(
                  ceja: 'Tickets',
                  titulo: 'Eventos y vales',
                  detalle:
                      'Arma la lista de cada evento, reparte los vales y emítelos para imprimir.',
                  compacto: compacto,
                  acciones: [
                    PermissionWidget(
                      buttonName: BotonTtkEvento.nuevo,
                      child: FilledButton.icon(
                        onPressed: _nuevo,
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo evento'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Expanded(child: _lista()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _lista() {
    final filtro = (estado: _estado, anio: _anio);
    final asincrono = ref.watch(ttkEventosProvider(filtro));
    final hoy = DateTime.now().year;
    final filtros = [
      DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _estado,
          borderRadius: BorderRadius.circular(Esquina.chica),
          items: const [
            DropdownMenuItem(value: null, child: Text('Todos los estados')),
            DropdownMenuItem(value: 'BORRADOR', child: Text('Borrador')),
            DropdownMenuItem(value: 'EMITIDO', child: Text('Vales emitidos')),
            DropdownMenuItem(value: 'CERRADO', child: Text('Cerrados')),
          ],
          onChanged: (v) => setState(() => _estado = v),
        ),
      ),
      DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _anio,
          borderRadius: BorderRadius.circular(Esquina.chica),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos los años')),
            for (var a = hoy + 1; a >= hoy - 4; a--)
              DropdownMenuItem(value: a, child: Text('$a')),
          ],
          onChanged: (v) => setState(() => _anio = v),
        ),
      ),
    ];

    return asincrono.when(
      skipLoadingOnReload: true,
      loading: () => const EsqueletoListaTtk(),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar: () => ref.invalidate(ttkEventosProvider(filtro)),
          ),
      data: (todos) {
        if (todos.isEmpty && _estado == null && _anio == null) {
          return const MensajeVacio(
            icono: Icons.celebration_outlined,
            titulo: 'Todavía no hay eventos',
            detalle:
                'Crea el primero: aniversario, fiesta de fin de año o el que toque.',
          );
        }
        final q = _buscar.toLowerCase();
        final eventos = [
          for (final e in todos)
            if (q.isEmpty ||
                e.nombre.toLowerCase().contains(q) ||
                (e.lugar ?? '').toLowerCase().contains(q))
              e,
        ];
        return ListadoTtk<TtkEventoEntity>(
          filas: eventos,
          buscador: _buscador,
          alBuscar: (t) => setState(() => _buscar = t.trim()),
          pistaBuscar: 'Buscar evento o lugar',
          filtros: filtros,
          columnas: [
            BosqueColumn(
              label: 'Evento',
              flex: 4,
              cellBuilder:
                  (e) => InkWell(
                    onTap: () => setState(() => _abierto = e.codEvento),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.nombre, style: context.tituloSeccion()),
                        if ((e.lugar ?? '').isNotEmpty)
                          Text(e.lugar!, style: context.apagado()),
                      ],
                    ),
                  ),
            ),
            BosqueColumn(
              label: 'Fecha',
              flex: 2,
              cellBuilder:
                  (e) => Text(fechaCorta(e.fecha), style: context.numero()),
            ),
            BosqueColumn(
              label: 'Estado',
              flex: 2,
              cellBuilder:
                  (e) => Etiqueta(
                    texto: e.estadoTexto,
                    tono: ttkTonoEstado(e.estado),
                  ),
            ),
            BosqueColumn(
              label: 'Lista',
              flex: 3,
              cellBuilder:
                  (e) => Text(
                    '${e.totalEmpleados} emp · ${e.totalRecientes} rec · ${e.totalInvitados} inv',
                    style: context.numero(),
                  ),
            ),
            BosqueColumn(
              label: 'Vales',
              alignment: Alignment.center,
              cellBuilder:
                  (e) => Text(
                    '${e.totalTickets}',
                    style: context.numero(fuerte: true),
                  ),
            ),
            BosqueColumn(
              label: 'Bingo',
              flex: 2,
              cellBuilder:
                  (e) =>
                      e.usaBingo
                          ? const Etiqueta(texto: 'Con bingo')
                          : Text('—', style: context.apagado()),
            ),
            BosqueColumn(
              label: 'Acciones',
              flex: 4,
              alignment: Alignment.center,
              cellBuilder: (e) => AccionesEnLineaTtk(acciones: _acciones(e)),
            ),
          ],
          tarjeta:
              (e) => TarjetaTtk(
                titulo: e.nombre,
                subtitulo: [
                  fechaCorta(e.fecha),
                  if ((e.lugar ?? '').isNotEmpty) e.lugar!,
                ].join(' · '),
                etiquetas: [
                  Etiqueta(texto: e.estadoTexto, tono: ttkTonoEstado(e.estado)),
                  if (e.usaBingo) const Etiqueta(texto: 'Con bingo'),
                ],
                pie: Text(
                  '${e.totalParticipantes} en la lista · ${e.totalTickets} vales',
                  style: context.apagado(),
                ),
                acciones: _acciones(e),
                alTocar: () => setState(() => _abierto = e.codEvento),
              ),
        );
      },
    );
  }

  List<AccionTtk> _acciones(TtkEventoEntity e) => accionesEventoTtk(
    context,
    ref,
    e,
    abrir: () => setState(() => _abierto = e.codEvento),
  );
}
