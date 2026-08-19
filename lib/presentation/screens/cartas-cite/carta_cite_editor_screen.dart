import 'package:bosque_flutter/core/state/cartas_cite_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/editor_cuerpo_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/html_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/identidad_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/listas_editables_cite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Redacción de un documento CITE.
///
/// **El formulario cambia de forma según el tipo.** Una carta lleva ciudad,
/// destinatario escrito a mano y referencia; un memorando elige al destinatario
/// de la planilla y lleva asunto; el certificado de trabajo no lleva
/// destinatario y su área la fija el sistema. Esas reglas viven en [TipoCite]
/// y no repartidas por la pantalla, que es lo que hacía el JSF con veintitantos
/// `rendered="#{...idTipoDoc == 1 or ...}"` copiados campo por campo.
///
/// **El número de CITE que se ve arriba es una previsualización.** El definitivo
/// lo asigna la base dentro de la transacción del guardado; si alguien guardó
/// primero, el mensaje de confirmación trae el número real.
class CartaCiteEditorScreen extends ConsumerStatefulWidget {
  /// Documento a editar o duplicar. Para uno nuevo, viene de
  /// [CartaCiteEntity.nuevo].
  final CartaCiteEntity original;

  /// Sólo lectura: un documento anulado, o de otro usuario sin permiso.
  final bool soloLectura;

  const CartaCiteEditorScreen({
    super.key,
    required this.original,
    this.soloLectura = false,
  });

  @override
  ConsumerState<CartaCiteEditorScreen> createState() => _CartaCiteEditorScreenState();
}

class _CartaCiteEditorScreenState extends ConsumerState<CartaCiteEditorScreen> {
  late CartaCiteEntity _doc;

  final _ciudad = TextEditingController();
  final _dirigido = TextEditingController();
  final _cargoDirigido = TextEditingController();
  final _referencia = TextEditingController();
  final _asunto = TextEditingController();
  final _via = TextEditingController();
  final _cargoVia = TextEditingController();
  final _cuerpo = TextEditingController();

  /// Controladores de las listas. Se mantienen en paralelo a las entidades
  /// porque un `TextEditingController` por fila es lo único que conserva el
  /// cursor al reconstruir.
  final List<TextEditingController> _ctrlCopias = [];
  final List<List<TextEditingController>> _ctrlDestinatarios = [];
  final List<List<TextEditingController>> _ctrlRemitentes = [];

  /// Ids de hijos que había en la base y el usuario quitó. El backend los
  /// necesita explícitos: no infiere las bajas comparando contra la BD.
  final List<BigInt> _copiasAEliminar = [];
  final List<BigInt> _destinatariosAEliminar = [];
  final List<BigInt> _remitentesAEliminar = [];

  GestionCiteEntity? _preview;
  bool _guardando = false;

  /// Si ya se intentó guardar al menos una vez.
  ///
  /// Los campos obligatorios recién se pintan de rojo después del primer
  /// intento. Un formulario que se abre vacío está vacío por definición;
  /// recibir al usuario con cinco errores en rojo no le informa nada y hace
  /// ver rota una pantalla recién abierta.
  bool _intentoGuardar = false;
  bool _cargandoCite = false;

  /// Huella de la lista de pendientes. Ver [_vigilar].
  String _clave = '';

  int get _uid => ref.read(userProvider)?.codUsuario ?? 0;
  int get _tipo => _doc.tipoDoc;
  bool get _bloqueado => widget.soloLectura || _doc.anulado;

