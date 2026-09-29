import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/presentation/widgets/precios/ancho_dialogo.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_ext_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';

/// El armazón de los formularios de catálogo del módulo de precios: título, el
/// error del backend arriba de los campos, el botón que se apaga mientras la
/// escritura viaja y el ancho máximo del cuerpo.
///
/// El error se muestra adentro y el formulario NO se cierra: el backend responde
/// con mensajes de negocio (nombre repetido, catálogo en uso) y cerrar obligaría
/// a reescribir todo para leer qué falló.
class MarcoFormulario extends StatelessWidget {
  const MarcoFormulario({
    super.key,
    required this.titulo,
    required this.formKey,
    required this.campos,
    required this.ocupado,
    required this.onGuardar,
    this.error,
    this.anchoMaximo = 420,
  });

  final String titulo;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final bool ocupado;
  final Object? error;
  final VoidCallback onGuardar;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) => PopScope(
    // Mientras graba no se cierra (atras, Escape o la barrera): el resultado
    // tiene que llegar para que la pantalla refresque lo grabado.
    canPop: !ocupado,
    child: AlertDialog(
      title: Text(titulo),
      // Scrollea: en un telefono con el teclado abierto el hueco util puede ser
      // de unos pocos centimetros y un formulario de seis campos no entra.
      content: SingleChildScrollView(
        child: SizedBox(
          width: anchoDialogo(context, anchoMaximo),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  MensajeError(error: error, compacto: true),
                  const SizedBox(height: Esp.m),
                ],
                ...campos,
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: ocupado ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: ocupado ? null : onGuardar,
          child:
              ocupado
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Guardar'),
        ),
      ],
    ),
  );
}

/// Nota de una sola linea dentro de un formulario.
class _Nota extends StatelessWidget {
  const _Nota(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: Esp.s),
          Expanded(child: Text(texto, style: context.apagado())),
        ],
      ),
    );
  }
}

// Color, tipo y presentación

/// Alta y edición de los catálogos de nombre y estado: colores, tipos de papel y
/// presentaciones (misma tabla de cinco columnas y mismo procedimiento de ABM).
///
/// El estado no se ofrece en el alta: los tres procedimientos fuerzan estado = 1
/// al insertar e ignoran lo que se mande, y un interruptor que no hace nada miente.
class FormularioNombreEstado extends StatefulWidget {
  const FormularioNombreEstado({
    super.key,
    required this.titulo,
    required this.etiquetaCampo,
    required this.maxLargo,
    required this.esNuevo,
    required this.nombreInicial,
    required this.estadoInicial,
    required this.onGuardar,
    this.ayuda,
    this.textoActivo = 'Activo',
    this.textoInactivo = 'Inactivo',
  });

  final String titulo;
  final String etiquetaCampo;
  final String? ayuda;
  final int maxLargo;
  final bool esNuevo;
  final String nombreInicial;
  final int estadoInicial;
  final String textoActivo;
  final String textoInactivo;

  /// Escribe en el backend. Si lanza, el dialogo queda abierto con el mensaje.
  final Future<void> Function(String nombre, int estado) onGuardar;

  @override
  State<FormularioNombreEstado> createState() => _FormularioNombreEstadoState();
}

class _FormularioNombreEstadoState extends State<FormularioNombreEstado> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombreInicial,
  );
  late int _estado = widget.esNuevo ? 1 : widget.estadoInicial;

  bool _ocupado = false;
  Object? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.onGuardar(_nombre.text.trim(), _estado);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo: widget.titulo,
    formKey: _formKey,
    ocupado: _ocupado,
    error: _error,
    onGuardar: _guardar,
    campos: [
      TextFormField(
        controller: _nombre,
        enabled: !_ocupado,
        autofocus: true,
        maxLength: widget.maxLargo,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: '${widget.etiquetaCampo} *',
          helperText: widget.ayuda,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final texto = (v ?? '').trim();
          if (texto.isEmpty) return 'El nombre es obligatorio';
          if (texto.length > widget.maxLargo) {
            return 'Máximo ${widget.maxLargo} caracteres';
          }
          return null;
        },
      ),
      if (widget.esNuevo)
        const _Nota(
          'Todo registro nuevo nace activo: el estado se cambia '
          'después, desde la edición.',
        )
      else
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _estado == 1,
          onChanged:
              _ocupado ? null : (v) => setState(() => _estado = v ? 1 : 0),
          title: Text(_estado == 1 ? widget.textoActivo : widget.textoInactivo),
          subtitle: Text(
            _estado == 1
                ? 'Se puede elegir al cargar una familia.'
                : 'Queda fuera de las listas, sin borrar lo ya cargado.',
            style: context.apagado(),
          ),
        ),
    ],
  );
}

