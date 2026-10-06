/// El modal «Cheques pendientes sin regularizar» (el «Nuevo» del legacy): los
/// cheques que todavia no tienen una verificacion valida, con los dos criterios
/// del legacy (estado del cheque y fecha de cobranza) y un «Seleccionar» por
/// cheque abierto.
///
/// Al elegir un cheque el servidor lo vuelve a leer (`preparar`): si mientras
/// tanto lo verifico otro usuario o se cerro, responde con el motivo y la lista se
/// refresca. Al guardar, el modal **sigue abierto** y se actualiza: asi se
/// verifican varios cheques seguidos, como en el legacy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/dialogo_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/lista_pendientes_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/piezas_verificacion.dart';

/// Los dos estados de cheque, por si el catalogo del servidor no llego: el filtro
/// no puede quedar sin opciones. El servidor solo acepta estos dos.
const List<OpcionChequeEntity> _estadosDeRespaldo = [
  OpcionChequeEntity(codigo: 'PEN', nombre: 'PENDIENTE'),
  OpcionChequeEntity(codigo: 'CER', nombre: 'CERRADO'),
];

/// Abre el modal. Devuelve cuando se cierra.
Future<void> abrirPendientesVerificacion(BuildContext context) {
  // El error de una operacion anterior no debe aparecer en un modal nuevo.
  ProviderScope.containerOf(
    context,
  ).read(operacionesVerificacionesProvider.notifier).limpiarError();
  return abrirPanelCheque<void>(
    context,
    anchoMaximo: 1100,
    contenido: (_) => const _PanelPendientes(),
  );
}

class _PanelPendientes extends ConsumerStatefulWidget {
  const _PanelPendientes();

  @override
  ConsumerState<_PanelPendientes> createState() => _PanelPendientesState();
}

class _PanelPendientesState extends ConsumerState<_PanelPendientes> {
  /// El motivo por el que el servidor no dejo preparar el cheque elegido. Es de
  /// este modal y no de las operaciones: el error de guardar vive en el
  /// formulario y no tiene que repetirse aqui, detras.
  String? _errorAlElegir;

