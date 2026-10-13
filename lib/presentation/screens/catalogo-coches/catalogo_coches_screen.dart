/// El catálogo de vehículos (`tac_coche`): alta, edición, baja lógica y
/// eliminación, por sucursal. Cuelga de la vista `tacCoche/Coche`: quien la tiene
/// en el menú es quien puede gestionarlos, y el backend lo vuelve a exigir.
///
/// El corte entre tabla y tarjetas se mide sobre el ancho del CAJÓN
/// (`LayoutBuilder`): dentro del `DashboardScreen` el sidebar se come su parte y
/// `MediaQuery` miente. Desde 720 px: planilla con columnas, filtros a la vista,
/// paginación y acciones en la fila. Debajo: tarjetas, filtros plegables y menú
/// contextual, sin scroll horizontal.
///
/// El listado se baja entero y se filtra aquí: son decenas de filas, y el
/// backend descarta los ceros de los filtros, así que «inactivos» no se podría
/// pedir. La baja es lógica (`estado = 0`) y es el camino normal: un vehículo con
/// kilometraje no se puede eliminar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart'
    show sucursalesProvider;
import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/acciones_coche.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/dialogo_coche.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/filtros_coches.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/tabla_coches.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/tarjeta_coche.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cabeza_y_lista.dart';

/// Con menos ancho que esto las ocho columnas no se leen: tarjetas.
const double _anchoMinimoTabla = 720;

// Estado local de la pantalla: vive aquí para que los filtros no se filtren a
// otras pantallas y arranquen limpios en cada visita.

final _filtroProvider = StateProvider.autoDispose<FiltroCoches>(
  (ref) => const FiltroCoches(),
);

/// Los `idCoche` con una escritura viajando. No es autoDispose: la escritura
/// puede terminar cuando la pantalla ya se desmontó (el atrás del navegador, una
/// sesión que vence) y escribir en un provider liberado lanza.
final _enCursoProvider = StateProvider<Set<int>>((ref) => <int>{});

class CatalogoCochesScreen extends ConsumerWidget {
  const CatalogoCochesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final compacto = restricciones.maxWidth < _anchoMinimoTabla;
        final margen = compacto ? Esp.l : Esp.xl;

        final estado = ref.watch(cocheProvider);
        final filtro = ref.watch(_filtroProvider);
        final catalogo = ref.watch(sucursalesProvider);
        final enCurso = ref.watch(_enCursoProvider);

        final sucursales = opcionesDeSucursal(
          catalogo: catalogo.valueOrNull,
          coches: estado.items,
        );
        final visibles = filtro.aplicar(estado.items);

