/// Las piezas visuales del modulo de cheques: pastillas de estado, de situacion
/// de cobro, de moneda y de tipo, el importe, el monograma del banco, la franja
/// de acento de una fila y el color de cada accion del historial.
///
/// **El color nunca es el unico canal**: cada resaltado lleva texto y, cuando
/// ayuda, un icono. Los colores con significado salen de `ChequesColores` (tonos
/// fijos que no cambian con la semilla) y los de marca, del `ColorScheme`; aqui
/// no hay ningun color escrito a mano.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/resumen_cheques.dart';
import 'package:bosque_flutter/domain/utils/situacion_cheque.dart';

// ═══════════════════════════════════════════════════════════════════════════
// QUE COLOR LE TOCA A QUE
// ═══════════════════════════════════════════════════════════════════════════

/// El significado de cada situacion de cobro.
///
/// - cerrado: exito (ya esta resuelto).
/// - atrasado: peligro (paso la fecha y sigue pendiente).
/// - cobra hoy: aviso (hay que ir a cobrarlo hoy).
/// - por cobrar (1 a 7 dias): info (se acerca, sin urgir).
/// - vigente y sin fecha: neutro (lo comun no se pinta).
SemanticaCheque semanticaDeSituacion(SituacionCheque s) => switch (s) {
  SituacionCheque.cerrado => SemanticaCheque.exito,
  SituacionCheque.atrasado => SemanticaCheque.peligro,
  SituacionCheque.cobraHoy => SemanticaCheque.aviso,
  SituacionCheque.porCobrar => SemanticaCheque.info,
  SituacionCheque.vigente => SemanticaCheque.neutro,
  SituacionCheque.sinFecha => SemanticaCheque.neutro,
};

/// El color de la franja de una fila. Lo comun (vigente, sin fecha) va con el
/// trazo tenue de las superficies para que lo importante sea lo que resalte.
Color colorFranjaCheque(BuildContext context, SituacionCheque s) {
  final tono = semanticaDeSituacion(s);
  return tono == SemanticaCheque.neutro
      ? Theme.of(context).colorScheme.outlineVariant
      : ChequesColores.pleno(context, tono);
}

/// El significado de cada estado de accion del historial.
///
/// Se agrupan por lo que le pasa al cheque, no uno por uno:
///
/// - **info** (el cheque se mueve entre manos): `REC` recibido, `TRASP`
///   traspaso, `DPB` depositado en banco.
/// - **aviso** (esta en curso o cambio de plazo): `CUS` a cobranza, `VEN`
///   postergado, `ADE` adelantado, `PAP` pago parcial (cierra, pero sin cobrar
///   todo).
/// - **peligro** (algo salio mal): `DEV` devuelto, `DPR` depositado-rechazado
///   (cierra, pero por rechazo).
/// - **exito** (se cobro): `COB`, `CEF`, `CCH` y `VER` verificado.
///
/// El brief pedia todos los cierres en exito; `PAP` y `DPR` se separan porque
/// pintar de verde un deposito rechazado diria lo contrario de lo que paso. El
/// estado del *cheque* si es exito en cualquier cierre. Un codigo fuera del
/// catalogo va en neutro.
SemanticaCheque semanticaDeAccion(String estado) => switch (estado.trim()) {
  'REC' || 'TRASP' || 'DPB' => SemanticaCheque.info,
  'CUS' || 'VEN' || 'ADE' || 'PAP' => SemanticaCheque.aviso,
  'DEV' || 'DPR' => SemanticaCheque.peligro,
  'COB' || 'CEF' || 'CCH' || 'VER' => SemanticaCheque.exito,
  _ => SemanticaCheque.neutro,
};

