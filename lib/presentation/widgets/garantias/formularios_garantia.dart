/// Formularios de una garantia: alta, edicion y edicion administrativa.
///
/// Reemplazan a los dialogos `garantiaModal`, `pdamGarDetModal` y
/// `garantiaModalAdm` de `tcbrGarantia/garantia.xhtml`. Lo que cambia:
///
/// - **El cliente se busca escribiendo**, contra SAP, en vez de un combo con
///   miles de clientes cargados de golpe.
/// - **La suma de los documentos se ve mientras se arma** y avisa si no
///   coincide con el valor declarado. El legacy solo mostraba un icono.
/// - **Editar dice que se edita.** En el legacy el boton «Editar» abria el
///   mismo formulario del alta, pero al guardar solo se grababan firmas,
///   protesta y documentos nuevos: los montos y fechas cambiados se perdian en
///   silencio. Aca esos campos se muestran como lectura y el cambio de montos
///   y fechas vive en la edicion administrativa.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PUNTOS DE ENTRADA
// ═══════════════════════════════════════════════════════════════════════════

/// Alta de una garantia. Devuelve el codGarantia nuevo, o null si se cancelo.
///
/// [cliente] llega cuando el alta se abre desde el panel de un cliente: el
/// campo ya viene elegido.
Future<BigInt?> abrirAltaGarantia(
  BuildContext context, {
  ClienteSapEntity? cliente,
}) => abrirPanel<BigInt>(
  context,
  anchoMaximo: 760,
  contenido: (_) => _FormularioGarantia(clienteInicial: cliente),
);

/// Edicion de una garantia existente: firmas, protesta y documentos nuevos.
Future<BigInt?> abrirEdicionGarantia(
  BuildContext context,
  GarantiaVistaEntity garantia,
) => abrirPanel<BigInt>(
  context,
  anchoMaximo: 760,
  contenido: (_) => _FormularioGarantia(existente: garantia),
);

/// Edicion administrativa: todo menos el cliente.
Future<BigInt?> abrirEdicionAdministrativa(
  BuildContext context,
  GarantiaVistaEntity garantia,
) => abrirPanel<BigInt>(
  context,
  anchoMaximo: 680,
  contenido: (_) => _FormularioAdministrativo(garantia: garantia),
);

// ═══════════════════════════════════════════════════════════════════════════
// ALTA Y EDICION
// ═══════════════════════════════════════════════════════════════════════════

class _FormularioGarantia extends ConsumerStatefulWidget {
  const _FormularioGarantia({this.clienteInicial, this.existente});

  final ClienteSapEntity? clienteInicial;
  final GarantiaVistaEntity? existente;

  @override
  ConsumerState<_FormularioGarantia> createState() =>
      _FormularioGarantiaState();
}

class _FormularioGarantiaState extends ConsumerState<_FormularioGarantia> {
  final _form = GlobalKey<FormState>();
  final _montoGarantia = TextEditingController();
  final _montoCredito = TextEditingController();
  final _tiempoPago = TextEditingController();
  final _observacion = TextEditingController();
  final _recFirmas = TextEditingController();
  final _nroProtesta = TextEditingController();

  ClienteSapEntity? _cliente;
  DateTime? _inicio;
  DateTime? _fin;

  /// Documentos agregados en esta sesion. Se mandan juntos al guardar.
  final List<CbrDetalleEntity> _nuevos = [];

  bool _tocado = false;

  bool get _esAlta => widget.existente == null;

