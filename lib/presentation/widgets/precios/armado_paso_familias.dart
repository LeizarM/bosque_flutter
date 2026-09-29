/// Paso 2 del asistente, para una propuesta por familias: elegir la familia y
/// cargarle el costo. Reemplaza a `dlgProd`.
///
/// Se carga de a una (editor, donde también se cambian los porcentajes) o en lote
/// (ver `armado_lote_familias.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/armado_propuesta_provider.dart';
import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cabeza_y_lista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_editor_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_lote_familias.dart';
import 'package:bosque_flutter/presentation/widgets/precios/articulos_de_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_dialogos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';

/// Solo las activas: el servidor rechaza repreciar una familia inactiva.
const FiltroFamilias _soloActivas = FiltroFamilias(estado: 1);

/// Una fila de la lista: la familia del catalogo y, si ya esta cargada, lo
/// que tiene en la propuesta.
@immutable
class _FilaFamilia {
  const _FilaFamilia({required this.codigo, this.familia, this.armada});

  final int codigo;

  /// Null cuando la familia esta en la propuesta pero ya no esta activa.
  final FamiliaVista? familia;

  final FamiliaArmadaEntity? armada;

  bool get enPropuesta => armada != null;

  bool get activa => familia != null;

  String get descripcion =>
      familia?.descripcion ?? 'Ya no figura entre las familias activas';

  String get proveedor => familia?.proveedorSap ?? '';

  String get grupo => familia?.grupoFamiliaSap ?? '';

  String get textoBuscable => familia?.textoBuscable ?? '$codigo'.toLowerCase();

  double? get costoActual =>
      familia == null || familia!.sinCosto ? null : familia!.costoTM;

  double? get costoPropuesto => armada?.costoSug;

  /// Cuanto se mueve un costo contra el vigente, en porcentaje. Null si falta
  /// alguno de los dos: sin base no hay variacion.
  double? variacionDe(double? costo) {
    final actual = costoActual;
    if (actual == null || costo == null || actual <= 0) return null;
    return (costo - actual) / actual * 100;
  }

  double? get variacionCosto => variacionDe(costoPropuesto);
}

/// Que familias se ven.
enum _Vista {
  todas('Todas'),
  cargadas('En la propuesta'),
  sinCargar('Sin cargar');

  const _Vista(this.etiqueta);

  final String etiqueta;

  bool deja(_FilaFamilia f) => switch (this) {
    _Vista.todas => true,
    _Vista.cargadas => f.enPropuesta,
    _Vista.sinCargar => !f.enPropuesta,
  };
}

class ArmadoPasoFamilias extends ConsumerStatefulWidget {
  const ArmadoPasoFamilias({super.key, required this.aire});

  final Aire aire;

  @override
  ConsumerState<ArmadoPasoFamilias> createState() => _ArmadoPasoFamiliasState();
}

class _ArmadoPasoFamiliasState extends ConsumerState<ArmadoPasoFamilias> {
  String _busqueda = '';
  String? _grupo;
  _Vista _vista = _Vista.todas;

  // Carga en lote
  bool _enLote = false;

  /// Solo las familias a las que se les escribio un costo nuevo.
  bool _soloEscritas = false;

  /// Lo escrito en la columna de costo, por familia. Nace con el costo ya
  /// guardado en la propuesta, si lo hay.
  final Map<int, TextEditingController> _costos = {};

  final Set<int> _marcadas = {};

  /// La ultima vista previa de cada familia. Vale mientras el costo escrito
  /// sea el mismo con el que se calculo (lo decide [estadoLote]).
  final Map<int, CalculoFamiliaEntity> _previas = {};

  /// Las filas del ultimo dibujo, por codigo: el oyente de cada campo necesita
  /// saber el costo guardado de su familia para decidir si lo escrito es nuevo.
  final Map<int, _FilaFamilia> _filasPorCodigo = {};

  /// Mientras calcula o guarda.
  ({int hechas, int total, bool guardando})? _avance;

  bool get _procesando => _avance != null;

  @override
  void dispose() {
    for (final c in _costos.values) {
      c.dispose();
    }
    super.dispose();
  }

  // De a una

  Future<void> _abrir(_FilaFamilia fila) async {
    final idAntes = ref.read(armadoProvider).idPropuesta;
    // En lote, el editor abre con el costo escrito en la tabla.
    final escrito = _enLote ? _costoDe(fila.codigo) : null;
    final guardada = await abrirEditorFamilia(
      context,
      codigoFamilia: fila.codigo,
      familia: fila.familia,
      costoInicial: escrito != null && escrito > 0 ? escrito : null,
    );
    if (guardada == null || !mounted) return;

    if (_enLote) {
      setState(() {
        _previas.remove(fila.codigo);
        final c = guardada.costo;
        if (c != null) _costos[fila.codigo]?.text = fmtMonto.format(c);
      });
    }

    final nacio = idAntes == null && guardada.idPropuesta != null;
    final detalle = _detalleLineas(guardada);
    avisar(
      context,
      nacio
          ? 'Se creó la propuesta N.º ${guardada.idPropuesta} con la familia '
              '${fila.codigo}$detalle.'
          : 'Familia ${fila.codigo} guardada en la propuesta$detalle.',
    );
  }

  String _detalleLineas(CalculoFamiliaEntity c) {
    final partes = [
      if (c.lineasNuevas > 0)
        '${c.lineasNuevas} ${c.lineasNuevas == 1 ? 'lista nueva' : 'listas nuevas'}',
      if (c.lineasActualizadas > 0)
        '${c.lineasActualizadas} '
            '${c.lineasActualizadas == 1 ? 'actualizada' : 'actualizadas'}',
      if (c.porcentajesCambiados > 0)
        '${c.porcentajesCambiados} '
            '${c.porcentajesCambiados == 1 ? 'porcentaje registrado' : 'porcentajes registrados'}',
    ];
    return partes.isEmpty ? '' : ' (${partes.join(', ')})';
  }

  void _verArticulos(_FilaFamilia f, List<ArticuloPrecioEntity>? articulos) {
    if (articulos == null) return;
    mostrarArticulosDeFamilia(
      context,
      codigoFamilia: f.codigo,
      descripcion: f.descripcion,
      articulos: articulos,
    );
  }

  // Lote

