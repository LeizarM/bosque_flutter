/// El espejo de un examen en curso: la pregunta que el evaluado tiene delante,
/// con lo que marcó y las válidas resaltadas, actualizada cada pocos segundos.
/// No es video de la pantalla: son los datos de `p_list_tcpe_Monitor` E.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/cronometro_examen.dart';
import 'package:bosque_flutter/core/utils/sondeo_periodico.dart';
import 'package:bosque_flutter/domain/entities/tcpe_espejo_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/resultado_examen.dart';

/// Cada cuánto se actualiza el espejo.
const Duration kRefrescoEspejo = Duration(seconds: 3);

Future<void> abrirEspejo(BuildContext context, {required BigInt codExamen, String? nombre}) =>
    mostrarFormulario<void>(
      context,
      (completa) => EspejoExamen(codExamen: codExamen, nombre: nombre, completa: completa),
    );

/// El indicador de conexión del panel: pastilla con icono en el color del estado.
class IndicadorConexion extends StatelessWidget {
  const IndicadorConexion(this.conexion, {super.key});

  final String? conexion;

  @override
  Widget build(BuildContext context) {
    final (tono, icono, texto) = switch ((conexion ?? '').trim().toUpperCase()) {
      'CONECTADO' => (TonoExamen.principal, Icons.wifi, 'Conectado'),
      'INACTIVO' => (TonoExamen.terciario, Icons.snooze, 'Inactivo'),
      'DESCONECTADO' => (TonoExamen.alerta, Icons.wifi_off, 'Desconectado'),
      _ => (null, null, '--'),
    };
    return Semantics(
      label: 'Conexión: $texto',
      child:
          tono == null
              ? Text(texto, style: context.apagado())
              : PastillaExamen(texto: texto, tono: tono, icono: icono),
    );
  }
}

class EspejoExamen extends ConsumerStatefulWidget {
  const EspejoExamen({super.key, required this.codExamen, required this.completa, this.nombre});

  final BigInt codExamen;
  final bool completa;
  final String? nombre;

  @override
  ConsumerState<EspejoExamen> createState() => _EspejoExamenState();
}

class _EspejoExamenState extends ConsumerState<EspejoExamen> with WidgetsBindingObserver {
  late final SondeoPeriodico _sondeo = SondeoPeriodico(consultar: _consultar, intervalo: kRefrescoEspejo);
  List<TcpeEspejoItemEntity>? _filas;
  Object? _error;
  DateTime? _leido;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sondeo
      ..iniciar()
      ..ahora();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sondeo.visible = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sondeo.detener();
    super.dispose();
  }

  Future<void> _consultar() async {
    try {
      final filas = await ref.read(examenesRepositoryProvider).espejo(widget.codExamen);
      if (!mounted) return;
      setState(() {
        _filas = filas;
        _error = null;
        _leido = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo: 'En vivo · ${widget.nombre ?? 'Examen N° ${widget.codExamen}'}',
    icono: Icons.sensors,
    completa: widget.completa,
    ancho: 820,
    cuerpo: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) MensajeError(error: _error, compacto: true, onReintentar: _sondeo.ahora),
        if (_filas == null && _error == null)
          const SizedBox(height: 280, child: EsqueletoLista(filas: 4, altoFila: 52))
        else if (_filas != null)
          VistaEspejo(filas: _filas!, leido: _leido),
      ],
    ),
    acciones: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
  );
}

/// Lo que se ve del evaluado: cabecera con su estado y la pregunta actual en
/// solo lectura. [leido] es cuándo llegaron los datos (para el reloj).
class VistaEspejo extends StatelessWidget {
  const VistaEspejo({super.key, required this.filas, this.leido});

  final List<TcpeEspejoItemEntity> filas;
  final DateTime? leido;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return const NotaDelDato(texto: 'Este examen no está en curso: no hay nada que mostrar en vivo.');
    }
    final f = filas.first;
    final pregunta = TcpeEspejoItemEntity.preguntaActualDe(filas);
    final enCurso = EstadoExamenTcpe.desde(f.estado) == EstadoExamenTcpe.enCurso;
    final pasados = leido == null ? 0 : DateTime.now().difference(leido!).inSeconds;
    final quedan = (f.segundosRestantes - pasados).clamp(0, 1 << 31);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Esp.l,
          runSpacing: Esp.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IndicadorConexion(f.conexion),
            EtiquetaEstadoExamen(EstadoExamenTcpe.desde(f.estado)),
            if (enCurso) Text('Quedan ${CronometroExamen.formato(quedan)}', style: context.numero(fuerte: true)),
            Text(
              f.ordenActual == null ? 'Sin pregunta abierta' : 'Pregunta ${f.ordenActual} de ${f.totalPreguntas}',
              style: context.numero(),
            ),
            Text('${f.respondidas} de ${f.totalPreguntas} respondidas', style: context.apagado()),
          ],
        ),
        const SizedBox(height: Esp.m),
        TiraEstados(
          leyenda: false,
          alto: 6,
          tramos: [
            TramoTira(f.respondidas, 'respondidas', TonoTramo.hecho),
            TramoTira((f.totalPreguntas - f.respondidas).clamp(0, f.totalPreguntas), 'sin responder', TonoTramo.pendiente),
          ],
        ),
        const SizedBox(height: Esp.l),
        if (pregunta == null)
          const NotaDelDato(texto: 'Todavía no abrió ninguna pregunta.')
        else
          Container(
            padding: const EdgeInsets.all(Esp.l),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            child: CuerpoPreguntaDevuelta(pregunta: pregunta, columnas: 2, paraEvaluador: true),
          ),
      ],
    );
  }
}
