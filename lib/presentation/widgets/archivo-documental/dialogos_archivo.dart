/// Fichas de alta y edición de una caja y de un documento (una línea de su
/// contenido). Validan lo mismo que el SP para avisar en el campo; si el
/// servidor rechaza igual, el motivo se muestra arriba y la ficha queda abierta.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CAJA
// ═══════════════════════════════════════════════════════════════════════════

class DialogoCaja extends StatefulWidget {
  const DialogoCaja({
    super.key,
    this.editar,
    required this.archivos,
    this.codArchivoInicial,
    required this.onGuardar,
    required this.siguienteNumero,
    this.mostrarAsa = true,
  });

  /// Null = alta.
  final CajaArchivoEntity? editar;
  final List<ArchivoFisicoEntity> archivos;
  final int? codArchivoInicial;
  final Future<void> Function(CajaArchivoEntity caja) onGuardar;

  /// Propone el número que sigue al elegir el archivo de una caja nueva.
  final Future<int> Function(int codArchivo) siguienteNumero;
  final bool mostrarAsa;

  @override
  State<DialogoCaja> createState() => _DialogoCajaState();
}

class _DialogoCajaState extends State<DialogoCaja> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _numero;
  late final TextEditingController _estante;
  late final TextEditingController _fila;
  late final TextEditingController _observacion;
  int? _archivo;
  bool _numeroTocado = false;
  bool _guardando = false;
  String? _errorServidor;

  bool get _esAlta => widget.editar == null;

  @override
  void initState() {
    super.initState();
    final c = widget.editar;
    _numero = TextEditingController(text: c?.numero.toString() ?? '');
    _estante = TextEditingController(text: c?.estante ?? '');
    _fila = TextEditingController(text: c?.fila ?? '');
    _observacion = TextEditingController(text: c?.observacion ?? '');
    _archivo = c?.codArchivo ?? widget.codArchivoInicial;
    if (_esAlta && _archivo != null) _proponerNumero(_archivo!);
  }

  @override
  void dispose() {
    _numero.dispose();
    _estante.dispose();
    _fila.dispose();
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _proponerNumero(int codArchivo) async {
    try {
      final n = await widget.siguienteNumero(codArchivo);
      // Si la persona ya escribió un número, no se lo pisamos.
      if (mounted && !_numeroTocado) _numero.text = '$n';
    } catch (_) {
      // Sin propuesta se escribe a mano: no es motivo para avisar.
    }
  }

  Future<void> _guardar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final base = widget.editar;
    setState(() {
      _guardando = true;
      _errorServidor = null;
    });
    try {
      await widget.onGuardar(
        CajaArchivoEntity(
          codCaja: base?.codCaja ?? 0,
          codArchivo: _archivo!,
          numero: int.parse(_numero.text.trim()),
          estante: _nullSiVacio(_estante.text),
          fila: _nullSiVacio(_fila.text),
          observacion: _nullSiVacio(_observacion.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorServidor = humanizar(e).texto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un archivo inactivo solo aparece si es el de la caja que se edita.
    final opciones = [
      for (final a in widget.archivos)
        if (a.esActivo || a.codArchivo == widget.editar?.codArchivo) a,
    ];

    return PopScope(
      canPop: !_guardando,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabezaFicha(
              titulo: _esAlta ? 'Nueva caja' : 'Editar ${tituloCaja(widget.editar!).toLowerCase()}',
              mostrarAsa: widget.mostrarAsa,
              ocupado: _guardando,
              icono: Icons.inventory_2_outlined,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorServidor != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Esp.m),
                          child: NotaDelDato(texto: _errorServidor!, tono: TonoNota.error),
                        ),
                      DropdownButtonFormField<int>(
                        value: opciones.any((a) => a.codArchivo == _archivo) ? _archivo : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Archivo *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final a in opciones)
                            DropdownMenuItem(value: a.codArchivo, child: Text(a.nombre)),
                        ],
                        onChanged:
                            _guardando
                                ? null
                                : (v) {
                                  setState(() => _archivo = v);
                                  if (_esAlta && v != null) _proponerNumero(v);
                                },
                        validator: (v) => v == null ? 'Elige el archivo.' : null,
                      ),
                      const SizedBox(height: Esp.l),
                      TextFormField(
                        controller: _numero,
                        enabled: !_guardando,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => _numeroTocado = true,
                        decoration: const InputDecoration(
                          labelText: 'Número de caja *',
                          helperText: 'Se propone el siguiente del archivo.',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return n == null || n <= 0 ? 'Escribe un número mayor que cero.' : null;
                        },
                      ),
                      const SizedBox(height: Esp.l),
                      Row(
                        children: [
                          Expanded(child: _texto(_estante, 'Estante', 20)),
                          const SizedBox(width: Esp.l),
                          Expanded(child: _texto(_fila, 'Fila', 20)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Esp.xs, bottom: Esp.l),
                        child: Text(
                          'Opcional: no todas las cajas están en un estante.',
                          style: context.apagado(),
                        ),
                      ),
                      _texto(_observacion, 'Observación', 200, lineas: 2),
                    ],
                  ),
                ),
              ),
            ),
            PieFicha(
              etiqueta: _esAlta ? 'Crear caja' : 'Guardar cambios',
              ocupado: _guardando,
              onGuardar: _guardar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _texto(TextEditingController c, String rotulo, int maximo, {int lineas = 1}) =>
      TextFormField(
        controller: c,
        enabled: !_guardando,
        maxLength: maximo,
        minLines: lineas,
        maxLines: lineas,
        decoration: InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// LÍNEA DE CONTENIDO
// ═══════════════════════════════════════════════════════════════════════════

class DialogoContenido extends StatefulWidget {
  const DialogoContenido({
    super.key,
    this.editar,
    required this.codCaja,
    required this.cajas,
    required this.tipos,
    required this.empresas,
    required this.onGuardar,
    this.mostrarAsa = true,
  });

  /// Null = alta en [codCaja].
  final ContenidoCajaEntity? editar;
  final int codCaja;

  /// Para mover la línea a otra caja al editarla.
  final List<CajaArchivoEntity> cajas;
  final List<TipoDocumentoArchivoEntity> tipos;
  final List<EmpresaEntity> empresas;
  final Future<void> Function(ContenidoCajaEntity linea) onGuardar;
  final bool mostrarAsa;

  @override
  State<DialogoContenido> createState() => _DialogoContenidoState();
}

class _DialogoContenidoState extends State<DialogoContenido> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _detalle;
  late final TextEditingController _gestion;
  late final TextEditingController _observacion;
  late int _caja;
  int? _tipo;
  int? _empresa;
  bool _guardando = false;
  bool _intento = false;
  String? _errorServidor;

  bool get _esAlta => widget.editar == null;

  @override
  void initState() {
    super.initState();
    final l = widget.editar;
    _detalle = TextEditingController(text: l?.detalle ?? '');
    _gestion = TextEditingController(text: l?.gestion ?? '');
    _observacion = TextEditingController(text: l?.observacion ?? '');
    _caja = l?.codCaja ?? widget.codCaja;
    _tipo = l?.codTipoDocumento;
    _empresa = l?.codEmpresa;
  }

  @override
  void dispose() {
    _detalle.dispose();
    _gestion.dispose();
    _observacion.dispose();
    super.dispose();
  }

  String? _validarGestion(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.length > 60) return 'Hasta 60 caracteres.';
    return anioDeGestion(t) == null
        ? 'Incluye al menos un año de cuatro cifras, por ejemplo 2019 o 2018 - 2019.'
        : null;
  }

  Future<void> _guardar() async {
    setState(() => _intento = true);
    final valido = _formulario.currentState?.validate() ?? false;
    if (!valido || _tipo == null) return;
    final base = widget.editar;
    setState(() {
      _guardando = true;
      _errorServidor = null;
    });
    try {
      await widget.onGuardar(
        ContenidoCajaEntity(
          codContenido: base?.codContenido ?? 0,
          codCaja: _caja,
          codTipoDocumento: _tipo!,
          codEmpresa: _empresa,
          detalle: _detalle.text.trim(),
          gestion: _nullSiVacio(_gestion.text),
          observacion: _nullSiVacio(_observacion.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorServidor = humanizar(e).texto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipos = [
      for (final t in widget.tipos)
        if (t.esActivo || t.codTipoDocumento == widget.editar?.codTipoDocumento) t,
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final cajas = [...widget.cajas]..sort((a, b) {
      final c = (a.nombreArchivo ?? '').compareTo(b.nombreArchivo ?? '');
      return c != 0 ? c : a.numero.compareTo(b.numero);
    });
    final desde = anioDeGestion(_gestion.text);
    final hasta = anioDeGestion(_gestion.text, mayor: true);

    return PopScope(
      canPop: !_guardando,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabezaFicha(
              titulo: _esAlta ? 'Nuevo documento' : 'Editar documento',
              mostrarAsa: widget.mostrarAsa,
              ocupado: _guardando,
              icono: Icons.description_outlined,
              semilla: TonosArchivo.documentos,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Form(
                  key: _formulario,
                  autovalidateMode:
                      _intento ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorServidor != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Esp.m),
                          child: NotaDelDato(texto: _errorServidor!, tono: TonoNota.error),
                        ),
                      if (!_esAlta) ...[
                        ComboBuscable<int>(
                          etiqueta: 'Caja',
                          valor: _caja,
                          ayuda: 'Cámbiala para mover el documento a otra caja.',
                          opciones: [
                            for (final c in cajas)
                              DropdownMenuEntry(
                                value: c.codCaja,
                                label: '${oGuion(c.nombreArchivo)} · ${tituloCaja(c)}',
                              ),
                          ],
                          onElegir: (v) {
                            if (v != null) setState(() => _caja = v);
                          },
                        ),
                        const SizedBox(height: Esp.l),
                      ],
                      ComboBuscable<int>(
                        etiqueta: 'Tipo de documento *',
                        valor: _tipo,
                        opciones: [
                          for (final t in tipos)
                            DropdownMenuEntry(value: t.codTipoDocumento, label: t.nombre),
                        ],
                        onElegir: (v) => setState(() => _tipo = v),
                      ),
                      if (_intento && _tipo == null)
                        Padding(
                          padding: const EdgeInsets.only(top: Esp.xs, left: Esp.m),
                          child: Text(
                            'Elige el tipo de documento.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
                          ),
                        ),
                      const SizedBox(height: Esp.l),
                      TextFormField(
                        controller: _detalle,
                        enabled: !_guardando,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Detalle *',
                          hintText: 'Facturas emisores septiembre 2016',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Escribe el detalle.' : null,
                      ),
                      const SizedBox(height: Esp.m),
                      TextFormField(
                        controller: _gestion,
                        enabled: !_guardando,
                        maxLength: 60,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Gestión',
                          hintText: '2019 o 2018 - 2019',
                          helperText:
                              desde == null
                                  ? 'Opcional. Se busca por los años que incluya.'
                                  : 'Años que cubre: ${rangoAnios(desde, hasta)}',
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: _validarGestion,
                      ),
                      const SizedBox(height: Esp.l),
                      DropdownButtonFormField<int?>(
                        value: widget.empresas.any((e) => e.codEmpresa == _empresa) ? _empresa : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Empresa',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Sin empresa (otros)')),
                          for (final e in widget.empresas)
                            DropdownMenuItem<int?>(value: e.codEmpresa, child: Text(e.nombre)),
                        ],
                        onChanged: _guardando ? null : (v) => setState(() => _empresa = v),
                      ),
                      const SizedBox(height: Esp.l),
                      TextFormField(
                        controller: _observacion,
                        enabled: !_guardando,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Observación',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PieFicha(
              etiqueta: _esAlta ? 'Agregar documento' : 'Guardar cambios',
              ocupado: _guardando,
              onGuardar: _guardar,
              semilla: TonosArchivo.documentos,
            ),
          ],
        ),
      ),
    );
  }
}

String? _nullSiVacio(String v) {
  final t = v.trim();
  return t.isEmpty ? null : t;
}