        return Scaffold(
          floatingActionButton:
              compacto
                  ? FloatingActionButton.extended(
                    onPressed: () => _abrirFicha(context, compacto: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                  )
                  : null,
          // Con el teclado abierto en el teléfono (el buscador) el encabezado y
          // los filtros no dejan lugar a la lista: CabezaYLista los acota.
          body: CabezaYLista(
            altoCompacto: 480,
            cabeza: [
              _Encabezado(
                compacto: compacto,
                margen: margen,
                cargando: estado.cargando,
                onNuevo: () => _abrirFicha(context, compacto: false),
                onRefrescar: () {
                  ref.read(cocheProvider.notifier).cargar();
                  // El catálogo de sucursales no se libera con la pantalla: si
                  // falló una vez, el error se quedaría hasta cerrar la sesión.
                  // El mismo botón lo reintenta.
                  if (catalogo.hasError) ref.invalidate(sucursalesProvider);
                },
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                child: FiltrosCoches(
                  compacto: compacto,
                  filtro: filtro,
                  onFiltro: (f) => ref.read(_filtroProvider.notifier).state = f,
                  sucursales: sucursales,
                  ayudaSucursal: switch (catalogo) {
                    AsyncLoading() => 'Cargando sucursales…',
                    AsyncError() => 'No se pudo cargar el catálogo completo',
                    _ => null,
                  },
                ),
              ),
              const Divider(height: 1),
            ],
            lista: _lista(
              context,
              ref,
              estado: estado,
              visibles: visibles,
              filtro: filtro,
              compacto: compacto,
              margen: margen,
              enCurso: enCurso,
            ),
          ),
        );
      },
    );
  }

  Widget _lista(
    BuildContext context,
    WidgetRef ref, {
    required CocheState estado,
    required List<CocheEntity> visibles,
    required FiltroCoches filtro,
    required bool compacto,
    required double margen,
    required Set<int> enCurso,
  }) {
    // Antes de la primera respuesta: el esqueleto reserva el lugar y la página
    // no salta cuando llegan los datos.
    if (!estado.cargado && estado.error == null) {
      return EsqueletoLista(filas: 8, altoFila: compacto ? 96 : _altoFilaTabla);
    }

    if (!estado.cargado) {
      return Padding(
        padding: EdgeInsets.all(margen),
        child: MensajeError(
          error: estado.error,
          onReintentar: () => ref.read(cocheProvider.notifier).cargar(),
        ),
      );
    }

    if (estado.items.isEmpty) {
      return const MensajeVacio(
        icono: Icons.directions_car_outlined,
        titulo: 'Todavía no hay vehículos registrados',
        detalle: 'Crea el primero con «Nuevo vehículo».',
      );
    }

    if (visibles.isEmpty) {
      return MensajeVacio(
        icono: Icons.search_off,
        titulo: 'Ningún vehículo coincide',
        detalle:
            filtro.hayAlgo
                ? 'Prueba con otra placa o quita los filtros: hay '
                    '${estado.items.length} vehículos en el catálogo.'
                : 'No hay vehículos para mostrar.',
      );
    }

    final activos = estado.items.where((c) => c.esActivo).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        margen,
        Esp.m,
        margen,
        // Deja pasar el botón flotante por encima de la última tarjeta.
        compacto ? 88 : Esp.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (estado.error != null)
            _AvisoRecarga(
              error: estado.error!,
              onReintentar: () => ref.read(cocheProvider.notifier).cargar(),
            ),
          // Una recarga con datos en pantalla deja la lista quieta y cuenta la
          // espera con una barra fina: reemplazarla por bloques grises haría
          // parecer que se perdió lo que había.
          SizedBox(
            height: 2,
            child: estado.cargando ? const LinearProgressIndicator() : null,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.s, top: Esp.xs),
            child: Text(
              filtro.hayAlgo
                  ? '${visibles.length} de ${estado.items.length} vehículos'
                  : '${estado.items.length} vehículos, $activos activos',
              style: context.apagado(),
            ),
          ),
          Expanded(
            child:
                compacto
                    ? _ListaMovil(
                      filas: visibles,
                      enCurso: enCurso,
                      onEditar:
                          (c) => _abrirFicha(context, coche: c, compacto: true),
                      onAccion: (c, a) => _accion(context, ref, c, a, true),
                    )
                    : TablaCoches(
                      filas: visibles,
                      enCurso: enCurso,
                      onEditar:
                          (c) =>
                              _abrirFicha(context, coche: c, compacto: false),
                      onAccion: (c, a) => _accion(context, ref, c, a, false),
                    ),
          ),
        ],
      ),
    );
  }

  // Acciones

  void _accion(
    BuildContext context,
    WidgetRef ref,
    CocheEntity coche,
    AccionCoche accion,
    bool compacto,
  ) {
    switch (accion) {
      case AccionCoche.editar:
        _abrirFicha(context, coche: coche, compacto: compacto);
      case AccionCoche.cambiarEstado:
        _cambiarEstado(context, coche);
      case AccionCoche.eliminar:
        _eliminar(context, coche);
    }
  }

  /// La ficha: hoja modal desde abajo en teléfono (cerrarla es el mismo gesto
  /// que volver) y diálogo centrado de ancho acotado en escritorio.
  Future<void> _abrirFicha(
    BuildContext context, {
    CocheEntity? coche,
    required bool compacto,
  }) async {
    final alta = coche == null;
    // El contenedor y no `ref`: la ficha va sobre el navegador raíz y la
    // pantalla puede desmontarse con ella abierta.
    final contenedor = ProviderScope.containerOf(context, listen: false);

    // Graba y deja que la ficha cierre; si el servidor rechaza, lanza y la ficha
    // muestra el motivo sin cerrarse. Avisa aquí y no al cerrar: la hoja se
    // cierra de varias formas y lo grabado tiene que notarse igual.
    Future<void> guardar(CocheEntity c) async {
      await contenedor.read(cocheProvider.notifier).guardar(c);
      if (context.mounted) {
        final placa = placaLegible(c);
        avisar(
          context,
          alta ? 'Vehículo $placa registrado.' : 'Vehículo $placa actualizado.',
        );
      }
    }

    if (compacto) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DialogoCoche(editar: coche, onGuardar: guardar),
      );
    } else {
      await showDialog<bool>(
        context: context,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Esquina.media),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: DialogoCoche(
                  editar: coche,
                  onGuardar: guardar,
                  mostrarAsa: false,
                ),
              ),
            ),
      );
    }
  }

  Future<void> _cambiarEstado(BuildContext context, CocheEntity coche) async {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final baja = coche.esActivo;
    final placa = placaLegible(coche);

    final ok = await confirmar(
      context,
      titulo:
          baja
              ? 'Dar de baja el vehículo $placa'
              : 'Reactivar el vehículo $placa',
      detalle:
          baja
              ? 'Deja de figurar como activo. Conserva su historial y puedes '
                  'reactivarlo cuando quieras.'
              : 'Vuelve a figurar como activo.',
      textoConfirmar: baja ? 'Dar de baja' : 'Reactivar',
    );
    if (!ok || !context.mounted) return;

    final error = await _escribir(
      contenedor,
      coche,
      () => contenedor
          .read(cocheProvider.notifier)
          .guardar(_conEstado(contenedor, coche, activo: !baja)),
    );
    if (!context.mounted) return;
    if (error == null) {
      avisar(
        context,
        baja ? 'Vehículo $placa dado de baja.' : 'Vehículo $placa reactivado.',
      );
    } else {
      mostrarAviso(context, textoParaUsuario(error), tono: TonoAviso.error);
    }
  }

  Future<void> _eliminar(BuildContext context, CocheEntity coche) async {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final placa = placaLegible(coche);

    final ok = await confirmar(
      context,
      titulo: 'Eliminar el vehículo $placa',
      detalle:
          'Solo se puede eliminar un vehículo sin movimiento, por ejemplo uno '
          'creado por error. Si ya tiene kilometraje registrado, el sistema no '
          'lo elimina y puedes darlo de baja.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;

    final cod = contenedor.read(userProvider)?.codUsuario ?? 0;
    final error = await _escribir(
      contenedor,
      coche,
      () =>
          contenedor.read(cocheProvider.notifier).eliminar(coche.idCoche, cod),
    );
    if (!context.mounted) return;

    if (error == null) {
      avisar(context, 'Vehículo $placa eliminado.');
      return;
    }

    final mensaje = humanizar(error);
    // Un vehículo con movimiento no se elimina: lo que corresponde es la baja.
    // Solo se ofrece si el rechazo es una regla (no una falla del sistema) y el
    // vehículo todavía está activo.
    if (mensaje.esFalloTecnico || !coche.esActivo) {
      mostrarAviso(context, mensaje.texto, tono: TonoAviso.error);
      return;
    }

    final baja = await confirmar(
      context,
      titulo: 'No se pudo eliminar el vehículo $placa',
      detalle: '${mensaje.texto}\n\n¿Quieres darlo de baja en su lugar?',
      textoConfirmar: 'Dar de baja',
    );
    if (!baja || !context.mounted) return;

    final errorBaja = await _escribir(
      contenedor,
      coche,
      () => contenedor
          .read(cocheProvider.notifier)
          .guardar(_conEstado(contenedor, coche, activo: false)),
    );
    if (!context.mounted) return;
    if (errorBaja == null) {
      avisar(context, 'Vehículo $placa dado de baja.');
    } else {
      mostrarAviso(context, textoParaUsuario(errorBaja), tono: TonoAviso.error);
    }
  }

  CocheEntity _conEstado(
    ProviderContainer contenedor,
    CocheEntity coche, {
    required bool activo,
  }) => coche.copyWith(
    estado: activo ? CocheEntity.activo : CocheEntity.inactivo,
    audUsuario: contenedor.read(userProvider)?.codUsuario ?? 0,
  );

  /// Corre [op] marcando al vehículo como «en curso» para que un segundo toque
  /// no reenvíe la fila con datos viejos. Devuelve el error, o null si salió bien.
  Future<Object?> _escribir(
    ProviderContainer contenedor,
    CocheEntity coche,
    Future<void> Function() op,
  ) async {
    final marca = contenedor.read(_enCursoProvider.notifier);
    if (marca.state.contains(coche.idCoche)) {
      return 'El vehículo ${placaLegible(coche)} se está actualizando: espera '
          'un momento.';
    }
    marca.state = {...marca.state, coche.idCoche};
    try {
      await op();
      return null;
    } catch (e) {
      return e;
    } finally {
      marca.state = {...marca.state}..remove(coche.idCoche);
    }
  }
}

