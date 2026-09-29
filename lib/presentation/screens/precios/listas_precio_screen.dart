/// Las listas de precio (tpr_clasificacionPrecio), agrupadas por sucursal:
/// reemplaza a dlgClasi y dlgNClasi del sistema anterior.
///
/// Desactivar una lista pide confirmación: deja de repreciarse y desaparece de
/// Precios vigentes y Porcentajes. Dos listas activas con el mismo VPP (que
/// identifica la lista en todo el módulo) se mezclan en cualquier grilla: se avisa.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/clasificacion_precio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogo_lista_precio.dart';

// Datos de la pantalla

/// Una lista de precio con el nombre de su sucursal, que no es columna de
/// tpr_clasificacionPrecio (sale de un JOIN) y por eso no está en la entity.
@immutable
class _Fila {
  const _Fila({required this.lista, required this.sucursal});

  final ClasificacionPrecioEntity lista;
  final String sucursal;

  bool get activa => lista.esActiva;

  /// "Precio 3": como las nombraba el sistema anterior. En la base todas se
  /// llaman "Precio" y lo que las distingue es el numero.
  String get etiqueta {
    final nombre = lista.nombrePrecio.trim();
    if (nombre.isEmpty) return 'Lista ${lista.vpp}';
    return RegExp(r'\d').hasMatch(nombre) ? nombre : '$nombre ${lista.vpp}';
  }

  String get listaSap =>
      lista.tieneListaSap ? 'Lista SAP ${lista.listNum}' : 'Sin lista SAP';

  bool coincide(String texto) {
    if (texto.isEmpty) return true;
    final aguja = texto.toLowerCase();
    return etiqueta.toLowerCase().contains(aguja) ||
        sucursal.toLowerCase().contains(aguja) ||
        lista.vpp.toString() == aguja ||
        lista.listNum.toString() == aguja;
  }
}

/// Las listas de una sucursal, en orden de VPP.
@immutable
class _Grupo {
  const _Grupo({
    required this.codSucursal,
    required this.sucursal,
    required this.filas,
  });

  final BigInt codSucursal;
  final String sucursal;
  final List<_Fila> filas;

  int get activas => filas.where((f) => f.activa).length;

  /// El primer VPP activo ordena las sucursales como se trabajan: Central
  /// (1-4), Cochabamba (5-8), Santa Cruz (9-12). Una sucursal sin listas
  /// activas va al final.
  int get orden {
    final activos = [
      for (final f in filas)
        if (f.activa) f.lista.vpp,
    ];
    if (activos.isEmpty) return 100000 + filas.first.lista.vpp;
    return activos.reduce((a, b) => a < b ? a : b);
  }
}

/// Que listas se ven. Por defecto TODAS: las inactivas siguen teniendo precios
/// cargados y esconderlas de entrada haria creer que esos precios no existen.
enum _Ver {
  todas('Todas'),
  activas('Activas'),
  inactivas('Inactivas');

  const _Ver(this.etiqueta);
  final String etiqueta;
}

/// Las filas, emparejadas con el nombre de su sucursal. Usa dos lecturas porque
/// ninguna alcanza sola: el listado plano trae la entity completa (con el número
/// de lista SAP) pero sin sucursal, y el listado con sucursal al revés.
final _filasProvider = FutureProvider.autoDispose<List<_Fila>>((ref) async {
  final listas = await ref.watch(
    clasificacionesPrecioProvider(const FiltroClasificaciones()).future,
  );
  final conSucursal = await ref.watch(
    clasificacionesConSucursalProvider.future,
  );

  final nombres = <BigInt, String>{};
  for (final fila in conSucursal) {
    final cod = _aBigInt(fila['codSucursal']);
    if (cod == null) continue;
    nombres[cod] = (fila['nombreSucursal'] ?? '').toString().trim();
  }

  return [
    for (final lista in listas)
      _Fila(
        lista: lista,
        sucursal:
            (nombres[lista.codSucursal] ?? '').isEmpty
                // Sin nombre resuelto se muestra el codigo: es preferible a
                // una celda vacia que parece un error de carga.
                ? 'Sucursal ${lista.codSucursal}'
                : nombres[lista.codSucursal]!,
      ),
  ];
});

