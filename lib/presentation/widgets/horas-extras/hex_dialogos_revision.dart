/// Diálogos de revisión de un reporte: corregir la hora de inicio o de fin,
/// dar el visto bueno, aprobar y rechazar. Los usan el encargado y el jefe de
/// área (también como reemplazo); las reglas y los mensajes son del SP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// Corrige el inicio, el fin o los dos; viaja solo el extremo cambiado. La
/// hora corregida reemplaza la del biométrico o la de la app.
Future<void> corregirHoraHex(
  BuildContext context,
  WidgetRef ref,
  HexReporteEntity r, {
  required VoidCallback refrescar,
}) => _abrirRevisionHex(
  context,
  ref,
  r,
  refrescar,
  (datos) => _CorregirHoraHex(datos: datos),
);

/// Visto bueno con el resumen de inicio y fin y su origen; la observación
/// es opcional.
Future<void> vistoBuenoHex(
  BuildContext context,
  WidgetRef ref,
  HexReporteEntity r, {
  required VoidCallback refrescar,
}) => _abrirRevisionHex(
  context,
  ref,
  r,
  refrescar,
  (datos) => _FirmaReporteHex(datos: datos, tipo: _TipoFirmaHex.vistoBueno),
);

/// Aprobación del jefe de área: el mismo resumen que el visto bueno y la
/// observación opcional.
Future<void> aprobarHex(
  BuildContext context,
  WidgetRef ref,
  HexReporteEntity r, {
  required VoidCallback refrescar,
}) => _abrirRevisionHex(
  context,
  ref,
  r,
  refrescar,
  (datos) => _FirmaReporteHex(datos: datos, tipo: _TipoFirmaHex.aprobacion),
);

/// Rechazo con su observación. [comoJefe] usa el endpoint de Aprobación de
/// área; si no, el de Revisión de encargado.
Future<void> rechazarHex(
  BuildContext context,
  WidgetRef ref,
  HexReporteEntity r, {
  required bool comoJefe,
  required VoidCallback refrescar,
}) => _abrirRevisionHex(
  context,
  ref,
  r,
  refrescar,
  (datos) => _RechazarHex(datos: datos, comoJefe: comoJefe),
);

/// Lo que recibe cada diálogo: el reporte, su id, el repositorio de la
/// pantalla y cómo recargar su lista.
typedef _DatosRevisionHex =
    ({
      BigInt id,
      HexReporteEntity reporte,
      HexReporteRepository repo,
      VoidCallback refrescar,
    });

/// Abre un diálogo con el repositorio de la pantalla; la recarga solo corre
/// si la pantalla sigue montada ([abrirDialogoHex]).
Future<void> _abrirRevisionHex(
  BuildContext context,
  WidgetRef ref,
  HexReporteEntity r,
  VoidCallback refrescar,
  Widget Function(_DatosRevisionHex datos) dialogo,
) async {
  final id = r.idReporte;
  if (id == null) return;
  final repo = ref.read(hexReporteRepositoryProvider);
  await abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) =>
            dialogo((id: id, reporte: r, repo: repo, refrescar: recargar)),
  );
}

/// Base de los tres diálogos: la escritura del kit con la recarga de la
/// pantalla que los abrió.
abstract class _DialogoRevisionHex extends StatefulWidget {
  const _DialogoRevisionHex({required this.datos});

  final _DatosRevisionHex datos;
}

abstract class _DialogoRevisionHexState<W extends _DialogoRevisionHex>
    extends State<W>
    with EscrituraEnDialogoHex<W> {
  @override
  VoidCallback get refrescarLista => widget.datos.refrescar;

  HexReporteEntity get reporte => widget.datos.reporte;
}

/// Un texto escrito o nulo si quedó vacío.
String? _oNulo(String texto) {
  final limpio = texto.trim();
  return limpio.isEmpty ? null : limpio;
}