  @override
  void initState() {
    super.initState();
    _cliente = widget.clienteInicial;
    final e = widget.existente;
    if (e != null) {
      final g = e.garantia;
      _cliente = ClienteSapEntity(
        codClienteSAP: g.codClienteSAP,
        datoCliente: e.datoCliente,
      );
      _montoGarantia.text = textoMonto(g.montoGarantia);
      _montoCredito.text = textoMonto(g.montoCredito);
      _tiempoPago.text = g.tiempoPago.toString();
      _inicio = g.fechaInicio;
      _fin = g.fechaExpiracion;
      _recFirmas.text = g.recFirmas ?? '';
      _nroProtesta.text = g.nroProtesta ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _montoGarantia,
      _montoCredito,
      _tiempoPago,
      _observacion,
      _recFirmas,
      _nroProtesta,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _marcar() {
    if (!_tocado) setState(() => _tocado = true);
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_cliente == null) {
      avisar(context, 'Elija el cliente de la garantía.', esError: true);
      return;
    }
    if (!_esAlta && _nuevos.isEmpty && !_cambiaronTextos) {
      avisar(context, 'No hay cambios para guardar.', esError: true);
      return;
    }

    final e = widget.existente?.garantia;
    final registro = GarantiaRegistroEntity(
      codGarantia: e?.codGarantia ?? BigInt.zero,
      codClienteSAP: _cliente!.codClienteSAP,
      montoGarantia: leerMonto(_montoGarantia.text) ?? 0,
      montoCredito: leerMonto(_montoCredito.text) ?? 0,
      tiempoPago: int.tryParse(_tiempoPago.text.trim()) ?? 0,
      fechaInicio: _inicio,
      fechaExpiracion: _fin,
      recFirmas: _recFirmas.text,
      nroProtesta: _nroProtesta.text,
      observacion: _esAlta ? _observacion.text : null,
      detalles: List.unmodifiable(_nuevos),
    );

    final notifier = ref.read(operacionesGarantiasProvider.notifier);
    final id = await notifier.registrarGarantia(registro);
    if (!mounted) return;
    if (id == null) {
      avisar(
        context,
        ref.read(operacionesGarantiasProvider).error ??
            'No se pudo guardar la garantía.',
        esError: true,
      );
      notifier.limpiarError();
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(id);
  }

  bool get _cambiaronTextos {
    final g = widget.existente?.garantia;
    if (g == null) return true;
    return _recFirmas.text.trim() != (g.recFirmas ?? '').trim() ||
        _nroProtesta.text.trim() != (g.nroProtesta ?? '').trim();
  }

  Future<void> _cerrar() async {
    if (_tocado || _nuevos.isNotEmpty) {
      final salir = await confirmar(
        context,
        titulo: '¿Descartar los cambios?',
        detalle: 'Lo que cargó en este formulario no se guardó.',
        textoConfirmar: 'Descartar',
        destructiva: true,
      );
      if (!salir || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    final existente = widget.existente;

    return Form(
      key: _form,
      onChanged: _marcar,
      child: MarcoPanel(
        titulo: _esAlta ? 'Nueva garantía' : 'Editar garantía',
        subtitulo:
            _esAlta
                ? 'Queda registrada a su nombre, con fecha de hoy.'
                : 'N° ${existente!.codGarantia} · ${existente.datoCliente}',
        onCerrar: ocupado ? () {} : _cerrar,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_esAlta)
              _BuscadorCliente(
                inicial: _cliente,
                onElegir: (c) {
                  setState(() => _cliente = c);
                  _marcar();
                },
              )
            else
              NotaGarantia(
                texto:
                    'Aquí se editan el reconocimiento de firmas y el N° de '
                    'protesta, y se agregan documentos. Los montos y las '
                    'fechas se cambian con la edición administrativa; si la '
                    'garantía se renueva, use «Extender» para mover la fecha '
                    'de expiración.',
              ),
            const SizedBox(height: Esp.l),
            _esAlta ? _camposEditables() : _camposDeLectura(existente!),
            const SizedBox(height: Esp.l),
            _FilaResponsiva(
              hijos: [
                TextFormField(
                  controller: _recFirmas,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Reconocimiento de firmas',
                    helperText: 'Opcional. Se puede completar después.',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  controller: _nroProtesta,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'N° de protesta',
                    helperText: 'Solo si corresponde.',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            if (_esAlta) ...[
              const SizedBox(height: Esp.s),
              TextFormField(
                controller: _observacion,
                maxLength: 299,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observación del registro',
                  helperText: 'Queda en la acción de registro de la garantía.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: Esp.l),
            _EditorDocumentos(
              existentes:
                  existente == null
                      ? null
                      : ref.watch(
                        detallesGarantiaProvider(existente.codGarantia),
                      ),
              nuevos: _nuevos,
              montoDeclarado:
                  _esAlta
                      ? leerMonto(_montoGarantia.text)
                      : existente!.garantia.montoGarantia,
              onAgregar: (d) => setState(() => _nuevos.add(d)),
              onQuitar: (i) => setState(() => _nuevos.removeAt(i)),
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: ocupado ? null : _cerrar,
            child: const Text('Cancelar'),
          ),
          BotonAccion(
            etiqueta: _esAlta ? 'Registrar garantía' : 'Guardar cambios',
            etiquetaOcupado: 'Guardando…',
            icono: Icons.save_outlined,
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }

  Widget _camposEditables() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FilaResponsiva(
        hijos: [
          CampoMonto(
            etiqueta: Glosario.valor.nombre,
            ayuda: 'Cuánto vale lo que entrega el cliente.',
            controlador: _montoGarantia,
            onCambio: (_) => setState(() {}),
          ),
          CampoMonto(
            etiqueta: Glosario.lineaAprobada.nombre,
            ayuda: 'Límite de crédito que se le aprueba con esta garantía.',
            controlador: _montoCredito,
          ),
          _CampoDias(controlador: _tiempoPago),
        ],
      ),
      const SizedBox(height: Esp.l),
      _FilaResponsiva(
        hijos: [
          CampoFecha(
            etiqueta: 'Fecha de inicio',
            valor: _inicio,
            onCambio: (f) => setState(() => _inicio = f),
          ),
          CampoFecha(
            etiqueta: 'Fecha de expiración',
            valor: _fin,
            onCambio: (f) => setState(() => _fin = f),
            validar: _validarFin,
          ),
        ],
      ),
      const SizedBox(height: Esp.xs),
      Text(
        'Al pasar la fecha de expiración la garantía queda Caducada, pero no '
        'se cierra sola: se puede extender o cerrar.',
        style: context.apagado(),
      ),
      const SizedBox(height: Esp.s),
      _AvisoMontos(
        garantia: leerMonto(_montoGarantia.text),
        credito: leerMonto(_montoCredito.text),
      ),
    ],
  );

  String? _validarFin(DateTime? f) {
    if (f != null && _inicio != null && !f.isAfter(_inicio!)) {
      return 'Debe ser posterior al inicio';
    }
    return null;
  }

  Widget _camposDeLectura(GarantiaVistaEntity e) {
    final g = e.garantia;
    return Wrap(
      spacing: Esp.xl,
      runSpacing: Esp.m,
      children: [
        DatoFicha(etiqueta: 'Cliente', valor: e.datoCliente, ancho: 260),
        DatoFicha.termino(
          Glosario.valor,
          valor: monto(g.montoGarantia),
          cifra: true,
        ),
        DatoFicha.termino(
          Glosario.lineaAprobada,
          valor: monto(g.montoCredito),
          cifra: true,
        ),
        DatoFicha.termino(Glosario.plazoPago, valor: '${g.tiempoPago} días'),
        DatoFicha(
          etiqueta: 'Vigencia',
          valor:
              '${fechaCorta(g.fechaInicio)} → ${fechaCorta(g.fechaExpiracion)}',
          ancho: 220,
        ),
      ],
    );
  }
}

/// La linea aprobada que supera el valor de la garantia no se bloquea —el
/// negocio lo permite y el legacy tambien—, pero se avisa.
class _AvisoMontos extends StatelessWidget {
  const _AvisoMontos({required this.garantia, required this.credito});

  final double? garantia;
  final double? credito;

  @override
  Widget build(BuildContext context) {
    if (garantia == null || credito == null || credito! <= garantia!) {
      return const SizedBox.shrink();
    }
    return NotaGarantia(
      tono: TonoNota.aviso,
      texto:
          'La línea de crédito (${monto(credito)}) supera el valor de la '
          'garantía (${monto(garantia)}).',
    );
  }
}

class _CampoDias extends StatelessWidget {
  const _CampoDias({required this.controlador});

  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controlador,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    textAlign: TextAlign.end,
    style: const TextStyle(fontFeatures: cifrasTabulares),
    decoration: const InputDecoration(
      labelText: 'Plazo de pago',
      helperText: 'Días para pagar cada compra a crédito.',
      helperMaxLines: 2,
      suffixText: 'días',
      isDense: true,
      border: OutlineInputBorder(),
    ),
    validator: (t) {
      final v = int.tryParse((t ?? '').trim());
      if (v == null) return 'Indique el plazo';
      if (v > 3650) return 'Plazo demasiado largo';
      return null;
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// BUSCADOR DE CLIENTE
// ═══════════════════════════════════════════════════════════════════════════

class _BuscadorCliente extends ConsumerStatefulWidget {
  const _BuscadorCliente({required this.inicial, required this.onElegir});

  final ClienteSapEntity? inicial;
  final ValueChanged<ClienteSapEntity?> onElegir;

  @override
  ConsumerState<_BuscadorCliente> createState() => _BuscadorClienteState();
}

class _BuscadorClienteState extends ConsumerState<_BuscadorCliente> {
  String? _error;
  bool _buscando = false;

  /// La ultima consulta que se lanzo. Si el usuario sigue escribiendo, las
  /// respuestas viejas se descartan para que no pisen a la nueva.
  String _ultima = '';

  Future<Iterable<ClienteSapEntity>> _opciones(TextEditingValue v) async {
    final texto = v.text.trim();
    if (texto.length < 3) return const [];
    _ultima = texto;
    // Espera corta: una consulta por pausa al escribir, no una por tecla.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (texto != _ultima) return const [];
    if (mounted) setState(() => _buscando = true);
    try {
      final r = await buscarClientesSap(ref, texto);
      if (mounted) setState(() => _error = null);
      return texto == _ultima ? r : const [];
    } catch (e) {
      if (mounted) setState(() => _error = textoParaUsuario(e));
      return const [];
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ClienteSapEntity>(
      initialValue:
          widget.inicial == null
              ? null
              : TextEditingValue(text: widget.inicial!.etiqueta),
      displayStringForOption: (c) => c.etiqueta,
      optionsBuilder: _opciones,
      onSelected: widget.onElegir,
      fieldViewBuilder:
          (context, ctrl, foco, alEnviar) => TextFormField(
            controller: ctrl,
            focusNode: foco,
            onChanged: (_) {
              // Escribir de nuevo invalida la eleccion anterior.
              if (widget.inicial != null) widget.onElegir(null);
            },
            validator:
                (_) =>
                    widget.inicial == null ? 'Elija un cliente de SAP' : null,
            decoration: InputDecoration(
              labelText: 'Cliente',
              helperText: 'Escriba al menos 3 letras del nombre o del código.',
              errorText: _error,
              isDense: true,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon:
                  _buscando
                      ? const Padding(
                        padding: EdgeInsets.all(Esp.m),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : null,
            ),
          ),
      optionsViewBuilder:
          (context, alElegir, opciones) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(Esquina.chica),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 560,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: opciones.length,
                  itemBuilder: (context, i) {
                    final c = opciones.elementAt(i);
                    return ListTile(
                      dense: true,
                      title: Text(c.datoCliente),
                      subtitle: Text(
                        c.codClienteSAP,
                        style: const TextStyle(fontFeatures: cifrasTabulares),
                      ),
                      onTap: () => alElegir(c),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DOCUMENTOS (DETALLES)
// ═══════════════════════════════════════════════════════════════════════════

/// Los documentos que respaldan la garantia. Los ya guardados se listan como
/// lectura (se editan desde el detalle); los nuevos se arman en memoria y
/// viajan juntos al guardar, como en el legacy.
class _EditorDocumentos extends ConsumerStatefulWidget {
  const _EditorDocumentos({
    required this.existentes,
    required this.nuevos,
    required this.montoDeclarado,
    required this.onAgregar,
    required this.onQuitar,
  });

  final AsyncValue<List<CbrDetalleEntity>>? existentes;
  final List<CbrDetalleEntity> nuevos;
  final double? montoDeclarado;
  final ValueChanged<CbrDetalleEntity> onAgregar;
  final ValueChanged<int> onQuitar;

  @override
  ConsumerState<_EditorDocumentos> createState() => _EditorDocumentosState();
}

class _EditorDocumentosState extends ConsumerState<_EditorDocumentos> {
  final _formDoc = GlobalKey<FormState>();
  final _monto = TextEditingController();
  final _detalle = TextEditingController();
  String? _tipo;

  @override
  void dispose() {
    _monto.dispose();
    _detalle.dispose();
    super.dispose();
  }

  void _agregar() {
    if (!(_formDoc.currentState?.validate() ?? false)) return;
    widget.onAgregar(
      CbrDetalleEntity.nuevo(
        codGarantia: BigInt.zero,
        tipoGarantia: _tipo!,
        detalle: _detalle.text.trim().isEmpty ? null : _detalle.text.trim(),
        montoGarantiaParc: leerMonto(_monto.text),
      ),
    );
    _monto.clear();
    _detalle.clear();
    setState(() => _tipo = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipos = ref.watch(tiposGarantiaProvider);
    final catalogo = tipos.valueOrNull;
    final guardados = widget.existentes?.valueOrNull ?? const [];

    final suma =
        guardados.fold(0.0, (s, d) => s + d.monto) +
        widget.nuevos.fold(0.0, (s, d) => s + d.monto);
    final declarado = widget.montoDeclarado;
    final difiere = declarado != null && (suma - declarado).abs() >= 0.005;

    return Container(
      padding: const EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloSeccion(
            texto: 'Documentos que la respaldan',
            accion: Text(
              'Suma ${monto(suma)}',
              style: context.cifra(
                fuerte: true,
                color: difiere ? colorAviso(context) : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.s),
            child: Text(
              'Lo que el cliente entrega como garantía: pagarés, letras de '
              'cambio, inmuebles, vehículos… Cargue cada uno con su monto; la '
              'suma debería ser igual al valor de la garantía.',
              style: context.apagado(),
            ),
          ),
          if (difiere)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: NotaGarantia(
                tono: TonoNota.aviso,
                texto:
                    'Los documentos suman ${monto(suma)} y el valor de la '
                    'garantía es ${monto(declarado)}. Se puede guardar igual, '
                    'pero conviene revisar los montos.',
              ),
            ),
          if (widget.existentes?.isLoading ?? false)
            const LinearProgressIndicator(minHeight: 2),
          for (final d in guardados)
            _FilaDocumento(
              tipo: nombreDeTipo(catalogo, d.tipoGarantia),
              detalle: d.detalle,
              valor: d.monto,
              marca: 'Guardado',
            ),
          for (final (i, d) in widget.nuevos.indexed)
            _FilaDocumento(
              tipo: nombreDeTipo(catalogo, d.tipoGarantia),
              detalle: d.detalle,
              valor: d.monto,
              marca: 'Nuevo',
              onQuitar: () => widget.onQuitar(i),
            ),
          if (guardados.isEmpty && widget.nuevos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.s),
              child: Text(
                'Todavía no hay documentos. Agregue el pagaré, la letra o el '
                'bien que respalda la garantía.',
                style: context.apagado(),
              ),
            ),
          const Divider(height: Esp.xl),
          Form(
            key: _formDoc,
            child: _FilaResponsiva(
              flex: const [3, 2, 4],
              hijos: [
                DropdownButtonFormField<String>(
                  key: ValueKey('tipo-$_tipo-${catalogo?.length}'),
                  value: _tipo,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Tipo de documento',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    errorText: tipos.hasError ? 'No se pudo cargar' : null,
                  ),
                  items: [
                    for (final TipoCbrEntity t in catalogo ?? const [])
                      DropdownMenuItem(
                        value: t.codTipos,
                        child: Text(t.nombre),
                      ),
                  ],
                  onChanged: (v) => setState(() => _tipo = v),
                  validator: (v) => v == null ? 'Elija el tipo' : null,
                ),
                CampoMonto(
                  etiqueta: 'Monto',
                  controlador: _monto,
                  permitirCero: false,
                ),
                TextFormField(
                  controller: _detalle,
                  maxLength: 299,
                  decoration: const InputDecoration(
                    labelText: 'Detalle',
                    hintText: 'N° de documento, ubicación del bien…',
                    isDense: true,
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Esp.s),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _agregar,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar documento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaDocumento extends StatelessWidget {
  const _FilaDocumento({
    required this.tipo,
    required this.detalle,
    required this.valor,
    required this.marca,
    this.onQuitar,
  });

  final String tipo;
  final String? detalle;
  final double valor;
  final String marca;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.xs),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap y no Row: en el telefono la etiqueta sola no entraba al
              // lado del tipo (desbordaba 18 px); asi baja a la linea siguiente.
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    tipo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  EtiquetaGarantia(
                    texto: marca,
                    tono:
                        onQuitar != null
                            ? TonoEtiqueta.aviso
                            : TonoEtiqueta.neutro,
                  ),
                ],
              ),
              if ((detalle ?? '').isNotEmpty)
                Text(
                  detalle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
            ],
          ),
        ),
        const SizedBox(width: Esp.s),
        Text(monto(valor), style: context.cifra(fuerte: true)),
        if (onQuitar != null)
          IconButton(
            tooltip: 'Quitar',
            onPressed: onQuitar,
            icon: const Icon(Icons.close, size: 18),
          )
        else
          const SizedBox(width: 40),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EDICION ADMINISTRATIVA
// ═══════════════════════════════════════════════════════════════════════════

class _FormularioAdministrativo extends ConsumerStatefulWidget {
  const _FormularioAdministrativo({required this.garantia});

  final GarantiaVistaEntity garantia;

  @override
  ConsumerState<_FormularioAdministrativo> createState() =>
      _FormularioAdministrativoState();
}

class _FormularioAdministrativoState
    extends ConsumerState<_FormularioAdministrativo> {
  final _form = GlobalKey<FormState>();
  late final _montoGarantia = TextEditingController(
    text: textoMonto(widget.garantia.garantia.montoGarantia),
  );
  late final _montoCredito = TextEditingController(
    text: textoMonto(widget.garantia.garantia.montoCredito),
  );
  late final _tiempoPago = TextEditingController(
    text: widget.garantia.garantia.tiempoPago.toString(),
  );
  late final _recFirmas = TextEditingController(
    text: widget.garantia.garantia.recFirmas ?? '',
  );
  late final _nroProtesta = TextEditingController(
    text: widget.garantia.garantia.nroProtesta ?? '',
  );
  late DateTime? _inicio = widget.garantia.garantia.fechaInicio;
  late DateTime? _fin = widget.garantia.garantia.fechaExpiracion;

  @override
  void dispose() {
    for (final c in [
      _montoGarantia,
      _montoCredito,
      _tiempoPago,
      _recFirmas,
      _nroProtesta,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final g = widget.garantia.garantia;

    // El registro COMPLETO: /actualizar reemplaza todas las columnas
    // editables, y un null borraria firmas o protesta.
    final actualizada = g.copyWith(
      montoGarantia: leerMonto(_montoGarantia.text),
      montoCredito: leerMonto(_montoCredito.text),
      tiempoPago: int.tryParse(_tiempoPago.text.trim()),
      fechaInicio: _inicio,
      fechaExpiracion: _fin,
      recFirmas: _recFirmas.text.trim(),
      nroProtesta: _nroProtesta.text.trim(),
    );

    final notifier = ref.read(operacionesGarantiasProvider.notifier);
    final id = await notifier.actualizarGarantia(actualizada);
    if (!mounted) return;
    if (id == null) {
      avisar(
        context,
        ref.read(operacionesGarantiasProvider).error ??
            'No se pudo actualizar la garantía.',
        esError: true,
      );
      notifier.limpiarError();
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    final e = widget.garantia;

    return Form(
      key: _form,
      child: MarcoPanel(
        titulo: 'Edición administrativa',
        subtitulo: 'N° ${e.codGarantia} · ${e.datoCliente}',
        onCerrar: ocupado ? () {} : null,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NotaGarantia(
              texto:
                  'Reemplaza montos, plazo, fechas, firmas y protesta. El '
                  'cliente no se cambia: para otro cliente registre una '
                  'garantía nueva.',
            ),
            const SizedBox(height: Esp.l),
            _FilaResponsiva(
              hijos: [
                CampoMonto(
                  etiqueta: Glosario.valor.nombre,
                  ayuda: 'Cuánto vale lo que entregó el cliente.',
                  controlador: _montoGarantia,
                ),
                CampoMonto(
                  etiqueta: Glosario.lineaAprobada.nombre,
                  ayuda: 'Límite de crédito aprobado con esta garantía.',
                  controlador: _montoCredito,
                ),
                _CampoDias(controlador: _tiempoPago),
              ],
            ),
            const SizedBox(height: Esp.l),
            _FilaResponsiva(
              hijos: [
                CampoFecha(
                  etiqueta: 'Fecha de inicio',
                  valor: _inicio,
                  onCambio: (f) => setState(() => _inicio = f),
                ),
                CampoFecha(
                  etiqueta: 'Fecha de expiración',
                  valor: _fin,
                  onCambio: (f) => setState(() => _fin = f),
                  validar:
                      (f) =>
                          f != null && _inicio != null && !f.isAfter(_inicio!)
                              ? 'Debe ser posterior al inicio'
                              : null,
                ),
              ],
            ),
            const SizedBox(height: Esp.l),
            _FilaResponsiva(
              hijos: [
                TextFormField(
                  controller: _recFirmas,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Reconocimiento de firmas',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  controller: _nroProtesta,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'N° de protesta',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonAccion(
            etiqueta: 'Guardar cambios',
            etiquetaOcupado: 'Guardando…',
            icono: Icons.save_outlined,
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DISPOSICION
// ═══════════════════════════════════════════════════════════════════════════

/// Campos en fila cuando hay ancho, apilados en el telefono. Nunca scroll
/// horizontal.
class _FilaResponsiva extends StatelessWidget {
  const _FilaResponsiva({required this.hijos, this.flex});

  final List<Widget> hijos;
  final List<int>? flex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, r) {
      if (r.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, h) in hijos.indexed) ...[
              if (i > 0) const SizedBox(height: Esp.m),
              h,
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, h) in hijos.indexed) ...[
            if (i > 0) const SizedBox(width: Esp.m),
            Expanded(flex: flex?[i] ?? 1, child: h),
          ],
        ],
      );
    },
  );
}
