/// El simulador de una jornada: con el empleado, la fecha y, si se quiere,
/// otra entrada y salida, muestra cómo se cruzan su horario, sus marcas, los
/// tramos y las comidas, cuánto se pagaría y qué revisar. No guarda nada.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_jornada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_segmento_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formulario_aprobador.dart'
    show CampoAgendaHex, personasDeAgendaHex;
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_tramos_reporte.dart';

/// Desde este ancho el formulario va en una fila y los avisos al lado.
const double hexAnchoSimuladorAncho = 1000;

/// Un segmento como tramo del reporte (D36), con su monto: así se dibuja con
/// la misma barra y la misma lista.
HexReporteTramoEntity tramoDeSegmentoHex(HexSimulacionSegmentoEntity s) =>
    HexReporteTramoEntity(
      orden: s.orden,
      desde: s.desde,
      hasta: s.hasta,
      horaDesde: s.horaDesde,
      horaHasta: s.horaHasta,
      minutos: s.minutos,
      duracionTexto: s.duracionTexto,
      clase: s.clase,
      codigo: s.codigo,
      leyenda: s.leyenda,
      textoPago: s.textoPago,
      monto: s.monto,
      resumen: s.resumen,
    );

/// El tono y el ícono de un aviso según su `nivel`.
({TonoHex tono, IconData icono}) visualAvisoHex(String nivel) =>
    switch (nivel) {
      'ERROR' => (tono: TonoHex.error, icono: Icons.error_outline),
      'AVISO' => (tono: TonoHex.pendiente, icono: Icons.warning_amber_rounded),
      _ => (tono: TonoHex.neutro, icono: Icons.info_outline),
    };

/// La pestaña «Simulador». Solo lectura: la ve quien ve la pantalla.
class SimuladorJornadaHex extends ConsumerStatefulWidget {
  const SimuladorJornadaHex({super.key});

  @override
  ConsumerState<SimuladorJornadaHex> createState() =>
      _SimuladorJornadaHexState();
}

class _SimuladorJornadaHexState extends ConsumerState<SimuladorJornadaHex> {
  BigInt? _empleado;
  DateTime? _fecha = DateUtils.dateOnly(DateTime.now());

  /// Nulas: las decide el SP; tras simular se llenan con las que usó.
  DateTime? _entrada;
  DateTime? _salida;

  /// Lo último que se pidió; nulo hasta el primer «Simular».
  FiltroSimulacionHex? _filtro;

  bool get _listo => _empleado != null && _fecha != null;

  void _simular() {
    final empleado = _empleado;
    final fecha = _fecha;
    if (empleado == null || fecha == null) return;
    HapticaHex.seleccion();
    final f = (
      codEmpleado: empleado,
      fechaJornada: fecha,
      inicio: _entrada,
      fin: _salida,
    );
    // El mismo pedido otra vez vuelve a preguntar (los tramos pudieron cambiar).
    if (f == _filtro) ref.invalidate(hexSimulacionProvider(f));
    setState(() => _filtro = f);
  }

  /// Otra persona u otra fecha: la entrada y la salida vuelven a decidirlas
  /// el SP.
  void _cambiarJornada(VoidCallback cambio) => setState(() {
    cambio();
    _entrada = null;
    _salida = null;
  });

  Future<DateTime?> _elegirMomento(DateTime? actual, String etiqueta) async {
    final base = actual ?? _fecha ?? DateUtils.dateOnly(DateTime.now());
    final dia = await pedirDiaHex(context, inicial: base, ayuda: etiqueta);
    if (dia == null || !mounted) return null;
    final hora = await pedirHoraHex(
      context,
      inicial:
          actual == null
              ? const TimeOfDay(hour: 18, minute: 0)
              : TimeOfDay.fromDateTime(actual),
      ayuda: etiqueta,
    );
    if (hora == null) return null;
    return DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
  }