  TextEditingController _campo(_FilaFamilia f) => _costos.putIfAbsent(
    f.codigo,
    () =>
        TextEditingController(text: _textoGuardado(f))
          ..addListener(() => _alEscribir(f.codigo)),
  );

  static String _textoGuardado(_FilaFamilia f) =>
      f.costoPropuesto == null ? '' : fmtMonto.format(f.costoPropuesto!);

  /// **La casilla dice qué entra en el lote.** Escribir un costo nuevo en una fila
  /// la marca sola; desmarcarla descarta lo escrito ([_descartar]). Así "Guardar"
  /// guarda exactamente las marcadas.
  void _alEscribir(int codigo) {
    if (!mounted) return;
    final f = _filasPorCodigo[codigo];
    if (f != null && f.activa && !_marcadas.contains(codigo) && _escrita(f)) {
      _marcadas.add(codigo);
    }
    setState(() {});
  }

  /// Deja la familia como estaba: con su costo guardado, o sin costo, y sin
  /// calculo.
  void _descartar(_FilaFamilia f) {
    _previas.remove(f.codigo);
    final c = _costos[f.codigo];
    if (c != null && c.text != _textoGuardado(f)) c.text = _textoGuardado(f);
  }

  double? _costoDe(int codigo) =>
      importeDesdeTexto(_costos[codigo]?.text ?? '');

  EstadoLote _estado(_FilaFamilia f) => estadoLote(
    activa: f.activa,
    escrito: _costos[f.codigo]?.text ?? '',
    costoGuardado: f.costoPropuesto,
    previa: _previas[f.codigo],
  );

  /// Tiene un costo escrito que todavia no esta guardado.
  bool _escrita(_FilaFamilia f) => switch (_estado(f)) {
    EstadoLote.sinCalcular ||
    EstadoLote.lista ||
    EstadoLote.conProblema ||
    EstadoLote.invalido => true,
    _ => false,
  };

  CuentaLote _cuenta(List<_FilaFamilia> filas) {
    var sinCalcular = 0, listas = 0, conProblema = 0, invalidos = 0;
    var lineas = 0;
    for (final f in filas) {
      if (!_marcadas.contains(f.codigo)) continue;
      switch (_estado(f)) {
        case EstadoLote.sinCalcular:
          sinCalcular++;
        case EstadoLote.lista:
          listas++;
          lineas += _previas[f.codigo]?.lineasAEscribir ?? 0;
        case EstadoLote.conProblema:
          conProblema++;
        case EstadoLote.invalido:
          invalidos++;
        default:
          break;
      }
    }
    return CuentaLote(
      sinCalcular: sinCalcular,
      listas: listas,
      conProblema: conProblema,
      invalidos: invalidos,
      lineas: lineas,
    );
  }