// Rango de gramaje

/// Alta y edición de un rango de gramaje.
///
/// Los dos límites se cargan por separado aunque la tabla muestre uno solo: lo
/// que se guarda son dos decimales independientes. Importan los decimales: min y
/// max son decimal(16,2), los únicos numéricos exactos del módulo (el modelo
/// viejo los mandaba a un parámetro entero y un 80,50 se guardaba como 80).
class FormularioRangoGramaje extends StatefulWidget {
  const FormularioRangoGramaje({
    super.key,
    required this.rango,
    required this.onGuardar,
  });

  /// Null en el alta.
  final RangoGramajeEntity? rango;

  final Future<void> Function(RangoGramajeEntity rango) onGuardar;

  @override
  State<FormularioRangoGramaje> createState() => _FormularioRangoGramajeState();
}

class _FormularioRangoGramajeState extends State<FormularioRangoGramaje> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _min = TextEditingController(
    text: widget.rango == null ? '' : _sinCerosDeMas(widget.rango!.min),
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.rango == null ? '' : _sinCerosDeMas(widget.rango!.max),
  );

  bool _ocupado = false;
  Object? _error;

  bool get _esNuevo => widget.rango == null;

  static String _sinCerosDeMas(double valor) =>
      valor == valor.roundToDouble()
          ? valor.toStringAsFixed(0)
          : valor.toStringAsFixed(2);

  /// Acepta coma o punto: el teclado numerico de Android manda coma y en el
  /// escritorio se escribe punto. La base guarda un decimal, no una cadena.
  static double? _aDecimal(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    return double.tryParse(limpio);
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  /// Valida un límite. El del tope compara además contra el piso: el intervalo
  /// invertido se avisa en el campo (del backend volvería un mensaje genérico).
  String? _validarLimite(
    String? valor,
    String nombre, {
    bool esMaximo = false,
  }) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'El $nombre es obligatorio';
    final numero = _aDecimal(texto);
    if (numero == null) return 'Escriba un número, por ejemplo 80.50';
    if (numero < 0) return 'No puede ser negativo';

    if (esMaximo) {
      final minimo = _aDecimal(_min.text);
      if (minimo != null && numero < minimo) {
        return 'No puede ser menor que el gramaje mínimo';
      }
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final min = _aDecimal(_min.text)!;
    final max = _aDecimal(_max.text)!;

    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.onGuardar(
        RangoGramajeEntity(
          idRangoGram: widget.rango?.idRangoGram ?? BigInt.zero,
          min: min,
          max: max,
          // El backend toma el usuario del token: lo que viaje aqui se descarta.
          audUsuario: BigInt.zero,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo:
        _esNuevo
            ? 'Nuevo rango de gramaje'
            : 'Editar ${widget.rango!.rangoLegible}',
    formKey: _formKey,
    ocupado: _ocupado,
    error: _error,
    onGuardar: _guardar,
    campos: [
      LayoutBuilder(
        builder: (context, cajon) {
          final campos = [
            _campoLimite(
              controlador: _min,
              etiqueta: 'Gramaje mínimo *',
              nombre: 'límite inferior',
              autofoco: true,
            ),
            _campoLimite(
              controlador: _max,
              etiqueta: 'Gramaje máximo *',
              nombre: 'límite superior',
              autofoco: false,
              esMaximo: true,
            ),
          ];

          // Los dos limites son un solo dato partido en dos: cuando entran, van
          // uno al lado del otro para que se lean como el intervalo que son.
          if (cajon.maxWidth >= 360) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: campos.first),
                const SizedBox(width: Esp.m),
                Expanded(child: campos.last),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              campos.first,
              const SizedBox(height: Esp.m),
              campos.last,
            ],
          );
        },
      ),
      const _Nota(
        'Se expresa en gramos por metro cuadrado y admite dos '
        'decimales. El intervalo incluye los dos extremos.',
      ),
    ],
  );

  Widget _campoLimite({
    required TextEditingController controlador,
    required String etiqueta,
    required String nombre,
    required bool autofoco,
    bool esMaximo = false,
  }) => TextFormField(
    controller: controlador,
    enabled: !_ocupado,
    autofocus: autofoco,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(
      labelText: etiqueta,
      suffixText: 'g/m²',
      border: const OutlineInputBorder(),
    ),
    validator: (v) => _validarLimite(v, nombre, esMaximo: esMaximo),
  );
}

