import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/clasificacion_precio_entity.dart';

/// Una sucursal que puede llevar listas de precio. El repositorio de precios no
/// expone un catálogo de sucursales (la tabla vive en otro módulo): se arman con
/// las que ya tienen alguna lista (`obtenerClasificacionesConSucursal()`) y el
/// formulario deja escribir el código de la que no tenga ninguna.
class OpcionSucursal {
  const OpcionSucursal({required this.codSucursal, required this.nombre});

  final BigInt codSucursal;
  final String nombre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpcionSucursal && other.codSucursal == codSucursal;

  @override
  int get hashCode => codSucursal.hashCode;
}

/// Valor centinela del combo: "la sucursal no esta en la lista, la escribo".
final BigInt _otraSucursal = BigInt.from(-1);

/// Alta y edición de una lista de precios (tpr_clasificacionPrecio). Reemplaza a
/// dlgClasi y dlgNClasi del sistema viejo (dos pantallas casi idénticas).
///
/// El vpp no puede repetirse: se verifica ANTES de enviar y el mensaje sale bajo
/// el campo, para no perder lo escrito al enterarse por el rechazo del backend.
class DialogoListaPrecio extends ConsumerStatefulWidget {
  const DialogoListaPrecio({
    super.key,
    required this.sucursales,
    required this.audUsuario,
    this.editar,
    this.mostrarAsa = true,
  });

  /// Sucursales que ofrece el combo. Puede venir vacia: en ese caso el
  /// formulario arranca directamente en "otra sucursal".
  final List<OpcionSucursal> sucursales;

  /// Usuario que queda en la auditoria de la fila.
  final int audUsuario;

  /// La lista que se esta editando. Null es un alta.
  final ClasificacionPrecioEntity? editar;

  /// false cuando el formulario se muestra dentro de un [Dialog] centrado: ese
  /// contenedor no se arrastra, asi que el asa de la hoja modal sobraria.
  final bool mostrarAsa;

  @override
  ConsumerState<DialogoListaPrecio> createState() => _DialogoListaPrecioState();
}