/// Sucursales que ofrece el combo del formulario: las que ya tienen listas (ver
/// [OpcionSucursal]).
final _sucursalesProvider = FutureProvider.autoDispose<List<OpcionSucursal>>((
  ref,
) async {
  final conSucursal = await ref.watch(
    clasificacionesConSucursalProvider.future,
  );

  final mapa = <BigInt, String>{};
  for (final fila in conSucursal) {
    final cod = _aBigInt(fila['codSucursal']);
    if (cod == null) continue;
    final nombre = (fila['nombreSucursal'] ?? '').toString().trim();
    mapa[cod] = nombre.isEmpty ? 'Sucursal $cod' : nombre;
  }

  return [
    for (final e in mapa.entries)
      OpcionSucursal(codSucursal: e.key, nombre: e.value),
  ]..sort((a, b) => a.nombre.compareTo(b.nombre));
});

/// Convierte lo que venga del DTO -entero, decimal o texto- a BigInt.
BigInt? _aBigInt(dynamic valor) {
  if (valor == null) return null;
  if (valor is BigInt) return valor;
  if (valor is num) return BigInt.from(valor.toInt());
  return BigInt.tryParse(valor.toString().trim());
}

List<_Grupo> _agrupar(List<_Fila> filas) {
  final porSucursal = <BigInt, List<_Fila>>{};
  for (final f in filas) {
    porSucursal.putIfAbsent(f.lista.codSucursal, () => []).add(f);
  }
  final grupos = [
    for (final e in porSucursal.entries)
      _Grupo(
        codSucursal: e.key,
        sucursal: e.value.first.sucursal,
        filas: e.value..sort((a, b) => a.lista.vpp.compareTo(b.lista.vpp)),
      ),
  ]..sort((a, b) => a.orden.compareTo(b.orden));
  return grupos;
}

/// VPP que usan dos o mas listas ACTIVAS, con las listas que lo comparten.
Map<int, List<_Fila>> _vppsRepetidos(List<_Fila> filas) {
  final porVpp = <int, List<_Fila>>{};
  for (final f in filas) {
    if (f.activa) porVpp.putIfAbsent(f.lista.vpp, () => []).add(f);
  }
  porVpp.removeWhere((_, v) => v.length < 2);
  return porVpp;
}

// Pantalla

class ListasPrecioScreen extends ConsumerStatefulWidget {
  const ListasPrecioScreen({super.key});

  @override
  ConsumerState<ListasPrecioScreen> createState() => _ListasPrecioScreenState();
}

class _ListasPrecioScreenState extends ConsumerState<ListasPrecioScreen> {
  final _buscadorCtrl = TextEditingController();
  String _busqueda = '';
  _Ver _ver = _Ver.todas;

  /// Las listas con una escritura en curso (activar, desactivar o eliminar): su
  /// interruptor queda ocupado y un segundo toque no manda otra. Es un conjunto:
  /// al terminar una no se debe liberar otra que sigue viajando.
  final Set<BigInt> _ocupadas = <BigInt>{};

  /// Avisa y devuelve true si la lista ya tiene una escritura en curso.
  bool _yaOcupada(_Fila fila) {
    if (!_ocupadas.contains(fila.lista.idClasificacion)) return false;
    avisar(
      context,
      '${fila.etiqueta} de ${fila.sucursal} se está actualizando.',
    );
    return true;
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
  }

  void _refrescar() {
    ref.invalidate(clasificacionesPrecioProvider);
    ref.invalidate(clasificacionesConSucursalProvider);
    ref.invalidate(vppsUsadosProvider);
  }

  // Acciones

