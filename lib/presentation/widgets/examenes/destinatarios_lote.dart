/// A quiénes van los exámenes de un lote (lote mixto): el bloque «Externos»
/// (cantidad o lista de personas) y el bloque «Empleados», activables a la
/// vez, con el total a generar. Lo usan generar lote y agregar exámenes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_elegible_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_personas.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';

/// Desde este ancho los dos bloques van lado a lado y su detalle debajo; más
/// angosto se apilan, cada uno con su detalle adentro.
const double _anchoEnFila = 520;

/// Qué bloques están activos y lo que pide cada uno. Notifica los cambios de
/// estructura; [conteo] además avisa cuando cambia cualquier cantidad.
class ControladorDestinatarios extends ChangeNotifier {
  ControladorDestinatarios({int cantidadInicial = 1}) : cantidad = TextEditingController(text: '$cantidadInicial');

  final TextEditingController cantidad;
  final ControladorPersonas personas = ControladorPersonas();
  bool _externos = true;
  bool _conEmpleados = false;
  ModoExternos _modoExternos = ModoExternos.cantidad;
  Set<BigInt> _empleados = const {};

  late final Listenable conteo = Listenable.merge([this, cantidad, personas]);

  bool get externos => _externos;
  bool get conEmpleados => _conEmpleados;
  ModoExternos get modoExternos => _modoExternos;
  Set<BigInt> get empleados => _empleados;

  /// La grilla de personas está a la vista: el formulario se ensancha.
  bool get conPersonas => _externos && _modoExternos == ModoExternos.personas;

  set externos(bool v) => _cambiar(() => _externos = v);
  set conEmpleados(bool v) => _cambiar(() => _conEmpleados = v);
  set modoExternos(ModoExternos v) => _cambiar(() => _modoExternos = v);
  set empleados(Set<BigInt> v) => _cambiar(() => _empleados = Set.unmodifiable(v));

  void _cambiar(VoidCallback cambio) {
    cambio();
    notifyListeners();
  }

  int get _cantidadAnonimos =>
      _externos && _modoExternos == ModoExternos.cantidad ? (int.tryParse(cantidad.text.trim()) ?? 0) : 0;

  int get cantidadExternos => _cantidadAnonimos + (conPersonas ? personas.personas.length : 0);
  int get cantidadEmpleados => _conEmpleados ? _empleados.length : 0;

  /// Lo que falta y el `Form` no valida (null si se puede enviar). Con la
  /// lista de personas, desde aquí sus campos muestran los errores.
  String? validar() {
    if (!_externos && !_conEmpleados) return 'Elige quiénes rinden: externos, empleados o ambos.';
    if (conPersonas) {
      final error = personas.validar();
      if (error != null) return error;
    }
    if (_conEmpleados && _empleados.isEmpty) return 'Elige al menos un empleado o desactiva «Empleados».';
    return null;
  }

  /// El pedido con todos los bloques activos; el total lo valida el SP.
  TcpePedidoExamenesEntity get pedido => TcpePedidoExamenesEntity(
    cantidad: _cantidadAnonimos,
    personas: conPersonas ? personas.personas : const [],
    codEmpleados: _conEmpleados ? _empleados.toList() : const [],
  );

  @override
  void dispose() {
    cantidad.dispose();
    personas.dispose();
    super.dispose();
  }
}

/// Los dos bloques y el total. En escritorio, los bloques lado a lado con su
/// detalle debajo; en el teléfono, apilados como tarjetas que se despliegan.
class SelectorDestinatarios extends StatelessWidget {
  const SelectorDestinatarios({
    super.key,
    required this.controlador,
    this.escrito = false,
    this.maximo = 200,
    this.yaTiene = 0,
    this.codRolExamen,
  });

  final ControladorDestinatarios controlador;

  /// El lote al que se agrega (null al generar uno nuevo).
  final BigInt? codRolExamen;

  /// Lote escrito: nadie recibe usuario ni clave, el examen se imprime.
  final bool escrito;

  /// `maxExamenesPorLote` de la configuración.
  final int maximo;

