/// Piezas visuales del modulo de garantias de cobranza.
///
/// **La idea que ordena la pantalla:** una garantia es un documento con plazo.
/// Lo que el oficial de cobranza necesita saber de un vistazo es cuanto le
/// queda y si la linea de credito que respalda coincide con SAP. Por eso la
/// pieza que se repite en todo el modulo es [BarraVigencia] —el plazo como una
/// regla que se va llenando, con la cuenta regresiva al lado— y el color se
/// reserva para el estado: vigente, por vencer, vencida, cerrada. Todo sale
/// del ColorScheme, porque el usuario elige la semilla del tema.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/theme/garantias_tema.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';

// Todo archivo del modulo importa este: asi recibe el tema, los colores de
// estado y el estilo de cifras sin repetir el import.
export 'package:bosque_flutter/core/theme/garantias_tema.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BOTONES DE LA VISTA 45 (tb_vistaBtn)
//
// Los mismos nombres que evaluaba wGarantiaCbr.esAutorizado(...) en la
// pantalla JSF: no hay que dar de alta ningun permiso nuevo.
// ═══════════════════════════════════════════════════════════════════════════

abstract final class BtnGarantias {
  static const String nueva = 'btnNewGarCbr';
  static const String editar = 'btnEditGarCbr';
  static const String editarAdm = 'btnEditAdmGarCbr';
  static const String traspaso = 'btnTraspGarCbr';
  static const String reporte = 'btnRptGaCbr';
  static const String recibo = 'btnRptUltGarCbr';
  static const String verCliente = 'btnSCGarCbr';
  static const String nuevaAccion = 'btnNewAcCbr';
  static const String editarAccion = 'btnEditAcCbr';
  static const String eliminarAccion = 'btnDelAcCbr';
  static const String extension = 'btnExtAcCbr';
}

// ═══════════════════════════════════════════════════════════════════════════
// FORMATOS
// ═══════════════════════════════════════════════════════════════════════════

/// Monto con separador de miles y dos decimales, sin moneda: la garantia no
/// guarda moneda y el legacy tampoco la mostraba.
String monto(num? v) => v == null ? '--' : FormatoMoneda.monto.format(v);

/// Espacio que no se corta: un numero y su palabra («3 caducadas», «1600
/// días») quedan en la misma linea aunque el texto salte.
const String espacioFijo = ' ';

/// «faltan 23 días», «vence hoy», «venció hace 4 días».
String cuentaRegresiva(int? dias) {
  if (dias == null) return 'Sin vencimiento';
  if (dias == 0) return 'Vence hoy';
  if (dias == 1) return 'Falta 1${espacioFijo}día';
  if (dias > 1) return 'Faltan $dias${espacioFijo}días';
  final n = -dias;
  return n == 1 ? 'Venció ayer' : 'Venció hace $n${espacioFijo}días';
}

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO
// ═══════════════════════════════════════════════════════════════════════════

/// Tono del estado de una garantia. «Por vencer» no es un estado del backend:
/// es una vigente a 30 dias o menos, y merece su propio color porque es la
/// que hay que renovar.
enum TonoGarantia { vigente, porVencer, caducada, cerrada }

TonoGarantia tonoDe(GarantiaVistaEntity g) {
  if (g.estaCerrada) return TonoGarantia.cerrada;
  if (g.estaCaducada) return TonoGarantia.caducada;
  if (g.porVencer) return TonoGarantia.porVencer;
  return TonoGarantia.vigente;
}

/// Que significa cada tono, en los colores del modulo ([GarantiasColores]).
Semantica semanticaDe(TonoGarantia t) => switch (t) {
  TonoGarantia.vigente => Semantica.exito,
  TonoGarantia.porVencer => Semantica.aviso,
  TonoGarantia.caducada => Semantica.peligro,
  TonoGarantia.cerrada => Semantica.neutro,
};

/// Color pleno del tono, para la barra de vigencia y los acentos.
Color colorDeTono(BuildContext context, TonoGarantia t) =>
    GarantiasColores.pleno(context, semanticaDe(t));

/// Color de aviso del modulo (ambar) para cifras e iconos: linea distinta de
/// SAP, documentos que no suman. Reemplaza al terciario de la semilla.
Color colorAviso(BuildContext context) =>
    GarantiasColores.texto(context, Semantica.aviso);

Semantica _semanticaEtiqueta(TonoEtiqueta t) => switch (t) {
  TonoEtiqueta.exito => Semantica.exito,
  TonoEtiqueta.aviso => Semantica.aviso,
  TonoEtiqueta.error => Semantica.peligro,
  TonoEtiqueta.neutro => Semantica.neutro,
};

/// Pastilla de estado del modulo. Misma forma que la `Etiqueta` comun, con los
/// colores de [GarantiasColores]: el aviso es ambar con cualquier semilla.
class EtiquetaGarantia extends StatelessWidget {
  const EtiquetaGarantia({
    super.key,
    required this.texto,
    this.tono = TonoEtiqueta.neutro,
    this.icono,
  });