  /// [compacto] viene del ancho del cajon, el mismo criterio del dibujo.
  void _abrirFormulario({
    required bool compacto,
    ClasificacionPrecioEntity? editar,
  }) {
    final sucursales =
        ref.read(_sucursalesProvider).valueOrNull ?? const <OpcionSucursal>[];
    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;

    if (compacto) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (_) => DialogoListaPrecio(
              sucursales: sucursales,
              audUsuario: audUsuario,
              editar: editar,
            ),
      );
      return;
    }

    // En escritorio, un dialogo centrado de ancho acotado: una hoja estirada
    // de punta a punta de un monitor de 1920 px es ilegible.
    showDialog<void>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DialogoListaPrecio(
                sucursales: sucursales,
                audUsuario: audUsuario,
                editar: editar,
                mostrarAsa: false,
              ),
            ),
          ),
    );
  }

  Future<void> _cambiarEstado(_Fila fila, bool activar) async {
    if (_yaOcupada(fila)) return;
    final seguir = await confirmar(
      context,
      titulo:
          activar
              ? 'Activar ${fila.etiqueta} de ${fila.sucursal}'
              : 'Desactivar ${fila.etiqueta} de ${fila.sucursal}',
      detalle:
          activar
              ? 'La lista vuelve a repreciarse y a aparecer en Precios vigentes '
                  'y en Porcentajes. Revise que las familias tengan su '
                  'porcentaje cargado para esta lista antes de armar una '
                  'propuesta.'
              : 'La lista deja de repreciarse: las propuestas nuevas ya no le '
                  'calculan precio, y sale de Precios vigentes y de '
                  'Porcentajes. Sus precios y porcentajes no se borran; se '
                  'puede volver a activar cuando haga falta.',
      textoConfirmar: activar ? 'Activar' : 'Desactivar',
      destructiva: !activar,
    );
    if (!seguir || !mounted || _yaOcupada(fila)) return;

    setState(() => _ocupadas.add(fila.lista.idClasificacion));
    try {
      // Rama aparte del registrar: solo escribe el estado, asi que no hay
      // forma de pisar sin querer el nombre ni el VPP.
      await ref
          .read(preciosRepositoryProvider)
          .cambiarEstadoClasificacionPrecio(
            idClasificacion: fila.lista.idClasificacion,
            estado: activar ? 1 : 0,
          );
      if (!mounted) return;
      _refrescar();
      avisar(
        context,
        activar
            ? '${fila.etiqueta} de ${fila.sucursal} activada.'
            : '${fila.etiqueta} de ${fila.sucursal} desactivada.',
      );
    } catch (e) {
      if (!mounted) return;
      avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      _ocupadas.remove(fila.lista.idClasificacion);
      if (mounted) setState(() {});
    }
  }

  Future<void> _eliminar(_Fila fila) async {
    if (_yaOcupada(fila)) return;
    final seguir = await confirmar(
      context,
      titulo: 'Eliminar ${fila.etiqueta} de ${fila.sucursal}',
      detalle:
          'La lista se borra del sistema. Si ya tiene precios o porcentajes '
          'cargados, el servidor va a rechazar la baja: en ese caso '
          'corresponde desactivarla.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!seguir || !mounted || _yaOcupada(fila)) return;

    setState(() => _ocupadas.add(fila.lista.idClasificacion));
    try {
      await ref
          .read(preciosRepositoryProvider)
          .eliminarClasificacionPrecio(fila.lista.idClasificacion);
      if (!mounted) return;
      _refrescar();
      avisar(context, '${fila.etiqueta} de ${fila.sucursal} eliminada.');
    } catch (e) {
      if (!mounted) return;
      avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      _ocupadas.remove(fila.lista.idClasificacion);
      if (mounted) setState(() {});
    }
  }

  // Dibujo

  @override
  Widget build(BuildContext context) {
    // Se observa aquí para que el combo del formulario ya esté resuelto al tocar
    // "Nueva lista".
    ref.watch(_sucursalesProvider);
    final asyncFilas = ref.watch(_filasProvider);

    return LayoutBuilder(
      builder: (context, cajon) {
        // El ancho del CAJON y no el de la ventana: adentro del dashboard el
        // menu lateral se come su parte y MediaQuery miente.
        final aire = Aire.de(cajon.maxWidth);
        final margen = aire.esChico ? Esp.m : Esp.xl;

        return Scaffold(
          floatingActionButton:
              aire.esChico
                  ? FloatingActionButton.extended(
                    onPressed: () => _abrirFormulario(compacto: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva lista'),
                  )
                  : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(
                aire: aire,
                filas: asyncFilas.valueOrNull,
                cargando: asyncFilas.isLoading,
                onNueva: () => _abrirFormulario(compacto: false),
                onRefrescar: _refrescar,
              ),
              _BarraFiltros(
                aire: aire,
                controlador: _buscadorCtrl,
                ver: _ver,
                onBuscar: (t) => setState(() => _busqueda = t.trim()),
                onVer: (v) => setState(() => _ver = v),
              ),
              Expanded(
                child: asyncFilas.when(
                  loading: () => const EsqueletoLista(altoFila: 120),
                  error:
                      (e, _) =>
                          MensajeError(error: e, onReintentar: _refrescar),
                  data: (filas) {
                    if (filas.isEmpty) {
                      return _SinListas(
                        onNueva: () => _abrirFormulario(compacto: aire.esChico),
                      );
                    }
                    return _cuerpo(filas, aire, margen);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cuerpo(List<_Fila> todas, Aire aire, double margen) {
    final repetidos = _vppsRepetidos(todas);
    final visibles = [
      for (final f in todas)
        if (f.coincide(_busqueda) &&
            switch (_ver) {
              _Ver.todas => true,
              _Ver.activas => f.activa,
              _Ver.inactivas => !f.activa,
            })
          f,
    ];
    final grupos = _agrupar(visibles);

    return LayoutBuilder(
      builder: (context, r) {
        // Tope de 1000 px de contenido: a 1900 px el nombre quedaba a medio metro
        // de su VPP y su estado. Se resuelve con el margen y no envolviendo la
        // lista, para que la rueda del mouse siga funcionando en los costados.
        final lateral =
            r.maxWidth - 2 * margen > _anchoMaximo
                ? (r.maxWidth - _anchoMaximo) / 2
                : margen;
        return _lista(grupos, repetidos, todas, aire, lateral);
      },
    );
  }

  static const double _anchoMaximo = 1000;

  Widget _lista(
    List<_Grupo> grupos,
    Map<int, List<_Fila>> repetidos,
    List<_Fila> todas,
    Aire aire,
    double margen,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        margen,
        Esp.s,
        margen,
        // En el telefono la ultima tarjeta tiene que poder pasar por encima
        // del boton flotante.
        aire.esChico ? 96 : Esp.xxl,
      ),
      children: [
        if (repetidos.isNotEmpty) ...[
          _AvisoRepetidos(repetidos: repetidos),
          const SizedBox(height: Esp.m),
        ],
        if (grupos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xxl),
            child: MensajeVacio(
              icono: Icons.search_off,
              titulo: 'Ninguna lista coincide',
              detalle:
                  'Hay ${todas.length} listas. Pruebe con otro texto o con '
                  '"${_Ver.todas.etiqueta}".',
            ),
          ),
        for (final g in grupos) ...[
          _BloqueSucursal(
            grupo: g,
            aire: aire,
            repetidos: repetidos.keys.toSet(),
            ocupadas: _ocupadas,
            onEditar:
                (f) =>
                    _abrirFormulario(compacto: aire.esChico, editar: f.lista),
            onEstado: _cambiarEstado,
            onEliminar: _eliminar,
          ),
          const SizedBox(height: Esp.m),
        ],
      ],
    );
  }
}

// Piezas

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.aire,
    required this.filas,
    required this.cargando,
    required this.onNueva,
    required this.onRefrescar,
  });

  final Aire aire;
  final List<_Fila>? filas;
  final bool cargando;
  final VoidCallback onNueva;
  final VoidCallback onRefrescar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final margen = aire.esChico ? Esp.m : Esp.xl;

    final f = filas;
    final String resumen;
    if (f == null) {
      resumen = 'Cada lista tiene un VPP y su enlace con la lista de SAP.';
    } else {
      final sucursales = {for (final x in f) x.lista.codSucursal}.length;
      final activas = f.where((x) => x.activa).length;
      resumen =
          '${f.length} listas en $sucursales '
          '${sucursales == 1 ? 'sucursal' : 'sucursales'} · $activas activas';
    }

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen - Esp.s, Esp.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Listas de precio',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: Peso.dato,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: Esp.xs),
                Text(resumen, style: context.apagado()),
              ],
            ),
          ),
          if (cargando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Esp.m),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: onRefrescar,
            icon: const Icon(Icons.refresh),
          ),
          if (!aire.esChico) ...[
            const SizedBox(width: Esp.s),
            FilledButton.icon(
              onPressed: onNueva,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva lista'),
            ),
            const SizedBox(width: Esp.s),
          ],
        ],
      ),
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.aire,
    required this.controlador,
    required this.ver,
    required this.onBuscar,
    required this.onVer,
  });

  final Aire aire;
  final TextEditingController controlador;
  final _Ver ver;
  final ValueChanged<String> onBuscar;
  final ValueChanged<_Ver> onVer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final margen = aire.esChico ? Esp.m : Esp.xl;

    final buscador = TextField(
      controller: controlador,
      onChanged: onBuscar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Sucursal, lista o VPP',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon:
            controlador.text.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controlador.clear();
                    onBuscar('');
                  },
                ),
      ),
    );

    final estados = SegmentedButton<_Ver>(
      showSelectedIcon: false,
      segments: [
        for (final v in _Ver.values)
          ButtonSegment<_Ver>(value: v, label: Text(v.etiqueta)),
      ],
      selected: {ver},
      onSelectionChanged: (s) => onVer(s.first),
    );

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
      child:
          aire.esChico
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [buscador, const SizedBox(height: Esp.s), estados],
              )
              : Row(
                children: [
                  SizedBox(width: 340, child: buscador),
                  const Spacer(),
                  estados,
                ],
              ),
    );
  }
}

