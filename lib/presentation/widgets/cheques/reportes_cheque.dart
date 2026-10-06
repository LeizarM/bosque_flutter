/// Los reportes en PDF del modulo de cheques: los cinco de la barra (`btnRpt1CH`
/// a `btnRpt5CH`) y la base comun que usa tambien la nomina del traspaso.
///
/// En el legacy son plantillas Jasper que arma el servidor; aqui el servidor
/// devuelve el PDF y la app lo muestra con `core/ui/visor_pdf.dart`, como
/// Garantias. Cada dialogo replica los campos del suyo (`chequeRptModal`,
/// `chequeRptModal02`, `custodioRptModal`, `chequeRecepcion`, `rptTraspAdmMod`) y
/// no su diseno.
///
/// **Empresa y sucursal salen de la pantalla**, no del login: la empresa activa
/// del combo «Empresa» y la sucursal de la grilla llegan ya resueltas. El
/// servidor exige el boton de cada reporte (403 sin el); la barra solo lo oculta.
///
/// **Un reporte no escribe nada**: no pasa por `operacionesChequesProvider`, asi
/// que no relee la grilla ni apaga su barra de progreso. Cada dialogo lleva su
/// propio «generando» y su propio error.
///
/// El error del servidor se muestra **completo y tal cual** (varias lineas si las
/// trae) y el dialogo queda abierto con lo elegido, para corregir y reintentar.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/repositories/cheques_repository.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/combo_cliente_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

// ═══════════════════════════════════════════════════════════════════════════
// VISOR Y GENERACION (BASE COMUN)
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que muestra un PDF ya generado. Es `mostrarPdf` de `core/ui`; existe como
/// provider para que una prueba lo sustituya (el visor real usa plugins que no
/// hay en las pruebas) y compruebe que bytes, titulo y nombre llegaron.
typedef VisorPdfCheque =
    Future<void> Function(
      BuildContext context, {
      required Uint8List bytes,
      required String titulo,
      required String nombreArchivo,
    });

final visorPdfChequeProvider = Provider<VisorPdfCheque>((ref) => mostrarPdf);

/// El «generando» y el error de un dialogo que baja un PDF.
///
/// [generarPdf] apaga el doble toque (ignora una segunda llamada mientras hay una
/// en curso; los botones ademas se apagan con [generando]), guarda el motivo de
/// un fallo en [errorDelPdf] **tal cual lo redacto el servidor** y, si salio
/// bien, abre el visor encima del dialogo, que sigue abierto debajo.
mixin GeneradorPdfCheque<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool generando = false;

  /// El motivo del ultimo fallo, listo para mostrar; null si no hubo o si ya se
  /// reintento.
  String? errorDelPdf;

  Future<void> generarPdf({
    required Future<Uint8List> Function(ChequesRepository repo) generar,
    required String titulo,
    required String nombreArchivo,
  }) async {
    if (generando) return;
    setState(() {
      generando = true;
      errorDelPdf = null;
    });

    final Uint8List bytes;
    try {
      bytes = await generar(ref.read(chequesRepositoryProvider));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        generando = false;
        errorDelPdf = mensajeDeErrorCheque(e);
      });
      return;
    }
    if (!mounted) return;
    setState(() => generando = false);
    await ref.read(visorPdfChequeProvider)(
      context,
      bytes: bytes,
      titulo: titulo,
      nombreArchivo: nombreArchivo,
    );
  }
}

/// El boton «Generar PDF»: con progreso mientras baja el archivo y apagado
/// mientras tanto.
class BotonGenerarPdfCheque extends StatelessWidget {
  const BotonGenerarPdfCheque({
    super.key,
    required this.generando,
    required this.onPressed,
    this.etiqueta = 'Generar PDF',
  });

  final bool generando;
  final VoidCallback? onPressed;
  final String etiqueta;

  @override
  Widget build(BuildContext context) => BotonGuardarCheque(
    etiqueta: etiqueta,
    etiquetaOcupado: 'Generando…',
    icono: Icons.picture_as_pdf_outlined,
    ocupado: generando,
    onPressed: onPressed,
  );
}

