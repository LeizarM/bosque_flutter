import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/asistencia_dia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart'
    show horaCorta, registrarMarcacionOlvidada;
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El reporte mensual, como calendario: un vistazo alcanza para ver el patrón
/// (¿faltó siempre los mismos días? ¿todos los sábados que no le tocaban están
/// bien marcados?), algo que una lista larga no muestra tan rápido.
///
/// **Por qué esta pantalla existe.** El reporte legacy (`p_Rpt_Biometrico`)
/// mezclaba "faltó" con "no tenía por qué venir" en una sola columna. Acá cada
/// día trae su [AsistenciaDiaEntity.estado] ya resuelto por el backend, así
/// que la grilla sólo tiene que mostrarlo distinto — nunca recalcularlo.
///
/// **Tocar un día también deja registrar una marcación olvidada ahí mismo**
/// (`registrarMarcacionOlvidada`, compartida con la pestaña Marcaciones
/// Olvidadas): corregir el día que se está mirando no debería obligar a
/// cambiar de pestaña y volver a buscar al mismo empleado.
class CalendarioAsistencia extends StatelessWidget {
  const CalendarioAsistencia({
    super.key,
    required this.mes,
    required this.dias,
    required this.anchoDisponible,
    required this.userId,
    required this.codEmpleado,
  });

  /// El mes mostrado (día siempre 1).
  final DateTime mes;
  final List<AsistenciaDiaEntity> dias;

  /// El ancho del panel donde vive esto — no `MediaQuery`, por la misma razón
  /// que el resto de los módulos de RR.HH.: adentro del dashboard el sidebar
  /// se come su parte (ver `Aire` en `tokens_bosque.dart`).
  final double anchoDisponible;

  /// A quién se le registra la marcación olvidada si se toca un día:
  /// [userId] es el usuario del reloj biométrico (`USERID`), [codEmpleado]
  /// el empleado de Bosque — los mismos dos datos que usa la pestaña
  /// Marcaciones Olvidadas.
  final int userId;
  final int codEmpleado;

