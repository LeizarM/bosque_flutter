/// Marcación en la app del módulo Horas Extras: quién asignó y el motivo
/// (D41, solo lectura), lo que hace falta antes de marcar (ubicación y
/// requisitos del SP) y solo las teclas que valen ahora.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// Tipos de marca que acepta el SP.
const String _entrada = 'ENTRADA';
const String _salida = 'SALIDA';

/// Ancho de las teclas cuando van al lado de los requisitos.
const double _anchoTeclas = 380;

/// Desde este ancho, dos teclas van una al lado de la otra.
const double _anchoDosTeclas = 340;

/// D41: quién asignó las horas extra de la jornada (el texto del SP) y el
/// motivo que escribió, tal cual y solo para leer.
class AsignacionHoyHex extends StatelessWidget {
  const AsignacionHoyHex(this.vista, {super.key});

  final HexVistaMarcacionEntity vista;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final motivo = vista.motivoAsignacion?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 22,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vista.textoVista.trim(),
                  style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                ),
                if (motivo.isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  Text(
                    'Motivo',
                    style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Semantics(
                    label: 'Motivo: $motivo',
                    excludeSemantics: true,
                    child: Text(motivo, style: t.bodyLarge),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel «Marcar en la app». Al abrir verifica la ubicación (y pide el
/// permiso); vuelve a verificar si el servicio cambia, al volver de los
/// ajustes y en cada toque. Cada tecla vale lo que diga `reporte/hoy` (D37).
class PanelMarcacionHex extends ConsumerStatefulWidget {
  const PanelMarcacionHex({super.key});

  @override
  ConsumerState<PanelMarcacionHex> createState() => _PanelMarcacionHexState();
}

class _PanelMarcacionHexState extends ConsumerState<PanelMarcacionHex> {
  final OcupadoHex _escritura = OcupadoHex();
  late final AppLifecycleListener _ciclo;
  StreamSubscription<bool>? _servicio;

  /// Nulo mientras llega la primera verificación.
  EstadoUbicacionHex? _estado;

  /// La marca en curso: mientras no es nula, ninguna otra sale.
  String? _marcando;
  String? _progreso;

  /// Lo que dejó la última marca; queda bajo las teclas hasta la siguiente.
  ResultadoHex? _resultado;

  /// Solo cuenta la verificación más reciente; una anterior que llegue
  /// tarde no la pisa.
  int _vuelta = 0;

  UbicacionHex get _ubicacion => ref.read(hexUbicacionProvider);

  @override
  void initState() {
    super.initState();
    _servicio = _ubicacion.servicioActivo().listen(
      (_) => _verificar(),
      // Sin avisos del servicio igual se verifica en cada toque.
      onError: (Object _) {},
    );
    // Al volver de los ajustes del sistema el permiso o el horario pudieron
    // cambiar: se revisan los dos.
    _ciclo = AppLifecycleListener(
      onResume: () {
        _verificar();
        ref
          ..invalidate(hexRequisitosMarcaProvider)
          ..invalidate(hexReporteHoyProvider);
      },
    );
    _verificar(pedirPermiso: true);
  }

  @override
  void dispose() {
    _servicio?.cancel();
    _ciclo.dispose();
    _escritura.dispose();
    super.dispose();
  }

  Future<EstadoUbicacionHex> _verificar({bool pedirPermiso = false}) async {
    final vuelta = ++_vuelta;
    EstadoUbicacionHex estado;
    try {
      estado = await _ubicacion.verificar(pedirPermiso: pedirPermiso);
    } on Exception {
      // Si el teléfono no sabe responder, no se marca: cuenta como sin permiso.
      estado = EstadoUbicacionHex.sinPermiso;
    }
    if (mounted && vuelta == _vuelta) setState(() => _estado = estado);
    return estado;
  }

  Future<void> _marcar(String tipoMarca) async {
    // La guardia se toma antes de verificar y de esperar al GPS (hasta 20 s):
    // un segundo toque no pide otra posición ni manda otra marca.
    if (_marcando != null) return;
    HapticaHex.toque();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _marcando = tipoMarca;
      _progreso = 'Verificando la ubicación…';
      _resultado = null;
    });
    try {
      // La ubicación pudo apagarse después de abrir la pantalla.
      if (await _verificar() != EstadoUbicacionHex.lista || !mounted) return;
      setState(() => _progreso = 'Obteniendo tu ubicación…');
      final posicion = await _leerPosicion();
      if (posicion == null || !mounted) return;
      setState(() => _progreso = 'Registrando la marca…');
      final repo = ref.read(hexReporteRepositoryProvider);
      // D37: sin confirmación; una salida ya registrada vuelve como 409. D41:
      // sin motivo, que el SP toma de la asignación.
      await ejecutarHex(
        context,
        ocupado: _escritura,
        accion: (_) => repo.marcar(tipoMarca: tipoMarca, posicion: posicion),
        refrescar: () => ref.invalidate(hexMisReportesProvider),
        alResultado: (r) {
          if (mounted) setState(() => _resultado = r);
        },
      );
      if (!mounted) return;
      // El SP pudo rechazar por un requisito y la tecla de salida pudo
      // bloquearse: se piden los dos de nuevo.
      ref
        ..invalidate(hexRequisitosMarcaProvider)
        ..invalidate(hexReporteHoyProvider);
    } finally {
      if (mounted) {
        setState(() {
          _marcando = null;
          _progreso = null;
        });
      }
    }
  }

  /// La posición, o nulo: si se perdió el servicio o el permiso, el panel
  /// muestra cómo recuperarlo; si no, se avisa. Un toque nunca queda sin
  /// respuesta.
  Future<PosicionHex?> _leerPosicion() async {
    try {
      return await _ubicacion.posicionActual();
    } on UbicacionNoDisponibleHex catch (e) {
      if (!mounted) return null;
      final perdido = e.estado;
      if (perdido != null) {
        _vuelta++;
        setState(() => _estado = perdido);
      } else {
        _avisarSinPosicion(
          'No se pudo obtener tu ubicación a tiempo. Busca cielo abierto o '
          'acércate a una ventana y vuelve a marcar.',
        );
      }
      return null;
    } on Exception {
      if (mounted) {
        _avisarSinPosicion(
          'No se pudo obtener tu ubicación. Vuelve a marcar en un momento.',
        );
      }
      return null;
    }
  }

  /// Sin posición no hay marca: queda escrito bajo las teclas, como un fallo.
  void _avisarSinPosicion(String texto) {
    HapticaHex.aviso();
    setState(() => _resultado = (exito: false, mensaje: texto));
  }

  /// Lleva al usuario a lo que falta; al volver, `onResume` verifica.
  Future<void> _resolver(EstadoUbicacionHex estado) async {
    if (estado == EstadoUbicacionHex.servicioApagado) {
      await _ubicacion.abrirAjustesUbicacion();
    } else if (estado == EstadoUbicacionHex.denegadoSiempre && !kIsWeb) {
      await _ubicacion.abrirAjustesApp();
    } else {
      await _verificar(pedirPermiso: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estado = _estado;
    final bloqueo = estado == null ? null : _bloqueoHex(estado);
    // Mientras llegan, o si el SP responde 204 o falla, los requisitos no
    // traban las teclas: el SP vuelve a validar al marcar.
    final requisitos = ref.watch(hexRequisitosMarcaProvider);
    final filas = [
      ...requisitos.valueOrNull ?? const <HexRequisitoMarcaEntity>[],
    ]..sort((a, b) => a.orden.compareTo(b.orden));
    final trabado = filas.any((r) => r.impideMarcar);
    final lista = estado == EstadoUbicacionHex.lista;
    final libre = lista && !trabado && _marcando == null;
    // Sin `reporte/hoy` a la vista ninguna tecla vale: lo decide el SP.
    final hoy = ref.watch(hexReporteHoyProvider).valueOrNull;
    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.touch_app_outlined, size: 20, color: cs.primary),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Text('Marcar en la app', style: context.tituloSeccion()),
            ),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text(
          'Úsalo si no alcanzaste a marcar en el biométrico. La hora la '
          'pone el sistema y se guarda tu ubicación.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.m),
        _RequisitosHex(
          ubicacion: estado,
          bloqueo: bloqueo,
          alResolver: estado == null ? null : () => _resolver(estado),
          requisitos: filas,
          revisando: requisitos.isLoading && !requisitos.hasValue,
        ),
      ],
    );
    final teclas = _TeclasMarcaHex(
      marcando: _marcando,
      progreso: _progreso,
      trabado: trabado,
      resultado: _resultado,
      hoy: hoy,
      alMarcar: libre ? _marcar : null,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= hexAnchoTabla;
          return Padding(
            padding: EdgeInsets.all(ancho ? Esp.l : Esp.m),
            child:
                ancho
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: datos),
                        const SizedBox(width: Esp.xl),
                        SizedBox(width: _anchoTeclas, child: teclas),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [datos, const SizedBox(height: Esp.m), teclas],
                    ),
          );
        },
      ),
    );
  }
}