  final String texto;
  final TonoEtiqueta tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final s = _semanticaEtiqueta(tono);
    final letra = GarantiasColores.texto(context, s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GarantiasColores.fondo(context, s),
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: letra),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: letra,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nota o aviso del modulo. Misma API que `NotaDelDato`, con los colores de
/// [GarantiasColores] y una franja del tono a la izquierda: el aviso se
/// distingue de la informacion por el color y tambien por la forma.
class NotaGarantia extends StatelessWidget {
  const NotaGarantia({
    super.key,
    required this.texto,
    this.tono = TonoNota.info,
    this.icono,
    this.accion,
  });

  final String texto;
  final TonoNota tono;
  final IconData? icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final (s, iconoPorDefecto) = switch (tono) {
      TonoNota.info => (Semantica.neutro, Icons.info_outline),
      TonoNota.exito => (Semantica.exito, Icons.check_circle_outline),
      TonoNota.aviso => (Semantica.aviso, Icons.warning_amber_rounded),
      TonoNota.error => (Semantica.peligro, Icons.report_problem_outlined),
    };
    final letra = GarantiasColores.texto(context, s);
    return Container(
      margin: const EdgeInsets.only(top: Esp.s),
      decoration: BoxDecoration(
        color: GarantiasColores.fondo(context, s),
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border(
          left: BorderSide(color: GarantiasColores.pleno(context, s), width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono ?? iconoPorDefecto, size: 18, color: letra),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: letra, height: 1.35),
            ),
          ),
          if (accion != null) ...[const SizedBox(width: Esp.s), accion!],
        ],
      ),
    );
  }
}

/// Que significa cada estado y que se puede hacer con la garantia. Es el texto
/// del tooltip de [ChipEstadoGarantia] y de la [LeyendaEstados]: la confusion
/// mas comun es creer que una garantia vencida esta cerrada.
String explicacionEstado(TonoGarantia t) => switch (t) {
  TonoGarantia.vigente =>
    'Vigente: está dentro de su plazo. Admite cambios, notas, extensión y cierre.',
  TonoGarantia.porVencer =>
    'Por vencer: vence en 30 días o menos. Si se renueva, use «Extender».',
  TonoGarantia.caducada =>
    'Caducada: su fecha de expiración ya pasó, pero sigue abierta. '
        'Se puede extender su plazo o cerrarla.',
  TonoGarantia.cerrada =>
    'Cerrada: alguien registró su cierre. Ya no admite cambios y el cierre '
        'no se puede deshacer desde el sistema.',
};

class ChipEstadoGarantia extends StatelessWidget {
  const ChipEstadoGarantia({super.key, required this.garantia});