/// Dos listas activas con el mismo VPP: se dice cuales y por que importa.
class _AvisoRepetidos extends StatelessWidget {
  const _AvisoRepetidos({required this.repetidos});

  final Map<int, List<_Fila>> repetidos;

  @override
  Widget build(BuildContext context) {
    final vpps = repetidos.keys.toList()..sort();
    final detalle = [
      for (final v in vpps)
        'VPP $v: ${repetidos[v]!.map((f) => f.sucursal).join(' y ')}',
    ].join('; ');

    return NotaDelDato(
      tono: TonoNota.aviso,
      texto:
          '${vpps.length == 1 ? 'Hay un VPP repetido' : 'Hay ${vpps.length} VPP repetidos'} '
          'entre listas activas ($detalle). El VPP identifica la lista en '
          'todo el módulo y las grillas ordenan por él: conviene dejar activa '
          'una sola lista por VPP.',
    );
  }
}

/// Una sucursal y sus listas.
class _BloqueSucursal extends StatelessWidget {
  const _BloqueSucursal({
    required this.grupo,
    required this.aire,
    required this.repetidos,
    required this.ocupadas,
    required this.onEditar,
    required this.onEstado,
    required this.onEliminar,
  });

  final _Grupo grupo;
  final Aire aire;
  final Set<int> repetidos;

