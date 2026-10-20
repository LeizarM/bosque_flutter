/// Carga en lote del banco: categoría, plantilla, datos pegados o un CSV,
/// vista previa con el estado que da `p_list_tcpe_BancoLote` V e importación
/// de las filas OK (`p_abm_tcpe_BancoLote` I). Ninguna regla se decide aquí.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/descargar_archivo.dart';
import 'package:bosque_flutter/core/utils/importacion_preguntas.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fila_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_importacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_pregunta.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

/// Abre el asistente. Devuelve true si se importó al menos una pregunta.
Future<bool> abrirImportacionPreguntas(
  BuildContext context, {
  BigInt? codClasificacion,
  required List<TcpeClasificacionEntity> categorias,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final asistente = AsistenteImportacion(codClasificacion: codClasificacion, categorias: categorias);
  final r =
      MediaQuery.sizeOf(context).width < 600
          ? await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => asistente))
          : await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => asistente);
  return r ?? false;
}

/// Rótulo fijo de cada estado de SQL; el detalle es el `mensaje` de la fila.
String etiquetaEstadoFila(EstadoFilaImportacion e) => switch (e) {
  EstadoFilaImportacion.ok => 'Lista para importar',
  EstadoFilaImportacion.duplicadaEnBanco => 'Ya está en el banco',
  EstadoFilaImportacion.duplicadaEnArchivo => 'Repetida en el archivo',
  EstadoFilaImportacion.error => 'Con error',
};

(TonoEtiqueta, MarcaBurbuja, IconData) _tonoFila(EstadoFilaImportacion e) => switch (e) {
  EstadoFilaImportacion.ok => (TonoEtiqueta.exito, MarcaBurbuja.marcada, Icons.check_circle_outline),
  EstadoFilaImportacion.duplicadaEnBanco => (TonoEtiqueta.aviso, MarcaBurbuja.aviso, Icons.library_books_outlined),
  EstadoFilaImportacion.duplicadaEnArchivo => (TonoEtiqueta.neutro, MarcaBurbuja.neutra, Icons.file_copy_outlined),
  EstadoFilaImportacion.error => (TonoEtiqueta.error, MarcaBurbuja.error, Icons.error_outline),
};

class AsistenteImportacion extends ConsumerStatefulWidget {
  const AsistenteImportacion({super.key, this.codClasificacion, required this.categorias});

  final BigInt? codClasificacion;
  final List<TcpeClasificacionEntity> categorias;

  @override
  ConsumerState<AsistenteImportacion> createState() => _AsistenteImportacionState();
}

class _AsistenteImportacionState extends ConsumerState<AsistenteImportacion> {
  static const _pasos = ['Categoría', 'Plantilla', 'Datos', 'Vista previa', 'Importar'];

  int _paso = 0;
  late BigInt? _categoria =
      widget.categorias.any((c) => c.codClasificacion == widget.codClasificacion) ? widget.codClasificacion : null;
  final _texto = TextEditingController();
  Timer? _pausa;
  LecturaPlantilla _lectura = const LecturaPlantilla();
  String? _archivo;

  // Vista previa: lo que respondió SQL para la lectura actual.
  List<TcpeFilaImportacionEntity>? _filas;
  Object? _errorValidacion;
  bool _validando = false;
  EstadoFilaImportacion? _filtro;

  bool _importando = false;
  TcpeResultadoImportacionEntity? _resultado;

  @override
  void dispose() {
    _pausa?.cancel();
    _texto.dispose();
    super.dispose();
  }

  TcpeClasificacionEntity? get _cat => widget.categorias.where((c) => c.codClasificacion == _categoria).firstOrNull;

  int get _listas => (_filas ?? const []).where((f) => f.importable).length;

