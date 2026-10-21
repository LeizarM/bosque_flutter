/// Agenda de la empresa en el Dashboard: una tarjeta de acceso y el popup con
/// los empleados vigentes, su cargo, su sucursal y sus números corporativos.
///
/// Escritorio: diálogo amplio con filas. Móvil: pantalla completa con
/// tarjetas, filtros que bajan de línea y botón de llamar. Tocar un empleado
/// (o «Ver ficha») abre su ficha si el menú le da esa pantalla al usuario.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bosque_flutter/core/state/agenda_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/presentation/screens/ficha-trabajador/empleado_informacion_screen.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart'
    show normalizarBusqueda;

/// Desde este ancho del diálogo las filas muestran todo en una línea.
const double _anchoFilas = 720;

/// Abre la agenda. Si el usuario elige un empleado, su ficha se abre en el
/// Navigator de [context] (el del dashboard), no encima del menú lateral.
Future<void> abrirAgendaEmpleados(BuildContext context) async {
  final navegador = Navigator.of(context);
  final codEmpleado = await showDialog<int>(
    context: context,
    builder: (ctx) {
      final pantalla = MediaQuery.sizeOf(ctx);
      if (pantalla.width < 600) {
        return const Dialog.fullscreen(child: _Agenda());
      }
      return Dialog(
        insetPadding: const EdgeInsets.all(Esp.xl),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        child: SizedBox(
          width: 920,
          height: pantalla.height * 0.86,
          child: const _Agenda(),
        ),
      );
    },
  );
  if (codEmpleado == null || codEmpleado <= 0) return;
  navegador.push(
    MaterialPageRoute(
      builder: (_) => InfoEmpleadoScreen(codEmpleado: codEmpleado),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE ACCESO EN EL INICIO
// ═══════════════════════════════════════════════════════════════════════════

class AccesoAgendaEmpleados extends StatelessWidget {
  const AccesoAgendaEmpleados({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final icono = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Icon(Icons.contact_phone_outlined, color: cs.onPrimaryContainer),
    );
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agenda de la empresa',
          style: t.titleMedium?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.xs),
        Text(
          'Números corporativos, cargo y sucursal de tus compañeros.',
          style: context.apagado(),
        ),
      ],
    );
    final boton = FilledButton.tonalIcon(
      key: const ValueKey('abrir-agenda'),
      onPressed: () => abrirAgendaEmpleados(context),
      icon: const Icon(Icons.search, size: 18),
      label: const Text('Abrir agenda'),
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: Esp.s),
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirAgendaEmpleados(context),
        child: Padding(
          padding: const EdgeInsets.all(Esp.l),
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        icono,
                        const SizedBox(width: Esp.m),
                        Expanded(child: texto),
                      ],
                    ),
                    const SizedBox(height: Esp.m),
                    boton,
                  ],
                );
              }
              return Row(
                children: [
                  icono,
                  const SizedBox(width: Esp.l),
                  Expanded(child: texto),
                  const SizedBox(width: Esp.m),
                  boton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EL POPUP
// ═══════════════════════════════════════════════════════════════════════════

class _Agenda extends ConsumerStatefulWidget {
  const _Agenda();

  @override
  ConsumerState<_Agenda> createState() => _AgendaState();
}

class _AgendaState extends ConsumerState<_Agenda> {
  final _buscar = TextEditingController();
  String _consulta = '';
  int? _sucursal;
  bool _soloConNumero = false;

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  List<AgendaEmpleadoEntity> _filtrar(List<AgendaEmpleadoEntity> todos) => [
    for (final e in todos)
      if ((_sucursal == null || e.codSucursal == _sucursal) &&
          (!_soloConNumero || e.tieneCorporativo) &&
          (_consulta.isEmpty ||
              normalizarBusqueda(
                '${e.nombreCompleto} ${e.cargo} ${e.sucursal} ${e.telefonos.join(' ')}',
              ).contains(_consulta)))
        e,
  ];

  @override
  Widget build(BuildContext context) {
    final lectura = ref.watch(agendaEmpleadosProvider);
    final puedeVerFicha = ref.watch(puedeVerFichaProvider);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= _anchoFilas;
          final todos = lectura.valueOrNull ?? const <AgendaEmpleadoEntity>[];
          final visibles = _filtrar(todos);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(
                total: todos.length,
                conNumero: todos.where((e) => e.tieneCorporativo).length,
                onCerrar: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ancho ? Esp.xl : Esp.m,
                  Esp.m,
                  ancho ? Esp.xl : Esp.m,
                  Esp.s,
                ),
                child: _Filtros(
                  ancho: ancho,
                  buscar: _buscar,
                  sucursales: _sucursalesDe(todos),
                  sucursal: _sucursal,
                  soloConNumero: _soloConNumero,
                  onBuscar:
                      (t) => setState(() => _consulta = normalizarBusqueda(t.trim())),
                  onSucursal: (s) => setState(() => _sucursal = s),
                  onSoloConNumero: (v) => setState(() => _soloConNumero = v),
                ),
              ),
              Expanded(
                child: _cuerpo(lectura, visibles, ancho, puedeVerFicha),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Las sucursales que aparecen en la agenda, con cuántos empleados tiene cada una.
  List<(int, String, int)> _sucursalesDe(List<AgendaEmpleadoEntity> todos) {
    final cuenta = <int, (String, int)>{};
    for (final e in todos) {
      if (e.codSucursal == 0) continue;
      final previo = cuenta[e.codSucursal];
      cuenta[e.codSucursal] = (e.sucursal, (previo?.$2 ?? 0) + 1);
    }
    final lista = [for (final x in cuenta.entries) (x.key, x.value.$1, x.value.$2)];
    lista.sort((a, b) => a.$2.compareTo(b.$2));
    return lista;
  }

  Widget _cuerpo(
    AsyncValue<List<AgendaEmpleadoEntity>> lectura,
    List<AgendaEmpleadoEntity> visibles,
    bool ancho,
    bool puedeVerFicha,
  ) {
    if (lectura.hasError && !lectura.isLoading) {
      return MensajeError(
        error: lectura.error,
        onReintentar: () => ref.invalidate(agendaEmpleadosProvider),
      );
    }
    if (!lectura.hasValue) return const EsqueletoLista(filas: 7, altoFila: 64);
    if (visibles.isEmpty) {
      return const MensajeVacio(
        icono: Icons.person_search_outlined,
        titulo: 'Nadie coincide',
        detalle: 'Prueba con otro nombre, cargo o número, o quita los filtros.',
      );
    }
    final margen = ancho ? Esp.xl : Esp.m;
    return ListView.separated(
      key: const ValueKey('lista-agenda'),
      padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.xl),
      itemCount: visibles.length,
      separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
      itemBuilder:
          (context, i) => _FilaEmpleado(
            key: ValueKey('agenda-${visibles[i].codEmpleado}'),
            empleado: visibles[i],
            ancho: ancho,
            puedeVerFicha: puedeVerFicha,
          ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.total,
    required this.conNumero,
    required this.onCerrar,
  });

  final int total;
  final int conNumero;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.s, Esp.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.contact_phone, color: cs.onPrimaryContainer, size: 28),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agenda de la empresa',
                  style: t.titleLarge?.copyWith(
                    fontWeight: Peso.titulo,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                if (total > 0)
                  Text(
                    '$total empleados vigentes · $conNumero con número corporativo',
                    style: t.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar,
            icon: Icon(Icons.close, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.ancho,
    required this.buscar,
    required this.sucursales,
    required this.sucursal,
    required this.soloConNumero,
    required this.onBuscar,
    required this.onSucursal,
    required this.onSoloConNumero,
  });

  final bool ancho;
  final TextEditingController buscar;
  final List<(int, String, int)> sucursales;
  final int? sucursal;
  final bool soloConNumero;
  final ValueChanged<String> onBuscar;
  final ValueChanged<int?> onSucursal;
  final ValueChanged<bool> onSoloConNumero;

  @override
  Widget build(BuildContext context) {
    final campo = TextField(
      key: const ValueKey('buscar-agenda'),
      controller: buscar,
      autofocus: ancho,
      onChanged: onBuscar,
      decoration: InputDecoration(
        hintText: 'Buscar nombre, cargo o número',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
      ),
    );
    final combo = DropdownMenu<int>(
      key: ValueKey('sucursal-$sucursal-${sucursales.length}'),
      width: ancho ? 260 : null,
      expandedInsets: ancho ? null : EdgeInsets.zero,
      label: const Text('Sucursal'),
      initialSelection: sucursal ?? 0,
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: 0, label: 'Todas las sucursales'),
        for (final (cod, nombre, n) in sucursales)
          DropdownMenuEntry(value: cod, label: '$nombre ($n)'),
      ],
      onSelected: (v) => onSucursal(v == null || v == 0 ? null : v),
    );
    final chip = FilterChip(
      label: const Text('Con número corporativo'),
      selected: soloConNumero,
      onSelected: onSoloConNumero,
    );

    if (ancho) {
      return Row(
        children: [
          Expanded(child: campo),
          const SizedBox(width: Esp.m),
          combo,
          const SizedBox(width: Esp.m),
          chip,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        campo,
        const SizedBox(height: Esp.s),
        combo,
        const SizedBox(height: Esp.s),
        Align(alignment: Alignment.centerLeft, child: chip),
      ],
    );
  }
}

class _FilaEmpleado extends StatelessWidget {
  const _FilaEmpleado({
    super.key,
    required this.empleado,
    required this.ancho,
    required this.puedeVerFicha,
  });

  final AgendaEmpleadoEntity empleado;
  final bool ancho;
  final bool puedeVerFicha;

  void _verFicha(BuildContext context) =>
      Navigator.of(context).pop(empleado.codEmpleado.toInt());

  Future<void> _copiar(BuildContext context, String numero) async {
    await Clipboard.setData(ClipboardData(text: numero));
    if (context.mounted) avisar(context, 'Número $numero copiado.');
  }

  Future<void> _llamar(BuildContext context, String numero) async {
    final uri = Uri(scheme: 'tel', path: numero.replaceAll(' ', ''));
    final ok = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!ok && context.mounted) await _copiar(context, numero);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final e = empleado;

    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: cs.secondaryContainer,
      child: Text(
        e.iniciales,
        style: t.labelLarge?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: Peso.dato,
        ),
      ),
    );
    final nombre = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.nombreCompleto,
          style: t.bodyLarge?.copyWith(fontWeight: Peso.titulo),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          e.cargo.isEmpty ? 'Sin cargo registrado' : e.cargo,
          style: context.apagado(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final sucursal = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.store_mall_directory_outlined, size: 16, color: cs.outline),
        const SizedBox(width: Esp.xs),
        Flexible(
          child: Text(
            e.sucursal.isEmpty ? '—' : e.sucursal,
            style: t.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final numeros =
        e.tieneCorporativo
            ? Wrap(
              spacing: Esp.xs,
              runSpacing: Esp.xs,
              children: [
                for (final n in e.telefonos)
                  ActionChip(
                    avatar: const Icon(Icons.phone_outlined, size: 16),
                    label: Text(
                      n,
                      style: const TextStyle(fontFeatures: cifrasTabulares),
                    ),
                    tooltip: 'Copiar $n',
                    onPressed: () => _copiar(context, n),
                  ),
              ],
            )
            : Text(
              'Sin número corporativo',
              style: context.apagado()?.copyWith(fontStyle: FontStyle.italic),
            );
    final ficha =
        puedeVerFicha
            ? IconButton.filledTonal(
              tooltip: 'Ver ficha',
              onPressed: () => _verFicha(context),
              icon: const Icon(Icons.badge_outlined),
            )
            : null;

    final contenido =
        ancho
            ? Row(
              children: [
                avatar,
                const SizedBox(width: Esp.m),
                Expanded(flex: 4, child: nombre),
                const SizedBox(width: Esp.m),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: sucursal)),
                const SizedBox(width: Esp.m),
                Expanded(flex: 3, child: numeros),
                if (ficha != null) ...[const SizedBox(width: Esp.s), ficha],
              ],
            )
            : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      nombre,
                      const SizedBox(height: Esp.xs),
                      sucursal,
                      const SizedBox(height: Esp.s),
                      numeros,
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e.tieneCorporativo)
                      IconButton.filled(
                        tooltip: 'Llamar',
                        onPressed: () => _llamar(context, e.telefonos.first),
                        icon: const Icon(Icons.call),
                      ),
                    if (ficha != null) ficha,
                  ],
                ),
              ],
            );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: puedeVerFicha ? () => _verFicha(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.l,
            vertical: Esp.m,
          ),
          child: contenido,
        ),
      ),
    );
  }
}
