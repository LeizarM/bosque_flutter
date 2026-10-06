/// El formulario de cheque: alta y edicion, con los tres modos del contrato
/// (`POST /cheque/registrar`) que son los tres modales del legacy.
///
/// | Modo | Modal del legacy | Que deja editar |
/// |---|---|---|
/// | `estandar`, alta | `chequeModal` | todo salvo empresa, sucursal y fecha de cobro |
/// | `estandar`, edicion | `chequeModal` | cliente, banco, nro de cheque, talonario, recibo y observacion |
/// | `talonario` | `chequeModalTal` | solo talonario y recibo |
/// | `admin` | `chequeModalMad` | todo salvo empresa y sucursal |
///
/// **El modo lo elige la pantalla, no el usuario**: «Registrar» abre `admin` si
/// el usuario tiene btnNuevo2CH (el administrador siempre) y `estandar` si no
/// (`PermisosCheque.modoDeRegistro`); el lapiz de la fila, segun
/// `modoDeEdicionCheque`.
///
/// **Lo que el modo no deja editar se muestra de solo lectura, no se esconde**:
/// quien corrige un talonario necesita ver a que cheque pertenece. El servidor
/// ignora igual lo que el modo no acepta, de modo que los campos bloqueados ni
/// siquiera viajan.
///
/// Las reglas de aqui (recibo y talonario, +-28 dias, formatos) son para ayudar:
/// el servidor las repite todas y su mensaje, con todas sus lineas, se muestra
/// tal cual junto al formulario.
///
/// **La empresa no sale del login.** En un alta es la activa de la pantalla (el
/// combo «Empresa» de los filtros) y de ella salen la empresa del cheque y la
/// lista de clientes; en una edicion es la del propio cheque, que puede no ser la
/// activa.
///
/// **El par talonario / recibo se comprueba mientras se escribe** (600 ms despues
/// de la ultima tecla, contra `/cheque/talonario/validar` y la empresa de arriba):
/// una linea de estado debajo de los dos campos avisa si no corresponde a un
/// talonario de la empresa. Es un aviso temprano, nunca bloquea el guardado: el
/// servidor valida igual al guardar. Una edicion abre sin consultar nada hasta que
/// el usuario toca uno de los dos campos.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart'
    show obtenerBancos;
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/catalogos_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/aviso_talonario_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/combo_cliente_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

// ═══════════════════════════════════════════════════════════════════════════
// QUE CAMPOS DEJA EDITAR CADA MODO
// ═══════════════════════════════════════════════════════════════════════════

/// Si [campo] se puede editar en [modo]. Es la tabla de arriba, en codigo, y la
/// unica que decide: el formulario no pregunta el modo en ningun otro lado.
///
/// Los campos: `empresa`, `sucursal`, `entregadoPor`, `tipo`, `cliente`,
/// `banco`, `nroCheque`, `monto`, `moneda`, `aOrdenDe`, `fechaCheque`,
/// `fechaCobrar`, `talonario`, `recibo` y `observacion`.
bool campoEditableCheque(
  String campo,
  ModoRegistroCheque modo, {
  required bool esAlta,
}) {
  final admin = modo == ModoRegistroCheque.admin;
  final talonario = modo == ModoRegistroCheque.talonario;
  return switch (campo) {
    // El cheque pertenece a una empresa y a una sucursal: no se mueve.
    'empresa' || 'sucursal' => false,
    // Sigue a la fecha del cheque; solo el administrador la fija a mano. En el
    // resto cambia unicamente con la accion «Fecha de cobro».
    'fechaCobrar' => admin,
    'talonario' || 'recibo' => true,
    'cliente' || 'banco' || 'nroCheque' || 'observacion' => !talonario,
    // Una vez guardados, solo el administrador los toca.
    'entregadoPor' ||
    'tipo' ||
    'monto' ||
    'moneda' ||
    'aOrdenDe' ||
    'fechaCheque' => esAlta || admin,
    _ => false,
  };
}

/// La clave con que se marca cada campo: `editable-<campo>` o
/// `bloqueado-<campo>`. Las pruebas la usan para comprobar la tabla de arriba.
ValueKey<String> claveCampoCheque(String campo, {required bool bloqueado}) =>
    ValueKey('${bloqueado ? 'bloqueado' : 'editable'}-$campo');

/// La clave del aviso de «cobro fuera de rango» que sale arriba del formulario.
const claveAvisoCobroFueraDeRango = ValueKey<String>(
  'aviso-cobro-fuera-de-rango',
);