  /// Las listas con una escritura en curso.
  final Set<BigInt> ocupadas;
  final ValueChanged<_Fila> onEditar;
  final void Function(_Fila fila, bool activar) onEstado;
  final ValueChanged<_Fila> onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inactivas = grupo.filas.length - grupo.activas;
    final ancho = !aire.esChico;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.m),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, size: 20, color: cs.primary),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    grupo.sucursal,
                    style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
                  ),
                ),
                Text(
                  grupo.activas == 0
                      ? 'Sin listas activas'
                      : '${grupo.activas} '
                          '${grupo.activas == 1 ? 'activa' : 'activas'}'
                          '${inactivas == 0 ? '' : ' · $inactivas ${inactivas == 1 ? 'inactiva' : 'inactivas'}'}',
                  style: context.apagado(),
                ),
              ],
            ),
          ),
          if (ancho) _CabeceraColumnas(amplio: aire == Aire.amplio),
          for (final (i, f) in grupo.filas.indexed) ...[
            if (i > 0 || !ancho) Divider(height: 1, color: cs.outlineVariant),
            _FilaLista(
              fila: f,
              aire: aire,
              repetido: f.activa && repetidos.contains(f.lista.vpp),
              ocupado: ocupadas.contains(f.lista.idClasificacion),
              onEditar: () => onEditar(f),
              onEstado: (v) => onEstado(f, v),
              onEliminar: () => onEliminar(f),
            ),
          ],
        ],
      ),
    );
  }
}

// Anchos de las columnas de escritorio. Fijos: la columna de estado y la de
// acciones tienen que quedar alineadas entre una sucursal y la siguiente.
const double _anchoVpp = 64;
const double _anchoSap = 150;
const double _anchoEstado = 170;
const double _anchoAcciones = 150;

class _CabeceraColumnas extends StatelessWidget {
  const _CabeceraColumnas({required this.amplio});

  final bool amplio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
      letterSpacing: 0.3,
    );

    return Container(
      color: cs.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s),
      child: Row(
        children: [
          SizedBox(width: _anchoVpp, child: Text('VPP', style: estilo)),
          Expanded(child: Text('Lista', style: estilo)),
          if (amplio)
            SizedBox(width: _anchoSap, child: Text('Lista SAP', style: estilo)),
          SizedBox(width: _anchoEstado, child: Text('Estado', style: estilo)),
          const SizedBox(width: _anchoAcciones),
        ],
      ),
    );
  }
}

class _FilaLista extends StatelessWidget {
  const _FilaLista({
    required this.fila,
    required this.aire,
    required this.repetido,
    required this.ocupado,
    required this.onEditar,
    required this.onEstado,
    required this.onEliminar,
  });

  final _Fila fila;
  final Aire aire;
  final bool repetido;
  final bool ocupado;
  final VoidCallback onEditar;
  final ValueChanged<bool> onEstado;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final activa = fila.activa;
    final amplio = aire == Aire.amplio;