  /// Tras la primera respuesta, la entrada y la salida que usó el SP quedan
  /// en el formulario para cambiarlas y volver a simular.
  void _escucharResultado(FiltroSimulacionHex f) {
    ref.listen(hexSimulacionProvider(f), (_, siguiente) {
      final j = siguiente.valueOrNull?.jornada;
      if (j == null || !mounted) return;
      if (_entrada != null || _salida != null) return;
      if (_empleado != f.codEmpleado || _fecha != f.fechaJornada) return;
      setState(() {
        _entrada = j.inicioUsado;
        _salida = j.finUsado;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtro = _filtro;
    if (filtro != null) _escucharResultado(filtro);
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth >= hexAnchoSimuladorAncho;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Prueba cómo se pagaría una jornada con los tramos, las comidas '
              'y los parámetros que rigen ese día. No guarda nada.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.l),
            _formulario(ancho),
            const SizedBox(height: Esp.xl),
            if (filtro == null)
              const SizedBox(
                height: hexAltoEstado,
                child: MensajeVacio(
                  icono: Icons.science_outlined,
                  titulo: 'Elige a alguien y una fecha',
                  detalle:
                      'Luego toca «Simular» para ver cómo se paga su jornada.',
                ),
              )
            else
              _resultado(filtro, ancho),
          ],
        );
      },
    );
  }

  Widget _formulario(bool ancho) {
    final campos = <Widget>[
      CampoAgendaHex<BigInt>(
        etiqueta: 'Empleado',
        valor: _empleado,
        opciones: personasDeAgendaHex,
        pista: 'Elige a alguien',
        alElegir: (v) => _cambiarJornada(() => _empleado = v),
      ),
      CampoSelectorHex(
        etiqueta: 'Fecha de la jornada',
        valor: _fecha == null ? null : fechaHex(_fecha),
        icono: Icons.event_outlined,
        alTocar: () async {
          final d = await pedirDiaHex(
            context,
            inicial: _fecha,
            ayuda: 'Fecha de la jornada',
          );
          if (d != null && mounted) _cambiarJornada(() => _fecha = d);
        },
      ),
      _CampoMomentoHex(
        etiqueta: 'Entrada',
        valor: _entrada,
        icono: Icons.login,
        alElegir: () async {
          final m = await _elegirMomento(_entrada, 'Entrada');
          if (m != null && mounted) setState(() => _entrada = m);
        },
        alQuitar: () => setState(() => _entrada = null),
      ),
      _CampoMomentoHex(
        etiqueta: 'Salida',
        valor: _salida,
        icono: Icons.logout,
        alElegir: () async {
          final m = await _elegirMomento(_salida, 'Salida');
          if (m != null && mounted) setState(() => _salida = m);
        },
        alQuitar: () => setState(() => _salida = null),
      ),
    ];
    final boton = FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size(120, 56)),
      onPressed: _listo ? _simular : null,
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Simular'),
    );
    const ayuda = Padding(
      padding: EdgeInsets.only(top: Esp.s),
      child: _AyudaMomentosHex(),
    );
    if (ancho) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, campo) in campos.indexed) ...[
                if (i > 0) const SizedBox(width: Esp.m),
                Expanded(flex: i == 0 ? 3 : 2, child: campo),
              ],
              const SizedBox(width: Esp.m),
              boton,
            ],
          ),
          ayuda,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final campo in campos) ...[campo, const SizedBox(height: Esp.m)],
        const _AyudaMomentosHex(),
        const SizedBox(height: Esp.m),
        boton,
      ],
    );
  }

  Widget _resultado(FiltroSimulacionHex f, bool ancho) {
    Widget enCaja(Widget hijo) => SizedBox(height: hexAltoEstado, child: hijo);
    return ref
        .watch(hexSimulacionProvider(f))
        .when(
          skipLoadingOnReload: true,
          loading: () => enCaja(const EsqueletoLista(filas: 4)),
          error:
              (e, _) => enCaja(
                vistaErrorHex(
                  e,
                  reintentar: () => ref.invalidate(hexSimulacionProvider(f)),
                ),
              ),
          data: (s) {
            final jornada = s.jornada;
            if (jornada == null) {
              return enCaja(
                const MensajeVacio(
                  icono: Icons.search_off,
                  titulo: 'No hay nada que simular',
                  detalle: 'El servidor no devolvió esa jornada.',
                ),
              );
            }
            return ResultadoSimulacionHex(s, jornada: jornada, ancho: ancho);
          },
        );
  }
}

