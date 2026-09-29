/// Alta y edicion de una familia de producto.
///
/// Reemplaza a los dialogos `dlgDtFam`, `dlgFam` y `dlgProdV` del monolito, que
/// eran tres ventanas distintas para cargar la misma fila de `tpr_producto`.
///
/// ## Las tres trampas de esta pantalla
///
/// **1. La PK la escribe el usuario.** `codigoFamilia` es `int` y NO es
/// autogenerada: no hay IDENTITY que la resuelva. Asi que el alta tiene un campo
/// de codigo, y antes de grabar hay que saber si ese numero ya esta tomado — de
/// otro modo el error llega desde la base, en ingles y con el formulario ya
/// perdido. La verificacion se hace contra `PreciosRepository.obtenerFamilia`,
/// que devuelve null cuando el codigo no existe, y corre mientras se escribe,
/// con una espera para no pegarle al backend una vez por tecla. En la edicion el
/// campo queda bloqueado: cambiar la PK no es editar, es otra familia.
///
/// **2. Los combos solo listan lo activo.** En la base hay colores, tipos y
/// presentaciones dados de baja; ofrecerlos aca seria dejar que una familia
/// nueva nazca apuntando a un catalogo muerto. Se usan las lecturas `*Activos`
/// del repositorio, que existen exactamente para esto. La contracara esta
/// contemplada: si se esta editando una familia que ya apunta a algo inactivo,
/// ese valor no aparece en la lista y el formulario lo dice en lugar de
/// cambiarlo por su cuenta.
///
/// **3. Formato y gramaje no se cargan.** Son columnas de `tpr_producto`, pero
/// estan vacias en toda la base y el dialogo del sistema anterior no las
/// pedia. La ficha no las muestra y, al editar, devuelve lo que la familia ya
/// tenga para no borrarlo.
///
/// ## Porcentaje por familia
///
/// Como en el dialogo "Registro de familias" del sistema anterior, la ficha
/// trae la grilla de porcentajes por sucursal y lista de precio, y se guarda
/// con la familia en la misma transaccion (ver `porcentajes_ficha_familia.dart`).
///
/// ## SAP
///
/// Al abrirse, la ficha dispara la sincronizacion de grupos y proveedores con
/// SAP de la sesion (`p_abm_producto 'H'`), que el sistema anterior corria al
/// abrir la pantalla de precios.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/producto_familia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/historial_costo_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_datos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_ficha_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/sincronizacion_sap.dart';

/// Ancho de campo en la version de dos columnas.
const double _anchoCampo = 268;

/// Quien persiste la ficha: la familia y, si la grilla llego, sus porcentajes
/// (todos en el alta, solo los que cambiaron en la edicion).
typedef GuardarFamilia =
    Future<void> Function(
      ProductoFamiliaEntity familia,
      List<PorcentajePrecioEntity>? porcentajes,
    );

class DialogoFamilia extends ConsumerStatefulWidget {
  const DialogoFamilia({
    super.key,
    this.editar,
    this.plantilla,
    this.onGuardar,
    this.mostrarAsa = true,
  });

  /// Null = alta. Con valor = edicion de esa familia.
  final FamiliaVista? editar;

  /// Solo en el alta: la familia de la que se copian los datos -todo menos el
  /// codigo, que es la llave nueva-. Casi toda familia nueva es la variante de
  /// otra: mismo grupo, proveedor y presentacion, otro gramaje o color.
  final FamiliaVista? plantilla;

  /// Quien persiste. En null el formulario queda en modo consulta: se valida
  /// todo pero el boton de guardar no se habilita. La pantalla de Familias
  /// siempre lo pasa.
  final GuardarFamilia? onGuardar;

  /// El asa de arrastre de la hoja modal de movil. En el dialogo de escritorio
  /// no va.
  final bool mostrarAsa;

  @override
  ConsumerState<DialogoFamilia> createState() => _DialogoFamiliaState();
}

class _DialogoFamiliaState extends ConsumerState<DialogoFamilia> {
  final _formulario = GlobalKey<FormState>();