/// Qué le falta a la ubicación, cómo se arregla y el botón que lleva ahí.
typedef _BloqueoHex =
    ({String texto, String ayuda, String accion, IconData icono});

/// Nulo si la ubicación está lista. En la web el permiso negado se arregla en
/// el navegador: no hay ajustes de la app que abrir.
_BloqueoHex? _bloqueoHex(EstadoUbicacionHex estado) => switch (estado) {
  EstadoUbicacionHex.lista => null,
  EstadoUbicacionHex.servicioApagado => (
    texto: 'Activa la ubicación del teléfono para marcar.',
    ayuda:
        'Cada marca guarda dónde estás. Enciende la ubicación (GPS) y vuelve '
        'a esta pantalla.',
    accion: 'Activar ubicación',
    icono: Icons.location_on_outlined,
  ),
  EstadoUbicacionHex.sinPermiso => (
    texto: 'Da permiso de ubicación a la aplicación para marcar.',
    ayuda:
        'Cada marca guarda dónde estás. Cuando el teléfono pregunte, permite '
        'la ubicación mientras usas la aplicación.',
    accion: 'Dar permiso',
    icono: Icons.my_location,
  ),
  EstadoUbicacionHex.denegadoSiempre when kIsWeb => (
    texto: 'Da permiso de ubicación a la aplicación para marcar.',
    ayuda:
        'Tu navegador bloqueó la ubicación de este sitio. Permítela desde el '
        'ícono junto a la dirección y vuelve a intentar.',
    accion: 'Volver a intentar',
    icono: Icons.refresh,
  ),
  EstadoUbicacionHex.denegadoSiempre => (
    texto: 'Da permiso de ubicación a la aplicación para marcar.',
    ayuda:
        'El permiso está negado. En Ajustes, entra a Permisos › Ubicación, '
        'permítela mientras usas la aplicación y vuelve a esta pantalla.',
    accion: 'Abrir ajustes',
    icono: Icons.settings_outlined,
  ),
};

