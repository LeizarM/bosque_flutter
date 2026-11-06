/// Formularios de la configuración del cálculo: vigencia nueva de un
/// parámetro, un tramo o una comida, editar una leyenda, dejar de usar un
/// parámetro y eliminar una vigencia. Fechas, cruces y vacíos los valida el SP.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_mapa_tramos.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENTRADAS PÚBLICAS
// ═══════════════════════════════════════════════════════════════════════════

/// Vigencia nueva de [base], prellenada con su fila (decisión 23 del Plan 1):
/// fecha, número o lista según la clave del [catalogo]; leyenda y «Rige desde».
Future<void> vigenciaParametroHex(
  BuildContext context,
  WidgetRef ref,
  HexParametroEntity base, {
  required VoidCallback refrescar,
  List<HexParametroClaveEntity> catalogo = const [],
}) {
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _VigenciaParametroHex(
          base: base,
          catalogo: catalogo,
          repo: repo,
          refrescarLista: recargar,
        ),
  );
}

/// Primera vigencia de una clave del [catalogo] (D33): se elige la clave y el
/// campo sigue su tipo; parte de la que falta. Lo demás lo valida el SP.
Future<void> nuevoParametroHex(
  BuildContext context,
  WidgetRef ref,
  List<HexParametroClaveEntity> catalogo, {
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _VigenciaParametroHex(
          catalogo: catalogo,
          repo: repo,
          refrescarLista: recargar,
        ),
  );
}

/// «Dejar de usar desde…» de [p] (D33): el primer día sin el parámetro, hoy
/// por defecto, y qué pasa desde entonces (`siFalta`). Lo demás lo valida el SP.
Future<void> dejarDeUsarParametroHex(
  BuildContext context,
  WidgetRef ref,
  HexParametroEntity p, {
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) =>
            _DejarDeUsarHex(parametro: p, repo: repo, refrescarLista: recargar),
  );
}

/// Vigencia nueva de [base] o, sin ella, un tramo nuevo (el SP crea el código
/// si no existe). El fin a las 00:00 son las 24:00.
Future<void> vigenciaTramoHex(
  BuildContext context,
  WidgetRef ref,
  HexTramoEntity? base, {
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) =>
            _VigenciaTramoHex(base: base, repo: repo, refrescarLista: recargar),
  );
}

/// Vigencia nueva de [base] o, sin ella, una comida nueva (el SP la crea si el
/// código no existe): leyendas, códigos, montos, ventana y «Rige desde».
Future<void> vigenciaComidaHex(
  BuildContext context,
  WidgetRef ref,
  HexComidaEntity? base, {
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexConfiguracionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _VigenciaComidaHex(
          base: base,
          repo: repo,
          refrescarLista: recargar,
        ),
  );
}

/// Edita una leyenda en su lugar (parámetro, tramo, comida o comida doble):
/// [guardar] manda el id y ese único campo; [etiqueta] nombra el campo.
Future<void> editarLeyendaHex(
  BuildContext context, {
  required String codigo,
  required String leyenda,
  required Future<HexRespuesta> Function(String leyenda) guardar,
  required VoidCallback refrescar,
  String etiqueta = 'Leyenda',
}) => abrirDialogoHex(
  context,
  refrescar: refrescar,
  dialogo:
      (recargar) => _EditarLeyendaHex(
        codigo: codigo,
        leyenda: leyenda,
        etiqueta: etiqueta,
        guardar: guardar,
        refrescarLista: recargar,
      ),
);

/// Confirma y elimina una vigencia. Si ya empezó a regir, el SP no lo deja y
/// su mensaje se muestra; [ocupado] evita una segunda eliminación en curso.
Future<void> eliminarVigenciaHex(
  BuildContext context, {
  required OcupadoHex ocupado,
  required String codigo,
  required DateTime? desde,
  required Future<HexRespuesta> Function() eliminar,
  required VoidCallback refrescar,
}) async {
  if (ocupado.value) return;
  FocusManager.instance.primaryFocus?.unfocus();
  final si = await confirmar(
    context,
    titulo: 'Eliminar vigencia',
    detalle:
        'Se elimina la vigencia de «$codigo» que rige desde el '
        '${fechaHex(desde)}. Queda registrada en el historial de cambios.',
    textoConfirmar: 'Eliminar',
    destructiva: true,
  );
  if (!si || !context.mounted) return;
  await ejecutarHex(
    context,
    ocupado: ocupado,
    accion: (_) => eliminar(),
    refrescar: refrescar,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS DE LOS FORMULARIOS
// ═══════════════════════════════════════════════════════════════════════════

/// Un número para editarlo: sin separador de miles, con coma y con todos sus
/// decimales; al leerlo de vuelta da el mismo valor.
String _numeroEditable(double? v) {
  if (v == null) return '';
  final t = v.toString();
  return (t.endsWith('.0') ? t.substring(0, t.length - 2) : t).replaceAll(
    '.',
    ',',
  );
}

/// El código de lo que se cambia y de qué fila parte.
class _CabeceraHex extends StatelessWidget {
  const _CabeceraHex({required this.codigo, required this.texto});

  final String codigo;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (codigo.isNotEmpty) ...[
        CodigoHex(codigo),
        const SizedBox(width: Esp.m),
      ],
      Expanded(child: Text(texto, style: context.apagado())),
    ],
  );
}