  @override
  void initState() {
    super.initState();
    _doc = widget.original;

    _ciudad.text = _doc.ciudad;
    _referencia.text = _sinNa(_doc.referencia);
    _asunto.text = _sinNa(_doc.asunto);
    _via.text = _doc.via;
    _cargoVia.text = _doc.cargoVia;
    _cuerpo.text = _doc.cuerpo;

    // En la COM. CI el destinatario se guarda en empleadoDe/cargoDe, así que
    // al editar hay que traerlo de vuelta al campo que ve el usuario.
    if (TipoCite.destinatarioEsRemite(_tipo) && _doc.empleadoDe.isNotEmpty) {
      _dirigido.text = _sinNa(_doc.empleadoDe);
      _cargoDirigido.text = _sinNa(_doc.cargoDe);
    } else {
      _dirigido.text = _sinNa(_doc.dirigido);
      _cargoDirigido.text = _sinNa(_doc.cargoDirigido);
    }

    for (final c in _doc.copiasArchivo) {
      _ctrlCopias.add(TextEditingController(text: c.copiaArch));
    }
    for (final d in _doc.destinatarios) {
      _ctrlDestinatarios.add([
        TextEditingController(text: d.copiaEnca),
        TextEditingController(text: d.cargoCopia),
      ]);
    }
    for (final r in _doc.remitentes) {
      _ctrlRemitentes.add([
        _ctrlVigilado(r.remitente),
        TextEditingController(text: r.cargoRemitente),
      ]);
    }

    _cuerpo.addListener(_vigilar);
    _dirigido.addListener(_vigilar);
    _referencia.addListener(_vigilar);
    _asunto.addListener(_vigilar);
    _clave = _clavePendientes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_doc.esNuevo) {
        _cargarPreviewCite();
        _precargarFirma();
      }
    });
  }

  /// Un controlador que avisa cuando cambia lo que falta para guardar.
  ///
  /// Se usa sólo en los campos que participan de la validación: el cuerpo, el
  /// destinatario escrito a mano, la referencia, el asunto y el nombre de cada
  /// firmante.
  TextEditingController _ctrlVigilado([String texto = '']) =>
      TextEditingController(text: texto)..addListener(_vigilar);

  /// Se vuelve a dibujar **sólo cuando cambia la lista de pendientes**, no en
  /// cada tecla.
  ///
  /// Un `setState` por pulsación reconstruiría el editor de cuerpo entero —con
  /// su vista previa al lado— mientras alguien escribe una carta de dos
  /// páginas. Comparar la clave cuesta una concatenación de seis palabras.
  void _vigilar() {
    final nueva = _clavePendientes();
    if (nueva != _clave) setState(() => _clave = nueva);
  }

  String _clavePendientes() => _pendientes().map((p) => p.corto).join('|');

  /// El SP guarda 'N/A' en los campos que el tipo no usa. Mostrarlo en un
  /// input haría que al editar quede escrito literalmente "N/A".
  String _sinNa(String v) => v.trim().toUpperCase() == 'N/A' ? '' : v;

  @override
  void dispose() {
    for (final c in [
      _ciudad, _dirigido, _cargoDirigido, _referencia,
      _asunto, _via, _cargoVia, _cuerpo,
    ]) {
      c.dispose();
    }
    for (final c in _ctrlCopias) {
      c.dispose();
    }
    for (final fila in [..._ctrlDestinatarios, ..._ctrlRemitentes]) {
      for (final c in fila) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _cargarPreviewCite() async {
    setState(() => _cargandoCite = true);
    try {
      final g = await ref.read(cartasCiteRepositoryProvider).siguienteCite(
            idTipoDoc: _tipo,
            codEmpresa: _doc.codEmpresa.toInt(),
          );
      if (mounted) setState(() => _preview = g);
    } catch (_) {
      // Sin previsualización se puede redactar igual; el número lo pone la base.
    } finally {
      if (mounted) setState(() => _cargandoCite = false);
    }
  }

  /// El primer remitente es quien redacta. El módulo viejo hacía lo mismo.
  Future<void> _precargarFirma() async {
    if (_ctrlRemitentes.isNotEmpty) return;
    final firma = await ref.read(firmaUsuarioCiteProvider(_uid).future);
    if (!mounted || firma == null) return;
    setState(() {
      _ctrlRemitentes.add([
        _ctrlVigilado(firma.nombreCompleto),
        TextEditingController(text: firma.cargo),
      ]);
    });
  }

  // ── validación y guardado ───────────────────────────────────────────────

  /// Lo que falta para poder guardar, en el orden en que aparece en el
  /// formulario. Lista vacía = listo.
  ///
  /// **Por qué es una lista y no el primer error.** Antes esto vivía adentro de
  /// `_validar` y devolvía un `String`: el usuario apretaba Guardar, se
  /// enteraba de que faltaba el área, la elegía, volvía a apretar y se enteraba
  /// de que faltaba el remitente. De a un problema por vez y siempre después de
  /// intentar. Ahora la barra de abajo muestra los que quedan, mientras escribe.
  ///
  /// El texto corto es para esa barra; el largo, para el aviso al guardar.
  List<({String corto, String largo})> _pendientes() {
    final falta = <({String corto, String largo})>[];

    if (TipoCite.usaArea(_tipo) && _doc.area.trim().isEmpty) {
      falta.add((
        corto: 'el área',
        largo: 'Seleccioná el área que emite el documento.',
      ));
    }
    if (_doc.codEmpresa.toInt() <= 0) {
      falta.add((corto: 'la empresa', largo: 'Seleccioná la empresa.'));
    }
    if (TipoCite.destinatarioLibre(_tipo) && _dirigido.text.trim().isEmpty) {
      falta.add((
        corto: 'el destinatario',
        largo: 'Indicá a quién va dirigido el documento.',
      ));
    }
    if (TipoCite.destinatarioEmpleado(_tipo) && _doc.codEmpleado.toInt() == 0) {
      falta.add((corto: 'el destinatario', largo: 'Seleccioná el destinatario.'));
    }
    /* Referencia y asunto son obligatorios según el tipo, igual que el resto:
       cada formato imprime uno u otro, nunca los dos. De los 781 documentos
       históricos sólo 6 salieron sin ese campo, así que exigirlo no cambia la
       forma en que se usa el módulo, sólo evita el olvido. */
    if (TipoCite.usaReferencia(_tipo) && _referencia.text.trim().isEmpty) {
      falta.add((
        corto: 'la referencia',
        largo: 'Escribí la referencia: la línea que resume de qué trata.',
      ));
    }
    if (TipoCite.usaAsunto(_tipo) && _asunto.text.trim().isEmpty) {
      falta.add((corto: 'el asunto', largo: 'Escribí el asunto del documento.'));
    }
    if (normalizarCuerpo(_cuerpo.text).isEmpty) {
      falta.add((
        corto: 'el contenido',
        largo: 'El documento no puede quedar sin contenido.',
      ));
    }
    if (_ctrlRemitentes.isEmpty ||
        _ctrlRemitentes.every((f) => f[0].text.trim().isEmpty)) {
      falta.add((
        corto: 'quién firma',
        largo: 'El documento tiene que llevar al menos un remitente que lo firme.',
      ));
    }

    return falta;
  }

  String? _validar() => _pendientes().map((p) => p.largo).firstOrNull;

  /// El texto rojo debajo de un campo obligatorio vacío, o `null` si todavía
  /// no corresponde mostrarlo. Ver [_intentoGuardar].
  String? _errorSi(bool falta, String mensaje) =>
      _intentoGuardar && falta ? mensaje : null;

  /// Cuelga el aviso debajo de un bloque que no es un input y por lo tanto no
  /// tiene `errorText` propio: el cuerpo y la lista de firmantes.
  Widget _conAviso(Widget hijo, String? mensaje) {
    if (mensaje == null) return hijo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hijo,
        SizedBox(height: Esp.s),
        _CampoError(mensaje: mensaje),
      ],
    );
  }

  Future<void> _guardar() async {
    final error = _validar();
    if (error != null) {
      setState(() => _intentoGuardar = true);
      _avisar(error, esError: true);
      return;
    }

    setState(() => _guardando = true);

    _doc
      ..ciudad = _ciudad.text.trim()
      ..referencia = _referencia.text.trim()
      ..asunto = _asunto.text.trim()
      ..via = _via.text.trim()
      ..cargoVia = _cargoVia.text.trim()
      ..cuerpo = normalizarCuerpo(_cuerpo.text)
      ..dirigido = _dirigido.text.trim()
      ..cargoDirigido = _cargoDirigido.text.trim()
      ..copiasArchivo = [
        for (var i = 0; i < _ctrlCopias.length; i++)
          CopiaArchEntity(
            idCopiaArch: i < _doc.copiasArchivo.length
                ? _doc.copiasArchivo[i].idCopiaArch
                : BigInt.zero,
            copiaArch: _ctrlCopias[i].text.trim(),
          ),
      ]
      ..destinatarios = [
        for (var i = 0; i < _ctrlDestinatarios.length; i++)
          CopiaEncabezadoEntity(
            idCopiaEncab: i < _doc.destinatarios.length
                ? _doc.destinatarios[i].idCopiaEncab
                : BigInt.zero,
            copiaEnca: _ctrlDestinatarios[i][0].text.trim(),
            cargoCopia: _ctrlDestinatarios[i][1].text.trim(),
          ),
      ]
      ..remitentes = [
        for (var i = 0; i < _ctrlRemitentes.length; i++)
          RemitenteEntity(
            idRemitente: i < _doc.remitentes.length
                ? _doc.remitentes[i].idRemitente
                : BigInt.zero,
            remitente: _ctrlRemitentes[i][0].text.trim(),
            cargoRemitente: _ctrlRemitentes[i][1].text.trim(),
          ),
      ];

    try {
      final msg = await ref.read(cartasCiteProvider(_uid).notifier).guardar(
            _doc,
            copiasAEliminar: _copiasAEliminar,
            destinatariosAEliminar: _destinatariosAEliminar,
            remitentesAEliminar: _remitentesAEliminar,
          );
      if (!mounted) return;
      Navigator.of(context).pop(msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _avisar(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''), esError: true);
    }
  }

  void _avisar(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: esError ? Theme.of(context).colorScheme.error : Colors.green,
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: Esp.s,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelloTipoCite(idTipoDoc: _tipo, tipo: _doc.tipo, lado: 32),
            SizedBox(width: Esp.m),
            Flexible(
              child: Text(
                _doc.esNuevo
                    ? 'Nuevo ${_doc.tipo.isEmpty ? "documento" : _doc.tipo.toLowerCase()}'
                    : '${_doc.tipo} ${_doc.cite}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      // Guardar vive abajo y en un solo lugar. Estaba arriba a la derecha, que
      // en un teléfono es la esquina más lejos del pulgar, y en un formulario
      // de seis bloques obliga a subir hasta el final para terminar.
      bottomNavigationBar: _bloqueado
          ? null
          : _BarraGuardar(
              pendientes: _pendientes().map((p) => p.corto).toList(),
              guardando: _guardando,
              onGuardar: _guardar,
            ),
      body: LayoutBuilder(
        builder: (context, cons) {
          final aire = Aire.de(cons.maxWidth);
          final ancho = aire == Aire.amplio ? 1100.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ancho),
              child: ListView(
                padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.xl),
                children: [
                  if (_doc.anulado) _AvisoAnulado(),
                  _encabezado(aire),
                  SizedBox(height: Esp.l),
                  _destinatario(aire),
                  SizedBox(height: Esp.l),
                  _asuntoYReferencia(aire),
                  _seccion(
                    'Contenido',
                    'Es el texto que sale impreso en el cuerpo del documento.',
                    Icons.article_outlined,
                    _conAviso(
                      EditorCuerpoCite(
                        controller: _cuerpo,
                        soloLectura: _bloqueado,
                        alto: aire.esChico ? 320 : 420,
                      ),
                      _errorSi(
                        normalizarCuerpo(_cuerpo.text).isEmpty,
                        'El documento no puede quedar sin contenido.',
                      ),
                    ),
                  ),
                  SizedBox(height: Esp.l),
                  _listaDestinatariosExtra(),
                  SizedBox(height: Esp.l),
                  _listaRemitentes(),
                  SizedBox(height: Esp.l),
                  _listaCopiasArchivo(),
                  SizedBox(height: Esp.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _seccion(String titulo, String detalle, IconData icono, Widget hijo) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      padding: EdgeInsets.all(Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: cs.onSurfaceVariant),
              SizedBox(width: Esp.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: context.tituloSeccion()),
                    Text(detalle, style: context.apagado()),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Esp.m),
          hijo,
        ],
      ),
    );
  }

  /// Empresa, área, fecha y el CITE que va a llevar.
  Widget _encabezado(Aire aire) {
    final areasAsync = ref.watch(areasCiteProvider(_doc.codEmpresa.toInt()));

    final campoArea = TipoCite.usaArea(_tipo)
        ? areasAsync.when(
            loading: () => const _CampoCargando(etiqueta: 'Área'),
            error: (e, _) => _CampoError(mensaje: 'No se pudieron cargar las áreas'),
            data: (areas) {
              // El valor guardado puede no estar en el catálogo actual (un área
              // dada de baja). Sin esta comprobación el Dropdown revienta.
              final valor = areas.any((a) => a.siglas == _doc.area.trim())
                  ? _doc.area.trim()
                  : null;
              return DropdownButtonFormField<String>(
                value: valor,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Área que emite *',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _errorSi(
                    _doc.area.trim().isEmpty,
                    'Elegí el área que emite.',
                  ),
                ),
                items: areas
                    .map((a) => DropdownMenuItem(
                          value: a.siglas,
                          child: Text(a.etiqueta, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _bloqueado
                    ? null
                    : (v) => setState(() => _doc.area = v ?? ''),
              );
            },
          )
        : const _CampoFijo(etiqueta: 'Área', valor: 'G.A. (la fija el sistema)');

    final campoFecha = InkWell(
      onTap: _bloqueado
          ? null
          : () async {
              final elegida = await showDatePicker(
                context: context,
                initialDate: _doc.fechaDoc ?? DateTime.now(),
                firstDate: DateTime(2018),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (elegida != null) setState(() => _doc.fechaDoc = elegida);
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha del documento',
          border: OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_doc.fechaDoc ?? DateTime.now())),
      ),
    );

    final campoCiudad = TipoCite.usaCiudad(_tipo)
        ? TextField(
            controller: _ciudad,
            readOnly: _bloqueado,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          )
        : null;

    return _seccion(
      'Encabezado',
      _doc.esNuevo
          ? 'El número definitivo se asigna al guardar.'
          : 'El número ya fue emitido y no cambia.',
      Icons.description_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChipCite(
            cite: _doc.esNuevo
                ? _citePrevisto()
                : (_doc.cite.isEmpty ? '—' : _doc.cite),
            empresa: _doc.empresa,
            tipo: _doc.tipo,
            idTipoDoc: _tipo,
            provisorio: _doc.esNuevo,
            cargando: _cargandoCite,
          ),
          SizedBox(height: Esp.m),
          _grilla(aire, [
            campoArea,
            campoFecha,
            if (campoCiudad != null) campoCiudad,
          ]),
        ],
      ),
    );
  }

  String _citePrevisto() {
    final area = _doc.area.trim().isEmpty ? '—' : _doc.area.trim();
    if (_preview == null) return '$area/…';
    final nro = _preview!.nroCite.toString().padLeft(3, '0');
    return '$area/$nro/${_preview!.gestion}';
  }

  /// A quién va dirigido. Cambia entero según el tipo.
  Widget _destinatario(Aire aire) {
    if (_tipo == TipoCite.certificadoTrabajo) {
      return _seccion(
        'Destinatario',
        'El certificado de trabajo no lleva destinatario.',
        Icons.person_outline,
        Text('No aplica para este tipo de documento.', style: context.apagado()),
      );
    }

    if (TipoCite.destinatarioEmpleado(_tipo)) {
      final empleadosAsync = ref.watch(empleadosCiteProvider);
      return _seccion(
        'Destinatario',
        'Se elige de la planilla; el cargo se completa solo.',
        Icons.person_outline,
        empleadosAsync.when(
          loading: () => const _CampoCargando(etiqueta: 'Destinatario'),
          error: (e, _) => _CampoError(mensaje: 'No se pudo cargar la lista de empleados'),
          data: (empleados) {
            final cod = _doc.codEmpleado.toInt();
            // -1 es la opción "todo el personal", igual que en el módulo viejo.
            final existe = cod == -1 || empleados.any((e) => e.codEmpleado.toInt() == cod);
            return Column(
              children: [
                DropdownButtonFormField<int>(
                  value: existe && cod != 0 ? cod : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Dirigido a *',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _errorSi(
                      _doc.codEmpleado.toInt() == 0,
                      'Elegí el destinatario.',
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: -1, child: Text('Personal de IMPEXPAP')),
                    ...empleados.map((e) => DropdownMenuItem(
                          value: e.codEmpleado.toInt(),
                          child: Text(e.nombreCompleto, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: _bloqueado
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() {
                            _doc.codEmpleado = BigInt.from(v);
                            if (v == -1) {
                              _dirigido.text = 'PERSONAL DE IMPEXPAP';
                              _cargoDirigido.text = 'N/A';
                            } else {
                              final e = empleados
                                  .firstWhere((x) => x.codEmpleado.toInt() == v);
                              _dirigido.text = e.nombreCompleto;
                              _cargoDirigido.text = e.cargo;
                            }
                          });
                        },
                ),
                SizedBox(height: Esp.s),
                _CampoFijo(
                  etiqueta: 'Cargo',
                  valor: _cargoDirigido.text.isEmpty ? '—' : _cargoDirigido.text,
                ),
              ],
            );
          },
        ),
      );
    }

    // Carta, informe de control interno y COM. CI: nombre escrito a mano.
    final esRemite = TipoCite.destinatarioEsRemite(_tipo);
    return _seccion(
      'Destinatario',
      esRemite
          ? 'En la comunicación CI este dato se imprime como "DE:".'
          : 'Nombre y cargo tal como salen impresos.',
      Icons.person_outline,
      Column(
        children: [
          _grilla(aire, [
            TextField(
              controller: _dirigido,
              readOnly: _bloqueado,
              decoration: InputDecoration(
                labelText: esRemite ? 'De *' : 'Señor/es *',
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _errorSi(
                  _dirigido.text.trim().isEmpty,
                  esRemite
                      ? 'Indicá de quién es el documento.'
                      : 'Indicá a quién va dirigido.',
                ),
              ),
            ),
            TextField(
              controller: _cargoDirigido,
              readOnly: _bloqueado,
              decoration: const InputDecoration(
                labelText: 'Cargo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ]),
          if (TipoCite.usaVia(_tipo)) ...[
            SizedBox(height: Esp.m),
            _grilla(aire, [
              TextField(
                controller: _via,
                readOnly: _bloqueado,
                decoration: const InputDecoration(
                  labelText: 'Vía',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              TextField(
                controller: _cargoVia,
                readOnly: _bloqueado,
                decoration: const InputDecoration(
                  labelText: 'Cargo de la vía',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _asuntoYReferencia(Aire aire) {
    final usaRef = TipoCite.usaReferencia(_tipo);
    final usaAsu = TipoCite.usaAsunto(_tipo);
    if (!usaRef && !usaAsu) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: Esp.l),
      child: _seccion(
        usaRef ? 'Referencia' : 'Asunto',
        'Una línea que resume de qué trata el documento.',
        Icons.subject,
        Column(
          children: [
            if (usaRef)
              TextField(
                controller: _referencia,
                readOnly: _bloqueado,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ref.: *',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _errorSi(
                    _referencia.text.trim().isEmpty,
                    'La referencia es obligatoria.',
                  ),
                ),
              ),
            if (usaRef && usaAsu) SizedBox(height: Esp.m),
            if (usaAsu)
              TextField(
                controller: _asunto,
                readOnly: _bloqueado,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Asunto *',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                  errorText: _errorSi(
                    _asunto.text.trim().isEmpty,
                    'El asunto es obligatorio.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Marca un hijo para darlo de baja en el próximo guardado.
  ///
  /// Sólo los que existen en la base: un id en cero es una fila que se agregó
  /// y se quitó sin llegar a guardarse nunca, y mandarla igual haría que el SP
  /// respondiera "falta el identificador" y se cayera todo el guardado. Pasa
  /// cuando un guardado falla —por validación, por ejemplo— y el usuario
  /// corrige quitando una fila que acababa de agregar.
  void _marcarBaja(List<BigInt> destino, BigInt id) {
    if (id != BigInt.zero) destino.add(id);
  }

  Widget _listaDestinatariosExtra() => ListaEditableCite(
        titulo: 'Copia a:',
        descripcion: 'Destinatarios adicionales que se imprimen en el encabezado.',
        icono: Icons.group_outlined,
        cantidad: _ctrlDestinatarios.length,
        soloLectura: _bloqueado,
        textoVacio: 'Sin destinatarios adicionales.',
        camposDe: (i) => [
          CampoFila(
            controller: _ctrlDestinatarios[i][0],
            etiqueta: 'Nombre',
            maxLargo: 180,
            soloLectura: _bloqueado,
          ),
          CampoFila(
            controller: _ctrlDestinatarios[i][1],
            etiqueta: 'Cargo',
            maxLargo: 180,
            soloLectura: _bloqueado,
          ),
        ],
        onAgregar: () => setState(() => _ctrlDestinatarios.add([
              TextEditingController(),
              TextEditingController(),
            ])),
        onQuitar: (i) => setState(() {
          if (i < _doc.destinatarios.length) {
            _marcarBaja(_destinatariosAEliminar, _doc.destinatarios[i].idCopiaEncab);
            _doc.destinatarios.removeAt(i);
          }
          for (final c in _ctrlDestinatarios[i]) {
            c.dispose();
          }
          _ctrlDestinatarios.removeAt(i);
        }),
      );

  Widget _listaRemitentes() => _conAviso(
        _listaRemitentesCruda(),
        _errorSi(
          _ctrlRemitentes.isEmpty ||
              _ctrlRemitentes.every((f) => f[0].text.trim().isEmpty),
          'El documento tiene que llevar al menos un firmante.',
        ),
      );

  Widget _listaRemitentesCruda() => ListaEditableCite(
        titulo: 'Firman',
        descripcion: 'Quiénes firman el documento. Máximo dos.',
        icono: Icons.draw_outlined,
        cantidad: _ctrlRemitentes.length,
        maximo: 2,
        soloLectura: _bloqueado,
        textoVacio: 'Sin remitentes. El documento tiene que llevar al menos uno.',
        camposDe: (i) => [
          CampoFila(
            controller: _ctrlRemitentes[i][0],
            etiqueta: 'Nombre',
            maxLargo: 150,
            soloLectura: _bloqueado,
          ),
          CampoFila(
            controller: _ctrlRemitentes[i][1],
            etiqueta: 'Cargo',
            maxLargo: 200,
            soloLectura: _bloqueado,
          ),
        ],
        onAgregar: () => setState(() => _ctrlRemitentes.add([
              _ctrlVigilado(),
              TextEditingController(),
            ])),
        onQuitar: (i) => setState(() {
          if (i < _doc.remitentes.length) {
            _marcarBaja(_remitentesAEliminar, _doc.remitentes[i].idRemitente);
            _doc.remitentes.removeAt(i);
          }
          for (final c in _ctrlRemitentes[i]) {
            c.dispose();
          }
          _ctrlRemitentes.removeAt(i);
        }),
      );

  Widget _listaCopiasArchivo() => ListaEditableCite(
        titulo: 'cc/Arch',
        descripcion: 'Siglas que se imprimen al pie. Hasta 25 caracteres cada una.',
        icono: Icons.folder_copy_outlined,
        cantidad: _ctrlCopias.length,
        soloLectura: _bloqueado,
        textoVacio: 'Sin copias de archivo.',
        camposDe: (i) => [
          CampoFila(
            controller: _ctrlCopias[i],
            etiqueta: 'cc/Arch',
            maxLargo: 25,
            soloLectura: _bloqueado,
          ),
        ],
        onAgregar: () => setState(() => _ctrlCopias.add(TextEditingController())),
        onQuitar: (i) => setState(() {
          if (i < _doc.copiasArchivo.length) {
            _marcarBaja(_copiasAEliminar, _doc.copiasArchivo[i].idCopiaArch);
            _doc.copiasArchivo.removeAt(i);
          }
          _ctrlCopias[i].dispose();
          _ctrlCopias.removeAt(i);
        }),
      );

  /// Dos columnas cuando entra, una cuando no. El corte se mide sobre el ancho
  /// del cajón y no sobre el de la ventana, porque adentro del dashboard el
  /// sidebar se come su parte.
  Widget _grilla(Aire aire, List<Widget> campos) {
    if (aire.esChico || campos.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < campos.length; i++) ...[
            if (i > 0) SizedBox(height: Esp.m),
            campos[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < campos.length; i++) ...[
          if (i > 0) SizedBox(width: Esp.m),
          Expanded(child: campos[i]),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS CHICAS
// ═══════════════════════════════════════════════════════════════════════════

class _ChipCite extends StatelessWidget {
  final String cite;
  final String empresa;
  final String tipo;
  final int idTipoDoc;
  final bool provisorio;
  final bool cargando;

  const _ChipCite({
    required this.cite,
    required this.empresa,
    required this.tipo,
    required this.idTipoDoc,
    required this.provisorio,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Row(
        children: [
          SelloTipoCite(idTipoDoc: idTipoDoc, tipo: tipo, lado: 40),
          SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cite,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                      ),
                ),
                Text(
                  [
                    if (tipo.isNotEmpty) tipo,
                    if (empresa.isNotEmpty) empresa,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
          if (cargando)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (provisorio)
            // Un ícono de información no dice que el número puede cambiar; hay
            // que pasarle el mouse por encima para enterarse, y en un teléfono
            // no hay mouse. La palabra sí lo dice.
            Tooltip(
              message: 'Es el número que tocaría hoy.\n'
                  'El definitivo se asigna al guardar.',
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.45),
                  ),
                  borderRadius: BorderRadius.circular(Esquina.pastilla),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 13, color: cs.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Provisional',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: Peso.titulo,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvisoAnulado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: Esp.l),
      padding: EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: cs.onErrorContainer, size: 20),
          SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              'Documento anulado. Se muestra sólo para consulta; su número de '
              'CITE queda consumido y no se reutiliza.',
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoCargando extends StatelessWidget {
  final String etiqueta;
  const _CampoCargando({required this.etiqueta});

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: Esp.s),
            Text('Cargando…', style: context.apagado()),
          ],
        ),
      );
}

class _CampoError extends StatelessWidget {
  final String mensaje;
  const _CampoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: cs.error),
        SizedBox(width: Esp.s),
        Expanded(child: Text(mensaje, style: TextStyle(color: cs.error))),
      ],
    );
  }
}

class _CampoFijo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _CampoFijo({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          enabled: false,
        ),
        child: Text(valor, style: context.apagado()),
      );
}

/// La barra de abajo: qué falta y el botón de guardar.
///
/// Es lo único que quedó fijo en pantalla mientras se redacta, y hace dos
/// cosas a la vez: dice si el documento ya se puede guardar, y guarda. Las dos
/// respondían antes a la misma pregunta —«¿ya está?»— y ninguna estaba a la
/// vista al llegar al final del formulario.
class _BarraGuardar extends StatelessWidget {
  final List<String> pendientes;
  final bool guardando;
  final VoidCallback onGuardar;

  const _BarraGuardar({
    required this.pendientes,
    required this.guardando,
    required this.onGuardar,
  });

  String get _resumen {
    if (pendientes.isEmpty) return 'Listo para guardar';
    // Los dos caminos del destinatario —planilla y escrito a mano— nombran el
    // mismo pendiente; repetirlo en la barra sería un error visible.
    final unicos = pendientes.toSet().toList();
    if (unicos.length == 1) return 'Falta ${unicos.first}';
    if (unicos.length == 2) return 'Faltan ${unicos[0]} y ${unicos[1]}';
    return 'Faltan ${unicos.take(2).join(", ")} y ${unicos.length - 2} más';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final listo = pendientes.isEmpty;

    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          padding: EdgeInsets.fromLTRB(Esp.l, Esp.s, Esp.l, Esp.s),
          child: Row(
            children: [
              Icon(
                listo ? Icons.check_circle_outline : Icons.pending_outlined,
                size: 18,
                color: listo ? cs.primary : cs.onSurfaceVariant,
              ),
              SizedBox(width: Esp.s),
              Expanded(
                child: Text(
                  _resumen,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: listo ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: listo ? Peso.titulo : Peso.normal,
                      ),
                ),
              ),
              SizedBox(width: Esp.s),
              FilledButton.icon(
                // Sigue habilitado con pendientes a propósito: apretarlo dice
                // cuál es el que frena. Un botón gris no explica nada.
                onPressed: guardando ? null : onGuardar,
                icon: guardando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(guardando ? 'Guardando…' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
