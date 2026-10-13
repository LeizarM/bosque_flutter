/// Alta y edición de un vehículo. Marca, placa y sucursal son obligatorias; el
/// año, si se escribe, tiene que ser razonable. Si el servidor rechaza (placa
/// repetida, sucursal inválida) el motivo se muestra en la ficha, que queda
/// abierta con lo que la persona escribió.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart'
    show sucursalesProvider;
import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';

/// Quien persiste la ficha. Lanza si el servidor la rechaza.
typedef GuardarCoche = Future<void> Function(CocheEntity coche);

/// Ancho a partir del cual los campos van de a dos por renglón.
const double _anchoDosColumnas = 520;

/// Los años que se aceptan: un vehículo anterior a esto no circula, y el modelo
/// del año siguiente ya se vende en el actual.
const int _anioMinimo = 1950;

class DialogoCoche extends ConsumerStatefulWidget {
  const DialogoCoche({
    super.key,
    this.editar,
    required this.onGuardar,
    this.mostrarAsa = true,
  });

  /// Null = alta.
  final CocheEntity? editar;
  final GuardarCoche onGuardar;

  /// El asa de arrastre de la hoja modal de móvil; el diálogo de escritorio
  /// no la lleva.
  final bool mostrarAsa;

  @override
  ConsumerState<DialogoCoche> createState() => _DialogoCocheState();
}

class _DialogoCocheState extends ConsumerState<DialogoCoche> {
  final _formulario = GlobalKey<FormState>();

  late final TextEditingController _placa;
  late final TextEditingController _marca;
  late final TextEditingController _clase;
  late final TextEditingController _anio;
  late final TextEditingController _color;

  int? _sucursal;
  late bool _activo;

  bool _guardando = false;
  bool _intentoGuardar = false;
  String? _errorServidor;

  bool get _esAlta => widget.editar == null;

  @override
  void initState() {
    super.initState();
    final c = widget.editar;
    _placa = TextEditingController(text: c?.placa ?? '');
    _marca = TextEditingController(text: c?.marca ?? '');
    _clase = TextEditingController(text: c?.clase ?? '');
    _anio = TextEditingController(text: c?.anio?.toString() ?? '');
    _color = TextEditingController(text: c?.color ?? '');
    _sucursal = c?.codSucursal;
    // Todo vehículo nuevo nace en uso: es lo que espera quien lo está creando.
    _activo = c?.esActivo ?? true;
  }

  @override
  void dispose() {
    _placa.dispose();
    _marca.dispose();
    _clase.dispose();
    _anio.dispose();
    _color.dispose();
    super.dispose();
  }

  String? _obligatorio(String? v, String campo) =>
      (v == null || v.trim().isEmpty) ? 'Escribe $campo.' : null;

  String? _validarAnio(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    final maximo = DateTime.now().year + 1;
    if (n == null || n < _anioMinimo || n > maximo) {
      return 'Un año entre $_anioMinimo y $maximo.';
    }
    return null;
  }