  final GarantiaVistaEntity garantia;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(garantia);
    final (texto, tono) = switch (t) {
      TonoGarantia.vigente => ('Vigente', TonoEtiqueta.exito),
      TonoGarantia.porVencer => ('Por vencer', TonoEtiqueta.aviso),
      TonoGarantia.caducada => ('Caducada', TonoEtiqueta.error),
      TonoGarantia.cerrada => ('Cerrada', TonoEtiqueta.neutro),
    };
    // Con el mouse encima en escritorio; tocandola en el telefono.
    return Tooltip(
      message: explicacionEstado(t),
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: EtiquetaGarantia(texto: texto, tono: tono),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOSARIO
// ═══════════════════════════════════════════════════════════════════════════

/// Un dato de la pantalla: como se llama y que significa.
typedef Termino = ({String nombre, String ayuda});

/// Glosario del modulo: cada dato tiene UN nombre y UNA explicacion, los mismos
/// en la tabla, las tarjetas, el detalle, los formularios y la guia.
///
/// Existe porque la misma cifra se llamaba «Monto garantizado», «Valor de la
/// garantía» o «Garantía» segun la pantalla, y nada decia que era la «Línea en
/// SAP» ni por que importa que coincida con la aprobada. Si se cambia un
/// termino, se cambia aqui y cambia en todo el modulo.
abstract final class Glosario {
  // ── De una garantia ──────────────────────────────────────────────────────
  static const Termino valor = (
    nombre: 'Valor de la garantía',
    ayuda: 'Cuánto vale lo que el cliente entregó como garantía.',
  );
  static const Termino lineaAprobada = (
    nombre: 'Línea aprobada',
    ayuda:
        'Límite de crédito que se le aprueba al cliente gracias a esta '
        'garantía.',
  );
  static const Termino plazoPago = (
    nombre: 'Plazo de pago',
    ayuda: 'Días que tiene el cliente para pagar cada compra a crédito.',
  );
  static const Termino inicio = (
    nombre: 'Inicio',
    ayuda: 'Desde cuándo rige la garantía.',
  );
  static const Termino expiracion = (
    nombre: 'Expiración',
    ayuda:
        'Último día de vigencia. Después queda Caducada, pero sigue abierta: '
        'se puede extender o cerrar.',
  );
  static const Termino documentos = (
    nombre: 'Documentos que la respaldan',
    ayuda:
        'Lo que el cliente entregó como garantía (pagarés, letras de cambio, '
        'inmuebles, vehículos…), cada uno con su monto.',
  );
  static const Termino sumaDocumentos = (
    nombre: 'Documentos suman',
    ayuda:
        'Suma de los montos de sus documentos. Debería ser igual al valor de '
        'la garantía.',
  );
  static const Termino lineaSap = (
    nombre: 'Línea en SAP',
    ayuda:
        'Límite de crédito que el cliente tiene cargado en SAP, sumando todas '
        'las empresas. Debería coincidir con la línea aprobada.',
  );
  static const Termino saldoSap = (
    nombre: 'Saldo en SAP',
    ayuda: 'Saldo de la cuenta del cliente en SAP, sumando todas las empresas.',
  );
  static const Termino recFirmas = (
    nombre: 'Reconocimiento de firmas',
    ayuda: 'Referencia del reconocimiento de firmas del documento, si se hizo.',
  );
  static const Termino nroProtesta = (
    nombre: 'N° de protesta',
    ayuda: 'Número de protesto del documento, si corresponde.',
  );
  static const Termino enCustodia = (
    nombre: 'En custodia',
    ayuda:
        'Sus documentos ya se entregaron al custodio con un traspaso. Recién '
        'entonces se puede extender o cerrar.',
  );
  static const Termino sinTraspaso = (
    nombre: 'Sin traspaso',
    ayuda:
        'Sus documentos todavía no se entregaron al custodio. El traspaso se '
        'genera desde «Traspaso» en la pantalla principal.',
  );

  // ── Del resumen por cliente: los montos suman sus garantias VIGENTES ──────
  static const Termino garantiasCliente = (
    nombre: 'Garantías',
    ayuda:
        'Cuántas garantías tiene y en qué estado está cada una: vigentes '
        '(dentro de su plazo), caducadas (vencidas, pero siguen abiertas) y '
        'cerradas.',
  );
  static const Termino valorVigente = (
    nombre: 'Valor en garantía',
    ayuda:
        'Suma del valor de sus garantías vigentes. Las caducadas y las '
        'cerradas no suman.',
  );
  static const Termino lineaVigente = (
    nombre: 'Línea aprobada',
    ayuda:
        'Suma de las líneas aprobadas de sus garantías vigentes (las caducadas '
        'y las cerradas no suman). Es la que se compara con la línea en SAP.',
  );
  static const Termino vencimientoCliente = (
    nombre: 'Vencimiento',
    ayuda:
        'Si tiene garantías vigentes, cuándo vence la primera. Si no tiene, '
        'cuándo venció la última, o si están todas cerradas.',
  );

  /// Los que explica la guia, en este orden.
  static const List<Termino> enGuia = [
    valor,
    lineaAprobada,
    plazoPago,
    expiracion,
    documentos,
    sumaDocumentos,
    lineaSap,
    saldoSap,
    recFirmas,
    nroProtesta,
    enCustodia,
  ];
}

/// El nombre de un dato con un ⓘ: con el mouse encima (o tocandolo en el
/// telefono) explica que es. El toque lo toma el tooltip, no la tarjeta que lo
/// contiene.
class EtiquetaConAyuda extends StatelessWidget {
  const EtiquetaConAyuda(
    this.termino, {
    super.key,
    this.estilo,
    this.alDerecha = false,
  });

  final Termino termino;
  final TextStyle? estilo;
  final bool alDerecha;

  @override
  Widget build(BuildContext context) {
    final st = estilo ?? context.apagado();
    return Tooltip(
      message: termino.ayuda,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            alDerecha ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              termino.nombre,
              style: st,
              textAlign: alDerecha ? TextAlign.end : TextAlign.start,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.info_outline,
            size: 14,
            color: st?.color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GUIA DEL MODULO
// ═══════════════════════════════════════════════════════════════════════════

/// Boton que abre la guia: el recorrido de una garantia, los estados, cuando
/// se cierra y que significa cada dato.
class BotonGuia extends StatelessWidget {
  const BotonGuia({super.key, this.texto = '¿Cómo funciona?'});

  final String texto;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => mostrarGuiaGarantias(context),
    icon: const Icon(Icons.help_outline, size: 18),
    label: Text(texto),
  );
}

Future<void> mostrarGuiaGarantias(BuildContext context) => abrirPanel<void>(
  context,
  anchoMaximo: 680,
  contenido: (_) => const _GuiaGarantias(),
);

class _GuiaGarantias extends StatelessWidget {
  const _GuiaGarantias();

  @override
  Widget build(BuildContext context) {
    Widget paso(int n, String titulo, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: Esp.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$n', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                ),
                const SizedBox(height: 2),
                Text(texto),
              ],
            ),
          ),
        ],
      ),
    );