  void _leer(String texto) {
    _pausa?.cancel();
    _pausa = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _lectura = leerPlantillaPreguntas(texto);
        _filas = null;
        _errorValidacion = null;
      });
    });
  }

  Future<void> _descargarPlantilla() async {
    try {
      final ok = await descargarBytes(utf8.encode(plantillaPreguntasCsv()), kNombrePlantilla, 'text/csv');
      if (mounted && ok) avisar(context, 'Plantilla descargada: $kNombrePlantilla');
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  Future<void> _elegirArchivo() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt', 'tsv'],
        withData: true,
      );
      final f = (r == null || r.files.isEmpty) ? null : r.files.single;
      if (f == null || f.bytes == null || !mounted) return;
      final texto = decodificarCsv(f.bytes!);
      _pausa?.cancel();
      setState(() {
        _archivo = f.name;
        _texto.text = texto;
        _lectura = leerPlantillaPreguntas(texto);
        _filas = null;
        _errorValidacion = null;
      });
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  Future<void> _validar() async {
    final cod = _categoria;
    if (cod == null || _lectura.vacia) return;
    setState(() {
      _validando = true;
      _errorValidacion = null;
      _filtro = null;
    });
    try {
      final filas = await ref.read(examenesRepositoryProvider).validarImportacion(cod, _lectura.preguntas);
      if (!mounted) return;
      setState(() {
        _filas = [...filas]..sort((a, b) => a.fila.compareTo(b.fila));
        _validando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorValidacion = e;
        _validando = false;
      });
    }
  }

  Future<void> _importar() async {
    final cod = _categoria;
    if (cod == null || _listas == 0) return;
    final omitidas = (_filas?.length ?? 0) - _listas;
    final ok = await confirmar(
      context,
      titulo: 'Importar $_listas ${_listas == 1 ? 'pregunta' : 'preguntas'}',
      detalle:
          'Se agregan a «${_cat?.nombre ?? ''}». '
          '${omitidas > 0 ? '$omitidas ${omitidas == 1 ? 'fila se omite' : 'filas se omiten'} por estar duplicadas o con error. ' : ''}'
          'Para quitarlas después habrá que desactivarlas o eliminarlas una por una.',
      textoConfirmar: 'Importar',
    );
    if (!ok || !mounted) return;
    setState(() => _importando = true);
    try {
      final r = await ref.read(examenesRepositoryProvider).importarPreguntas(cod, _lectura.preguntas);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _resultado = r;
        _importando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _importando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  Future<void> _cerrar() async {
    final hayTrabajo = _texto.text.trim().isNotEmpty && _resultado == null;
    if (hayTrabajo) {
      final salir = await confirmar(
        context,
        titulo: '¿Salir sin importar?',
        detalle: 'Se pierde lo que pegaste o elegiste. El banco queda como estaba.',
        textoConfirmar: 'Salir',
        textoCancelar: 'Seguir aquí',
        destructiva: true,
      );
      if (!salir || !mounted) return;
    }
    Navigator.of(context).pop((_resultado?.insertadas ?? 0) > 0);
  }

  void _ir(int paso) {
    setState(() => _paso = paso);
    if (paso == 3 && _filas == null && !_validando) _validar();
  }

  bool get _puedeSeguir => switch (_paso) {
    0 => _categoria != null,
    1 => true,
    2 => !_lectura.vacia,
    3 => _filas != null,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < 600;
        final contenido = _Marco(
          compacto: compacto,
          titulo: 'Importar preguntas',
          subtitulo: _cat == null ? null : 'Categoría: ${_cat!.nombre ?? ''}',
          pasos: PasosBurbuja(pasos: _pasos, actual: _paso, compacto: r.maxWidth < 760),
          onCerrar: _cerrar,
          cuerpo: AnimatedSwitcher(
            duration: duracionSuave(context, 200),
            // Arriba y no centrado: un paso corto no debe flotar en el medio del diálogo.
            layoutBuilder:
                (actual, previos) =>
                    Stack(alignment: Alignment.topCenter, children: [...previos, if (actual != null) actual]),
            child: KeyedSubtree(key: ValueKey('paso-$_paso-${_resultado != null}'), child: _cuerpo(context, compacto)),
          ),
          pie: _pie(context, compacto),
        );
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _cerrar();
          },
          child: contenido,
        );
      },
    );
  }

  List<Widget> _pie(BuildContext context, bool compacto) {
    if (_resultado != null) {
      return [
        TextButton(
          onPressed:
              () => setState(() {
                _resultado = null;
                _texto.clear();
                _archivo = null;
                _lectura = const LecturaPlantilla();
                _filas = null;
                _paso = 2;
              }),
          child: const Text('Importar otro archivo'),
        ),
        FilledButton(onPressed: _cerrar, child: const Text('Listo')),
      ];
    }
    final atras = TextButton.icon(
      onPressed: _paso == 0 || _importando ? null : () => _ir(_paso - 1),
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Atrás'),
    );
    final siguiente =
        _paso == 4
            ? BotonAccion(
              etiqueta: _listas == 0 ? 'Nada para importar' : 'Importar $_listas',
              etiquetaOcupado: 'Importando…',
              icono: Icons.download_done_outlined,
              ocupado: _importando,
              onPressed: _listas == 0 ? null : _importar,
            )
            : FilledButton.icon(
              onPressed: _puedeSeguir ? () => _ir(_paso + 1) : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(switch (_paso) {
                1 => 'Ya tengo los datos',
                2 => 'Ver vista previa',
                3 => 'Continuar',
                _ => 'Siguiente',
              }),
            );
    return [atras, siguiente];
  }

  Widget _cuerpo(BuildContext context, bool compacto) {
    if (_resultado != null) return _Resumen(resultado: _resultado!, enviadas: _lectura.filas.length);
    return switch (_paso) {
      0 => _pasoCategoria(context),
      1 => _pasoPlantilla(context, compacto),
      2 => _pasoDatos(context, compacto),
      3 => _pasoVistaPrevia(context),
      _ => _pasoImportar(context),
    };
  }

  // ── 1. Categoría ────────────────────────────────────────────────────────
  Widget _pasoCategoria(BuildContext context) {
    final opciones = [...widget.categorias]..sort((a, b) => (a.nombre ?? '').compareTo(b.nombre ?? ''));
    return _Desplazable(
      children: [
        _Titular(
          titulo: '¿A qué categoría van las preguntas?',
          detalle:
              'Todas las filas del archivo se cargan en la misma categoría. Los duplicados se buscan dentro de ella.',
        ),
        const SizedBox(height: Esp.l),
        ComboBuscable<BigInt>(
          etiqueta: 'Categoría',
          valor: _categoria,
          pista: 'Escribe para buscar la categoría…',
          opciones: [for (final c in opciones) DropdownMenuEntry(value: c.codClasificacion, label: c.nombre ?? '--')],
          onElegir:
              (v) => setState(() {
                _categoria = v;
                _filas = null;
              }),
        ),
        if (opciones.isEmpty)
          const NotaDelDato(
            texto: 'No hay categorías activas. Créala primero en «Áreas y categorías».',
            tono: TonoNota.aviso,
          ),
      ],
    );
  }

  // ── 2. Plantilla ────────────────────────────────────────────────────────
  Widget _pasoPlantilla(BuildContext context, bool compacto) {
    final cs = Theme.of(context).colorScheme;
    const ejemplo = [
      ['¿Qué color tiene la señal de prohibición?', 'Cerrada', '', 'Rojo', 'Verde', 'Azul', '', '', '', 'A'],
      [
        'Explica el bloqueo y etiquetado.',
        'Abierta',
        'Cortar la energía, bloquear y etiquetar.',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
    ];
    return _Desplazable(
      children: [
        _Titular(
          titulo: 'Usa la plantilla',
          detalle:
              'Una pregunta por fila. Las cerradas llevan sus opciones en las columnas A a F y las letras '
              'correctas (por ejemplo «A,C»); en las abiertas va la respuesta modelo y las opciones se ignoran.',
        ),
        const SizedBox(height: Esp.l),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _descargarPlantilla,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Descargar plantilla CSV'),
          ),
        ),
        const SizedBox(height: Esp.l),
        Text('COLUMNAS', style: _rotulo(context)),
        const SizedBox(height: Esp.s),
        if (compacto)
          for (var i = 0; i < kColumnasPlantilla.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: Row(
                children: [
                  BurbujaHoja(texto: String.fromCharCode(65 + i), tamanio: 26, marca: MarcaBurbuja.neutra),
                  const SizedBox(width: Esp.m),
                  Expanded(child: Text(kColumnasPlantilla[i])),
                ],
              ),
            )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            clipBehavior: Clip.antiAlias,
            child: ScrollConfiguration(
              behavior: const ArrastreLateral(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 56,
                  headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                  columns: [for (final c in kColumnasPlantilla) DataColumn(label: Text(c, style: _rotulo(context)))],
                  rows: [
                    for (final f in ejemplo)
                      DataRow(
                        cells: [
                          for (final v in f)
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(v, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: Esp.m),
        Text(
          'El ejemplo es solo una guía: la plantilla descargada viene vacía, con el separador «;» que usa Excel en español.',
          style: context.apagado(),
        ),
      ],
    );
  }

  // ── 3. Datos ────────────────────────────────────────────────────────────
  Widget _pasoDatos(BuildContext context, bool compacto) {
    final n = _lectura.filas.length;
    final avisos = _lectura.avisos;
    return _Desplazable(
      children: [
        _Titular(
          titulo: 'Pega las filas o elige el archivo',
          detalle: 'Copia las celdas desde Excel (con o sin encabezado) y pégalas aquí, o elige el CSV guardado.',
        ),
        const SizedBox(height: Esp.l),
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _elegirArchivo,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Elegir archivo CSV'),
            ),
            if (_archivo != null) Etiqueta(texto: _archivo!),
          ],
        ),
        const SizedBox(height: Esp.m),
        TextField(
          key: const ValueKey('importar-texto'),
          controller: _texto,
          minLines: compacto ? 6 : 8,
          maxLines: compacto ? 10 : 14,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontFamily: fuenteFija, fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Filas copiadas desde Excel',
            hintText: 'Pregunta⇥Tipo⇥Respuesta modelo⇥Opción A⇥…⇥Correctas',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (t) {
            setState(() => _archivo = null);
            _leer(t);
          },
        ),
        const SizedBox(height: Esp.m),
        AnimatedSwitcher(
          duration: duracionSuave(context),
          child:
              _texto.text.trim().isEmpty
                  ? const SizedBox.shrink()
                  : Semantics(
                    liveRegion: true,
                    child: NotaDelDato(
                      key: ValueKey('leidas-$n-${avisos.length}'),
                      tono: n == 0 ? TonoNota.aviso : TonoNota.exito,
                      texto:
                          n == 0
                              ? 'Todavía no se reconoce ninguna pregunta. Revisa que la columna Tipo diga Abierta o Cerrada.'
                              : '$n ${n == 1 ? 'pregunta leída' : 'preguntas leídas'}. En la vista previa se verifica cada una.',
                    ),
                  ),
        ),
        if (avisos.isNotEmpty) _Avisos(avisos: avisos),
      ],
    );
  }

  // ── 4. Vista previa ─────────────────────────────────────────────────────
  Widget _pasoVistaPrevia(BuildContext context) {
    if (_validando || (_filas == null && _errorValidacion == null)) {
      return const EsqueletoLista(filas: 5, altoFila: 56);
    }
    if (_errorValidacion != null) {
      return VacioExamenes(
        icono: Icons.rule_outlined,
        titulo: 'No se pudo verificar',
        detalle: textoParaUsuario(_errorValidacion),
        accion: 'Reintentar',
        iconoAccion: Icons.refresh,
        onAccion: _validar,
      );
    }
    final filas = _filas!;
    final cuenta = {for (final e in EstadoFilaImportacion.values) e: filas.where((f) => f.estado == e).length};
    final visibles = _filtro == null ? filas : filas.where((f) => f.estado == _filtro).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.l, Esp.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TiraEstados(
            tramos: [
              TramoTira(cuenta[EstadoFilaImportacion.ok]!, 'listas', TonoTramo.hecho),
              TramoTira(cuenta[EstadoFilaImportacion.duplicadaEnBanco]!, 'ya en el banco', TonoTramo.revisar),
              TramoTira(
                cuenta[EstadoFilaImportacion.duplicadaEnArchivo]!,
                'repetidas en el archivo',
                TonoTramo.pendiente,
              ),
              TramoTira(cuenta[EstadoFilaImportacion.error]!, 'con error', TonoTramo.alerta),
            ],
          ),
          const SizedBox(height: Esp.m),
          // Escritorio: chips a la vista. Teléfono: un combo, sin scroll lateral.
          LayoutBuilder(
            builder:
                (context, r) =>
                    r.maxWidth < 600
                        ? ComboFiltro<EstadoFilaImportacion>(
                          key: const ValueKey('filtro-estado'),
                          etiqueta: 'Mostrar',
                          valor: _filtro,
                          ancho: double.infinity,
                          textoTodos: 'Todas (${filas.length})',
                          opciones: [
                            for (final e in EstadoFilaImportacion.values)
                              if (cuenta[e]! > 0) (e, '${etiquetaEstadoFila(e)} (${cuenta[e]})'),
                          ],
                          onCambio: (v) => setState(() => _filtro = v),
                        )
                        : Wrap(
                          spacing: Esp.s,
                          runSpacing: Esp.s,
                          children: [
                            ChoiceChip(
                              label: Text('Todas (${filas.length})'),
                              selected: _filtro == null,
                              onSelected: (_) => setState(() => _filtro = null),
                            ),
                            for (final e in EstadoFilaImportacion.values)
                              if (cuenta[e]! > 0)
                                ChoiceChip(
                                  avatar: Icon(_tonoFila(e).$3, size: 18),
                                  label: Text('${etiquetaEstadoFila(e)} (${cuenta[e]})'),
                                  selected: _filtro == e,
                                  onSelected: (_) => setState(() => _filtro = _filtro == e ? null : e),
                                ),
                          ],
                        ),
          ),
          const SizedBox(height: Esp.m),
          Expanded(
            child: TablaExamenes<TcpeFilaImportacionEntity>(
              filas: visibles,
              claveFila: (f) => f.fila,
              vacio: const MensajeVacio(
                icono: Icons.filter_alt_off_outlined,
                titulo: 'Ninguna fila con ese estado',
                detalle: 'Elige «Todas» para ver el archivo completo.',
              ),
              columnas: [
                ColumnaExamen('Fila', (f) => _burbujaFila(f), flex: 1),
                ColumnaExamen('Pregunta', (f) => CeldaTexto(f.pregunta, lineas: 2), flex: 5),
                ColumnaExamen('Tipo', (f) => CeldaTexto(_tipo(f), apagado: true, lineas: 2), flex: 3),
                ColumnaExamen('Estado', (f) => _estado(f), flex: 3),
                ColumnaExamen('Mensaje', (f) => CeldaTexto(f.mensaje, lineas: 2, apagado: true), flex: 4),
              ],
              acciones: [
                AccionExamen(
                  'Ver la pregunta del banco',
                  Icons.open_in_new,
                  _verExistente,
                  visible: (f) => f.codPreguntaExistente != null,
                ),
              ],
              tarjeta:
                  (f) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _burbujaFila(f),
                      const SizedBox(width: Esp.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(oGuion(f.pregunta), maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: Esp.xs),
                            Text(_tipo(f), style: context.apagado()),
                            const SizedBox(height: Esp.s),
                            _estado(f),
                            if ((f.mensaje ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: Esp.xs),
                              Text(f.mensaje!.trim(), style: context.apagado()),
                            ],
                          ],
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

  Widget _burbujaFila(TcpeFilaImportacionEntity f) => Semantics(
    label: 'Fila ${f.fila}',
    child: BurbujaHoja(texto: '${f.fila}', tamanio: 30, marca: _tonoFila(f.estado).$2),
  );

  Widget _estado(TcpeFilaImportacionEntity f) {
    final (tono, _, icono) = _tonoFila(f.estado);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: _colorIcono(context, f.estado)),
        const SizedBox(width: Esp.xs),
        Flexible(child: Etiqueta(texto: etiquetaEstadoFila(f.estado), tono: tono)),
      ],
    );
  }

  static Color _colorIcono(BuildContext context, EstadoFilaImportacion e) {
    final cs = Theme.of(context).colorScheme;
    return switch (e) {
      EstadoFilaImportacion.ok => cs.primary,
      EstadoFilaImportacion.duplicadaEnBanco => cs.tertiary,
      EstadoFilaImportacion.duplicadaEnArchivo => cs.onSurfaceVariant,
      EstadoFilaImportacion.error => cs.error,
    };
  }

  static String _tipo(TcpeFilaImportacionEntity f) =>
      f.esCerrada
          ? 'Cerrada · ${f.cantOpciones} opc. · ${f.cantValidas} ${f.cantValidas == 1 ? 'válida' : 'válidas'}'
          : 'Abierta';

  Future<void> _verExistente(TcpeFilaImportacionEntity f) async {
    final cod = f.codPreguntaExistente;
    if (cod == null) return;
    try {
      final lista = await ref.read(examenesRepositoryProvider).listarPreguntas(codPregunta: cod);
      final p = lista.where((x) => x.codPregunta == cod).firstOrNull;
      if (!mounted) return;
      if (p == null) {
        avisar(context, 'La pregunta ya no está en el banco.', esError: true);
        return;
      }
      await editarPregunta(context, pregunta: p, categorias: widget.categorias);
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  // ── 5. Importar ─────────────────────────────────────────────────────────
  Widget _pasoImportar(BuildContext context) {
    final total = _filas?.length ?? 0;
    final omitidas = total - _listas;
    return _Desplazable(
      children: [
        _Titular(
          titulo: _listas == 0 ? 'Ninguna fila está lista' : 'Todo listo para importar',
          detalle:
              _listas == 0
                  ? 'Corrige el archivo según los mensajes de la vista previa y vuelve a pegarlo.'
                  : 'Solo se agregan las filas listas. El servidor las vuelve a verificar al guardar.',
        ),
        const SizedBox(height: Esp.xl),
        Wrap(
          spacing: Esp.xxl,
          runSpacing: Esp.l,
          children: [
            _Cifra(
              valor: _listas,
              rotulo: _listas == 1 ? 'pregunta se importa' : 'preguntas se importan',
              marca: MarcaBurbuja.marcada,
            ),
            _Cifra(
              valor: omitidas,
              rotulo: omitidas == 1 ? 'fila se omite' : 'filas se omiten',
              marca: MarcaBurbuja.neutra,
            ),
          ],
        ),
        const SizedBox(height: Esp.xl),
        Text('DESTINO', style: _rotulo(context)),
        const SizedBox(height: Esp.xs),
        Text(_cat?.nombre ?? '--', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

TextStyle? _rotulo(BuildContext context) => Theme.of(context).textTheme.labelSmall?.copyWith(
  fontFamily: fuenteFija,
  letterSpacing: 1.2,
  fontWeight: Peso.titulo,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
);

/// El marco del asistente: diálogo amplio en escritorio, pantalla completa en
/// el teléfono; cabecera con los pasos, cuerpo y acciones al pie.
class _Marco extends StatelessWidget {
  const _Marco({
    required this.compacto,
    required this.titulo,
    required this.pasos,
    required this.cuerpo,
    required this.pie,
    required this.onCerrar,
    this.subtitulo,
  });

  final bool compacto;
  final String titulo;
  final String? subtitulo;
  final Widget pasos;
  final Widget cuerpo;
  final List<Widget> pie;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cabecera = Padding(
      padding: EdgeInsets.fromLTRB(Esp.l, compacto ? Esp.s : Esp.l, Esp.s, Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
                      ),
                    ),
                    if (subtitulo != null)
                      Text(subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.apagado()),
                  ],
                ),
              ),
              IconButton(tooltip: 'Cerrar', onPressed: onCerrar, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: Esp.m),
          Padding(padding: const EdgeInsets.only(right: Esp.s), child: pasos),
        ],
      ),
    );
    final piePagina = Padding(
      padding: const EdgeInsets.all(Esp.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: pie.first),
          for (final w in pie.skip(1)) ...[const SizedBox(width: Esp.s), Flexible(child: w)],
        ],
      ),
    );
    final columna = Column(
      children: [
        cabecera,
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(child: cuerpo),
        Divider(height: 1, color: cs.outlineVariant),
        SafeArea(top: false, child: piePagina),
      ],
    );
    if (compacto) return Scaffold(body: SafeArea(bottom: false, child: columna));
    final t = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(Esp.xl),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: math.min(1000, t.width - 48), height: math.min(760, t.height - 48), child: columna),
    );
  }
}