  @override
  Widget build(BuildContext context) {
    final porDia = {for (final d in dias) d.fecha.day: d};
    final diasEnMes = DateTime(mes.year, mes.month + 1, 0).day;
    // DateTime.weekday: 1=lunes...7=domingo — coincide con el orden que se
    // quiere mostrar, así que el offset es directo.
    final offset = DateTime(mes.year, mes.month, 1).weekday - 1;

    // Bajo ~500 px una celda no entra con número + ícono; se cae a lista.
    final esListaAngosta = anchoDisponible < 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Resumen(dias: dias),
        const SizedBox(height: Esp.l),
        if (esListaAngosta)
          _ListaAngosta(
            mes: mes,
            diasEnMes: diasEnMes,
            porDia: porDia,
            userId: userId,
            codEmpleado: codEmpleado,
          )
        else
          _Grilla(
            mes: mes,
            diasEnMes: diasEnMes,
            offset: offset,
            porDia: porDia,
            userId: userId,
            codEmpleado: codEmpleado,
          ),
        const SizedBox(height: Esp.l),
        const _Leyenda(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMEN
// ═══════════════════════════════════════════════════════════════════════════

class _Resumen extends StatelessWidget {
  const _Resumen({required this.dias});
  final List<AsistenciaDiaEntity> dias;

  @override
  Widget build(BuildContext context) {
    final faltas = dias.where((d) => d.estado == 'FALTA').length;
    final trabajados = dias.where((d) => d.estado == 'TRABAJADO').length;
    final justificados = dias.where((d) => d.esJustificado).length;

    return Wrap(
      spacing: Esp.xl,
      runSpacing: Esp.s,
      children: [
        _Cifra(
          etiqueta: 'Trabajados',
          valor: trabajados,
          color: Theme.of(context).colorScheme.primary,
        ),
        _Cifra(
          etiqueta: 'Faltas',
          valor: faltas,
          color: Theme.of(context).colorScheme.error,
          destacar: faltas > 0,
        ),
        _Cifra(etiqueta: 'Días sin exigencia', valor: justificados),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.etiqueta,
    required this.valor,
    this.color,
    this.destacar = false,
  });

  final String etiqueta;
  final int valor;
  final Color? color;
  final bool destacar;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$valor',
        style: context
            .numero(fuerte: true, color: color)
            ?.copyWith(
              fontSize: 22,
              fontWeight: destacar ? Peso.dato : Peso.titulo,
            ),
      ),
      Text(etiqueta, style: context.apagado()),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GRILLA (Aire.medio / Aire.amplio)
// ═══════════════════════════════════════════════════════════════════════════

const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class _Grilla extends StatelessWidget {
  const _Grilla({
    required this.mes,
    required this.diasEnMes,
    required this.offset,
    required this.porDia,
    required this.userId,
    required this.codEmpleado,
  });

  final DateTime mes;
  final int diasEnMes;
  final int offset;
  final Map<int, AsistenciaDiaEntity> porDia;
  final int userId;
  final int codEmpleado;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return Column(
      children: [
        Row(
          children: [
            for (final d in _diasSemana)
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: context.apagado()?.copyWith(fontWeight: Peso.titulo),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Esp.s),
        // La proporción de la celda se calcula del ancho REAL que le toca acá
        // adentro (no del ancho de la pestaña completa, que no es lo mismo
        // una vez restados el padding y el tope de 900 px) — así se puede
        // aplanar agresivo en pantalla ancha sin desbordar en la franja
        // angosta donde todavía se usa grilla y no lista (`Aire.justo`,
        // antes de caer a `_ListaAngosta`). Un número fijo (se probó 2.0) se
        // veía bien en un monitor ancho pero el texto del día + el ícono no
        // entraban en una celda de ~60px de ancho.
        LayoutBuilder(
          builder: (context, tamano) {
            final anchoCelda = (tamano.maxWidth - 6 * Esp.s) / 7;
            // 68 (subido de 52 al agregar la etiqueta de estado dentro de la
            // celda) deja ~60px de contenido después del padding vertical —
            // suficiente para el número del día + ícono + una etiqueta corta
            // ("Vacación", "Feriado"...) con margen. Nunca más cuadrada que
            // la original (1.15) ni más chata que 2.0. El `FittedBox` de
            // _CeldaDia es la última red de seguridad: si en la franja más
            // angosta ni así entra bien, encoge en vez de desbordar.
            const alturaMinimaCelda = 68.0;
            final aspectRatio = (anchoCelda / alturaMinimaCelda).clamp(
              1.15,
              2.0,
            );
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: Esp.s,
                mainAxisSpacing: Esp.s,
                childAspectRatio: aspectRatio,
              ),
              itemCount: offset + diasEnMes,
              itemBuilder: (context, i) {
                if (i < offset) return const SizedBox.shrink();
                final dia = i - offset + 1;
                final fecha = DateTime(mes.year, mes.month, dia);
                return _CeldaDia(
                  dia: dia,
                  fecha: fecha,
                  entrada: porDia[dia],
                  esHoy:
                      hoy.year == fecha.year &&
                      hoy.month == fecha.month &&
                      hoy.day == fecha.day,
                  userId: userId,
                  codEmpleado: codEmpleado,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CeldaDia extends ConsumerWidget {
  const _CeldaDia({
    required this.dia,
    required this.fecha,
    required this.entrada,
    required this.esHoy,
    required this.userId,
    required this.codEmpleado,
  });

  final int dia;
  final DateTime fecha;
  final AsistenciaDiaEntity? entrada;
  final bool esHoy;
  final int userId;
  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color =
        entrada == null
            ? ColorDeEstado(cs.surfaceContainerHighest, cs.onSurfaceVariant)
            : colorDeAsistencia(cs, entrada!.estado);

    // Radio concéntrico: el mismo valor por fuera (el anillo de "hoy") y por
    // dentro (la celda) — un radio distinto entre los dos es lo primero que
    // se ve "raro" en una superficie anidada.
    final radio = BorderRadius.circular(Esquina.chica);

    // Antes la celda entera se pintaba con el color pleno del estado — un
    // bloque sólido y saturado por día, 31 a la vez. Acá el color queda como
    // acento (franja + ícono + etiqueta) sobre una base tenida, no un bloque
    // saturado. Empezó en 0.12 (casi imperceptible, feriado/vacación no se
    // distinguían de un día en blanco — pedido explícito del usuario) y
    // subió a 0.35: suficiente para notarse de un vistazo sin volver a la
    // "cuadrícula de colores a pleno" del diseño original.
    final fondo = Color.alphaBlend(
      color.fondo.withValues(alpha: 0.35),
      cs.surface,
    );

    return Container(
      // El anillo de "hoy" es el único borde puramente decorativo — comunica
      // una posición, no un estado — así que se mantiene aparte de la franja
      // de color, que sí es estructural (ver better-ui: bordes para
      // estructura/estado, no para relleno).
      decoration: BoxDecoration(
        borderRadius: radio,
        border: esHoy ? Border.all(color: cs.primary, width: 1.5) : null,
      ),
      padding: esHoy ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
      child: Material(
        color: fondo,
        borderRadius: radio,
        child: InkWell(
          borderRadius: radio,
          onTap:
              () => _mostrarDetalle(
                context,
                ref,
                fecha,
                entrada,
                userId: userId,
                codEmpleado: codEmpleado,
              ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radio,
              border: Border(left: BorderSide(color: color.fondo, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(Esp.s, Esp.xs, Esp.xs, Esp.xs),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dia',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: esHoy ? Peso.titulo : Peso.dato,
                        fontFeatures: cifrasTabulares,
                      ),
                    ),
                    // Antes el porqué del día (vacación, feriado, falta...)
                    // sólo se veía tocando la celda para abrir el detalle. Ahora
                    // el mismo motivo corto que ya usa el PDF (columna Obs)
                    // aparece adentro de la celda — de un vistazo, sin abrir
                    // nada. `FittedBox` en vez de un tamaño de fuente fijo: si
                    // la celda queda muy angosta (ver `alturaMinimaCelda` en
                    // `_Grilla`) encoge el contenido en vez de desbordar.
                    if (entrada != null)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconoDeEstado(entrada!.estado),
                                size: 14,
                                color: color.texto,
                              ),
                              Text(
                                _textoDeCelda(entrada!),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color.texto,
                                  fontWeight: Peso.dato,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // Marca de "problema" (falta, o trabajó con atraso) — un
                // vistazo alcanza para saber si vale la pena abrir la celda,
                // sin competir con el resto del contenido de adentro.
                if (entrada?.tieneProblema ?? false)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.priority_high, size: 13, color: cs.error),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA (Aire.justo — menos de ~500 px, la grilla no entra legible)
// ═══════════════════════════════════════════════════════════════════════════

class _ListaAngosta extends StatelessWidget {
  const _ListaAngosta({
    required this.mes,
    required this.diasEnMes,
    required this.porDia,
    required this.userId,
    required this.codEmpleado,
  });

  final DateTime mes;
  final int diasEnMes;
  final Map<int, AsistenciaDiaEntity> porDia;
  final int userId;
  final int codEmpleado;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: diasEnMes,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final dia = i + 1;
        final fecha = DateTime(mes.year, mes.month, dia);
        return _FilaAngosta(
          dia: dia,
          fecha: fecha,
          entrada: porDia[dia],
          esHoy:
              hoy.year == fecha.year &&
              hoy.month == fecha.month &&
              hoy.day == fecha.day,
          userId: userId,
          codEmpleado: codEmpleado,
        );
      },
    );
  }
}

class _FilaAngosta extends ConsumerWidget {
  const _FilaAngosta({
    required this.dia,
    required this.fecha,
    required this.entrada,
    required this.esHoy,
    required this.userId,
    required this.codEmpleado,
  });

  final int dia;
  final DateTime fecha;
  final AsistenciaDiaEntity? entrada;
  final bool esHoy;
  final int userId;
  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color =
        entrada == null
            ? ColorDeEstado(cs.surfaceContainerHighest, cs.onSurfaceVariant)
            : colorDeAsistencia(cs, entrada!.estado);

    return ListTile(
      onTap:
          () => _mostrarDetalle(
            context,
            ref,
            fecha,
            entrada,
            userId: userId,
            codEmpleado: codEmpleado,
          ),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.alphaBlend(
            color.fondo.withValues(alpha: 0.35),
            cs.surface,
          ),
          border: Border.all(
            color: esHoy ? cs.primary : color.fondo.withValues(alpha: 0.5),
            width: esHoy ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$dia',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: esHoy ? Peso.titulo : Peso.dato,
          ),
        ),
      ),
      title: Text(_diasSemana[fecha.weekday - 1]),
      subtitle:
          entrada == null
              ? null
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_etiquetaDeEstado(entrada!.estado)),
                  // Mismo criterio que la marca de la celda ancha: falta, o
                  // trabajó con atraso — acá al lado de la etiqueta en vez de
                  // superpuesta al avatar (evita cualquier riesgo de recorte
                  // dentro del slot fijo de `ListTile.leading`).
                  if (entrada!.tieneProblema) ...[
                    const SizedBox(width: Esp.xs),
                    Icon(Icons.priority_high, size: 14, color: cs.error),
                  ],
                ],
              ),
      trailing:
          entrada == null
              ? null
              : Icon(_iconoDeEstado(entrada!.estado), color: color.fondo),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEYENDA — el color no es el único canal: acá está el texto de cada uno.
// ═══════════════════════════════════════════════════════════════════════════

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  static const _estados = [
    'TRABAJADO',
    'FALTA',
    'FERIADO',
    'SABADO_LIBRE',
    'PERMISO',
    'VACACION',
    'SIN_HORARIO',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.s,
      children: [
        for (final e in _estados)
          _ItemLeyenda(
            color: colorDeAsistencia(cs, e).fondo,
            icono: _iconoDeEstado(e),
            texto: _etiquetaDeEstado(e),
          ),
      ],
    );
  }
}

class _ItemLeyenda extends StatelessWidget {
  const _ItemLeyenda({
    required this.color,
    required this.icono,
    required this.texto,
  });
  final Color color;
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          icono,
          size: 10,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(width: Esp.xs),
      Text(texto, style: context.apagado()),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// DETALLE DEL DÍA — con la acción de registrar una marcación olvidada.
// ═══════════════════════════════════════════════════════════════════════════

/// [dia] puede venir `null` (el backend siempre trae una fila por día del
/// mes, pero si algún día faltara igual se puede abrir el detalle para
/// cargar una marcación a mano — no hace falta que el reporte lo cubra
/// primero).
void _mostrarDetalle(
  BuildContext context,
  WidgetRef ref,
  DateTime fecha,
  AsistenciaDiaEntity? dia, {
  required int userId,
  required int codEmpleado,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (contextHoja) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Esp.xl, 0, Esp.xl, Esp.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fechaLarga(fecha), style: context.tituloSeccion()),
            const SizedBox(height: Esp.s),
            if (dia != null) ...[
              Etiqueta(
                texto: _etiquetaDeEstado(dia.estado),
                tono: _tonoDeEstado(dia.estado),
              ),
              if (dia.motivo != null && dia.motivo!.isNotEmpty) ...[
                const SizedBox(height: Esp.m),
                Text(dia.motivo!, style: context.apagado()),
              ],
              if (dia.horaEntradaEsperada != null ||
                  dia.horaEntradaReal != null) ...[
                const SizedBox(height: Esp.l),
                _FilaHora(
                  etiqueta: 'Entrada',
                  esperada: dia.horaEntradaEsperada,
                  real: dia.horaEntradaReal,
                ),
                const SizedBox(height: Esp.s),
                _FilaHora(
                  etiqueta: 'Salida',
                  esperada: dia.horaSalidaEsperada,
                  real: dia.horaSalidaReal,
                ),
              ],
            ] else
              Text(
                'Sin datos de asistencia para este día.',
                style: context.apagado(),
              ),
            const SizedBox(height: Esp.xl),
            const Divider(height: 1),
            const SizedBox(height: Esp.m),
            // Mismo botón "Registrar marcación olvidada" que la pestaña
            // Marcaciones Olvidadas — esa pestaña ya está gateada por
            // `marOlv` a nivel de BiometricoScreen, pero este atajo vive
            // adentro de Reporte, que no tiene botón propio. Sin este
            // PermissionWidget, alguien sin `marOlv` no vería la pestaña
            // pero igual podría cargar una marcación a mano desde acá.
            PermissionWidget(
              buttonName: 'marOlv',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Registrar marcación olvidada'),
                  onPressed: () async {
                    Navigator.pop(contextHoja);
                    if (!context.mounted) return;
                    await registrarMarcacionOlvidada(
                      context,
                      ref,
                      userId: userId,
                      codEmpleado: codEmpleado,
                      fechaSugerida: fecha,
                    );
                    if (!context.mounted) return;
                    ref.invalidate(
                      reporteBiometricoProvider(
                        ReporteBiometricoParams(
                          codEmpleado: BigInt.from(codEmpleado),
                          anio: fecha.year,
                          mes: fecha.month,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FilaHora extends StatelessWidget {
  const _FilaHora({
    required this.etiqueta,
    required this.esperada,
    required this.real,
  });
  final String etiqueta;
  final DateTime? esperada;
  final DateTime? real;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(width: 70, child: Text(etiqueta, style: context.apagado())),
        Expanded(
          child: Text(
            'esperada: ${horaCorta(esperada)}',
            style: context.numero(),
          ),
        ),
        Expanded(
          child: Text(
            'real: ${horaCorta(real)}',
            style: context.numero(
              fuerte: real != null,
              color: real == null ? cs.error : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

IconData _iconoDeEstado(String estado) => switch (estado) {
  'TRABAJADO' => Icons.check_circle_outline,
  'FALTA' => Icons.cancel_outlined,
  'FERIADO' => Icons.celebration_outlined,
  'SABADO_LIBRE' => Icons.weekend_outlined,
  'PERMISO' => Icons.assignment_outlined,
  'VACACION' => Icons.beach_access_outlined,
  'SIN_HORARIO' => Icons.remove,
  _ => Icons.help_outline,
};

String _etiquetaDeEstado(String estado) => switch (estado) {
  'TRABAJADO' => 'Trabajó',
  'FALTA' => 'Falta',
  'FERIADO' => 'Feriado',
  'SABADO_LIBRE' => 'Descanso',
  'PERMISO' => 'Permiso',
  'VACACION' => 'Vacación',
  'SIN_HORARIO' => 'Sin horario asignado',
  _ => estado,
};

/// El [AsistenciaDiaEntity.motivo] (si hay) en vez de la etiqueta genérica
/// del estado — "DIA DE BOLIVIA" dice más que "Feriado" a secas, mismo
/// criterio que la columna Obs del PDF. Recortado a ~24 caracteres: los
/// motivos de una marcación olvidada a medias ("Marcó entrada pero no
/// registró salida...") son oraciones largas que el `FittedBox` de la celda
/// terminaría encogiendo hasta ilegible en vez de simplemente acortar.
String _textoDeCelda(AsistenciaDiaEntity dia) {
  final motivo = dia.motivo?.trim();
  if (motivo == null || motivo.isEmpty)
    return _etiquetaCortaDeEstado(dia.estado);
  return motivo.length > 24 ? '${motivo.substring(0, 23)}…' : motivo;
}

/// Igual que [_etiquetaDeEstado] pero recortada para entrar en una celda
/// chica de la grilla ("Descanso (sábado)" no entra en ~60px de ancho;
/// "Libre" sí). La hoja de detalle sigue usando la versión larga.
String _etiquetaCortaDeEstado(String estado) => switch (estado) {
  'TRABAJADO' => 'Trabajó',
  'FALTA' => 'Falta',
  'FERIADO' => 'Feriado',
  'SABADO_LIBRE' => 'Libre',
  'PERMISO' => 'Permiso',
  'VACACION' => 'Vacación',
  'SIN_HORARIO' => '',
  _ => estado,
};

TonoEtiqueta _tonoDeEstado(String estado) => switch (estado) {
  'TRABAJADO' => TonoEtiqueta.exito,
  'FALTA' => TonoEtiqueta.error,
  'FERIADO' || 'VACACION' || 'PERMISO' => TonoEtiqueta.aviso,
  _ => TonoEtiqueta.neutro,
};

/// `EEEE d 'de' MMMM, yyyy` a mano — sin `intl` por lo mismo que [fechaCorta].
String fechaLarga(DateTime f) {
  const meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${_diasSemana[f.weekday - 1]} ${f.day} de ${meses[f.month - 1]}, ${f.year}';
}