/// La tecla de acción de un campo: «siguiente» en los de en medio y «listo» en
/// el último, que además envía el formulario con [alEnviar].
typedef AccionTeclaHex = ({TextInputAction accion, VoidCallback? alEnviar});

const AccionTeclaHex _siguiente = (
  accion: TextInputAction.next,
  alEnviar: null,
);

AccionTeclaHex _listo(VoidCallback alEnviar) => (
  accion: TextInputAction.done,
  alEnviar: alEnviar,
);

class _TextoHex extends StatelessWidget {
  const _TextoHex({
    required this.control,
    required this.etiqueta,
    required this.habilitado,
    required this.tecla,
    this.mayusculas = false,
    this.autofocus = false,
  });

  final TextEditingController control;
  final String etiqueta;
  final bool habilitado;
  final AccionTeclaHex tecla;
  final bool mayusculas;

  /// Solo si es el único campo del diálogo.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: control,
    enabled: habilitado,
    autofocus: autofocus,
    textInputAction: tecla.accion,
    onSubmitted: tecla.alEnviar == null ? null : (_) => tecla.alEnviar!(),
    textCapitalization:
        mayusculas
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
    ),
  );
}

/// Solo cifras, punto y coma: nada de signos ni «NaN» o «Infinity».
final List<TextInputFormatter> _soloCifras = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
];

/// Un número con su lectura en vivo: «Se guardará: X» (al menos 2 decimales,
/// sin dudas con los miles) o «No se entiende el número». Solo muestra: lo
/// que no se entiende viaja nulo y el SP responde. [enBs]: un monto.
class _NumeroHex extends StatelessWidget {
  const _NumeroHex({
    required this.control,
    required this.etiqueta,
    required this.habilitado,
    required this.tecla,
    this.enBs = false,
    this.ayuda = 'Coma para decimales y punto para miles: 1.234,50.',
  });

  final TextEditingController control;
  final String etiqueta;
  final bool habilitado;
  final AccionTeclaHex tecla;
  final bool enBs;
  final String ayuda;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: control,
        builder: (context, valor, _) {
          final texto = valor.text.trim();
          final numero = numeroEscritoHex(texto);
          final noSeEntiende = texto.isNotEmpty && numero == null;
          final lectura =
              texto.isEmpty
                  ? null
                  : numero == null
                  ? 'No se entiende el número'
                  : 'Se guardará: '
                      '${enBs ? bsHex(numero) : decimalSinDudaHex(numero)}';
          return TextField(
            controller: control,
            enabled: habilitado,
            textInputAction: tecla.accion,
            onSubmitted:
                tecla.alEnviar == null ? null : (_) => tecla.alEnviar!(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _soloCifras,
            style: context.numero(fuerte: true),
            decoration: InputDecoration(
              labelText: etiqueta,
              prefixText: enBs ? 'Bs ' : null,
              helperText: lectura == null ? ayuda : '$lectura\n$ayuda',
              helperMaxLines: 4,
              helperStyle:
                  noSeEntiende
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
              border: const OutlineInputBorder(),
            ),
          );
        },
      );
}

/// «Rige desde»: siempre se elige; la fecha de la fila anterior no viaja.
/// [ayuda] explica qué pasa con lo anterior (cada formulario la suya).
class _RigeDesdeHex extends StatelessWidget {
  const _RigeDesdeHex({
    required this.fecha,
    required this.alElegir,
    this.ayuda = 'La vigencia anterior se cierra sola.',
  });

  final DateTime? fecha;
  final ValueChanged<DateTime>? alElegir;
  final String ayuda;

  Future<void> _elegir(BuildContext context) async {
    final elegida = await pedirDiaHex(
      context,
      inicial: fecha,
      ayuda: 'Rige desde',
    );
    if (elegida != null && context.mounted) alElegir?.call(elegida);
  }

  @override
  Widget build(BuildContext context) => CampoSelectorHex(
    etiqueta: 'Rige desde',
    valor: fecha == null ? null : fechaHex(fecha),
    pista: 'Elige el primer día',
    icono: Icons.event_outlined,
    ayuda: ayuda,
    alTocar: alElegir == null ? null : () => _elegir(context),
  );
}

/// Una hora que abre el selector de 24 h del kit.
class _HoraHex extends StatelessWidget {
  const _HoraHex({
    required this.etiqueta,
    required this.hora,
    required this.alElegir,
    this.ayuda,
  });

  final String etiqueta;
  final String? hora;
  final ValueChanged<String>? alElegir;
  final String? ayuda;

  Future<void> _elegir(BuildContext context) async {
    final elegida = await pedirHoraHex(
      context,
      inicial: horaDeTimeHex(hora),
      ayuda: etiqueta,
    );
    if (elegida != null && context.mounted) {
      alElegir?.call(horaTimeHex(elegida));
    }
  }

  @override
  Widget build(BuildContext context) => CampoSelectorHex(
    etiqueta: etiqueta,
    valor: hora == null ? null : horaTramoHex(hora),
    icono: Icons.schedule,
    ayuda: ayuda,
    alTocar: alElegir == null ? null : () => _elegir(context),
  );
}

const SizedBox _entre = SizedBox(height: Esp.l);

// ═══════════════════════════════════════════════════════════════════════════
// PARÁMETRO
// ═══════════════════════════════════════════════════════════════════════════

class _VigenciaParametroHex extends StatefulWidget {
  const _VigenciaParametroHex({
    required this.repo,
    required this.refrescarLista,
    this.base,
    this.catalogo = const [],
  });

