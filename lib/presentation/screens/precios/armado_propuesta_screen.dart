/// El asistente para armar una propuesta de precios: "Nueva propuesta" y el
/// "Editar" de una propuesta pendiente.
///
/// Reemplaza a la cadena de dialogos de Autorizacion.xhtml -`dlgNuevo`,
/// `dlgProd`, `dlgVista`, `dlgArtD` y el "Agregar Mas Familias" de
/// `dlgPropEditar`-, que se abrian uno encima del otro sobre el mismo
/// ManagedBean y obligaban a recordar lo cargado en el anterior.
///
/// Son tres pasos, en el orden en que se piensa una propuesta:
///
/// 1. **Datos**: el tipo, el titulo, las observaciones y, si es por familias,
///    el flete de cada sucursal.
/// 2. **Contenido**: las familias con su costo -el precio de cada lista lo
///    calcula el servidor- o los articulos.
/// 3. **Revision**: lo que quedo armado y el envio a autorizar.
///
/// **No es una ruta del router.** Se abre encima del listado con
/// `Navigator.push`, igual que el detalle de una propuesta: no tiene sentido
/// entrar a un asistente a medio armar desde el menu ni desde una URL, y asi no
/// hace falta una fila en tb_vista para una pantalla que no es de menu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/armado_propuesta_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_paso_articulos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_paso_datos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_paso_familias.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_paso_revision.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';

/// Abre el asistente para una propuesta nueva.
Future<void> abrirArmadoNuevo(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const ArmadoPropuestaScreen()));

/// Abre el asistente sobre una propuesta pendiente: el "Editar" del listado.
Future<void> abrirArmadoExistente(
  BuildContext context,
  PropuestaEnAutorizacion fila,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(builder: (_) => ArmadoPropuestaScreen(existente: fila)),
);

class ArmadoPropuestaScreen extends ConsumerStatefulWidget {
  const ArmadoPropuestaScreen({super.key, this.existente});

  /// La propuesta pendiente que se sigue armando. Null = propuesta nueva.
  final PropuestaEnAutorizacion? existente;

  @override
  ConsumerState<ArmadoPropuestaScreen> createState() =>
      _ArmadoPropuestaScreenState();
}