  Future<void> _salirDelLote(List<_FilaFamilia> filas) async {
    final pendientes = filas.where(_escrita).length;
    if (pendientes > 0) {
      final salir = await confirmar(
        context,
        titulo: '¿Salir de la carga en lote?',
        detalle:
            pendientes == 1
                ? 'Hay 1 familia con un costo escrito que no se guardó. Se '
                    'descarta.'
                : 'Hay $pendientes familias con un costo escrito que no se '
                    'guardó. Se descartan.',
        textoConfirmar: 'Salir sin guardar',
        textoCancelar: 'Seguir en lote',
        destructiva: true,
      );
      if (!salir || !mounted) return;
    }
    final viejos = _costos.values.toList();
    setState(() {
      _costos.clear();
      _marcadas.clear();
      _previas.clear();
      _soloEscritas = false;
      _enLote = false;
    });
    // Despues del cuadro: los campos que los usaban ya no estan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in viejos) {
        c.dispose();
      }
    });
  }

  void _alternarMarca(_FilaFamilia f) {
    if (_marcadas.remove(f.codigo)) {
      _descartar(f);
    } else {
      _marcadas.add(f.codigo);
    }
    setState(() {});
  }

  void _marcarVisibles(List<_FilaFamilia> visibles, bool marcar) {
    for (final f in visibles) {
      if (!f.activa) continue;
      if (marcar) {
        _marcadas.add(f.codigo);
      } else if (_marcadas.remove(f.codigo)) {
        _descartar(f);
      }
    }
    setState(() {});
  }

  /// Pone el mismo costo a todas las marcadas y las calcula en el acto.
  Future<void> _ponerAMarcadas(List<_FilaFamilia> filas, double costo) async {
    final marcadas = [
      for (final f in filas)
        if (f.activa && _marcadas.contains(f.codigo)) f,
    ];
    if (marcadas.isEmpty) return;
    setState(() {
      for (final f in marcadas) {
        _campo(f).text = fmtMonto.format(costo);
      }
    });
    await _calcularLote(
      filas,
      antes:
          'USD ${fmtMonto.format(costo)} puesto a '
          '${marcadas.length == 1 ? '1 familia' : '${marcadas.length} familias'}. ',
    );
  }

  void _deshacerEscrito(List<_FilaFamilia> filas) => setState(() {
    for (final f in filas) {
      final c = _costos[f.codigo];
      if (c == null) continue;
      c.text =
          f.costoPropuesto == null ? '' : fmtMonto.format(f.costoPropuesto!);
    }
    _previas.clear();
  });

  Future<void> _calcularLote(
    List<_FilaFamilia> filas, {
    String antes = '',
  }) async {
    final pedidos = <int, double>{
      for (final f in filas)
        if (_marcadas.contains(f.codigo) && _estado(f).seCalcula)
          f.codigo: _costoDe(f.codigo)!,
    };
    if (pedidos.isEmpty) return;

    setState(
      () => _avance = (hechas: 0, total: pedidos.length, guardando: false),
    );
    final r = await ref
        .read(armadoProvider.notifier)
        .calcularFamilias(
          pedidos,
          alAvanzar: (hechas, total) {
            if (mounted) {
              setState(
                () =>
                    _avance = (hechas: hechas, total: total, guardando: false),
              );
            }
          },
        );
    if (!mounted) return;
    setState(() {
      _avance = null;
      if (r.salio) {
        for (final c in r.valor!) {
          _previas[c.codigoFamilia] = c;
        }
      }
    });
    if (!r.salio) {
      avisar(context, r.error!, esError: true);
      return;
    }
    final problemas = r.valor!.where((c) => !c.sePuedeGuardar).length;
    final n = r.valor!.length;
    avisar(
      context,
      antes +
          (problemas == 0
              ? (n == 1
                  ? 'Familia calculada: se puede guardar.'
                  : 'Se calcularon $n familias: todas se pueden guardar.')
              : 'Se calcularon $n familias; '
                  '${problemas == 1 ? '1 tiene problemas' : '$problemas tienen problemas'}. '
                  'Revíselas antes de guardar.'),
      esError: problemas > 0,
    );
  }

  Future<void> _guardarLote(List<_FilaFamilia> filas) async {
    final listas = [
      for (final f in filas)
        if (_marcadas.contains(f.codigo) && _estado(f) == EstadoLote.lista) f,
    ];
    final problemas = [
      for (final f in filas)
        if (_marcadas.contains(f.codigo) &&
            _estado(f) == EstadoLote.conProblema)
          f,
    ];
    if (listas.isEmpty) return;

    final n = listas.length;
    final lineas = listas.fold<int>(
      0,
      (s, f) => s + (_previas[f.codigo]?.lineasAEscribir ?? 0),
    );
    final existe = ref.read(armadoProvider).existe;
    final confirmado = await confirmar(
      context,
      titulo:
          n == 1
              ? 'Guardar 1 familia en la propuesta'
              : 'Guardar $n familias en la propuesta',
      detalle:
          'Se escriben $lineas precios por tonelada, con el costo que escribió '
          'para cada familia y los porcentajes de sus listas.'
          '${existe ? '' : ' La propuesta se crea con este lote.'}'
          '${problemas.isEmpty ? '' : '\n\nNo se ${problemas.length == 1 ? 'guarda 1 familia' : 'guardan ${problemas.length} familias'} con problemas: '
                  '${problemas.take(8).map((f) => f.codigo).join(', ')}'
                  '${problemas.length > 8 ? '…' : ''}. Ábralas en el editor para ver qué pasa.'}',
      textoConfirmar: n == 1 ? 'Guardar 1' : 'Guardar $n',
    );
    if (!confirmado || !mounted) return;

    final costos = {for (final f in listas) f.codigo: _costoDe(f.codigo)!};
    final idAntes = ref.read(armadoProvider).idPropuesta;
    setState(
      () => _avance = (hechas: 0, total: costos.length, guardando: true),
    );
    final r = await ref
        .read(armadoProvider.notifier)
        .guardarFamilias(
          costos,
          alAvanzar: (hechas, total) {
            if (mounted) {
              setState(
                () => _avance = (hechas: hechas, total: total, guardando: true),
              );
            }
          },
        );
    if (!mounted) return;
    setState(() {
      _avance = null;
      // Con un corte a mitad de camino no se sabe cuáles entraron: se borran todas las
      // vistas previas del lote y cada fila vuelve a decir lo que es (igual o sin calcular).
      for (final c in costos.keys) {
        _previas.remove(c);
      }
      if (r.salio) _marcadas.removeAll(costos.keys);
    });
    if (!r.salio) {
      avisar(context, r.error!, esError: true);
      return;
    }
    final v = r.valor!;
    final nacio = idAntes == null && v.idPropuesta > BigInt.zero;
    final familias = v.familiasRecalculadas;
    avisar(
      context,
      '${nacio ? 'Se creó la propuesta N.º ${v.idPropuesta} con' : 'Se guardaron en la propuesta'} '
      '${familias == 1 ? '1 familia' : '$familias familias'} '
      '(${v.lineasEscritas} ${v.lineasEscritas == 1 ? 'precio' : 'precios'}).',
    );
  }

  // Dibujo

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(armadoProvider);
    final familias = ref.watch(familiasProvider(_soloActivas));
    final armadas =
        estado.existe
            ? ref.watch(familiasArmadasProvider(estado.idPropuesta!))
            : const AsyncValue<List<FamiliaArmadaEntity>>.data([]);

    final chico = widget.aire.esChico;
    final margen = chico ? Esp.m : Esp.xl;

    return familias.when(
      loading: () => const EsqueletoLista(altoFila: 64),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar: () => ref.invalidate(familiasProvider(_soloActivas)),
          ),
      data: (crudas) {
        final porCodigo = <int, FamiliaArmadaEntity>{
          for (final a in armadas.valueOrNull ?? const <FamiliaArmadaEntity>[])
            a.codigoFamilia: a,
        };
        final catalogo =
            crudas.map(FamiliaVista.deMapa).toList()
              ..sort((a, b) => a.codigoFamilia.compareTo(b.codigoFamilia));

        final filas = <_FilaFamilia>[
          for (final f in catalogo)
            _FilaFamilia(
              codigo: f.codigoFamilia,
              familia: f,
              armada: porCodigo[f.codigoFamilia],
            ),
          // Las que estan en la propuesta pero ya no son activas tambien se
          // muestran: al aprobar se aplican igual.
          for (final a in porCodigo.values)
            if (!catalogo.any((f) => f.codigoFamilia == a.codigoFamilia))
              _FilaFamilia(codigo: a.codigoFamilia, armada: a),
        ];
        _filasPorCodigo
          ..clear()
          ..addEntries(filas.map((f) => MapEntry(f.codigo, f)));

        // Los articulos de todas las familias en una sola lectura: el
        // procedimiento recibe la lista de codigos entera.
        final asyncArticulos = ref.watch(
          articulosPorFamiliasProvider(
            ClaveFamilias([for (final f in catalogo) f.codigoFamilia]),
          ),
        );
        final articulos = asyncArticulos.whenData(articulosPorFamilia);
        List<ArticuloPrecioEntity>? articulosDe(int codigo) {
          final mapa = articulos.valueOrNull;
          if (mapa == null) return null;
          return mapa[codigo] ?? const <ArticuloPrecioEntity>[];
        }

        final grupos =
            {
                for (final f in filas)
                  if (f.grupo.trim().isNotEmpty) f.grupo.trim(),
              }.toList()
              ..sort();

        // En lote hay que esperar lo que ya tiene cargado la propuesta: los
        // campos nacen con el costo guardado.
        final enLote = _enLote;
        final esperandoPropuesta =
            enLote && armadas.isLoading && armadas.valueOrNull == null;

        // El filtro de estado no cuenta para los numeros de los chips: cada
        // chip dice cuantas veria con el resto de los filtros puestos.
        final texto = _busqueda.trim().toLowerCase();
        final filtradas = [
          for (final f in filas)
            if ((_grupo == null || f.grupo.trim() == _grupo) &&
                (texto.isEmpty || f.textoBuscable.contains(texto)))
              f,
        ];
        final visibles = [
          for (final f in filtradas)
            if (_vista.deja(f) && (!enLote || !_soloEscritas || _escrita(f))) f,
        ];
        int cuantas(_Vista v) => filtradas.where(v.deja).length;

        final cargadas = porCodigo.length;
        final listas = porCodigo.values.fold<int>(0, (s, a) => s + a.lineas);
        final variaciones = [
          for (final f in filas)
            if (f.variacionCosto != null) f.variacionCosto!,
        ];
        final variacionMedia =
            variaciones.isEmpty
                ? null
                : variaciones.reduce((a, b) => a + b) / variaciones.length;

        final cuenta = enLote ? _cuenta(filas) : null;
        final escritas = enLote ? filas.where(_escrita).length : 0;
        final marcables = visibles.where((f) => f.activa).toList();
        final marcadasVisibles =
            marcables.where((f) => _marcadas.contains(f.codigo)).length;

        final Widget cuerpo;
        if (esperandoPropuesta) {
          cuerpo = const EsqueletoLista(filas: 8, altoFila: 52);
        } else if (visibles.isEmpty) {
          cuerpo = _SinResultados(
            vista: _vista,
            total: filas.length,
            soloEscritas: enLote && _soloEscritas,
            onVerTodas:
                _vista == _Vista.todas && !(enLote && _soloEscritas)
                    ? null
                    : () => setState(() {
                      _vista = _Vista.todas;
                      _soloEscritas = false;
                    }),
          );
        } else if (widget.aire == Aire.amplio) {
          cuerpo = Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.xs, margen, Esp.m),
            child:
                enLote
                    ? _TablaLote(
                      filas: visibles,
                      campo: _campo,
                      estado: _estado,
                      previa: (c) => _previas[c],
                      costoDe: _costoDe,
                      marcadas: _marcadas,
                      habilitado: !_procesando,
                      articulosDe: articulosDe,
                      onMarcar: _alternarMarca,
                      onAbrir: _abrir,
                      onVerArticulos: _verArticulos,
                    )
                    : _Tabla(
                      filas: visibles,
                      articulosDe: articulosDe,
                      onAbrir: _abrir,
                      onVerArticulos: _verArticulos,
                    ),
          );
        } else {
          cuerpo =
              enLote
                  ? _TarjetasLote(
                    filas: visibles,
                    margen: margen,
                    campo: _campo,
                    estado: _estado,
                    previa: (c) => _previas[c],
                    costoDe: _costoDe,
                    marcadas: _marcadas,
                    habilitado: !_procesando,
                    articulosDe: articulosDe,
                    onMarcar: _alternarMarca,
                    onAbrir: _abrir,
                    onVerArticulos: _verArticulos,
                  )
                  : _Tarjetas(
                    filas: visibles,
                    margen: margen,
                    articulosDe: articulosDe,
                    onAbrir: _abrir,
                    onVerArticulos: _verArticulos,
                  );
        }

        // Con el teclado abierto en teléfono (buscador, costo del lote) los encabezados no
        // dejan lugar a la lista: CabezaYLista los acota.
        return CabezaYLista(
          cabeza: [
            // En el telefono, en lote, las cifras ceden su lugar a la tabla.
            if (!(chico && enLote))
              Padding(
                padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, 0),
                child:
                    estado.existe
                        ? _Tablero(
                          compacto: chico,
                          cargadas: cargadas,
                          activas: catalogo.length,
                          listas: listas,
                          variacionMedia: variacionMedia,
                          conVariacion: variaciones.length,
                          cargando: armadas.isLoading,
                        )
                        : _ComoSeArma(compacto: chico),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.s),
              child: _BarraModo(
                enLote: enLote,
                compacto: chico,
                habilitado: !_procesando,
                onEntrar: () => setState(() => _enLote = true),
                onSalir: () => _salirDelLote(filas),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.s),
              child: FiltrosPropuesta(
                compacto: chico,
                resumen: [
                  if (_busqueda.trim().isNotEmpty) '"${_busqueda.trim()}"',
                  if (_grupo != null) _grupo!,
                  if (_vista != _Vista.todas) _vista.etiqueta,
                ].join(' · '),
                hijos: [
                  BuscadorPropuesta(
                    texto: _busqueda,
                    pista: 'Código, grupo, proveedor, tipo o color',
                    ancho: chico ? null : 320,
                    alCambiar: (t) => setState(() => _busqueda = t),
                  ),
                  SizedBox(
                    width: chico ? double.infinity : 240,
                    child: DropdownButtonFormField<String?>(
                      value: _grupo,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Grupo de familia SAP',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        for (final g in grupos)
                          DropdownMenuItem<String?>(
                            value: g,
                            child: Text(g, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (g) => setState(() => _grupo = g),
                    ),
                  ),
                  // Sin propuesta todas estan sin cargar: los chips no
                  // separarian nada.
                  if (estado.existe)
                    Wrap(
                      spacing: Esp.s,
                      runSpacing: Esp.xs,
                      children: [
                        for (final v in _Vista.values)
                          ChoiceChip(
                            label: Text('${v.etiqueta} (${cuantas(v)})'),
                            selected: _vista == v,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _vista = v),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (enLote)
              Padding(
                padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.xs),
                child: _HerramientasLote(
                  compacto: chico,
                  habilitado: !_procesando,
                  marcadas: _marcadas.length,
                  marcables: marcables.length,
                  marcadasVisibles: marcadasVisibles,
                  escritas: escritas,
                  soloEscritas: _soloEscritas,
                  onMarcarVisibles: (m) => _marcarVisibles(marcables, m),
                  onPoner: (costo) => _ponerAMarcadas(filas, costo),
                  onDeshacer: () => _deshacerEscrito(filas),
                  onSoloEscritas: (v) => setState(() => _soloEscritas = v),
                ),
              ),
          ],
          lista: cuerpo,
          pie:
              enLote && cuenta != null
                  ? BarraLote(
                    cuenta: cuenta,
                    margen: margen,
                    compacto: chico,
                    avance: _avance,
                    onCalcular:
                        _procesando ||
                                cuenta.aCalcular == 0 ||
                                cuenta.invalidos > 0
                            ? null
                            : () => _calcularLote(filas),
                    onGuardar:
                        _procesando ||
                                cuenta.listas == 0 ||
                                cuenta.sinCalcular > 0 ||
                                cuenta.invalidos > 0
                            ? null
                            : () => _guardarLote(filas),
                  )
                  : null,
        );
      },
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({
    required this.vista,
    required this.total,
    required this.soloEscritas,
    required this.onVerTodas,
  });

  final _Vista vista;
  final int total;
  final bool soloEscritas;
  final VoidCallback? onVerTodas;

  @override
  Widget build(BuildContext context) {
    final (titulo, detalle) =
        soloEscritas
            ? (
              'Todavía no escribió ningún costo nuevo',
              'Escriba el costo en la columna Propuesto, o marque familias y '
                  'use «Aplicar a las marcadas».',
            )
            : switch (vista) {
              _Vista.cargadas => (
                'Ninguna familia de la propuesta coincide',
                'Pruebe con otro texto, quite el filtro de grupo o vea todas.',
              ),
              _Vista.sinCargar => (
                'No quedan familias sin cargar que coincidan',
                'Pruebe con otro texto, quite el filtro de grupo o vea todas.',
              ),
              _Vista.todas => (
                'Ninguna familia coincide',
                'Hay $total familias activas. Pruebe con otro texto o quite el '
                    'filtro de grupo.',
              ),
            };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: MensajeVacio(
            icono: Icons.search_off,
            titulo: titulo,
            detalle: detalle,
          ),
        ),
        if (onVerTodas != null)
          TextButton(
            onPressed: onVerTodas,
            child: const Text('Ver todas las familias'),
          ),
      ],
    );
  }
}