  /// Exámenes que el lote ya tiene (al agregar).
  final int yaTiene;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador,
    builder:
        (context, _) => LayoutBuilder(
          builder: (context, r) {
            final enFila = r.maxWidth >= _anchoEnFila;
            final c = controlador;
            Widget externos({Widget? detalle}) => _Bloque(
              icono: Icons.badge_outlined,
              titulo: 'Externos',
              resumen: escrito ? 'Postulantes: el examen se imprime.' : 'Postulantes: reciben usuario y clave.',
              activo: c.externos,
              onCambio: (v) => c.externos = v,
              detalle: detalle,
            );
            Widget empleados({Widget? detalle}) => _Bloque(
              icono: Icons.groups_outlined,
              titulo: 'Empleados',
              resumen: escrito ? 'El examen sale con su nombre y CI.' : 'Rinden con su usuario de Bosque.',
              activo: c.conEmpleados,
              onCambio: (v) => c.conEmpleados = v,
              detalle: detalle,
            );
            final detalleExternos = _DetalleExternos(controlador: c, escrito: escrito, corto: !enFila);
            final detalleEmpleados = _DetalleEmpleados(
              controlador: c,
              escrito: escrito,
              ancho: !enFila,
              codRolExamen: codRolExamen,
            );
            final total = _TotalPedido(controlador: c, escrito: escrito, maximo: maximo, yaTiene: yaTiene);

            if (!enFila) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  externos(detalle: c.externos ? detalleExternos : null),
                  const SizedBox(height: Esp.s),
                  empleados(detalle: c.conEmpleados ? detalleEmpleados : null),
                  const SizedBox(height: Esp.m),
                  total,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: externos()),
                      const SizedBox(width: Esp.m),
                      Expanded(child: empleados()),
                    ],
                  ),
                ),
                if (c.externos) ...[
                  const SizedBox(height: Esp.m),
                  EntradaSuave(child: _Panel(titulo: 'Externos', child: detalleExternos)),
                ],
                if (c.conEmpleados) ...[
                  const SizedBox(height: Esp.m),
                  EntradaSuave(child: _Panel(titulo: 'Empleados', child: detalleEmpleados)),
                ],
                const SizedBox(height: Esp.m),
                total,
              ],
            );
          },
        ),
  );
}

/// Un bloque que se activa con un toque: la burbuja se marca como en la hoja
/// de respuestas. En el teléfono lleva su [detalle] adentro.
class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.icono,
    required this.titulo,
    required this.resumen,
    required this.activo,
    required this.onCambio,
    this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String resumen;
  final bool activo;
  final ValueChanged<bool> onCambio;
  final Widget? detalle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Esquina.media),
      side: BorderSide(color: activo ? cs.primary : cs.outlineVariant, width: activo ? 1.5 : 1),
    );
    return Material(
      color: activo ? cs.surfaceContainerLow : cs.surface,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      animationDuration: duracionSuave(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MergeSemantics(
            child: Semantics(
              checked: activo,
              child: InkWell(
                onTap: () => onCambio(!activo),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.all(Esp.m),
                    child: Row(
                      children: [
                        BurbujaHoja(
                          texto: '',
                          tamanio: 28,
                          marca: activo ? MarcaBurbuja.marcada : MarcaBurbuja.vacia,
                          hijo: activo ? Icon(Icons.check, size: 18, color: cs.onPrimary) : null,
                        ),
                        const SizedBox(width: Esp.m),
                        Icon(icono, size: 20, color: activo ? cs.primary : cs.onSurfaceVariant),
                        const SizedBox(width: Esp.s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(titulo, style: context.tituloSeccion()),
                              Text(resumen, style: context.apagado()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duracionSuave(context),
            alignment: Alignment.topCenter,
            child:
                detalle == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(padding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m), child: detalle),
          ),
        ],
      ),
    );
  }
}

/// El detalle de un bloque en escritorio: superficie tenue con su título.
class _Panel extends StatelessWidget {
  const _Panel({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(color: cs.surfaceContainerLow, shape: contornoSuperficie(cs)),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [Text(titulo, style: context.tituloSeccion()), const SizedBox(height: Esp.s), child],
        ),
      ),
    );
  }
}

/// Externos: anónimos por cantidad o una lista de personas con CI.
class _DetalleExternos extends StatelessWidget {
  const _DetalleExternos({required this.controlador, required this.escrito, required this.corto});

  final ControladorDestinatarios controlador;
  final bool escrito;

  /// Rótulos cortos y sin íconos en el teléfono.
  final bool corto;