/// «Vacía, la decide el sistema»: explica las entradas opcionales.
class _AyudaMomentosHex extends StatelessWidget {
  const _AyudaMomentosHex();

  @override
  Widget build(BuildContext context) => Text(
    'Deja la entrada y la salida vacías para que se usen las del biométrico, '
    'el reporte o el horario; luego puedes cambiarlas y volver a simular.',
    style: context.apagado(),
  );
}

/// Un día y una hora en un solo campo; con valor, la «x» lo vacía.
class _CampoMomentoHex extends StatelessWidget {
  const _CampoMomentoHex({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.alElegir,
    required this.alQuitar,
  });

  final String etiqueta;
  final DateTime? valor;
  final IconData icono;
  final VoidCallback alElegir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    final v = valor;
    return CampoSelectorHex(
      etiqueta: etiqueta,
      valor: v == null ? null : '${diaMesHex(v)} ${relojHex(v)}',
      pista: 'La decide el sistema',
      icono: icono,
      textoQuitar: 'Vaciar $etiqueta',
      alQuitar: alQuitar,
      alTocar: alElegir,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULTADO
// ═══════════════════════════════════════════════════════════════════════════

/// La jornada, los totales, la barra de tramos, la lista y los avisos. En el
/// ancho, la lista y los avisos van lado a lado; en el angosto, apilados.
class ResultadoSimulacionHex extends StatelessWidget {
  const ResultadoSimulacionHex(
    this.simulacion, {
    super.key,
    required this.jornada,
    required this.ancho,
  });

  final HexSimulacionEntity simulacion;
  final HexSimulacionJornadaEntity jornada;
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final tramos = [
      for (final s in simulacion.segmentos) tramoDeSegmentoHex(s),
    ];
    final avisos = [...simulacion.avisos]
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final tarjeta = _TarjetaJornadaHex(jornada);
    final totales = _TotalesHex(jornada);
    final barra = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccionHex(
          'Cómo se reparte la jornada',
          icono: Icons.view_timeline_outlined,
        ),
        const SizedBox(height: Esp.m),
        if (tramos.isEmpty)
          Text(
            'No hay tiempo que pagar en esta jornada.',
            style: context.apagado(),
          )
        else
          BarraTramosHex(tramos),
      ],
    );
    final lista =
        tramos.isEmpty ? const SizedBox.shrink() : ListaTramosHex(tramos);
    final revisar = _AvisosHex(avisos);
    const hueco = SizedBox(height: Esp.xl);
    if (ancho) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: tarjeta),
              const SizedBox(width: Esp.l),
              Expanded(flex: 2, child: totales),
            ],
          ),
          hueco,
          barra,
          const SizedBox(height: Esp.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: lista),
              const SizedBox(width: Esp.xl),
              Expanded(flex: 2, child: revisar),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tarjeta,
        const SizedBox(height: Esp.l),
        totales,
        hueco,
        revisar,
        hueco,
        barra,
        const SizedBox(height: Esp.l),
        lista,
      ],
    );
  }
}

/// Un recuadro de superficie del simulador.
class _CajaHex extends StatelessWidget {
  const _CajaHex({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: contornoSuperficie(cs),
      ),
      child: Padding(padding: const EdgeInsets.all(Esp.l), child: child),
    );
  }
}

/// Quién, qué día y de dónde salió cada dato, en palabras del SP.
class _TarjetaJornadaHex extends StatelessWidget {
  const _TarjetaJornadaHex(this.j);

