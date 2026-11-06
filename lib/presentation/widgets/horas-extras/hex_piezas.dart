/// Piezas del módulo Horas Extras: encabezado, etiquetas de estado y tipo con
/// ícono y color, origen de cada hora, montos, códigos que se explican al
/// tocarlos, acciones con permiso por botón y tarjetas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_avance.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_donde_marco.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_leyenda.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENCABEZADO Y ETIQUETAS
// ═══════════════════════════════════════════════════════════════════════════

/// Encabezado de pantalla: ceja del módulo, título, detalle y acciones. Bajo
/// [hexAnchoTabla] se compacta y las acciones bajan debajo del título.
class EncabezadoHex extends StatelessWidget {
  const EncabezadoHex({
    super.key,
    required this.titulo,
    this.detalle,
    this.acciones = const [],
  });

  final String titulo;
  final String? detalle;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final compacto = c.maxWidth < hexAnchoTabla;
      final cs = Theme.of(context).colorScheme;
      final t = Theme.of(context).textTheme;
      final textos = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Horas extra',
            style: t.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: Peso.titulo,
            ),
          ),
          const SizedBox(height: Esp.xs),
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: (compacto ? t.titleLarge : t.headlineSmall)?.copyWith(
                fontWeight: Peso.titulo,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (detalle != null && detalle!.isNotEmpty) ...[
            const SizedBox(height: Esp.xs),
            Text(
              detalle!,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      );
      if (acciones.isEmpty) return textos;
      final botones = Wrap(
        spacing: Esp.s,
        runSpacing: Esp.s,
        alignment: compacto ? WrapAlignment.start : WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: acciones,
      );
      if (compacto) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [textos, const SizedBox(height: Esp.m), botones],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: textos),
          const SizedBox(width: Esp.l),
          Flexible(
            flex: 2,
            child: Align(alignment: Alignment.topRight, child: botones),
          ),
        ],
      );
    },
  );
}

/// Estado de un reporte o de una planilla con el texto del SP, su ícono y su
/// color (mapa de `estadoVisualHex`). [ayuda], por ejemplo de quién espera.
class EtiquetaEstadoHex extends StatelessWidget {
  const EtiquetaEstadoHex(this.estado, this.texto, {super.key, this.ayuda});

  final String estado;
  final String texto;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final v = estadoVisualHex(estado);
    return ChipHex(
      texto: texto.trim().isEmpty ? estado : texto,
      icono: v.icono,
      tono: v.tono,
      tachado: v.tachado,
      ayuda: ayuda,
    );
  }
}

/// «Editado»: un encargado corrigió alguna hora del reporte.
class EtiquetaEditadoHex extends StatelessWidget {
  const EtiquetaEditadoHex({super.key});

  @override
  Widget build(BuildContext context) => const ChipHex(
    texto: 'Editado',
    icono: Icons.edit_outlined,
    tono: TonoHex.terciario,
    ayuda: 'Un encargado corrigió alguna hora de este reporte.',
  );
}

/// Adenda D37: «Sin salida marcada», con el aviso del SP como ayuda. Va en la
/// celda angosta del estado; el texto entero, en [AvisoSalidaHex].
class EtiquetaSinSalidaHex extends StatelessWidget {
  const EtiquetaSinSalidaHex(this.aviso, {super.key});

  final String? aviso;

  @override
  Widget build(BuildContext context) {
    final texto = aviso?.trim() ?? '';
    return ChipHex(
      texto: 'Sin salida marcada',
      icono: Icons.timer_off_outlined,
      tono: TonoHex.terciario,
      ayuda: texto.isEmpty ? null : texto,
    );
  }
}

/// Adenda D37: el aviso del SP de un reporte sin salida marcada, a todo el
/// ancho y en tono de advertencia. Nada si el SP no lo manda.
class AvisoSalidaHex extends StatelessWidget {
  const AvisoSalidaHex(this.reporte, {super.key});

  final HexReporteEntity reporte;

  /// Si hay algo que mostrar: la bandera y el texto del SP.
  static bool hay(HexReporteEntity r) =>
      r.sinSalidaMarcada && (r.avisoSalida?.trim() ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hay(reporte)) return const SizedBox.shrink();
    return NotaDelDato(
      texto: reporte.avisoSalida!.trim(),
      tono: TonoNota.aviso,
      icono: Icons.timer_off_outlined,
    );
  }
}