class _Desplazable extends StatelessWidget {
  const _Desplazable({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(Esp.l),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

class _Titular extends StatelessWidget {
  const _Titular({required this.titulo, required this.detalle});

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo)),
      ),
      const SizedBox(height: Esp.xs),
      Text(
        detalle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

/// Los avisos de formato: los tres primeros a la vista y el resto plegado.
class _Avisos extends StatefulWidget {
  const _Avisos({required this.avisos});

  final List<String> avisos;

  @override
  State<_Avisos> createState() => _AvisosState();
}

class _AvisosState extends State<_Avisos> {
  bool _todos = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.avisos;
    final visibles = _todos ? a : a.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in visibles) NotaDelDato(texto: t, tono: TonoNota.aviso),
        if (a.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _todos = !_todos),
              child: Text(_todos ? 'Ver menos' : 'Ver los ${a.length} avisos'),
            ),
          ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.rotulo, required this.marca});

  final int valor;
  final String rotulo;
  final MarcaBurbuja marca;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BurbujaHoja(texto: '$valor', tamanio: 52, marca: marca),
      const SizedBox(width: Esp.m),
      Flexible(child: Text(rotulo, style: Theme.of(context).textTheme.titleSmall)),
    ],
  );
}

/// El final: lo que dijo el SP, tal cual, con el número de insertadas.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.resultado, required this.enviadas});

  final TcpeResultadoImportacionEntity resultado;
  final int enviadas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = resultado.insertadas;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: EntradaSuave(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BurbujaHoja(texto: '$n', tamanio: 88, marca: n > 0 ? MarcaBurbuja.marcada : MarcaBurbuja.neutra),
                const SizedBox(height: Esp.l),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    n == 0
                        ? 'No se importó ninguna pregunta'
                        : (n == 1 ? '1 pregunta nueva en el banco' : '$n preguntas nuevas en el banco'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
                  ),
                ),
                if ((resultado.mensaje ?? '').isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  Text(
                    resultado.mensaje!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: Esp.s),
                Text('De $enviadas filas enviadas.', style: context.apagado()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