/// Lo que hace falta antes de marcar. Si todo se cumple, una sola línea que
/// se abre para ver el detalle; si algo falta, «Antes de marcar» con solo lo
/// que falta (y «Ver todo» para el resto).
class _RequisitosHex extends StatefulWidget {
  const _RequisitosHex({
    required this.ubicacion,
    required this.bloqueo,
    required this.alResolver,
    required this.requisitos,
    required this.revisando,
  });

  /// Nulo mientras llega la primera verificación.
  final EstadoUbicacionHex? ubicacion;
  final _BloqueoHex? bloqueo;
  final VoidCallback? alResolver;
  final List<HexRequisitoMarcaEntity> requisitos;
  final bool revisando;

  @override
  State<_RequisitosHex> createState() => _RequisitosHexState();
}

class _RequisitosHexState extends State<_RequisitosHex> {
  bool _todo = false;

  void _alternar() {
    HapticaHex.seleccion();
    setState(() => _todo = !_todo);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = widget;
    final ubicacion = w.ubicacion;
    final faltan = [
      for (final r in w.requisitos)
        if (!r.cumple) r,
    ];
    final ubicacionLista = ubicacion == EstadoUbicacionHex.lista;
    final verificando = ubicacion == null || w.revisando;
    final listo = ubicacionLista && faltan.isEmpty && !w.revisando;

    final Widget contenido;
    if (verificando && w.bloqueo == null && faltan.isEmpty) {
      contenido = _FilaRequisitoHex(
        marca: _MarcaRequisitoHex.revisando,
        titulo:
            ubicacion == null
                ? 'Verificando la ubicación…'
                : 'Revisando tus requisitos…',
        detalle: '',
      );
    } else if (listo) {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label:
                _todo
                    ? 'Todo listo para marcar. Ocultar el detalle'
                    : 'Todo listo para marcar. Ver el detalle',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(Esquina.chica),
              onTap: _alternar,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 20,
                      color: HexColores.de(context).exito,
                    ),
                    const SizedBox(width: Esp.s),
                    Expanded(
                      child: Text(
                        'Todo listo para marcar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      _todo ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_todo) ..._detalle(context, soloFaltas: false),
        ],
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Antes de marcar',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: Peso.titulo,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Esp.xs),
          ..._detalle(context, soloFaltas: !_todo),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
              onPressed: _alternar,
              child: Text(_todo ? 'Ver solo lo que falta' : 'Ver todo'),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Semantics(liveRegion: true, child: contenido),
    );
  }