    Widget estado(String nombre, TonoEtiqueta tono, TonoGarantia t) => Padding(
      padding: const EdgeInsets.only(bottom: Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EtiquetaGarantia(texto: nombre, tono: tono),
          const SizedBox(height: Esp.xs),
          Text(explicacionEstado(t)),
        ],
      ),
    );

    Widget punto(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: Esp.s),
            child: Icon(Icons.circle, size: 6),
          ),
          Expanded(child: Text(texto)),
        ],
      ),
    );

    Widget dato(Termino t) => Padding(
      padding: const EdgeInsets.only(bottom: Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.nombre,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          ),
          const SizedBox(height: 2),
          Text(t.ayuda, style: context.apagado()),
        ],
      ),
    );

    return MarcoPanel(
      titulo: 'Cómo funcionan las garantías',
      subtitulo: 'El recorrido, los estados y qué significa cada dato.',
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(texto: 'El recorrido de una garantía'),
          paso(
            1,
            'Registrarla',
            'Con «Nueva garantía» se cargan el cliente, el valor, la línea '
                'aprobada, la vigencia y los documentos que la respaldan. '
                'Queda «Sin traspaso».',
          ),
          paso(
            2,
            'Traspasarla a custodia',
            'Con «Traspaso», en la pantalla principal, se entregan al '
                'custodio los documentos de todas las garantías registradas '
                'que falten, y se imprime la nómina de entrega. Queda «En '
                'custodia».',
          ),
          paso(
            3,
            'Seguirla mientras dure',
            'Desde su detalle: notas para dejar constancia de lo que pase, '
                'y «Extender» para mover la fecha de expiración si se renueva.',
          ),
          paso(
            4,
            'Cerrarla',
            'Con «Cerrar garantía», desde su detalle, cuando ya no '
                'corresponde. Es definitivo.',
          ),
          const SizedBox(height: Esp.m),
          const TituloSeccion(texto: 'Estados'),
          estado('Vigente', TonoEtiqueta.exito, TonoGarantia.vigente),
          estado('Por vencer', TonoEtiqueta.aviso, TonoGarantia.porVencer),
          estado('Caducada', TonoEtiqueta.error, TonoGarantia.caducada),
          estado('Cerrada', TonoEtiqueta.neutro, TonoGarantia.cerrada),
          const SizedBox(height: Esp.m),
          const TituloSeccion(texto: '¿Cuándo se cierra una garantía?'),
          punto(
            'Solo cuando alguien la cierra con «Cerrar garantía». El sistema '
            'nunca la cierra solo.',
          ),
          punto(
            'Vencerse no la cierra: queda Caducada y todavía se puede extender '
            'o cerrar.',
          ),
          punto(
            'Para extenderla o cerrarla, antes tiene que estar en custodia.',
          ),
          punto(
            'El cierre es definitivo: después no se puede editar, ni agregar '
            'documentos o notas, ni extender. Si se cerró por error, hay que '
            'pedir a Sistemas que lo corrija.',
          ),
          const SizedBox(height: Esp.m),
          const TituloSeccion(texto: 'Qué significa cada dato'),
          for (final t in Glosario.enGuia) dato(t),
        ],
      ),
      acciones: [
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA BARRA DE VIGENCIA
// ═══════════════════════════════════════════════════════════════════════════

/// El plazo de una garantia como una regla: se llena a medida que pasa el
/// tiempo entre la fecha de inicio y la de expiracion. A la derecha, la cuenta
/// regresiva en cifras tabulares.
///
/// Reemplaza a la columna «Fecha Expiracion» del legacy con sus dos iconos
/// (una cruz si faltaban menos de 30 dias, un visto si no), que obligaban a
/// leer la fecha y hacer la cuenta de cabeza.
class BarraVigencia extends StatelessWidget {
  const BarraVigencia({
    super.key,
    required this.garantia,
    this.conFechas = true,
  });

  final GarantiaVistaEntity garantia;

  /// Muestra las fechas debajo de la barra. En la grilla compacta se omiten.
  final bool conFechas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tono = tonoDe(garantia);
    final color = colorDeTono(context, tono);
    final fraccion =
        tono == TonoGarantia.cerrada
            ? 1.0
            : (garantia.fraccionTranscurrida ?? 0);
    final g = garantia.garantia;

    final leyenda =
        tono == TonoGarantia.cerrada
            ? 'Cerrada'
            : cuentaRegresiva(garantia.diasParaVencer);

    return Semantics(
      label: 'Vigencia: $leyenda',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final barra = ClipRRect(
                borderRadius: BorderRadius.circular(Esquina.pastilla),
                child: SizedBox(
                  height: 6,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: cs.surfaceContainerHighest),
                      ),
                      // Positioned.fill: suelto en el Stack, un ColoredBox sin
                      // hijo mide 0 de alto y el tramo no se ve (pasaba: solo
                      // quedaba la pista gris).
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: fraccion,
                          child: ColoredBox(
                            color: color.withValues(
                              alpha: tono == TonoGarantia.cerrada ? 0.45 : 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              final texto = Text(
                leyenda,
                style: context.cifra(fuerte: true, color: color),
              );
              // Angosto (telefono chico, encabezado del detalle): la cuenta
              // regresiva va arriba de la barra en vez de apretarla.
              if (c.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [texto, const SizedBox(height: Esp.xs), barra],
                );
              }
              return Row(
                children: [
                  Expanded(child: barra),
                  const SizedBox(width: Esp.s),
                  texto,
                ],
              );
            },
          ),
          if (conFechas) ...[
            const SizedBox(height: Esp.xs),
            // Wrap y no Row con Spacer: en una fila apretada las dos fechas no
            // entran y la Row desbordaba. Asi van a los extremos cuando caben
            // y la de expiracion baja cuando no.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Esp.s,
              children: [
                Text(fechaCorta(g.fechaInicio), style: _fechaChica(context)),
                Text(
                  fechaCorta(g.fechaExpiracion),
                  style: _fechaChica(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TextStyle? _fechaChica(BuildContext context) =>
      context.apagado()?.copyWith(fontFeatures: cifrasTabulares);
}

/// La cuenta regresiva sola, con el color de su urgencia. Para el vencimiento
/// proximo de un cliente en la grilla principal.
class CuentaRegresiva extends StatelessWidget {
  const CuentaRegresiva({super.key, required this.dias, this.fecha});

  final int? dias;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (dias == null) {
      return Text('Sin vigentes', style: context.apagado());
    }
    final color =
        dias! < 0
            ? cs.error
            : dias! <= 30
            ? colorAviso(context)
            : cs.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cuentaRegresiva(dias),
          style: context.cifra(fuerte: dias! <= 30, color: color),
        ),
        if (fecha != null)
          Text(
            fechaCorta(fecha),
            style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
          ),
      ],
    );
  }
}

/// La linea aprobada por garantias frente a la de SAP. Si no coinciden, lo
/// dice en palabras y con la diferencia: el legacy pintaba la fila de rojo sin
/// explicar por que.
class ComparacionSap extends StatelessWidget {
  const ComparacionSap({
    super.key,
    required this.aprobada,
    required this.sap,
    this.alinearDerecha = true,
  });

  final double aprobada;
  final double sap;
  final bool alinearDerecha;

  bool get difiere => (aprobada - sap).abs() >= 0.005;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          difiere
              ? 'La línea aprobada por garantías (${monto(aprobada)}) no '
                  'coincide con la línea de crédito en SAP (${monto(sap)}).'
              : 'Coincide con la línea de crédito en SAP.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            alinearDerecha ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (difiere) ...[
            Icon(Icons.compare_arrows, size: 14, color: colorAviso(context)),
            const SizedBox(width: Esp.xs),
          ],
          // Una linea de millones con el icono no entra en la columna a 1000
          // px y la Row desbordaba: la cifra se achica, nunca se corta.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  alinearDerecha ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                monto(sap),
                style: context.cifra(
                  fuerte: difiere,
                  color: difiere ? colorAviso(context) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPOS DE FORMULARIO
// ═══════════════════════════════════════════════════════════════════════════

final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

/// Campo de fecha de solo lectura que abre el calendario. Valida como un
/// TextFormField para que el Form lo cuente.
class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
    this.obligatorio = true,
    this.validar,
    this.primera,
    this.ultima,
    this.habilitado = true,
  });

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> onCambio;
  final bool obligatorio;
  final String? Function(DateTime?)? validar;
  final DateTime? primera;
  final DateTime? ultima;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      key: ValueKey('$etiqueta-$valor'),
      initialValue: valor,
      validator: (v) {
        if (obligatorio && v == null) return 'Indique la fecha';
        return validar?.call(v);
      },
      builder:
          (estado) => InkWell(
            borderRadius: BorderRadius.circular(Esquina.chica),
            onTap:
                !habilitado
                    ? null
                    : () async {
                      final hoy = DateTime.now();
                      final elegida = await showDatePicker(
                        context: context,
                        initialDate: valor ?? hoy,
                        firstDate: primera ?? DateTime(2000),
                        lastDate: ultima ?? DateTime(hoy.year + 15),
                        helpText: etiqueta,
                      );
                      if (elegida == null) return;
                      estado.didChange(elegida);
                      onCambio(elegida);
                    },
            child: InputDecorator(
              isEmpty: valor == null,
              decoration: InputDecoration(
                labelText: etiqueta,
                errorText: estado.errorText,
                enabled: habilitado,
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.event_outlined, size: 18),
              ),
              child: Text(
                valor == null ? '' : _formatoFecha.format(valor!),
                style: const TextStyle(fontFeatures: cifrasTabulares),
              ),
            ),
          ),
    );
  }
}