  final HexSimulacionJornadaEntity j;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final apoyo = [
      j.cargo,
      j.nombreSucursal,
    ].where((p) => p.trim().isNotEmpty).join(' · ');
    final costo = switch ((j.haberBasico, j.divisor)) {
      (final h?, final d?) =>
        '${bsHex(j.costoHora)} (${bsHex(h)} ÷ ${decimalHex(d)})',
      _ => bsHex(j.costoHora),
    };
    final datos = <(IconData, String, String)>[
      (Icons.schedule, 'Horario', j.textoHorario),
      (Icons.fingerprint, 'Marcas', j.textoMarcas),
      (Icons.assignment_ind_outlined, 'Asignación', j.textoAsignacion),
      (Icons.description_outlined, 'Reporte', j.textoReporte),
      (Icons.login, 'Entrada y salida usadas', j.textoOrigen),
      (Icons.payments_outlined, 'Costo hora', costo),
    ];
    return _CajaHex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                oGuionHex(j.nombreEmpleado),
                style: t.titleMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              TipoDiaHex(j.tipoDia, j.textoTipoDia),
              if (j.fechaJornada != null)
                ChipHex(
                  texto: fechaHex(j.fechaJornada),
                  icono: Icons.event_outlined,
                  contorno: true,
                ),
            ],
          ),
          if (apoyo.isNotEmpty) ...[
            const SizedBox(height: Esp.xs),
            Text(apoyo, style: context.apagado()),
          ],
          const SizedBox(height: Esp.m),
          LayoutBuilder(
            builder: (context, c) {
              final columnas = c.maxWidth >= 560 ? 2 : 1;
              final w = (c.maxWidth - (columnas - 1) * Esp.l) / columnas;
              return Wrap(
                spacing: Esp.l,
                runSpacing: Esp.m,
                children: [
                  for (final (icono, rotulo, texto) in datos)
                    SizedBox(
                      width: w,
                      child: _DatoHex(
                        icono: icono,
                        rotulo: rotulo,
                        texto: texto,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DatoHex extends StatelessWidget {
  const _DatoHex({
    required this.icono,
    required this.rotulo,
    required this.texto,
  });

  final IconData icono;
  final String rotulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: cs.primary),
        const SizedBox(width: Esp.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: t.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(oGuionHex(texto), style: t.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// El total en grande y lo que va por horas y por comidas; el resumen del SP
/// debajo.
class _TotalesHex extends StatelessWidget {
  const _TotalesHex(this.j);

  final HexSimulacionJornadaEntity j;

  @override
  Widget build(BuildContext context) => _CajaHex(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CifrasHex(
          principal: (rotulo: 'Se pagaría', valor: bsHex(j.total)),
          cifras: [
            (rotulo: 'Por horas', valor: bsHex(j.totalHoras)),
            (rotulo: 'Por comidas', valor: bsHex(j.totalComidas)),
          ],
          compacto: true,
        ),
        if (textoUsableHex(j.resumen) case final resumen?) ...[
          const SizedBox(height: Esp.m),
          Text(resumen, style: context.apagado()),
        ],
      ],
    ),
  );
}

/// «Qué revisar»: cada aviso con su ícono y color por nivel, qué hacer y
/// quién lo arregla.
class _AvisosHex extends StatelessWidget {
  const _AvisosHex(this.avisos);

  final List<HexSimulacionAvisoEntity> avisos;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const TituloSeccionHex('Qué revisar', icono: Icons.fact_check_outlined),
      const SizedBox(height: Esp.m),
      if (avisos.isEmpty)
        Text('No hay nada que revisar.', style: context.apagado())
      else
        for (final (i, a) in avisos.indexed) ...[
          if (i > 0) const SizedBox(height: Esp.s),
          _AvisoSimulacionHex(a),
        ],
    ],
  );
}

class _AvisoSimulacionHex extends StatelessWidget {
  const _AvisoSimulacionHex(this.a);

  final HexSimulacionAvisoEntity a;

  @override
  Widget build(BuildContext context) {
    final v = visualAvisoHex(a.nivel);
    final par = coloresTonoHex(context, v.tono);
    final t = Theme.of(context).textTheme;
    final estilo = t.bodySmall?.copyWith(color: par.letra, fontSize: 13);
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Esp.m),
        decoration: BoxDecoration(
          color: par.fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(v.icono, size: 20, color: par.letra),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.texto,
                    style: t.bodyMedium?.copyWith(
                      color: par.letra,
                      fontWeight: Peso.titulo,
                    ),
                  ),
                  if (textoUsableHex(a.queHacer) case final que?) ...[
                    const SizedBox(height: Esp.xs),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Qué hacer: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: que),
                        ],
                      ),
                      style: estilo,
                    ),
                  ],
                  if (textoUsableHex(a.quien) case final quien?) ...[
                    const SizedBox(height: Esp.s),
                    ChipHex(
                      texto: quien,
                      icono: Icons.person_outline,
                      contorno: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