class _ArmadoPropuestaScreenState extends ConsumerState<ArmadoPropuestaScreen> {
  /// El notifier se inicia despues del primer cuadro -no se puede tocar
  /// durante la construccion del arbol-. Hasta entonces se muestra la espera,
  /// para no dibujar un cuadro con el estado de una propuesta nueva cuando se
  /// abrio una existente.
  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(armadoProvider.notifier);
      final existente = widget.existente;
      if (existente == null) {
        notifier.iniciarNueva();
      } else {
        notifier.abrirExistente(
          idPropuesta: existente.idPropuesta,
          tipo: TipoArmado.desdeCodigo(existente.propuesta.tipo),
          titulo: existente.titulo,
        );
      }
      setState(() => _iniciado = true);
    });
  }

  void _cerrar() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estado = ref.watch(armadoProvider);

    // Mientras guarda no se sale. Un lote de familias viaja en tandas y la
    // propuesta nace con la primera: salir a mitad dejaba las tandas que
    // faltaban sin el id, y cada una creaba otra propuesta.
    return PopScope(
      canPop: !estado.ocupado,
      onPopInvokedWithResult: (yaSalio, _) {
        if (!yaSalio && ref.read(armadoProvider).ocupado) {
          mostrarAviso(
            context,
            'Espere a que termine de guardar para salir.',
            tono: TonoAviso.aviso,
          );
        }
      },
      child: GuardiaDeSalida(
        hayCambios: _iniciado && estado.hayCambiosSinGuardar && !estado.ocupado,
        mensaje:
            estado.existe
                ? 'Los fletes que cambió todavía no se guardaron.'
                : 'La propuesta todavía no existe: se crea al guardar la primera '
                    'familia o el primer artículo. Si sale ahora se pierden el '
                    'título y las observaciones.',
        child: Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: LayoutBuilder(
              // El ancho del cajon: adentro del dashboard el menu lateral se come
              // su parte y MediaQuery contaria la ventana entera.
              builder: (context, restricciones) {
                final aire = Aire.de(restricciones.maxWidth);
                if (!_iniciado) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Encabezado(aire: aire, estado: estado, onCerrar: _cerrar),
                    _IndicadorPasos(aire: aire, estado: estado),
                    SizedBox(
                      height: 2,
                      child:
                          estado.ocupado
                              ? const LinearProgressIndicator(minHeight: 2)
                              : null,
                    ),
                    Divider(height: 1, color: cs.outlineVariant),
                    Expanded(child: _contenido(aire, estado)),
                    Divider(height: 1, color: cs.outlineVariant),
                    _BarraAcciones(
                      aire: aire,
                      estado: estado,
                      onCerrar: _cerrar,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(Aire aire, EstadoArmado estado) => switch (estado.paso) {
    PasoArmado.datos => ArmadoPasoDatos(aire: aire),
    PasoArmado.contenido =>
      estado.esPorFamilia
          ? ArmadoPasoFamilias(aire: aire)
          : ArmadoPasoArticulos(aire: aire),
    PasoArmado.revision => ArmadoPasoRevision(aire: aire, onTerminar: _cerrar),
  };
}

double _margen(Aire aire) => switch (aire) {
  Aire.justo => Esp.m,
  Aire.medio => Esp.l,
  Aire.amplio => Esp.xl,
};

/// El nombre del segundo paso depende del tipo.
String _etiquetaPaso(PasoArmado paso, EstadoArmado estado) =>
    paso == PasoArmado.contenido
        ? (estado.esPorFamilia ? 'Familias' : 'Artículos')
        : paso.etiqueta;

// ═══════════════════════════════════════════════════════════════════════════
// ENCABEZADO
// ═══════════════════════════════════════════════════════════════════════════

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.aire,
    required this.estado,
    required this.onCerrar,
  });

  final Aire aire;
  final EstadoArmado estado;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final titulo =
        estado.existe
            ? 'Propuesta N.º ${estado.idPropuesta}'
            : 'Nueva propuesta de precios';
    final bajada =
        estado.existe
            ? '${estado.tipo.etiqueta} · Pendiente'
                '${estado.titulo.trim().isEmpty ? '' : ' · ${estado.titulo.trim()}'}'
            : estado.esPorFamilia
            ? 'Se crea al guardar la primera familia.'
            : 'Se crea al agregar el primer artículo.';

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(
        _margen(aire),
        Esp.m,
        _margen(aire) - Esp.s,
        Esp.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: Peso.dato,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: Esp.xs),
                Text(
                  bajada,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar el asistente',
            onPressed: onCerrar,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PASOS
// ═══════════════════════════════════════════════════════════════════════════

/// Que se hace en cada paso, en una linea: el rotulo solo ("Datos") no lo dice.
String _detallePaso(PasoArmado paso, EstadoArmado estado) => switch (paso) {
  PasoArmado.datos => 'Tipo, título y fletes',
  PasoArmado.contenido =>
    estado.esPorFamilia ? 'El costo de cada familia' : 'Los artículos nuevos',
  PasoArmado.revision => 'Revisar y enviar a autorizar',
};

IconData _iconoPaso(PasoArmado paso, EstadoArmado estado) => switch (paso) {
  PasoArmado.datos => Icons.description_outlined,
  PasoArmado.contenido =>
    estado.esPorFamilia ? Icons.inventory_2_outlined : Icons.category_outlined,
  PasoArmado.revision => Icons.fact_check_outlined,
};

/// Donde se esta y cuanto falta.
///
/// En pantallas anchas son tres tarjetas centradas sobre el contenido -no tres
/// circulos en los extremos de una linea que cruzaba la ventana entera-: cada una
/// dice el numero, el nombre y que se hace en el paso. En el telefono, una barra
/// de progreso en tres tramos con el paso actual escrito debajo: tres tarjetas no
/// entran en 360 px.
class _IndicadorPasos extends ConsumerWidget {
  const _IndicadorPasos({required this.aire, required this.estado});

  final Aire aire;
  final EstadoArmado estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final actual = estado.paso.index;

    if (aire.esChico) {
      return _PasosCompactos(aire: aire, estado: estado);
    }

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(_margen(aire), Esp.xs, _margen(aire), Esp.m),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Row(
          children: [
            for (final paso in PasoArmado.values) ...[
              if (paso.index > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color:
                        paso.index <= actual ? cs.primary : cs.outlineVariant,
                  ),
                ),
              Expanded(
                child: _TarjetaPaso(
                  numero: paso.index + 1,
                  etiqueta: _etiquetaPaso(paso, estado),
                  detalle: _detallePaso(paso, estado),
                  icono: _iconoPaso(paso, estado),
                  hecho: paso.index < actual,
                  actual: paso.index == actual,
                  // Solo se vuelve para atras con el indicador: avanzar pide
                  // cumplir lo del paso, y eso lo decide la barra de abajo.
                  onTap:
                      paso.index < actual && !estado.ocupado
                          ? () => ref.read(armadoProvider.notifier).irA(paso)
                          : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaPaso extends StatelessWidget {
  const _TarjetaPaso({
    required this.numero,
    required this.etiqueta,
    required this.detalle,
    required this.icono,
    required this.hecho,
    required this.actual,
    this.onTap,
  });

  final int numero;
  final String etiqueta;
  final String detalle;
  final IconData icono;
  final bool hecho;
  final bool actual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final fondo =
        actual
            ? cs.primaryContainer
            : (hecho ? cs.surfaceContainerLowest : cs.surfaceContainerLow);
    final borde =
        actual
            ? cs.primary
            : (hecho ? cs.primary.withValues(alpha: 0.45) : cs.outlineVariant);
    final tinta = actual ? cs.onPrimaryContainer : cs.onSurface;
    final estado = hecho ? 'LISTO' : (actual ? 'EN CURSO' : 'PENDIENTE');

    final tarjeta = Material(
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: borde, width: actual ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.m,
            vertical: Esp.s + 2,
          ),
          child: Row(
            children: [
              _CirculoPaso(icono: icono, hecho: hecho, actual: actual),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PASO $numero · $estado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                        fontWeight: Peso.titulo,
                        letterSpacing: 0.8,
                        color:
                            actual || hecho ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: actual ? Peso.dato : Peso.titulo,
                        color: hecho || actual ? tinta : cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color:
                            actual
                                ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                                : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return onTap == null
        ? tarjeta
        : Tooltip(message: 'Volver a $etiqueta', child: tarjeta);
  }
}

/// El icono del paso en un circulo: lleno si es el actual (con un halo), con un
/// tilde si ya se hizo y apagado si falta.
class _CirculoPaso extends StatelessWidget {
  const _CirculoPaso({
    required this.icono,
    required this.hecho,
    required this.actual,
  });

  final IconData icono;
  final bool hecho;
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lleno = hecho || actual;

    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: actual ? cs.primary.withValues(alpha: 0.18) : Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lleno ? cs.primary : cs.surfaceContainerHighest,
          border: lleno ? null : Border.all(color: cs.outlineVariant, width: 1),
        ),
        child: Icon(
          hecho ? Icons.check_rounded : icono,
          size: 18,
          color: lleno ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// En el telefono: tres tramos de progreso y, debajo, el paso actual.
class _PasosCompactos extends StatelessWidget {
  const _PasosCompactos({required this.aire, required this.estado});

  final Aire aire;
  final EstadoArmado estado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final actual = estado.paso.index;
    final total = PasoArmado.values.length;

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(_margen(aire), 0, _margen(aire), Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final paso in PasoArmado.values) ...[
                if (paso.index > 0) const SizedBox(width: Esp.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          paso.index <= actual
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Esp.s),
          Row(
            children: [
              _CirculoPaso(
                icono: _iconoPaso(estado.paso, estado),
                hecho: false,
                actual: true,
              ),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PASO ${actual + 1} DE $total',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: Peso.titulo,
                        letterSpacing: 0.8,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      _etiquetaPaso(estado.paso, estado),
                      style: tt.titleSmall?.copyWith(fontWeight: Peso.dato),
                    ),
                    Text(
                      _detallePaso(estado.paso, estado),
                      style: context.apagado(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BARRA DE ACCIONES
// ═══════════════════════════════════════════════════════════════════════════

/// Atras, adelante y, a la izquierda, por que no se puede avanzar.
///
/// El motivo va escrito y no en un tooltip: en el telefono no hay hover, y un
/// boton apagado sin explicacion se lee como una falla.
class _BarraAcciones extends ConsumerWidget {
  const _BarraAcciones({
    required this.aire,
    required this.estado,
    required this.onCerrar,
  });

  final Aire aire;
  final EstadoArmado estado;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(armadoProvider.notifier);

    final (
      String? motivo,
      VoidCallback adelante,
      String etiqueta,
    ) = switch (estado.paso) {
      PasoArmado.datos => (
        estado.fletesModificados
            ? 'Guarde o descarte los cambios de fletes para seguir.'
            : estado.faltaEnDatos,
        () => notifier.irA(PasoArmado.contenido),
        estado.esPorFamilia ? 'Familias' : 'Artículos',
      ),
      PasoArmado.contenido => (
        estado.existe
            ? null
            : estado.esPorFamilia
            ? 'Guarde al menos una familia para seguir.'
            : 'Agregue al menos un artículo para seguir.',
        () => notifier.irA(PasoArmado.revision),
        'Revisar',
      ),
      PasoArmado.revision => (null, onCerrar, 'Terminar'),
    };

    final atras = switch (estado.paso) {
      PasoArmado.datos => null,
      PasoArmado.contenido => () => notifier.irA(PasoArmado.datos),
      PasoArmado.revision => () => notifier.irA(PasoArmado.contenido),
    };

    final habilitado = motivo == null && !estado.ocupado;
    final esUltimo = estado.paso == PasoArmado.revision;

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(_margen(aire), Esp.s, _margen(aire), Esp.s),
      child: Row(
        children: [
          if (atras != null)
            aire.esChico
                ? IconButton(
                  tooltip: 'Paso anterior',
                  onPressed: estado.ocupado ? null : atras,
                  icon: const Icon(Icons.arrow_back),
                )
                : TextButton.icon(
                  onPressed: estado.ocupado ? null : atras,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Atrás'),
                )
          else
            TextButton(onPressed: onCerrar, child: const Text('Cancelar')),
          const SizedBox(width: Esp.s),
          Expanded(
            child:
                motivo == null
                    ? const SizedBox()
                    : Text(
                      motivo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: context.apagado(),
                    ),
          ),
          const SizedBox(width: Esp.m),
          FilledButton.icon(
            onPressed: habilitado ? adelante : null,
            // La flecha va del lado al que se avanza.
            iconAlignment: esUltimo ? IconAlignment.start : IconAlignment.end,
            icon: Icon(esUltimo ? Icons.check : Icons.arrow_forward, size: 18),
            label: Text(etiqueta),
          ),
        ],
      ),
    );
  }
}