/// Entrada de un monto: acepta separador de miles con coma y punto decimal.
class CampoMonto extends StatelessWidget {
  const CampoMonto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.obligatorio = true,
    this.permitirCero = true,
    this.ayuda,
    this.onCambio,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final bool obligatorio;
  final bool permitirCero;
  final String? ayuda;
  final ValueChanged<String>? onCambio;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controlador,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    textAlign: TextAlign.end,
    style: const TextStyle(fontFeatures: cifrasTabulares),
    onChanged: onCambio,
    decoration: InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      // Sin esto una ayuda larga se corta en una linea con «…».
      helperMaxLines: 2,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
    validator: (t) {
      final v = leerMonto(t);
      if (v == null) return obligatorio ? 'Indique el monto' : null;
      if (v < 0) return 'No puede ser negativo';
      if (!permitirCero && v == 0) return 'Debe ser mayor a cero';
      if (v >= 100000000000) return 'Monto demasiado grande';
      return null;
    },
  );
}

/// Lee un monto escrito con coma de miles («12,345.67»). Null si esta vacio o
/// no es un numero.
double? leerMonto(String? t) {
  if (t == null || t.trim().isEmpty) return null;
  return double.tryParse(t.trim().replaceAll(',', ''));
}

/// Texto inicial de un campo de monto a partir de un valor guardado.
String textoMonto(num? v) => v == null ? '' : v.toStringAsFixed(2);