// Resumen y modo

/// Antes de la primera familia no hay nada que contar: se dice como se arma.
class _ComoSeArma extends StatelessWidget {
  const _ComoSeArma({required this.compacto});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const pasos = [
      (
        'Elija una familia',
        'De a una, o varias a la vez con «Cargar en lote».',
      ),
      (
        'Escriba el costo',
        'Y, si hace falta, ajuste el % de utilidad de cada lista.',
      ),
      ('Guarde', 'La propuesta se crea con la primera familia.'),
    ];
    final matices = [matizAzul, matizVioleta, matizVerde];

    Widget paso(int i) {
      final (titulo, detalle) = pasos[i];
      final t = tonosDeMatiz(matices[i], cs);
      final numero = Container(
        width: compacto ? 22 : 28,
        height: compacto ? 22 : 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: t.icono, shape: BoxShape.circle),
        child: Text(
          '${i + 1}',
          style: tt.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: Peso.dato,
          ),
        ),
      );
      if (compacto) {
        return Padding(
          padding: const EdgeInsets.only(top: Esp.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              numero,
              const SizedBox(width: Esp.s),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$titulo. ',
                        style: const TextStyle(fontWeight: Peso.titulo),
                      ),
                      TextSpan(text: detalle),
                    ],
                  ),
                  style: tt.bodySmall,
                ),
              ),
            ],
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          numero,
          const SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
                ),
                Text(detalle, style: context.apagado()),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.06),
          cs.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (var i = 0; i < pasos.length; i++) paso(i)],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < pasos.length; i++) ...[
                    if (i > 0) const SizedBox(width: Esp.l),
                    Expanded(child: paso(i)),
                  ],
                ],
              ),
    );
  }
}

