/// Bancos: la lista de bancos que usan Cheques, Depositos y Pagos al Exterior
/// (tabla `tch_banco`).
///
/// Reemplaza a `tchBanco/banco.xhtml` (tb_vista codVista 43). Cambios respecto
/// del legacy:
///
/// - **Los permisos solo dibujan**: que botones se ven lo resuelve
///   `PermisosBanco`; la puerta que cierra de verdad es la del servidor.
/// - **Un fallo no es una lista vacia**: la lectura propaga los errores y la
///   pantalla ofrece reintentar.
/// - **Tabla en escritorio, tarjetas en movil**, sin scroll horizontal en movil.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart'
    show mensajeDeErrorCheque;
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/presentation/widgets/bancos/dialogos_banco.dart';
import 'package:bosque_flutter/presentation/widgets/bancos/lista_bancos.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

/// Alto de los mensajes de estado dentro del scroll de la pantalla: son
/// `Center(SingleChildScrollView)` y piden una altura acotada.
const double _altoMensaje = 320;

/// Ancho maximo de la lista: pasado esto no gana nada y se lee peor.
const double _anchoMaximoLista = 960;

class BancosScreen extends ConsumerWidget {
  const BancosScreen({super.key});

  void _alElegirAccion(
    BuildContext context,
    WidgetRef ref,
    AccionFilaBanco accion,
    BancoEntity banco,
  ) {
    switch (accion) {
      case AccionFilaBanco.editar:
        abrirFormularioBanco(context, existente: banco);
      case AccionFilaBanco.eliminar:
        eliminarBanco(context, ref, banco);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaBancosProvider);
    final permisos = ref.watch(permisosBancoProvider);
    final ocupado = ref.watch(
      operacionesBancosProvider.select((s) => s.ocupado),
    );

    void recargar() => ref.invalidate(listaBancosProvider);

    // Una recarga con datos ya en pantalla se cuenta con una barra y no con un
    // esqueleto: la lista no desaparece mientras se espera.
    final cargandoConDatos = lectura.isLoading && lectura.hasValue;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final chico = Aire.de(restricciones.maxWidth) == Aire.justo;
          final margen = chico ? Esp.m : Esp.xl;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(
                chico: chico,
                permisos: permisos,
                onRecargar: recargar,
                onNuevo: () => abrirFormularioBanco(context),
              ),
              SizedBox(
                height: 2,
                child:
                    (cargandoConDatos || ocupado)
                        ? const LinearProgressIndicator(minHeight: 2)
                        : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xxl),
                  child: _Cuerpo(
                    lectura: lectura,
                    permisos: permisos,
                    onReintentar: recargar,
                    onAccion:
                        (accion, banco) =>
                            _alElegirAccion(context, ref, accion, banco),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.chico,
    required this.permisos,
    required this.onRecargar,
    required this.onNuevo,
  });

  final bool chico;
  final PermisosBanco permisos;
  final VoidCallback onRecargar;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bancos',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.xs),
        Text(
          'Los bancos que usan Cheques, Depósitos y Pagos al exterior',
          style: context.apagado(),
        ),
      ],
    );

    final recargar = IconButton(
      onPressed: onRecargar,
      icon: const Icon(Icons.refresh),
      tooltip: 'Actualizar',
    );

    final acciones = <Widget>[
      recargar,
      if (permisos.puedeCrear)
        if (chico)
          IconButton.filled(
            onPressed: onNuevo,
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo banco',
          )
        else ...[
          const SizedBox(width: Esp.s),
          FilledButton.icon(
            onPressed: onNuevo,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo'),
          ),
        ],
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        chico ? Esp.m : Esp.xl,
        Esp.l,
        chico ? Esp.s : Esp.xl,
        Esp.m,
      ),
      color: cs.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titulo),
          const SizedBox(width: Esp.s),
          Row(mainAxisSize: MainAxisSize.min, children: acciones),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUERPO: LISTADO O EL ESTADO QUE CORRESPONDA
// ═══════════════════════════════════════════════════════════════════════════

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.lectura,
    required this.permisos,
    required this.onReintentar,
    required this.onAccion,
  });

  final AsyncValue<List<BancoEntity>> lectura;
  final PermisosBanco permisos;
  final VoidCallback onReintentar;
  final AlElegirAccionBanco onAccion;

  @override
  Widget build(BuildContext context) {
    // Un fallo no es «sin bancos»: se dice cual fue y se ofrece reintentar.
    if (lectura.hasError && !lectura.isLoading) {
      return SizedBox(
        height: _altoMensaje,
        child: ErrorCheques(
          titulo: 'No se pudieron cargar los bancos',
          texto: mensajeDeErrorCheque(lectura.error!),
          onReintentar: onReintentar,
        ),
      );
    }

    final bancos = lectura.valueOrNull;
    if (bancos == null) return const _EsqueletoBancos();

    if (bancos.isEmpty) {
      return SizedBox(
        height: _altoMensaje,
        child: MensajeVacio(
          icono: Icons.account_balance_outlined,
          titulo: 'Todavía no hay bancos registrados',
          detalle:
              permisos.puedeCrear
                  ? 'Registra el primero con «Nuevo».'
                  : 'Cuando se registre el primero aparecerá aquí.',
        ),
      );
    }

    // Dos datos por fila: en una pantalla ancha, el nombre y sus acciones
    // quedarian a mil pixeles uno del otro y el ojo pierde la fila.
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _anchoMaximoLista),
        child: ListaBancos(
          bancos: bancos,
          permisos: permisos,
          onAccion: onAccion,
        ),
      ),
    );
  }
}

/// Bloques grises del alto de las filas que van a llegar: la pagina no salta
/// cuando llegan los datos. Sin animacion: es solo para la primera carga.
class _EsqueletoBancos extends StatelessWidget {
  const _EsqueletoBancos();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('esqueleto-bancos'),
      children: [
        for (var i = 0; i < 6; i++) ...[
          Opacity(
            opacity: 1 - (i * 0.12).clamp(0.0, 0.6),
            child: Container(
              height: 56,
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