// ═══════════════════════════════════════════════════════════════════════════
// CONTENEDORES
// ═══════════════════════════════════════════════════════════════════════════

/// Abre [contenido] como dialogo en pantallas anchas y a pantalla completa en
/// el telefono, donde un dialogo flotante deja el teclado tapando la mitad del
/// formulario.
///
/// El ancho se mide en cada dibujo y no solo al abrir: si la ventana cambia de
/// tamano con el panel abierto, el panel cambia con ella (antes, abierto en una
/// ventana angosta, seguia a pantalla completa en una de escritorio). La clave
/// conserva lo que el usuario ya escribio cuando pasa de un modo al otro.
Future<T?> abrirPanel<T>(
  BuildContext context, {
  required Widget Function(BuildContext) contenido,
  double anchoMaximo = 640,
}) {
  final clave = GlobalKey(debugLabel: 'abrirPanel');
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final pantalla = MediaQuery.sizeOf(ctx);
      final panel = KeyedSubtree(
        key: clave,
        child: GarantiasScope(child: contenido(ctx)),
      );
      if (pantalla.width < 600) return Dialog.fullscreen(child: panel);
      return Dialog(
        insetPadding: const EdgeInsets.all(Esp.xl),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: anchoMaximo,
            maxHeight: pantalla.height * 0.92,
          ),
          child: panel,
        ),
      );
    },
  );
}

/// La espera de una seccion **dentro de un panel**.
///
/// [EsqueletoLista] es un `ListView`: ocupa toda la altura que le den. El
/// cuerpo de [MarcoPanel] va en un `SingleChildScrollView`, que le da altura
/// infinita, y la lista revienta con "Vertical viewport was given unbounded
/// height": el panel queda sin tamano, ningun toque le llega y la pantalla
/// parece congelada. Aqui el esqueleto va con el alto exacto de sus filas.
///
/// Fuera de un panel (en una pantalla, dentro de un `Expanded`) se puede usar
/// [EsqueletoLista] directamente.
class EsperaEnPanel extends StatelessWidget {
  const EsperaEnPanel({super.key, this.filas = 3, this.altoFila = 72});

  final int filas;
  final double altoFila;

  /// El alto que dibuja [EsqueletoLista]: su padding ([Esp.m] arriba y abajo),
  /// las filas y los separadores ([Esp.s]) entre ellas.
  double get alto => Esp.m * 2 + filas * altoFila + (filas - 1) * Esp.s;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: alto,
    child: EsqueletoLista(filas: filas, altoFila: altoFila),
  );
}

/// Estructura comun de los paneles: encabezado fijo, cuerpo con scroll y pie
/// con las acciones. El pie no se mueve cuando el formulario crece.
///
/// **Regla del cuerpo:** como ya scrollea, adentro no puede ir nada que pida
/// "toda la altura disponible": ni `ListView`/`GridView` sin `shrinkWrap`, ni
/// `Expanded`/`Flexible`/`Spacer` en una `Column`, ni [EsqueletoLista] suelto.
/// Para la espera usar [EsperaEnPanel]; para mensajes de pantalla entera
/// (`MensajeError`, `MensajeVacio`), darles un `SizedBox` con alto fijo. La
/// prueba `test/garantias_paneles_test.dart` arma cada panel en sus estados de
/// espera, error y datos para que esto no vuelva a pasar.
///
/// **Esc cierra el panel** y hace lo mismo que la X: nada mientras se guarda,
/// y en los formularios con cambios pregunta antes de descartarlos. Hace falta
/// aca porque [abrirPanel] abre con `barrierDismissible: false` (un clic
/// afuera no puede borrar un formulario) y Flutter ata el Esc de los dialogos
/// a ese mismo indicador.
class MarcoPanel extends StatelessWidget {
  const MarcoPanel({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.cuerpo,
    this.acciones = const [],
    this.onCerrar,
    this.encabezadoExtra,
  });