class _DialogoListaPrecioState extends ConsumerState<DialogoListaPrecio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _vppCtrl = TextEditingController();
  final _listNumCtrl = TextEditingController();
  final _codSucursalCtrl = TextEditingController();

  BigInt? _codSucursal;
  bool _activa = true;
  bool _guardando = false;

  /// El vpp que el backend ya rechazó por repetido. Se guarda el número y no una
  /// bandera para que el error desaparezca solo al escribir otro.
  int? _vppRechazado;

  bool get _esAlta => widget.editar == null;

  /// El vpp que la fila ya tenia antes de abrir el formulario. Una lista no
  /// choca consigo misma, asi que ese valor no cuenta como repetido.
  int? get _vppPropio => widget.editar?.vpp;

  @override
  void initState() {
    super.initState();
    final fila = widget.editar;
    if (fila != null) {
      _nombreCtrl.text = fila.nombrePrecio;
      _vppCtrl.text = fila.vpp.toString();
      _listNumCtrl.text =
          fila.listNum > BigInt.zero ? fila.listNum.toString() : '';
      _activa = fila.esActiva;

      final conocida = widget.sucursales.any(
        (s) => s.codSucursal == fila.codSucursal,
      );
      _codSucursal = conocida ? fila.codSucursal : _otraSucursal;
      if (!conocida) _codSucursalCtrl.text = fila.codSucursal.toString();
    } else if (widget.sucursales.isEmpty) {
      // Sin catalogo no hay nada que elegir: se arranca escribiendo el codigo.
      _codSucursal = _otraSucursal;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _vppCtrl.dispose();
    _listNumCtrl.dispose();
    _codSucursalCtrl.dispose();
    super.dispose();
  }

  /// Los vpp ya tomados, sin contar el de la fila en edición. Se refresca en cada
  /// dibujo y el validador lo lee (corre por tecla, fuera de un build: no puede
  /// observar el provider). La palabra final la tiene el backend en [_guardar].
  Set<int> _vppsTomados = const <int>{};

  String? _validarVpp(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Indique el VPP';
    final numero = int.tryParse(texto);
    if (numero == null) return 'El VPP debe ser un número';
    if (numero <= 0) return 'El VPP debe ser mayor que cero';
    if (numero == _vppRechazado) {
      return 'El VPP $numero ya está usado por otra lista';
    }
    if (_vppsTomados.contains(numero)) {
      return 'El VPP $numero ya está usado por otra lista';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;

    final vpp = int.parse(_vppCtrl.text.trim());
    final codSucursal =
        _codSucursal == _otraSucursal
            ? BigInt.parse(_codSucursalCtrl.text.trim())
            : _codSucursal!;

    setState(() => _guardando = true);
    // El contenedor y no `ref`: si el formulario se cerrara durante la
    // escritura, `ref` lanza y las lecturas quedaban viejas.
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final repo = contenedor.read(preciosRepositoryProvider);

    try {
      // Se verifica contra el backend antes del alta: la lista local de vpp puede
      // tener minutos de atraso si otro usuario creó una lista mientras tanto.
      final repetido = await repo.existeVpp(
        vpp: vpp,
        idClasificacion: widget.editar?.idClasificacion,
      );
      if (!mounted) return;
      if (repetido) {
        setState(() {
          _guardando = false;
          _vppRechazado = vpp;
        });
        // Re-valida para que el mensaje aparezca debajo del campo.
        _formKey.currentState!.validate();
        return;
      }

      final entidad = ClasificacionPrecioEntity(
        // En el alta va en cero: el procedimiento genera el id y lo devuelve.
        idClasificacion: widget.editar?.idClasificacion ?? BigInt.zero,
        codSucursal: codSucursal,
        listNum: BigInt.tryParse(_listNumCtrl.text.trim()) ?? BigInt.zero,
        nombrePrecio: _nombreCtrl.text.trim(),
        vpp: vpp,
        estado: _activa ? 1 : 0,
        audUsuario: BigInt.from(widget.audUsuario),
        // La sella el procedimiento con GETDATE(); el cliente no la manda.
        audFecha: null,
      );

      await repo.registrarClasificacionPrecio(entidad);

      // Lecturas que esta escritura deja viejas (la grilla se refresca sola). Van
      // antes del mounted: lo grabado debe aparecer aunque el formulario ya no esté.
      contenedor.invalidate(clasificacionesConSucursalProvider);
      contenedor.invalidate(clasificacionesPrecioProvider);
      contenedor.invalidate(vppsUsadosProvider);
      contenedor.invalidate(existeVppProvider);
      if (!mounted) return;

      Navigator.of(context).pop();
      mostrarAviso(
        context,
        _esAlta ? 'Lista de precios creada' : 'Lista de precios actualizada',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      // El backend manda el mensaje de negocio listo para mostrar. El
      // formulario queda abierto con lo que el usuario escribio.
      mostrarAviso(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        tono: TonoAviso.error,
      );
    }
  }

  String _nombreSucursal(BigInt codSucursal) {
    for (final s in widget.sucursales) {
      if (s.codSucursal == codSucursal) return s.nombre;
    }
    return 'Sucursal $codSucursal';
  }

  Widget _campoVpp() => TextFormField(
    controller: _vppCtrl,
    enabled: !_guardando,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: const InputDecoration(
      labelText: 'VPP',
      helperText: 'No puede repetirse',
      prefixIcon: Icon(Icons.tag),
    ),
    validator: _validarVpp,
    // Al cambiar el numero, el rechazo del backend deja de valer.
    onChanged: (_) {
      if (_vppRechazado != null) setState(() => _vppRechazado = null);
    },
  );

  Widget _campoListaSap() => TextFormField(
    controller: _listNumCtrl,
    enabled: !_guardando,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: const InputDecoration(
      labelText: 'Lista SAP',
      helperText: 'Vacío si no está enlazada',
      prefixIcon: Icon(Icons.link),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final escribeCodigo = _codSucursal == _otraSucursal;

    // valueOrNull y no value: con la lectura en error, `value` relanza en pleno
    // build y el diálogo se vuelve pantalla roja. Sin la lista de usados el
    // formulario funciona igual: el servidor rechaza un vpp repetido al guardar.
    final usados = ref.watch(vppsUsadosProvider).valueOrNull ?? const <int>[];
    _vppsTomados = usados.where((v) => v != _vppPropio).toSet();

    return PopScope(
      canPop: !_guardando,
      child: Padding(
        padding: EdgeInsets.only(
          left: Esp.l,
          right: Esp.l,
          top: Esp.l,
          // El teclado del telefono no puede taparle el boton Guardar.
          bottom: MediaQuery.viewInsetsOf(context).bottom + Esp.l,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.mostrarAsa)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: Esp.m),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Text(
                  _esAlta
                      ? 'Nueva lista de precios'
                      : 'Editar lista de precios',
                  style: tt.titleMedium?.copyWith(fontWeight: Peso.dato),
                ),
                if (!_esAlta)
                  Padding(
                    padding: const EdgeInsets.only(top: Esp.xs),
                    child: Text(
                      '${_nombreSucursal(widget.editar!.codSucursal)} · '
                      'VPP ${widget.editar!.vpp}',
                      style: context.apagado(),
                    ),
                  ),
                const SizedBox(height: Esp.l),

                // Sucursal
                DropdownButtonFormField<BigInt>(
                  value: _codSucursal,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  items: [
                    for (final s in widget.sucursales)
                      DropdownMenuItem<BigInt>(
                        value: s.codSucursal,
                        child: Text(s.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    DropdownMenuItem<BigInt>(
                      value: _otraSucursal,
                      child: Text(
                        'Otra sucursal (indicar código)',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                  validator: (v) => v == null ? 'Elija una sucursal' : null,
                  onChanged:
                      _guardando
                          ? null
                          : (v) => setState(() => _codSucursal = v),
                ),
                if (escribeCodigo) ...[
                  const SizedBox(height: Esp.m),
                  TextFormField(
                    controller: _codSucursalCtrl,
                    enabled: !_guardando,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Código de sucursal',
                      helperText: 'Solo si la sucursal todavía no tiene listas',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (v) {
                      final texto = (v ?? '').trim();
                      if (texto.isEmpty) return 'Indique el código de sucursal';
                      final numero = int.tryParse(texto);
                      if (numero == null || numero <= 0) {
                        return 'El código debe ser un número mayor que cero';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: Esp.m),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  // La columna admite 100 caracteres: cortar aquí evita que el procedimiento
                  // trunque sin avisar.
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la lista',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) {
                    final texto = (v ?? '').trim();
                    if (texto.isEmpty) return 'Indique el nombre de la lista';
                    return null;
                  },
                ),
                const SizedBox(height: Esp.xs),

                // VPP y lista SAP, lado a lado: son los dos números que identifican la lista
                // (Bosque y SAP) y se revisan juntos.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campoVpp()),
                    const SizedBox(width: Esp.m),
                    Expanded(child: _campoListaSap()),
                  ],
                ),
                const SizedBox(height: Esp.s),

                // Estado
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _activa,
                  onChanged:
                      _guardando ? null : (v) => setState(() => _activa = v),
                  title: const Text('Lista activa'),
                  subtitle: Text(
                    _activa
                        ? 'Se reprecia y aparece en Precios vigentes y en '
                            'Porcentajes.'
                        : 'No se reprecia ni aparece en Precios vigentes. Sus '
                            'precios y porcentajes no se borran.',
                    style: context.apagado(),
                  ),
                ),
                const SizedBox(height: Esp.l),

                // Acciones
                Row(
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save_outlined),
                      label: Text(_esAlta ? 'Crear' : 'Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