DateTime _hoy() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// «LA PAZ · Sucursal LA PAZ»: la empresa y la sucursal sobre las que trabaja el
/// reporte, para que se vea de que lugar sale. El nombre si ya llego la lista; el
/// codigo si no.
String _subtituloReporte(WidgetRef ref, int codEmpresa, int codSucursal) {
  final empresas = ref.watch(empresasChequeProvider).valueOrNull;
  final empresa =
      empresas
          ?.where((e) => e.codEmpresa == codEmpresa)
          .map((e) => e.nombre)
          .firstOrNull;
  final sucursal =
      ref
          .watch(sucursalesChequeActivasProvider)
          .where((s) => s.codSucursal == codSucursal)
          .map((s) => s.nombre)
          .firstOrNull;
  return '${(empresa ?? '').trim().isEmpty ? 'Empresa $codEmpresa' : empresa} · '
      'Sucursal ${sucursal ?? codSucursal}';
}

/// El error del PDF, pegado arriba del dialogo, o nada.
List<Widget> _errorArriba(String? error) => [
  if (error != null) ...[
    ErrorServidorCheque(error),
    const SizedBox(height: Esp.l),
  ],
];

/// Dos campos lado a lado y, en un ancho que no los deja respirar, uno sobre
/// otro.
class _ParDeCampos extends StatelessWidget {
  const _ParDeCampos({required this.a, required this.b});

  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, r) =>
            r.maxWidth < 440
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [a, const SizedBox(height: Esp.l), b],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: a),
                    const SizedBox(width: Esp.m),
                    Expanded(child: b),
                  ],
                ),
  );
}

/// Un desplegable con «Todos» (valor null) adelante.
class _DesplegableTodos<V> extends StatelessWidget {
  const _DesplegableTodos({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onCambio,
    this.ayuda,
  });