/// Quién y qué jornada: «Mamani Quispe Juan Carlos» y «Jornada 23/10/2026 ·
/// Después del horario · Planta El Alto».
class _ResumenHex extends StatelessWidget {
  const _ResumenHex(this.reporte);

  final HexReporteEntity reporte;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    final jornada = [
      'Jornada ${fechaHex(r.fechaJornada)}',
      r.tipoTexto,
      r.nombreSucursal ?? '',
    ].where((p) => p.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(oGuionHex(r.nombreEmpleado), style: context.tituloSeccion()),
        const SizedBox(height: 2),
        Text(jornada, style: context.apagado()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CORREGIR HORA
// ═══════════════════════════════════════════════════════════════════════════

/// Un extremo (inicio o fin) mientras se corrige: el día y la hora elegidos,
/// inmutable. Parte de la hora registrada; corregida es la que difiere.
@immutable
class _ExtremoHex {
  const _ExtremoHex._(this.registrada, this.jornada, this.dia, this.hora);

  factory _ExtremoHex.registrado(DateTime? registrada, DateTime? jornada) =>
      _ExtremoHex._(
        registrada,
        jornada,
        DateUtils.dateOnly(registrada ?? jornada ?? DateTime.now()),
        registrada == null ? null : TimeOfDay.fromDateTime(registrada),
      );

  final DateTime? registrada;
  final DateTime? jornada;
  final DateTime dia;
  final TimeOfDay? hora;

  _ExtremoHex conDia(DateTime d) => _ExtremoHex._(registrada, jornada, d, hora);

  _ExtremoHex conHora(TimeOfDay h) =>
      _ExtremoHex._(registrada, jornada, dia, h);

  _ExtremoHex deshecho() => _ExtremoHex.registrado(registrada, jornada);

  DateTime? get valor {
    final h = hora;
    return h == null
        ? null
        : DateTime(dia.year, dia.month, dia.day, h.hour, h.minute);
  }

  /// Lo que viaja: nulo si no tiene hora o si es la misma registrada.
  DateTime? get corregida {
    final v = valor;
    final r = registrada;
    final igual =
        v != null &&
        r != null &&
        DateUtils.isSameDay(v, r) &&
        v.hour == r.hour &&
        v.minute == r.minute;
    return igual ? null : v;
  }
}

/// «Día siguiente a la jornada» cuando la hora cae en otro día: una salida
/// pasada la medianoche no se confunde con una del mismo día.
String? _otroDiaTexto(DateTime? hora, DateTime? jornada) {
  if (hora == null || jornada == null || !otroDiaHex(hora, jornada)) {
    return null;
  }
  final dias =
      DateTime.utc(hora.year, hora.month, hora.day)
          .difference(DateTime.utc(jornada.year, jornada.month, jornada.day))
          .inDays;
  return switch (dias) {
    1 => 'Día siguiente a la jornada',
    -1 => 'Día anterior a la jornada',
    _ => 'Otro día que la jornada',
  };
}

/// El extremo que se corrige, con su rótulo.
enum _LadoHex {
  inicio('Inicio'),
  fin('Fin');

  const _LadoHex(this.etiqueta);

  final String etiqueta;
}

class _CorregirHoraHex extends _DialogoRevisionHex {
  const _CorregirHoraHex({required super.datos});

  @override
  State<_CorregirHoraHex> createState() => _CorregirHoraHexState();
}

class _CorregirHoraHexState extends _DialogoRevisionHexState<_CorregirHoraHex> {
  final TextEditingController _observacion = TextEditingController();
  late _ExtremoHex _inicio = _ExtremoHex.registrado(
    reporte.inicio,
    reporte.fechaJornada,
  );
  late _ExtremoHex _fin = _ExtremoHex.registrado(
    reporte.fin,
    reporte.fechaJornada,
  );

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  _ExtremoHex _de(_LadoHex lado) => lado == _LadoHex.inicio ? _inicio : _fin;

  void _guardar(_LadoHex lado, _ExtremoHex e) => setState(() {
    if (lado == _LadoHex.inicio) {
      _inicio = e;
    } else {
      _fin = e;
    }
  });

  /// Límites solo del calendario: qué días valen lo decide el SP.
  Future<void> _elegirDia(_LadoHex lado) async {
    final e = _de(lado);
    final base = e.jornada ?? e.dia;
    final elegido = await pedirDiaHex(
      context,
      inicial: e.dia,
      ayuda: 'Día del ${lado.etiqueta.toLowerCase()}',
      primero: DateTime(base.year - 1),
      ultimo: DateTime(base.year + 1, 12, 31),
    );
    if (elegido != null && mounted) _guardar(lado, _de(lado).conDia(elegido));
  }

  /// El selector del kit: en 24 h y con la letra acotada.
  Future<void> _elegirHora(_LadoHex lado) async {
    final elegida = await pedirHoraHex(
      context,
      inicial: _de(lado).hora ?? TimeOfDay.now(),
      ayuda: 'Hora del ${lado.etiqueta.toLowerCase()}',
    );
    if (elegida != null && mounted) _guardar(lado, _de(lado).conHora(elegida));
  }

  // Sin nada corregido viaja vacío y el SP responde con su mensaje.
  void _corregir() => escribir(
    (_) => widget.datos.repo.corregirHora(
      idReporte: widget.datos.id,
      inicio: _inicio.corregida,
      fin: _fin.corregida,
      observacion: _observacion.text.trim(),
    ),
  );

  Widget _campo(_LadoHex lado, String? origen, bool enCurso) {
    final e = _de(lado);
    return _CampoExtremoHex(
      etiqueta: lado.etiqueta,
      dia: e.dia,
      hora: e.hora,
      registrada: e.registrada,
      corregida: e.corregida,
      jornada: e.jornada,
      origen: origen,
      alElegirDia: enCurso ? null : () => _elegirDia(lado),
      alElegirHora: enCurso ? null : () => _elegirHora(lado),
      alDeshacer: enCurso ? null : () => _guardar(lado, e.deshecho()),
    );
  }

  @override
  Widget build(BuildContext context) => DialogoHex(
    titulo: 'Corregir hora',
    subtitulo: 'La hora corregida reemplaza la del biométrico o la de la app',
    icono: Icons.schedule,
    ocupado: ocupado,
    accion: 'Corregir',
    alAceptar: _corregir,
    contenido:
        (enCurso) => [
          _ResumenHex(reporte),
          const SizedBox(height: Esp.l),
          _campo(_LadoHex.inicio, reporte.origenInicio, enCurso),
          const SizedBox(height: Esp.m),
          _campo(_LadoHex.fin, reporte.origenFin, enCurso),
          const SizedBox(height: Esp.l),
          TextoLargoHex(
            control: _observacion,
            etiqueta: 'Observación',
            pista: 'Por qué corriges la hora',
            ayuda: 'Obligatorio.',
            habilitado: !enCurso,
          ),
        ],
  );
}

/// Un extremo del reporte: día y hora como dos botones. Sin corregir
/// muestra su origen; corregido, la hora de antes y «Deshacer».
class _CampoExtremoHex extends StatelessWidget {
  const _CampoExtremoHex({
    required this.etiqueta,
    required this.dia,
    required this.hora,
    required this.registrada,
    required this.corregida,
    required this.jornada,
    required this.origen,
    required this.alElegirDia,
    required this.alElegirHora,
    required this.alDeshacer,
  });

  final String etiqueta;
  final DateTime dia;
  final TimeOfDay? hora;
  final DateTime? registrada;

  /// La hora que viaja; nula si el extremo no se corrigió.
  final DateTime? corregida;
  final DateTime? jornada;
  final String? origen;
  final VoidCallback? alElegirDia;
  final VoidCallback? alElegirHora;
  final VoidCallback? alDeshacer;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final corregido = corregida != null;
    final h = hora;
    final elegida =
        h == null
            ? dia
            : DateTime(dia.year, dia.month, dia.day, h.hour, h.minute);
    final otroDia = _otroDiaTexto(elegida, jornada);
    final nombre = etiqueta.toLowerCase();
    Widget boton(IconData icono, String texto, VoidCallback? alTocar) =>
        corregido
            ? FilledButton.tonalIcon(
              onPressed: alTocar,
              icon: Icon(icono, size: 18),
              label: Text(texto),
            )
            : OutlinedButton.icon(
              onPressed: alTocar,
              icon: Icon(icono, size: 18),
              label: Text(texto),
            );
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.s, Esp.s, Esp.m),
      decoration: BoxDecoration(
        color: corregido ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: corregido ? cs.primary : cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  corregido ? '$etiqueta · corregido' : etiqueta,
                  style: context.tituloSeccion(),
                ),
              ),
              // El mismo alto con o sin «Deshacer»: el diálogo no salta.
              SizedBox(
                height: 48,
                child:
                    corregido
                        ? TextButton.icon(
                          onPressed: alDeshacer,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Deshacer'),
                        )
                        : null,
              ),
            ],
          ),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              Tooltip(
                message: 'Día del $nombre',
                child: boton(
                  Icons.calendar_today_outlined,
                  fechaHex(dia),
                  alElegirDia,
                ),
              ),
              Tooltip(
                message: 'Hora del $nombre',
                child: boton(
                  Icons.schedule,
                  h == null ? 'Elige la hora' : relojHex(elegida),
                  alElegirHora,
                ),
              ),
            ],
          ),
          if (otroDia != null) ...[
            const SizedBox(height: Esp.s),
            Etiqueta(texto: otroDia, tono: TonoEtiqueta.aviso),
          ],
          const SizedBox(height: Esp.s),
          if (corregido)
            Wrap(
              spacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  registrada == null
                      ? 'Antes:'
                      : 'Antes: ${fechaHoraHex(registrada)} ·',
                  style: context.apagado(),
                ),
                OrigenHoraHex(origen),
              ],
            )
          else
            OrigenHoraHex(origen),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VISTO BUENO Y APROBACIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// Las dos firmas con el mismo resumen: el visto bueno (del encargado o del