  final String titulo;
  final String? subtitulo;
  final Widget cuerpo;
  final List<Widget> acciones;
  final VoidCallback? onCerrar;
  final Widget? encabezadoExtra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chico = MediaQuery.sizeOf(context).width < 600;
    final margen = chico ? Esp.l : Esp.xl;
    final cerrar = onCerrar ?? () => Navigator.of(context).maybePop();

    // Esc llega como DismissIntent y Flutter usa la accion mas cercana al foco
    // aunque este deshabilitada: la del dialogo lo esta (barrierDismissible
    // falso). Esta la tapa, y el Focus con autofocus pone el foco dentro del
    // panel apenas abre, para que el Esc funcione sin haber tocado nada. Un
    // Autocomplete abierto se queda con el primer Esc (cierra sus sugerencias)
    // y pasa el siguiente hasta aca.
    return Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            cerrar();
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: _cuerpoDelMarco(context, cs, margen, cerrar),
      ),
    );
  }

  Widget _cuerpoDelMarco(
    BuildContext context,
    ColorScheme cs,
    double margen,
    VoidCallback cerrar,
  ) {
    return Material(
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cs.surfaceContainerLow,
            padding: EdgeInsets.fromLTRB(margen, Esp.l, Esp.s, Esp.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: Peso.titulo,
                        ),
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: Esp.xs),
                        Text(subtitulo!, style: context.apagado()),
                      ],
                      if (encabezadoExtra != null) ...[
                        const SizedBox(height: Esp.s),
                        encabezadoExtra!,
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar (Esc)',
                  onPressed: cerrar,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.l),
              child: cuerpo,
            ),
          ),
          if (acciones.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.m),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: acciones,
              ),
            ),
        ],
      ),
    );
  }
}

/// Titulo de una seccion dentro de un panel, con una accion opcional a la
/// derecha.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion({super.key, required this.texto, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    // Wrap y no Row: a 320 px el titulo y el boton ("Agregar documento") no
    // entran juntos. Asi van a los extremos cuando caben y el boton baja
    // cuando no, en vez de desbordar.
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Esp.s,
      children: [
        Text(texto, style: context.tituloSeccion()),
        if (accion != null) accion!,
      ],
    ),
  );
}

/// Par etiqueta / valor para las fichas de datos. Con [ayuda], la etiqueta
/// lleva su ⓘ (ver [EtiquetaConAyuda]); para los datos del [Glosario] usar
/// [DatoFicha.termino].
class DatoFicha extends StatelessWidget {
  const DatoFicha({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.cifra = false,
    this.ancho = 180,
    this.ayuda,
  });

  DatoFicha.termino(
    Termino t, {
    super.key,
    required this.valor,
    this.cifra = false,
    this.ancho = 180,
  }) : etiqueta = t.nombre,
       ayuda = t.ayuda;