/// «Aviso de biométrico»: el biométrico registra otra hora que la del reporte.
class EtiquetaAvisoBiometricoHex extends StatelessWidget {
  const EtiquetaAvisoBiometricoHex({super.key});

  @override
  Widget build(BuildContext context) => const ChipHex(
    texto: 'Aviso de biométrico',
    icono: Icons.fingerprint,
    tono: TonoHex.pendiente,
    ayuda: 'El biométrico registra otra hora que la del reporte.',
  );
}

/// El tipo de reporte (antes, después o sin horario) con su ícono en
/// `primary`. [plano] para una celda angosta: sin ficha.
class TipoReporteHex extends StatelessWidget {
  const TipoReporteHex(this.tipo, this.texto, {super.key, this.plano = false});

  final String tipo;
  final String texto;
  final bool plano;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rotulo = oGuionHex(texto.trim().isEmpty ? tipo : texto);
    final icono = iconoTipoReporteHex(tipo);
    if (plano) {
      return IconoTextoHex(
        texto: rotulo,
        icono: icono,
        colorIcono: cs.primary,
        colorTexto: cs.onSurface,
        estilo: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return ChipHex(texto: rotulo, icono: icono, contorno: true);
  }
}

/// El tipo de día: domingo y feriado en la familia terciaria (rinden más),
/// el día hábil neutro. [plano] para una celda angosta: sin ficha.
class TipoDiaHex extends StatelessWidget {
  const TipoDiaHex(this.tipoDia, this.texto, {super.key, this.plano = false});

  final String tipoDia;
  final String texto;
  final bool plano;