/// Cuanto va armado: es lo primero que se lee al volver al paso.
class _Tablero extends StatelessWidget {
  const _Tablero({
    required this.compacto,
    required this.cargadas,
    required this.activas,
    required this.listas,
    required this.variacionMedia,
    required this.conVariacion,
    required this.cargando,
  });

  final bool compacto;
  final int cargadas;
  final int activas;
  final int listas;
  final double? variacionMedia;

  /// De cuantas familias sale la variacion media.
  final int conVariacion;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = variacionMedia;
    final espera = cargando ? '…' : null;

    final cifras = [
      CifraResumen(
        compacto: compacto,
        matiz: matizAzul,
        icono: Icons.inventory_2_outlined,
        rotulo: compacto ? 'Familias' : 'Familias en la propuesta',
        valor: espera ?? '$cargadas',
        detalle: 'de $activas activas',
      ),
      CifraResumen(
        compacto: compacto,
        matiz: matizVioleta,
        icono: Icons.price_change_outlined,
        rotulo: compacto ? 'Listas' : 'Listas con precio propuesto',
        valor: espera ?? '$listas',
        detalle: compacto ? 'con precio' : 'entre todas las sucursales',
      ),
      CifraResumen(
        compacto: compacto,
        matiz: v == null ? cs.outline : colorVariacion(cs, v),
        icono: v == null ? Icons.trending_flat_rounded : iconoVariacion(v),
        rotulo: compacto ? 'Costo' : 'Costo propuesto vs. actual',
        valor: espera ?? (v == null ? '--' : variacionLegible(v)),
        colorValor: v == null ? null : colorVariacion(cs, v),
        detalle:
            v == null
                ? 'sin costos que comparar'
                : (compacto
                    ? 'en promedio'
                    : 'promedio de $conVariacion '
                        '${conVariacion == 1 ? 'familia' : 'familias'}'),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cifras.length; i++) ...[
          if (i > 0) SizedBox(width: compacto ? Esp.s : Esp.m),
          Expanded(child: cifras[i]),
        ],
      ],
    );
  }
}

/// De a una o en lote: que se esta haciendo y el boton para cambiar.
class _BarraModo extends StatelessWidget {
  const _BarraModo({
    required this.enLote,
    required this.compacto,
    required this.habilitado,
    required this.onEntrar,
    required this.onSalir,
  });

  final bool enLote;
  final bool compacto;
  final bool habilitado;
  final VoidCallback onEntrar;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final texto =
        enLote
            ? (compacto
                ? 'Marque familias, escriba el costo y toque Poner. Después, '
                    'Guardar.'
                : 'Carga en lote: marque las familias, escriba el costo '
                    'propuesto y toque «Poner a las marcadas»; se calculan '
                    'solas. También puede escribirlo fila por fila y tocar '
                    'Calcular. Se guardan solo las marcadas: desmarcar una '
                    'descarta su costo. Cada familia se calcula con sus listas '
                    'y sus porcentajes.')
            : (compacto
                ? 'Toque una familia, o cargue varias a la vez.'
                : 'Toque una familia para cargarla de a una (ahí también '
                    'cambia el % de utilidad), o cargue varias a la vez.');