  /// La ubicación y los requisitos del SP; con [soloFaltas], solo los que no
  /// se cumplen. Lo que falta de la ubicación lleva cómo arreglarlo.
  List<Widget> _detalle(BuildContext context, {required bool soloFaltas}) {
    final w = widget;
    final b = w.bloqueo;
    final resolver = w.alResolver;
    final ubicacion = w.ubicacion;
    final ubicacionLista = ubicacion == EstadoUbicacionHex.lista;
    return [
      if (!soloFaltas || !ubicacionLista)
        _FilaRequisitoHex(
          marca: switch (ubicacion) {
            null => _MarcaRequisitoHex.revisando,
            EstadoUbicacionHex.lista => _MarcaRequisitoHex.cumple,
            _ => _MarcaRequisitoHex.bloquea,
          },
          titulo: switch (ubicacion) {
            null => 'Verificando la ubicación…',
            EstadoUbicacionHex.lista => 'Ubicación activa',
            EstadoUbicacionHex.servicioApagado => 'Ubicación apagada',
            _ => 'Sin permiso de ubicación',
          },
          detalle: b?.texto ?? '',
        ),
      if (b != null && resolver != null)
        Padding(
          padding: const EdgeInsets.only(left: 28, bottom: Esp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(b.ayuda, style: context.apagado()),
              const SizedBox(height: Esp.s),
              FilledButton.tonalIcon(
                onPressed: resolver,
                icon: Icon(b.icono, size: 18),
                label: Text(b.accion),
              ),
            ],
          ),
        ),
      if (w.revisando)
        const _FilaRequisitoHex(
          marca: _MarcaRequisitoHex.revisando,
          titulo: 'Revisando tus requisitos…',
          detalle: '',
        ),
      for (final r in w.requisitos)
        if (!soloFaltas || !r.cumple) _filaDe(r),
    ];
  }

  static Widget _filaDe(HexRequisitoMarcaEntity r) => _FilaRequisitoHex(
    marca:
        r.cumple
            ? _MarcaRequisitoHex.cumple
            : r.bloquea
            ? _MarcaRequisitoHex.bloquea
            : _MarcaRequisitoHex.aviso,
    titulo: r.titulo.trim().isEmpty ? r.requisito : r.titulo,
    detalle: r.detalle,
  );
}

/// Cómo está un requisito: se cumple, impide marcar, solo avisa o se revisa.
enum _MarcaRequisitoHex { cumple, bloquea, aviso, revisando }