  @override
  Widget build(BuildContext context) {
    final rotulo = texto.trim().isEmpty ? tipoDiaHex(tipoDia) : texto;
    if (rotulo.trim().isEmpty) return const SizedBox.shrink();
    final especial = diaEspecialHex(tipoDia);
    final icono = iconoTipoDiaHex(tipoDia);
    if (plano) {
      return IconoTextoHex(
        texto: rotulo,
        icono: icono,
        tono: especial ? TonoHex.terciario : TonoHex.neutro,
      );
    }
    return especial
        ? ChipHex(texto: rotulo, icono: icono, tono: TonoHex.terciario)
        : ChipHex(
          texto: rotulo,
          icono: icono,
          contorno: true,
          colorIcono: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HORAS, MONTOS Y CÓDIGOS
// ═══════════════════════════════════════════════════════════════════════════

/// De dónde salió una hora, con ícono y color: biométrico y app (dato
/// fiable) en `primary`, corregida en `tertiary`, pendiente en ámbar.
/// [detallado] agrega debajo qué significa, para el detalle del reporte.
/// Con [alTocar], la ficha de la app abre dónde se marcó (D30).
class OrigenHoraHex extends StatelessWidget {
  const OrigenHoraHex(
    this.origen, {
    super.key,
    this.texto,
    this.detallado = false,
    this.alFinal = false,
    this.alTocar,
  });

  final String? origen;

  /// El origen en palabras del SP (anexo de la planilla): reemplaza al rótulo
  /// fijo; el ícono y el color siguen saliendo de [origen].
  final String? texto;
  final bool detallado;

  /// En la columna de la derecha (la hora de fin): todo alineado al final.
  final bool alFinal;

  /// Solo la ficha «App · con ubicación» responde al toque; las demás no.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final (icono, rotulo, ayuda, tono) = switch (origen) {
      'HORARIO' => (
        Icons.schedule,
        'Del horario',
        'Tomada de tu horario asignado.',
        TonoHex.neutro,
      ),
      'BIOMETRICO' => (
        Icons.fingerprint,
        'Biométrico',
        'Marcada en el biométrico.',
        TonoHex.primario,
      ),
      'APP' => (
        Icons.location_on,
        'App · con ubicación',
        'Marcada en la app; se guardó dónde estabas.',
        TonoHex.primario,
      ),
      'EDITADO' => (
        Icons.edit_outlined,
        'Corregida por el encargado',
        'Un encargado corrigió esta hora.',
        TonoHex.terciario,
      ),
      null => (
        Icons.hourglass_empty,
        'Pendiente de biométrico',
        'Todavía no llega la marca del biométrico.',
        TonoHex.pendiente,
      ),
      final otro => (Icons.help_outline, otro, otro, TonoHex.neutro),
    };
    final delSp = texto?.trim() ?? '';
    final fila = IconoTextoHex(
      texto: delSp.isEmpty ? rotulo : delSp,
      icono: icono,
      tono: tono,
    );
    if (detallado) {
      return Column(
        crossAxisAlignment:
            alFinal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          fila,
          Text(
            ayuda,
            textAlign: alFinal ? TextAlign.end : TextAlign.start,
            style: context.apagado(),
          ),
        ],
      );
    }
    final toque = origen == 'APP' ? alTocar : null;
    if (toque != null) {
      return Tooltip(
        message: 'Ver dónde marcó',
        child: Semantics(
          button: true,
          label: 'Ver dónde marcó',
          excludeSemantics: true,
          child: InkWell(
            onTap: toque,
            borderRadius: BorderRadius.circular(Esquina.chica),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: fila),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.map_outlined,
                    size: 14,
                    color: acentoTonoHex(context, tono),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Tooltip(message: ayuda, child: fila);
  }
}

/// Una hora de reloj con su origen debajo. Si cae en otro día que la jornada
/// (salida pasada la medianoche) lleva el día al lado.
class HoraOrigenHex extends StatelessWidget {
  const HoraOrigenHex(
    this.hora,
    this.origen, {
    super.key,
    this.jornada,
    this.textoOrigen,
    this.idReporte,
  });

  final DateTime? hora;
  final String? origen;
  final DateTime? jornada;

  /// El origen en palabras del SP, si lo manda (ver [OrigenHoraHex.texto]).
  final String? textoOrigen;

  /// El reporte de la hora: con él, tocar la ficha de la app abre la hoja
  /// «Dónde marcó». Sin él la ficha no responde.
  final BigInt? idReporte;

  @override
  Widget build(BuildContext context) {
    final h = hora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              relojHex(h),
              style: estiloCifrasHex(Theme.of(context).textTheme.titleSmall),
            ),
            if (h != null && otroDiaHex(h, jornada))
              Text(diaMesHex(h), style: context.apagado()),
          ],
        ),
        const SizedBox(height: 2),
        OrigenHoraHex(
          origen,
          texto: textoOrigen,
          alTocar:
              idReporte == null
                  ? null
                  : () => mostrarDondeMarcoHex(context, idReporte!),
        ),
      ],
    );
  }
}

/// Inicio → fin de un reporte, cada hora con su origen (y el día si cruza la
/// medianoche). Con [rotulos], «Inicio» y «Fin» van encima de cada hora.
class InicioFinHex extends StatelessWidget {
  const InicioFinHex(this.reporte, {super.key, this.rotulos = false});

  final HexReporteEntity reporte;
  final bool rotulos;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    Widget extremo(String rotulo, DateTime? hora, String? origen) {
      final celda = HoraOrigenHex(
        hora,
        origen,
        jornada: r.fechaJornada,
        idReporte: r.idReporte,
      );
      if (!rotulos) return celda;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: context.apagado()),
          const SizedBox(height: 2),
          celda,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: extremo('Inicio', r.inicio, r.origenInicio)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(child: extremo('Fin', r.fin, r.origenFin)),
      ],
    );
  }
}

/// Un monto del SP en cifras fijas; «provisional» si el haber aún puede cambiar.
class MontoHex extends StatelessWidget {
  const MontoHex(this.monto, {super.key, this.provisional = false});

  final double? monto;
  final bool provisional;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Esp.s,
    runSpacing: 2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        bsHex(monto),
        style: estiloCifrasHex(
          Theme.of(context).textTheme.bodyMedium,
          fuerte: true,
        ),
      ),
      if (provisional) const EtiquetaProvisionalHex(),
    ],
  );
}

/// «provisional» (o [texto]): el haber básico aún puede cambiar el monto.
class EtiquetaProvisionalHex extends StatelessWidget {
  const EtiquetaProvisionalHex({super.key, this.texto = 'provisional'});