/// jefe que lo reemplaza) y la aprobación del jefe de área.
enum _TipoFirmaHex {
  vistoBueno(
    'Visto bueno',
    'Dar visto bueno',
    Icons.task_alt,
    'Al dar el visto bueno confirmas que el empleado estuvo trabajando en la '
        'sucursal durante estas horas. Tu firma queda registrada.',
  ),
  aprobacion(
    'Aprobar reporte',
    'Aprobar',
    Icons.verified_outlined,
    'Queda listo para la planilla de RRHH',
  );

  const _TipoFirmaHex(this.titulo, this.accion, this.icono, this.efecto);

  final String titulo;
  final String accion;
  final IconData icono;

  /// Qué se confirma o qué pasa al firmar; fijo, siempre a la vista.
  final String efecto;
}

/// Visto bueno o aprobación de un reporte, según [tipo].
class _FirmaReporteHex extends _DialogoRevisionHex {
  const _FirmaReporteHex({required super.datos, required this.tipo});

  final _TipoFirmaHex tipo;

  @override
  State<_FirmaReporteHex> createState() => _FirmaReporteHexState();
}

class _FirmaReporteHexState extends _DialogoRevisionHexState<_FirmaReporteHex> {
  final TextEditingController _observacion = TextEditingController();

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  void _firmar() {
    final repo = widget.datos.repo;
    final id = widget.datos.id;
    final observacion = _oNulo(_observacion.text);
    // Adenda D37: sin salida marcada el SP pide confirmar (100) y se reenvía.
    escribir(
      (confirmado) => switch (widget.tipo) {
        _TipoFirmaHex.vistoBueno => repo.vistoBueno(
          idReporte: id,
          observacion: observacion,
          confirmado: confirmado,
        ),
        _TipoFirmaHex.aprobacion => repo.aprobar(
          idReporte: id,
          observacion: observacion,
          confirmado: confirmado,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    final tipo = widget.tipo;
    return DialogoHex(
      titulo: tipo.titulo,
      subtitulo: tipo.efecto,
      icono: tipo.icono,
      ocupado: ocupado,
      accion: tipo.accion,
      alAceptar: _firmar,
      contenido:
          (enCurso) => [
            _ResumenHex(r),
            // Adenda D37: sin salida marcada, el aviso del SP antes de firmar.
            if (AvisoSalidaHex.hay(r)) ...[
              const SizedBox(height: Esp.m),
              AvisoSalidaHex(r),
            ],
            // Solo existe con visto bueno: lo calcula el SP al darlo.
            if (r.avisoBiometrico) ...[
              const SizedBox(height: Esp.m),
              const NotaDelDato(
                texto:
                    'El biométrico registra otra hora que la del reporte: '
                    'revísala antes de aprobar.',
                tono: TonoNota.aviso,
              ),
            ],
            const SizedBox(height: Esp.l),
            InicioFinHex(r, rotulos: true),
            const SizedBox(height: Esp.m),
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // D36: el resumen de tiempo del SP; sin él, las horas.
                if ((r.resumenTiempo ?? '').trim().isNotEmpty)
                  Text(
                    r.resumenTiempo!.trim(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text(
                    horasHex(r.horasPagables),
                    style: estiloCifrasHex(
                      Theme.of(context).textTheme.bodyMedium,
                      fuerte: true,
                    ),
                  ),
                if (r.verMontos)
                  MontoHex(r.montoTotal, provisional: r.esProvisional),
              ],
            ),
            const SizedBox(height: Esp.l),
            TextoLargoHex(
              control: _observacion,
              etiqueta: 'Observación',
              ayuda: 'Opcional.',
              habilitado: !enCurso,
            ),
          ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECHAZAR
// ═══════════════════════════════════════════════════════════════════════════

class _RechazarHex extends _DialogoRevisionHex {
  const _RechazarHex({required super.datos, required this.comoJefe});

  final bool comoJefe;

  @override
  State<_RechazarHex> createState() => _RechazarHexState();
}

class _RechazarHexState extends _DialogoRevisionHexState<_RechazarHex> {
  final TextEditingController _observacion = TextEditingController();

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  // Sin motivo viaja vacío y el SP responde con su mensaje.
  void _rechazar() {
    final repo = widget.datos.repo;
    final id = widget.datos.id;
    final observacion = _observacion.text.trim();
    escribir(
      (_) =>
          widget.comoJefe
              ? repo.rechazarJefe(idReporte: id, observacion: observacion)
              : repo.rechazarEncargado(idReporte: id, observacion: observacion),
    );
  }

  @override
  Widget build(BuildContext context) => DialogoHex(
    titulo: 'Rechazar reporte',
    subtitulo: 'El empleado verá tu motivo',
    icono: Icons.warning_amber_rounded,
    destructiva: true,
    ocupado: ocupado,
    accion: 'Rechazar',
    alAceptar: _rechazar,
    contenido:
        (enCurso) => [
          Text('Se rechaza este reporte:', style: context.apagado()),
          const SizedBox(height: Esp.xs),
          _ResumenHex(reporte),
          const SizedBox(height: Esp.m),
          InicioFinHex(reporte, rotulos: true),
          const SizedBox(height: Esp.l),
          TextoLargoHex(
            control: _observacion,
            etiqueta: 'Observación',
            pista: 'El motivo del rechazo',
            ayuda: 'Obligatorio.',
            autofocus: true,
            habilitado: !enCurso,
          ),
        ],
  );
}