  @override
  Widget build(BuildContext context) {
    final c = controlador;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          escrito
              ? 'No llevan usuario ni clave: cada examen se imprime.'
              : 'Cada externo recibe su usuario IPX-n y una clave temporal al azar, que deja de funcionar cuando '
                  'entrega su examen. Las credenciales se muestran al generar.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.s),
        SegmentedButton<ModoExternos>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ModoExternos.cantidad,
              label: const Text('Cantidad'),
              icon: corto ? null : const Icon(Icons.numbers),
            ),
            ButtonSegment(
              value: ModoExternos.personas,
              label: Text(corto ? 'Personas' : 'Lista de personas'),
              icon: corto ? null : const Icon(Icons.badge_outlined),
            ),
          ],
          selected: {c.modoExternos},
          onSelectionChanged: (s) => c.modoExternos = s.first,
        ),
        const SizedBox(height: Esp.m),
        if (c.modoExternos == ModoExternos.cantidad)
          TextFormField(
            controller: c.cantidad,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            decoration: InputDecoration(
              labelText: escrito ? 'Cantidad de exámenes' : 'Cantidad de postulantes',
              helperText:
                  escrito
                      ? 'Un examen distinto por persona, sin nombre: se completa a mano.'
                      : 'Usuarios anónimos: cada uno completa sus datos al ingresar.',
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
            // Solo el formato: el total y el máximo los valida Lote V con su mensaje.
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n < 1) return escrito ? 'Indica cuántos exámenes' : 'Indica cuántos postulantes';
              return null;
            },
          )
        else ...[
          Text(
            escrito
                ? 'Cada examen sale impreso con el nombre y el CI de la persona.'
                : 'Si alguien ya tiene usuario con el mismo CI, se reutiliza su login.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.s),
          EditorPersonasExamen(controlador: c.personas),
        ],
      ],
    );
  }
}

/// Empleados: se eligen de la lista; rinden con su usuario de Bosque.
class _DetalleEmpleados extends StatelessWidget {
  const _DetalleEmpleados({required this.controlador, required this.escrito, required this.ancho, this.codRolExamen});

  final ControladorDestinatarios controlador;
  final bool escrito;

  /// Al agregar: el lote, para marcar a los que ya tienen examen en él.
  final BigInt? codRolExamen;

  /// En el teléfono el botón ocupa todo el ancho.
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final n = controlador.empleados.length;
    final boton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: () async {
        final r = await elegirEmpleados(context, controlador.empleados, codRolExamen: codRolExamen);
        if (r != null) controlador.empleados = r;
      },
      icon: Icon(n == 0 ? Icons.person_add_alt_outlined : Icons.edit_outlined, size: 18),
      label: Text(n == 0 ? 'Elegir empleados' : '$n ${n == 1 ? 'empleado elegido' : 'empleados elegidos'} · Cambiar'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          escrito
              ? 'Cada examen sale impreso con el nombre y el CI del empleado.'
              : 'Cada empleado lo rinde en «Mis exámenes» con su usuario de Bosque: no recibe clave.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.s),
        if (ancho) boton else Align(alignment: Alignment.centerLeft, child: boton),
      ],
    );
  }
}

/// El total a generar como una burbuja grande, con el desglose. Al agregar,
/// cuántos quedan en el lote; el máximo real lo valida Lote V.
class _TotalPedido extends StatelessWidget {
  const _TotalPedido({required this.controlador, required this.escrito, required this.maximo, required this.yaTiene});