  @override
  void initState() {
    super.initState();
    // Despues del primer dibujo: un provider no se toca mientras el arbol se arma.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pendientesVerificacionProvider.notifier).iniciar();
    });
  }

  PendientesVerificacionNotifier get _pendientes =>
      ref.read(pendientesVerificacionProvider.notifier);

  Future<void> _seleccionar(ChequePendienteVerificacionEntity cheque) async {
    final ops = ref.read(operacionesVerificacionesProvider.notifier);
    ops.limpiarError();
    final preparada = await ops.preparar(cheque.codCheque);
    if (!mounted) return;
    if (preparada == null) {
      // El motivo se dibuja arriba del listado, que ya se esta refrescando.
      setState(
        () =>
            _errorAlElegir =
                ref.read(operacionesVerificacionesProvider).error,
      );
      return;
    }
    setState(() => _errorAlElegir = null);
    await abrirVerificacionNueva(context, preparada);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(pendientesVerificacionProvider);
    final ocupado = ref.watch(
      operacionesVerificacionesProvider.select((s) => s.ocupado),
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorAlElegir != null) ...[
          ErrorServidorCheque(_errorAlElegir!),
          const SizedBox(height: Esp.l),
        ],
        _Criterios(
          estado: estado.filtro.estado,
          soloHoy: estado.filtro.soloCobranzaHoy,
          onEstado: (e) {
            setState(() => _errorAlElegir = null);
            _pendientes.elegirEstado(e);
          },
          onSoloHoy: (v) {
            setState(() => _errorAlElegir = null);
            _pendientes.elegirSoloHoy(v);
          },
        ),
        const SizedBox(height: Esp.l),
        _Resultado(
          estado: estado,
          ocupado: ocupado,
          onSeleccionar: _seleccionar,
        ),
      ],
    );

    return MarcoPanelCheque(
      titulo: 'Cheques pendientes sin regularizar',
      subtitulo: 'Elige el cheque cuyo depósito vas a verificar.',
      onCerrar: () => Navigator.of(context).pop(),
      cuerpo: cuerpo,
      acciones: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CRITERIOS
// ═══════════════════════════════════════════════════════════════════════════

class _Criterios extends ConsumerWidget {
  const _Criterios({
    required this.estado,
    required this.soloHoy,
    required this.onEstado,
    required this.onSoloHoy,
  });

  final String? estado;
  final bool soloHoy;
  final ValueChanged<String?> onEstado;
  final ValueChanged<bool> onSoloHoy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estados =
        ref.watch(estadosChequeVerificacionProvider).valueOrNull ?? const [];
    final opciones = estados.isEmpty ? _estadosDeRespaldo : estados;

    final campoEstado = DropdownButtonFormField<String?>(
      key: ValueKey('criterio-estado-$estado-${opciones.length}'),
      value: opciones.any((o) => o.codigo == estado) ? estado : null,
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        for (final o in opciones)
          DropdownMenuItem<String?>(
            value: o.codigo,
            child: Text(o.nombre, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onEstado,
      decoration: const InputDecoration(
        labelText: 'Estado del cheque',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );

    final campoFecha = DropdownButtonFormField<bool>(
      key: ValueKey('criterio-fecha-$soloHoy'),
      value: soloHoy,
      isExpanded: true,
      items: const [
        DropdownMenuItem(
          value: false,
          child: Text(
            'Todos (anteriores y con fecha de cobranza hasta hoy)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: true,
          child: Text(
            'Solo los de fecha de cobranza de hoy',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (v) {
        if (v != null) onSoloHoy(v);
      },
      decoration: const InputDecoration(
        labelText: 'Fecha de cobranza',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [campoEstado, const SizedBox(height: Esp.m), campoFecha],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: campoEstado),
            const SizedBox(width: Esp.m),
            Expanded(flex: 5, child: campoFecha),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULTADO
// ═══════════════════════════════════════════════════════════════════════════

class _Resultado extends ConsumerWidget {
  const _Resultado({
    required this.estado,
    required this.ocupado,
    required this.onSeleccionar,
  });

  final EstadoPendientesVerificacion estado;
  final bool ocupado;
  final AlSeleccionarPendiente onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.read(pendientesVerificacionProvider.notifier);

    if (estado.error != null) {
      return SizedBox(
        height: 260,
        child: ErrorCheques(
          titulo: 'No se pudieron cargar los cheques pendientes',
          texto: estado.error!,
          onReintentar: pendientes.recargar,
        ),
      );
    }
    if (estado.resultado == null) return const _Esqueleto();

    if (estado.filas.isEmpty) {
      final f = estado.filtro;
      return SizedBox(
        height: 260,
        child: MensajeVacio(
          icono: Icons.task_alt_outlined,
          titulo: 'No hay cheques pendientes de verificar con esos criterios',
          detalle:
              f.soloCobranzaHoy
                  ? 'No hay cheques con fecha de cobranza de hoy. Prueba con «Todos (anteriores y con fecha de cobranza hasta hoy)» o cambia el estado.'
                  : 'Todos los cheques con ese estado y cobranza hasta hoy ya tienen una verificación válida.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La barra de carga no mueve la lista: ocupa su sitio siempre.
        SizedBox(
          height: 2,
          child: estado.cargando ? const LinearProgressIndicator(minHeight: 2) : null,
        ),
        const SizedBox(height: Esp.s),
        ListaPendientesVerificacion(
          filas: estado.filas,
          ocupado: ocupado,
          onSeleccionar: onSeleccionar,
          pie: PaginadorVerificaciones(
            pagina: estado.pagina,
            totalPaginas: estado.totalPaginas,
            total: estado.total,
            singular: 'cheque',
            plural: 'cheques',
            onAnterior: estado.hayAnterior ? pendientes.anterior : null,
            onSiguiente: estado.haySiguiente ? pendientes.siguiente : null,
          ),
        ),
      ],
    );
  }
}

/// Bloques grises del alto de las filas que van a llegar: el modal no salta
/// cuando llegan los datos.
class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('esqueleto-pendientes'),
      children: [
        for (var i = 0; i < 4; i++) ...[
          Opacity(
            opacity: 1 - (i * 0.15).clamp(0.0, 0.6),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Esquina.media),
              ),
            ),
          ),
          const SizedBox(height: Esp.s),
        ],
      ],
    );
  }
}
