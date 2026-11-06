/// D43: el encargado crea el reporte de un día pasado en que el empleado no
/// marcó. Lo que se puede crear, el tipo y los textos son del SP; la app solo
/// muestra la lista del servidor y manda el empleado, la jornada y las horas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_dialogos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Texto del botón, también para las pruebas.
const String textoCrearPasadoHex = 'Crear reporte de un día pasado';

/// La justificación viaja tras la nota fija que el SP antepone en el evento,
/// cuya columna es de 500: el resto es este tope.
const int _largoJustificacion = 432;

/// Debajo de este ancho el botón va a todo el ancho, bajo el texto.
const double _anchoEnFila = 600;

/// La franja con el botón: solo si el servidor mandó jornadas y el usuario
/// tiene el botón de corregir hora. Mientras carga o con error no ocupa lugar.
class FranjaReportePasadoHex extends ConsumerWidget {
  const FranjaReportePasadoHex({super.key, required this.refrescar});

  /// Recarga la bandeja de la pantalla después de crear.
  final VoidCallback refrescar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadas =
        ref.watch(hexJornadasPasadasProvider).valueOrNull ?? const [];
    if (jornadas.isEmpty) return const SizedBox.shrink();
    final cs = context.cs;
    final aviso = textoUsableHex(jornadas.first.textoRegularizacion);
    final boton = FilledButton.tonalIcon(
      onPressed:
          () => crearReportePasadoHex(
            context,
            ref,
            jornadas,
            refrescar: () {
              refrescar();
              ref.invalidate(hexJornadasPasadasProvider);
            },
          ),
      icon: const Icon(Icons.edit_calendar_outlined, size: 20),
      label: const Text(textoCrearPasadoHex),
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    );
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cuentaHex(
            jornadas.length,
            'jornada pasada sin reporte',
            'jornadas pasadas sin reporte',
          ),
          style: context.tituloSeccion(),
        ),
        if (aviso != null) ...[
          const SizedBox(height: 2),
          Text(aviso, style: context.apagado()),
        ],
      ],
    );
    return PermissionWidget(
      buttonName: BotonHex.editarHora,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Esp.m),
        child: Container(
          padding: const EdgeInsets.all(Esp.m),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Esquina.chica),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: LayoutBuilder(
            builder:
                (context, c) =>
                    c.maxWidth < _anchoEnFila
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            texto,
                            const SizedBox(height: Esp.m),
                            boton,
                          ],
                        )
                        : Row(
                          children: [
                            Icon(Icons.history, color: cs.primary),
                            const SizedBox(width: Esp.m),
                            Expanded(child: texto),
                            const SizedBox(width: Esp.m),
                            boton,
                          ],
                        ),
          ),
        ),
      ),
    );
  }
}

/// Abre el diálogo con la lista que mandó el servidor; al crear, [refrescar]
/// recarga la bandeja y la lista (solo si la pantalla sigue montada).
Future<void> crearReportePasadoHex(
  BuildContext context,
  WidgetRef ref,
  List<HexJornadaPasadaEntity> jornadas, {
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexReporteRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _ReportePasadoHex(
          jornadas: jornadas,
          repo: repo,
          refrescar: recargar,
        ),
  );
}

/// Un extremo (inicio o fin): el día y la hora elegidos.
typedef _ExtremoPasadoHex = ({DateTime dia, TimeOfDay? hora});

_ExtremoPasadoHex _sugerido(DateTime? sugerida, DateTime? jornada) => (
  dia: DateUtils.dateOnly(sugerida ?? jornada ?? DateTime.now()),
  hora: sugerida == null ? null : TimeOfDay.fromDateTime(sugerida),
);

DateTime? _valor(_ExtremoPasadoHex e) {
  final h = e.hora;
  return h == null
      ? null
      : DateTime(e.dia.year, e.dia.month, e.dia.day, h.hour, h.minute);
}

class _ReportePasadoHex extends StatefulWidget {
  const _ReportePasadoHex({
    required this.jornadas,
    required this.repo,
    required this.refrescar,
  });

  final List<HexJornadaPasadaEntity> jornadas;
  final HexReporteRepository repo;
  final VoidCallback refrescar;

  @override
  State<_ReportePasadoHex> createState() => _ReportePasadoHexState();
}