    final vpp = _Vpp(vpp: fila.lista.vpp, activa: activa, repetido: repetido);

    final nombre = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          fila.etiqueta,
          style: tt.bodyMedium?.copyWith(
            fontWeight: activa ? Peso.titulo : Peso.normal,
            color: activa ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
        // Sin columna propia, la lista SAP baja a la segunda linea.
        if (!amplio)
          Text(
            fila.listaSap,
            style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
          ),
        if (repetido)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xs),
            child: Etiqueta(
              texto: 'VPP ${fila.lista.vpp} repetido',
              tono: TonoEtiqueta.aviso,
            ),
          ),
      ],
    );

    final interruptor = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ocupado)
          const SizedBox(
            width: 40,
            height: 24,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          Switch(value: activa, onChanged: onEstado),
        if (!aire.esChico) ...[
          const SizedBox(width: Esp.s),
          Text(
            activa ? 'Activa' : 'Inactiva',
            style: tt.bodySmall?.copyWith(
              color: activa ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final menu = PopupMenuButton<String>(
      tooltip: 'Más acciones',
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (opcion) {
        if (opcion == 'editar') onEditar();
        if (opcion == 'eliminar') onEliminar();
      },
      itemBuilder:
          (_) => [
            // En pantallas anchas "Editar" tiene su propio boton al lado.
            if (aire.esChico)
              const PopupMenuItem<String>(
                value: 'editar',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
            PopupMenuItem<String>(
              value: 'eliminar',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: cs.error),
                title: Text('Eliminar', style: TextStyle(color: cs.error)),
              ),
            ),
          ],
    );

    final Widget contenido;
    if (aire.esChico) {
      contenido = Padding(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.s, Esp.xs, Esp.s),
        child: Row(
          children: [
            vpp,
            const SizedBox(width: Esp.m),
            Expanded(child: nombre),
            interruptor,
            menu,
          ],
        ),
      );
    } else {
      contenido = Padding(
        padding: const EdgeInsets.fromLTRB(Esp.l, Esp.s, Esp.s, Esp.s),
        child: Row(
          children: [
            SizedBox(
              width: _anchoVpp,
              child: Align(alignment: Alignment.centerLeft, child: vpp),
            ),
            Expanded(child: nombre),
            if (amplio)
              SizedBox(
                width: _anchoSap,
                child: Text(
                  fila.lista.tieneListaSap ? '${fila.lista.listNum}' : '--',
                  style: context.numero(
                    color: activa ? null : cs.onSurfaceVariant,
                  ),
                ),
              ),
            SizedBox(width: _anchoEstado, child: interruptor),
            SizedBox(
              width: _anchoAcciones,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  menu,
                ],
              ),
            ),
          ],
        ),
      );
    }

    // La fila entera abre la edicion: en el telefono es el blanco mas grande
    // y en escritorio ahorra buscar el boton.
    return Material(
      color: activa ? Colors.transparent : cs.surfaceContainerLow,
      child: InkWell(onTap: onEditar, child: contenido),
    );
  }
}

/// El VPP, que es el numero por el que se nombra una lista: va adelante y en
/// una pastilla, no perdido en una columna.
class _Vpp extends StatelessWidget {
  const _Vpp({required this.vpp, required this.activa, required this.repetido});

  final int vpp;
  final bool activa;
  final bool repetido;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra) =
        repetido
            ? (cs.tertiaryContainer, cs.onTertiaryContainer)
            : activa
            ? (cs.primaryContainer, cs.onPrimaryContainer)
            : (cs.surfaceContainerHighest, cs.onSurfaceVariant);

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: Esp.xs),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VPP',
            style: TextStyle(fontSize: 9, letterSpacing: 0.6, color: letra),
          ),
          Text(
            '$vpp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
              color: letra,
            ),
          ),
        ],
      ),
    );
  }
}

class _SinListas extends StatelessWidget {
  const _SinListas({required this.onNueva});

  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Expanded(
        child: MensajeVacio(
          icono: Icons.sell_outlined,
          titulo: 'Todavía no hay listas de precio',
          detalle:
              'Cada lista tiene un VPP y su enlace con la lista de SAP. Sin '
              'listas no hay precios que repreciar.',
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: Esp.xxl),
        child: FilledButton.icon(
          onPressed: onNueva,
          icon: const Icon(Icons.add),
          label: const Text('Crear la primera lista'),
        ),
      ),
    ],
  );
}