  final ControladorDestinatarios controlador;
  final bool escrito;
  final int maximo;
  final int yaTiene;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador.conteo,
    builder: (context, _) {
      final cs = Theme.of(context).colorScheme;
      final externos = controlador.cantidadExternos;
      final empleados = controlador.cantidadEmpleados;
      final total = externos + empleados;
      final queda = yaTiene + total;
      final excede = queda > maximo;
      final partes = [
        if (externos > 0) '$externos ${externos == 1 ? 'externo' : 'externos'}${escrito ? '' : ' con credencial'}',
        if (empleados > 0) '$empleados ${empleados == 1 ? 'empleado' : 'empleados'}${escrito ? '' : ' sin clave'}',
      ];
      final limite =
          yaTiene > 0
              ? 'El lote queda con $queda de $maximo.'
              : excede
              ? 'Supera el máximo de $maximo por lote.'
              : null;
      return Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: cs.surfaceContainerHighest, shape: contornoSuperficie(cs)),
          child: Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: Row(
              children: [
                BurbujaHoja(
                  texto: '$total',
                  tamanio: 44,
                  marca:
                      total == 0
                          ? MarcaBurbuja.vacia
                          : excede
                          ? MarcaBurbuja.error
                          : MarcaBurbuja.marcada,
                ),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(total == 1 ? 'examen a generar' : 'exámenes a generar', style: context.tituloSeccion()),
                      Text(
                        partes.isEmpty ? 'Activa «Externos», «Empleados» o ambos.' : partes.join(' · '),
                        style: context.apagado(),
                      ),
                      if (limite != null)
                        Text(limite, style: context.apagado()?.copyWith(color: excede ? cs.error : null)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SELECTOR DE EMPLEADOS
// ═══════════════════════════════════════════════════════════════════════════

Future<Set<BigInt>?> elegirEmpleados(BuildContext context, Set<BigInt> elegidos, {BigInt? codRolExamen}) =>
    mostrarFormulario<Set<BigInt>>(
      context,
      (completa) => _SelectorEmpleados(inicial: elegidos, completa: completa, codRolExamen: codRolExamen),
    );

class _SelectorEmpleados extends ConsumerStatefulWidget {
  const _SelectorEmpleados({required this.inicial, required this.completa, this.codRolExamen});

  final BigInt? codRolExamen;

  final Set<BigInt> inicial;
  final bool completa;

  @override
  ConsumerState<_SelectorEmpleados> createState() => _SelectorEmpleadosState();
}

class _SelectorEmpleadosState extends ConsumerState<_SelectorEmpleados> {
  late final Set<BigInt> _elegidos = {...widget.inicial};
  String _buscar = '';

  @override
  Widget build(BuildContext context) {
    final empleados = ref.watch(tcpeEmpleadosElegiblesProvider(widget.codRolExamen));
    return MarcoFormulario(
      titulo: 'Elegir empleados',
      icono: Icons.groups_outlined,
      completa: widget.completa,
      cuerpo: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Buscar por nombre, CI o cargo',
              border: OutlineInputBorder(),
            ),
            onChanged: (t) => setState(() => _buscar = t.trim().toLowerCase()),
          ),
          const SizedBox(height: Esp.s),
          Text(_elegidos.length == 1 ? '1 elegido' : '${_elegidos.length} elegidos', style: context.apagado()),
          const SizedBox(height: Esp.s),
          empleados.when(
            loading: () => const Padding(padding: EdgeInsets.all(Esp.xl), child: Center(child: CircularProgressIndicator())),
            error:
                (e, _) => MensajeError(
                  error: e,
                  compacto: true,
                  onReintentar: () => ref.invalidate(tcpeEmpleadosElegiblesProvider(widget.codRolExamen)),
                ),
            data: (lista) {
              final filtrados = [
                for (final e in lista)
                  if (_buscar.isEmpty || '${e.nombreCompleto} ${e.ci} ${e.cargo}'.toLowerCase().contains(_buscar)) e,
              ];
              if (filtrados.isEmpty) {
                return const MensajeVacio(icono: Icons.person_search, titulo: 'Sin resultados', detalle: 'Prueba con otro nombre o CI.');
              }
              return SizedBox(
                height: widget.completa ? MediaQuery.sizeOf(context).height * 0.6 : 360,
                child: ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final e = filtrados[i];
                    final cod = e.codEmpleado;
                    return _FilaEmpleado(
                      empleado: e,
                      elegido: e.puedeRendir && _elegidos.contains(cod),
                      onCambio:
                          e.puedeRendir
                              ? (v) => setState(() => v ? _elegidos.add(cod) : _elegidos.remove(cod))
                              : null,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      acciones: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _elegidos), child: const Text('Listo')),
      ],
    );
  }
}

/// Un empleado en el selector: nombre, CI y cargo actual. Si no se le puede
/// asignar un examen, la fila va apagada con el motivo que da el SQL.
class _FilaEmpleado extends StatelessWidget {
  const _FilaEmpleado({required this.empleado, required this.elegido, required this.onCambio});

  final TcpeEmpleadoElegibleEntity empleado;
  final bool elegido;
  final ValueChanged<bool>? onCambio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = empleado;
    return CheckboxListTile(
      dense: true,
      value: elegido,
      enabled: onCambio != null,
      onChanged: onCambio == null ? null : (v) => onCambio!(v ?? false),
      title: Text(oGuion(e.nombreCompleto)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('CI ${oGuion(e.ci)}', style: context.numero()?.copyWith(fontFamily: fuenteFija)),
                if ((e.cargo ?? '').trim().isNotEmpty)
                  PastillaExamen(texto: e.cargo!.trim(), tono: TonoExamen.secundario, icono: Icons.work_outline),
              ],
            ),
            if (!e.puedeRendir && (e.motivo ?? '').isNotEmpty) ...[
              const SizedBox(height: Esp.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block, size: 14, color: cs.error),
                  const SizedBox(width: Esp.xs),
                  Expanded(
                    child: Text(e.motivo!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