  /// Nula: la primera vigencia de una clave elegida del [catalogo].
  final HexParametroEntity? base;
  final List<HexParametroClaveEntity> catalogo;
  final HexConfiguracionRepository repo;
  final VoidCallback refrescarLista;

  @override
  State<_VigenciaParametroHex> createState() => _VigenciaParametroHexState();
}

class _VigenciaParametroHexState extends State<_VigenciaParametroHex>
    with EscrituraEnDialogoHex {
  /// Parte de la obligatoria que falta, luego de la que no tiene valor.
  late String? _clave =
      widget.base?.clave ??
      (widget.catalogo.where((k) => k.aviso != null).firstOrNull ??
              widget.catalogo.where((k) => !k.tieneVigente).firstOrNull ??
              widget.catalogo.firstOrNull)
          ?.clave;
  late final TextEditingController _valor = TextEditingController(
    text: _numeroEditable(widget.base?.valorNumero),
  );
  late final TextEditingController _leyenda = TextEditingController(
    text: widget.base?.leyenda ?? _elegida?.nombre ?? '',
  );
  late DateTime? _valorFecha = widget.base?.valorFecha;
  late double? _opcion = widget.base?.valorNumero;
  DateTime? _rige;

  /// Los valores de una clave con lista; nula si no aplica, carga o falló, y
  /// entonces el valor se escribe como número.
  List<HexParametroOpcionEntity>? _opciones;
  bool _cargandoOpciones = false;

  bool get _conOpciones => _elegida?.conOpciones ?? false;

  bool get _usaLista => _conOpciones && (_opciones?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  /// Pide la lista de la clave elegida; una respuesta de otra clave se ignora.
  void _cargarOpciones() {
    final clave = _clave;
    _opciones = null;
    _cargandoOpciones = clave != null && _conOpciones;
    if (!_cargandoOpciones) return;
    widget.repo
        .opcionesParametro(clave!)
        .then(
          (l) {
            if (!mounted || clave != _clave) return;
            setState(() {
              _opciones = l;
              _cargandoOpciones = false;
            });
          },
          onError: (Object _) {
            if (!mounted || clave != _clave) return;
            setState(() => _cargandoOpciones = false);
          },
        );
  }

  bool get _nuevo => widget.base == null;

  HexParametroClaveEntity? get _elegida =>
      widget.catalogo.where((k) => k.clave == _clave).firstOrNull;

  bool get _esFecha =>
      _nuevo ? _elegida?.tipoValor == 'FECHA' : widget.base!.valorFecha != null;

  /// Otra clave: el valor se vacía y la leyenda sigue al nombre si no se tocó.
  void _cambiarClave(String? clave) {
    final antes = _elegida?.nombre ?? '';
    setState(() {
      _clave = clave;
      _valor.clear();
      _valorFecha = null;
      _opcion = null;
      _cargarOpciones();
      final t = _leyenda.text.trim();
      if (t.isEmpty || t == antes) _leyenda.text = _elegida?.nombre ?? '';
    });
  }

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  @override
  void dispose() {
    _valor.dispose();
    _leyenda.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final f = await pedirDiaHex(context, inicial: _valorFecha, ayuda: 'Fecha');
    if (f != null && mounted) setState(() => _valorFecha = f);
  }

  // La fila se arma entera: un valor vacío viaja nulo y el SP lo pide.
  void _guardar() {
    final p = HexParametroEntity(
      clave: widget.base?.nuevaVigencia().clave ?? _clave ?? '',
      valorNumero:
          _esFecha
              ? null
              : _usaLista
              ? _opcion
              : numeroEscritoHex(_valor.text),
      valorFecha: _esFecha ? _valorFecha : null,
      leyenda: _leyenda.text.trim(),
      vigenteDesde: _rige,
    );
    escribir((_) => widget.repo.nuevaVigenciaParametro(p));
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    final descripcion = textoUsableHex(_elegida?.descripcion);
    return DialogoHex(
      titulo: _nuevo ? 'Nuevo parámetro' : 'Nueva vigencia',
      icono: _nuevo ? Icons.add_circle_outline : Icons.event_repeat,
      ocupado: ocupado,
      accion: 'Guardar',
      alAceptar: _guardar,
      contenido:
          (enCurso) => [
            if (base != null)
              _CabeceraHex(
                codigo: base.clave,
                texto:
                    'Parte de la vigencia del ${fechaHex(base.vigenteDesde)}.',
              )
            else ...[
              DropdownButtonFormField<String>(
                value: _clave,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Parámetro',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final k in widget.catalogo)
                    DropdownMenuItem(
                      value: k.clave,
                      child: Text(
                        k.tieneVigente ? k.nombre : '${k.nombre} · sin valor',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged:
                    enCurso
                        ? null
                        : (v) {
                          HapticaHex.seleccion();
                          _cambiarClave(v);
                        },
              ),
              if (descripcion != null) ...[
                const SizedBox(height: Esp.s),
                Text(descripcion, style: context.apagado()),
              ],
            ],
            ..._campos(enCurso),
          ],
    );
  }

  List<Widget> _campos(bool enCurso) => [
    _entre,
    if (_esFecha)
      CampoSelectorHex(
        etiqueta: 'Fecha',
        valor: _valorFecha == null ? null : fechaHex(_valorFecha),
        icono: Icons.calendar_today_outlined,
        alTocar: enCurso ? null : _elegirFecha,
      )
    else if (_usaLista)
      _lista(enCurso)
    else if (_cargandoOpciones)
      const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Valor',
          border: OutlineInputBorder(),
        ),
        child: Text('Cargando opciones…'),
      )
    else
      _NumeroHex(
        control: _valor,
        etiqueta: 'Valor',
        habilitado: !enCurso,
        tecla: _siguiente,
      ),
    _entre,
    _TextoHex(
      control: _leyenda,
      etiqueta: 'Leyenda',
      habilitado: !enCurso,
      tecla: _listo(_guardar),
    ),
    _entre,
    _RigeDesdeHex(
      fecha: _rige,
      alElegir: enCurso ? null : (f) => setState(() => _rige = f),
    ),
  ];

  /// El valor elegido por su nombre; debajo, el detalle del SP (su código).
  Widget _lista(bool enCurso) {
    final opciones = _opciones!;
    final elegida = opciones.where((o) => o.valor == _opcion).firstOrNull;
    return DropdownButtonFormField<double>(
      value: elegida?.valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: textoUsableHex(_elegida?.nombre) ?? 'Valor',
        helperText: elegida?.detalle,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final o in opciones)
          DropdownMenuItem(
            value: o.valor,
            child: Text(o.texto, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged:
          enCurso
              ? null
              : (v) {
                HapticaHex.seleccion();
                setState(() => _opcion = v);
              },
    );
  }
}

class _DejarDeUsarHex extends StatefulWidget {
  const _DejarDeUsarHex({
    required this.parametro,
    required this.repo,
    required this.refrescarLista,
  });

  final HexParametroEntity parametro;
  final HexConfiguracionRepository repo;
  final VoidCallback refrescarLista;

  @override
  State<_DejarDeUsarHex> createState() => _DejarDeUsarHexState();
}

class _DejarDeUsarHexState extends State<_DejarDeUsarHex>
    with EscrituraEnDialogoHex {
  final DateTime _hoy = DateUtils.dateOnly(DateTime.now());
  late DateTime _desde = _hoy;

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  /// El calendario empieza hoy: una fecha pasada no se puede elegir.
  Future<void> _elegir() async {
    final f = await pedirDiaHex(
      context,
      inicial: _desde,
      ayuda: 'Deja de usarse desde',
      primero: _hoy,
    );
    if (f != null && mounted) setState(() => _desde = f);
  }

  void _guardar() {
    final id = widget.parametro.idParametro;
    if (id == null) return;
    escribir((_) => widget.repo.dejarDeUsarParametro(id, _desde));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parametro;
    final siFalta = textoUsableHex(p.siFalta);
    const efecto =
        'Desde esa fecha el sistema actuará como si este parámetro no '
        'existiera';
    return DialogoHex(
      titulo: 'Dejar de usar un parámetro',
      icono: Icons.event_busy,
      ocupado: ocupado,
      accion: 'Dejar de usar',
      destructiva: true,
      alAceptar: _guardar,
      contenido:
          (enCurso) => [
            _CabeceraHex(
              codigo: p.clave,
              texto: textoUsableHex(p.nombre) ?? oGuionHex(p.leyenda),
            ),
            _entre,
            CampoSelectorHex(
              etiqueta: 'Deja de usarse desde',
              valor: fechaHex(_desde),
              icono: Icons.event_outlined,
              alTocar: enCurso ? null : _elegir,
            ),
            _entre,
            AvisoHex(
              tono: TonoHex.pendiente,
              icono: Icons.info_outline,
              texto: siFalta == null ? '$efecto.' : '$efecto: $siFalta',
            ),
          ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRAMO
// ═══════════════════════════════════════════════════════════════════════════

class _VigenciaTramoHex extends StatefulWidget {
  const _VigenciaTramoHex({
    required this.base,
    required this.repo,
    required this.refrescarLista,
  });

  /// Nula: un tramo nuevo.
  final HexTramoEntity? base;
  final HexConfiguracionRepository repo;
  final VoidCallback refrescarLista;

  @override
  State<_VigenciaTramoHex> createState() => _VigenciaTramoHexState();
}

/// El mapa del tipo de día sin el cambio, con él (si el tramo está completo)
/// y la fecha en que regiría.
typedef _VistaTramoHex =
    ({
      List<HexTramoMapaEntity> antes,
      List<HexTramoMapaEntity>? despues,
      DateTime? fecha,
    });

class _VigenciaTramoHexState extends State<_VigenciaTramoHex>
    with EscrituraEnDialogoHex {
  late final TextEditingController _codigo = TextEditingController(
    text: widget.base?.codigo ?? '',
  );
  late final TextEditingController _leyenda = TextEditingController(
    text: widget.base?.leyenda ?? '',
  );
  late final TextEditingController _factor = TextEditingController(
    text:
        widget.base == null ? '' : _numeroEditable(widget.base!.multiplicador),
  );
  late String? _tipoDia =
      (widget.base?.tipoDia.isEmpty ?? true) ? null : widget.base!.tipoDia;
  late String? _desde = widget.base?.horaDesde;
  late String? _hasta = widget.base?.horaHasta;
  DateTime? _rige;

  /// Vista previa «Antes / Desde»: se pide 300 ms después del último cambio
  /// y solo vale la respuesta del último pedido.
  Timer? _espera;
  int _pedido = 0;
  _VistaTramoHex? _vista;
  bool _cargandoVista = false;
  bool _vistaFallo = false;

  bool get _nuevo => widget.base == null;

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  @override
  void initState() {
    super.initState();
    _codigo.addListener(_programarVista);
    _programarVista();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _codigo
      ..removeListener(_programarVista)
      ..dispose();
    _leyenda.dispose();
    _factor.dispose();
    super.dispose();
  }

  String get _codigoElegido => widget.base?.codigo ?? _codigo.text.trim();

  void _programarVista() {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 300), _cargarVista);
  }

  /// El mapa del tipo de día en «Rige desde» sin el cambio y, si el tramo
  /// está completo, con él. La app no compara: el SP marca huecos y cruces.
  Future<void> _cargarVista() async {
    final tipo = _tipoDia;
    if (!mounted) return;
    if (tipo == null) {
      setState(() => _vista = null);
      return;
    }
    final pedido = ++_pedido;
    final codigo = _codigoElegido;
    final completo = codigo.isNotEmpty && _desde != null && _hasta != null;
    final fecha = _rige;
    setState(() => _cargandoVista = true);
    try {
      final mapas = await Future.wait([
        widget.repo.mapaTramos(tipoDia: tipo, fecha: fecha),
        if (completo)
          widget.repo.mapaTramos(
            tipoDia: tipo,
            fecha: fecha,
            codigo: codigo,
            horaDesde: _desde,
            horaHasta: _hasta,
          ),
      ]);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _vista = (
          antes: mapas.first,
          despues: completo ? mapas.last : null,
          fecha: fecha,
        );
        _cargandoVista = false;
        _vistaFallo = false;
      });
    } catch (_) {
      // Sin vista previa el formulario sigue: el SP valida al guardar.
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _cargandoVista = false;
        _vistaFallo = true;
      });
    }
  }

  /// Cambia un campo y vuelve a pedir la vista previa.
  void _cambiar(VoidCallback cambio) {
    setState(cambio);
    _programarVista();
  }

  // Lo que falta viaja vacío (factor 0) y el SP responde con su mensaje.
  void _guardar() {
    final b = widget.base?.nuevaVigencia();
    final t = HexTramoEntity(
      codigo: b?.codigo ?? _codigo.text.trim(),
      leyenda: _leyenda.text.trim(),
      tipoDia: _tipoDia ?? '',
      horaDesde: _desde,
      horaHasta: _hasta,
      multiplicador: numeroEscritoHex(_factor.text) ?? 0,
      orden: b?.orden,
      vigenteDesde: _rige,
    );
    // Si deja huecos o cruces el SP pregunta y se reenvía confirmado.
    escribir((c) => widget.repo.nuevaVigenciaTramo(t, confirmado: c));
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    return DialogoHex(
      titulo: _nuevo ? 'Nuevo tramo' : 'Nueva vigencia',
      icono: _nuevo ? Icons.add_alarm_outlined : Icons.event_repeat,
      ocupado: ocupado,
      accion: 'Guardar',
      alAceptar: _guardar,
      contenido:
          (enCurso) => [
            if (base != null) ...[
              _CabeceraHex(
                codigo: base.codigo,
                texto:
                    'Parte de la vigencia del ${fechaHex(base.vigenteDesde)}.',
              ),
              _entre,
            ],
            DropdownButtonFormField<String>(
              value: _tipoDia,
              isExpanded: true,
              // Deshabilitado, el menú solo muestra esta pista.
              disabledHint:
                  _tipoDia == null ? null : Text(tipoDiaHex(_tipoDia!)),
              decoration: const InputDecoration(
                labelText: 'Tipo de día',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final MapEntry(key: codigo, value: texto)
                    in tiposDiaHex.entries)
                  DropdownMenuItem(value: codigo, child: Text(texto)),
              ],
              // En una vigencia nueva el tipo de día y el código no cambian.
              onChanged:
                  enCurso || !_nuevo
                      ? null
                      : (v) {
                        HapticaHex.seleccion();
                        _cambiar(() => _tipoDia = v);
                      },
            ),
            if (_nuevo) ...[
              _entre,
              _TextoHex(
                control: _codigo,
                etiqueta: 'Código',
                habilitado: !enCurso,
                tecla: _siguiente,
                mayusculas: true,
              ),
            ],
            _entre,
            _TextoHex(
              control: _leyenda,
              etiqueta: 'Leyenda',
              habilitado: !enCurso,
              tecla: _siguiente,
            ),
            _entre,
            _HoraHex(
              etiqueta: 'Hora desde',
              hora: _desde,
              alElegir: enCurso ? null : (h) => _cambiar(() => _desde = h),
            ),
            _entre,
            _HoraHex(
              etiqueta: 'Hora hasta',
              hora: _hasta,
              ayuda:
                  'La hora de fin no se incluye: el tramo siguiente empieza '
                  'a esa misma hora. 00:00 = 24:00 (fin del día).',
              alElegir: enCurso ? null : (h) => _cambiar(() => _hasta = h),
            ),
            _entre,
            _NumeroHex(
              control: _factor,
              etiqueta: 'Factor',
              habilitado: !enCurso,
              tecla: _listo(_guardar),
              ayuda: 'Veces el costo hora, con coma: 1,5 paga hora y media.',
            ),
            _entre,
            _RigeDesdeHex(
              fecha: _rige,
              ayuda:
                  'Hasta el día anterior se paga con lo de antes; desde esta '
                  'fecha, con lo nuevo. Lo ya pagado no cambia.',
              alElegir: enCurso ? null : (f) => _cambiar(() => _rige = f),
            ),
            // En una ventana angosta la vista previa va bajo el formulario.
            if (!dialogoDobleHex(context)) ...[
              _entre,
              const Divider(height: 1),
              _entre,
              _vistaPrevia(),
            ],
          ],
      lateral:
          (_) => SingleChildScrollView(primary: false, child: _vistaPrevia()),
    );
  }

  /// «Antes» y «Desde dd/mm/yyyy»: el día del tipo elegido sin y con el
  /// cambio, con la franja de comidas y los huecos y cruces que dejaría.
  Widget _vistaPrevia() {
    final vista = _vista;
    final t = Theme.of(context).textTheme;
    Widget rotulo(String texto) => Padding(
      padding: const EdgeInsets.only(top: Esp.m, bottom: Esp.xs),
      child: Text(
        texto,
        style: t.labelLarge?.copyWith(fontWeight: Peso.titulo),
      ),
    );
    final pista = switch ((vista, _tipoDia)) {
      (_, null) => 'Elige el tipo de día para ver cómo queda.',
      _ when _vistaFallo => 'No se pudo cargar la vista previa.',
      (null, _) => 'Cargando…',
      _ => null,
    };
    final cuerpo = <Widget>[
      if (pista != null)
        Padding(
          padding: const EdgeInsets.only(top: Esp.s),
          child: Text(pista, style: context.apagado()),
        )
      else if (vista != null) ...[
        rotulo('Antes'),
        // Las comidas (las mismas en esa fecha) van bajo «Desde» si lo hay.
        BarraDiaHex(
          vista.antes,
          tonos: tonosMapaHex([...vista.antes, ...?vista.despues]),
          alto: 28,
          conComidas: vista.despues == null,
        ),
        rotulo(
          vista.fecha == null
              ? 'Con el cambio'
              : 'Desde ${fechaHex(vista.fecha)}',
        ),
        if (vista.despues case final despues?) ...[
          BarraDiaHex(
            despues,
            tonos: tonosMapaHex([...vista.antes, ...despues]),
            alto: 28,
          ),
          ProblemasMapaHex(despues),
        ] else
          Text(
            'Completa el código y las horas para verlo.',
            style: context.apagado(),
          ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TituloSeccionHex(
                'Cómo queda el día',
                icono: Icons.view_timeline_outlined,
              ),
            ),
            if (_cargandoVista)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        ...cuerpo,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMIDA
// ═══════════════════════════════════════════════════════════════════════════

class _VigenciaComidaHex extends StatefulWidget {
  const _VigenciaComidaHex({
    required this.base,
    required this.repo,
    required this.refrescarLista,
  });

  /// Nula: una comida nueva.
  final HexComidaEntity? base;
  final HexConfiguracionRepository repo;
  final VoidCallback refrescarLista;

  @override
  State<_VigenciaComidaHex> createState() => _VigenciaComidaHexState();
}

/// Cómo se guarda la comida: una vigencia que rige desde una fecha, o otra
/// configuración solo en un período, también hacia atrás (D40).
enum _ModoComidaHex { vigencia, periodo }

class _VigenciaComidaHexState extends State<_VigenciaComidaHex>
    with EscrituraEnDialogoHex {
  late final TextEditingController _codigo = TextEditingController(
    text: widget.base?.codigo ?? '',
  );
  late final TextEditingController _leyenda = TextEditingController(
    text: widget.base?.leyenda ?? '',
  );
  late final TextEditingController _codigoDoble = TextEditingController(
    text: widget.base?.codigoDoble ?? '',
  );
  late final TextEditingController _leyendaDoble = TextEditingController(
    text: widget.base?.leyendaDoble ?? '',
  );
  late final TextEditingController _monto = TextEditingController(
    text: _numeroEditable(widget.base?.monto),
  );
  late final TextEditingController _montoDoble = TextEditingController(
    text: _numeroEditable(widget.base?.montoDoble),
  );
  late final TextEditingController _minutosSimple = TextEditingController(
    text: widget.base?.minutosSimple?.toString() ?? '',
  );
  late final TextEditingController _minutosDoble = TextEditingController(
    text: widget.base?.minutosDoble?.toString() ?? '',
  );
  late String? _desde = widget.base?.horaDesde;
  late String? _hasta = widget.base?.horaHasta;
  late bool _activa = widget.base?.activo ?? true;
  late bool _conDoble = widget.base?.conDoble ?? true;
  _ModoComidaHex _modo = _ModoComidaHex.vigencia;

  bool get _nuevo => widget.base == null;

  /// Sin minutos, el SP pone los de la vigencia anterior; en una nueva, 60.
  String get _ayudaMinutos =>
      _nuevo ? 'Vacío: 60 min.' : 'Vacío: el de la vigencia anterior.';

  /// «Rige desde» de la vigencia, o el primer día del período.
  DateTime? _rige;

  /// El último día del período; nulo: rige sin fin.
  DateTime? _hastaPeriodo;

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  @override
  void dispose() {
    _codigo.dispose();
    _leyenda.dispose();
    _codigoDoble.dispose();
    _leyendaDoble.dispose();
    _monto.dispose();
    _montoDoble.dispose();
    _minutosSimple.dispose();
    _minutosDoble.dispose();
    super.dispose();
  }

  /// Minutos escritos; lo vacío o lo que no es un entero viaja nulo y el SP
  /// pone el de la vigencia anterior o responde con su mensaje.
  static int? _minutos(TextEditingController c) => int.tryParse(c.text.trim());

  // Montos vacíos viajan nulos y el SP los pide; sin doble, sus datos viajan
  // vacíos y el SP los completa. `activo` y `conDoble` viajan siempre.
  void _guardar() {
    final b = widget.base?.nuevaVigencia();
    final doble = _conDoble;
    final c = HexComidaEntity(
      codigo: b?.codigo ?? _codigo.text.trim(),
      leyenda: _leyenda.text.trim(),
      codigoDoble: doble ? _codigoDoble.text.trim() : '',
      leyendaDoble: doble ? _leyendaDoble.text.trim() : '',
      horaDesde: _desde,
      horaHasta: _hasta,
      monto: numeroEscritoHex(_monto.text),
      montoDoble: doble ? numeroEscritoHex(_montoDoble.text) : null,
      activo: _activa,
      orden: b?.orden,
      vigenteDesde: _rige,
      conDoble: _conDoble,
      minutosSimple: _minutos(_minutosSimple),
      minutosDoble: doble ? _minutos(_minutosDoble) : null,
    );
    final periodo = _modo == _ModoComidaHex.periodo;
    final hasta = _hastaPeriodo;
    escribir(
      (_) =>
          periodo
              ? widget.repo.periodoComida(c, hasta: hasta)
              : widget.repo.nuevaVigenciaComida(c),
    );
  }

  Future<void> _elegirDesdePeriodo() async {
    final elegida = await pedirDiaHex(
      context,
      inicial: _rige,
      ayuda: 'Primer día del período',
    );
    if (elegida != null && mounted) setState(() => _rige = elegida);
  }

  Future<void> _elegirHastaPeriodo() async {
    final elegida = await pedirDiaHex(
      context,
      inicial: _hastaPeriodo ?? _rige,
      ayuda: 'Último día del período',
    );
    if (elegida != null && mounted) setState(() => _hastaPeriodo = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    final periodo = _modo == _ModoComidaHex.periodo;
    return DialogoHex(
      titulo:
          _nuevo
              ? 'Nueva comida'
              : periodo
              ? 'Configuración por período'
              : 'Nueva vigencia',
      icono:
          _nuevo
              ? Icons.add_circle_outline
              : periodo
              ? Icons.date_range_outlined
              : Icons.event_repeat,
      ocupado: ocupado,
      accion: 'Guardar',
      alAceptar: _guardar,
      contenido:
          (enCurso) => [
            // Una comida nueva no tiene período: primero existe con una vigencia.
            if (base == null)
              _TextoHex(
                control: _codigo,
                etiqueta: 'Código',
                habilitado: !enCurso,
                tecla: _siguiente,
                mayusculas: true,
              )
            else ...[
              _CabeceraHex(
                codigo: base.codigo,
                texto:
                    'Parte de la vigencia del ${fechaHex(base.vigenteDesde)}.',
              ),
              _entre,
              SegmentedButton<_ModoComidaHex>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _ModoComidaHex.vigencia,
                    label: Text(
                      'Desde una fecha',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ButtonSegment(
                    value: _ModoComidaHex.periodo,
                    label: Text('Un período', overflow: TextOverflow.ellipsis),
                  ),
                ],
                selected: {_modo},
                onSelectionChanged:
                    enCurso
                        ? null
                        : (s) {
                          HapticaHex.seleccion();
                          setState(() => _modo = s.first);
                        },
              ),
              const SizedBox(height: Esp.xs),
              Text(
                periodo
                    ? 'Rige solo entre esas fechas, también pasadas; después '
                        'vuelve la vigencia anterior. Lo ya pagado no cambia.'
                    : 'Rige desde esa fecha y cierra la vigencia anterior.',
                style: context.apagado(),
              ),
              // El período va primero: es lo que se está decidiendo.
              if (periodo) ...[
                _entre,
                CampoSelectorHex(
                  etiqueta: 'Primer día del período',
                  valor: _rige == null ? null : fechaHex(_rige),
                  pista: 'Elige el primer día',
                  icono: Icons.event_outlined,
                  ayuda: 'Puede ser una fecha pasada.',
                  alTocar: enCurso ? null : _elegirDesdePeriodo,
                ),
                _entre,
                CampoSelectorHex(
                  etiqueta: 'Último día (opcional)',
                  valor: _hastaPeriodo == null ? null : fechaHex(_hastaPeriodo),
                  pista: 'Sin fin',
                  icono: Icons.event_outlined,
                  ayuda: 'Sin fecha, rige sin fin.',
                  alTocar: enCurso ? null : _elegirHastaPeriodo,
                  alQuitar:
                      enCurso
                          ? null
                          : () => setState(() => _hastaPeriodo = null),
                ),
              ],
            ],
            _entre,
            _TextoHex(
              control: _leyenda,
              etiqueta: 'Leyenda',
              habilitado: !enCurso,
              tecla: _siguiente,
            ),
            _entre,
            _NumeroHex(
              control: _monto,
              etiqueta: 'Monto',
              enBs: true,
              habilitado: !enCurso,
              tecla: _siguiente,
            ),
            _entre,
            _MinutosHex(
              control: _minutosSimple,
              etiqueta: 'Minutos para ganar la comida',
              habilitado: !enCurso,
              ayuda: _ayudaMinutos,
            ),
            const SizedBox(height: Esp.s),
            SwitchListTile(
              value: _conDoble,
              contentPadding: EdgeInsets.zero,
              title: const Text('Paga la comida doble'),
              subtitle: const Text(
                'Sin doble, el tiempo que sigue se paga como hora extra.',
              ),
              onChanged:
                  enCurso
                      ? null
                      : (v) {
                        HapticaHex.toque();
                        setState(() => _conDoble = v);
                      },
            ),
            // Sin doble sus datos no se piden: el SP los completa y no se pagan.
            if (_conDoble) ...[
              _entre,
              _TextoHex(
                control: _codigoDoble,
                etiqueta: 'Código doble',
                habilitado: !enCurso,
                tecla: _siguiente,
                mayusculas: true,
              ),
              _entre,
              _TextoHex(
                control: _leyendaDoble,
                etiqueta: 'Leyenda doble',
                habilitado: !enCurso,
                tecla: _siguiente,
              ),
              _entre,
              _NumeroHex(
                control: _montoDoble,
                etiqueta: 'Monto doble',
                enBs: true,
                habilitado: !enCurso,
                tecla: _listo(_guardar),
                ayuda:
                    'Lo que paga la doble en total: reemplaza al monto simple.',
              ),
              _entre,
              _MinutosHex(
                control: _minutosDoble,
                etiqueta: 'Minutos para ganar la doble',
                habilitado: !enCurso,
                ayuda: _ayudaMinutos,
              ),
            ],
            _entre,
            Text('Horario de la comida', style: context.tituloSeccion()),
            const SizedBox(height: Esp.xs),
            Text(
              'Se gana si las horas extra empiezan dentro de este horario. '
              'Obligatorio si la comida está activa.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.s),
            _HoraHex(
              etiqueta: 'Desde',
              hora: _desde,
              alElegir: enCurso ? null : (h) => setState(() => _desde = h),
            ),
            _entre,
            _HoraHex(
              etiqueta: 'Hasta',
              hora: _hasta,
              alElegir: enCurso ? null : (h) => setState(() => _hasta = h),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed:
                    enCurso || (_desde == null && _hasta == null)
                        ? null
                        : () => setState(() => _desde = _hasta = null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Sin horario'),
              ),
            ),
            SwitchListTile(
              value: _activa,
              contentPadding: EdgeInsets.zero,
              title: const Text('Activa'),
              onChanged:
                  enCurso
                      ? null
                      : (v) {
                        HapticaHex.toque();
                        setState(() => _activa = v);
                      },
            ),
            _entre,
            if (!periodo)
              _RigeDesdeHex(
                fecha: _rige,
                alElegir: enCurso ? null : (f) => setState(() => _rige = f),
              ),
          ],
    );
  }
}

/// Minutos enteros (1 a 600 los valida el SP); [ayuda] dice qué pasa si
/// quedan vacíos.
class _MinutosHex extends StatelessWidget {
  const _MinutosHex({
    required this.control,
    required this.etiqueta,
    required this.habilitado,
    required this.ayuda,
  });

  final TextEditingController control;
  final String etiqueta;
  final bool habilitado;
  final String ayuda;

  @override
  Widget build(BuildContext context) => TextField(
    controller: control,
    enabled: habilitado,
    textInputAction: TextInputAction.next,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: context.numero(fuerte: true),
    decoration: InputDecoration(
      labelText: etiqueta,
      suffixText: 'min',
      helperText: ayuda,
      helperMaxLines: 2,
      border: const OutlineInputBorder(),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// LEYENDA
// ═══════════════════════════════════════════════════════════════════════════

class _EditarLeyendaHex extends StatefulWidget {
  const _EditarLeyendaHex({
    required this.codigo,
    required this.leyenda,
    required this.etiqueta,
    required this.guardar,
    required this.refrescarLista,
  });

  final String codigo;
  final String leyenda;
  final String etiqueta;
  final Future<HexRespuesta> Function(String leyenda) guardar;
  final VoidCallback refrescarLista;

  @override
  State<_EditarLeyendaHex> createState() => _EditarLeyendaHexState();
}

class _EditarLeyendaHexState extends State<_EditarLeyendaHex>
    with EscrituraEnDialogoHex {
  late final TextEditingController _leyenda = TextEditingController(
    text: widget.leyenda,
  );

  @override
  VoidCallback get refrescarLista => widget.refrescarLista;

  @override
  void dispose() {
    _leyenda.dispose();
    super.dispose();
  }

  void _guardar() => escribir((_) => widget.guardar(_leyenda.text.trim()));

  @override
  Widget build(BuildContext context) => DialogoHex(
    titulo: 'Editar ${widget.etiqueta.toLowerCase()}',
    icono: Icons.edit_note,
    ocupado: ocupado,
    accion: 'Guardar',
    alAceptar: _guardar,
    contenido:
        (enCurso) => [
          _CabeceraHex(
            codigo: widget.codigo,
            texto: 'Cambia solo el texto; el valor y la vigencia no cambian.',
          ),
          _entre,
          _TextoHex(
            control: _leyenda,
            etiqueta: widget.etiqueta,
            habilitado: !enCurso,
            tecla: _listo(_guardar),
            autofocus: true,
          ),
        ],
  );
}