    final boton =
        enLote
            ? OutlinedButton.icon(
              onPressed: habilitado ? onSalir : null,
              icon: const Icon(Icons.close, size: 18),
              label: Text(compacto ? 'Salir' : 'Salir del lote'),
            )
            : FilledButton.tonalIcon(
              onPressed: habilitado ? onEntrar : null,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: const Text('Cargar en lote'),
            );

    final fila = Row(
      children: [
        Icon(
          enLote ? Icons.playlist_add_check_rounded : Icons.touch_app_outlined,
          size: 18,
          color: enLote ? cs.tertiary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: Esp.s),
        Expanded(child: Text(texto, style: context.apagado())),
        const SizedBox(width: Esp.s),
        boton,
      ],
    );

    if (!enLote) return fila;
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.xs, Esp.xs, Esp.xs),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.tertiary.withValues(alpha: 0.08),
          cs.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.35)),
      ),
      child: fila,
    );
  }
}

/// Las herramientas del lote: marcar, poner un costo a las marcadas y
/// deshacer.
class _HerramientasLote extends StatelessWidget {
  const _HerramientasLote({
    required this.compacto,
    required this.habilitado,
    required this.marcadas,
    required this.marcables,
    required this.marcadasVisibles,
    required this.escritas,
    required this.soloEscritas,
    required this.onMarcarVisibles,
    required this.onPoner,
    required this.onDeshacer,
    required this.onSoloEscritas,
  });

  final bool compacto;
  final bool habilitado;
  final int marcadas;
  final int marcables;
  final int marcadasVisibles;
  final int escritas;
  final bool soloEscritas;
  final ValueChanged<bool> onMarcarVisibles;
  final ValueChanged<double> onPoner;
  final VoidCallback onDeshacer;
  final ValueChanged<bool> onSoloEscritas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool? todas =
        marcadasVisibles == 0
            ? false
            : (marcadasVisibles == marcables ? true : null);

    final alternar =
        !habilitado || marcables == 0
            ? null
            : () => onMarcarVisibles(todas != true);
    // El rotulo tambien marca: la casilla sola es un blanco chico.
    final marcar = InkWell(
      onTap: alternar,
      borderRadius: BorderRadius.circular(Esquina.chica),
      child: Padding(
        padding: const EdgeInsets.only(right: Esp.s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: todas,
              tristate: true,
              onChanged: alternar == null ? null : (_) => alternar(),
            ),
            Text(
              compacto
                  ? (marcadas == 0 ? 'Marcar todas' : '$marcadas marcadas')
                  : 'Marcar las visibles ($marcables)',
            ),
          ],
        ),
      ),
    );

    final costo = CostoParaMarcadas(
      marcadas: marcadas,
      habilitado: habilitado,
      compacto: compacto,
      onPoner: onPoner,
    );

    final contenido =
        compacto
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    marcar,
                    const Spacer(),
                    PopupMenuButton<VoidCallback>(
                      tooltip: 'Más acciones del lote',
                      enabled: habilitado,
                      onSelected: (accion) => accion(),
                      itemBuilder:
                          (_) => [
                            PopupMenuItem(
                              value: () => onSoloEscritas(!soloEscritas),
                              child: ListTile(
                                leading: Icon(
                                  soloEscritas
                                      ? Icons.filter_alt_off_outlined
                                      : Icons.filter_alt_outlined,
                                ),
                                title: Text(
                                  soloEscritas
                                      ? 'Ver todas'
                                      : 'Ver solo las escritas ($escritas)',
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: onDeshacer,
                              child: const ListTile(
                                leading: Icon(Icons.undo_rounded),
                                title: Text('Deshacer lo escrito'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: Esp.xs),
                costo,
              ],
            )
            : Wrap(
              spacing: Esp.m,
              runSpacing: Esp.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                marcar,
                costo,
                FilterChip(
                  label: Text('Solo las escritas ($escritas)'),
                  selected: soloEscritas,
                  onSelected: habilitado ? onSoloEscritas : null,
                ),
                TextButton.icon(
                  onPressed: habilitado && escritas > 0 ? onDeshacer : null,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Deshacer lo escrito'),
                ),
              ],
            );

    // Un recuadro propio: es la herramienta principal del lote y tiene que
    // verse como tal, no como un boton mas de la fila de filtros.
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.xs, Esp.s, Esp.m, Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: contenido,
    );
  }
}

// Celdas

/// "Cargar precios" en el tono principal y "Editar" en el ambar de editar de
/// las propuestas: el mismo color hace lo mismo en todo el modulo.
class _BotonFamilia extends StatelessWidget {
  const _BotonFamilia({required this.fila, required this.onPressed});

  final _FilaFamilia fila;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!fila.enPropuesta) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text('Cargar precios'),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    final t = AccionDePropuesta.editar.tonos(cs);
    // El ambar puro sobre su propio fondo claro no se lee como texto: en claro
    // se oscurece; en oscuro [tonosDeMatiz] ya lo aclaro.
    final tinta =
        cs.brightness == Brightness.dark
            ? t.icono
            : Color.lerp(t.icono, Colors.black, 0.4)!;
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Editar'),
      style: FilledButton.styleFrom(
        backgroundColor: t.fondo,
        foregroundColor: tinta,
        side: BorderSide(color: t.icono.withValues(alpha: 0.45)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// El codigo con un circulo que dice si la familia ya esta en la propuesta.
class _CeldaCodigo extends StatelessWidget {
  const _CeldaCodigo({required this.fila});

  final _FilaFamilia fila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final verde = tonosDeMatiz(matizVerde, cs).icono;

    return Tooltip(
      message: fila.enPropuesta ? 'Ya está en la propuesta' : 'Sin cargar',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fila.enPropuesta
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: fila.enPropuesta ? verde : cs.outlineVariant,
          ),
          const SizedBox(width: Esp.s),
          celdaNumero(context, '${fila.codigo}', fuerte: true),
        ],
      ),
    );
  }
}

/// La descripcion y, debajo, el proveedor: dos datos en un renglon de 52 px
/// en lugar de dos columnas.
class _CeldaFamilia extends StatelessWidget {
  const _CeldaFamilia({required this.fila});