// ═══════════════════════════════════════════════════════════════════════════
// ABRIR
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el formulario. Con [existente] null es un alta; con un cheque, su
/// edicion. Devuelve el codCheque guardado o null si se cancelo.
///
/// [codSucursal] es la sucursal de la grilla: el cheque nuevo queda en ella.
///
/// [avisoCobroFueraDeRango]: un administrador pidio editar un cheque cerrado cuyo
/// cobro quedo fuera de +-28 dias y se abrio en modo `talonario`
/// (`modoDeEdicionCheque`); el formulario lo explica arriba. Solo informa.
Future<BigInt?> abrirFormularioCheque(
  BuildContext context, {
  required ModoRegistroCheque modo,
  required int codSucursal,
  ChequeFilaEntity? existente,
  bool avisoCobroFueraDeRango = false,
}) {
  // El error de una escritura anterior no debe aparecer en un formulario nuevo.
  ProviderScope.containerOf(
    context,
  ).read(operacionesChequesProvider.notifier).limpiarError();
  return abrirPanelCheque<BigInt>(
    context,
    contenido:
        (_) => _FormularioCheque(
          modo: modo,
          codSucursal: codSucursal,
          existente: existente,
          avisoCobroFueraDeRango: avisoCobroFueraDeRango,
        ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EL FORMULARIO
// ═══════════════════════════════════════════════════════════════════════════

class _FormularioCheque extends ConsumerStatefulWidget {
  const _FormularioCheque({
    required this.modo,
    required this.codSucursal,
    required this.existente,
    this.avisoCobroFueraDeRango = false,
  });

  final ModoRegistroCheque modo;
  final int codSucursal;
  final ChequeFilaEntity? existente;
  final bool avisoCobroFueraDeRango;

  @override
  ConsumerState<_FormularioCheque> createState() => _FormularioChequeState();
}

class _FormularioChequeState extends ConsumerState<_FormularioCheque> {
  final _form = GlobalKey<FormState>();
  final _nro = TextEditingController();
  final _monto = TextEditingController();
  final _aOrden = TextEditingController();
  final _talonario = TextEditingController(text: '0');
  final _recibo = TextEditingController(text: '0');
  final _observacion = TextEditingController();

  int _codEmpleado = 0;
  String? _codCliente;
  String _textoCliente = '';
  int? _codBanco;
  DateTime? _fechaCheque;
  DateTime? _fechaCobrar;

  /// Lo que **eligio el usuario** en tipo y moneda. Sin eleccion, el valor sale
  /// de [_tipoEfectivo] / [_monedaEfectiva].
  String? _tipo;
  String? _moneda;

  bool _tocado = false;

  /// Ya se intento guardar: desde ahi los errores se actualizan al escribir.
  bool _intentado = false;

  /// La linea de estado del par talonario / recibo.
  late final ComprobadorTalonarioCheque _comprobador;

  /// El usuario escribio en talonario o recibo. Una edicion abre con los dos ya
  /// cargados y no se consulta hasta que esto es `true`.
  bool _talonarioTocado = false;

  bool get _esAlta => widget.existente == null;
  ModoRegistroCheque get _modo => widget.modo;

  bool _puede(String campo) =>
      campoEditableCheque(campo, _modo, esAlta: _esAlta);

  @override
  void initState() {
    super.initState();
    _comprobador = ComprobadorTalonarioCheque(
      consultar:
          (codEmpresa, talonario, recibo) => ref
              .read(chequesRepositoryProvider)
              .validarTalonario(
                codEmpresa: codEmpresa,
                nroTalonario: talonario,
                reciboManual: recibo,
              ),
    )..addListener(_alCambiarAvisoTalonario);
    final e = widget.existente;
    if (e == null) return;
    final c = e.cheque;
    _nro.text = c.nrocheque;
    _codCliente = c.codCliente;
    _textoCliente = e.datoCliente;
    _codBanco = c.codBanco;
    _codEmpleado = c.codEmpleado ?? 0;
    _aOrden.text = c.aOrdenDe ?? '';
    _monto.text = c.monto == null ? '' : c.monto!.toStringAsFixed(2);
    _fechaCheque = c.fechaCheque;
    _fechaCobrar = c.fechaCobrar;
    _talonario.text = (c.nroTalonario ?? '').trim().isEmpty
        ? '0'
        : c.nroTalonario!.trim();
    _recibo.text = (c.reciboManual ?? '').trim().isEmpty
        ? '0'
        : c.reciboManual!.trim();
    _observacion.text = e.observacion ?? '';
  }

  @override
  void dispose() {
    // Cancela la espera pendiente y descarta la respuesta de una consulta en
    // vuelo: nada llama a `setState` despues de esto.
    _comprobador.dispose();
    for (final c in [_nro, _monto, _aOrden, _talonario, _recibo, _observacion]) {
      c.dispose();
    }
    super.dispose();
  }

  void _marcar() {
    if (!_tocado) setState(() => _tocado = true);
  }

  // ── Comprobacion del talonario ───────────────────────────────────────────

  void _alCambiarAvisoTalonario() {
    if (mounted) setState(() {});
  }

  /// El usuario cambio el talonario o el recibo.
  void _alEditarTalonarioORecibo() {
    _talonarioTocado = true;
    _programarComprobacion();
  }

  /// Vuelve a decidir si hay que consultar. La empresa es la del formulario (la
  /// activa en un alta, la del cheque en una edicion), nunca la del login.
  void _programarComprobacion() {
    _comprobador.programar(
      codEmpresa: _codEmpresa(ref.read(empresaChequeActivaProvider)),
      talonario: _talonario.text,
      recibo: _recibo.text,
    );
  }

  // ── Valores que dependen de los catalogos ────────────────────────────────

  static bool _enCatalogo(List<OpcionChequeEntity> l, String? cod) =>
      cod != null && l.any((o) => o.codigo.trim() == cod.trim());

  /// El tipo en pantalla: lo elegido; si no, en un alta el primero del catalogo
  /// (como el desplegable del legacy); en una edicion, el guardado **solo si es
  /// confiable**. `descTipo` en null significa que el JOIN no lo encontro: el
  /// `tipo` guardado esta corrupto y no se reenvia, el usuario tiene que elegir.
  String? _tipoEfectivo(List<OpcionChequeEntity> tipos) {
    if (_tipo != null) return _tipo;
    if (_esAlta) return tipos.isEmpty ? null : tipos.first.codigo;
    final e = widget.existente!;
    final guardado = e.cheque.tipo?.trim();
    if (e.descTipo == null || !_enCatalogo(tipos, guardado)) return null;
    return guardado;
  }

  String? _monedaEfectiva(List<OpcionChequeEntity> monedas) {
    if (_moneda != null) return _moneda;
    if (_esAlta) return monedas.isEmpty ? null : monedas.first.codigo;
    final guardada = widget.existente!.cheque.moneda?.trim();
    return _enCatalogo(monedas, guardada) ? guardada : null;
  }

  // ── Guardar ──────────────────────────────────────────────────────────────

  Future<void> _guardar(CatalogosChequeEntity catalogos) async {
    // El boton ya esta apagado sin empresa; esto cubre cualquier otra via.
    if (_esAlta && ref.read(empresaChequeActivaProvider) == null) {
      avisar(context, 'Todavía no se cargó la empresa.', esError: true);
      return;
    }
    setState(() => _intentado = true);
    if (!(_form.currentState?.validate() ?? false)) {
      avisar(context, 'Revisa los campos marcados en rojo.', esError: true);
      return;
    }

    final registro = _armar(catalogos);
    final id = await ref
        .read(operacionesChequesProvider.notifier)
        .registrar(registro);
    // El error, si lo hubo, queda en el estado y se dibuja junto al formulario.
    if (id == null || !mounted) return;
    avisar(
      context,
      _esAlta
          ? 'Cheque ${registro.nrocheque} registrado.'
          : 'Cheque actualizado.',
    );
    Navigator.of(context).pop(id);
  }

  /// Solo lo que el modo acepta: el resto no viaja (y, en una edicion, el tipo
  /// corrupto de la base no vuelve a salir).
  ChequeRegistroEntity _armar(CatalogosChequeEntity catalogos) {
    final e = widget.existente;
    final recibo = _recibo.text.trim();
    final talonario = _talonario.text.trim();
    final obs = _observacionAEnviar();

    if (_modo == ModoRegistroCheque.talonario) {
      return ChequeRegistroEntity(
        codCheque: e!.codCheque,
        modo: _modo,
        nroTalonario: talonario,
        reciboManual: recibo,
      );
    }

    final base = ChequeRegistroEntity(
      codCheque: e?.codCheque ?? BigInt.zero,
      modo: _modo,
      nrocheque: _nro.text.trim(),
      codCliente: _codCliente,
      codBanco: _codBanco,
      nroTalonario: talonario,
      reciboManual: recibo,
      observacion: obs,
    );
    if (!_esAlta && _modo == ModoRegistroCheque.estandar) return base;

    final cobrar =
        _modo == ModoRegistroCheque.admin ? _fechaCobrar : _fechaCheque;
    return ChequeRegistroEntity(
      codCheque: base.codCheque,
      modo: _modo,
      nrocheque: base.nrocheque,
      codCliente: base.codCliente,
      codBanco: base.codBanco,
      nroTalonario: base.nroTalonario,
      reciboManual: base.reciboManual,
      observacion: base.observacion,
      aOrdenDe: _aOrden.text.trim(),
      fechaCheque: _fechaCheque,
      fechaCobrar: cobrar,
      monto: ReglasCheque.leerMonto(_monto.text),
      moneda: _monedaEfectiva(catalogos.monedas),
      tipo: _tipoEfectivo(catalogos.tiposCheque),
      codEmpleado: _codEmpleado,
      // Solo el alta manda donde queda el cheque (la empresa elegida en la
      // pantalla, no la del login); una edicion no los mueve.
      codSucursal: _esAlta ? widget.codSucursal : null,
      codEmpresa:
          _esAlta ? ref.read(empresaChequeActivaProvider)?.codEmpresa : null,
    );
  }

  /// En el alta, el texto o nada. En una edicion, null si no se toco (el
  /// servidor conserva la anterior) y `""` si se vacio (la borra).
  String? _observacionAEnviar() {
    final obs = _observacion.text.trim();
    if (_esAlta) return obs.isEmpty ? null : obs;
    final original = (widget.existente!.observacion ?? '').trim();
    return obs == original ? null : obs;
  }

  Future<void> _cerrar() async {
    if (_tocado) {
      final salir = await confirmar(
        context,
        titulo: '¿Descartar los cambios?',
        detalle: 'Lo que cargaste en este formulario no se guardó.',
        textoConfirmar: 'Descartar',
        destructiva: true,
      );
      if (!salir || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  // ── Dibujo ───────────────────────────────────────────────────────────────

  String get _titulo {
    if (_esAlta) {
      return _modo == ModoRegistroCheque.admin
          ? 'Registrar cheque (administrador)'
          : 'Registrar cheque';
    }
    return switch (_modo) {
      ModoRegistroCheque.talonario => 'Editar talonario y recibo',
      ModoRegistroCheque.admin => 'Editar cheque (administrador)',
      ModoRegistroCheque.estandar => 'Editar cheque',
    };
  }

  String get _subtitulo {
    final e = widget.existente;
    if (e == null) {
      return 'Queda registrado a tu nombre, en estado Pendiente.';
    }
    return 'Cheque ${e.cheque.nrocheque} · ${e.datoCliente}';
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesChequesProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesChequesProvider.select((s) => s.error),
    );
    final asyncCatalogos = ref.watch(catalogosChequeProvider);
    final catalogos = asyncCatalogos.valueOrNull ?? CatalogosChequeEntity.vacio;
    final e = widget.existente;

    // La empresa del cheque: la activa de la pantalla en un alta, la propia del
    // cheque en una edicion. Nunca la del login.
    final asyncEmpresas = ref.watch(empresasChequeProvider);
    final empresas = asyncEmpresas.valueOrNull ?? const <EmpresaChequeEntity>[];
    final activa = ref.watch(empresaChequeActivaProvider);
    final codEmpresa = _codEmpresa(activa);
    final sinEmpresa = _esAlta && activa == null;

    // La empresa activa llega tarde (la lista aun cargaba) o cambia: el par que
    // ya escribio el usuario se vuelve a comprobar contra la nueva.
    ref.listen<EmpresaChequeEntity?>(empresaChequeActivaProvider, (_, __) {
      if (_talonarioTocado) _programarComprobacion();
    });

    final codSucursalCheque = e?.cheque.codSucursal ?? widget.codSucursal;
    final sucursales =
        codEmpresa == null
            ? const <SucursalChequeEntity>[]
            : ref.watch(sucursalesChequeProvider(codEmpresa)).valueOrNull ??
                const <SucursalChequeEntity>[];
    final nombreSucursal =
        sucursales
            .where((s) => s.codSucursal == codSucursalCheque)
            .map((s) => s.nombre)
            .firstOrNull ??
        'Sucursal $codSucursalCheque';

    final tipoSel = _tipoEfectivo(catalogos.tiposCheque);
    final monedaSel = _monedaEfectiva(catalogos.monedas);

    // Cuando la base trae un tipo que no se puede resolver, se avisa por que el
    // combo aparece sin seleccion.
    final tipoInvalido =
        !_esAlta &&
        _puede('tipo') &&
        _tipo == null &&
        tipoSel == null &&
        catalogos.tiposCheque.isNotEmpty;

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        if (widget.avisoCobroFueraDeRango) ...[
          NotaDelDato(
            key: claveAvisoCobroFueraDeRango,
            texto:
                'La fecha de cobro de este cheque está fuera de '
                '±${ReglasCheque.diasToleranciaCobro} días de la fecha del '
                'cheque: solo se pueden corregir el talonario y el recibo.',
          ),
          const SizedBox(height: Esp.l),
        ],
        if (sinEmpresa) ...[
          _avisoSinEmpresa(asyncEmpresas),
          const SizedBox(height: Esp.l),
        ],
        if (asyncCatalogos.hasError) ...[
          NotaDelDato(
            tono: TonoNota.error,
            texto:
                'No se pudieron cargar los tipos y monedas: '
                '${mensajeDeErrorCheque(asyncCatalogos.error!)}',
            accion: TextButton(
              onPressed: () => ref.invalidate(catalogosChequeProvider),
              child: const Text('Reintentar'),
            ),
          ),
          const SizedBox(height: Esp.l),
        ],
        _Cuadricula([
          _celda(
            'empresa',
            etiqueta: 'Empresa',
            bloqueado: _nombreEmpresa(activa, empresas, codEmpresa),
            editable: () => const SizedBox.shrink(),
          ),
          _celda(
            'sucursal',
            etiqueta: 'Sucursal',
            bloqueado: nombreSucursal,
            editable: () => const SizedBox.shrink(),
          ),
          _celda(
            'entregadoPor',
            etiqueta: 'Entregado por',
            bloqueado: e == null ? null : textoEntregadoPor(e),
            editable: () => _entregadoPor(codSucursalCheque),
          ),
          _celda(
            'tipo',
            etiqueta: 'Tipo',
            bloqueado: e == null ? null : textoTipoCheque(e),
            editable:
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _desplegable<String>(
                      etiqueta: 'Tipo',
                      valor: tipoSel,
                      opciones: [
                        for (final o in catalogos.tiposCheque)
                          (o.codigo, o.nombre),
                      ],
                      alElegir: (v) {
                        setState(() => _tipo = v);
                        _marcar();
                      },
                      vacio: 'Elige el tipo.',
                    ),
                    if (tipoInvalido)
                      const NotaDelDato(
                        tono: TonoNota.aviso,
                        texto:
                            'El tipo guardado de este cheque no es válido. '
                            'Elige Pago o Respaldo para poder guardar.',
                      ),
                  ],
                ),
          ),
          _celda(
            'cliente',
            etiqueta: 'Cliente',
            bloqueado: e?.datoCliente,
            completa: true,
            editable:
                () => ComboClienteCheque(
                  codEmpresa: codEmpresa,
                  eligio: _codCliente != null,
                  textoInicial: _textoCliente,
                  alElegir: (c) {
                    setState(() {
                      _codCliente = c.codCliente;
                      _textoCliente = etiquetaCliente(c);
                    });
                    _marcar();
                  },
                  alEscribir: () {
                    // Escribir de nuevo invalida la eleccion anterior.
                    if (_codCliente != null) setState(() => _codCliente = null);
                    _marcar();
                  },
                  validar:
                      (_) =>
                          (_codCliente ?? '').isEmpty
                              ? 'Elige un cliente de la lista.'
                              : null,
                ),
          ),
          _celda(
            'banco',
            etiqueta: 'Banco',
            bloqueado: e?.nombreBanco,
            editable: _banco,
          ),
          _celda(
            'nroCheque',
            etiqueta: 'Nro. de cheque',
            bloqueado: e?.cheque.nrocheque,
            editable:
                () => TextFormField(
                  controller: _nro,
                  inputFormatters: [LengthLimitingTextInputFormatter(45)],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nro. de cheque',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (t) {
                    final v = (t ?? '').trim();
                    if (v.isEmpty) return 'Ingresa el nro. de cheque.';
                    if (RegExp(r'^0+$').hasMatch(v)) {
                      return 'El nro. de cheque no puede ser solo ceros.';
                    }
                    return ReglasCheque.errorNroCheque(v);
                  },
                ),
          ),
          _celda(
            'monto',
            etiqueta: 'Monto',
            bloqueado: e == null ? null : textoMontoSinMoneda(e),
            editable:
                () => TextFormField(
                  controller: _monto,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontFeatures: cifrasTabulares),
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (t) {
                    if ((t ?? '').trim().isEmpty) {
                      return 'Ingresa el monto del cheque.';
                    }
                    return ReglasCheque.leerMonto(t) == null
                        ? 'El monto no es un número válido.'
                        : null;
                  },
                ),
          ),
          _celda(
            'moneda',
            etiqueta: 'Moneda',
            bloqueado:
                e == null
                    ? null
                    : (e.descMoneda.trim().isNotEmpty
                        ? e.descMoneda
                        : e.cheque.moneda),
            editable:
                () => _desplegable<String>(
                  etiqueta: 'Moneda',
                  valor: monedaSel,
                  opciones: [
                    for (final o in catalogos.monedas) (o.codigo, o.nombre),
                  ],
                  alElegir: (v) {
                    setState(() => _moneda = v);
                    _marcar();
                  },
                  vacio: 'Elige la moneda.',
                ),
          ),
          _celda(
            'aOrdenDe',
            etiqueta: 'A la orden de',
            bloqueado: e?.cheque.aOrdenDe,
            completa: true,
            editable:
                () => TextFormField(
                  controller: _aOrden,
                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'A la orden de',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (t) {
                    final v = (t ?? '').trim();
                    if (v.isEmpty) {
                      return 'Ingresa a la orden de quién está el cheque.';
                    }
                    return ReglasCheque.errorAOrdenDe(v);
                  },
                ),
          ),
          _celda(
            'fechaCheque',
            etiqueta: 'Fecha del cheque',
            bloqueado: textoFecha(_fechaCheque),
            editable:
                () => CampoFechaCheque(
                  etiqueta: 'Fecha del cheque',
                  valor: _fechaCheque,
                  ultima: DateTime(DateTime.now().year + 5),
                  onCambio: _alElegirFechaCheque,
                ),
          ),
          _celda(
            'fechaCobrar',
            etiqueta: 'Fecha de cobro',
            bloqueado: textoFecha(_esAlta ? _fechaCheque : _fechaCobrar),
            ayudaBloqueado:
                _esAlta
                    ? 'Es la fecha del cheque.'
                    : 'Solo cambia con la acción «Fecha de cobro».',
            editable: _fechaCobrarEditable,
          ),
          _celda(
            'talonario',
            etiqueta: 'Talonario manual',
            editable:
                () => TextFormField(
                  controller: _talonario,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _alEditarTalonarioORecibo(),
                  decoration: const InputDecoration(
                    labelText: 'Talonario manual',
                    helperText: 'Del talonario asignado. Si no hay, 0.',
                    helperMaxLines: 2,
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (t) {
                    final v = (t ?? '').trim();
                    if (v.isEmpty) return 'Ingresa el talonario manual (0 si no hay).';
                    final f = ReglasCheque.errorNroTalonario(v);
                    if (f != null) return f;
                    return ReglasCheque.errorTalonarioSegunRecibo(
                      reciboManual: _recibo.text.trim(),
                      nroTalonario: v,
                    );
                  },
                ),
          ),
          _celda(
            'recibo',
            etiqueta: 'Recibo manual',
            editable:
                () => TextFormField(
                  controller: _recibo,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _alEditarTalonarioORecibo(),
                  decoration: const InputDecoration(
                    labelText: 'Recibo manual',
                    helperText: 'Del talonario asignado. Si lo dejó el cliente, 0.',
                    helperMaxLines: 2,
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (t) {
                    final v = (t ?? '').trim();
                    if (v.isEmpty) return 'Ingresa el recibo manual (0 si no hay).';
                    final f = ReglasCheque.errorReciboManual(v);
                    if (f != null) return f;
                    return ReglasCheque.errorReciboSegunEntrega(
                      codEmpleado: _codEmpleado,
                      reciboManual: v,
                    );
                  },
                ),
          ),
          // Debajo de los dos campos, a todo el ancho de su fila. Sin nada que
          // decir no ocupa lugar (ni su espacio entre filas).
          if (_puede('talonario') &&
              _puede('recibo') &&
              _comprobador.estado.visible)
            _CeldaForm(
              AvisoTalonarioCheque(estado: _comprobador.estado),
              completa: true,
              clave: const ValueKey('celda-aviso-talonario'),
            ),
          _celda(
            'observacion',
            etiqueta: 'Observación',
            bloqueado: e?.observacion,
            completa: true,
            editable:
                () => TextFormField(
                  controller: _observacion,
                  maxLength: 200,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    helperText: 'Opcional. Queda en la acción de recepción.',
                    border: OutlineInputBorder(),
                  ),
                ),
          ),
        ]),
      ],
    );

    return Form(
      key: _form,
      onChanged: _marcar,
      autovalidateMode:
          _intentado
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
      child: MarcoPanelCheque(
        titulo: _titulo,
        subtitulo: _subtitulo,
        onCerrar: ocupado ? () {} : _cerrar,
        cuerpo: cuerpo,
        acciones: [
          TextButton(
            onPressed: ocupado ? null : _cerrar,
            child: const Text('Cancelar'),
          ),
          BotonGuardarCheque(
            etiqueta: _esAlta ? 'Registrar cheque' : 'Guardar cambios',
            ocupado: ocupado,
            // Sin empresa el cheque no tendria donde quedar.
            onPressed: (ocupado || sinEmpresa) ? null : () => _guardar(catalogos),
          ),
        ],
      ),
    );
  }

  // ── Piezas del formulario ────────────────────────────────────────────────

  /// Un campo: editable o, si el modo no lo deja, de solo lectura. Los dos
  /// llevan su clave para que se pueda comprobar cual es cual.
  _CeldaForm _celda(
    String campo, {
    required String etiqueta,
    String? bloqueado,
    String? ayudaBloqueado,
    bool completa = false,
    required Widget Function() editable,
  }) {
    final clave = ValueKey('celda-$campo');
    if (_puede(campo)) {
      return _CeldaForm(
        KeyedSubtree(
          key: claveCampoCheque(campo, bloqueado: false),
          child: editable(),
        ),
        completa: completa,
        clave: clave,
      );
    }
    // Empresa y sucursal son siempre de solo lectura y no se anuncian como un
    // campo aparte de «editable» en el resto: llevan igual su clave.
    return _CeldaForm(
      _CampoBloqueado(
        clave: claveCampoCheque(campo, bloqueado: true),
        etiqueta: etiqueta,
        valor: bloqueado,
        ayuda: ayudaBloqueado,
      ),
      completa: completa,
      clave: clave,
    );
  }

  /// La empresa a la que pertenece el cheque: en un alta, la activa de la
  /// pantalla; en una edicion, la suya (la activa solo si el dato falta). Null
  /// mientras no se sabe.
  int? _codEmpresa(EmpresaChequeEntity? activa) {
    final propia = widget.existente?.cheque.codEmpresa;
    if (!_esAlta && propia != null && propia > 0) return propia;
    return activa?.codEmpresa;
  }

  /// El nombre de esa empresa: el que trae el cheque en una edicion y, si no,
  /// el de la lista de empresas.
  String? _nombreEmpresa(
    EmpresaChequeEntity? activa,
    List<EmpresaChequeEntity> empresas,
    int? codEmpresa,
  ) {
    final e = widget.existente;
    if (e != null && e.datoEmpresa.trim().isNotEmpty) return e.datoEmpresa;
    if (e == null) return activa?.nombre;
    return empresas
        .where((x) => x.codEmpresa == codEmpresa)
        .map((x) => x.nombre)
        .firstOrNull;
  }

  /// Por que no se puede registrar todavia: la lista de empresas carga, fallo o
  /// vino vacia. Es el unico camino para que el alta no abra con empresa.
  Widget _avisoSinEmpresa(AsyncValue<List<EmpresaChequeEntity>> async) {
    if (async.hasError && !async.isLoading) {
      return NotaDelDato(
        tono: TonoNota.error,
        texto:
            'No se pudo cargar la empresa: '
            '${mensajeDeErrorCheque(async.error!)}',
        accion: TextButton(
          onPressed: () => ref.invalidate(empresasChequeProvider),
          child: const Text('Reintentar'),
        ),
      );
    }
    if (async.valueOrNull?.isEmpty ?? false) {
      return const NotaDelDato(
        tono: TonoNota.aviso,
        texto: 'No hay empresas disponibles para registrar cheques.',
      );
    }
    return const NotaDelDato(texto: 'Cargando la empresa…');
  }

  Widget _desplegable<T>({
    required String etiqueta,
    required T? valor,
    required List<(T, String)> opciones,
    required ValueChanged<T?> alElegir,
    required String vacio,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey('$etiqueta-$valor-${opciones.length}'),
      value: opciones.any((o) => o.$1 == valor) ? valor : null,
      isExpanded: true,
      items: [
        for (final (v, texto) in opciones)
          DropdownMenuItem<T>(
            value: v,
            child: Text(texto, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: opciones.isEmpty ? null : alElegir,
      decoration: InputDecoration(
        labelText: etiqueta,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v == null ? vacio : null,
    );
  }

  Widget _entregadoPor(int codSucursal) {
    final async = ref.watch(personalEntreganProvider(codSucursal));
    final personal = async.valueOrNull ?? const <PersonalChequeEntity>[];
    final e = widget.existente;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _desplegable<int>(
          etiqueta: 'Entregado por',
          valor: _codEmpleado,
          opciones: [
            // Como el legacy: quien lo dejo es el propio cliente (codEmpleado 0).
            (0, '- Cliente -'),
            for (final p in personal) (p.codEmpleado, p.nombreCompleto),
            // Quien lo trajo y hoy ya no figura entre los activos de la
            // sucursal: sin su item, el desplegable no podria mostrarlo.
            if (_codEmpleado != 0 &&
                !personal.any((p) => p.codEmpleado == _codEmpleado))
              (
                _codEmpleado,
                e == null ? 'Empleado $_codEmpleado' : textoEntregadoPor(e),
              ),
          ],
          alElegir: (v) {
            setState(() => _codEmpleado = v ?? 0);
            _marcar();
          },
          vacio: 'Elige quién lo entregó.',
        ),
        if (async.hasError)
          NotaDelDato(
            tono: TonoNota.aviso,
            texto:
                'No se pudo cargar el personal: '
                '${mensajeDeErrorCheque(async.error!)}',
            accion: TextButton(
              onPressed: () => ref.invalidate(personalEntreganProvider(codSucursal)),
              child: const Text('Reintentar'),
            ),
          ),
      ],
    );
  }

  Widget _banco() {
    final async = ref.watch(obtenerBancos);
    final bancos = async.valueOrNull ?? const <BancoEntity>[];
    final e = widget.existente;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _desplegable<int>(
          etiqueta: 'Banco',
          valor: _codBanco,
          opciones: [
            for (final b in bancos) (b.codBanco, b.nombre),
            // Un banco que ya no esta en la lista igual se muestra.
            if (_codBanco != null &&
                _codBanco != 0 &&
                !bancos.any((b) => b.codBanco == _codBanco))
              (_codBanco!, textoODash(e?.nombreBanco)),
          ],
          alElegir: (v) {
            setState(() => _codBanco = v);
            _marcar();
          },
          vacio: 'Elige el banco.',
        ),
        if (async.hasError)
          NotaDelDato(
            tono: TonoNota.aviso,
            texto: 'No se pudo cargar la lista de bancos.',
            accion: TextButton(
              onPressed: () => ref.invalidate(obtenerBancos),
              child: const Text('Reintentar'),
            ),
          ),
      ],
    );
  }

  void _alElegirFechaCheque(DateTime? f) {
    setState(() {
      final anterior = _fechaCheque;
      _fechaCheque = f;
      // La fecha de cobro sigue a la del cheque. El administrador puede haberla
      // fijado a mano: solo se la mueve si seguia igual a la fecha anterior.
      if (_modo != ModoRegistroCheque.admin ||
          _fechaCobrar == null ||
          _fechaCobrar == anterior) {
        _fechaCobrar = f;
      }
    });
    _marcar();
  }

  /// Fecha de cobro del administrador: +-28 dias de la del cheque.
  Widget _fechaCobrarEditable() {
    final cheque = _fechaCheque;
    final rango = cheque == null ? null : ReglasCheque.rangoCobro(cheque);
    return CampoFechaCheque(
      etiqueta: 'Fecha de cobro',
      valor: _fechaCobrar,
      primera: rango?.desde,
      ultima: rango?.hasta,
      ayuda:
          rango == null
              ? 'Elige primero la fecha del cheque.'
              : 'Hasta ${ReglasCheque.diasToleranciaCobro} días antes o después '
                  'de la fecha del cheque.',
      onCambio: (f) {
        setState(() => _fechaCobrar = f);
        _marcar();
      },
      validar: (f) {
        if (f == null || cheque == null) return null;
        return ReglasCheque.cobroEnRango(f, cheque)
            ? null
            : 'La fecha de cobro debe estar a '
                '${ReglasCheque.diasToleranciaCobro} días o menos de la del '
                'cheque.';
      },
    );
  }
}