/// El icono de cada estado de accion: asi dos estados del mismo color (`CUS` y
/// `VEN`, por ejemplo) se distinguen sin mirar el texto.
IconData iconoDeAccion(String estado) => switch (estado.trim()) {
  'REC' => Icons.inbox_outlined,
  'TRASP' => Icons.swap_horiz,
  'CUS' => Icons.how_to_reg_outlined,
  'DEV' => Icons.undo,
  'VEN' => Icons.event_repeat_outlined,
  'ADE' => Icons.event_available_outlined,
  'COB' => Icons.task_alt,
  'CEF' => Icons.payments_outlined,
  'CCH' => Icons.receipt_long_outlined,
  'PAP' => Icons.pie_chart_outline,
  'DPR' => Icons.cancel_outlined,
  'DPB' => Icons.account_balance_outlined,
  'VER' => Icons.verified_outlined,
  _ => Icons.circle_outlined,
};

IconData? _iconoDeSituacion(SituacionCheque s) => switch (s) {
  SituacionCheque.atrasado => Icons.warning_amber_rounded,
  SituacionCheque.cobraHoy => Icons.today_outlined,
  SituacionCheque.porCobrar => Icons.schedule,
  SituacionCheque.sinFecha => Icons.event_busy_outlined,
  _ => null,
};

// ═══════════════════════════════════════════════════════════════════════════
// PASTILLA
// ═══════════════════════════════════════════════════════════════════════════

/// Una pastilla de estado. [fuerte] la llena del tono pleno (lo urgente); sin
/// ella es suave. [punto] pone un circulo de color antes del texto.
class PastillaCheque extends StatelessWidget {
  const PastillaCheque({
    super.key,
    required this.texto,
    required this.tono,
    this.icono,
    this.punto = false,
    this.fuerte = false,
  });

  final String texto;
  final SemanticaCheque tono;
  final IconData? icono;
  final bool punto;
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    final fondo =
        fuerte
            ? ChequesColores.fondoFuerte(context, tono)
            : ChequesColores.fondo(context, tono);
    final letra =
        fuerte
            ? ChequesColores.textoFuerte(context, tono)
            : ChequesColores.texto(context, tono);
    final borde = ChequesColores.pleno(context, tono);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
        border: fuerte ? null : Border.all(color: borde.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (punto) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: fuerte ? letra : borde,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: 6),
            ],
            if (icono != null) ...[
              Icon(icono, size: 13, color: letra),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: letra,
                  fontWeight: Peso.dato,
                  letterSpacing: 0.2,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La situacion de cobro como pastilla: lo urgente (atrasado, cobra hoy) va
/// llena; lo que se acerca, suave. Un cheque cerrado no lleva esta pastilla (el
/// estado ya lo dice).
class PastillaSituacionCheque extends StatelessWidget {
  const PastillaSituacionCheque({super.key, required this.situacion});

  final SituacionDeCheque situacion;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: situacion.textoLargo,
      child: PastillaCheque(
        texto: situacion.texto,
        tono: semanticaDeSituacion(situacion.situacion),
        icono: _iconoDeSituacion(situacion.situacion),
        fuerte: situacion.esUrgente,
      ),
    );
  }
}

/// La situacion de cobro como texto chico bajo la fecha, en el color de su
/// significado («Atrasado 12 d» en coral). Lo comun (vigente) va tenue.
class TextoSituacionCheque extends StatelessWidget {
  const TextoSituacionCheque({super.key, required this.situacion});

  final SituacionDeCheque situacion;