  final String texto;

  @override
  Widget build(BuildContext context) => ChipHex(
    texto: texto,
    icono: Icons.hourglass_top,
    tono: TonoHex.error,
    ayuda: 'El haber básico aún no está confirmado; el monto puede cambiar.',
  );
}

/// Una cifra del pie de una planilla: qué es y su valor ya formateado.
typedef CifraHex = ({String rotulo, String valor});

/// El pie de una planilla: [principal] (el total en dinero) en grande, con la
/// doble raya de los totales de la hoja de cálculo, y las demás [cifras] al
/// lado (ancho) o de a dos debajo (angosto). Muestra cifras del SP.
class CifrasHex extends StatelessWidget {
  const CifrasHex({
    super.key,
    required this.principal,
    this.cifras = const [],
    this.contable = true,
    this.tonoTotal,
    this.compacto,
  });

  final CifraHex principal;
  final List<CifraHex> cifras;

  /// Sin él (una planilla anulada, que no se paga), el total va en el tono
  /// secundario y sin la doble raya de los totales.
  final bool contable;

  /// El color del total y de su doble raya (por ejemplo, el verde de lo que
  /// se va a pagar); sin él, el texto normal y `primary`.
  final TonoHex? tonoTotal;

  /// Fija la disposición (`true`: el total y las cifras de a dos, uno bajo el
  /// otro) sin medir el contenedor. Hace falta dentro de un diálogo, cuyo
  /// ancho se calcula por contenido y no admite un `LayoutBuilder`.
  final bool? compacto;

  /// Mide el contenedor, salvo que [compacto] fije la disposición.
  Widget _conAncho(Widget Function(BuildContext, double) armar) {
    if (compacto != null) {
      return Builder(builder: (context) => armar(context, 0));
    }
    return LayoutBuilder(builder: (context, c) => armar(context, c.maxWidth));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget rotulo(String texto) =>
        Text(texto, style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant));
    final tono = tonoTotal;
    final colorTotal =
        !contable
            ? cs.onSurfaceVariant
            : (tono == null ? cs.onSurface : acentoTonoHex(context, tono));
    final colorRaya =
        contable && tono != null ? acentoTonoHex(context, tono) : cs.primary;
    final valor = Text(
      principal.valor,
      style: estiloCifrasHex(
        t.headlineSmall,
        fuerte: contable,
      )?.copyWith(color: colorTotal),
    );
    final total = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        rotulo(principal.rotulo),
        const SizedBox(height: Esp.xs),
        if (!contable)
          valor
        else
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                valor,
                const SizedBox(height: 3),
                Divider(height: 1, thickness: 1.5, color: colorRaya),
                const SizedBox(height: 2),
                Divider(height: 1, thickness: 1.5, color: colorRaya),
              ],
            ),
          ),
      ],
    );
    Widget cifra(CifraHex c) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        rotulo(c.rotulo),
        const SizedBox(height: 2),
        Text(c.valor, style: estiloCifrasHex(t.titleSmall)),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: _conAncho((context, maxWidth) {
          final ancho =
              compacto == null
                  ? maxWidth >= hexAnchoTabla - 2 * Esp.l
                  : !compacto!;
          final columna =
              ancho
                  ? 168.0
                  : (compacto == null ? (maxWidth - Esp.m) / 2 : 150.0);
          final resto = Wrap(
            spacing: Esp.m,
            runSpacing: Esp.m,
            children: [
              for (final x in cifras) SizedBox(width: columna, child: cifra(x)),
            ],
          );
          final cuerpo =
              ancho
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 200),
                        child: total,
                      ),
                      if (cifras.isNotEmpty) ...[
                        const SizedBox(width: Esp.xl),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: cs.outlineVariant),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: Esp.xl),
                              child: resto,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: total),
                      if (cifras.isNotEmpty) ...[
                        const SizedBox(height: Esp.m),
                        resto,
                      ],
                    ],
                  );
          return cuerpo;
        }),
      ),
    );
  }
}