/// La fila de la tabla mide esto: el esqueleto la imita para no saltar.
const double _altoFilaTabla = 52;

// Encabezado

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.compacto,
    required this.margen,
    required this.cargando,
    required this.onNuevo,
    required this.onRefrescar,
  });

  final bool compacto;
  final double margen;
  final bool cargando;
  final VoidCallback onNuevo;
  final VoidCallback onRefrescar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: Esp.l,
        runSpacing: Esp.s,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gestión de vehículos',
                style: tt.titleLarge?.copyWith(
                  fontWeight: Peso.dato,
                  letterSpacing: -0.4,
                ),
              ),
              // En un teléfono la bajada cuesta un tercio del alto útil y no
              // dice nada que no se sepa a la segunda visita.
              if (!compacto)
                Text(
                  'Los vehículos de cada sucursal. Dar de baja conserva su '
                  'historial; eliminar solo es posible si nunca se usó.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: cargando ? null : onRefrescar,
                icon: const Icon(Icons.refresh),
                tooltip: 'Volver a traer el listado',
              ),
              if (!compacto) ...[
                const SizedBox(width: Esp.s),
                FilledButton.icon(
                  onPressed: onNuevo,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo vehículo'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// La recarga falló pero hay datos viejos en pantalla: se dejan y se avisa.
class _AvisoRecarga extends StatelessWidget {
  const _AvisoRecarga({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: MensajeError(
      error: error,
      onReintentar: onReintentar,
      compacto: true,
    ),
  );
}

// Lista de móvil

/// Las tarjetas se entregan de a tandas: un teléfono no necesita paginador con
/// números, necesita no cargar de más.
class _ListaMovil extends StatefulWidget {
  const _ListaMovil({
    required this.filas,
    required this.enCurso,
    required this.onEditar,
    required this.onAccion,
  });

  final List<CocheEntity> filas;
  final Set<int> enCurso;
  final void Function(CocheEntity coche) onEditar;
  final void Function(CocheEntity coche, AccionCoche accion) onAccion;

  @override
  State<_ListaMovil> createState() => _ListaMovilState();
}

class _ListaMovilState extends State<_ListaMovil> {
  static const _tanda = 20;
  int _visibles = _tanda;

  @override
  void didUpdateWidget(_ListaMovil anterior) {
    super.didUpdateWidget(anterior);
    // Otro filtro, otra lista: volver a empezar de arriba.
    if (anterior.filas.length != widget.filas.length) _visibles = _tanda;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.filas.length;
    final hasta = _visibles.clamp(0, total);
    final hayMas = hasta < total;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: hasta + 1,
      itemBuilder: (context, i) {
        if (i == hasta) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.m),
            child: Center(
              child:
                  hayMas
                      ? OutlinedButton.icon(
                        onPressed: () => setState(() => _visibles += _tanda),
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: Text('Mostrar más (${total - hasta} restantes)'),
                      )
                      : Text(
                        total == 1 ? '1 vehículo' : '$total vehículos',
                        style: context.apagado(),
                      ),
            ),
          );
        }
        final coche = widget.filas[i];
        return TarjetaCoche(
          coche: coche,
          ocupado: widget.enCurso.contains(coche.idCoche),
          onEditar: () => widget.onEditar(coche),
          onAccion: (a) => widget.onAccion(coche, a),
        );
      },
    );
  }
}
