import 'package:bosque_flutter/core/state/articulo_almacen_provider.dart';
import 'package:bosque_flutter/core/state/articulo_ciudad_provider.dart';
import 'package:bosque_flutter/core/utils/busqueda_articulos.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/ciudad_venta_entity.dart';
import 'package:bosque_flutter/presentation/screens/ventas/ciudades_por_usuario_screen.dart';
import 'package:bosque_flutter/core/state/ventas_ciudades_provider.dart';
import 'package:bosque_flutter/presentation/widgets/shared/aviso.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class VentasArticulosView extends ConsumerStatefulWidget {
  /// Qué ciudades puede elegir el usuario (lo decide el backend).
  final CiudadesPermitidasEntity permitidas;

  const VentasArticulosView({super.key, required this.permitidas});

  @override
  ConsumerState<VentasArticulosView> createState() =>
      _VentasArticulosViewState();
}

/// Cada cuánto se vuelven a pedir precios y stock sin que el vendedor toque nada.
const _intervaloAutoRefresco = Duration(minutes: 5);

/// Cuánto tiempo queda marcado un artículo cuyo precio o stock cambió.
const _duracionResaltado = _intervaloAutoRefresco;

enum _TipoCambio { precioSube, precioBaja, stock }

class _CambioArticulo {
  final _TipoCambio tipo;
  final DateTime cuando;
  const _CambioArticulo(this.tipo, this.cuando);
}