// Grupo de familia SAP

/// Alta y edición de un grupo de familia SAP con su equivalencia de código en las
/// tres empresas.
///
/// Los tres códigos son TEXTO (varchar(20), admiten letras y ceros a la
/// izquierda; el procedimiento viejo los declaraba enteros y rompía los
/// alfanuméricos): no se convierten a número.
class FormularioGrupoFamiliaSap extends StatefulWidget {
  const FormularioGrupoFamiliaSap({
    super.key,
    required this.grupo,
    required this.onGuardar,
  });

  /// Null en el alta.
  final GrupoFamiliaSapEntity? grupo;

  final Future<void> Function(GrupoFamiliaSapEntity grupo) onGuardar;

  @override
  State<FormularioGrupoFamiliaSap> createState() =>
      _FormularioGrupoFamiliaSapState();
}

class _FormularioGrupoFamiliaSapState extends State<FormularioGrupoFamiliaSap> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _grpFam = TextEditingController(
    text: widget.grupo?.grpFam ?? '',
  );
  late final TextEditingController _alias = TextEditingController(
    text: widget.grupo?.alias ?? '',
  );
  late final TextEditingController _codIpx = TextEditingController(
    text: widget.grupo?.codGrpFamSap ?? '',
  );
  late final TextEditingController _codEpp = TextEditingController(
    text: widget.grupo?.codGrpFamSapEpp ?? '',
  );
  late final TextEditingController _codProdPap = TextEditingController(
    text: widget.grupo?.codGrpFamSapProdPap ?? '',
  );

  bool _ocupado = false;
  Object? _error;

  bool get _esNuevo => widget.grupo == null;

  @override
  void dispose() {
    _grpFam.dispose();
    _alias.dispose();
    _codIpx.dispose();
    _codEpp.dispose();
    _codProdPap.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.onGuardar(
        GrupoFamiliaSapEntity(
          idGrpFamiliaSap: widget.grupo?.idGrpFamiliaSap ?? BigInt.zero,
          codGrpFamSap: _codIpx.text.trim(),
          codGrpFamSapEpp: _codEpp.text.trim(),
          codGrpFamSapProdPap: _codProdPap.text.trim(),
          grpFam: _grpFam.text.trim(),
          alias: _alias.text.trim(),
          audUsuario: BigInt.zero,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo:
        _esNuevo
            ? 'Nuevo grupo de familia SAP'
            : 'Editar ${widget.grupo!.nombreVisible}',
    anchoMaximo: 560,
    formKey: _formKey,
    ocupado: _ocupado,
    error: _error,
    onGuardar: _guardar,
    campos: [
      TextFormField(
        controller: _grpFam,
        enabled: !_ocupado,
        autofocus: true,
        maxLength: 150,
        decoration: const InputDecoration(
          labelText: 'Grupo de familia *',
          border: OutlineInputBorder(),
        ),
        validator:
            (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'El nombre del grupo es obligatorio'
                    : null,
      ),
      const SizedBox(height: Esp.s),
      TextFormField(
        controller: _alias,
        enabled: !_ocupado,
        maxLength: 250,
        decoration: const InputDecoration(
          labelText: 'Alias',
          helperText: 'Nombre corto: es el que se muestra en las tarjetas.',
          helperMaxLines: 2,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: Esp.s),
      Text('Códigos SAP por empresa', style: context.tituloSeccion()),
      const SizedBox(height: Esp.s),
      LayoutBuilder(
        builder: (context, cajon) {
          final campos = [
            _campoCodigo(_codIpx, 'IMPEXPAP'),
            _campoCodigo(_codEpp, 'ESPPAPEL'),
            _campoCodigo(_codProdPap, 'PRODUCTIVA'),
          ];

          // Tres codigos de veinte caracteres entran en una fila en el
          // escritorio; en un telefono no, y apretarlos los vuelve ilegibles.
          if (cajon.maxWidth >= 480) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < campos.length; i++) ...[
                  if (i > 0) const SizedBox(width: Esp.m),
                  Expanded(child: campos[i]),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < campos.length; i++) ...[
                if (i > 0) const SizedBox(height: Esp.m),
                campos[i],
              ],
            ],
          );
        },
      ),
      const _Nota(
        'Un código vacío deja al grupo sin mapear en esa empresa y '
        'borra el que estuviera guardado. Son textos: admiten letras y ceros '
        'a la izquierda.',
      ),
    ],
  );

  Widget _campoCodigo(TextEditingController controlador, String empresa) =>
      TextFormField(
        controller: controlador,
        enabled: !_ocupado,
        maxLength: 20,
        decoration: InputDecoration(
          labelText: empresa,
          counterText: '',
          border: const OutlineInputBorder(),
        ),
      );
}