  late final TextEditingController _codigo;
  final _porcentajes = PorcentajesFicha();

  // Null = todavia no lo toco nadie. En la edicion eso significa "usa lo que ya
  // tiene la familia", que se resuelve en `_resuelto`. No se guarda el valor
  // derivado en el estado para no tener que escribir en `setState` durante el
  // primer `build`, que es cuando recien llegan los catalogos.
  BigInt? _grupo;
  BigInt? _proveedor;
  BigInt? _presentacion;
  BigInt? _tipo;
  BigInt? _rango;
  BigInt? _color;

  late bool _activa;

  Timer? _reloj;
  bool _verificando = false;

  /// El codigo tipeado ya pertenece a otra familia. Se guarda el codigo
  /// verificado junto al resultado para no mostrar el cartel de un numero que
  /// ya se borro.
  int? _codigoTomado;

  bool _guardando = false;
  bool _intentoGuardar = false;

  bool get _esAlta => widget.editar == null;

  @override
  void initState() {
    super.initState();
    final f = widget.editar;
    _codigo = TextEditingController(text: f == null ? '' : f.codigoLegible);
    // Toda familia nueva nace activa: es lo que espera quien la esta creando.
    _activa = f?.esActiva ?? true;
    // Grupos y proveedores nuevos de SAP, una vez por sesion. En modo consulta
    // no: es una escritura.
    if (widget.onGuardar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(sincronizacionSapProvider.notifier).asegurar();
      });
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _codigo.dispose();
    _porcentajes.dispose();
    super.dispose();
  }

  // ── El codigo ya existe ───────────────────────────────────────────────────

  void _verificarCodigo(String texto) {
    _reloj?.cancel();
    final codigo = int.tryParse(texto.trim());

    if (codigo == null || codigo <= 0) {
      if (_codigoTomado != null || _verificando) {
        setState(() {
          _codigoTomado = null;
          _verificando = false;
        });
      }
      return;
    }

    setState(() => _verificando = true);
    _reloj = Timer(const Duration(milliseconds: 500), () async {
      try {
        final existente = await ref
            .read(preciosRepositoryProvider)
            .obtenerFamilia(codigo);
        if (!mounted) return;
        // El campo pudo cambiar mientras la consulta viajaba: si ya no es el
        // mismo numero, el resultado no describe nada de lo que hay en pantalla.
        if (int.tryParse(_codigo.text.trim()) != codigo) return;
        setState(() {
          _verificando = false;
          _codigoTomado = existente == null ? null : codigo;
        });
      } catch (_) {
        if (!mounted) return;
        // Que la verificacion falle no bloquea el formulario: el backend vuelve
        // a validar al grabar y ahi si el mensaje es definitivo.
        setState(() => _verificando = false);
      }
    });
  }

  // ── Resolucion de los combos ──────────────────────────────────────────────

  /// Que id mostrar en un combo: lo que eligio la persona, si eligio; si no, lo
  /// que ya tiene la familia.
  ///
  /// El listado de familias devuelve las descripciones resueltas y no los ids
  /// (asi esta documentado el DTO en `PreciosRepository.obtenerFamilias`), asi
  /// que cuando el id no viene se empareja por nombre contra el catalogo. Es
  /// exacto mientras los nombres no se repitan, que es lo que ya asume la
  /// pantalla vieja al mostrarlos.
  BigInt? _resuelto<T>({
    required BigInt? elegido,
    required BigInt? idDelDto,
    required AsyncValue<List<T>> catalogo,
    required BigInt Function(T) id,
    required String descripcion,
    required List<String> Function(T) nombres,
  }) {
    if (elegido != null) return elegido;
    if (idDelDto != null) return idDelDto;

    // valueOrNull y no value: con el catalogo en error, value relanza la
    // excepcion en pleno build y la ficha entera se vuelve un ErrorWidget.
    final datos = catalogo.valueOrNull;
    final buscado = descripcion.trim().toLowerCase();
    if (datos == null || buscado.isEmpty) return null;

    for (final d in datos) {
      for (final n in nombres(d)) {
        if (n.trim().toLowerCase() == buscado) return id(d);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Los combos arrancan en lo que tiene la familia que se edita o, en un alta
    // a partir de otra, en lo de la plantilla.
    final f = widget.editar ?? widget.plantilla;

    // Los catalogos de los combos: SOLO ACTIVOS. Ver la trampa 2 del encabezado.
    final grupos = ref.watch(gruposFamiliaSapProvider);
    final proveedores = ref.watch(proveedoresSapComboProvider);
    final presentaciones = ref.watch(presentacionesActivasProvider);
    final tipos = ref.watch(tiposProductoActivosProvider);
    final rangos = ref.watch(rangosGramajeComboProvider);
    final colores = ref.watch(coloresActivosProvider);

    // Opcionales: sin dato en la familia, el combo muestra "Sin asignar".
    final sinGrupo = f != null && f.grupoFamiliaSap.trim().isEmpty;
    final sinProveedor = f != null && f.proveedorSap.trim().isEmpty;
    final grupo = _resuelto(
      elegido: _grupo ?? (sinGrupo ? BigInt.zero : null),
      idDelDto: f?.idGrpFamiliaSap,
      catalogo: grupos,
      id: (g) => g.idGrpFamiliaSap,
      descripcion: f?.grupoFamiliaSap ?? '',
      nombres: (g) => [g.grpFam, g.alias, g.nombreVisible],
    );
    final proveedor = _resuelto(
      elegido: _proveedor ?? (sinProveedor ? BigInt.zero : null),
      idDelDto: f?.idProveedorSap,
      catalogo: proveedores,
      id: (p) => p.idProveedorSap,
      descripcion: f?.proveedorSap ?? '',
      nombres: (p) => [p.proveedorExtSap, p.nombreLegible, p.etiquetaCompleta],
    );
    final presentacion = _resuelto(
      elegido: _presentacion,
      idDelDto: f?.idPresentacion,
      catalogo: presentaciones,
      id: (p) => p.idPresentacion,
      descripcion: f?.presentacion ?? '',
      nombres: (p) => [p.presentacion, p.nombreLegible],
    );
    final tipo = _resuelto(
      elegido: _tipo,
      idDelDto: f?.idTipo,
      catalogo: tipos,
      id: (t) => t.idTipo,
      descripcion: f?.tipo ?? '',
      nombres: (t) => [t.tipo, t.nombreLegible],
    );
    final rango = _resuelto(
      elegido: _rango,
      idDelDto: f?.idRangoGram,
      catalogo: rangos,
      id: (r) => r.idRangoGram,
      descripcion: f?.rangoGramaje ?? '',
      // El listado arma la etiqueta "[ 80.00 - 120.00 ]" y la entity la
      // reconstruye igual; se prueban las dos formas por si el DTO cambia.
      nombres: (r) => [r.rangoConDecimales, r.rangoLegible],
    );
    final color = _resuelto(
      elegido: _color,
      idDelDto: f?.idColor,
      catalogo: colores,
      id: (c) => c.idColor,
      descripcion: f?.color ?? '',
      nombres: (c) => [c.color, c.nombreVisible],
    );

    // La grilla "Porcentaje por familia": en la edicion, la de la familia; en
    // el alta, las listas activas en 0 %, con los porcentajes de la plantilla
    // si la familia nace a partir de otra.
    final grilla =
        _esAlta
            ? ref.watch(listasParaPorcentajeProvider)
            : ref.watch(
              porcentajesPorFamiliaProvider(widget.editar!.codigoFamilia),
            );
    final plantilla = widget.plantilla;
    final dePlantilla =
        _esAlta && plantilla != null
            ? ref.watch(porcentajesPorFamiliaProvider(plantilla.codigoFamilia))
            : null;
    if (!_porcentajes.cargada &&
        grilla.hasValue &&
        (dePlantilla == null || !dePlantilla.isLoading)) {
      final copiados = dePlantilla?.valueOrNull?.map(FilaPorcentaje.deMapa);
      _porcentajes.cargar(
        grilla.requireValue.map(FilaPorcentaje.deMapa).toList(),
        valores:
            copiados == null
                ? null
                : {for (final c in copiados) c.idClasificacion: c.porcen},
      );
    }

    // Lo que la familia tiene cargado pero el catalogo activo ya no ofrece.
    final noResueltos = <String>[
      if (!_esAlta && presentacion == null && f!.presentacion.isNotEmpty)
        'presentación',
      if (!_esAlta && tipo == null && f!.tipo.isNotEmpty) 'tipo',
      if (!_esAlta && rango == null && f!.rangoGramaje.isNotEmpty)
        'rango de gramaje',
      if (!_esAlta && color == null && f!.color.isNotEmpty) 'color',
    ];

    return PopScope(
      // Mientras graba no se cierra: el resultado tiene que llegar a la
      // ficha para que cierre sola con lo grabado.
      canPop: !_guardando,
      child: LayoutBuilder(
        builder: (context, restricciones) {
          // El ancho del CAJON: este mismo widget es una hoja modal en un telefono
          // y un dialogo centrado en escritorio.
          final compacto = Aire.de(restricciones.maxWidth).esChico;

          return SafeArea(
            top: false,
            child: Padding(
              // Deja subir el contenido cuando aparece el teclado, que en un
              // telefono se come mas de la mitad de la hoja.
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.mostrarAsa)
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: Esp.m),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(Esquina.pastilla),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Esp.xl,
                      Esp.l,
                      Esp.xl,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            !_esAlta
                                ? 'Familia ${widget.editar!.codigoLegible}'
                                : widget.plantilla == null
                                ? 'Nueva familia de producto'
                                : 'Nueva familia a partir de la '
                                    '${widget.plantilla!.codigoLegible}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: Peso.titulo),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Cerrar',
                          onPressed: _guardando ? null : _cerrar,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        Esp.xl,
                        Esp.m,
                        Esp.xl,
                        Esp.l,
                      ),
                      child: Form(
                        key: _formulario,
                        autovalidateMode:
                            _intentoGuardar
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.onGuardar == null)
                              const NotaDelDato(
                                tono: TonoNota.aviso,
                                texto:
                                    'Esta ficha está en modo consulta: los datos se '
                                    'validan pero no se pueden guardar.',
                              ),
                            if (noResueltos.isNotEmpty)
                              NotaDelDato(
                                tono: TonoNota.aviso,
                                texto:
                                    'Esta familia usa ${noResueltos.join(', ')} '
                                    'que ya no figura entre los activos del '
                                    'catálogo. El combo quedó vacío: elija un valor '
                                    'vigente o el dato anterior se pierde al '
                                    'guardar.',
                              ),
                            const SizedBox(height: Esp.l),
                            _Seccion('Identificación'),
                            _campos(compacto, [_campoCodigo(), _campoEstado()]),
                            const SizedBox(height: Esp.l),
                            _Seccion('Clasificación'),
                            if (widget.onGuardar != null)
                              const LineaSincronizacionSap(),
                            _campos(compacto, [
                              _combo(
                                etiqueta: 'Grupo de familia SAP',
                                catalogo: grupos,
                                valor: grupo,
                                id: (g) => g.idGrpFamiliaSap,
                                rotulo: (g) => g.nombreVisible,
                                onElegir: (v) => setState(() => _grupo = v),
                                opcional: true,
                              ),
                              _combo(
                                etiqueta: 'Proveedor SAP',
                                catalogo: proveedores,
                                valor: proveedor,
                                id: (p) => p.idProveedorSap,
                                rotulo: (p) => p.nombreLegible,
                                onElegir: (v) => setState(() => _proveedor = v),
                                opcional: true,
                              ),
                              _combo(
                                etiqueta: 'Presentación',
                                catalogo: presentaciones,
                                valor: presentacion,
                                id: (p) => p.idPresentacion,
                                rotulo: (p) => p.nombreLegible,
                                onElegir:
                                    (v) => setState(() => _presentacion = v),
                              ),
                              _combo(
                                etiqueta: 'Tipo',
                                catalogo: tipos,
                                valor: tipo,
                                id: (t) => t.idTipo,
                                rotulo: (t) => t.nombreLegible,
                                onElegir: (v) => setState(() => _tipo = v),
                              ),
                              _combo(
                                etiqueta: 'Rango de gramaje',
                                catalogo: rangos,
                                valor: rango,
                                id: (r) => r.idRangoGram,
                                rotulo: (r) => r.rangoLegible,
                                onElegir: (v) => setState(() => _rango = v),
                              ),
                              _combo(
                                etiqueta: 'Color',
                                catalogo: colores,
                                valor: color,
                                id: (c) => c.idColor,
                                rotulo: (c) => c.nombreVisible,
                                onElegir: (v) => setState(() => _color = v),
                              ),
                            ]),
                            const SizedBox(height: Esp.l),
                            _Seccion('Porcentaje por familia'),
                            Text(
                              !_esAlta
                                  ? 'El margen de la familia en cada lista de '
                                      'precio activa. Se guardan solo los que '
                                      'cambie.'
                                  : plantilla != null
                                  ? 'Copiados de la familia '
                                      '${plantilla.codigoLegible}. Revíselos: se '
                                      'guardan con la familia.'
                                  : 'Las listas activas arrancan en 0 %. Se '
                                      'guardan con la familia; también puede '
                                      'cargarlos después en Porcentajes.',
                              style: context.apagado(),
                            ),
                            const SizedBox(height: Esp.m),
                            _grillaPorcentajes(grilla),
                            if (!_esAlta) ...[
                              _Seccion('Solo lectura'),
                              _soloLectura(compacto, widget.editar!),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed:
                                      () => mostrarHistorialCosto(
                                        context,
                                        widget.editar!,
                                      ),
                                  icon: const Icon(
                                    Icons.timeline_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Ver historial del costo'),
                                ),
                              ),
                            ],
                          ],
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
                          onPressed: _guardando ? null : _cerrar,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: Esp.s),
                        Tooltip(
                          message:
                              widget.onGuardar == null
                                  ? 'Ficha en modo consulta'
                                  : '',
                          child: BotonAccion(
                            etiqueta: _esAlta ? 'Crear familia' : 'Guardar',
                            etiquetaOcupado: 'Guardando…',
                            icono: Icons.save_outlined,
                            ocupado: _guardando,
                            onPressed:
                                widget.onGuardar == null
                                    ? null
                                    : () => _guardar(
                                      grupo: grupo,
                                      proveedor: proveedor,
                                      presentacion: presentacion,
                                      tipo: tipo,
                                      rango: rango,
                                      color: color,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Piezas del formulario ─────────────────────────────────────────────────

  /// Dos columnas cuando hay ancho, una sola cuando no. No es la misma grilla
  /// escalada: en un telefono un campo por renglon es lo unico que se lee.
  Widget _campos(bool compacto, List<Widget> campos) {
    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in campos) ...[c, const SizedBox(height: Esp.m)],
        ],
      );
    }
    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.m,
      children: [
        for (final c in campos) SizedBox(width: _anchoCampo, child: c),
      ],
    );
  }

  Widget _campoCodigo() => TextFormField(
    controller: _codigo,
    enabled: _esAlta,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: _esAlta ? _verificarCodigo : null,
    decoration: InputDecoration(
      isDense: true,
      border: const OutlineInputBorder(),
      labelText: 'Código de familia *',
      helperText:
          _esAlta
              ? 'Lo asigna usted: no lo genera el sistema'
              : 'No se puede cambiar: identifica la familia',
      suffixIcon:
          _verificando
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
    validator: (v) {
      if (!_esAlta) return null;
      final codigo = int.tryParse((v ?? '').trim());
      if (codigo == null || codigo <= 0) {
        return 'Escriba un código mayor que cero';
      }
      if (_codigoTomado == codigo) {
        return 'Ese código ya pertenece a otra familia';
      }
      return null;
    },
  );

  Widget _campoEstado() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: _activa,
    onChanged: (v) => setState(() => _activa = v),
    title: const Text('Familia activa'),
    subtitle: Text(
      _activa
          ? 'Se puede usar en propuestas y artículos'
          : 'Queda fuera de las listas de trabajo',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );

  Widget _grillaPorcentajes(AsyncValue<List<Map<String, dynamic>>> grilla) {
    void reintentar() {
      if (_esAlta) {
        ref.invalidate(listasParaPorcentajeProvider);
      } else {
        ref.invalidate(
          porcentajesPorFamiliaProvider(widget.editar!.codigoFamilia),
        );
      }
    }

    return switch (grilla) {
      AsyncError(:final error) => NotaDelDato(
        tono: TonoNota.aviso,
        texto:
            'No se pudieron traer las listas de precio: '
            '${textoParaUsuario(error)}. Si guarda así, la familia queda sin '
            'porcentajes y los puede cargar después en Porcentajes.',
        accion: TextButton(
          onPressed: reintentar,
          child: const Text('Reintentar'),
        ),
      ),
      AsyncData(:final value) when value.isEmpty => const NotaDelDato(
        texto: 'No hay listas de precio activas.',
      ),
      _ when !_porcentajes.cargada => const Padding(
        padding: EdgeInsets.symmetric(vertical: Esp.m),
        child: LinearProgressIndicator(),
      ),
      _ => GrillaPorcentajesFicha(
        porcentajes: _porcentajes,
        mostrarErrores: _intentoGuardar,
      ),
    };
  }

  /// Un combo de catalogo. Los opcionales agregan "Sin asignar", que en la base
  /// es el cero y no un nulo: `idGrpFamiliaSap = 0` significa justamente eso.
  Widget _combo<T>({
    required String etiqueta,
    required AsyncValue<List<T>> catalogo,
    required BigInt? valor,
    required BigInt Function(T) id,
    required String Function(T) rotulo,
    required ValueChanged<BigInt?> onElegir,
    bool opcional = false,
  }) {
    final opciones = catalogo.maybeWhen(
      data:
          (datos) => [
            if (opcional)
              DropdownMenuEntry<BigInt?>(
                value: BigInt.zero,
                label: 'Sin asignar',
              ),
            for (final d in datos)
              DropdownMenuEntry<BigInt?>(value: id(d), label: rotulo(d)),
          ],
      orElse: () => const <DropdownMenuEntry<BigInt?>>[],
    );

    final falta = _intentoGuardar && !opcional && !_elegido(valor);

    return ComboBuscable<BigInt?>(
      etiqueta: opcional ? etiqueta : '$etiqueta *',
      valor: valor,
      opciones: opciones,
      onElegir: onElegir,
      ayuda: switch (catalogo) {
        AsyncError() => 'No se pudo cargar el catálogo',
        AsyncLoading() => 'Cargando…',
        _ => falta ? 'Elija un valor' : null,
      },
    );
  }

  /// El cero es "sin asignar", que para un campo obligatorio no alcanza.
  bool _elegido(BigInt? valor) => valor != null && valor > BigInt.zero;

  Widget _soloLectura(bool compacto, FamiliaVista f) => _campos(compacto, [
    _Lectura(
      rotulo: 'Costo por tonelada',
      valor: f.sinCosto ? 'Sin costo cargado' : f.costoTmLegible,
      ayuda: 'Lo mueven las propuestas de precio, no esta ficha',
    ),
    _Lectura(
      rotulo: 'Última propuesta aprobada',
      valor:
          f.tienePropuestaAprobada
              ? f.idPropuestaAprobada.toString()
              : 'Todavía ninguna',
      ayuda: 'Se actualiza al aprobar una propuesta',
    ),
  ]);

  // ── Guardar y cerrar ──────────────────────────────────────────────────────

  bool get _hayCambios {
    final f = widget.editar;
    if (f == null) {
      return _codigo.text.trim().isNotEmpty ||
          _porcentajes.hayCambios ||
          _grupo != null ||
          _proveedor != null ||
          _presentacion != null ||
          _tipo != null ||
          _rango != null ||
          _color != null;
    }
    return _porcentajes.hayCambios ||
        _activa != f.esActiva ||
        _grupo != null ||
        _proveedor != null ||
        _presentacion != null ||
        _tipo != null ||
        _rango != null ||
        _color != null;
  }

  Future<void> _cerrar() async {
    if (_hayCambios) {
      final salir = await confirmar(
        context,
        titulo: 'Descartar los cambios',
        detalle:
            'Hay datos cargados en la ficha que todavía no se guardaron. '
            '¿Cierra igual?',
        textoConfirmar: 'Descartar',
        textoCancelar: 'Seguir editando',
        destructiva: true,
      );
      if (!salir || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _guardar({
    required BigInt? grupo,
    required BigInt? proveedor,
    required BigInt? presentacion,
    required BigInt? tipo,
    required BigInt? rango,
    required BigInt? color,
  }) async {
    setState(() => _intentoGuardar = true);

    final formularioOk = _formulario.currentState?.validate() ?? false;
    final combosOk =
        _elegido(presentacion) &&
        _elegido(tipo) &&
        _elegido(rango) &&
        _elegido(color);

    if (!formularioOk || !combosOk) {
      mostrarAviso(
        context,
        'Faltan datos obligatorios en la ficha',
        tono: TonoAviso.error,
      );
      return;
    }

    if (_porcentajes.cargada && _porcentajes.hayInvalidos) {
      mostrarAviso(
        context,
        'Revise los porcentajes: hay uno que no es un número',
        tono: TonoAviso.error,
      );
      return;
    }

    // Una ultima verificacion del codigo antes de grabar: entre lo que se tipeo
    // y este momento pudo crearla otra persona.
    if (_esAlta && _codigoTomado == int.tryParse(_codigo.text.trim())) {
      mostrarAviso(
        context,
        'Ese código ya pertenece a otra familia',
        tono: TonoAviso.error,
      );
      return;
    }

    final f = widget.editar;
    final familia = ProductoFamiliaEntity(
      codigoFamilia:
          _esAlta ? int.parse(_codigo.text.trim()) : f!.codigoFamilia,
      idGrpFamiliaSap: grupo ?? BigInt.zero,
      idProveedorSap: proveedor ?? BigInt.zero,
      idPresentacion: presentacion!,
      idTipo: tipo!,
      idRangoGram: rango!,
      // La ficha no los carga: la edicion devuelve los que ya tenia.
      formato: f?.formato ?? '',
      gramaje: f?.gramaje ?? '',
      idColor: color!,
      estado: _activa ? 1 : 0,
      // Los dos son de solo lectura desde esta ficha: el alta los deja en cero
      // y la edicion repite lo que ya tenia la fila. Los mueve el circuito de
      // propuestas.
      costoTM: f?.costoTM ?? 0,
      idPropuestaAprobada: f?.idPropuestaAprobada ?? BigInt.zero,
      audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
      audFecha: null,
    );

    final porcentajes =
        _porcentajes.cargada
            ? _porcentajes.aGuardar(
              alta: _esAlta,
              codigoFamilia: familia.codigoFamilia,
            )
            : null;

    setState(() => _guardando = true);
    try {
      await widget.onGuardar!(
        familia,
        porcentajes == null || porcentajes.isEmpty ? null : porcentajes,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas chicas
// ═══════════════════════════════════════════════════════════════════════════

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.m),
    child: Text(titulo, style: context.tituloSeccion()),
  );
}

/// Un dato que la ficha muestra pero no escribe. Se dibuja como un campo
/// deshabilitado y no como texto suelto para que se lea como parte del
/// formulario, con su rotulo arriba igual que los demas.
class _Lectura extends StatelessWidget {
  const _Lectura({
    required this.rotulo,
    required this.valor,
    required this.ayuda,
  });

  final String rotulo;
  final String valor;
  final String ayuda;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      isDense: true,
      border: const OutlineInputBorder(),
      labelText: rotulo,
      helperText: ayuda,
      helperMaxLines: 2,
      enabled: false,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Text(valor, style: context.numero(fuerte: true)),
  );
}