  final _FilaFamilia fila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fila.descripcion,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(
            fontWeight: Peso.titulo,
            color: fila.familia == null ? cs.error : cs.onSurface,
          ),
        ),
        if (fila.proveedor.trim().isNotEmpty)
          Text(
            fila.proveedor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

// De a una

class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.filas,
    required this.articulosDe,
    required this.onAbrir,
    required this.onVerArticulos,
  });

  final List<_FilaFamilia> filas;
  final List<ArticuloPrecioEntity>? Function(int codigo) articulosDe;
  final ValueChanged<_FilaFamilia> onAbrir;
  final void Function(_FilaFamilia, List<ArticuloPrecioEntity>?) onVerArticulos;

  @override
  Widget build(BuildContext context) {
    // 1.072 px: el proveedor va debajo de la familia y no en una columna.
    return TablaPropuesta<_FilaFamilia>(
      filas: filas,
      alTocarFila: onAbrir,
      columnas: [
        ColumnaPropuesta(
          'Código',
          96,
          (c, f) => _CeldaCodigo(fila: f),
          alinear: Alignment.centerLeft,
        ),
        ColumnaPropuesta(
          'Familia y proveedor',
          304,
          (c, f) => _CeldaFamilia(fila: f),
          alinear: Alignment.centerLeft,
        ),
        ColumnaPropuesta(
          'Artículos',
          124,
          (c, f) => BotonArticulos(
            articulos: articulosDe(f.codigo),
            onVer: () => onVerArticulos(f, articulosDe(f.codigo)),
          ),
          alinear: Alignment.centerLeft,
          ayuda:
              'Los artículos del catálogo que cambian de precio con la '
              'familia. Tóquelo para verlos.',
        ),
        ColumnaPropuesta(
          'Actual',
          108,
          (c, f) => celdaNumero(
            c,
            f.costoActual == null ? '--' : fmtMonto.format(f.costoActual!),
          ),
          banda: 'Costo por tonelada (USD)',
          ayuda: 'Costo vigente de la familia.',
        ),
        ColumnaPropuesta(
          'Propuesto',
          116,
          (c, f) => celdaNumero(
            c,
            f.costoPropuesto == null
                ? '--'
                : fmtMonto.format(f.costoPropuesto!),
            fuerte: true,
          ),
          banda: 'Costo por tonelada (USD)',
          ayuda: 'El costo cargado en esta propuesta.',
        ),
        ColumnaPropuesta(
          'Variación',
          100,
          (c, f) => CeldaVariacion(variacion: f.variacionCosto),
          banda: 'Costo por tonelada (USD)',
          ayuda: 'Cuánto sube o baja el costo propuesto contra el actual.',
        ),
        ColumnaPropuesta(
          'Listas',
          64,
          (c, f) =>
              celdaNumero(c, f.enPropuesta ? '${f.armada!.lineas}' : '--'),
          ayuda: 'Listas de precios con precio propuesto.',
        ),
        ColumnaPropuesta(
          '',
          160,
          (c, f) => _BotonFamilia(fila: f, onPressed: () => onAbrir(f)),
          alinear: Alignment.centerRight,
        ),
      ],
    );
  }
}

/// El telefono: tarjetas; la tarjeta entera abre la familia y el boton lo
/// dice.
class _Tarjetas extends StatelessWidget {
  const _Tarjetas({
    required this.filas,
    required this.margen,
    required this.articulosDe,
    required this.onAbrir,
    required this.onVerArticulos,
  });