/// Una fila de los requisitos: la marca de color, el título y el detalle.
/// Lo que impide marcar lleva el detalle en el color de error.
class _FilaRequisitoHex extends StatelessWidget {
  const _FilaRequisitoHex({
    required this.marca,
    required this.titulo,
    required this.detalle,
  });

  final _MarcaRequisitoHex marca;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hc = HexColores.de(context);
    final t = Theme.of(context).textTheme;
    final (IconData? icono, Color color, String lectura) = switch (marca) {
      _MarcaRequisitoHex.cumple => (Icons.check_circle, hc.exito, 'Listo'),
      _MarcaRequisitoHex.bloquea => (Icons.cancel, cs.error, 'Falta'),
      _MarcaRequisitoHex.aviso => (Icons.error_outline, hc.pendiente, 'Revisa'),
      _MarcaRequisitoHex.revisando => (null, cs.onSurfaceVariant, ''),
    };
    final texto = detalle.trim();
    return Semantics(
      label: lectura.isEmpty ? null : '$lectura: $titulo',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Esp.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 20,
              child:
                  icono == null
                      ? Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                      : Icon(icono, size: 20, color: color),
            ),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (texto.isNotEmpty)
                    Text(
                      texto,
                      style: t.bodySmall?.copyWith(
                        fontSize: 13,
                        color:
                            marca == _MarcaRequisitoHex.bloquea
                                ? cs.error
                                : cs.onSurfaceVariant,
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

/// Solo las teclas que el SP deja usar ahora (`puedeMarcar*`), grandes y con
/// su texto; de la que no vale queda su texto, discreto. Debajo, lo que se
/// está haciendo y el resultado de la marca.
class _TeclasMarcaHex extends StatelessWidget {
  const _TeclasMarcaHex({
    required this.marcando,
    required this.progreso,
    required this.trabado,
    required this.resultado,
    required this.hoy,
    required this.alMarcar,
  });

  final String? marcando;
  final String? progreso;

  /// Qué tecla vale ahora y por qué, del SP; nulo: ninguna.
  final HexVistaMarcacionEntity? hoy;

  /// Un requisito del SP impide marcar: se dice dónde mirar.
  final bool trabado;
  final ResultadoHex? resultado;

  /// Nulo: las teclas quedan deshabilitadas.
  final ValueChanged<String>? alMarcar;

  @override
  Widget build(BuildContext context) {
    final marcar = alMarcar;
    final enCurso = progreso;
    final r = resultado;
    final v = hoy;
    final conEntrada = v?.puedeMarcarEntrada ?? false;
    final conSalida = v?.puedeMarcarSalida ?? false;
    final teclas = <Widget>[
      if (conEntrada)
        _TeclaHex(
          etiqueta: 'Marcar entrada',
          ayuda: _ayuda(
            v?.textoMarcarEntrada,
            'Empiezo antes de mi horario, o es domingo o feriado',
          ),
          icono: Icons.login,
          destacada: !conSalida,
          ocupada: marcando == _entrada,
          alTocar: marcar == null ? null : () => marcar(_entrada),
        ),
      if (conSalida)
        _TeclaHex(
          etiqueta: 'Marcar salida',
          ayuda: _ayuda(v?.textoMarcarSalida, 'Me quedo después de mi horario'),
          icono: Icons.logout,
          destacada: true,
          ocupada: marcando == _salida,
          alTocar: marcar == null ? null : () => marcar(_salida),
        ),
    ];
    // Lo que el SP dice de la tecla que no vale (por ejemplo, «Ya
    // registraste tu salida…»), sin repetir el mismo texto.
    final notas = <String>{
      if (!conSalida && (v?.textoMarcarSalida.trim() ?? '').isNotEmpty)
        v!.textoMarcarSalida.trim(),
      if (!conEntrada && (v?.textoMarcarEntrada.trim() ?? '').isNotEmpty)
        v!.textoMarcarEntrada.trim(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (teclas.length == 2)
          LayoutBuilder(
            builder:
                (context, c) =>
                    c.maxWidth >= _anchoDosTeclas
                        ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: teclas[0]),
                              const SizedBox(width: Esp.s),
                              Expanded(child: teclas[1]),
                            ],
                          ),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            teclas[1],
                            const SizedBox(height: Esp.s),
                            teclas[0],
                          ],
                        ),
          )
        else if (teclas.length == 1)
          teclas.single,
        for (final n in notas) ...[
          if (teclas.isNotEmpty || n != notas.first)
            const SizedBox(height: Esp.s),
          _NotaTeclaHex(n),
        ],
        if (enCurso != null) ...[
          const SizedBox(height: Esp.s),
          Semantics(
            liveRegion: true,
            child: Text(
              enCurso,
              textAlign: TextAlign.center,
              style: context.apagado(),
            ),
          ),
        ] else if (trabado && teclas.isNotEmpty) ...[
          const SizedBox(height: Esp.s),
          Text(
            'Falta un requisito: revisa «Antes de marcar».',
            textAlign: TextAlign.center,
            style: context.apagado()?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (r != null) ...[
          const SizedBox(height: Esp.s),
          AvisoHex(
            tono: r.exito ? TonoHex.exito : TonoHex.error,
            icono: r.exito ? Icons.check_circle : Icons.error_outline,
            texto:
                r.mensaje.trim().isNotEmpty
                    ? r.mensaje
                    : r.exito
                    ? 'Marca registrada.'
                    : 'No se pudo registrar la marca.',
          ),
        ],
      ],
    );
  }
}