/// El texto del monto sin moneda, para el campo de solo lectura.
String textoMontoSinMoneda(ChequeFilaEntity c) {
  final m = c.cheque.monto;
  return m == null ? '—' : m.toStringAsFixed(2);
}

// ═══════════════════════════════════════════════════════════════════════════
// CUADRICULA Y CAMPO BLOQUEADO
// ═══════════════════════════════════════════════════════════════════════════

class _CeldaForm {
  const _CeldaForm(this.hijo, {this.completa = false, required this.clave});

  final Widget hijo;

  /// Ocupa todo el ancho aunque quepan dos columnas.
  final bool completa;

  /// Identifica la celda: una que aparece o desaparece en medio de la lista (la
  /// linea del talonario) no puede hacer que las demas cambien de dueno y pierdan
  /// su estado.
  final Key clave;
}

/// Dos columnas cuando caben y una cuando no. Se mide el ancho que tiene el
/// formulario, no el de la pantalla: el mismo panel es un dialogo en escritorio
/// y pantalla completa en el telefono.
class _Cuadricula extends StatelessWidget {
  const _Cuadricula(this.celdas);

  final List<_CeldaForm> celdas;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final dos = c.maxWidth >= 480;
        final medio =
            dos ? ((c.maxWidth - Esp.l) / 2).floorToDouble() : c.maxWidth;
        return Wrap(
          spacing: Esp.l,
          runSpacing: Esp.l,
          children: [
            for (final x in celdas)
              SizedBox(
                key: x.clave,
                width: x.completa ? c.maxWidth : medio,
                child: x.hijo,
              ),
          ],
        );
      },
    );
  }
}

/// Un dato que este modo no deja editar: se ve, con el candado, y no se puede
/// tocar.
class _CampoBloqueado extends StatelessWidget {
  const _CampoBloqueado({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    this.ayuda,
  });

  final ValueKey<String> clave;
  final String etiqueta;
  final String? valor;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: clave,
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          helperMaxLines: 3,
          enabled: false,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(Icons.lock_outline, size: 16, color: cs.outline),
        ),
        child: Text(
          textoODash(valor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontFeatures: cifrasTabulares,
          ),
        ),
      ),
    );
  }
}
