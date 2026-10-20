/// En vivo (`tcpeExamenes/EnVivo`): cada evaluado de un lote en tiempo casi
/// real (conexión, pregunta actual, tiempo y salidas de la pestaña) y el
/// espejo de su pregunta. El panel deja de consultar si la pantalla no se ve.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/cronometro_examen.dart';
import 'package:bosque_flutter/core/utils/sondeo_periodico.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_lote_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/espejo_examen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

class EnVivoExamenScreen extends ConsumerStatefulWidget {
  const EnVivoExamenScreen({super.key, this.loteInicial});

  /// El lote con el que se abre (viene del detalle del lote).
  final BigInt? loteInicial;

  @override
  ConsumerState<EnVivoExamenScreen> createState() => _EnVivoExamenScreenState();
}

class _EnVivoExamenScreenState extends ConsumerState<EnVivoExamenScreen> with WidgetsBindingObserver {
  late BigInt? _lote = widget.loteInicial;
  late final SondeoPeriodico _sondeo = SondeoPeriodico(
    consultar: _consultar,
    intervalo: Duration(seconds: TcpeConfiguracion.respaldo.segundosRefrescoPanel),
  );
  Timer? _reloj;
  List<TcpeMonitorExamenEntity>? _filas;
  Object? _error;
  DateTime? _leido;
  bool _appVisible = true;
  bool _espejoAbierto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sondeo.iniciar();
    if (_lote != null) _sondeo.ahora();
    // La cuenta regresiva corre entre consultas; se detiene si no se ve.
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _sondeo.visible && _filas != null) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    _actualizarVisibilidad();
  }

  void _actualizarVisibilidad() => _sondeo.visible = _appVisible && !_espejoAbierto;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sondeo.detener();
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _consultar() async {
    final lote = _lote;
    if (lote == null) return;
    try {
      final filas = await ref.read(examenesRepositoryProvider).monitorExamenes(lote);
      if (!mounted || lote != _lote) return;
      setState(() {
        _filas = filas;
        _error = null;
        _leido = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _elegir(BigInt? lote) {
    setState(() {
      _lote = lote;
      _filas = null;
      _error = null;
    });
    _sondeo.ahora();
  }

  Future<void> _verEnVivo(TcpeMonitorExamenEntity e) async {
    _espejoAbierto = true;
    _actualizarVisibilidad();
    await abrirEspejo(context, codExamen: e.codExamen, nombre: _nombre(e));
    if (!mounted) return;
    _espejoAbierto = false;
    _actualizarVisibilidad();
  }

  /// Lo que queda contando desde la última consulta.
  int _quedan(TcpeMonitorExamenEntity e) {
    final pasados = _leido == null ? 0 : DateTime.now().difference(_leido!).inSeconds;
    return (e.segundosRestantes - pasados).clamp(0, 1 << 31);
  }

  static String _nombre(TcpeMonitorExamenEntity e) =>
      (e.nombreCompleto ?? '').trim().isNotEmpty ? e.nombreCompleto!.trim() : (e.login ?? 'Examen N° ${e.codExamen}');

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(configExamenesProvider(OrigenRendicion.empleado)).valueOrNull ?? TcpeConfiguracion.respaldo;
    _sondeo.intervalo = Duration(seconds: cfg.segundosRefrescoPanel);
    final lotes = ref.watch(tcpeMonitorLotesProvider);
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        final opciones = <(BigInt, String)>[
          for (final l in lotes.valueOrNull ?? const <TcpeMonitorLoteEntity>[])
            (l.codRolExamen, '${l.titulo ?? 'Lote'} · ${l.enCurso} en curso · ${l.sinIniciar} sin iniciar'),
        ];
        if (_lote != null && !opciones.any((o) => o.$1 == _lote)) opciones.insert(0, (_lote!, 'Lote N° $_lote'));
        return Scaffold(
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Exámenes · En vivo',
                  titulo: 'En vivo',
                  icono: Icons.sensors,
                  detalle:
                      'Cada evaluado en tiempo casi real: conexión, pregunta actual, tiempo y salidas de la '
                      'pestaña. Se actualiza cada ${cfg.segundosRefrescoPanel} s mientras miras esta pantalla.',
                  compacto: compacto,
                  acciones: [
                    if (_leido != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Esp.m),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_sondeo.visible) ...[const _Latido(), const SizedBox(width: Esp.s)],
                            Text(
                              'Actualizado ${_hora(_leido!)}',
                              style: context.apagado()?.copyWith(fontFamily: fuenteFija, fontFeatures: cifrasTabulares),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () {
                        ref.invalidate(tcpeMonitorLotesProvider);
                        _sondeo.ahora();
                      },
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                if (lotes.hasError)
                  MensajeError(error: lotes.error, compacto: true, onReintentar: () => ref.invalidate(tcpeMonitorLotesProvider))
                else
                  ComboFiltro<BigInt>(
                    etiqueta: 'Lote',
                    valor: _lote,
                    textoTodos: lotes.isLoading ? 'Cargando lotes…' : 'Elige un lote',
                    ancho: compacto ? double.infinity : 480,
                    opciones: opciones,
                    onCambio: _elegir,
                  ),
                const SizedBox(height: Esp.m),
                if (_filas != null && _filas!.isNotEmpty) ...[
                  _Resumen(filas: _filas!),
                  const SizedBox(height: Esp.m),
                ],
                if (_error != null) ...[
                  MensajeError(error: _error, compacto: true, onReintentar: _sondeo.ahora),
                  const SizedBox(height: Esp.m),
                ],
                Expanded(child: _cuerpo(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context) {
    if (_lote == null) {
      return const VacioExamenes(
        icono: Icons.sensors_outlined,
        titulo: 'Elige un lote',
        detalle: 'Aparecen los lotes con exámenes en curso o con la ventana abierta.',
      );
    }
    if (_filas == null) return _error == null ? const EsqueletoLista() : const SizedBox.shrink();
    return TablaExamenes<TcpeMonitorExamenEntity>(
      filas: _filas!,
      claveFila: (e) => e.codExamen,
      // La franja dice la conexión; quien ya terminó o no empezó, en gris.
      tonoFila:
          (e) => switch ((e.conexion ?? '').toUpperCase()) {
            'CONECTADO' => TonoExamen.principal,
            'INACTIVO' => TonoExamen.terciario,
            'DESCONECTADO' => TonoExamen.alerta,
            _ => TonoExamen.neutro,
          },
      alTocarFila: (e) {
        if (_enCurso(e)) _verEnVivo(e);
      },
      vacio: const VacioExamenes(
        icono: Icons.inbox_outlined,
        titulo: 'Este lote no tiene exámenes',
        detalle: 'Cuando haya evaluados, aparecen aquí.',
      ),
      columnas: [
        ColumnaExamen(
          'Evaluado',
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CeldaTexto(_nombre(e), fuerte: true),
              Text(e.login ?? '', style: context.apagado()?.copyWith(fontFamily: fuenteFija)),
            ],
          ),
          flex: 5,
        ),
        ColumnaExamen('Conexión', (e) => IndicadorConexion(e.conexion), flex: 3),
        ColumnaExamen('Estado', (e) => EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)), flex: 2),
        ColumnaExamen('Tiempo', (e) => _tiempo(context, e), flex: 2, alinear: Alignment.centerRight),
        ColumnaExamen('Pregunta', (e) => CeldaTexto(_pregunta(e)), flex: 2),
        ColumnaExamen('Resp.', (e) => CeldaNumero('${e.respondidas}/${e.totalPreguntas}'), flex: 2, alinear: Alignment.centerRight),
        ColumnaExamen('Salidas', (e) => _salidas(context, e), flex: 2, alinear: Alignment.centerRight),
      ],
      acciones: [
        AccionExamen('Ver en vivo', Icons.visibility_outlined, _verEnVivo, visible: _enCurso, tono: TonoExamen.terciario),
      ],
      tarjeta:
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_nombre(e), style: Theme.of(context).textTheme.titleSmall)),
                  EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)),
                ],
              ),
              const SizedBox(height: Esp.xs),
              Wrap(
                spacing: Esp.m,
                runSpacing: Esp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IndicadorConexion(e.conexion),
                  if (_enCurso(e)) _tiempo(context, e),
                  Text(_pregunta(e), style: context.apagado()),
                ],
              ),
              const SizedBox(height: Esp.xs),
              Text(
                '${e.respondidas} de ${e.totalPreguntas} respondidas · '
                '${e.salidasPestana} ${e.salidasPestana == 1 ? 'salida' : 'salidas'} de la pestaña',
                style: context.apagado(),
              ),
            ],
          ),
    );
  }

  static bool _enCurso(TcpeMonitorExamenEntity e) => EstadoExamenTcpe.desde(e.estado) == EstadoExamenTcpe.enCurso;

  static String _pregunta(TcpeMonitorExamenEntity e) =>
      e.ordenActual == null ? '--' : 'Pregunta ${e.ordenActual} de ${e.totalPreguntas}';

  Widget _tiempo(BuildContext context, TcpeMonitorExamenEntity e) {
    if (!_enCurso(e)) return Text('--', style: context.apagado());
    final s = _quedan(e);
    // El reloj en pastilla: secundario con tiempo, terciario en aviso, alerta al final.
    final tono =
        CronometroExamen.critico(s)
            ? TonoExamen.alerta
            : (CronometroExamen.enAviso(s) ? TonoExamen.terciario : TonoExamen.secundario);
    final c = coloresDeTono(Theme.of(context).colorScheme, tono);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 2),
      decoration: BoxDecoration(color: c.fondo, borderRadius: BorderRadius.circular(Esquina.pastilla)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: c.letra),
          const SizedBox(width: Esp.xs),
          Text(CronometroExamen.formato(s), style: context.numero(fuerte: true, color: c.letra)),
        ],
      ),
    );
  }

  Widget _salidas(BuildContext context, TcpeMonitorExamenEntity e) {
    final texto =
        e.salidasPestana > 0
            ? PastillaExamen(texto: '${e.salidasPestana}', tono: TonoExamen.terciario, icono: Icons.tab_unselected)
            : CeldaNumero('${e.salidasPestana}');
    if (e.ultimaSalida == null) return texto;
    return Tooltip(message: 'Última salida: ${fechaHora(e.ultimaSalida)}', child: texto);
  }

  static String _hora(DateTime f) =>
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}:${f.second.toString().padLeft(2, '0')}';
}