/// Un código de la planilla (HS, H50, C, DC…) con ícono y color por [familia]:
/// tramos en `primary` según su [multiplicador], comidas en `tertiary`.
/// [explicar] abre su significado al tocarlo; [apagado], comida inactiva.
class CodigoHex extends StatelessWidget {
  const CodigoHex(
    this.codigo, {
    super.key,
    this.apagado = false,
    this.familia,
    this.multiplicador,
    this.explicar = false,
  });

  final String codigo;
  final bool apagado;
  final FamiliaCodigoHex? familia;
  final double? multiplicador;
  final bool explicar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final par =
        apagado
            ? (fondo: cs.surfaceContainerLow, letra: cs.onSurfaceVariant)
            : coloresCodigoHex(
              context,
              codigo,
              familia: familia,
              multiplicador: multiplicador,
            );
    final icono = switch (familia) {
      FamiliaCodigoHex.tramo => Icons.schedule,
      FamiliaCodigoHex.comida => iconoComidaHex(codigo),
      null => null,
    };
    final ficha = Container(
      constraints: const BoxConstraints(minWidth: 36),
      padding: EdgeInsets.fromLTRB(icono == null ? 6 : 4, 2, 6, 2),
      decoration: BoxDecoration(
        color: par.fondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 16, color: par.letra),
            const SizedBox(width: 3),
          ],
          Text(
            codigo,
            textAlign: TextAlign.center,
            style: estiloCifrasHex(
              Theme.of(context).textTheme.labelMedium,
              fuerte: true,
            )?.copyWith(fontSize: 12, color: par.letra),
          ),
        ],
      ),
    );
    if (!explicar || codigo.trim().isEmpty) return ficha;
    return Semantics(
      button: true,
      label: 'Código $codigo: ver qué significa',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => mostrarSignificadoCodigoHex(context, codigo),
          child: ficha,
        ),
      ),
    );
  }
}

/// Los códigos de comida de un reporte (`C,DC`, como los manda el SP) en
/// fichas de la planilla con su ícono; un guion si no tiene. [explicar]: cada
/// ficha abre su significado al tocarla.
class ComidasHex extends StatelessWidget {
  const ComidasHex(this.codigos, {super.key, this.explicar = false});

  final String? codigos;
  final bool explicar;

