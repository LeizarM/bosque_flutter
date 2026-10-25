import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_encargado.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_carton_papel.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_jugar.dart';

/// `ttkBingo/MiCarton` (todo empleado): elegir un cartón disponible, ver los
/// propios, imprimirlos, jugar marcando a mano y entrar al en vivo.
class TtkMiCartonScreen extends ConsumerStatefulWidget {
  const TtkMiCartonScreen({super.key});

  @override
  ConsumerState<TtkMiCartonScreen> createState() => _TtkMiCartonScreenState();
}

class _TtkMiCartonScreenState extends ConsumerState<TtkMiCartonScreen> {
  BigInt? _elegido;
  bool _eligiendo = false;
  bool _jugando = false;

  void _refrescar(BigInt codBingo) {
    ref.invalidate(ttkMisBingosProvider);
    ref.invalidate(ttkMisCartonesProvider(codBingo));
    ref.invalidate(ttkCartonesDisponiblesProvider(codBingo));
  }

  @override
  Widget build(BuildContext context) {
    final bingos = ref.watch(ttkMisBingosProvider);
    final t = Theme.of(context).textTheme;
    // Letra un punto más grande en toda la pantalla: la usan personas mayores.
    final escala = MediaQuery.textScalerOf(context).scale(14) / 14;
    final tema = Theme.of(context).copyWith(
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          textStyle: t.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          textStyle: t.titleMedium,
        ),
      ),
    );
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(escala * 1.08)),
      child: Theme(
        data: tema,
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, c) {
              final compacto = Aire.de(c.maxWidth).esChico;
              final relleno = compacto ? Esp.m : Esp.xl;
              return Padding(
                padding: EdgeInsets.fromLTRB(relleno, relleno, relleno, 0),
                child: bingos.when(
                  skipLoadingOnReload: true,
                  loading: () => const EsqueletoListaTtk(),
                  error:
                      (e, _) => MensajeError(
                        error: e,
                        onReintentar:
                            () => ref.invalidate(ttkMisBingosProvider),
                      ),
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const MensajeVacio(
                        icono: Icons.casino_outlined,
                        titulo: 'No hay bingos por ahora',
                        detalle:
                            'Cuando RRHH abra la elección de cartones, aparece aquí.',
                      );
                    }
                    final b = lista.firstWhere(
                      (x) => x.codBingo == _elegido,
                      orElse: () => lista.first,
                    );
                    if (_eligiendo && b.puedeElegir) {
                      return _ElegirCarton(
                        bingo: b,
                        compacto: compacto,
                        alVolver: () => setState(() => _eligiendo = false),
                        // La escena ya reveló sus números: solo se vuelve a «Mi cartón».
                        alElegir: (_) {
                          _refrescar(b.codBingo!);
                          setState(() => _eligiendo = false);
                        },
                      );
                    }
                    if (_jugando && b.estado == 'EN_JUEGO') {
                      final mios = ref.watch(
                        ttkMisCartonesProvider(b.codBingo!),
                      );
                      final cartones = mios.valueOrNull ?? const [];
                      if (cartones.isNotEmpty) {
                        return JugarBingoTtk(
                          bingo: b,
                          cartones: cartones,
                          alVolver: () => setState(() => _jugando = false),
                        );
                      }
                      if (mios.isLoading) return const EsqueletoListaTtk();
                    }
                    return _MiBingo(
                      bingos: lista,
                      bingo: b,
                      compacto: compacto,
                      alCambiarBingo: (cod) => setState(() => _elegido = cod),
                      alElegir: () => setState(() => _eligiendo = true),
                      alJugar: () => setState(() => _jugando = true),
                      alRefrescar: () => _refrescar(b.codBingo!),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiBingo extends ConsumerWidget {
  const _MiBingo({
    required this.bingos,
    required this.bingo,
    required this.compacto,
    required this.alCambiarBingo,
    required this.alElegir,
    required this.alJugar,
    required this.alRefrescar,
  });

  final List<TtkBingoParticipanteEntity> bingos;
  final TtkBingoParticipanteEntity bingo;
  final bool compacto;
  final ValueChanged<BigInt?> alCambiarBingo;
  final VoidCallback alElegir;
  final VoidCallback alJugar;
  final VoidCallback alRefrescar;

  Future<void> _imprimir(BuildContext context, WidgetRef ref) =>
      imprimirCeldasTtk(
        context,
        nombreEvento: bingo.nombreEvento,
        letras: bingo.letras,
        celdas:
            () => ref
                .read(ttkBingoRepositoryProvider)
                .misCeldas(codBingo: bingo.codBingo),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final b = bingo;
    final mios = ref.watch(ttkMisCartonesProvider(b.codBingo!));

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Esp.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EncabezadoTtk(
              ceja: 'Bingo',
              titulo: 'Mi cartón',
              compacto: compacto,
              acciones: [
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: alRefrescar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: Esp.l),
            if (bingos.length > 1) ...[
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: [
                  for (final x in bingos)
                    ChoiceChip(
                      label: Text(x.nombreEvento),
                      selected: x.codBingo == b.codBingo,
                      onSelected: (_) => alCambiarBingo(x.codBingo),
                    ),
                ],
              ),
              const SizedBox(height: Esp.l),
            ],
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: cs.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Esquina.media),
              ),
              child: Padding(
                padding: EdgeInsets.all(compacto ? Esp.l : Esp.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Esp.s,
                      runSpacing: Esp.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          b.nombreEvento,
                          style: t.headlineSmall?.copyWith(
                            fontWeight: Peso.titulo,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        Etiqueta(
                          texto: b.estadoTexto,
                          tono: ttkTonoEstado(b.estado),
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      fechaCorta(b.fechaEvento),
                      style: t.bodyLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: Esp.l),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        b.mensaje,
                        style: t.titleLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: Esp.l),
                    Wrap(
                      spacing: Esp.m,
                      runSpacing: Esp.m,
                      children: [
                        if (b.puedeElegir)
                          FilledButton.icon(
                            onPressed: alElegir,
                            icon: const Icon(Icons.touch_app_outlined),
                            label: const Text('Elegir mi cartón'),
                          ),
                        if (b.estado == 'EN_JUEGO' && b.misCartones > 0)
                          FilledButton.icon(
                            onPressed: alJugar,
                            icon: const Icon(Icons.grid_on_outlined),
                            label: const Text('Jugar con mi cartón'),
                          ),
                        if (b.puedeVerEnVivo)
                          FilledButton.icon(
                            onPressed:
                                () => context.go(
                                  '/dashboard/${AppConstants.rutaTtkEnVivo}',
                                  extra: b.codBingo,
                                ),
                            icon: const Icon(Icons.live_tv_outlined),
                            label: const Text('Ver el bingo en vivo'),
                          ),
                        if (b.misCartones > 0)
                          OutlinedButton.icon(
                            onPressed: () => _imprimir(context, ref),
                            icon: const Icon(Icons.print_outlined),
                            label: Text(
                              b.misCartones == 1
                                  ? 'Imprimir mi cartón'
                                  : 'Imprimir mis cartones',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Esp.xl),
            Text(
              'Mis cartones (${b.misCartones} de ${b.maxCartonesEmpleado})',
              style: t.titleLarge?.copyWith(fontWeight: Peso.titulo),
            ),
            const SizedBox(height: Esp.m),
            mios.when(
              skipLoadingOnReload: true,
              loading: () => const LinearProgressIndicator(),
              error:
                  (e, _) => MensajeError(
                    error: e,
                    compacto: true,
                    onReintentar: alRefrescar,
                  ),
              data:
                  (lista) =>
                      lista.isEmpty
                          ? Text(
                            'Todavía no tienes cartón en este bingo. Toca «Elegir mi cartón» cuando la elección esté abierta, o pídele uno al encargado.',
                            style: t.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          )
                          : Wrap(
                            spacing: Esp.m,
                            runSpacing: Esp.m,
                            children: [
                              for (final k in lista)
                                SizedBox(
                                  width: compacto ? double.infinity : 320,
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    elevation: 0,
                                    color: cs.surfaceContainerLow,
                                    shape: contornoSuperficie(cs),
                                    child: Padding(
                                      padding: const EdgeInsets.all(Esp.l),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text('Cartón N°', style: t.bodyLarge),
                                          Text(
                                            k.nroCarton.toString().padLeft(
                                              4,
                                              '0',
                                            ),
                                            style: t.displaySmall?.copyWith(
                                              fontFamily: ttkFuenteNumeros,
                                              fontWeight: Peso.dato,
                                              fontFeatures: cifrasTabulares,
                                              color: cs.primary,
                                            ),
                                          ),
                                          Text(
                                            [
                                              ttkOGuion(k.origenTexto),
                                              if ((k.formaTexto ?? '')
                                                  .isNotEmpty)
                                                k.formaTexto!,
                                            ].join('\n'),
                                            style: t.bodyMedium?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: Esp.m),
                                          FilledButton.tonalIcon(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 52),
                                            ),
                                            onPressed:
                                                () => verCartonTtk(
                                                  context,
                                                  codCarton: k.codCarton!,
                                                  nroCarton: k.nroCarton,
                                                  encargado: false,
                                                  letras: b.letras,
                                                ),
                                            icon: const Icon(Icons.grid_view),
                                            label: const Text('Ver mi cartón'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La mesa de cartones de papel boca abajo: se elige uno por su número, sin
/// vista previa; al confirmarlo gira y revela sus números. No se cambia.
class _ElegirCarton extends ConsumerStatefulWidget {
  const _ElegirCarton({
    required this.bingo,
    required this.compacto,
    required this.alVolver,
    required this.alElegir,
  });

  final TtkBingoParticipanteEntity bingo;
  final bool compacto;
  final VoidCallback alVolver;
  final ValueChanged<TtkBingoCartonEntity> alElegir;

  @override
  ConsumerState<_ElegirCarton> createState() => _ElegirCartonState();
}

class _ElegirCartonState extends ConsumerState<_ElegirCarton> {
  final _buscador = TextEditingController();
  String _buscar = '';

  /// Solo se reparten las hojas del primer vistazo; las demás ya están en la mesa.
  bool _repartido = false;

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  FormaCartonTtk get _forma => FormaCartonTtk(
    filas: widget.bingo.filas,
    columnas: widget.bingo.columnas,
    letras: widget.bingo.letras,
    conComodin: widget.bingo.conComodin,
  );

  Future<void> _elegir(TtkBingoCartonEntity k) async {
    final repo = ref.read(ttkBingoRepositoryProvider);
    final elegido = await elegirCartonEnMesaTtk(
      context,
      nroCarton: k.nroCarton,
      forma: _forma,
      elegir: () => repo.elegirCarton(k.codCarton!),
      celdas: () => repo.verCarton(k.codCarton!),
    );
    if (!mounted) return;
    if (elegido) {
      widget.alElegir(k);
    } else {
      // Otro lo pudo haber tomado: se vuelve a pedir la lista de libres.
      ref.invalidate(ttkCartonesDisponiblesProvider(widget.bingo.codBingo!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final libres = ref.watch(
      ttkCartonesDisponiblesProvider(widget.bingo.codBingo!),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoTtk(
          ceja: widget.bingo.nombreEvento,
          titulo: 'Elige tu cartón',
          detalle:
              'Toca el cartón que quieres: sus números se revelan al elegirlo. Una vez elegido no se cambia.',
          compacto: widget.compacto,
          alVolver: widget.alVolver,
        ),
        const SizedBox(height: Esp.m),
        TextField(
          controller: _buscador,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _buscar = v.trim()),
          style: t.titleMedium,
          decoration: const InputDecoration(
            labelText: 'Buscar un número',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Esp.m),
        Expanded(
          child: libres.when(
            skipLoadingOnReload: true,
            loading: () => const EsqueletoListaTtk(),
            error:
                (e, _) => MensajeError(
                  error: e,
                  onReintentar:
                      () => ref.invalidate(
                        ttkCartonesDisponiblesProvider(widget.bingo.codBingo!),
                      ),
                ),
            data: (todos) {
              final lista = [
                for (final k in todos)
                  if (_buscar.isEmpty || '${k.nroCarton}'.contains(_buscar)) k,
              ];
              if (lista.isEmpty) {
                return const MensajeVacio(
                  icono: Icons.style_outlined,
                  titulo: 'No hay cartones con ese número',
                  detalle: 'Prueba con otro número o borra la búsqueda.',
                );
              }
              if (!_repartido) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _repartido = true,
                );
              }
              final hueco = widget.compacto ? Esp.m : Esp.l;
              return MesaTtk(
                child: Scrollbar(
                  child: GridView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(hueco, Esp.l, hueco, Esp.xl),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: widget.compacto ? 132 : 168,
                      childAspectRatio: ttkProporcionCarton,
                      crossAxisSpacing: hueco,
                      mainAxisSpacing: hueco,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final k = lista[i];
                      return RepartirTtk(
                        indice: i,
                        activo: !_repartido,
                        child: CartonPapelTtk(
                          key: ValueKey(k.codCarton),
                          nroCarton: k.nroCarton,
                          forma: _forma,
                          alTocar: () => _elegir(k),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