/// El texto del SP de una tecla que ahora no vale, sin botón.
class _NotaTeclaHex extends StatelessWidget {
  const _NotaTeclaHex(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: Esp.s),
        Expanded(child: Text(texto, style: context.apagado())),
      ],
    );
  }
}

/// El texto del SP de por qué la tecla vale o no; sin él, la ayuda fija.
String _ayuda(String? delSp, String fija) {
  final t = delSp?.trim() ?? '';
  return t.isEmpty ? fija : t;
}

/// Una tecla grande con su ícono arriba y el texto del SP de hasta cuándo
/// vale; la de salida va destacada porque es la marca más frecuente.
class _TeclaHex extends StatelessWidget {
  const _TeclaHex({
    required this.etiqueta,
    required this.ayuda,
    required this.icono,
    required this.ocupada,
    required this.alTocar,
    this.destacada = false,
  });

  final String etiqueta;
  final String ayuda;
  final IconData icono;
  final bool ocupada;
  final VoidCallback? alTocar;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final estilo = FilledButton.styleFrom(
      minimumSize: const Size(0, 88),
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
    );
    // La ayuda hereda el color de la tecla (también deshabilitada).
    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 22,
          child:
              ocupada
                  ? const Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                  : Icon(icono, size: 22),
        ),
        const SizedBox(height: Esp.xs),
        Text(etiqueta, textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(
          ayuda,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
        ),
      ],
    );
    return destacada
        ? FilledButton(style: estilo, onPressed: alTocar, child: contenido)
        : FilledButton.tonal(
          style: estilo,
          onPressed: alTocar,
          child: contenido,
        );
  }
}

/// «Mis horas extras» bloqueada (D37): el texto del SP de por qué (no hay
/// asignación para hoy) y un botón para volver a consultar.
class VistaBloqueadaHex extends StatelessWidget {
  const VistaBloqueadaHex({
    super.key,
    required this.texto,
    required this.alActualizar,
    this.actualizando = false,
  });

  final String texto;
  final VoidCallback alActualizar;
  final bool actualizando;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.xl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_outlined, size: 44, color: cs.onSurfaceVariant),
          const SizedBox(height: Esp.m),
          Semantics(
            liveRegion: true,
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: t.titleMedium,
            ),
          ),
          const SizedBox(height: Esp.xs),
          Text(
            'Cuando tu encargado te asigne horas extra, aquí podrás marcar y '
            'ver tus reportes.',
            textAlign: TextAlign.center,
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.l),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: actualizando ? null : alActualizar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Volver a consultar'),
          ),
        ],
      ),
    );
  }
}