  String? _nullSiVacio(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _guardar() async {
    setState(() => _intentoGuardar = true);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final base = widget.editar;
    final coche = CocheEntity(
      idCoche: base?.idCoche ?? 0,
      placa: _placa.text.trim().toUpperCase(),
      marca: _marca.text.trim(),
      clase: _nullSiVacio(_clase.text),
      anio: int.tryParse(_anio.text.trim()),
      color: _nullSiVacio(_color.text),
      codSucursal: _sucursal,
      estado: _activo ? CocheEntity.activo : CocheEntity.inactivo,
      audUsuario: ref.read(userProvider)?.codUsuario ?? 0,
    );

    setState(() {
      _guardando = true;
      _errorServidor = null;
    });
    try {
      await widget.onGuardar(coche);
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
    final tt = Theme.of(context).textTheme;

    final catalogo = ref.watch(sucursalesProvider);
    final opciones = opcionesDeSucursal(
      catalogo: catalogo.valueOrNull,
      coches: [if (widget.editar != null) widget.editar!],
    );

    final titulo =
        _esAlta
            ? 'Nuevo vehículo'
            : 'Editar ${widget.editar!.placa?.trim() ?? 'vehículo'}';

    final autovalidar =
        _intentoGuardar
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled;

    return PopScope(
      // Mientras el guardado viaja la ficha no se cierra (atrás, Esc, toque
      // fuera): cerrada, el motivo del rechazo del servidor no tendría dónde
      // mostrarse y se perdería. Los botones ya están apagados por lo mismo.
      canPop: !_guardando,
      child: Padding(
        // En la hoja de móvil el teclado la empuja; en el diálogo lo resuelve el
        // propio `Dialog`.
        padding: EdgeInsets.only(
          bottom:
              widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mostrarAsa)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: Esp.s),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.s, Esp.s),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: tt.titleLarge?.copyWith(fontWeight: Peso.dato),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar sin guardar',
                    onPressed:
                        _guardando ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Form(
                  key: _formulario,
                  autovalidateMode: autovalidar,
                  child: LayoutBuilder(
                    builder: (context, r) {
                      final dos = r.maxWidth >= _anchoDosColumnas;
                      final ancho = dos ? (r.maxWidth - Esp.l) / 2 : r.maxWidth;

                      Widget campo(Widget hijo) =>
                          SizedBox(width: ancho, child: hijo);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorServidor != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: Esp.m),
                              child: NotaDelDato(
                                texto: _errorServidor!,
                                tono: TonoNota.error,
                              ),
                            ),
                          Wrap(
                            spacing: Esp.l,
                            runSpacing: Esp.l,
                            children: [
                              campo(
                                TextFormField(
                                  controller: _placa,
                                  enabled: !_guardando,
                                  maxLength: 50,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode: autovalidar,
                                  decoration: const InputDecoration(
                                    labelText: 'Placa *',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                  validator: (v) => _obligatorio(v, 'la placa'),
                                ),
                              ),
                              campo(
                                TextFormField(
                                  controller: _marca,
                                  enabled: !_guardando,
                                  maxLength: 50,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode: autovalidar,
                                  decoration: const InputDecoration(
                                    labelText: 'Marca *',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                  validator: (v) => _obligatorio(v, 'la marca'),
                                ),
                              ),
                              campo(
                                TextFormField(
                                  controller: _clase,
                                  enabled: !_guardando,
                                  maxLength: 50,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Clase',
                                    hintText: 'Camioneta, camión, minibús…',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              campo(
                                TextFormField(
                                  controller: _anio,
                                  enabled: !_guardando,
                                  maxLength: 4,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  autovalidateMode: autovalidar,
                                  decoration: const InputDecoration(
                                    labelText: 'Año',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                  validator: _validarAnio,
                                ),
                              ),
                              campo(
                                TextFormField(
                                  controller: _color,
                                  enabled: !_guardando,
                                  maxLength: 50,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Color',
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              campo(
                                DropdownButtonFormField<int>(
                                  value:
                                      opciones.any(
                                            (o) => o.codSucursal == _sucursal,
                                          )
                                          ? _sucursal
                                          : null,
                                  isExpanded: true,
                                  autovalidateMode: autovalidar,
                                  decoration: InputDecoration(
                                    labelText: 'Sucursal *',
                                    border: const OutlineInputBorder(),
                                    helperText: switch (catalogo) {
                                      AsyncLoading() => 'Cargando sucursales…',
                                      AsyncError() =>
                                        'No se pudo cargar el catálogo completo',
                                      _ => null,
                                    },
                                  ),
                                  items: [
                                    for (final o in opciones)
                                      DropdownMenuItem(
                                        value: o.codSucursal,
                                        child: Text(
                                          o.nombre,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged:
                                      _guardando
                                          ? null
                                          : (v) =>
                                              setState(() => _sucursal = v),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Elige la sucursal.'
                                              : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Esp.l),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Activo'),
                            subtitle: const Text(
                              'Un vehículo inactivo deja de usarse, pero '
                              'conserva su historial.',
                            ),
                            value: _activo,
                            onChanged:
                                _guardando
                                    ? null
                                    : (v) => setState(() => _activo = v),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Esp.l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: Esp.s),
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon:
                        _guardando
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.check, size: 18),
                    label: Text(_esAlta ? 'Crear vehículo' : 'Guardar cambios'),
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