class _ReportePasadoHexState extends State<_ReportePasadoHex>
    with EscrituraEnDialogoHex {
  final TextEditingController _observacion = TextEditingController();
  HexJornadaPasadaEntity? _elegida;
  _ExtremoPasadoHex? _inicio;
  _ExtremoPasadoHex? _fin;

  @override
  VoidCallback get refrescarLista => widget.refrescar;

  @override
  void initState() {
    super.initState();
    // Con una sola jornada que se puede crear, ya va elegida.
    final validas = widget.jornadas.where((j) => j.puedeCrear).toList();
    if (validas.length == 1) _elegir(validas.single);
  }

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  /// Al cambiar de jornada, las horas vuelven a las sugeridas por el SP.
  void _elegir(HexJornadaPasadaEntity j) {
    _elegida = j;
    _inicio = _sugerido(j.inicioSugerido, j.fechaJornada);
    _fin = _sugerido(j.finSugerido, j.fechaJornada);
  }

  void _poner(bool esInicio, _ExtremoPasadoHex e) => setState(() {
    if (esInicio) {
      _inicio = e;
    } else {
      _fin = e;
    }
  });

  Future<void> _elegirDia(bool esInicio) async {
    final e = esInicio ? _inicio : _fin;
    if (e == null) return;
    final elegido = await pedirDiaHex(
      context,
      inicial: e.dia,
      ayuda: esInicio ? 'Día del inicio' : 'Día del fin',
      primero: DateTime(e.dia.year - 1),
      ultimo: DateTime(e.dia.year + 1, 12, 31),
    );
    if (elegido == null || !mounted) return;
    _poner(esInicio, (dia: elegido, hora: e.hora));
  }

  Future<void> _elegirHora(bool esInicio) async {
    final e = esInicio ? _inicio : _fin;
    if (e == null) return;
    final elegida = await pedirHoraHex(
      context,
      inicial: e.hora ?? TimeOfDay.now(),
      ayuda: esInicio ? 'Hora del inicio' : 'Hora del fin',
    );
    if (elegida == null || !mounted) return;
    _poner(esInicio, (dia: e.dia, hora: elegida));
  }

  ({HexJornadaPasadaEntity j, DateTime inicio, DateTime fin})? get _listo {
    final j = _elegida;
    final i = _inicio == null ? null : _valor(_inicio!);
    final f = _fin == null ? null : _valor(_fin!);
    if (j == null || !j.puedeCrear || i == null || f == null) return null;
    if (j.codEmpleado == null || j.fechaJornada == null) return null;
    return (j: j, inicio: i, fin: f);
  }

  // La justificación viaja aunque esté vacía: el SP responde con su regla.
  void _crear() {
    final l = _listo;
    if (l == null) return;
    escribir(
      (_) => widget.repo.crearReportePasado(
        HexReportePasadoEntity(
          codEmpleado: l.j.codEmpleado!,
          fechaJornada: l.j.fechaJornada!,
          inicio: l.inicio,
          fin: l.fin,
          observacion: _observacion.text.trim(),
        ),
      ),
    );
  }

  Widget _lista(bool enCurso, {required bool propioScroll}) {
    final items = [
      for (final j in widget.jornadas)
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.s),
          child: _OpcionJornadaHex(
            jornada: j,
            elegida: identical(j, _elegida),
            alTocar:
                enCurso || !j.puedeCrear
                    ? null
                    : () => setState(() => _elegir(j)),
          ),
        ),
    ];
    if (!propioScroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      );
    }
    return ListView(primary: false, children: items);
  }

  List<Widget> _formulario(bool enCurso) {
    final j = _elegida;
    final aviso = textoUsableHex(widget.jornadas.first.textoRegularizacion);
    return [
      if (aviso != null) ...[
        AvisoHex(tono: TonoHex.neutro, icono: Icons.info_outline, texto: aviso),
        const SizedBox(height: Esp.l),
      ],
      if (j == null)
        Text(
          'Elige la jornada del empleado en la lista.',
          style: context.apagado(),
        )
      else ...[
        Text(oGuionHex(j.nombreEmpleado), style: context.tituloSeccion()),
        const SizedBox(height: 2),
        Text(_jornadaTexto(j), style: context.apagado()),
        const SizedBox(height: Esp.l),
        _CampoHoraPasadaHex(
          etiqueta: 'Inicio',
          extremo: _inicio!,
          jornada: j.fechaJornada,
          alElegirDia: enCurso ? null : () => _elegirDia(true),
          alElegirHora: enCurso ? null : () => _elegirHora(true),
        ),
        const SizedBox(height: Esp.m),
        _CampoHoraPasadaHex(
          etiqueta: 'Fin',
          extremo: _fin!,
          jornada: j.fechaJornada,
          alElegirDia: enCurso ? null : () => _elegirDia(false),
          alElegirHora: enCurso ? null : () => _elegirHora(false),
        ),
      ],
      const SizedBox(height: Esp.l),
      TextoLargoHex(
        control: _observacion,
        etiqueta: 'Justificación',
        pista: 'Por qué se crea el reporte sin la marca del biométrico',
        ayuda: 'Obligatorio. Queda en el historial del reporte.',
        habilitado: !enCurso,
        largoMaximo: _largoJustificacion,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final doble = dialogoDobleHex(context);
    return DialogoHex(
      titulo: textoCrearPasadoHex,
      subtitulo:
          'Queda reportado y sigue la revisión de siempre: visto bueno y '
          'aprobación',
      icono: Icons.edit_calendar_outlined,
      ocupado: ocupado,
      accion: 'Crear reporte',
      alAceptar: _crear,
      aceptarHabilitado: _listo != null,
      lateral: (enCurso) => _lista(enCurso, propioScroll: true),
      contenido:
          (enCurso) => [
            if (!doble) ...[
              Text('Jornada', style: context.tituloSeccion()),
              const SizedBox(height: Esp.s),
              _lista(enCurso, propioScroll: false),
              const SizedBox(height: Esp.m),
            ],
            ..._formulario(enCurso),
          ],
    );
  }
}

/// «Jornada 03/11/2026 · Domingo · Central».
String _jornadaTexto(HexJornadaPasadaEntity j) => [
  'Jornada ${fechaHex(j.fechaJornada)}',
  j.textoTipoDia,
  j.nombreSucursal ?? '',
].where((p) => p.trim().isNotEmpty).join(' · ');

/// Una jornada de la lista: quién, cuándo, el horario, el motivo y la ayuda
/// del SP. Sin [alTocar] se ve apagada (no se puede crear o hay escritura).
class _OpcionJornadaHex extends StatelessWidget {
  const _OpcionJornadaHex({
    required this.jornada,
    required this.elegida,
    required this.alTocar,
  });

  final HexJornadaPasadaEntity jornada;
  final bool elegida;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final j = jornada;
    final motivo = textoUsableHex(j.motivo);
    final ayuda = textoUsableHex(j.textoAyuda);
    final apagada = !j.puedeCrear;
    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              elegida ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: elegida ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Text(
                oGuionHex(j.nombreEmpleado),
                style: context.tituloSeccion(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text(_jornadaTexto(j), style: context.apagado()),
        if (textoUsableHex(j.cargo) != null)
          Text(j.cargo!, style: context.apagado()),
        const SizedBox(height: Esp.xs),
        Text(oGuionHex(j.textoHorario)),
        if (motivo != null) Text('Motivo: $motivo', style: context.apagado()),
        if (ayuda != null) ...[
          const SizedBox(height: Esp.xs),
          // Apagada: la razón con el tono de aviso del tema, en varias líneas.
          apagada
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.tertiary),
                  const SizedBox(width: Esp.xs),
                  Expanded(
                    child: Text(
                      ayuda,
                      style: context.apagado()?.copyWith(color: cs.tertiary),
                    ),
                  ),
                ],
              )
              : Text(ayuda, style: context.apagado()),
        ],
      ],
    );
    return Semantics(
      button: !apagada,
      selected: elegida,
      enabled: alTocar != null,
      child: Material(
        color: elegida ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
          side: BorderSide(color: elegida ? cs.primary : cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Opacity(
            opacity: apagada ? 0.6 : 1,
            child: Padding(
              padding: const EdgeInsets.all(Esp.m),
              child: contenido,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inicio o fin: el día y la hora como dos botones; avisa si la hora cae en
/// otro día que la jornada (una salida pasada la medianoche).
class _CampoHoraPasadaHex extends StatelessWidget {
  const _CampoHoraPasadaHex({
    required this.etiqueta,
    required this.extremo,
    required this.jornada,
    required this.alElegirDia,
    required this.alElegirHora,
  });

  final String etiqueta;
  final _ExtremoPasadoHex extremo;
  final DateTime? jornada;
  final VoidCallback? alElegirDia;
  final VoidCallback? alElegirHora;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final valor = _valor(extremo);
    final nombre = etiqueta.toLowerCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.s, Esp.s, Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              Tooltip(
                message: 'Día del $nombre',
                child: OutlinedButton.icon(
                  onPressed: alElegirDia,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(fechaHex(extremo.dia)),
                ),
              ),
              Tooltip(
                message: 'Hora del $nombre',
                child: OutlinedButton.icon(
                  onPressed: alElegirHora,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    valor == null ? 'Elige la hora' : relojHex(valor),
                  ),
                ),
              ),
            ],
          ),
          if (valor != null && otroDiaHex(valor, jornada)) ...[
            const SizedBox(height: Esp.s),
            const Etiqueta(
              texto: 'Otro día que la jornada',
              tono: TonoEtiqueta.aviso,
            ),
          ],
        ],
      ),
    );
  }
}