  @override
  Widget build(BuildContext context) {
    final lista = [
      for (final c in (codigos ?? '').split(','))
        if (c.trim().isNotEmpty) c.trim(),
    ];
    if (lista.isEmpty) return const Text('—');
    return Wrap(
      spacing: Esp.xs,
      runSpacing: Esp.xs,
      children: [
        for (final c in lista)
          CodigoHex(c, familia: FamiliaCodigoHex.comida, explicar: explicar),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACCIONES Y TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

/// Una acción de fila o tarjeta. Con [boton], solo aparece si el usuario lo
/// tiene (`tb_vistaBtn`); la pantalla la agrega solo si el SP la permite
/// (`puede*`). Sin [alTocar] queda deshabilitada (escritura en curso).
class AccionHex {
  const AccionHex(
    this.etiqueta,
    this.icono,
    this.alTocar, {
    this.boton,
    this.destructiva = false,
    this.textoPrincipal,
    this.tono,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback? alTocar;
  final String? boton;
  final bool destructiva;

  /// Lo que dice el botón cuando la acción va a la vista (por ejemplo «Dar
  /// visto bueno»); sin él dice [etiqueta], que también es su ayuda.
  final String? textoPrincipal;

  /// El color del botón a la vista; sin él, el tonal del tema.
  final TonoHex? tono;
}

/// La acción que va a la vista: la primera de [acciones] con un botón de
/// [principales]; nula si no hay.
AccionHex? accionPrincipalHex(
  List<AccionHex> acciones,
  Set<String> principales,
) {
  for (final a in acciones) {
    if (a.boton != null && principales.contains(a.boton)) return a;
  }
  return null;
}

/// La acción principal como botón de 48 px, dentro de `PermissionWidget`: con
/// [conTexto], ícono y texto (tarjeta y tabla ancha); si no, solo el ícono con
/// su ayuda. [expandido]: a todo el ancho, con aire arriba (la tarjeta).
class BotonPrincipalHex extends StatelessWidget {
  const BotonPrincipalHex(
    this.accion, {
    super.key,
    this.conTexto = true,
    this.expandido = false,
  });

  final AccionHex accion;
  final bool conTexto;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final a = accion;
    final tono = a.tono;
    final par = tono == null ? null : coloresTonoHex(context, tono);
    final Widget boton;
    if (conTexto) {
      final tonal = FilledButton.tonalIcon(
        onPressed: a.alTocar,
        icon: Icon(a.icono, size: 20),
        label: Text(a.textoPrincipal ?? a.etiqueta),
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          visualDensity: VisualDensity.standard,
          padding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.l, 0),
          backgroundColor: par?.fondo,
          foregroundColor: par?.letra,
        ),
      );
      // En la tabla ancha no hay tarjeta que explique: la ayuda al pasar el
      // puntero. En la tarjeta el texto del botón ya lo dice.
      boton = expandido ? tonal : Tooltip(message: a.etiqueta, child: tonal);
    } else {
      boton = IconButton.filledTonal(
        tooltip: a.etiqueta,
        onPressed: a.alTocar,
        visualDensity: VisualDensity.standard,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: par?.fondo,
          foregroundColor: par?.letra,
        ),
        icon: Icon(a.icono, size: 20),
      );
    }
    final ancho =
        expandido
            ? Padding(
              padding: const EdgeInsets.only(top: Esp.m),
              child: SizedBox(width: double.infinity, child: boton),
            )
            : boton;
    final nombre = a.boton;
    if (nombre == null) return ancho;
    return PermissionWidget(buttonName: nombre, child: ancho);
  }
}

/// Las acciones que el usuario puede ver: sin botón o con su permiso.
List<AccionHex> accionesPermitidasHex(
  WidgetRef ref,
  List<AccionHex> acciones,
) => [
  for (final a in acciones)
    if (a.boton == null || tienePermisoDeBoton(ref, a.boton!)) a,
];

/// Acciones en línea (iconos con su ayuda, 48 px de área táctil) para la
/// tabla, o con [enMenu] en un menú contextual para la tarjeta del teléfono.
class AccionesHex extends ConsumerWidget {
  const AccionesHex({super.key, required this.acciones, this.enMenu = false});

  final List<AccionHex> acciones;
  final bool enMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final visibles = accionesPermitidasHex(ref, acciones);
    if (visibles.isEmpty) return const SizedBox.shrink();
    Color? color(AccionHex a) => a.destructiva ? cs.error : null;
    if (!enMenu) {
      return Wrap(
        children: [
          for (final a in visibles)
            IconButton(
              tooltip: a.etiqueta,
              // El tema usa la densidad del escritorio (40 px): aquí se fija
              // el mínimo táctil de 48 px.
              visualDensity: VisualDensity.standard,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: a.alTocar,
              icon: Icon(a.icono, size: 20, color: color(a)),
            ),
        ],
      );
    }
    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_vert),
      onOpened: () => FocusManager.instance.primaryFocus?.unfocus(),
      // 48 px de área táctil también con la densidad del escritorio.
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        visualDensity: VisualDensity.standard,
      ),
      onSelected: (i) => visibles[i].alTocar?.call(),
      itemBuilder:
          (_) => [
            for (var i = 0; i < visibles.length; i++)
              PopupMenuItem(
                value: i,
                enabled: visibles[i].alTocar != null,
                child: Row(
                  children: [
                    Icon(
                      visibles[i].icono,
                      size: 20,
                      color: color(visibles[i]),
                    ),
                    const SizedBox(width: Esp.m),
                    Flexible(child: Text(visibles[i].etiqueta)),
                  ],
                ),
              ),
          ],
    );
  }
}