class _VentasArticulosViewState extends ConsumerState<VentasArticulosView>
    with WidgetsBindingObserver {
  String _sortBy = 'datoArt';
  bool _sortAscending = true;
  int? _selectedFamilia;
  List<ArticulosxCiudadEntity> _articulosCache = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Ciudad elegida en el selector; 0 = "Todas".
  // Admin arranca en "Todas"; el resto, en su ciudad (codCiudadInicial ya
  // es la del login si la tiene permitida).
  late int _codCiudad =
      widget.permitidas.esAdmin && widget.permitidas.todas
          ? CiudadesPermitidasEntity.todasLasCiudades
          : widget.permitidas.codCiudadInicial;
  bool get _enTodas => _codCiudad == CiudadesPermitidasEntity.todasLasCiudades;

  Timer? _autoRefresco;

  // Búsqueda: el campo escribe sin redibujar la pantalla; el filtro se aplica
  // cuando se deja de teclear un momento.
  Timer? _esperaBusqueda;
  BusquedaArticulos _consulta = BusquedaArticulos('');

  // Índice por carga de datos: agrupado por código y con el texto ya
  // normalizado. Se rehace sólo cuando llega otra lista.
  List<ArticulosxCiudadEntity>? _fuenteIndice;
  Map<String, List<ArticulosxCiudadEntity>> _grupos = {};
  Map<String, String> _textoBuscable = {};

  void _indexar(List<ArticulosxCiudadEntity> articulos) {
    if (identical(articulos, _fuenteIndice)) return;
    final grupos = <String, List<ArticulosxCiudadEntity>>{};
    for (final a in articulos) {
      grupos.putIfAbsent(a.codArticulo, () => []).add(a);
    }
    _grupos = grupos;
    _textoBuscable = {
      for (final e in grupos.entries)
        e.key: BusquedaArticulos.normalizar(
          '${e.value.first.datoArt} ${e.key}',
        ),
    };
    _fuenteIndice = articulos;
  }

  void _alEscribir(String texto) {
    _esperaBusqueda?.cancel();
    _esperaBusqueda = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _consulta = BusquedaArticulos(texto);
      });
    });
  }

  void _limpiarBusqueda() {
    _esperaBusqueda?.cancel();
    _searchController.clear();
    setState(() {
      _consulta = BusquedaArticulos('');
    });
  }

  /// El texto con las coincidencias de la búsqueda resaltadas.
  TextSpan _resaltar(String texto) {
    final tramos = _consulta.tramos(texto);
    if (tramos.isEmpty) return TextSpan(text: texto);
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final marca = TextStyle(
      backgroundColor: Colors.amber.withValues(alpha: oscuro ? 0.45 : 0.55),
      fontWeight: FontWeight.w800,
    );
    final partes = <TextSpan>[];
    var desde = 0;
    for (final (ini, fin) in tramos) {
      if (ini > desde) partes.add(TextSpan(text: texto.substring(desde, ini)));
      partes.add(TextSpan(text: texto.substring(ini, fin), style: marca));
      desde = fin;
    }
    if (desde < texto.length) {
      partes.add(TextSpan(text: texto.substring(desde)));
    }
    return TextSpan(children: partes);
  }

  DateTime? _ultimaActualizacion;
  bool _refrescoManual = false;

  // Foto de la última carga para detectar qué cambió.
  Map<String, double> _preciosPrevios = {};
  Map<String, int> _stockPrevio = {};
  final Map<String, _CambioArticulo> _cambios = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Siempre datos frescos al entrar a la pantalla.
      _refrescar();
    });
    _iniciarAutoRefresco();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver a la app los precios pueden haber cambiado.
      _refrescar();
      _iniciarAutoRefresco();
    } else if (state == AppLifecycleState.paused) {
      _autoRefresco?.cancel();
    }
  }

  void _iniciarAutoRefresco() {
    _autoRefresco?.cancel();
    _autoRefresco = Timer.periodic(_intervaloAutoRefresco, (_) => _refrescar());
  }

  /// Vuelve a pedir precios y stock (también el stock por almacén).
  Future<void> _refrescar({bool manual = false}) async {
    if (!mounted) return;
    if (manual) {
      _refrescoManual = true;
      HapticFeedback.lightImpact();
      // Reinicia el contador del auto-refresco para no pedir dos veces seguidas.
      _iniciarAutoRefresco();
    }
    ref.read(articulosCiudadRefreshProvider.notifier).state++;
    try {
      await ref.read(articulosCiudadProvider(_codCiudad).future);
    } catch (_) {
      // El error ya se muestra en pantalla (banner / estado de error).
    }
  }

  /// Cambia la ciudad del catálogo. La foto anterior es de otra ciudad, así
  /// que se descarta: si no, todo saldría marcado como "cambió".
  void _cambiarCiudad(int codCiudad) {
    if (codCiudad == _codCiudad) return;
    setState(() {
      _codCiudad = codCiudad;
      _articulosCache = [];
      _preciosPrevios = {};
      _stockPrevio = {};
      _cambios.clear();
      _ultimaActualizacion = null;
    });
    // Datos frescos aunque esa ciudad ya se haya visto en esta sesión.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refrescar());
  }

  static String _clavePrecio(ArticulosxCiudadEntity a) =>
      '${a.codArticulo}|${a.codCiudad}|${a.db}|${a.listaPrecio}';

  void _procesarNuevosDatos(List<ArticulosxCiudadEntity> lista) {
    final ahora = DateTime.now();
    final precios = <String, double>{};
    final stock = <String, int>{};
    for (final a in lista) {
      precios[_clavePrecio(a)] = a.precio;
      // Mismo número que muestra la tarjeta: el total de ambas empresas.
      stock.putIfAbsent(a.codArticulo, () => a.disponibleTotal);
    }

    final conCambioPrecio = <String>{};
    final conCambioStock = <String>{};
    final hayFotoPrevia = _preciosPrevios.isNotEmpty;
    if (hayFotoPrevia) {
      precios.forEach((clave, nuevo) {
        final previo = _preciosPrevios[clave];
        if (previo == null || (previo - nuevo).abs() < 0.0001) return;
        final cod = clave.split('|').first;
        conCambioPrecio.add(cod);
        _cambios[cod] = _CambioArticulo(
          nuevo > previo ? _TipoCambio.precioSube : _TipoCambio.precioBaja,
          ahora,
        );
      });
      stock.forEach((cod, nuevo) {
        final previo = _stockPrevio[cod];
        if (previo == null || previo == nuevo) return;
        // Un cambio de precio pesa más que uno de stock.
        if (conCambioPrecio.contains(cod)) return;
        conCambioStock.add(cod);
        _cambios[cod] = _CambioArticulo(_TipoCambio.stock, ahora);
      });
    }
    _cambios.removeWhere(
      (_, c) => ahora.difference(c.cuando) > _duracionResaltado,
    );

    final manual = _refrescoManual;
    _refrescoManual = false;
    setState(() {
      _preciosPrevios = precios;
      _stockPrevio = stock;
      _ultimaActualizacion = ahora;
    });

    if (!hayFotoPrevia) return;
    final nPrecio = conCambioPrecio.length;
    final nStock = conCambioStock.length;
    final partes = <String>[
      if (nPrecio > 0)
        nPrecio == 1 ? '1 precio cambió' : '$nPrecio precios cambiaron',
      if (nStock > 0)
        nStock == 1 ? '1 stock cambió' : '$nStock stocks cambiaron',
    ];
    if (partes.isNotEmpty) {
      mostrarAviso(
        context,
        'Datos actualizados: ${partes.join(' y ')}',
        tono: TonoAviso.aviso,
      );
    } else if (manual) {
      mostrarAviso(context, 'Todo al día: sin cambios de precio ni stock');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefresco?.cancel();
    _esperaBusqueda?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articulosAsyncValue = ref.watch(articulosCiudadProvider(_codCiudad));
    final cargando = articulosAsyncValue.isLoading;

    ref.listen<AsyncValue<List<ArticulosxCiudadEntity>>>(
      articulosCiudadProvider(_codCiudad),
      (_, next) {
        if (next.isLoading) return;
        if (next.hasError) {
          if (_refrescoManual) {
            _refrescoManual = false;
            mostrarAviso(
              context,
              'No se pudo actualizar. Revisa tu conexión.',
              tono: TonoAviso.error,
            );
          }
          return;
        }
        final lista = next.valueOrNull;
        if (lista != null) _procesarNuevosDatos(lista);
      },
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Encabezado: título, frescura de datos y actualizar ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catálogo de artículos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                        fontSize: isMobile ? 19 : 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _EstadoEnVivo(
                      ultimaActualizacion: _ultimaActualizacion,
                      cargando: cargando,
                      conError: articulosAsyncValue.hasError,
                      cambiosRecientes: _cambios.length,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ROLE_ADM siempre; el resto, con el botón del ACL en la BD.
              PermissionWidget(
                buttonName: btnCiudadesUsuario,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildBotonGestionCiudades(compacto: isMobile),
                ),
              ),
              _buildBotonActualizar(cargando, compacto: isMobile),
            ],
          ),

          const SizedBox(height: 12),

          // --- Ciudad ---
          _buildSelectorCiudad(context),

          // --- Buscador + orden ---
          _buildToolbar(context),

          // Línea de progreso mientras se refresca con datos ya visibles.
          SizedBox(
            height: 14,
            child: Center(
              child: AnimatedOpacity(
                opacity: cargando && _articulosCache.isNotEmpty ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),

          // --- Contenido principal ---
          Expanded(
            child: Builder(
              builder: (context) {
                if (articulosAsyncValue is AsyncLoading &&
                    _articulosCache.isNotEmpty) {
                  return _buildArticulosList(_articulosCache);
                }

                return articulosAsyncValue.when(
                  loading: () {
                    if (_articulosCache.isNotEmpty) {
                      return _buildArticulosList(_articulosCache);
                    }
                    return _buildLoadingState(context);
                  },
                  error: (error, stack) {
                    console('Error cargando artículos: $error');
                    if (_articulosCache.isNotEmpty) {
                      return Column(
                        children: [
                          _buildErrorBanner(context, error),
                          Expanded(child: _buildArticulosList(_articulosCache)),
                        ],
                      );
                    }
                    return _buildErrorState(context, error);
                  },
                  data: (articulos) {
                    if (articulos.isEmpty) {
                      if (_articulosCache.isNotEmpty) {
                        return _buildArticulosList(_articulosCache);
                      }
                      return _buildEmptyState(context);
                    }
                    if (articulos.isNotEmpty && mounted) {
                      _articulosCache = List.from(articulos);
                    }
                    return _buildArticulosList(articulos);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Search & Filter Bar ---
  static const _opcionesOrden = <(String, String)>[
    ('datoArt', 'Descripción'),
    ('codArticulo', 'Código'),
    ('precio', 'Precio'),
    ('disponible', 'Stock'),
  ];

  Widget _buildBotonActualizar(bool cargando, {required bool compacto}) {
    final icono =
        cargando
            ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : const Icon(Icons.refresh_rounded, size: 20);
    final onPressed = cargando ? null : () => _refrescar(manual: true);

    if (compacto) {
      return IconButton.filledTonal(
        tooltip: 'Actualizar precios y stock',
        onPressed: onPressed,
        icon: icono,
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: icono,
      label: Text(cargando ? 'Actualizando…' : 'Actualizar'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }

  Widget _buildBotonGestionCiudades({required bool compacto}) {
    void abrir() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CiudadesPorUsuarioScreen()));
    if (compacto) {
      return IconButton.outlined(
        tooltip: 'Ciudades por usuario',
        onPressed: abrir,
        icon: const Icon(Icons.manage_accounts_rounded),
      );
    }
    return OutlinedButton.icon(
      onPressed: abrir,
      icon: const Icon(Icons.manage_accounts_rounded, size: 20),
      label: const Text('Ciudades por usuario'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// Chips de ciudad. Con una sola ciudad no hay nada que elegir: se muestra
  /// cuál es, para que el vendedor sepa de dónde son los precios.
  Widget _buildSelectorCiudad(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.permitidas;

    if (!p.tieneSelector) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.place_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              'Precios y stock de ${p.ciudades.first.ciudad}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    Widget chip(int cod, String etiqueta, {IconData? icono}) {
      final activo = cod == _codCiudad;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          showCheckmark: false,
          selected: activo,
          onSelected: (_) => _cambiarCiudad(cod),
          avatar:
              icono == null
                  ? null
                  : Icon(
                    icono,
                    size: 16,
                    color: activo ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
          label: Text(etiqueta),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            color: activo ? cs.onPrimary : cs.onSurface,
          ),
          selectedColor: cs.primary,
          side: BorderSide(
            color: activo ? Colors.transparent : cs.outlineVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.place_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (p.todas && p.esAdmin)
                    chip(
                      CiudadesPermitidasEntity.todasLasCiudades,
                      'Todas',
                      icono: Icons.public_rounded,
                    ),
                  // La ciudad del usuario primero.
                  for (final c in [
                    ...p.ciudades.where(
                      (c) => c.codCiudad == p.codCiudadInicial,
                    ),
                    ...p.ciudades.where(
                      (c) => c.codCiudad != p.codCiudadInicial,
                    ),
                  ])
                    chip(c.codCiudad, c.ciudad),
                  if (p.todas && !p.esAdmin)
                    chip(
                      CiudadesPermitidasEntity.todasLasCiudades,
                      'Todas las mías',
                      icono: Icons.public_rounded,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sigla de la ciudad para las líneas de precio en "Todas".
  static const _siglas = {
    'la paz': 'LPZ',
    'el alto': 'LPZ',
    'cochabamba': 'CBB',
    'santa cruz': 'SCZ',
    'tarija': 'TJA',
    'sucre': 'SRE',
    'oruro': 'ORU',
    'potosi': 'PTS',
    'potosí': 'PTS',
    'beni': 'BEN',
    'trinidad': 'TDD',
    'pando': 'PND',
    'cobija': 'CIJ',
  };

  String _siglaCiudad(int codCiudad) {
    final nombre = widget.permitidas.nombreDe(codCiudad).trim();
    final sigla = _siglas[nombre.toLowerCase()];
    if (sigla != null) return sigla;
    final letras = nombre.replaceAll(' ', '');
    return (letras.length >= 3 ? letras.substring(0, 3) : letras).toUpperCase();
  }

  // ── Colores fijos por empresa y por ciudad ─────────────────────────────
  // Fuera del verde/ámbar/rojo, que quedan para la disponibilidad: así un
  // color nunca significa dos cosas.
  static const _coloresDb = {
    'IPX': Color(0xFF1565C0), // azul
    'ESP': Color(0xFF7B1FA2), // violeta
  };
  static const _coloresCiudad = {
    1: Color(0xFF00897B), // La Paz (y El Alto): verde azulado
    4: Color(0xFFE65100), // Cochabamba: naranja
    5: Color(0xFFC2185B), // Santa Cruz: fucsia
    6: Color(0xFF6D4C41), // Oruro: café
  };
  static const _coloresCiudadExtra = [
    Color(0xFF3949AB),
    Color(0xFF00838F),
    Color(0xFF8E24AA),
    Color(0xFF5D4037),
  ];

  static Color _colorDb(String? db) =>
      _coloresDb[(db ?? '').trim().toUpperCase()] ?? const Color(0xFF546E7A);

  static Color _colorCiudad(int codCiudad) {
    final cod = codCiudad == 3 ? 1 : codCiudad;
    return _coloresCiudad[cod] ??
        _coloresCiudadExtra[cod.abs() % _coloresCiudadExtra.length];
  }

  /// En modo oscuro los tonos fuertes se aclaran para que se lean como texto.
  Color _legible(Color c) =>
      Theme.of(context).brightness == Brightness.dark
          ? Color.lerp(c, Colors.white, 0.45)!
          : c;

  /// Placa sólida de color con texto blanco (empresa, sigla de ciudad).
  Widget _placa(
    String texto,
    Color color, {
    double tamano = 9.5,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: tamano,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _etiquetaCiudad(int codCiudad, ColorScheme cs) {
    return Tooltip(
      message: widget.permitidas.nombreDe(codCiudad),
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: _placa(
          _siglaCiudad(codCiudad),
          _colorCiudad(codCiudad),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        ),
      ),
    );
  }

  // --- Buscador + orden ---
  // Ancho >= 760: una sola fila. Más angosto: buscador arriba y chips de orden
  // con scroll horizontal debajo.
  Widget _buildToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final buscador = TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por código o descripción',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder:
              (context, valor, _) =>
                  valor.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: _limpiarBusqueda,
                      ),
        ),
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 14,
        ),
      ),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14.5),
      onChanged: _alEscribir,
    );

    Widget chips({required bool conRotulo}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conRotulo) ...[
          Text(
            'Ordenar',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
        for (final (valor, etiqueta) in _opcionesOrden) ...[
          _chipOrden(valor, etiqueta, colorScheme),
          const SizedBox(width: 6),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: buscador),
              const SizedBox(width: 16),
              chips(conRotulo: true),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buscador,
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chips(conRotulo: false),
            ),
          ],
        );
      },
    );
  }

  // Tocar el chip activo invierte el sentido; tocar otro lo activa ascendente.
  Widget _chipOrden(String valor, String etiqueta, ColorScheme colorScheme) {
    final activo = _sortBy == valor;
    return ChoiceChip(
      showCheckmark: false,
      selected: activo,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: activo ? Colors.transparent : colorScheme.outlineVariant,
      ),
      selectedColor: colorScheme.primaryContainer,
      tooltip:
          activo
              ? (_sortAscending ? 'Ascendente' : 'Descendente')
              : 'Ordenar por ${etiqueta.toLowerCase()}',
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color:
                  activo
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
            ),
          ),
          if (activo) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: colorScheme.onPrimaryContainer,
            ),
          ],
        ],
      ),
      onSelected: (_) {
        setState(() {
          if (activo) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = valor;
            _sortAscending = true;
          }
        });
      },
    );
  }

  // --- Loading state ---
  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando artículos...',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Error banner (when cache available) ---
  Widget _buildErrorBanner(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexión — mostrando datos guardados',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _refrescar(manual: true),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // --- Error state (no cache) ---
  Widget _buildErrorState(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _refrescar(manual: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Empty state ---
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No se encontraron artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros criterios de búsqueda',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // --- Articles list ---
  Widget _buildArticulosList(List<ArticulosxCiudadEntity> articulos) {
    _indexar(articulos);

    final articulosAgrupados = <String, List<ArticulosxCiudadEntity>>{};
    var totalPrecios = 0;
    _grupos.forEach((codigo, filas) {
      if (_selectedFamilia != null &&
          filas.first.codigoFamilia != _selectedFamilia) {
        return;
      }
      if (!_consulta.vacia &&
          !_consulta.coincideNormalizado(_textoBuscable[codigo]!)) {
        return;
      }
      articulosAgrupados[codigo] = filas;
      totalPrecios += filas.length;
    });

    if (articulosAgrupados.isEmpty) {
      return _buildEmptyState(context);
    }

    List<String> codigosOrdenados = articulosAgrupados.keys.toList();

    codigosOrdenados.sort((a, b) {
      if (_sortBy == 'datoArt') {
        final aDesc = articulosAgrupados[a]!.first.datoArt;
        final bDesc = articulosAgrupados[b]!.first.datoArt;
        return _sortAscending ? aDesc.compareTo(bDesc) : bDesc.compareTo(aDesc);
      } else if (_sortBy == 'codArticulo') {
        return _sortAscending ? a.compareTo(b) : b.compareTo(a);
      } else if (_sortBy == 'precio') {
        final aPrecioMin = articulosAgrupados[a]!
            .map((e) => e.precio)
            .reduce((v, e) => v < e ? v : e);
        final bPrecioMin = articulosAgrupados[b]!
            .map((e) => e.precio)
            .reduce((v, e) => v < e ? v : e);
        return _sortAscending
            ? aPrecioMin.compareTo(bPrecioMin)
            : bPrecioMin.compareTo(aPrecioMin);
      } else if (_sortBy == 'disponible') {
        final aDisp = articulosAgrupados[a]!.first.disponibleTotal;
        final bDisp = articulosAgrupados[b]!.first.disponibleTotal;
        return _sortAscending ? aDisp.compareTo(bDisp) : bDisp.compareTo(aDisp);
      }
      return 0;
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2, left: 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _formatNumber(codigosOrdenados.length),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text:
                      codigosOrdenados.length == 1 ? ' artículo' : ' artículos',
                ),
                TextSpan(text: '  ·  ${_formatNumber(totalPrecios)} precios'),
              ],
            ),
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Expanded(
          // Se decide por el ancho disponible (sin el menú lateral), no por
          // el de la pantalla.
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return _buildMobileTabletList(
                  codigosOrdenados,
                  articulosAgrupados,
                );
              }
              final columnas = (constraints.maxWidth / 260).floor().clamp(2, 5);
              return _buildDesktopGrid(
                codigosOrdenados,
                articulosAgrupados,
                columnas,
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Cuadrícula (web / escritorio / tablet) ---
  Widget _buildDesktopGrid(
    List<String> codigosOrdenados,
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados,
    int columnas,
  ) {
    const espacio = 12.0;
    final filas = (codigosOrdenados.length / columnas).ceil();

    return RefreshIndicator(
      onRefresh: () => _refrescar(manual: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Arriba deja lugar para la etiqueta de "Precio subió".
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: filas,
        itemBuilder: (context, fila) {
          final inicio = fila * columnas;
          return Padding(
            padding: EdgeInsets.only(bottom: fila < filas - 1 ? espacio : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < columnas; i++) ...[
                    if (i > 0) const SizedBox(width: espacio),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final idx = inicio + i;
                          if (idx >= codigosOrdenados.length) {
                            return const SizedBox.shrink();
                          }
                          final codigo = codigosOrdenados[idx];
                          final variantes = articulosAgrupados[codigo]!;
                          return _ResaltadoCambio(
                            cambio: _cambios[codigo],
                            child: _buildArticuloCard(
                              variantes.first,
                              _agruparVariantes(variantes),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Lista (celular) ---
  Widget _buildMobileTabletList(
    List<String> codigosOrdenados,
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refrescar(manual: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: codigosOrdenados.length,
        itemBuilder: (context, index) {
          final codigo = codigosOrdenados[index];
          final variantes = articulosAgrupados[codigo]!;
          return _ResaltadoCambio(
            cambio: _cambios[codigo],
            margenInferior: 12,
            child: _buildArticuloMobileItem(
              variantes.first,
              _agruparVariantes(variantes),
            ),
          );
        },
      ),
    );
  }

  Map<String?, Map<int?, ArticulosxCiudadEntity>> _agruparVariantes(
    List<ArticulosxCiudadEntity> variantes,
  ) {
    Map<String?, Map<int?, ArticulosxCiudadEntity>> result = {};
    for (var v in variantes) {
      result.putIfAbsent(v.db, () => {});
      result[v.db]![v.listaPrecio] = v;
    }
    return result;
  }

  // --- Helper: Format price with thousand separators ---
  static final _priceFormatter = NumberFormat('#,##0.00', 'en_US');

  String _formatNumber(int number) {
    return NumberFormat('#,##0', 'en_US').format(number);
  }

  // --- Helper: Get availability color ---
  Color _getDisponibilidadColor(BuildContext context, int disponible) {
    final colorScheme = Theme.of(context).colorScheme;
    if (disponible > 100) return colorScheme.primary;
    if (disponible > 20) return Colors.amber.shade700;
    return colorScheme.error;
  }

  // ============================================================
  //  PIEZAS COMUNES DE LAS TARJETAS
  // ============================================================
  static const _tabular = [FontFeature.tabularFigures()];

  /// Precios ordenados de menor a mayor, como una lista de precios impresa.
  List<ArticulosxCiudadEntity> _preciosOrdenados(
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    final lista = <ArticulosxCiudadEntity>[
      for (final porLista in variantesPorDbYLista.values) ...porLista.values,
    ];
    lista.sort((a, b) => a.precio.compareTo(b.precio));
    return lista;
  }

  static final _decimalCorto = NumberFormat('#,##0.##', 'en_US');

  String _meta(ArticulosxCiudadEntity a) {
    final partes = <String>[
      if (a.utm > 0) 'UTM ${_decimalCorto.format(a.utm)}',
      if (a.gramaje > 0) '${_decimalCorto.format(a.gramaje)} g',
    ];
    return partes.join('  ·  ');
  }

  /// Código arriba en una sola línea (se achica si no entra, nunca se
  /// parte) y las empresas debajo: todas las bandas miden lo mismo.
  Widget _codigoYBases(
    ArticulosxCiudadEntity articulo,
    Iterable<String?> bases,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _codigoCopiable(
          articulo.codArticulo,
          texto: _resaltar(articulo.codArticulo),
          estilo: TextStyle(
            fontFeatures: _tabular,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final db in bases)
              if (db != null && db.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _placa(db, _colorDb(db)),
                ),
          ],
        ),
      ],
    );
  }

  /// Código del artículo que se copia al tocarlo (con su ícono al lado).
  /// En una sola línea: si no entra, se achica.
  Widget _codigoCopiable(
    String codigo, {
    required TextStyle estilo,
    InlineSpan? texto,
    double icono = 12,
  }) {
    final color = estilo.color ?? Theme.of(context).colorScheme.onSurface;
    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: 'Copiar código',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            Clipboard.setData(ClipboardData(text: codigo));
            HapticFeedback.selectionClick();
            mostrarAviso(context, 'Código copiado');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 1, 2, 1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    texto ?? TextSpan(text: codigo),
                    maxLines: 1,
                    style: estilo,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.copy_rounded,
                    size: icono,
                    color: color.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonCopiar(ArticulosxCiudadEntity articulo, ColorScheme cs) {
    return IconButton(
      tooltip: 'Copiar descripción',
      visualDensity: VisualDensity.compact,
      iconSize: 16,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      padding: EdgeInsets.zero,
      color: cs.onSurfaceVariant,
      icon: const Icon(Icons.copy_rounded),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: articulo.datoArt));
        mostrarAviso(context, 'Descripción copiada');
      },
    );
  }

  Widget _stock(int disponible, ColorScheme colorScheme) {
    final color = _getDisponibilidadColor(context, disponible);
    // En modo oscuro el primario/error son claros: ahí va texto oscuro.
    final texto =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded, size: 12, color: texto),
          const SizedBox(width: 4),
          Text(
            '${_formatNumber(disponible)} disp.',
            style: TextStyle(
              fontFeatures: _tabular,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: texto,
            ),
          ),
        ],
      ),
    );
  }

  /// Una línea de la lista de precios: "L9  Aut GG ........ BS 1,093.57".
  Widget _lineaPrecio(ArticulosxCiudadEntity a, ColorScheme cs, bool mejor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'L${a.listaPrecio}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: mejor ? cs.primary : cs.onSurfaceVariant,
                fontFeatures: _tabular,
              ),
            ),
          ),
          if (_enTodas) _etiquetaCiudad(a.codCiudad, cs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              a.condicionPrecio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
          ),
          const Expanded(child: _PuntosGuia()),
          Text(
            _priceFormatter.format(a.precio),
            style: TextStyle(
              fontFeatures: _tabular,
              fontSize: 12.5,
              fontWeight: mejor ? FontWeight.w700 : FontWeight.w500,
              color: mejor ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _precioDesde(
    ArticulosxCiudadEntity? mejor,
    ColorScheme cs, {
    required double tamano,
  }) {
    if (mejor == null) {
      return Text(
        'Consultar',
        style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'desde',
          style: TextStyle(
            fontSize: 10.5,
            height: 1,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${mejor.moneda ?? 'BS'} ',
                style: TextStyle(
                  fontSize: tamano * 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: _priceFormatter.format(mejor.precio)),
            ],
          ),
          style: TextStyle(
            fontFeatures: _tabular,
            fontSize: tamano,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.1,
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  COLOR: franja lateral = familia, banda superior = stock
  // ============================================================
  static const _paletaFamilias = <Color>[
    Color(0xFF1E88E5), // azul
    Color(0xFF8E24AA), // violeta
    Color(0xFF00897B), // verde azulado
    Color(0xFFF4511E), // naranja
    Color(0xFF3949AB), // índigo
    Color(0xFFD81B60), // rosa
    Color(0xFF6D4C41), // café
    Color(0xFF00ACC1), // celeste
    Color(0xFF7CB342), // verde lima
    Color(0xFFFFB300), // ámbar
  ];

  /// Mismo código de familia -> mismo color, en todas las visitas.
  Color _colorFamilia(int codigoFamilia) =>
      _paletaFamilias[codigoFamilia.abs() % _paletaFamilias.length];

  /// Tarjeta con franja de familia a la izquierda. [contenido] ya trae la
  /// banda de stock arriba.
  Widget _marcoTarjeta({
    required ArticulosxCiudadEntity articulo,
    required Map<String?, Map<int?, ArticulosxCiudadEntity>> variantes,
    required ColorScheme cs,
    required Widget contenido,
    VoidCallback? onLongPress,
  }) {
    return _TarjetaElevable(
      child: InkWell(
        onTap: () => _mostrarVariantesPrecio(context, articulo, variantes),
        onLongPress: onLongPress,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tooltip(
                message: 'Familia ${articulo.codigoFamilia}',
                child: Container(
                  width: 6,
                  color: _colorFamilia(articulo.codigoFamilia),
                ),
              ),
              Expanded(child: contenido),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bandaStock(
    ArticulosxCiudadEntity articulo,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantes,
    ColorScheme cs,
  ) {
    final color = _getDisponibilidadColor(context, articulo.disponibleTotal);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _codigoYBases(articulo, variantes.keys, cs)),
          const SizedBox(width: 6),
          _stock(articulo.disponibleTotal, cs),
        ],
      ),
    );
  }

  Widget _pie({required Widget izquierda, required Widget derecha}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Expanded(child: izquierda), derecha],
      ),
    );
  }

  // ============================================================
  //  TARJETA (cuadrícula)
  // ============================================================
  Widget _buildArticuloCard(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    final cs = Theme.of(context).colorScheme;
    final precios = _preciosOrdenados(variantesPorDbYLista);
    final visibles = precios.take(3).toList();
    final restantes = precios.length - visibles.length;
    final meta = _meta(articuloPrincipal);

    return _marcoTarjeta(
      articulo: articuloPrincipal,
      variantes: variantesPorDbYLista,
      cs: cs,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bandaStock(articuloPrincipal, variantesPorDbYLista, cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: articuloPrincipal.datoArt,
                        waitDuration: const Duration(milliseconds: 500),
                        child: Text.rich(
                          _resaltar(articuloPrincipal.datoArt),
                          // 3 líneas: con 5 columnas la tarjeta es angosta y la
                          // descripción completa es lo que el vendedor busca.
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            height: 1.3,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _botonCopiar(articuloPrincipal, cs),
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                for (int i = 0; i < visibles.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _lineaPrecio(visibles[i], cs, i == 0),
                  ),
              ],
            ),
          ),
          const Spacer(),
          _pie(
            izquierda:
                restantes > 0
                    ? Text(
                      restantes == 1
                          ? 'Ver 1 precio más'
                          : 'Ver $restantes precios más',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    )
                    : const SizedBox.shrink(),
            derecha: _precioDesde(
              visibles.isEmpty ? null : visibles.first,
              cs,
              tamano: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  FILA (celular)
  // ============================================================
  Widget _buildArticuloMobileItem(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    final cs = Theme.of(context).colorScheme;
    final precios = _preciosOrdenados(variantesPorDbYLista);
    final mejor = precios.isEmpty ? null : precios.first;
    final meta = _meta(articuloPrincipal);

    return _marcoTarjeta(
      articulo: articuloPrincipal,
      variantes: variantesPorDbYLista,
      cs: cs,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: articuloPrincipal.datoArt));
        HapticFeedback.selectionClick();
        mostrarAviso(context, 'Descripción copiada');
      },
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bandaStock(articuloPrincipal, variantesPorDbYLista, cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  _resaltar(articuloPrincipal.datoArt),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: cs.onSurface,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _pie(
            izquierda: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mejor != null)
                  Text(
                    _enTodas
                        ? 'L${mejor.listaPrecio} · ${_siglaCiudad(mejor.codCiudad)} · ${mejor.condicionPrecio}'
                        : 'L${mejor.listaPrecio} · ${mejor.condicionPrecio}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                Text(
                  precios.length == 1
                      ? 'Ver detalle'
                      : 'Ver ${precios.length} precios',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            derecha: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _precioDesde(mejor, cs, tamano: 21),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  HOJA DE DETALLE - precios y stock por almacén
  //  Un solo margen (24) para todo, cifras a la derecha en la misma
  //  columna, sin bandas anidadas con sangrías distintas.
  // ============================================================
  static const double _margenHoja = 24;

  static String _titulo(String texto) => texto
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');

  TextStyle _cifra(
    double tamano, {
    FontWeight peso = FontWeight.w700,
    Color? color,
  }) => TextStyle(
    fontFeatures: _tabular,
    fontSize: tamano,
    fontWeight: peso,
    color: color,
    letterSpacing: -0.2,
  );

  void _mostrarVariantesPrecio(
    BuildContext context,
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // En web/escritorio la hoja queda centrada y no de borde a borde.
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder:
              (context, scrollController) => _hojaDetalle(
                context,
                articuloPrincipal,
                variantesPorDbYLista,
                scrollController,
              ),
        );
      },
    );
  }

  Widget _hojaDetalle(
    BuildContext context,
    ArticulosxCiudadEntity a,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantes,
    ScrollController scrollController,
  ) {
    final cs = Theme.of(context).colorScheme;
    final precios = _preciosOrdenados(variantes);
    final unidad = _titulo((a.unidadMedida ?? '').toString()).toLowerCase();

    Widget accion(IconData icono, String ayuda, VoidCallback onTap) =>
        IconButton(
          tooltip: ayuda,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHigh,
            foregroundColor: cs.onSurfaceVariant,
            fixedSize: const Size(40, 40),
          ),
          icon: Icon(icono, size: 20),
        );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Agarradera
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Encabezado: código + descripción | copiar + cerrar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _margenHoja),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _codigoCopiable(
                          a.codArticulo,
                          icono: 14,
                          estilo: _cifra(
                            12.5,
                            peso: FontWeight.w500,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          a.datoArt,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -0.2,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  accion(Icons.copy_rounded, 'Copiar descripción', () {
                    Clipboard.setData(ClipboardData(text: a.datoArt));
                    mostrarAviso(context, 'Descripción copiada');
                  }),
                  const SizedBox(width: 8),
                  accion(
                    Icons.close_rounded,
                    'Cerrar',
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Resumen: stock, precio y UTM, del mismo ancho
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _margenHoja,
                12,
                _margenHoja,
                0,
              ),
              child: _resumenArticulo(context, a, precios, unidad),
            ),

            // Pestañas segmentadas
            Container(
              margin: const EdgeInsets.fromLTRB(
                _margenHoja,
                18,
                _margenHoja,
                4,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: cs.onSurface,
                unselectedLabelColor: cs.onSurfaceVariant,
                // Del tema: el TabBar no hereda la fuente del texto de alrededor.
                labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                unselectedLabelStyle: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w500, fontSize: 13.5),
                splashBorderRadius: BorderRadius.circular(9),
                tabs: [
                  Tab(height: 34, text: 'Precios · ${precios.length}'),
                  const Tab(height: 34, text: 'Stock por almacén'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildPreciosTab(context, variantes, scrollController),
                  _buildDisponibilidadTab(context, a, scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nivel de stock con las mismas reglas que el color de disponibilidad.
  String _nivelStock(int disponible, {bool corto = false}) {
    if (disponible > 100) return corto ? 'Alto' : 'Stock alto';
    if (disponible > 20) return corto ? 'Medio' : 'Stock medio';
    if (disponible > 0) return corto ? 'Bajo' : 'Stock bajo';
    return 'Sin stock';
  }

  /// Resumen en una franja delgada: stock, precio y UTM. Lo importante de
  /// la hoja son las listas de precios y los almacenes, no esto.
  Widget _resumenArticulo(
    BuildContext context,
    ArticulosxCiudadEntity a,
    List<ArticulosxCiudadEntity> precios,
    String unidad,
  ) {
    final cs = Theme.of(context).colorScheme;
    final compacto = MediaQuery.sizeOf(context).width < 520;
    final colorStock = _getDisponibilidadColor(context, a.disponibleTotal);
    final menor = precios.isEmpty ? null : precios.first;
    final mayor = precios.isEmpty ? null : precios.last;
    final moneda = menor?.moneda ?? 'BS';

    TextStyle chico(Color c, {FontWeight peso = FontWeight.w600}) =>
        TextStyle(fontSize: 11.5, fontWeight: peso, color: c);

    final divisor = VerticalDivider(
      width: 1,
      thickness: 1,
      indent: 8,
      endIndent: 8,
      color: cs.outlineVariant.withValues(alpha: 0.6),
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _segmentoResumen(
              icono: Icons.inventory_2_rounded,
              acento: colorStock,
              etiqueta: Text(
                _nivelStock(a.disponibleTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: chico(_legible(colorStock), peso: FontWeight.w700),
              ),
              valor: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: _formatNumber(a.disponibleTotal)),
                    if (unidad.isNotEmpty)
                      TextSpan(
                        text: ' $unidad',
                        style: chico(cs.onSurfaceVariant),
                      ),
                  ],
                ),
                style: _cifra(
                  16,
                  peso: FontWeight.w800,
                  color: _legible(colorStock),
                ),
              ),
            ),
            divisor,
            _segmentoResumen(
              icono: Icons.sell_rounded,
              acento: cs.primary,
              etiqueta: Text(
                menor == null
                    ? 'Precio'
                    : compacto
                    ? 'Lista ${menor.listaPrecio}'
                    : 'Precio · Lista ${menor.listaPrecio} · ${menor.condicionPrecio}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: chico(cs.onSurfaceVariant),
              ),
              valor: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$moneda ', style: chico(cs.primary)),
                    TextSpan(
                      text:
                          menor == null
                              ? '—'
                              : _priceFormatter.format(menor.precio),
                    ),
                    if (!compacto && mayor != null && precios.length > 1)
                      TextSpan(
                        text: '  a ${_priceFormatter.format(mayor.precio)}',
                        style: chico(cs.onSurfaceVariant),
                      ),
                  ],
                ),
                style: _cifra(16, peso: FontWeight.w800, color: cs.primary),
              ),
            ),
            divisor,
            _segmentoResumen(
              icono: Icons.straighten_rounded,
              acento: cs.tertiary,
              etiqueta: Text(
                a.gramaje > 0
                    ? 'UTM · ${_decimalCorto.format(a.gramaje)} g'
                    : 'UTM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: chico(cs.onSurfaceVariant),
              ),
              valor: Text(
                a.utm > 0 ? _decimalCorto.format(a.utm) : '—',
                style: _cifra(
                  16,
                  peso: FontWeight.w800,
                  color: _legible(cs.tertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentoResumen({
    required IconData icono,
    required Color acento,
    required Widget etiqueta,
    required Widget valor,
  }) {
    final compacto = MediaQuery.sizeOf(context).width < 520;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 8 : 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            if (!compacto) ...[
              Icon(icono, size: 18, color: _legible(acento)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  etiqueta,
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: valor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bloque agrupado: filas separadas por una línea fina, sin tarjetas sueltas.
  Widget _bloque(ColorScheme cs, List<Widget> filas, {Color? acento}) {
    final contenido = Column(
      children: [
        for (int i = 0; i < filas.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          filas[i],
        ],
      ],
    );
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (acento ?? cs.outlineVariant).withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          acento == null
              ? contenido
              : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: acento),
                    Expanded(child: contenido),
                  ],
                ),
              ),
    );
  }

  /// Encabezado de un grupo de precios: placa de empresa + ciudad en su color.
  Widget _encabezadoPrecios(
    ColorScheme cs,
    String db,
    int? codCiudad,
    int cantidad,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 4, 8),
      child: Row(
        children: [
          _placa(
            db,
            _colorDb(db),
            tamano: 12,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          ),
          if (codCiudad != null) ...[
            const SizedBox(width: 10),
            Icon(
              Icons.place_rounded,
              size: 16,
              color: _legible(_colorCiudad(codCiudad)),
            ),
            const SizedBox(width: 3),
            Text(
              widget.permitidas.nombreDe(codCiudad),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _legible(_colorCiudad(codCiudad)),
              ),
            ),
          ],
          const Spacer(),
          Text(
            cantidad == 1 ? '1 lista' : '$cantidad listas',
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // --- Pestaña Precios ---
  // Agrupado por empresa y, si hay varias, por ciudad. En cada ciudad el
  // precio más alto lleva "Precio recomendado".
  Widget _buildPreciosTab(
    BuildContext context,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
    ScrollController scrollController,
  ) {
    final cs = Theme.of(context).colorScheme;
    final todos = _preciosOrdenados(variantesPorDbYLista);

    final recomendado = <int, ArticulosxCiudadEntity>{};
    for (final v in todos) {
      final actual = recomendado[v.codCiudad];
      if (actual == null || v.precio > actual.precio) {
        recomendado[v.codCiudad] = v;
      }
    }
    final variasCiudades = recomendado.length > 1;

    // (empresa, ciudad) -> listas, en orden de lista
    final grupos = <String, List<ArticulosxCiudadEntity>>{};
    for (final v in todos) {
      final clave = variasCiudades ? '${v.db}|${v.codCiudad}' : v.db;
      grupos.putIfAbsent(clave, () => []).add(v);
    }
    for (final g in grupos.values) {
      g.sort((x, y) => x.listaPrecio.compareTo(y.listaPrecio));
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(_margenHoja, 16, _margenHoja, 28),
      children: [
        for (final g in grupos.values) ...[
          _encabezadoPrecios(
            cs,
            g.first.db,
            variasCiudades ? g.first.codCiudad : null,
            g.length,
          ),
          _bloque(
            cs,
            [
              for (final v in g)
                _filaPrecio(cs, v, identical(v, recomendado[v.codCiudad])),
            ],
            acento:
                variasCiudades
                    ? _colorCiudad(g.first.codCiudad)
                    : _colorDb(g.first.db),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _filaPrecio(
    ColorScheme cs,
    ArticulosxCiudadEntity v,
    bool recomendado,
  ) {
    // En celular la etiqueta va debajo de la condición, para no aplastarla.
    final compacto = MediaQuery.sizeOf(context).width < 520;
    final etiqueta = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.thumb_up_alt_rounded,
            size: 12,
            color: cs.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Precio recomendado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
    final condicion = Text(
      v.condicionPrecio,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              'Lista ${v.listaPrecio}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: recomendado ? cs.primary : cs.onSurfaceVariant,
                fontFeatures: _tabular,
              ),
            ),
          ),
          Expanded(
            child:
                recomendado && compacto
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        condicion,
                        const SizedBox(height: 4),
                        etiqueta,
                      ],
                    )
                    : condicion,
          ),
          if (recomendado && !compacto)
            Padding(padding: const EdgeInsets.only(right: 12), child: etiqueta),
          Text(
            '${v.moneda ?? 'BS'} ${_priceFormatter.format(v.precio)}',
            style: _cifra(15, color: recomendado ? cs.primary : cs.onSurface),
          ),
        ],
      ),
    );
  }

  // --- Pestaña Stock por almacén ---
  Widget _buildDisponibilidadTab(
    BuildContext context,
    ArticulosxCiudadEntity articulo,
    ScrollController scrollController,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Consumer(
      builder: (context, ref, _) {
        final stock = ref.watch(
          articuloAlmacenProvider((articulo.codArticulo, _codCiudad)),
        );

        return stock.when(
          loading:
              () => ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  _margenHoja,
                  16,
                  _margenHoja,
                  28,
                ),
                children: [
                  // Esqueleto con la forma del contenido, no una ruedita.
                  for (final alto in [78.0, 132.0, 96.0])
                    Container(
                      height: alto,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                ],
              ),
          error:
              (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(_margenHoja),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, color: cs.error, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        'No se pudo cargar el stock por almacén.',
                        style: TextStyle(color: cs.onSurface),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed:
                            () => ref.invalidate(
                              articuloAlmacenProvider((
                                articulo.codArticulo,
                                _codCiudad,
                              )),
                            ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
          data: (filas) {
            if (filas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 44,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sin stock en ningún almacén',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            return _buildStockContent(
              context,
              articulo,
              filas,
              scrollController,
            );
          },
        );
      },
    );
  }

  Widget _buildStockContent(
    BuildContext context,
    ArticulosxCiudadEntity articulo,
    List<ArticulosxAlmacenEntity> filas,
    ScrollController scrollController,
  ) {
    final cs = Theme.of(context).colorScheme;
    final unidad =
        _titulo((articulo.unidadMedida ?? '').toString()).toLowerCase();

    // empresa -> ciudad -> almacenes
    final porDb = <String, Map<String, List<ArticulosxAlmacenEntity>>>{};
    for (final f in filas) {
      porDb
          .putIfAbsent(f.db, () => {})
          .putIfAbsent(_titulo(f.ciudad), () => [])
          .add(f);
    }
    int suma(Iterable<ArticulosxAlmacenEntity> xs) =>
        xs.fold(0, (t, x) => t + x.disponible);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(_margenHoja, 16, _margenHoja, 28),
      children: [
        for (final db in porDb.entries) ...[
          // Empresa: placa + total, bien visible.
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _colorDb(db.key),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    db.key,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  db.value.length == 1
                      ? '1 ciudad'
                      : '${db.value.length} ciudades',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  _formatNumber(suma(db.value.values.expand((x) => x))),
                  style: _cifra(16, color: cs.onSurface),
                ),
                if (unidad.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unidad,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          for (final ciudad in db.value.entries) ...[
            _bloqueCiudad(cs, ciudad.key, ciudad.value, suma(ciudad.value)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  /// Una ciudad en su color: encabezado teñido con su total (coloreado según
  /// la disponibilidad) y, debajo, cada almacén con código, nombre y cantidad.
  Widget _bloqueCiudad(
    ColorScheme cs,
    String ciudad,
    List<ArticulosxAlmacenEntity> almacenes,
    int total,
  ) {
    final ordenados = [...almacenes]
      ..sort((x, y) => y.disponible.compareTo(x.disponible));
    final color = _colorCiudad(ordenados.first.codCiudad);
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de la ciudad
          Container(
            color: color.withValues(alpha: oscuro ? 0.28 : 0.14),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(Icons.place_rounded, size: 18, color: _legible(color)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ciudad,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _legible(color),
                    ),
                  ),
                ),
                Text(
                  ordenados.length == 1
                      ? '1 almacén'
                      : '${ordenados.length} almacenes',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                _cantidad(total, 16),
              ],
            ),
          ),
          for (int i = 0; i < ordenados.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            _filaAlmacen(cs, ordenados[i], color),
          ],
        ],
      ),
    );
  }

  /// Cantidad con el color de su disponibilidad (verde / ámbar / rojo).
  Widget _cantidad(int valor, double tamano) {
    final c = _getDisponibilidadColor(context, valor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          _formatNumber(valor),
          style: _cifra(tamano, peso: FontWeight.w800, color: c),
        ),
      ],
    );
  }

  Widget _filaAlmacen(
    ColorScheme cs,
    ArticulosxAlmacenEntity a,
    Color colorCiudad,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Código del almacén en placa de ancho fijo, en el color de la ciudad.
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorCiudad.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorCiudad.withValues(alpha: 0.4)),
            ),
            child: Text(
              a.whsCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _legible(colorCiudad),
                fontFeatures: _tabular,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _titulo(a.whsName),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _cantidad(a.disponible, 18),
        ],
      ),
    );
  }
}

