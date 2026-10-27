import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_encargado.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';

/// `ttkBingo/Configuracion` (encargado): parámetros, figuras por juego, generación
/// de cartones, elección e inicio. El reparto, en `ttkBingo/Cartones`.
class TtkBingoConfiguracionScreen extends ConsumerWidget {
  const TtkBingoConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingos = ref.watch(ttkBingosProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final compacto = Aire.de(c.maxWidth).esChico;
          final relleno = compacto ? Esp.m : Esp.xl;
          return Padding(
            padding: EdgeInsets.fromLTRB(relleno, relleno, relleno, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoTtk(
                  ceja: 'Bingo',
                  titulo: 'Configuración del bingo',
                  detalle:
                      'En orden: ajusta los parámetros, dibuja la figura de cada juego, '
                      'genera los cartones, abre la elección e inicia el bingo.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(ttkBingosProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Expanded(
                  child: bingos.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoListaTtk(),
                    error:
                        (e, _) => MensajeError(
                          error: e,
                          onReintentar: () => ref.invalidate(ttkBingosProvider),
                        ),
                    data: (lista) {
                      final b = bingoElegidoTtk(ref, lista);
                      if (b == null) {
                        return const MensajeVacio(
                          icono: Icons.casino_outlined,
                          titulo: 'No hay bingos',
                          detalle:
                              'Crea un evento con bingo en la pantalla de eventos y vuelve aquí.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectorBingoTtk(bingos: lista),
                          ),
                          const SizedBox(height: Esp.s),
                          Expanded(
                            child: _Configuracion(
                              key: ValueKey(b.codBingo),
                              bingo: b,
                              compacto: compacto,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Configuracion extends StatelessWidget {
  const _Configuracion({
    super.key,
    required this.bingo,
    required this.compacto,
  });

  final TtkBingoEntity bingo;
  final bool compacto;

  // Los cartones (asignar, liberar, imprimir) tienen su propia pantalla: ttkBingo/Cartones.
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          isScrollable: compacto,
          tabAlignment: compacto ? TabAlignment.start : null,
          tabs: [
            const Tab(text: 'Resumen'),
            Tab(text: 'Juegos y figuras (${bingo.nroJuegos})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _TabResumen(bingo: bingo, compacto: compacto),
              _TabJuegos(bingo: bingo, compacto: compacto),
            ],
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMEN Y PARÁMETROS
// ═══════════════════════════════════════════════════════════════════════════

enum _Generar { nuevo, rehacer, completar }

/// Con cartones asignados el SP solo completa; sin ellos, genera todo de nuevo.
_Generar _modoGenerar(TtkBingoEntity b) =>
    b.cartonesAsignados > 0
        ? _Generar.completar
        : (b.cartonesGenerados > 0 ? _Generar.rehacer : _Generar.nuevo);

class _TabResumen extends ConsumerWidget {
  const _TabResumen({required this.bingo, required this.compacto});

  final TtkBingoEntity bingo;
  final bool compacto;

  Future<void> _correr(
    BuildContext context,
    WidgetRef ref, {
    required String titulo,
    required String detalle,
    required String boton,
    required Future<TtkRespuesta> Function() accion,
  }) async {
    final ok = await confirmar(
      context,
      titulo: titulo,
      detalle: detalle,
      textoConfirmar: boton,
    );
    if (!ok || !context.mounted) return;
    if (await ejecutarTtk(context, accion)) {
      refrescarBingoTtk(ref, bingo.codBingo!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = bingo;
    final repo = ref.read(ttkBingoRepositoryProvider);
    final estado = SeccionTtk(
      titulo: 'Estado',
      accion: Etiqueta(texto: b.estadoTexto, tono: ttkTonoEstado(b.estado)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasosBingo(estado: b.estado),
          if (b.mensajeEstado.isNotEmpty) ...[
            const SizedBox(height: Esp.m),
            NotaDelDato(
              icono: Icons.arrow_forward_rounded,
              texto: b.mensajeEstado,
            ),
          ],
          const SizedBox(height: Esp.l),
          Wrap(
            spacing: Esp.xl,
            runSpacing: Esp.m,
            children: [
              CifraTtk(
                valor: '${b.cartonesGenerados}',
                rotulo: 'Cartones generados',
              ),
              CifraTtk(valor: '${b.cartonesAsignados}', rotulo: 'Con dueño'),
              CifraTtk(valor: '${b.cartonesDisponibles}', rotulo: 'Sin dueño'),
              CifraTtk(
                valor: '${b.empleadosConCarton}',
                rotulo: 'Personas con cartón',
              ),
              if (b.porVales) ...[
                CifraTtk(valor: '${b.valesBingo}', rotulo: 'Vales de bingo'),
                if (b.cartonesFaltantes > 0)
                  CifraTtk(
                    valor: '${b.cartonesFaltantes}',
                    rotulo: 'Vales sin cartón',
                  ),
              ],
              CifraTtk(
                valor: '${b.juegosFinalizados}/${b.nroJuegos}',
                rotulo: 'Juegos jugados',
              ),
            ],
          ),
          if ((b.rangos ?? '').isNotEmpty) ...[
            const SizedBox(height: Esp.m),
            Text(
              'Qué números van en cada columna',
              style: context.tituloSeccion(),
            ),
            const SizedBox(height: Esp.xs),
            Text(b.rangos!, style: context.numero()),
          ],
          const SizedBox(height: Esp.l),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              if (b.puedeGenerar)
                PermissionWidget(
                  buttonName: BotonTtkBingo.generar,
                  child: FilledButton.icon(
                    onPressed:
                        () => _correr(
                          context,
                          ref,
                          titulo: switch (_modoGenerar(b)) {
                            _Generar.completar => 'Completar los cartones',
                            _Generar.rehacer => 'Volver a generar los cartones',
                            _Generar.nuevo => 'Generar los cartones',
                          },
                          detalle: switch (_modoGenerar(b)) {
                            _Generar.completar =>
                              'Se crean solo los cartones que faltan para los vales nuevos. Los que ya tienen dueño no cambian.',
                            _Generar.rehacer =>
                              'Se reemplazan los ${b.cartonesGenerados} cartones actuales. Si ya los imprimiste, los papeles dejan de valer.',
                            _Generar.nuevo =>
                              'Se generan los cartones de ${b.nroJuegos} juegos cada uno.',
                          },
                          boton: 'Generar',
                          accion: () => repo.generarCartones(b.codBingo!),
                        ),
                    icon: const Icon(Icons.auto_awesome_motion_outlined),
                    label: Text(switch (_modoGenerar(b)) {
                      _Generar.completar => 'Completar cartones',
                      _Generar.rehacer => 'Volver a generar',
                      _Generar.nuevo => 'Generar cartones',
                    }),
                  ),
                ),
              if (b.puedeAbrirEleccion)
                PermissionWidget(
                  buttonName: BotonTtkBingo.generar,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        () => _correr(
                          context,
                          ref,
                          titulo: 'Abrir la elección',
                          detalle:
                              'Los participantes podrán entrar a «Mi cartón» y elegir el suyo. '
                              'Tú también puedes asignar cartones a mano en «Bingo: cartones».',
                          boton: 'Abrir elección',
                          accion: () => repo.abrirEleccion(b.codBingo!),
                        ),
                    icon: const Icon(Icons.how_to_vote_outlined),
                    label: const Text('Abrir elección'),
                  ),
                ),
              if (b.puedeIniciar)
                PermissionWidget(
                  buttonName: BotonTtkBingo.generar,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        () => _correr(
                          context,
                          ref,
                          titulo: 'Iniciar el bingo',
                          detalle:
                              'Se cierra la elección: nadie más podrá elegir cartón. Juegan los '
                              '${b.cartonesAsignados} cartones que tienen dueño. Después, comienza '
                              'el primer juego desde el panel en vivo.',
                          boton: 'Iniciar',
                          accion: () => repo.iniciarBingo(b.codBingo!),
                        ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar bingo'),
                  ),
                ),
              if (b.puedeImprimir)
                PermissionWidget(
                  buttonName: BotonTtkBingo.imprimir,
                  child: OutlinedButton.icon(
                    onPressed: () => imprimirCartonesTtk(context, ref, b),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimir cartones'),
                  ),
                ),
              if (b.cartonesGenerados > 0)
                OutlinedButton.icon(
                  onPressed:
                      () => context.go(
                        '/dashboard/${AppConstants.rutaTtkBingoCartones}',
                      ),
                  icon: const Icon(Icons.style_outlined),
                  label: const Text('Ver cartones'),
                ),
              if (b.estado == 'EN_JUEGO')
                OutlinedButton.icon(
                  onPressed:
                      () => context.go(
                        '/dashboard/${AppConstants.rutaTtkBingoPanel}',
                      ),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Ir al panel en vivo'),
                ),
            ],
          ),
        ],
      ),
    );
    final parametros = SeccionTtk(
      titulo: 'Parámetros',
      child: _Parametros(bingo: b),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: Esp.m),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [estado, const SizedBox(height: Esp.m), parametros],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: estado),
                  const SizedBox(width: Esp.l),
                  Expanded(flex: 4, child: parametros),
                ],
              ),
    );
  }
}

class _Parametros extends ConsumerStatefulWidget {
  const _Parametros({required this.bingo});

  final TtkBingoEntity bingo;

  @override
  ConsumerState<_Parametros> createState() => _ParametrosState();
}

class _ParametrosState extends ConsumerState<_Parametros> {
  late final Map<String, TextEditingController> _c = {
    'bolillos': TextEditingController(),
    'filas': TextEditingController(),
    'columnas': TextEditingController(),
    'letras': TextEditingController(),
    'juegos': TextEditingController(),
    'cartones': TextEditingController(),
    'max': TextEditingController(),
    'ranking': TextEditingController(),
    'empate': TextEditingController(),
  };
  late bool _comodin;
  late String _modalidad;
  late bool _conAviso;
  BigInt? _tipo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant _Parametros viejo) {
    super.didUpdateWidget(viejo);
    final cambio =
        viejo.bingo.audFecha != widget.bingo.audFecha ||
        viejo.bingo.estado != widget.bingo.estado;
    if (cambio) _cargar();
  }

  void _cargar() {
    final b = widget.bingo;
    _c['bolillos']!.text = '${b.nroBolillos}';
    _c['filas']!.text = '${b.filas}';
    _c['columnas']!.text = '${b.columnas}';
    _c['letras']!.text = b.letras ?? '';
    _c['juegos']!.text = '${b.nroJuegos}';
    _c['cartones']!.text = '${b.nroCartones}';
    _c['max']!.text = '${b.maxCartonesEmpleado}';
    _c['ranking']!.text = '${b.tamRanking}';
    _c['empate']!.text = b.reglaEmpate ?? '';
    _comodin = b.conComodin;
    _modalidad = b.modalidad;
    _conAviso = b.conAviso;
    _tipo = b.codTipoTicket;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? _n(String k) => int.tryParse(_c[k]!.text.trim());

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final b = widget.bingo.copyWith(
      nroBolillos: _n('bolillos'),
      filas: _n('filas'),
      columnas: _n('columnas'),
      letras: _c['letras']!.text.trim().toUpperCase(),
      conComodin: _comodin,
      nroJuegos: _n('juegos'),
      // Con vale, la cantidad sale de los vales y el SP la ignora.
      nroCartones: _tipo == null ? _n('cartones') : null,
      codTipoTicket: _tipo,
      sinTipoTicket: _tipo == null,
      maxCartonesEmpleado: _n('max'),
      tamRanking: _n('ranking'),
      modalidad: _modalidad,
      conAviso: _conAviso,
      // Vacía la quita (el SP la guarda como NULL).
      reglaEmpate: _c['empate']!.text.trim(),
    );
    final ok = await ejecutarTtk(
      context,
      () => ref.read(ttkBingoRepositoryProvider).guardarBingo(b),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) refrescarBingoTtk(ref, widget.bingo.codBingo!);
  }

  /// Campo con su ayuda debajo: dice qué es y da un ejemplo.
  Widget _campo(
    String k,
    String rotulo,
    String ayuda, {
    bool habilitado = true,
    bool numerico = true,
  }) => SizedBox(
    width: 230,
    child: TextField(
      controller: _c[k],
      enabled: habilitado,
      keyboardType: numerico ? TextInputType.number : TextInputType.text,
      textCapitalization:
          numerico ? TextCapitalization.none : TextCapitalization.characters,
      inputFormatters:
          numerico
              ? [FilteringTextInputFormatter.digitsOnly]
              : [LengthLimitingTextInputFormatter(10)],
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontFamily: ttkFuenteNumeros,
        fontFeatures: cifrasTabulares,
      ),
      decoration: InputDecoration(
        labelText: rotulo,
        helperText: ayuda,
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  /// Un bloque del formulario con su título y para qué sirve.
  Widget _grupo(String titulo, String para, List<Widget> hijos) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(titulo, style: context.tituloSeccion()),
      const SizedBox(height: Esp.xs),
      Text(para, style: context.apagado()),
      const SizedBox(height: Esp.m),
      ...hijos,
    ],
  );

  /// Los tipos de vale del evento más «sin vale». Si la lista no llega, queda
  /// al menos el vale enlazado: el combo nunca pierde su valor actual.
  Widget _selectorVale(TtkBingoEntity b, {required bool habilitado}) {
    final tipos = ref.watch(ttkTiposProvider(b.codEvento!)).valueOrNull ?? [];
    final opciones = <BigInt?, String>{null: 'Sin vale (cartones manuales)'};
    for (final t in tipos) {
      if (t.codTipoTicket != null) opciones[t.codTipoTicket] = t.nombre;
    }
    if (b.codTipoTicket != null) {
      opciones.putIfAbsent(
        b.codTipoTicket,
        () => ttkOGuion(b.nombreTipoTicket),
      );
    }
    final valor = opciones.containsKey(_tipo) ? _tipo : null;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DropdownButtonFormField<BigInt?>(
          value: valor,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Vale que da cartón',
            helperText:
                'Cada vale de este tipo que tenga una persona le da un cartón. '
                'Con «Sin vale», tú decides cuántos cartones se generan.',
            helperMaxLines: 3,
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final e in opciones.entries)
              DropdownMenuItem<BigInt?>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: habilitado ? (v) => setState(() => _tipo = v) : null,
        ),
      ),
    );
  }

  /// En pantalla, impreso o ambos. Impreso o no, todos pueden seguir y marcar
  /// su cartón en la pantalla; la forma decide qué imprime el encargado.
  Widget _formaDeJuego({required bool habilitado}) {
    const opciones = [
      ('P', 'En pantalla', Icons.smartphone_outlined),
      ('I', 'Impreso', Icons.print_outlined),
      ('A', 'Ambos', Icons.devices_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [
            for (final (valor, rotulo, icono) in opciones)
              ChoiceChip(
                avatar: Icon(icono, size: 18),
                showCheckmark: false,
                label: Text(rotulo),
                selected: _modalidad == valor,
                onSelected:
                    habilitado
                        ? (_) => setState(() => _modalidad = valor)
                        : null,
              ),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text(switch (_modalidad) {
          'P' =>
            'Nadie recibe papel: cada persona juega y marca su cartón en su celular o computadora.',
          'I' =>
            'Todos reciben su cartón impreso. Si quieren, también pueden marcarlo en la pantalla.',
          _ =>
            'Tú eliges cuáles cartones se entregan en papel: en «Bingo: cartones», «Pasar a impreso». '
                'Los demás se juegan en la pantalla.',
        }, style: context.apagado()),
      ],
    );
  }

  /// Con vale enlazado la cantidad de cartones es de solo lectura.
  Widget _cartonesPorVales(TtkBingoEntity b) => SizedBox(
    width: 230,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Cartones a generar',
        helperText:
            _tipo == b.codTipoTicket
                ? 'Uno por vale (${b.valesBingo} vales repartidos)'
                : 'Se calcula al guardar: uno por vale',
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        isDense: true,
        enabled: false,
      ),
      child: Text(
        _tipo == b.codTipoTicket ? '${b.cartonesObjetivo}' : '—',
        style: const TextStyle(
          fontFamily: ttkFuenteNumeros,
          fontFeatures: cifrasTabulares,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final b = widget.bingo;
    final matriz = b.puedeConfigurar;
    final enJuego = b.estado == 'EN_JUEGO';
    final editable = matriz || enJuego;
    const separacion = SizedBox(height: Esp.xl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!editable)
          const NotaDelDato(
            texto: 'El bingo terminó: los parámetros quedan como se jugaron.',
          )
        else if (!matriz)
          const NotaDelDato(
            tono: TonoNota.info,
            texto:
                'Con el bingo en juego ya no cambian el cartón ni el reparto. '
                'Sí puedes ajustar cómo se juega, el desempate, el máximo por persona y el ranking.',
          ),
        if (!matriz) const SizedBox(height: Esp.l),
        _grupo(
          'El cartón',
          'Cada cartón trae varios juegos, y cada juego es una cuadrícula de números.',
          [
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              children: [
                _campo(
                  'bolillos',
                  'Bolillos de la máquina',
                  'Los números van del 1 hasta este (por ejemplo, 75).',
                  habilitado: matriz,
                ),
                _campo(
                  'juegos',
                  'Juegos por cartón',
                  'Rondas que se juegan; cada una tiene su propia figura.',
                  habilitado: matriz,
                ),
                _campo(
                  'filas',
                  'Filas de cada juego',
                  'Casillas de arriba hacia abajo (por ejemplo, 5).',
                  habilitado: matriz,
                ),
                _campo(
                  'columnas',
                  'Columnas de cada juego',
                  'Casillas de izquierda a derecha (por ejemplo, 5).',
                  habilitado: matriz,
                ),
                _campo(
                  'letras',
                  'Letras del encabezado',
                  'Una letra arriba de cada columna, en orden: con 5 columnas, '
                      'BINGO. Déjalo vacío si no quieres letras.',
                  habilitado: matriz,
                  numerico: false,
                ),
              ],
            ),
            const SizedBox(height: Esp.m),
            _VistaEncabezado(letras: _c['letras']!, columnas: _c['columnas']!),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Casilla del centro libre (comodín)'),
              subtitle: const Text(
                'Cuenta como marcada desde el inicio. Pide filas y columnas impares, como 5 × 5.',
              ),
              value: _comodin,
              onChanged: matriz ? (v) => setState(() => _comodin = v) : null,
            ),
          ],
        ),
        separacion,
        _grupo(
          'Quién recibe cartón',
          'De dónde salen los cartones y cuántos puede tener cada persona.',
          [
            _selectorVale(b, habilitado: matriz),
            const SizedBox(height: Esp.m),
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              children: [
                if (_tipo == null)
                  _campo(
                    'cartones',
                    'Cartones a generar',
                    'Total de cartones del bingo.',
                    habilitado: matriz,
                  )
                else
                  _cartonesPorVales(b),
                _campo(
                  'max',
                  'Máximo por persona',
                  'Cuántos cartones puede tener cada participante.',
                  habilitado: editable,
                ),
              ],
            ),
          ],
        ),
        separacion,
        _grupo(
          'Cómo se juega',
          'En papel, en la pantalla o mezclado, si pueden avisarte a distancia y qué pasa si hay empate.',
          [
            _formaDeJuego(habilitado: editable),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Botón «¡Bingo!» para avisar al encargado'),
              subtitle: const Text(
                'Para jugar a distancia: el participante toca «¡Bingo!» y te llega '
                'el aviso en el panel. Nunca le dice si ganó.',
              ),
              value: _conAviso,
              onChanged: editable ? (v) => setState(() => _conAviso = v) : null,
            ),
            const SizedBox(height: Esp.m),
            TextField(
              controller: _c['empate'],
              enabled: editable,
              minLines: 2,
              maxLines: 4,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Si hay empate',
                hintText:
                    'Por ejemplo: se resolverá tirando un dado; gana el número mayor.',
                helperText:
                    'Qué pasa si dos o más cartones completan la figura a la vez. '
                    'Se muestra en la pantalla en vivo y en «Mi cartón».',
                helperMaxLines: 3,
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        separacion,
        _grupo('Panel del encargado', 'Lo que ves mientras se juega.', [
          Align(
            alignment: Alignment.centerLeft,
            child: _campo(
              'ranking',
              'Cartones en el ranking',
              'Cuántos de los cartones más cerca de ganar ves en el panel.',
              habilitado: editable,
            ),
          ),
        ]),
        const SizedBox(height: Esp.l),
        if (editable)
          Align(
            alignment: Alignment.centerRight,
            child: PermissionWidget(
              buttonName: BotonTtkBingo.configurar,
              child: BotonAccion(
                etiqueta: 'Guardar parámetros',
                etiquetaOcupado: 'Guardando…',
                icono: Icons.save_outlined,
                ocupado: _guardando,
                onPressed: _guardar,
              ),
            ),
          ),
      ],
    );
  }
}

