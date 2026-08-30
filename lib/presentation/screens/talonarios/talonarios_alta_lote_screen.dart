import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/constants/talonarios_botones.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/data/models/talonario_lote_model.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Alta masiva de talonarios.
///
/// Dos pasos, y esa es la diferencia grande con el wizard viejo:
///
/// 1. **Previsualizar** arma el lote en el backend y marca los `nroTalonario`
///    que ya existen. **No escribe nada.** El legacy avisaba de los duplicados
///    a mitad del guardado y los salteaba en silencio.
/// 2. **Guardar** graba todo o nada. Si falla uno, no queda ninguno.
///
/// Nunca se dio de alta un talonario de a uno: los 1035 de producción se
/// crearon en 34 lotes, el mayor de 62.
class TalonariosAltaLoteScreen extends ConsumerStatefulWidget {
  const TalonariosAltaLoteScreen({super.key});

  @override
  ConsumerState<TalonariosAltaLoteScreen> createState() =>
      _TalonariosAltaLoteScreenState();
}

class _TalonariosAltaLoteScreenState
    extends ConsumerState<TalonariosAltaLoteScreen> {
  final _formKey = GlobalKey<FormState>();

  BigInt? _codTipoRecibo;
  int? _codEmpresa;
  final _cantidad = TextEditingController(text: '10');
  final _bloqueInicial = TextEditingController(text: '1');
  final _correlativo = TextEditingController(text: '1');
  final _costo = TextEditingController(text: '0');
  int _tipoCosto = TalonarioLoteModel.costoIndividual;
  bool _porGestion = false;
  final _anio = TextEditingController(text: '${DateTime.now().year}');
  final _observacion = TextEditingController();

  /// Último folio usado por el tipo elegido. Sale del backend.
  int _ultimoFolioTipo = 0;

  TalonarioLoteModel? _preview;

  /// Los duplicados como Set: `contains` sobre la lista era O(n) por fila, o
  /// sea O(n²) por build en un lote de 1000.
  Set<String> _duplicados = const {};

  bool _ocupado = false;

  /// Si la hoja de previsualización está abierta. Sirve para cerrarla en el
  /// orden correcto al guardar, sin adivinar cuántas rutas hay que sacar.
  bool _hojaAbierta = false;

  @override
  void dispose() {
    _cantidad.dispose();
    _bloqueInicial.dispose();
    _correlativo.dispose();
    _costo.dispose();
    _anio.dispose();
    _observacion.dispose();
    super.dispose();
  }

  void _invalidarPreview() {
    if (_ocupado) return;
    if (_preview != null) {
      setState(() {
        _preview = null;
        _duplicados = const {};
      });
    }
  }

  TalonarioLoteModel _armarDto() => TalonarioLoteModel(
    codTipoRecibo: _codTipoRecibo ?? BigInt.zero,
    codEmpresa: BigInt.from(_codEmpresa ?? 0),
    cantidad: int.tryParse(_cantidad.text) ?? 0,
    bloqueInicial: int.tryParse(_bloqueInicial.text) ?? 1,
    correlativoInicial: int.tryParse(_correlativo.text) ?? 1,
    tipoCosto: _tipoCosto,
    costo: double.tryParse(_costo.text.replaceAll(',', '.')) ?? 0,
    porGestion: _porGestion,
    anio: int.tryParse(_anio.text) ?? 0,
    observacion: _observacion.text,
    audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return GuardiaDeSalida(
      hayCambios: (_preview != null || _codTipoRecibo != null) && !_ocupado,
      mensaje: 'Se pierde el lote que armaste y todo lo que cargaste.',
      child: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          final anchoSuficiente = aire == Aire.amplio;

          return Scaffold(
            appBar: AppBar(title: const Text('Nuevo lote de talonarios')),
            // En angosto y medio el botón principal vive abajo, al alcance.
            bottomNavigationBar: anchoSuficiente ? null : _barraInferior(),
            body:
                anchoSuficiente
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 420, child: _formulario(aire)),
                        const VerticalDivider(width: 1),
                        Expanded(child: _panelPreview()),
                      ],
                    )
                    : _formulario(aire),
          );
        },
      ),
    );
  }

  // ── Formulario ────────────────────────────────────────────────────────────

  Widget _formulario(Aire aire) {
    final tipos = ref.watch(tiposReciboProvider);
    final empresas = ref.watch(empresasProvider);
    final puedeCrear = tienePermisoDeBoton(ref, TalonariosBotones.nuevo);

    return AbsorbPointer(
      // Congela el formulario mientras el POST viaja. Sin esto se podía editar
      // un campo, ver desaparecer el resumen, y que el request siguiera
      // escribiendo el lote viejo.
      absorbing: _ocupado,
      child: AnimatedOpacity(
        opacity: _ocupado ? 0.6 : 1,
        duration: const Duration(milliseconds: 150),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Esp.l),
          child: Form(
            key: _formKey,
            // Sin esto los errores en rojo quedan pegados aunque la persona ya
            // haya elegido el valor: solo se limpian en el próximo validate().
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // El aviso de permiso va arriba, no después de armar el lote:
                // antes se descubría tras completar ocho campos.
                if (!puedeCrear) ...[
                  const NotaDelDato(
                    texto:
                        'No tenés permiso para dar de alta talonarios. Podés '
                        'previsualizar, pero no guardar.',
                    tono: TonoNota.aviso,
                  ),
                  const SizedBox(height: Esp.m),
                ],

                _combo(
                  async: tipos,
                  etiqueta: 'Tipo de recibo',
                  provider: tiposReciboProvider,
                  construir:
                      (lista) => ComboBuscable<BigInt>(
                        etiqueta: 'Tipo de recibo *',
                        valor: _codTipoRecibo,
                        // El detalle lo escribió el negocio y dice para qué
                        // empresa es cada sigla ("Se usaran para IPX").
                        ayuda:
                            lista
                                .where((t) => t.codTipoRecibo == _codTipoRecibo)
                                .map((t) => t.detalle)
                                .firstOrNull,
                        opciones:
                            lista
                                .where((t) => t.activo)
                                .map(
                                  (t) => DropdownMenuEntry(
                                    value: t.codTipoRecibo,
                                    label: '${t.sigla} — ${t.nombre}',
                                  ),
                                )
                                .toList(),
                        onElegir: (v) {
                          final tipo =
                              lista
                                  .where((t) => t.codTipoRecibo == v)
                                  .firstOrNull;
                          setState(() {
                            _codTipoRecibo = v;
                            _preview = null;
                            _duplicados = const {};
                            _ultimoFolioTipo = tipo?.ultimoFolio ?? 0;
                            // Propone el primer bloque libre. El legacy dejaba
                            // el 1 y así se duplicaban números de recibo.
                            if (tipo != null) {
                              _bloqueInicial.text = '${tipo.bloqueSugerido}';
                            }
                          });
                        },
                      ),
                ),
                const SizedBox(height: Esp.m),

                _combo(
                  async: empresas,
                  etiqueta: 'Empresa',
                  provider: empresasProvider,
                  construir:
                      (lista) => ComboBuscable<int>(
                        etiqueta: 'Empresa *',
                        valor: _codEmpresa,
                        opciones:
                            lista
                                .map(
                                  (e) => DropdownMenuEntry(
                                    value: e.codEmpresa,
                                    label: e.nombre,
                                  ),
                                )
                                .toList(),
                        onElegir:
                            (v) => setState(() {
                              _codEmpresa = v;
                              _preview = null;
                              _duplicados = const {};
                            }),
                      ),
                ),
                _avisoCombinacion(),
                const SizedBox(height: Esp.l),

                // En angosto los dos numéricos se apilan: a 360 px quedan
                // 158 px cada uno y «Correlativo inicial *» se corta justo en
                // el campo que gobierna la numeración de los recibos físicos.
                Flex(
                  direction: aire.esChico ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _envolver(
                      aire,
                      _numero(
                        _cantidad,
                        'Cantidad *',
                        ayuda: 'Cuántos talonarios generar',
                        minimo: 1,
                        maximo: 1000,
                      ),
                    ),
                    SizedBox(
                      width: aire.esChico ? 0 : Esp.m,
                      height: aire.esChico ? Esp.m : 0,
                    ),
                    _envolver(
                      aire,
                      _numero(
                        _correlativo,
                        'Correlativo inicial *',
                        ayuda: 'Se completa con ceros a 3 dígitos (007)',
                        minimo: 1,
                        maximo: 999999,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),

                _numero(
                  _bloqueInicial,
                  'Bloque de folios *',
                  ayuda:
                      'Cada talonario cubre ${TalonarioLoteModel.recibosPorTalonario} '
                      'recibos. El bloque 1 arranca en el folio 1, el 2 en el 51.',
                  minimo: 1,
                  maximo: 1000000,
                ),
                _avisoFolios(),
                const SizedBox(height: Esp.l),

                Text('Costo', style: context.tituloSeccion()),
                _opcionCosto(
                  TalonarioLoteModel.costoIndividual,
                  'Por talonario',
                  'El monto es el de cada uno',
                ),
                _opcionCosto(
                  TalonarioLoteModel.costoTotal,
                  'Total del lote',
                  'Se divide entre la cantidad',
                ),
                _numero(
                  _costo,
                  'Costo Bs',
                  decimal: true,
                  minimo: 0,
                  maximo: 9999999,
                ),
                const SizedBox(height: Esp.m),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _porGestion,
                  title: const Text('Prefijo por gestión'),
                  subtitle: const Text('Antepone el año a la sigla'),
                  onChanged:
                      (v) => setState(() {
                        _porGestion = v;
                        _preview = null;
                        _duplicados = const {};
                      }),
                ),
                // AnimatedSize: el campo aparece creciendo en vez de saltar.
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child:
                      _porGestion
                          ? _numero(_anio, 'Año', minimo: 2000, maximo: 2100)
                          : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: Esp.m),

                TextField(
                  controller: _observacion,
                  maxLength: 250,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _invalidarPreview(),
                ),

                // En ancho el botón vive acá; en el resto está en la barra fija.
                if (aire == Aire.amplio) ...[
                  const SizedBox(height: Esp.s),
                  BotonAccion(
                    etiqueta: 'Previsualizar',
                    etiquetaOcupado: 'Previsualizando…',
                    icono: Icons.visibility_outlined,
                    tonal: true,
                    ocupado: _ocupado,
                    onPressed: _simular,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _envolver(Aire aire, Widget hijo) =>
      aire.esChico ? hijo : Expanded(child: hijo);

  /// Un combo con sus tres estados resueltos igual en todos lados.
  Widget _combo<T>({
    required AsyncValue<List<T>> async,
    required String etiqueta,
    required ProviderOrFamily provider,
    required Widget Function(List<T>) construir,
  }) => async.when(
    loading: () => _CampoCargando(etiqueta: etiqueta),
    error:
        (e, _) => MensajeError(
          error: e,
          compacto: true,
          onReintentar: () => ref.invalidate(provider),
        ),
    data: construir,
  );

  Widget _opcionCosto(int valor, String texto, String ayuda) => RadioListTile<int>(
    contentPadding: EdgeInsets.zero,
    value: valor,
    groupValue: _tipoCosto,
    title: Text(texto),
    subtitle: Text(ayuda, style: context.apagado()),
    onChanged:
        (v) => setState(() {
          _tipoCosto = v ?? TalonarioLoteModel.costoIndividual;
          _preview = null;
          _duplicados = const {};
        }),
  );

  /// Los topes espejan los del backend (MAX_CANTIDAD_LOTE, MAX_BLOQUE,
  /// MAX_CORRELATIVO). Sin ellos un número de 11 dígitos no entra en el `int`
  /// del DTO y el pedido muere antes de llegar al controller.
  Widget _numero(
    TextEditingController c,
    String label, {
    String? ayuda,
    bool decimal = false,
    num minimo = 0,
    required num maximo,
  }) => TextFormField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
      ),
      LengthLimitingTextInputFormatter(maximo.toStringAsFixed(0).length + 2),
    ],
    style: const TextStyle(fontFeatures: cifrasTabulares),
    decoration: InputDecoration(
      labelText: label,
      helperText: ayuda,
      helperMaxLines: 3,
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) => _invalidarPreview(),
    validator: (v) {
      final n =
          decimal
              ? double.tryParse((v ?? '').replaceAll(',', '.'))
              : int.tryParse(v ?? '');
      if (n == null) return 'Número inválido';
      if (n < minimo) return 'Mínimo $minimo';
      if (n > maximo) return 'Máximo ${maximo.toStringAsFixed(0)}';
      return null;
    },
  );

  // ── Avisos ────────────────────────────────────────────────────────────────

  /// Contrasta la combinación tipo + empresa contra el historial.
  ///
  /// **Avisa, no bloquea.** No hay restricción que ate un tipo a una empresa, y
  /// el historial la contradiría: ER1 se usó en Esppapel (119) y en Impexpap
  /// (41), y PR2 en Impexpap (150) y en Papirus (50).
  Widget _avisoCombinacion() {
    if (_codTipoRecibo == null || _codEmpresa == null) {
      return const SizedBox.shrink();
    }

    final uso = ref.watch(
      usoTipoEmpresaProvider((
        codTipoRecibo: _codTipoRecibo!,
        codEmpresa: BigInt.from(_codEmpresa!),
      )),
    );

    return uso.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.only(top: Esp.s),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      // Un fallo del chequeo no traba el alta: es solo un aviso.
      error: (_, __) => const SizedBox.shrink(),
      data: (cantidad) {
        if (cantidad < 0) return const SizedBox.shrink();
        return cantidad == 0
            ? const NotaDelDato(
              tono: TonoNota.aviso,
              texto:
                  'Esta sigla nunca se usó en esta empresa. Revisá que sea la '
                  'correcta antes de continuar.',
            )
            : NotaDelDato(
              tono: TonoNota.exito,
              texto: 'Ya hay $cantidad talonarios con esta combinación.',
            );
      },
    );
  }

  /// Avisa si los folios del lote pisan a los que ya existen para ese tipo.
  ///
  /// El backend lo rechaza con error 28; esto es para que el caso ni se
  /// presente. Duplicar folios significa dos libretas físicas con los mismos
  /// números de recibo.
  Widget _avisoFolios() {
    if (_codTipoRecibo == null || _ultimoFolioTipo <= 0) {
      return const SizedBox.shrink();
    }
    final bloque = int.tryParse(_bloqueInicial.text) ?? 0;
    if (bloque < 1) return const SizedBox.shrink();

    final primerFolio =
        ((bloque - 1) * TalonarioLoteModel.recibosPorTalonario) + 1;
    if (primerFolio > _ultimoFolioTipo) return const SizedBox.shrink();

    final sugerido =
        (_ultimoFolioTipo ~/ TalonarioLoteModel.recibosPorTalonario) + 1;
    return NotaDelDato(
      tono: TonoNota.error,
      texto:
          'Estos folios ya se usaron. Este tipo llega hasta el folio '
          '$_ultimoFolioTipo, y el bloque $bloque arranca en el $primerFolio. '
          'Usá el bloque $sugerido o uno mayor.',
      accion: TextButton(
        onPressed:
            () => setState(() {
              _bloqueInicial.text = '$sugerido';
              _preview = null;
              _duplicados = const {};
            }),
        child: const Text('Corregir'),
      ),
    );
  }

  // ── Previsualización ──────────────────────────────────────────────────────

  Widget _panelPreview() {
    final p = _preview;
    if (p == null) {
      return const MensajeVacio(
        icono: Icons.visibility_outlined,
        titulo: 'Nada previsualizado todavía',
        detalle:
            'Completá el formulario y tocá Previsualizar. No se guarda nada '
            'hasta que confirmes.',
      );
    }

    return Column(
      children: [
        _resumen(p),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Esp.s),
            itemCount: p.talonarios.length,
            itemBuilder: (_, i) => _filaPreview(p.talonarios[i]),
          ),
        ),
      ],
    );
  }

  Widget _filaPreview(TalonarioEntity t) {
    final duplicado = _duplicados.contains(t.nroTalonario);
    final cs = context.cs;
    return ListTile(
      dense: true,
      leading: Icon(
        duplicado ? Icons.error_outline : Icons.check_circle_outline,
        color: duplicado ? cs.error : cs.primary,
      ),
      title: Text(
        t.nroTalonario,
        style: TextStyle(
          fontWeight: Peso.dato,
          fontFeatures: cifrasTabulares,
          color: duplicado ? cs.error : null,
        ),
      ),
      subtitle: Text('folios ${t.numeracionInicial}–${t.numeracionFinal}'),
      trailing: SizedBox(
        width: 96,
        child: Text(
          'Bs ${t.costoBs.toStringAsFixed(2)}',
          textAlign: TextAlign.end,
          style: context.numero(fuerte: true),
        ),
      ),
    );
  }

  Widget _resumen(TalonarioLoteModel p) {
    final hayDuplicados = _duplicados.isNotEmpty;
    // Se corta: sesenta duplicados son ~900 caracteres y no entran en el panel.
    final muestra = p.duplicados.take(6).join(', ');
    final resto = p.duplicados.length - 6;

    return Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${p.talonarios.length}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              const SizedBox(width: Esp.s),
              Text('talonarios', style: context.apagado()),
            ],
          ),
          if (hayDuplicados)
            NotaDelDato(
              tono: TonoNota.error,
              texto:
                  '${p.duplicados.length} ya existen: $muestra'
                  '${resto > 0 ? ' y $resto más' : ''}. '
                  'Cambiá el correlativo inicial: el alta es todo o nada, con '
                  'un duplicado no se guarda ninguno.',
            ),
          const SizedBox(height: Esp.m),
          PermissionWidget(
            buttonName: TalonariosBotones.nuevo,
            placeholder: Text(
              'No tenés permiso para dar de alta talonarios.',
              style: context.apagado(),
            ),
            child: BotonAccion(
              etiqueta: 'Guardar los ${p.talonarios.length}',
              etiquetaOcupado: 'Guardando…',
              icono: Icons.save_outlined,
              ocupado: _ocupado,
              onPressed: hayDuplicados ? null : _guardar,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra inferior (angosto y medio) ──────────────────────────────────────

  Widget _barraInferior() {
    final p = _preview;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: BotonAccion(
          etiqueta:
              p == null ? 'Previsualizar' : 'Ver los ${p.talonarios.length}',
          etiquetaOcupado: 'Previsualizando…',
          icono: Icons.visibility_outlined,
          tonal: p == null,
          ocupado: _ocupado,
          onPressed: p == null ? _simular : _abrirHojaPreview,
        ),
      ),
    );
  }

  /// En pantalla chica la previsualización es una hoja casi completa.
  ///
  /// Resuelve tres cosas de una: previsualizar **pasa algo visible**, la lista
  /// se lee en toda la pantalla, y el botón de guardar queda donde la persona
  /// termina de mirar el resultado.
  void _abrirHojaPreview() {
    _hojaAbierta = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            builder:
                (ctx, scroll) => StatefulBuilder(
                  builder: (ctx, _) {
                    final p = _preview;
                    if (p == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _resumen(p),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            controller: scroll,
                            itemCount: p.talonarios.length,
                            itemBuilder: (_, i) => _filaPreview(p.talonarios[i]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
    ).whenComplete(() => _hojaAbierta = false);
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _simular() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _ocupado = true);
    try {
      final r = await ref
          .read(talonariosRepositoryProvider)
          .simularLote(_armarDto());
      if (!mounted) return;
      setState(() {
        _preview = r;
        _duplicados = r.duplicados.toSet();
      });
      if (r.tieneDuplicados) {
        mostrarAviso(
          context,
          '${r.duplicados.length} de ${r.talonarios.length} ya existen',
          tono: TonoAviso.aviso,
        );
      }
      // En angosto la hoja se abre sola: si no, tocar Previsualizar parece no
      // hacer nada porque el resultado vive fuera de la pantalla.
      if (Aire.de(MediaQuery.of(context).size.width) != Aire.amplio) {
        _abrirHojaPreview();
      }
    } catch (e) {
      if (!mounted) return;
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _guardar() async {
    final p = _preview;
    if (p == null) return;

    final sigue = await confirmar(
      context,
      titulo: 'Registrar ${p.talonarios.length} talonarios',
      detalle:
          'Del ${p.talonarios.first.nroTalonario} al '
          '${p.talonarios.last.nroTalonario}, folios '
          '${p.talonarios.first.numeracionInicial} a '
          '${p.talonarios.last.numeracionFinal}.\n\n'
          'Se graba todo o nada: si falla uno, no queda ninguno.',
      textoConfirmar: 'Registrar',
    );
    if (!sigue || !mounted) return;

    setState(() => _ocupado = true);
    try {
      final ids = await ref.read(talonariosRepositoryProvider).aplicarLote(p);
      if (!mounted) return;
      refrescarTalonarios(ref);
      mostrarAviso(context, 'Se registraron ${ids.length} talonarios');
      // Cierra primero la hoja de previsualización si quedó abierta, y recién
      // después la pantalla. Con un `popUntil` genérico no hay forma de saber
      // dónde parar, y se lleva puestas rutas de más.
      if (_hojaAbierta) {
        Navigator.of(context).pop();
        _hojaAbierta = false;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // El backend manda "No se guardó ningún registro. Falló …".
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
}

/// Un campo deshabilitado del alto de un combo, para mientras carga.
class _CampoCargando extends StatelessWidget {
  const _CampoCargando({required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) => TextField(
    enabled: false,
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
      suffixIcon: const Padding(
        padding: EdgeInsets.all(Esp.m),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}