/// Indicador de frescura: punto que late + "Actualizado hace X".
/// Así el vendedor sabe que los precios que ve son los de ahora.
class _EstadoEnVivo extends StatefulWidget {
  final DateTime? ultimaActualizacion;
  final bool cargando;
  final bool conError;
  final int cambiosRecientes;

  const _EstadoEnVivo({
    required this.ultimaActualizacion,
    required this.cargando,
    required this.conError,
    required this.cambiosRecientes,
  });

  @override
  State<_EstadoEnVivo> createState() => _EstadoEnVivoState();
}

class _EstadoEnVivoState extends State<_EstadoEnVivo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    // Sólo para que el texto "hace X" avance solo.
    _reloj = Timer.periodic(
      const Duration(seconds: 10),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _pulso.dispose();
    super.dispose();
  }

  String _haceCuanto(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 10) return 'justo ahora';
    if (d.inSeconds < 60) return 'hace ${d.inSeconds} s';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    return 'a las ${DateFormat('HH:mm').format(t)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ultima = widget.ultimaActualizacion;
    final desactualizado =
        ultima == null ||
        DateTime.now().difference(ultima) >
            _intervaloAutoRefresco + const Duration(minutes: 1);

    final Color color;
    final String texto;
    if (widget.cargando) {
      color = colorScheme.primary;
      texto = 'Actualizando precios y stock…';
    } else if (widget.conError) {
      color = colorScheme.error;
      texto =
          ultima == null
              ? 'Sin conexión'
              : 'Sin conexión · datos de ${_haceCuanto(ultima)}';
    } else if (ultima == null) {
      color = colorScheme.outline;
      texto = 'Cargando…';
    } else {
      color = desactualizado ? Colors.amber.shade700 : Colors.green.shade600;
      texto = 'En vivo · actualizado ${_haceCuanto(ultima)}';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: AnimatedBuilder(
                animation: _pulso,
                builder: (context, _) {
                  final t = _pulso.value;
                  final latiendo =
                      !widget.conError &&
                      !desactualizado &&
                      !MediaQuery.of(context).disableAnimations;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (latiendo)
                        Container(
                          width: 6 + 8 * t,
                          height: 6 + 8 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.35 * (1 - t)),
                          ),
                        ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            // Sin AnimatedSwitcher: el cruce de dos textos de distinto largo
            // se veía encimado.
            Flexible(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        if (widget.cambiosRecientes > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.cambiosRecientes == 1
                  ? '1 artículo con cambios'
                  : '${widget.cambiosRecientes} artículos con cambios',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

/// Marca un artículo cuyo precio o stock cambió en el último refresco:
/// borde de color, destello al llegar el cambio y etiqueta arriba.
class _ResaltadoCambio extends StatelessWidget {
  final _CambioArticulo? cambio;
  final Widget child;
  final double margenInferior;

  const _ResaltadoCambio({
    required this.cambio,
    required this.child,
    this.margenInferior = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = cambio;
    if (c == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: margenInferior),
        child: child,
      );
    }

    final (Color color, IconData icono, String texto) = switch (c.tipo) {
      _TipoCambio.precioSube => (
        Colors.red.shade600,
        Icons.trending_up_rounded,
        'Precio subió',
      ),
      _TipoCambio.precioBaja => (
        Colors.green.shade600,
        Icons.trending_down_rounded,
        'Precio bajó',
      ),
      // Azul: el primario del tema es verde y se confundía con "Precio bajó".
      _TipoCambio.stock => (
        Colors.blue.shade600,
        Icons.inventory_rounded,
        'Stock actualizado',
      ),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: margenInferior),
      child: TweenAnimationBuilder<double>(
        // Nuevo cambio -> nueva clave -> el destello se repite.
        key: ValueKey(c.cuando),
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 2400),
        curve: Curves.easeOutCubic,
        builder: (context, destello, hijo) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: 1.6),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12 + 0.35 * destello),
                        blurRadius: 6 + 14 * destello,
                        spreadRadius: 2 * destello,
                      ),
                    ],
                  ),
                  child: hijo,
                ),
              ),
              Positioned(
                top: -9,
                right: 12,
                child: Transform.scale(
                  scale: 1 + 0.15 * destello,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icono, size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          texto,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: child,
      ),
    );
  }
}