  final String etiqueta;
  final V? valor;
  final List<(V, String)> opciones;
  final ValueChanged<V?>? onCambio;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    // Un valor que la lista ya no trae haria fallar al desplegable.
    final vigente = opciones.any((o) => o.$1 == valor) ? valor : null;
    return DropdownButtonFormField<V?>(
      key: ValueKey('$etiqueta-$vigente-${opciones.length}'),
      value: vigente,
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Todos')),
        for (final (v, texto) in opciones)
          DropdownMenuItem<V?>(
            value: v,
            child: Text(texto, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onCambio,
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        helperMaxLines: 2,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// «Debe ser igual o posterior a la fecha inicial»; null si el rango esta bien o
/// si falta alguno de los dos extremos.
String? _errorDeRango(DateTime? desde, DateTime? hasta) =>
    (desde != null && hasta != null && hasta.isBefore(desde))
        ? 'Debe ser igual o posterior a la fecha inicial.'
        : null;

// ═══════════════════════════════════════════════════════════════════════════
// REPORTE: CHEQUES RECIBIDOS (btnRpt1CH)
// ═══════════════════════════════════════════════════════════════════════════

/// «Reporte» (`btnRpt1CH`): los cheques recibidos en caja entre dos fechas, que
/// por defecto son hoy. Cada fecha es opcional: vacia, no limita.
Future<void> abrirReporteRecibidos(
  BuildContext context, {
  required int codEmpresa,
  required int codSucursal,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 560,
  contenido:
      (_) => _DialogoReporteRecibidos(
        codEmpresa: codEmpresa,
        codSucursal: codSucursal,
      ),
);

class _DialogoReporteRecibidos extends ConsumerStatefulWidget {
  const _DialogoReporteRecibidos({
    required this.codEmpresa,
    required this.codSucursal,
  });

  final int codEmpresa;
  final int codSucursal;

  @override
  ConsumerState<_DialogoReporteRecibidos> createState() =>
      _DialogoReporteRecibidosState();
}

class _DialogoReporteRecibidosState
    extends ConsumerState<_DialogoReporteRecibidos>
    with GeneradorPdfCheque<_DialogoReporteRecibidos> {
  DateTime? _desde = _hoy();
  DateTime? _hasta = _hoy();

  Future<void> _generar() => generarPdf(
    generar:
        (repo) => repo.reporteRecibidos(
          codEmpresa: widget.codEmpresa,
          codSucursal: widget.codSucursal,
          fechaDesde: _desde,
          fechaHasta: _hasta,
        ),
    titulo: 'Cheques recibidos',
    nombreArchivo: 'reporte-cheques-recibidos.pdf',
  );

  @override
  Widget build(BuildContext context) {
    final errorRango = _errorDeRango(_desde, _hasta);

    return MarcoPanelCheque(
      titulo: 'Reporte de cheques recibidos',
      subtitulo: _subtituloReporte(ref, widget.codEmpresa, widget.codSucursal),
      onCerrar: generando ? () {} : () => Navigator.of(context).pop(),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._errorArriba(errorDelPdf),
          Text(
            'Cheques recibidos en caja entre las dos fechas. Deja una fecha '
            'vacía para no limitar por ella.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.l),
          _ParDeCampos(
            a: CampoFechaCheque(
              etiqueta: 'Fecha inicial',
              valor: _desde,
              obligatorio: false,
              permiteQuitar: true,
              onCambio: (f) => setState(() => _desde = f),
            ),
            b: CampoFechaCheque(
              etiqueta: 'Fecha final',
              valor: _hasta,
              obligatorio: false,
              permiteQuitar: true,
              error: errorRango,
              onCambio: (f) => setState(() => _hasta = f),
            ),
          ),
        ],
      ),
      acciones: [
        TextButton(
          onPressed: generando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        BotonGenerarPdfCheque(
          generando: generando,
          onPressed: errorRango == null ? _generar : null,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORTE: CHEQUES DE COBRANZA (btnRpt2CH)
// ═══════════════════════════════════════════════════════════════════════════

/// «Reporte Cheques» (`btnRpt2CH`): cheques de cobranza entre dos fechas (hoy por
/// defecto), de un estado y de un cliente de la empresa activa. «Todos» no manda
/// el filtro.
Future<void> abrirReporteCobranzas(
  BuildContext context, {
  required int codEmpresa,
  required int codSucursal,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 600,
  contenido:
      (_) => _DialogoReporteCobranzas(
        codEmpresa: codEmpresa,
        codSucursal: codSucursal,
      ),
);

class _DialogoReporteCobranzas extends ConsumerStatefulWidget {
  const _DialogoReporteCobranzas({
    required this.codEmpresa,
    required this.codSucursal,
  });

  final int codEmpresa;
  final int codSucursal;

  @override
  ConsumerState<_DialogoReporteCobranzas> createState() =>
      _DialogoReporteCobranzasState();
}

class _DialogoReporteCobranzasState
    extends ConsumerState<_DialogoReporteCobranzas>
    with GeneradorPdfCheque<_DialogoReporteCobranzas> {
  final _form = GlobalKey<FormState>();
  DateTime? _desde = _hoy();
  DateTime? _hasta = _hoy();
  String? _estado;

  /// Ya se intento generar: desde entonces el aviso del cliente se actualiza
  /// mientras se escribe. Antes no: avisar «elige uno de la lista» a quien
  /// todavia esta tecleando el nombre es ruido.
  bool _intentado = false;

  /// El cliente elegido de la lista; null = todos. Escribir despues invalida la
  /// eleccion, y un texto sin elegir no es «todos»: el campo lo senala.
  String? _codCliente;

  Future<void> _generar() async {
    setState(() => _intentado = true);
    if (!(_form.currentState?.validate() ?? false)) return;
    await generarPdf(
      generar:
          (repo) => repo.reporteCobranzas(
            codEmpresa: widget.codEmpresa,
            codSucursal: widget.codSucursal,
            fechaDesde: _desde,
            fechaHasta: _hasta,
            estado: _estado,
            codCliente: _codCliente,
          ),
      titulo: 'Cheques de cobranza',
      nombreArchivo: 'reporte-cheques-cobranza.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorRango = _errorDeRango(_desde, _hasta);
    final estados =
        ref.watch(catalogosChequeProvider).valueOrNull?.estadosCheque ??
        const <OpcionChequeEntity>[];

    return Form(
      key: _form,
      autovalidateMode:
          _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: MarcoPanelCheque(
        titulo: 'Reporte de cheques de cobranza',
        subtitulo: _subtituloReporte(
          ref,
          widget.codEmpresa,
          widget.codSucursal,
        ),
        onCerrar: generando ? () {} : () => Navigator.of(context).pop(),
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._errorArriba(errorDelPdf),
            Text(
              'Deja una fecha vacía, o el estado y el cliente en «Todos», para '
              'no filtrar por ellos.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.l),
            _ParDeCampos(
              a: CampoFechaCheque(
                etiqueta: 'Fecha inicial',
                valor: _desde,
                obligatorio: false,
                permiteQuitar: true,
                onCambio: (f) => setState(() => _desde = f),
              ),
              b: CampoFechaCheque(
                etiqueta: 'Fecha final',
                valor: _hasta,
                obligatorio: false,
                permiteQuitar: true,
                error: errorRango,
                onCambio: (f) => setState(() => _hasta = f),
              ),
            ),
            const SizedBox(height: Esp.l),
            _DesplegableTodos<String>(
              key: const ValueKey('reporte-estado'),
              etiqueta: 'Estado',
              valor: _estado,
              opciones: [for (final o in estados) (o.codigo, o.nombre)],
              onCambio: generando ? null : (v) => setState(() => _estado = v),
            ),
            const SizedBox(height: Esp.l),
            ComboClienteCheque(
              codEmpresa: widget.codEmpresa,
              eligio: _codCliente != null,
              textoInicial: '',
              opcional: true,
              ayuda:
                  _codCliente == null
                      ? 'Todos los clientes. Escribe parte del nombre o del '
                          'código para elegir uno.'
                      : 'Solo los cheques de este cliente. Borra el texto para '
                          'incluir a todos.',
              alElegir: (c) => setState(() => _codCliente = c.codCliente),
              // Escribir de nuevo invalida la eleccion anterior.
              alEscribir: () {
                if (_codCliente != null) setState(() => _codCliente = null);
              },
              validar:
                  (texto) =>
                      (texto ?? '').trim().isNotEmpty && _codCliente == null
                          ? 'Elige un cliente de la lista o borra el texto '
                              'para incluir a todos.'
                          : null,
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: generando ? null : () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          BotonGenerarPdfCheque(
            generando: generando,
            onPressed: errorRango == null ? _generar : null,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORTE: CHEQUES EN CUSTODIA (btnRpt3CH)
// ═══════════════════════════════════════════════════════════════════════════

/// «Reporte Custodio» (`btnRpt3CH`): los cheques entregados a custodia en una
/// fecha (hoy por defecto, opcional), de un responsable de la sucursal o de todos.
Future<void> abrirReporteCustodio(
  BuildContext context, {
  required int codEmpresa,
  required int codSucursal,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 560,
  contenido:
      (_) => _DialogoReporteCustodio(
        codEmpresa: codEmpresa,
        codSucursal: codSucursal,
      ),
);

class _DialogoReporteCustodio extends ConsumerStatefulWidget {
  const _DialogoReporteCustodio({
    required this.codEmpresa,
    required this.codSucursal,
  });

  final int codEmpresa;
  final int codSucursal;

  @override
  ConsumerState<_DialogoReporteCustodio> createState() =>
      _DialogoReporteCustodioState();
}

class _DialogoReporteCustodioState
    extends ConsumerState<_DialogoReporteCustodio>
    with GeneradorPdfCheque<_DialogoReporteCustodio> {
  DateTime? _fecha = _hoy();
  int? _codEmpleado;

  Future<void> _generar() => generarPdf(
    generar:
        (repo) => repo.reporteCustodio(
          codEmpresa: widget.codEmpresa,
          codSucursal: widget.codSucursal,
          fecha: _fecha,
          codEmpleado: _codEmpleado,
        ),
    titulo: 'Cheques en custodia',
    nombreArchivo: 'reporte-cheques-custodia.pdf',
  );

  @override
  Widget build(BuildContext context) {
    final asyncResponsables = ref.watch(
      personalCustodiaProvider(widget.codSucursal),
    );
    final responsables =
        asyncResponsables.valueOrNull ?? const <PersonalChequeEntity>[];

    return MarcoPanelCheque(
      titulo: 'Reporte de cheques en custodia',
      subtitulo: _subtituloReporte(ref, widget.codEmpresa, widget.codSucursal),
      onCerrar: generando ? () {} : () => Navigator.of(context).pop(),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._errorArriba(errorDelPdf),
          Text(
            'Cheques entregados en custodia en la fecha elegida. Deja la fecha '
            'vacía, o el responsable en «Todos», para no filtrar por ellos.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.l),
          CampoFechaCheque(
            etiqueta: 'Fecha de asignación',
            valor: _fecha,
            obligatorio: false,
            permiteQuitar: true,
            onCambio: (f) => setState(() => _fecha = f),
          ),
          const SizedBox(height: Esp.l),
          _DesplegableTodos<int>(
            key: const ValueKey('reporte-responsable'),
            etiqueta: 'Responsable',
            valor: _codEmpleado,
            ayuda: 'Jefe de cobranzas o cobrador de la sucursal.',
            opciones: [
              for (final p in responsables) (p.codEmpleado, p.nombreCompleto),
            ],
            onCambio:
                generando ? null : (v) => setState(() => _codEmpleado = v),
          ),
          if (asyncResponsables.isLoading && !asyncResponsables.hasValue)
            const Padding(
              padding: EdgeInsets.only(top: Esp.s),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (asyncResponsables.hasError && !asyncResponsables.isLoading)
            // La lista no es imprescindible: con «Todos» se puede generar igual.
            NotaDelDato(
              tono: TonoNota.error,
              texto:
                  'No se pudo cargar los responsables: '
                  '${mensajeDeErrorCheque(asyncResponsables.error!)} Puedes '
                  'generar el reporte de «Todos».',
              accion: TextButton(
                onPressed:
                    () => ref.invalidate(
                      personalCustodiaProvider(widget.codSucursal),
                    ),
                child: const Text('Reintentar'),
              ),
            ),
        ],
      ),
      acciones: [
        TextButton(
          onPressed: generando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        BotonGenerarPdfCheque(generando: generando, onPressed: _generar),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECIBO DEL ULTIMO CHEQUE (btnRpt4CH)
// ═══════════════════════════════════════════════════════════════════════════

/// «Recibo del Ultimo Cheque» (`btnRpt4CH`): sin campos. El recibo es el del
/// ultimo cheque que registro **este usuario** en la sucursal; si no registro
/// ninguno, el servidor responde con un mensaje y el dialogo lo muestra.
Future<void> abrirReciboUltimoCheque(
  BuildContext context, {
  required int codEmpresa,
  required int codSucursal,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 520,
  contenido:
      (_) => _DialogoReciboUltimoCheque(
        codEmpresa: codEmpresa,
        codSucursal: codSucursal,
      ),
);

class _DialogoReciboUltimoCheque extends ConsumerStatefulWidget {
  const _DialogoReciboUltimoCheque({
    required this.codEmpresa,
    required this.codSucursal,
  });

  final int codEmpresa;
  final int codSucursal;

  @override
  ConsumerState<_DialogoReciboUltimoCheque> createState() =>
      _DialogoReciboUltimoChequeState();
}

class _DialogoReciboUltimoChequeState
    extends ConsumerState<_DialogoReciboUltimoCheque>
    with GeneradorPdfCheque<_DialogoReciboUltimoCheque> {
  Future<void> _generar() => generarPdf(
    generar:
        (repo) => repo.reporteUltimoRecibo(
          codEmpresa: widget.codEmpresa,
          codSucursal: widget.codSucursal,
        ),
    titulo: 'Recibo del último cheque',
    nombreArchivo: 'recibo-ultimo-cheque.pdf',
  );

  @override
  Widget build(BuildContext context) {
    return MarcoPanelCheque(
      titulo: 'Recibo del último cheque',
      subtitulo: _subtituloReporte(ref, widget.codEmpresa, widget.codSucursal),
      onCerrar: generando ? () {} : () => Navigator.of(context).pop(),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._errorArriba(errorDelPdf),
          Text(
            'Se genera el recibo del último cheque que registraste en esta '
            'sucursal.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Esp.m),
          Text(
            'Si todavía no registraste ninguno aquí, el sistema te lo avisa.',
            style: context.apagado(),
          ),
        ],
      ),
      acciones: [
        TextButton(
          onPressed: generando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        BotonGenerarPdfCheque(generando: generando, onPressed: _generar),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REIMPRIMIR TRASPASO (btnRpt5CH, ADMINISTRADOR)
// ═══════════════════════════════════════════════════════════════════════════

/// «Imp Traspso» (`btnRpt5CH`): vuelve a imprimir la nomina de un traspaso
/// anterior. Se elige el dia (hoy por defecto), despues la hora de uno de los
/// traspasos de ese dia, y recien entonces se puede generar.
Future<void> abrirReimprimirTraspaso(
  BuildContext context, {
  required int codEmpresa,
  required int codSucursal,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 560,
  contenido:
      (_) => _DialogoReimprimirTraspaso(
        codEmpresa: codEmpresa,
        codSucursal: codSucursal,
      ),
);

class _DialogoReimprimirTraspaso extends ConsumerStatefulWidget {
  const _DialogoReimprimirTraspaso({
    required this.codEmpresa,
    required this.codSucursal,
  });

  final int codEmpresa;
  final int codSucursal;

  @override
  ConsumerState<_DialogoReimprimirTraspaso> createState() =>
      _DialogoReimprimirTraspasoState();
}

class _DialogoReimprimirTraspasoState
    extends ConsumerState<_DialogoReimprimirTraspaso>
    with GeneradorPdfCheque<_DialogoReimprimirTraspaso> {
  late final DateTime _hoyDia = _hoy();
  late DateTime _fecha = _hoyDia;
  int? _codAccion;

  ConsultaHorasTraspasoCheque get _consulta => (
    codSucursal: widget.codSucursal,
    fecha: _fecha,
  );

  Future<void> _generar(int codAccion) => generarPdf(
    generar:
        (repo) => repo.reporteReimpresionTraspaso(
          codEmpresa: widget.codEmpresa,
          codSucursal: widget.codSucursal,
          codAccion: codAccion,
        ),
    titulo: 'Traspaso de cheques',
    nombreArchivo: 'reimpresion-traspaso-cheques.pdf',
  );

  @override
  Widget build(BuildContext context) {
    final asyncHoras = ref.watch(horasDeTraspasoChequeProvider(_consulta));
    final horas =
        asyncHoras.valueOrNull ?? const <HoraTraspasoChequeEntity>[];
    // Solo cuenta lo que sigue en la lista del dia: al cambiar la fecha la hora
    // elegida deja de valer.
    final elegida = horas.any((h) => h.codAccion == _codAccion)
        ? _codAccion
        : null;

    final Widget lista;
    if (asyncHoras.hasError && !asyncHoras.isLoading) {
      lista = NotaDelDato(
        tono: TonoNota.error,
        texto:
            'No se pudo cargar los traspasos: '
            '${mensajeDeErrorCheque(asyncHoras.error!)}',
        accion: TextButton(
          onPressed: () => ref.invalidate(horasDeTraspasoChequeProvider(_consulta)),
          child: const Text('Reintentar'),
        ),
      );
    } else if (!asyncHoras.hasValue) {
      lista = const LinearProgressIndicator(minHeight: 2);
    } else if (horas.isEmpty) {
      lista = const NotaDelDato(
        key: ValueKey('sin-traspasos'),
        tono: TonoNota.info,
        icono: Icons.event_busy_outlined,
        texto:
            'No hay traspasos en esa fecha. Elige otro día: solo aparecen los '
            'traspasos a cobranza registrados en la fecha elegida.',
      );
    } else {
      lista = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hora del traspaso', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              for (final h in horas)
                ChoiceChip(
                  key: ValueKey('hora-${h.codAccion}'),
                  label: Text(
                    h.hora,
                    style: const TextStyle(fontFeatures: cifrasTabulares),
                  ),
                  selected: elegida == h.codAccion,
                  onSelected:
                      generando
                          ? null
                          : (_) => setState(() => _codAccion = h.codAccion),
                ),
            ],
          ),
        ],
      );
    }

    return MarcoPanelCheque(
      titulo: 'Reimprimir traspaso',
      subtitulo: _subtituloReporte(ref, widget.codEmpresa, widget.codSucursal),
      onCerrar: generando ? () {} : () => Navigator.of(context).pop(),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._errorArriba(errorDelPdf),
          Text(
            'Vuelve a imprimir la nómina de un traspaso anterior. Elige el día '
            'y la hora del traspaso.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.l),
          CampoFechaCheque(
            etiqueta: 'Fecha del traspaso',
            valor: _fecha,
            ultima: _hoyDia,
            onCambio: (f) {
              if (f == null) return;
              // Otro dia, otros traspasos: la hora elegida ya no vale.
              setState(() {
                _fecha = DateTime(f.year, f.month, f.day);
                _codAccion = null;
              });
            },
          ),
          const SizedBox(height: Esp.l),
          lista,
        ],
      ),
      acciones: [
        TextButton(
          onPressed: generando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        BotonGenerarPdfCheque(
          generando: generando,
          onPressed: elegida == null ? null : () => _generar(elegida),
        ),
      ],
    );
  }
}