  @override
  Widget build(BuildContext context) {
    final s = situacion.situacion;
    if (s == SituacionCheque.cerrado || s == SituacionCheque.sinFecha) {
      return const SizedBox.shrink();
    }
    final tono = semanticaDeSituacion(s);
    final color = ChequesColores.texto(context, tono);
    final icono = _iconoDeSituacion(s);
    return Tooltip(
      message: situacion.textoLargo,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              situacion.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: situacion.esUrgente ? Peso.dato : Peso.titulo,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El estado de una accion del historial: su nombre en el color y con el icono
/// de [semanticaDeAccion] e [iconoDeAccion].
class PastillaAccionCheque extends StatelessWidget {
  const PastillaAccionCheque({
    super.key,
    required this.estado,
    required this.nombre,
  });

  final String estado;
  final String nombre;

  @override
  Widget build(BuildContext context) => PastillaCheque(
    texto: nombre,
    tono: semanticaDeAccion(estado),
    icono: iconoDeAccion(estado),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MONEDA E IMPORTE
// ═══════════════════════════════════════════════════════════════════════════

/// «Bs» y «$us» en tonos distintos. La moneda no es un estado: se tine con los
/// colores de marca del tema (principal y terciario), que no compiten con los de
/// significado.
class PastillaMonedaCheque extends StatelessWidget {
  const PastillaMonedaCheque(this.unidad, {super.key});

  final String unidad;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra) = switch (unidad) {
      'Bs' => (cs.primaryContainer, cs.onPrimaryContainer),
      r'$us' => (cs.tertiaryContainer, cs.onTertiaryContainer),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          unidad,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: letra,
            fontWeight: Peso.dato,
            letterSpacing: 0.3,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

/// El importe de un cheque: la moneda como pastilla y la cifra en mono, negrita.
/// Si no entra, se achica en vez de desbordar. Un lector de pantalla oye
/// «Bs 1,500.50» entero.
class ImporteCheque extends StatelessWidget {
  const ImporteCheque({
    super.key,
    required this.cheque,
    this.tam = 12.5,
    this.alineacion = Alignment.centerRight,
  });

  final ChequeFilaEntity cheque;

  /// Tamano de la cifra.
  final double tam;
  final Alignment alineacion;

  @override
  Widget build(BuildContext context) {
    final monto = cheque.cheque.monto;
    if (monto == null) {
      return Text('—', style: context.cifraCheque(tam: tam));
    }
    final unidad = unidadDeMonedaCheque(cheque);
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
// BANCO
// ═══════════════════════════════════════════════════════════════════════════

/// Palabras que no distinguen a un banco de otro: «Banco Union» y «Banco Bisa»
/// son «UN» y «BI», no dos «BA».
const Set<String> _palabrasGenericas = {
  'BANCO',
  'BCO',
  'DE',
  'DEL',
  'LA',
  'LAS',
  'EL',
  'LOS',
  'Y',
  'S',
  'A',
  'SA',
};

/// Las dos letras de un banco: las iniciales de sus dos primeras palabras con
/// significado, o las dos primeras letras si solo hay una.
String monogramaDeBanco(String nombre) {
  final palabras =
      nombre
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÑÜ0-9 ]'), ' ')
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
  final utiles = palabras.where((p) => !_palabrasGenericas.contains(p)).toList();
  final fuente = utiles.isEmpty ? palabras : utiles;
  if (fuente.isEmpty) return '?';
  if (fuente.length == 1) {
    final p = fuente.first;
    return p.length == 1 ? p : p.substring(0, 2);
  }
  return fuente[0][0] + fuente[1][0];
}

/// Un numero estable por nombre: el mismo banco cae siempre en el mismo color.
/// **No es `String.hashCode`**: no esta garantizado entre plataformas, y en la
/// web un hash de 32 bits multiplicado pierde precision. Este se queda en 31
/// bits y da lo mismo en el telefono, en el escritorio y en el navegador.
int indiceDeBanco(String nombre) {
  final limpio = nombre.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  var h = 7;
  for (final c in limpio.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return h;
}

/// Circulo de dos letras con el color estable del banco (`colorDeCatalogo`).
///
/// La letra se elige entre blanco y negro por contraste y no con el `texto` de
/// `colorDeCatalogo`: ese usa grises suaves y en los tonos medios queda por
/// debajo de 4,5:1.
class MonogramaBanco extends StatelessWidget {
  const MonogramaBanco(this.nombre, {super.key, this.tam = 28});

  final String nombre;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo = colorDeCatalogo(cs, indiceDeBanco(nombre) % 9).fondo;
    final letra = letraSobre(fondo);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fondo,
          shape: BoxShape.circle,
          border: Border.all(color: letra.withValues(alpha: 0.22)),
        ),
        child: SizedBox.square(
          dimension: tam,
          child: Center(
            child: Text(
              monogramaDeBanco(nombre),
              maxLines: 1,
              style: TextStyle(
                color: letra,
                fontSize: tam * 0.38,
                fontWeight: Peso.dato,
                letterSpacing: 0.2,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blanco o negro sobre [fondo], el que de mas contraste: en el peor caso
/// (luminancia media) llega a 4,58:1, por encima del 4,5 que se exige.
Color letraSobre(Color fondo) {
  return ChequesColores.contraste(fondo, Colors.black) >=
          ChequesColores.contraste(fondo, Colors.white)
      ? Colors.black
      : Colors.white;
}

/// El banco: monograma y nombre. Con poco ancho (la tabla apretada) el
/// monograma se va y queda el nombre, que es el dato.
class BancoCheque extends StatelessWidget {
  const BancoCheque(this.nombre, {super.key, this.lineas = 3, this.tam = 22});

  final String nombre;
  final int lineas;

  /// Diametro del monograma.
  final double tam;

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      nombre.trim().isEmpty ? '—' : nombre.trim(),
      maxLines: lineas,
      overflow: TextOverflow.ellipsis,
      // 13 y no 14: con el monograma al lado quedan unos 85 px y «ECONOMICO» a
      // 14 se partia a mitad de palabra.
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
    );
    return LayoutBuilder(
      builder: (context, c) {
        // Con menos de ~128 px el nombre queda en 85 y una palabra como
        // «ECONOMICO» se parte a mitad: el monograma cede, el nombre no.
        final conMonograma = c.maxWidth >= 128 && nombre.trim().isNotEmpty;
        return Tooltip(
          message: nombre.trim(),
          child: Row(
            children: [
              if (conMonograma) ...[
                MonogramaBanco(nombre, tam: tam),
                const SizedBox(width: 6),
              ],
              Expanded(child: texto),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIPO Y ENTREGADO POR
// ═══════════════════════════════════════════════════════════════════════════

/// Un cheque de respaldo (garantia), que es la excepcion: 9 entre ~9.700.
bool esChequeRespaldo(ChequeFilaEntity c) =>
    (c.descTipo ?? '').trim().toUpperCase() == 'RESPALDO' ||
    (c.cheque.tipo ?? '').trim() == 'RES';

/// El tipo del cheque: lo comun (PAGO) callado, lo excepcional (RESPALDO)
/// resaltado. Sin descripcion (el JOIN no la encontro) va un guion, nunca el
/// codigo crudo.
class TipoCheque extends StatelessWidget {
  const TipoCheque(this.cheque, {super.key});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context) {
    final desc = (cheque.descTipo ?? '').trim();
    if (esChequeRespaldo(cheque)) {
      // Se achica en vez de cortar la palabra en una columna angosta.
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: PastillaCheque(
          texto: desc.isEmpty ? 'RESPALDO' : desc,
          tono: SemanticaCheque.info,
          icono: Icons.shield_outlined,
        ),
      );
    }
    return Text(
      desc.isEmpty ? '—' : desc,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Quien entrego el cheque: el cliente, atenuado y con icono de persona; un
/// empleado, normal y con icono de credencial.
class EntregadoPorCheque extends StatelessWidget {
  const EntregadoPorCheque({
    super.key,
    required this.cheque,
    required this.texto,
    this.lineas = 2,
  });

  final ChequeFilaEntity cheque;

  /// Ya sin los guiones de adorno (`textoEntregadoPor`).
  final String texto;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final delCliente =
        cheque.cheque.loEntregoElCliente ||
        texto.toLowerCase().contains('cliente');
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: delCliente ? cs.onSurfaceVariant : null,
    );
    return Tooltip(
      message: texto,
      child: Row(
        children: [
          Icon(
            delCliente ? Icons.person_outline : Icons.badge_outlined,
            size: 16,
            color: delCliente ? cs.onSurfaceVariant : cs.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              maxLines: lineas,
              overflow: TextOverflow.ellipsis,
              style: estilo,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FRANJA DE ACENTO
// ═══════════════════════════════════════════════════════════════════════════

/// La franja de 4 px al borde izquierdo de una fila o tarjeta.
class FranjaCheque extends StatelessWidget {
  const FranjaCheque({super.key, required this.color, this.ancho = 4});

  final Color color;
  final double ancho;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: ColoredBox(color: color, child: SizedBox(width: ancho)));
}