/// Tarjeta de un registro en el teléfono: título con su [estado] al lado,
/// línea de apoyo, contenido, etiquetas, [pie], la [accionPrincipal] a la
/// vista y el menú de acciones. Se toca entera para abrir.
class TarjetaHex extends StatelessWidget {
  const TarjetaHex({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.contenido,
    this.etiquetas = const [],
    this.acciones = const [],
    this.alTocar,
    this.estado,
    this.pie,
    this.accionPrincipal,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? contenido;
  final List<Widget> etiquetas;
  final List<AccionHex> acciones;
  final VoidCallback? alTocar;

  /// La acción de la tarea del día, a la vista al pie de la tarjeta; el resto
  /// de [acciones] va en el menú ⋮.
  final AccionHex? accionPrincipal;

  /// Junto al título; baja de renglón si no entra.
  final Widget? estado;

  /// Al final, a todo el ancho (el avance de un reporte).
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textoTitulo = Text(
      titulo,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
    );
    final marca = estado;
    final abajo = pie;
    final principal = accionPrincipal;
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.xs, Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (marca == null)
                      textoTitulo
                    else
                      Wrap(
                        spacing: Esp.s,
                        runSpacing: Esp.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [textoTitulo, marca],
                      ),
                    if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitulo!, style: context.apagado()),
                    ],
                    if (contenido != null) ...[
                      const SizedBox(height: Esp.m),
                      contenido!,
                    ],
                    if (etiquetas.isNotEmpty) ...[
                      const SizedBox(height: Esp.s),
                      Wrap(
                        spacing: Esp.xs,
                        runSpacing: Esp.xs,
                        children: etiquetas,
                      ),
                    ],
                    if (abajo != null) ...[
                      const SizedBox(height: Esp.m),
                      Padding(
                        padding: const EdgeInsets.only(right: Esp.m),
                        child: abajo,
                      ),
                    ],
                    if (principal != null)
                      Padding(
                        padding: const EdgeInsets.only(right: Esp.m),
                        child: BotonPrincipalHex(principal, expandido: true),
                      ),
                  ],
                ),
              ),
              if (acciones.isNotEmpty)
                AccionesHex(acciones: acciones, enMenu: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// La cabecera de un grupo de filas seguidas: «[titulo] — [detalle]» con borde
/// en `primary`, sus [etiquetas] y su [codigo] como ficha, y el [pie] debajo.
/// En la tabla, franja con [accion] a la derecha; en tarjetas, un panel.
class FranjaGrupoHex extends StatelessWidget {
  const FranjaGrupoHex({
    super.key,
    required this.titulo,
    required this.enTabla,
    this.detalle,
    this.icono,
    this.accion,
    this.codigo,
    this.familiaCodigo,
    this.etiquetas = const [],
    this.pie,
  });

  /// Fichas junto al título, antes del [codigo] (por ejemplo «Obligatorio»).
  final List<Widget> etiquetas;

  /// Bajo el título, a todo el ancho (la explicación de un parámetro).
  final Widget? pie;

  final String titulo;
  final String? detalle;
  final bool enTabla;
  final IconData? icono;
  final Widget? accion;

  /// La clave técnica del grupo, como ficha pequeña junto al [titulo]
  /// (que es la leyenda que lee el usuario).
  final String? codigo;
  final FamiliaCodigoHex? familiaCodigo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final leyenda = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: titulo,
            style: t.titleSmall?.copyWith(
              fontWeight: Peso.titulo,
              color: cs.onSurface,
            ),
          ),
          if (detalle != null)
            TextSpan(
              text: ' — $detalle',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
    final clave = codigo?.trim() ?? '';
    final cabeza =
        clave.isEmpty && etiquetas.isEmpty
            ? leyenda
            : Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                leyenda,
                ...etiquetas,
                if (clave.isNotEmpty) CodigoHex(clave, familia: familiaCodigo),
              ],
            );
    final abajo = pie;
    final texto =
        abajo == null
            ? cabeza
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [cabeza, const SizedBox(height: Esp.xs), abajo],
            );
    final marca =
        icono == null ? null : Icon(icono, size: 20, color: cs.primary);
    final boton = accion;
    // El borde izquierdo en `primary` marca el grupo; el fondo lo separa de
    // las filas sin competir con el estado de cada una.
    final fondo = BoxDecoration(
      color: cs.secondaryContainer.withValues(alpha: 0.45),
      border: Border(left: BorderSide(color: cs.primary, width: 3)),
    );

    if (enTabla) {
      return Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.xs, Esp.m, Esp.xs),
        decoration: fondo,
        child: Row(
          children: [
            if (marca != null) ...[marca, const SizedBox(width: Esp.s)],
            Expanded(child: texto),
            if (boton != null) ...[const SizedBox(width: Esp.m), boton],
          ],
        ),
      );
    }
    // Un borde de un solo lado no admite `borderRadius`: se recorta.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Container(
          padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.s),
          decoration: fondo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (marca != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: marca,
                    ),
                    const SizedBox(width: Esp.s),
                  ],
                  Expanded(child: texto),
                ],
              ),
              if (boton != null) ...[
                const SizedBox(height: Esp.s),
                Align(alignment: Alignment.centerRight, child: boton),
              ] else
                const SizedBox(height: Esp.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// La tarjeta de un reporte: estado junto al título, tipo y día en fichas,
/// horas con su origen y su resumen, monto, comidas y el avance (o el rechazo).
/// En «Mis horas» va sin [mostrarEmpleado]: el título es la jornada.
class TarjetaReporteHex extends StatelessWidget {
  const TarjetaReporteHex(
    this.reporte, {
    super.key,
    this.acciones = const [],
    this.alTocar,
    this.mostrarEmpleado = true,
    this.mostrarSucursal = false,
    this.mostrarComidas = true,
    this.principales = const {},
  });

  final HexReporteEntity reporte;

  /// D41: el operario no ve los códigos de comida (su leyenda no es suya).
  final bool mostrarComidas;
  final List<AccionHex> acciones;
  final VoidCallback? alTocar;
  final bool mostrarEmpleado;

  /// Los botones cuya acción va a la vista en la tarjeta (la tarea del día de
  /// quien revisa o aprueba); el resto queda en el menú.
  final Set<String> principales;

  /// En las bandejas de quien revisa: la sucursal va en la línea de apoyo.
  final bool mostrarSucursal;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    final apoyo = [
      if (mostrarEmpleado) fechaHex(r.fechaJornada),
      if (mostrarSucursal) r.nombreSucursal ?? '',
    ].where((p) => p.isNotEmpty).join(' · ');
    final tipo = r.tipo.isNotEmpty || r.tipoTexto.isNotEmpty;
    final dia = r.tipoDia.isNotEmpty || r.tipoDiaTexto.isNotEmpty;
    final comidas = mostrarComidas && (r.comidas ?? '').trim().isNotEmpty;
    final principal = accionPrincipalHex(acciones, principales);
    return TarjetaHex(
      titulo:
          mostrarEmpleado
              ? oGuionHex(r.nombreEmpleado)
              : 'Jornada ${fechaHex(r.fechaJornada)}',
      subtitulo: apoyo,
      estado: EtiquetaEstadoHex(r.estado, r.estadoTexto),
      accionPrincipal: principal,
      acciones: [
        for (final a in acciones)
          if (a != principal) a,
      ],
      alTocar: alTocar,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tipo || dia) ...[
            Wrap(
              spacing: Esp.xs,
              runSpacing: Esp.xs,
              children: [
                if (tipo) TipoReporteHex(r.tipo, r.tipoTexto),
                if (dia) TipoDiaHex(r.tipoDia, r.tipoDiaTexto),
              ],
            ),
            const SizedBox(height: Esp.m),
          ],
          // Adenda D37: en las bandejas, el aviso entero antes de firmar.
          if (mostrarEmpleado && AvisoSalidaHex.hay(r)) ...[
            AvisoSalidaHex(r),
            const SizedBox(height: Esp.m),
          ],
          InicioFinHex(r),
          // D36: el tiempo en palabras del SP, si lo mandó.
          if ((r.resumenTiempo ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: Esp.xs),
            Text(r.resumenTiempo!.trim(), style: context.apagado()),
          ],
          if (r.verMontos || comidas) ...[
            const SizedBox(height: Esp.s),
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // D38: el dinero solo si el SP lo deja ver.
                if (r.verMontos)
                  MontoHex(r.montoTotal, provisional: r.esProvisional),
                if (comidas) ComidasHex(r.comidas, explicar: true),
              ],
            ),
          ],
        ],
      ),
      etiquetas: [
        if (r.esEditado) const EtiquetaEditadoHex(),
        if (r.avisoBiometrico) const EtiquetaAvisoBiometricoHex(),
        if (r.sinSalidaMarcada) EtiquetaSinSalidaHex(r.avisoSalida),
      ],
      pie: AvanceReporteHex(r, compacto: true),
    );
  }
}
