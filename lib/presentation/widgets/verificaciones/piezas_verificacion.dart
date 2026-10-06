/// Las piezas visuales de «Verificar Cheques»: la pastilla de estado de la
/// verificacion, el importe del cheque, el paginador y la nota del encabezado.
///
/// Usan la misma gramatica del modulo de cheques (`ChequesScope`,
/// `ChequesColores`, `PastillaCheque`, el monograma del banco): el color nunca es
/// el unico canal, cada resaltado lleva texto e icono, y aqui no hay ningun color
/// escrito a mano.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/datos_cheque_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_deposito_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

// ═══════════════════════════════════════════════════════════════════════════
// QUE COLOR LE TOCA A QUE
// ═══════════════════════════════════════════════════════════════════════════

/// El significado de cada estado de verificacion.
///
/// - `Y` valida: exito (el deposito esta comprobado).
/// - `N` anulada: peligro, en su version suave (ya no vale, pero no es un error).
/// - cualquier otro codigo: neutro.
SemanticaCheque semanticaDeVerificacion(String estado) =>
    switch (estado.trim()) {
      VerificacionDepositoEntity.valida => SemanticaCheque.exito,
      VerificacionDepositoEntity.anulada => SemanticaCheque.peligro,
      _ => SemanticaCheque.neutro,
    };

/// El icono de cada estado: asi «Valido» y «Anulado» se distinguen sin el color.
IconData iconoDeVerificacion(String estado) => switch (estado.trim()) {
  VerificacionDepositoEntity.valida => Icons.verified_outlined,
  VerificacionDepositoEntity.anulada => Icons.block,
  _ => Icons.circle_outlined,
};

/// El texto de un estado de verificacion. Sale del codigo y no del texto del
/// procedimiento («Valido» sin tilde): el codigo es lo que manda. Un codigo fuera
/// de `Y` y `N` muestra el texto que dio el servidor.
String textoDeVerificacion(String estado, String textoDelServidor) =>
    switch (estado.trim()) {
      VerificacionDepositoEntity.valida => 'Válida',
      VerificacionDepositoEntity.anulada => 'Anulada',
      _ => textoDelServidor.trim().isEmpty ? '—' : textoDelServidor.trim(),
    };

/// El color de la franja de una fila: el de su estado de verificacion.
Color colorFranjaVerificacion(BuildContext context, String estado) {
  final tono = semanticaDeVerificacion(estado);
  return tono == SemanticaCheque.neutro
      ? Theme.of(context).colorScheme.outlineVariant
      : ChequesColores.pleno(context, tono);
}

// ═══════════════════════════════════════════════════════════════════════════
// PASTILLAS
// ═══════════════════════════════════════════════════════════════════════════

/// El estado de una verificacion: «Válida» en exito, «Anulada» en peligro suave.
class PastillaVerificacion extends StatelessWidget {
  const PastillaVerificacion({
    super.key,
    required this.estado,
    required this.textoDelServidor,
  });

  final String estado;
  final String textoDelServidor;

  @override
  Widget build(BuildContext context) {
    // Se achica en vez de desbordar una columna de ancho fijo con texto grande.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: PastillaCheque(
        texto: textoDeVerificacion(estado, textoDelServidor),
        tono: semanticaDeVerificacion(estado),
        icono: iconoDeVerificacion(estado),
      ),
    );
  }
}

/// «Sin verificar»: lo que le falta a un cheque del modal de pendientes. Va en
/// aviso porque pide una accion.
class PastillaSinVerificar extends StatelessWidget {
  const PastillaSinVerificar({super.key});

  @override
  Widget build(BuildContext context) => const FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: PastillaCheque(
      texto: 'Sin verificar',
      tono: SemanticaCheque.aviso,
      icono: Icons.pending_outlined,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// IMPORTE
// ═══════════════════════════════════════════════════════════════════════════

/// El importe del cheque: la moneda como pastilla (si se conoce) y la cifra en
/// mono, negrita. Si no entra, se achica. Un lector de pantalla oye «Bs
/// 1,500.50» entero. Sin monto, un guion.
class ImporteVerificacion extends StatelessWidget {
  const ImporteVerificacion({
    super.key,
    required this.cheque,
    this.tam = 12.5,
    this.alineacion = Alignment.centerRight,
  });

  final DatosChequeVerificacionEntity cheque;
  final double tam;
  final Alignment alineacion;

  @override
  Widget build(BuildContext context) {
    final monto = cheque.montoCheque;
    if (monto == null) return Text('—', style: context.cifraCheque(tam: tam));
    final unidad = cheque.unidadMoneda;
    final cifra = FormatoMoneda.monto.format(monto);
    return Semantics(
      container: true,
      label: unidad.isEmpty ? cifra : '$unidad $cifra',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alineacion,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unidad.isNotEmpty) ...[
              PastillaMonedaCheque(unidad),
              const SizedBox(width: 6),
            ],
            Text(cifra, style: context.cifraCheque(fuerte: true, tam: tam)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGINADOR
// ═══════════════════════════════════════════════════════════════════════════

/// «Pagina 2 de 7 · 135 verificaciones» y los botones de anterior y siguiente. En
/// anchos chicos los botones bajan a una segunda linea en vez de desbordar.
class PaginadorVerificaciones extends StatelessWidget {
  const PaginadorVerificaciones({
    super.key,
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    required this.singular,
    required this.plural,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final int pagina;
  final int totalPaginas;
  final int total;

  /// «verificación» / «cheque»: el sustantivo del conteo.
  final String singular;
  final String plural;

  /// Null deshabilita el boton (no hay pagina anterior / siguiente).
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Esp.l,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          child: Text(
            'Página $pagina de $totalPaginas · $total ${total == 1 ? singular : plural}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: onAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: onSiguiente,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