/// Muestra, mientras se escribe, qué letra queda arriba de cada columna: así
/// se entiende que «BINGO» es una letra por columna. Si falta una, sale «?».
class _VistaEncabezado extends StatelessWidget {
  const _VistaEncabezado({required this.letras, required this.columnas});

  final TextEditingController letras;
  final TextEditingController columnas;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([letras, columnas]),
    builder: (context, _) {
      final n = (int.tryParse(columnas.text.trim()) ?? 0).clamp(0, 9);
      final l = letras.text.trim().toUpperCase();
      if (n == 0) return const SizedBox.shrink();
      final cs = Theme.of(context).colorScheme;
      Widget caja(String letra, String pie, Color fondo, Color tinta) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(Esquina.chica),
            ),
            child: Text(
              letra,
              style: TextStyle(
                color: tinta,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(pie, style: context.apagado()?.copyWith(fontSize: 11)),
        ],
      );
      return Semantics(
        label:
            l.isEmpty
                ? 'Encabezado sin letras'
                : 'Encabezado: ${[for (var i = 0; i < n && i < l.length; i++) l[i]].join(' ')}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.isEmpty
                  ? 'Encabezado del cartón: sin letras, solo números.'
                  : 'Así queda el encabezado del cartón:',
              style: context.apagado(),
            ),
            if (l.isNotEmpty) ...[
              const SizedBox(height: Esp.xs),
              Wrap(
                spacing: Esp.xs,
                runSpacing: Esp.xs,
                children: [
                  for (var i = 0; i < n; i++)
                    i < l.length
                        ? caja(
                          l[i],
                          'Col. ${i + 1}',
                          cs.primaryContainer,
                          cs.onPrimaryContainer,
                        )
                        : caja(
                          '?',
                          'Col. ${i + 1}',
                          cs.surfaceContainerHighest,
                          cs.onSurfaceVariant,
                        ),
                  for (var i = n; i < l.length; i++)
                    caja(
                      l[i],
                      'Sin columna',
                      cs.errorContainer,
                      cs.onErrorContainer,
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Los cinco pasos del bingo con el actual resaltado, para que el encargado
/// sepa dónde está; qué hacer ahora lo dice el mensaje del SP debajo.
class _PasosBingo extends StatelessWidget {
  const _PasosBingo({required this.estado});

  final String? estado;

  static const _pasos = [
    ('CONFIGURACION', 'Parámetros y figuras'),
    ('GENERADO', 'Cartones generados'),
    ('ELECCION', 'Elección de cartones'),
    ('EN_JUEGO', 'En juego'),
    ('FINALIZADO', 'Finalizado'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actual = _pasos.indexWhere((p) => p.$1 == estado);
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (var i = 0; i < _pasos.length; i++)
          Builder(
            builder: (context) {
              final hecho = i < actual || estado == 'FINALIZADO';
              final ahora = i == actual && !hecho;
              final tinta =
                  ahora
                      ? cs.onPrimary
                      : (hecho ? cs.onSecondaryContainer : cs.onSurfaceVariant);
              return Semantics(
                label:
                    'Paso ${i + 1}: ${_pasos[i].$2}'
                    '${hecho ? ', hecho' : (ahora ? ', actual' : '')}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Esp.s,
                    vertical: Esp.xs,
                  ),
                  decoration: BoxDecoration(
                    color:
                        ahora
                            ? cs.primary
                            : (hecho
                                ? cs.secondaryContainer
                                : cs.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hecho
                            ? Icons.check_circle
                            : (ahora
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                        size: 16,
                        color: tinta,
                      ),
                      const SizedBox(width: Esp.xs),
                      Text(
                        '${i + 1}. ${_pasos[i].$2}',
                        style: TextStyle(
                          color: tinta,
                          fontWeight: ahora ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// JUEGOS Y FIGURAS
// ═══════════════════════════════════════════════════════════════════════════

class _TabJuegos extends ConsumerWidget {
  const _TabJuegos({required this.bingo, required this.compacto});

  final TtkBingoEntity bingo;
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juegos = ref.watch(ttkJuegosProvider(bingo.codBingo!));
    final cs = Theme.of(context).colorScheme;
    return juegos.when(
      skipLoadingOnReload: true,
      loading: () => const EsqueletoListaTtk(),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar:
                () => ref.invalidate(ttkJuegosProvider(bingo.codBingo!)),
          ),
      data:
          (lista) =>
              lista.isEmpty
                  ? const MensajeVacio(
                    icono: Icons.grid_on,
                    titulo: 'Sin juegos',
                    detalle:
                        'Guarda los parámetros para crear los juegos del bingo.',
                  )
                  : LayoutBuilder(
                    builder: (context, c) {
                      final porFila =
                          c.maxWidth >= 1100
                              ? 4
                              : (c.maxWidth >= 760
                                  ? 3
                                  : (c.maxWidth >= 480 ? 2 : 1));
                      final ancho =
                          (c.maxWidth - (porFila - 1) * Esp.m) / porFila;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: Esp.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const NotaDelDato(
                              texto:
                                  'La figura es lo que hay que completar para ganar ese juego '
                                  '(por ejemplo, una L o el cartón lleno). Toca «Editar figura y premio», '
                                  'marca sus casillas y, si quieres, anota el premio: en la pantalla en vivo '
                                  'se lee «Se está jugando por …». El premio se puede cambiar hasta que el juego termine.',
                            ),
                            const SizedBox(height: Esp.m),
                            Wrap(
                              spacing: Esp.m,
                              runSpacing: Esp.m,
                              children: [
                                for (final j in lista)
                                  SizedBox(
                                    width: ancho,
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      elevation: 0,
                                      color:
                                          j.enCurso
                                              ? cs.primaryContainer
                                              : cs.surfaceContainerLow,
                                      shape: contornoSuperficie(
                                        cs,
                                        color: j.enCurso ? cs.primary : null,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(Esp.l),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Juego ${j.nroJuego}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        fontWeight: Peso.titulo,
                                                        color: cs.primary,
                                                      ),
                                                ),
                                                const Spacer(),
                                                Etiqueta(
                                                  texto: j.estadoTexto,
                                                  tono: ttkTonoEstado(j.estado),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: Esp.xs),
                                            Text(
                                              j.nombre,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: context.tituloSeccion(),
                                            ),
                                            const SizedBox(height: Esp.xs),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.redeem_outlined,
                                                  size: 16,
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: Esp.xs),
                                                Expanded(
                                                  child: Text(
                                                    (j.premio ?? '').isEmpty
                                                        ? 'Sin premio anotado'
                                                        : j.premio!,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        (j.premio ?? '').isEmpty
                                                            ? context.apagado()
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: Esp.m),
                                            Center(
                                              child: FiguraTtk(
                                                figura: j.figura,
                                                filas: j.filas,
                                                columnas: j.columnas,
                                                conComodin: j.conComodin,
                                                celda: 18,
                                              ),
                                            ),
                                            const SizedBox(height: Esp.m),
                                            Text(
                                              '${j.casillasFigura} casillas · ${j.bolillosMarcados} bolillos',
                                              style: context.apagado(),
                                            ),
                                            if (j.puedeEditarFigura ||
                                                j.puedeEditarPremio) ...[
                                              const SizedBox(height: Esp.s),
                                              PermissionWidget(
                                                buttonName:
                                                    BotonTtkBingo.configurar,
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton.icon(
                                                    onPressed:
                                                        () => editarFiguraTtk(
                                                          context,
                                                          ref,
                                                          bingo: bingo,
                                                          juego: j,
                                                        ),
                                                    icon: Icon(
                                                      j.puedeEditarFigura
                                                          ? Icons.edit_outlined
                                                          : Icons
                                                              .redeem_outlined,
                                                      size: 18,
                                                    ),
                                                    label: Text(
                                                      j.puedeEditarFigura
                                                          ? 'Editar figura y premio'
                                                          : 'Cambiar premio',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
    );
  }
}