// Proveedor externo SAP

/// Alta y edición de un proveedor externo de SAP.
///
/// El nombre no se trunca: el backend lo rechaza. La columna es varchar(50)
/// aunque el parámetro del procedimiento declare 200; el límite se avisa en el
/// campo, antes de enviar.
class FormularioProveedorSap extends StatefulWidget {
  const FormularioProveedorSap({
    super.key,
    required this.proveedor,
    required this.onGuardar,
  });

  /// Null en el alta.
  final ProveedorExtSapEntity? proveedor;

  final Future<void> Function(ProveedorExtSapEntity proveedor) onGuardar;

  @override
  State<FormularioProveedorSap> createState() => _FormularioProveedorSapState();
}

class _FormularioProveedorSapState extends State<FormularioProveedorSap> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigo = TextEditingController(
    text: widget.proveedor?.codProvExtSap ?? '',
  );
  late final TextEditingController _nombre = TextEditingController(
    text: widget.proveedor?.proveedorExtSap ?? '',
  );

  bool _ocupado = false;
  Object? _error;

  bool get _esNuevo => widget.proveedor == null;

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.onGuardar(
        ProveedorExtSapEntity(
          idProveedorSap: widget.proveedor?.idProveedorSap ?? BigInt.zero,
          codProvExtSap: _codigo.text.trim(),
          proveedorExtSap: _nombre.text.trim(),
          audUsuario: BigInt.zero,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo:
        _esNuevo
            ? 'Nuevo proveedor SAP'
            : 'Editar ${widget.proveedor!.nombreLegible}',
    formKey: _formKey,
    ocupado: _ocupado,
    error: _error,
    onGuardar: _guardar,
    campos: [
      TextFormField(
        controller: _nombre,
        enabled: !_ocupado,
        autofocus: true,
        maxLength: 50,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Proveedor *',
          helperText: 'Hasta 50 caracteres: un nombre más largo se rechaza.',
          helperMaxLines: 2,
          border: OutlineInputBorder(),
        ),
        validator: (v) {
          final texto = (v ?? '').trim();
          if (texto.isEmpty) return 'El nombre es obligatorio';
          if (texto.length > 50) return 'Máximo 50 caracteres';
          return null;
        },
      ),
      const SizedBox(height: Esp.s),
      TextFormField(
        controller: _codigo,
        enabled: !_ocupado,
        maxLength: 20,
        decoration: const InputDecoration(
          labelText: 'Código SAP',
          helperText: 'Es texto: conserve los ceros a la izquierda.',
          helperMaxLines: 2,
          border: OutlineInputBorder(),
        ),
        validator: (v) {
          final texto = (v ?? '').trim();
          if (texto.length > 20) return 'Máximo 20 caracteres';
          return null;
        },
      ),
    ],
  );
}