/// Puntos guía entre la condición y el monto, como en una lista de precios.
class _PuntosGuia extends StatelessWidget {
  const _PuntosGuia();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: CustomPaint(
        size: const Size.fromHeight(1),
        painter: _PuntosGuiaPainter(
          Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _PuntosGuiaPainter extends CustomPainter {
  final Color color;
  _PuntosGuiaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x + 0.75, size.height / 2), 0.75, paint);
    }
  }

  @override
  bool shouldRepaint(_PuntosGuiaPainter old) => old.color != color;
}

/// Tarjeta con borde fino y sombra suave; al pasar el mouse sube 2 px y se
/// marca el borde. Sin animación si el sistema pide reducir movimiento.
class _TarjetaElevable extends StatefulWidget {
  final Widget child;
  const _TarjetaElevable({required this.child});

  @override
  State<_TarjetaElevable> createState() => _TarjetaElevableState();
}

class _TarjetaElevableState extends State<_TarjetaElevable> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final sinMovimiento = MediaQuery.of(context).disableAnimations;
    final radio = BorderRadius.circular(16);

    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: AnimatedContainer(
        duration:
            sinMovimiento ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _encima ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: radio,
          border: Border.all(
            color:
                _encima
                    ? cs.primary.withValues(alpha: 0.45)
                    : cs.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: oscuro ? 0.30 : (_encima ? 0.10 : 0.04),
              ),
              blurRadius: _encima ? 18 : 6,
              offset: Offset(0, _encima ? 6 : 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radio,
          child: Material(type: MaterialType.transparency, child: widget.child),
        ),
      ),
    );
  }
}