  final String etiqueta;
  final String valor;
  final bool cifra;
  final double ancho;
  final String? ayuda;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ancho,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ayuda != null)
          EtiquetaConAyuda((nombre: etiqueta, ayuda: ayuda!))
        else
          Text(etiqueta, style: context.apagado()),
        const SizedBox(height: 2),
        Text(
          valor.trim().isEmpty ? '--' : valor,
          style:
              cifra
                  ? context.cifra(fuerte: true)
                  : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MENU DE ACCIONES (⋮)
// ═══════════════════════════════════════════════════════════════════════════

/// Una opcion de [MenuAcciones].
@immutable
class OpcionMenu {
  const OpcionMenu(
    this.etiqueta,
    this.icono,
    this.alElegir, {
    this.detalle,
    this.motivo,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback alElegir;

  /// Texto chico debajo de la etiqueta («3 pendientes»).
  final String? detalle;

  /// Si no es null, la opcion va deshabilitada y esto dice por que.
  final String? motivo;

  bool get habilitada => motivo == null;
}

/// El boton ⋮ con su menu. **En el modulo no se usa `PopupMenuButton`.**
///
/// El menu de `PopupMenuButton` es una ruta aparte que, cada vez que cambia el
/// tamano de la ventana, recalcula su posicion con el contexto del boton. Si
/// el boton ya no existe —la fila paso de diseno angosto a ancho al agrandar
/// la ventana, la lista se volvio a dibujar— el menu revienta con "Looking up
/// a deactivated widget's ancestor is unsafe" y tapa la pantalla de rojo
/// (paso el 2026-09-24). Este (MenuAnchor) vive dentro del boton: se va con
/// el, y se cierra solo si la ventana cambia de tamano o la lista scrollea.
///
/// Al abrirlo el foco pasa al boton, para que el primer Esc cierre el menu y
/// no el panel de abajo; el siguiente Esc ya cierra el panel.
class MenuAcciones extends StatefulWidget {
  const MenuAcciones({
    super.key,
    required this.opciones,
    this.tooltip = 'Más acciones',
    this.tamIcono,
    this.aviso = false,
  });

  final List<OpcionMenu> opciones;
  final String tooltip;
  final double? tamIcono;

  /// Punto de aviso sobre el icono (hay traspasos pendientes).
  final bool aviso;

  @override
  State<MenuAcciones> createState() => _MenuAccionesState();
}

class _MenuAccionesState extends State<MenuAcciones> {
  final _foco = FocusNode(debugLabel: 'MenuAcciones');

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _foco,
      menuChildren: [
        for (final o in widget.opciones)
          MenuItemButton(
            leadingIcon: Icon(o.icono, size: 20),
            onPressed: o.habilitada ? o.alElegir : null,
            child: _TextoOpcion(o),
          ),
      ],
      builder:
          (context, menu, _) => IconButton(
            focusNode: _foco,
            tooltip: widget.tooltip,
            icon: Badge(
              isLabelVisible: widget.aviso,
              child: Icon(Icons.more_vert, size: widget.tamIcono),
            ),
            onPressed: () {
              if (menu.isOpen) {
                menu.close();
              } else {
                menu.open();
                _foco.requestFocus();
              }
            },
          ),
    );
  }
}

class _TextoOpcion extends StatelessWidget {
  const _TextoOpcion(this.o);

  final OpcionMenu o;

  @override
  Widget build(BuildContext context) {
    final nota = o.motivo ?? o.detalle;
    if (nota == null) return Text(o.etiqueta);
    // El menu mide su ancho por la linea mas larga: sin tope, un motivo largo
    // lo estiraria de lado a lado de la pantalla.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Esp.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(o.etiqueta),
            Text(nota, style: context.apagado()?.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGINADOR
// ═══════════════════════════════════════════════════════════════════════════

/// Cuantas filas por pagina se pueden elegir en las tablas del modulo.
const List<int> opcionesDeFilas = [25, 50, 100];

/// Pie de las tablas de escritorio: que filas se ven, cuantas por pagina y las
/// flechas. Lo comparten las vistas «Por cliente» y «Por garantía».
class PaginadorTabla extends StatelessWidget {
  const PaginadorTabla({
    super.key,
    required this.padding,
    required this.primera,
    required this.ultima,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
    required this.porPagina,
    required this.onPagina,
    required this.onPorPagina,
    this.sustantivo = 'registros',
  });

  final EdgeInsets padding;
  final int primera;
  final int ultima;
  final int total;
  final int pagina;
  final int totalPaginas;
  final int porPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<int> onPorPagina;

  /// «clientes», «garantías»: lo que se esta contando.
  final String sustantivo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: padding.copyWith(top: Esp.xs, bottom: Esp.xs),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$primera–$ultima',
                    style: context.cifra(fuerte: true),
                  ),
                  TextSpan(text: ' de ', style: context.apagado()),
                  TextSpan(text: '$total', style: context.cifra(fuerte: true)),
                  TextSpan(text: ' $sustantivo', style: context.apagado()),
                ],
              ),
            ),
          ),
          Text('Filas', style: context.apagado()),
          const SizedBox(width: Esp.s),
          DropdownButton<int>(
            value: opcionesDeFilas.contains(porPagina) ? porPagina : 25,
            underline: const SizedBox(),
            isDense: true,
            borderRadius: BorderRadius.circular(Esquina.chica),
            items: [
              for (final n in opcionesDeFilas)
                DropdownMenuItem(
                  value: n,
                  child: Text('$n', style: context.cifra()),
                ),
            ],
            onChanged: (n) {
              if (n != null) onPorPagina(n);
            },
          ),
          const SizedBox(width: Esp.l),
          IconButton(
            tooltip: 'Página anterior',
            onPressed: pagina > 0 ? () => onPagina(pagina - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${pagina + 1} / $totalPaginas',
            style: context.cifra(fuerte: true),
          ),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed:
                pagina < totalPaginas - 1 ? () => onPagina(pagina + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// El numero de una fila en la lista filtrada («#» de las tablas). Sirve para
/// ubicar una fila de palabra —«la 12»— y para saber cuantas van.
class NumeroFila extends StatelessWidget {
  const NumeroFila(this.n, {super.key, this.ancho = 40});

  final int n;
  final double ancho;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ancho,
    child: Text(
      '$n',
      style: context.cifra(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        tam: 11.5,
      ),
    ),
  );
}