/// Cuántos hay conectados, inactivos, desconectados y entregados.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.filas});

  final List<TcpeMonitorExamenEntity> filas;

  @override
  Widget build(BuildContext context) {
    int contar(String c) => filas.where((e) => (e.conexion ?? '').toUpperCase() == c).length;
    final cerrados = filas.where((e) => EstadoExamenTcpe.desde(e.estado).cerrado).length;
    final sinIniciar = filas.where((e) => EstadoExamenTcpe.desde(e.estado) == EstadoExamenTcpe.sinIniciar).length;
    return TiraEstados(
      tramos: [
        TramoTira(contar('CONECTADO'), 'conectados', TonoTramo.hecho),
        TramoTira(contar('INACTIVO'), 'inactivos', TonoTramo.revisar),
        TramoTira(contar('DESCONECTADO'), 'desconectados', TonoTramo.alerta),
        TramoTira(cerrados, 'terminados', TonoTramo.enCurso),
        TramoTira(sinIniciar, 'sin iniciar', TonoTramo.pendiente),
      ],
    );
  }
}

/// El punto que late mientras el panel se actualiza solo; quieto si el
/// sistema pide menos movimiento.
class _Latido extends StatefulWidget {
  const _Latido();

  @override
  State<_Latido> createState() => _LatidoState();
}

class _LatidoState extends State<_Latido> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (duracionSuave(context) == Duration.zero) {
      _c
        ..stop()
        ..value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
    ),
  );
}