  final List<_FilaFamilia> filas;
  final double margen;
  final List<ArticuloPrecioEntity>? Function(int codigo) articulosDe;
  final ValueChanged<_FilaFamilia> onAbrir;
  final void Function(_FilaFamilia, List<ArticuloPrecioEntity>?) onVerArticulos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(margen, Esp.xs, margen, Esp.xl),
      itemCount: filas.length,
      itemBuilder: (context, i) {
        final f = filas[i];
        final v = f.variacionCosto;
        final articulos = articulosDe(f.codigo);
        return TarjetaPropuesta(
          titulo: 'Familia ${f.codigo}',
          subtitulo: f.descripcion,
          etiqueta:
              f.enPropuesta
                  ? const Etiqueta(texto: 'Cargada', tono: TonoEtiqueta.exito)
                  : null,
          alTocar: () => onAbrir(f),
          destacado: Row(
            children: [
              Expanded(
                child: _Dato(
                  rotulo: 'Costo actual',
                  valor:
                      f.costoActual == null
                          ? '--'
                          : montoLegible(f.costoActual!, moneda: 'USD'),
                ),
              ),
              if (f.costoPropuesto != null) ...[
                Icon(Icons.arrow_forward, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: _Dato(
                    rotulo: 'Propuesto',
                    valor: montoLegible(f.costoPropuesto!, moneda: 'USD'),
                  ),
                ),
                if (v != null) CeldaVariacion(variacion: v),
              ],
            ],
          ),
          datos: [
            if (f.proveedor.isNotEmpty)
              FilaDeDato(
                rotulo: 'Proveedor',
                valor: f.proveedor,
                esNumero: false,
              ),
            if (f.enPropuesta)
              FilaDeDato(
                rotulo: 'Listas propuestas',
                valor: '${f.armada!.lineas}',
              ),
            Padding(
              padding: const EdgeInsets.only(top: Esp.xs),
              child: Row(
                children: [
                  BotonArticulos(
                    articulos: articulos,
                    onVer: () => onVerArticulos(f, articulos),
                  ),
                  const Spacer(),
                  _BotonFamilia(fila: f, onPressed: () => onAbrir(f)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(rotulo, style: context.apagado()),
      Text(valor, style: context.numero(fuerte: true)),
    ],
  );
}

// En lote

class _TablaLote extends StatelessWidget {
  const _TablaLote({
    required this.filas,
    required this.campo,
    required this.estado,
    required this.previa,
    required this.costoDe,
    required this.marcadas,
    required this.habilitado,
    required this.articulosDe,
    required this.onMarcar,
    required this.onAbrir,
    required this.onVerArticulos,
  });

  final List<_FilaFamilia> filas;
  final TextEditingController Function(_FilaFamilia) campo;
  final EstadoLote Function(_FilaFamilia) estado;
  final CalculoFamiliaEntity? Function(int codigo) previa;
  final double? Function(int codigo) costoDe;
  final Set<int> marcadas;
  final bool habilitado;
  final List<ArticuloPrecioEntity>? Function(int codigo) articulosDe;
  final ValueChanged<_FilaFamilia> onMarcar;
  final ValueChanged<_FilaFamilia> onAbrir;
  final void Function(_FilaFamilia, List<ArticuloPrecioEntity>?) onVerArticulos;

  @override
  Widget build(BuildContext context) {
    // Sin alTocarFila: tocar la fila no abre el editor, porque se toca para
    // escribir. El editor se abre con el boton del final.
    return TablaPropuesta<_FilaFamilia>(
      filas: filas,
      columnas: [
        ColumnaPropuesta(
          '',
          48,
          (c, f) => Checkbox(
            value: marcadas.contains(f.codigo),
            onChanged: !habilitado || !f.activa ? null : (_) => onMarcar(f),
          ),
          alinear: Alignment.center,
        ),
        ColumnaPropuesta(
          'Código',
          96,
          (c, f) => _CeldaCodigo(fila: f),
          alinear: Alignment.centerLeft,
        ),
        ColumnaPropuesta(
          'Familia y proveedor',
          260,
          (c, f) => _CeldaFamilia(fila: f),
          alinear: Alignment.centerLeft,
        ),
        ColumnaPropuesta(
          'Artículos',
          124,
          (c, f) => BotonArticulos(
            articulos: articulosDe(f.codigo),
            onVer: () => onVerArticulos(f, articulosDe(f.codigo)),
          ),
          alinear: Alignment.centerLeft,
        ),
        ColumnaPropuesta(
          'Actual',
          104,
          (c, f) => celdaNumero(
            c,
            f.costoActual == null ? '--' : fmtMonto.format(f.costoActual!),
          ),
          banda: 'Costo por tonelada (USD)',
        ),
        ColumnaPropuesta(
          'Propuesto',
          132,
          (c, f) {
            final e = estado(f);
            return CampoCostoLote(
              controlador: campo(f),
              habilitado: habilitado && f.activa,
              invalido: e == EstadoLote.invalido,
              cambiado:
                  e == EstadoLote.sinCalcular ||
                  e == EstadoLote.lista ||
                  e == EstadoLote.conProblema,
            );
          },
          banda: 'Costo por tonelada (USD)',
          ayuda:
              'Escriba el costo nuevo de la familia. Tab pasa a la '
              'siguiente.',
        ),
        ColumnaPropuesta(
          'Variación',
          96,
          (c, f) => CeldaVariacion(variacion: f.variacionDe(costoDe(f.codigo))),
          banda: 'Costo por tonelada (USD)',
        ),
        ColumnaPropuesta(
          'Al guardar',
          200,
          (c, f) => ResultadoLote(estado: estado(f), previa: previa(f.codigo)),
          alinear: Alignment.centerLeft,
          ayuda: 'Lo que pasaría con la familia, según el último cálculo.',
        ),
        ColumnaPropuesta(
          '',
          52,
          (c, f) => IconButton(
            tooltip:
                'Abrir en el editor: la grilla de listas y los porcentajes',
            onPressed: habilitado && f.activa ? () => onAbrir(f) : null,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
          ),
          alinear: Alignment.center,
        ),
      ],
    );
  }
}

class _TarjetasLote extends StatelessWidget {
  const _TarjetasLote({
    required this.filas,
    required this.margen,
    required this.campo,
    required this.estado,
    required this.previa,
    required this.costoDe,
    required this.marcadas,
    required this.habilitado,
    required this.articulosDe,
    required this.onMarcar,
    required this.onAbrir,
    required this.onVerArticulos,
  });

  final List<_FilaFamilia> filas;
  final double margen;
  final TextEditingController Function(_FilaFamilia) campo;
  final EstadoLote Function(_FilaFamilia) estado;
  final CalculoFamiliaEntity? Function(int codigo) previa;
  final double? Function(int codigo) costoDe;
  final Set<int> marcadas;
  final bool habilitado;
  final List<ArticuloPrecioEntity>? Function(int codigo) articulosDe;
  final ValueChanged<_FilaFamilia> onMarcar;
  final ValueChanged<_FilaFamilia> onAbrir;
  final void Function(_FilaFamilia, List<ArticuloPrecioEntity>?) onVerArticulos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(margen, Esp.xs, margen, Esp.l),
      itemCount: filas.length,
      itemBuilder: (context, i) {
        final f = filas[i];
        final e = estado(f);
        final articulos = articulosDe(f.codigo);
        final v = f.variacionDe(costoDe(f.codigo));
        final marcada = marcadas.contains(f.codigo);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: Esp.s),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Esquina.media),
            side: BorderSide(
              color: marcada ? cs.primary : cs.outlineVariant,
              width: marcada ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Esp.xs, Esp.xs, Esp.s, Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: marcada,
                      onChanged:
                          !habilitado || !f.activa ? null : (_) => onMarcar(f),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Esp.s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Familia ${f.codigo}',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: Peso.titulo,
                              ),
                            ),
                            Text(
                              f.descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color:
                                    f.activa ? cs.onSurfaceVariant : cs.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir en el editor',
                      onPressed:
                          habilitado && f.activa ? () => onAbrir(f) : null,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: Esp.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Aire para el rotulo flotante del campo de costo.
                      const SizedBox(height: Esp.m),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _Dato(
                              rotulo: 'Costo actual',
                              valor:
                                  f.costoActual == null
                                      ? '--'
                                      : montoLegible(
                                        f.costoActual!,
                                        moneda: 'USD',
                                      ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: CampoCostoLote(
                              controlador: campo(f),
                              habilitado: habilitado && f.activa,
                              invalido: e == EstadoLote.invalido,
                              cambiado:
                                  e == EstadoLote.sinCalcular ||
                                  e == EstadoLote.lista ||
                                  e == EstadoLote.conProblema,
                              etiqueta: 'Propuesto (USD)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Esp.s),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ResultadoLote(
                                estado: e,
                                previa: previa(f.codigo),
                                conDetalle: true,
                              ),
                            ),
                          ),
                          if (v != null) ...[
                            const SizedBox(width: Esp.s),
                            CeldaVariacion(variacion: v),
                          ],
                        ],
                      ),
                      const SizedBox(height: Esp.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BotonArticulos(
                          articulos: articulos,
                          onVer: () => onVerArticulos(f, articulos),
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
    );
  }
}
