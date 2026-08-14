import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/tramo_saldo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/detalle_tramo_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// De dónde salen los días: los 5 tramos del sistema anterior. Es la pestaña
/// «Desglose».
///
/// **Origen:** `p_list_Permiso 'D'`. Las etiquetas de los tramos las escribe el
/// propio SP y llegan con las fechas adentro; se muestran **literales**, sin
/// corregirles la ortografía ni acortarlas. El criterio de aceptación es que
/// sean carácter por carácter iguales a las del modal viejo, que es contra lo
/// que RR.HH. va a comparar.
class DesgloseTab extends ConsumerWidget {
  const DesgloseTab({super.key, required this.codEmpleado});

  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desglose = ref.watch(desgloseSaldoProvider(codEmpleado));

    return desglose.when(
      loading: () => const Cargando(),
      error:
          (e, _) => ErrorDelDato(
            error: e,
            onReintentar:
                () => ref.invalidate(desgloseSaldoProvider(codEmpleado)),
          ),
      data: (d) {
        if (d == null) {
          return const MensajeVacio(
            icono: Icons.table_rows_outlined,
            titulo: 'Sin desglose',
            detalle:
                'La consulta no devolvió datos para este empleado. Verifique en '
                'el sistema anterior que tenga cargo y relación laboral activa.',
          );
        }

        return LayoutBuilder(
          builder: (context, cajon) {
            final aire = Aire.de(cajon.maxWidth);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(desgloseSaldoProvider(codEmpleado));
                await ref.read(desgloseSaldoProvider(codEmpleado).future);
              },
              child: ListView(
                padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!d.tieneFechaBeneficio) ...[
                            const AvisoDelDato(
                              icono: Icons.warning_amber_rounded,
                              // Corrección al borrador del plan: sin fecha de
                              // beneficio NO son cinco ceros. Sólo los tramos 1
                              // y 4 dan 0; el 2 muestra toda la historia, el 3
                              // las duodécimas y el 5 lo programado.
                              texto:
                                  'Este empleado no tiene fecha de inicio de '
                                  'beneficio cargada. Los tramos que dependen '
                                  'del año laboral quedan en cero y el resto '
                                  'muestra toda la historia: el desglose no se '
                                  'puede leer como los demás.',
                            ),
                            const SizedBox(height: Esp.m),
                          ],
                          if (d.desgloseAplicable)
                            _Tramos(desglose: d, aire: aire)
                          else
                            _SinDesglose(desglose: d),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUPUESTO D2 — pendiente de confirmación de RR.HH. (ver plan §5)
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que se ve cuando el desglose por año laboral no aplica — **hoy 57 de 85
/// empleados**.
///
/// Con `datoAnios < 2` el `CASE` del tramo 2 del SP cae en el `ELSE` y suma
/// **todas** las asignaciones sin filtro de fecha, mientras la etiqueta que él
/// mismo arma dice «Vacación correspondiente a su **-1º** año cumplido», con un
/// rango que termina antes de la fecha de inicio de beneficio. Y ese número
/// entra en el total.
///
/// Así que **acá no se pintan los cinco tramos**: se muestran los tres números
/// que sí son defendibles. Mostrar la cifra igual sería publicar un total que
/// nadie puede sostener frente a un reclamo, y la etiqueta «-1º» convierte un
/// error del sistema viejo en un error de este.
class _SinDesglose extends StatelessWidget {
  const _SinDesglose({required this.desglose});

  final DesgloseSaldoEntity desglose;

  @override
  Widget build(BuildContext context) {
    // Los tres que no dependen de la rama degenerada. Se buscan por `clave` y
    // no por posición: el orden del `SELECT` del SP no es un contrato.
    final asignados = _tramo('ASIGNADA_ANIO');
    final utilizados = _tramo('UTILIZADA');
    final programados = _tramo('PROGRAMADA');

    return Bloque(
      icono: Icons.info_outline,
      titulo: 'El desglose por año laboral no aplica',
      // El acta de D2 escribe «todavía no cumplió su primer año de beneficio».
      // Con `datoAnios == 1` —16 de los 57— eso sería falso: la rama degenerada
      // del SP es `(datoAnios − 1) <= 0`, o sea *menos de dos años*. Se dice lo
      // que de verdad pasa. Si RR.HH. prefiere el texto literal del acta, es
      // esta línea y ninguna otra.
      explicacion:
          'Este empleado todavía no cumplió dos años de beneficio '
          '(${_anios(desglose.datoAnios)}), así que el sistema anterior no '
          'puede separar el año en curso del anterior. Estos son los números '
          'que sí valen.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Esp.xl,
            runSpacing: Esp.m,
            children: [
              Metrica(
                rotulo: 'Asignados hasta hoy',
                texto: asignados?.montoTxt ?? '--',
                valor: asignados?.monto,
              ),
              Metrica(
                rotulo: 'Utilizados',
                texto: utilizados?.montoTxt ?? '--',
                valor: utilizados?.monto,
              ),
              Metrica(
                rotulo: 'Programados',
                texto: programados?.montoTxt ?? '--',
                valor: programados?.monto,
              ),
            ],
          ),
          const SizedBox(height: Esp.m),
          Text(
            'El saldo total del empleado está en la pestaña «Saldo». El '
            'desglose en cinco tramos vuelve a estar disponible cuando cumpla '
            'dos años de beneficio.',
            style: context.apagado(),
          ),
        ],
      ),
    );
  }

  TramoSaldoEntity? _tramo(String clave) {
    for (final t in desglose.tramos) {
      if (t.clave == clave) return t;
    }
    return null;
  }

  static String _anios(int n) => switch (n) {
    <= 0 => 'no llegó al primero',
    1 => 'lleva 1 año',
    _ => 'lleva $n años',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// LOS 5 TRAMOS
// ═══════════════════════════════════════════════════════════════════════════

class _Tramos extends StatelessWidget {
  const _Tramos({required this.desglose, required this.aire});

  final DesgloseSaldoEntity desglose;
  final Aire aire;

  @override
  Widget build(BuildContext context) => Bloque(
    icono: Icons.account_tree_outlined,
    titulo: 'De dónde salen los días',
    explicacion:
        'Las cinco líneas son las del sistema anterior, con sus mismos '
        'nombres y fechas.',
    hijo: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La etiqueta real del SP llega a 95 caracteres. En un panel angosto
        // una tabla de dos columnas la parte en cinco renglones y el número
        // queda flotando lejos de su fila; una lista deja que el texto ocupe
        // el ancho entero y el monto vaya debajo, pegado a lo que describe.
        if (aire.esChico) _lista(context) else _tabla(context),
        const Divider(height: Esp.xl),
        _leyenda(context),
        const SizedBox(height: Esp.m),
        _total(context),
      ],
    ),
  );

  /// Qué significa cada color. Un código cromático sin leyenda obliga a
  /// adivinar, y acá lo que se adivina es si un número suma o resta.
  Widget _leyenda(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: Esp.l,
      runSpacing: Esp.xs,
      children: [
        // Cortas a propósito: en 360 px una leyenda de tres frases largas
        // desborda la fila, y una leyenda que no entra no explica nada.
        _marca(context, cs.primary, 'Suma'),
        _marca(context, cs.tertiary, 'Resta'),
        _marca(context, cs.onSurfaceVariant, 'No cuenta'),
      ],
    );
  }

  Widget _marca(BuildContext context, Color color, String texto) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: Esp.xs),
      Flexible(child: Text(texto, style: context.apagado())),
    ],
  );

  Widget _lista(BuildContext context) => Column(
    children: [
      for (final t in desglose.tramos)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Esp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.etiqueta, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Esp.xs),
              // `Wrap` y no `Row`: «12,9 días» junto a «No suma al total» se
              // pasa 25 px del ancho de un teléfono de 360, y un `Row` que no
              // entra no se acomoda — pinta la franja amarilla y negra.
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    t.montoConSigno,
                    style: context.numero(
                      fuerte: true,
                      color: _colorDelTramo(context, t),
                    ),
                  ),
                  if (t.esInformativo)
                    const Etiqueta(
                      texto: 'No suma al total',
                      tono: TonoEtiqueta.aviso,
                    ),
                  if (t.tieneDetalle) _verDetalle(context, t),
                ],
              ),
            ],
          ),
        ),
    ],
  );

  /// El acceso al detalle. Va como botón con texto y no como una fila
  /// misteriosamente tocable: de los cinco tramos sólo tres se abren, y sin
  /// rótulo nadie descubre cuáles.
  /// El color del monto, y es lo único cromático de la pantalla.
  ///
  /// Codifica el `signo` que ya venía en el contrato y que hasta ahora sólo
  /// existía como texto: los cinco tramos se veían idénticos y no había forma
  /// de saber cuál sumaba. Tres roles del `ColorScheme`, no tres colores
  /// fijos — la app tiene 9 semillas y modo oscuro, así que cualquier hex se
  /// rompería en ocho de los nueve temas.
  ///
  /// El negativo pisa todo lo demás: un tramo en rojo es el dato que RR.HH.
  /// necesita ver antes que cualquier otra cosa.
  Color? _colorDelTramo(BuildContext context, TramoSaldoEntity t) {
    final cs = Theme.of(context).colorScheme;
    if (t.monto < 0) return cs.error;
    if (t.esInformativo) return cs.onSurfaceVariant;
    return t.suma ? cs.primary : cs.tertiary;
  }

  Widget _verDetalle(BuildContext context, TramoSaldoEntity t) => TextButton.icon(
    onPressed:
        () => mostrarDetalleTramo(
          context,
          codEmpleado: desglose.codEmpleado,
          tramo: t,
        ),
    icon: const Icon(Icons.unfold_more, size: 16),
    label: const Text('Ver detalle'),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: Esp.s),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    ),
  );

  Widget _tabla(BuildContext context) => Table(
    // La etiqueta se queda con todo el ancho sobrante y el número pide sólo lo
    // que mide: al revés, «220 días» y «3,5 días» partirían la columna en dos
    // anchos distintos según el empleado.
    columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      for (final t in desglose.tramos)
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Esp.s,
                horizontal: Esp.xs,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      t.etiqueta,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (t.esInformativo) ...[
                    const SizedBox(width: Esp.s),
                    const Etiqueta(texto: 'No suma', tono: TonoEtiqueta.aviso),
                  ],
                  if (t.tieneDetalle) _verDetalle(context, t),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Esp.s,
                horizontal: Esp.m,
              ),
              child: Text(
                t.montoConSigno,
                textAlign: TextAlign.right,
                style: context.numero(
                  fuerte: true,
                  color: _colorDelTramo(context, t),
                ),
              ),
            ),
          ],
        ),
    ],
  );

  /// El total, y **por qué da eso**.
  ///
  /// ── SUPUESTO D1 — pendiente de confirmación de RR.HH. (ver plan §5) ──
  /// El total replica exactamente al bean del sistema anterior: DEBE = tramo 1
  /// + tramo 2, HABER = tramo 4 + tramo 5, y el tramo 3 —las duodécimas
  /// acumuladas— **no entra**. Se tomó la opción (c) del plan: se muestran los
  /// dos números desglosados y rotulados, y el tramo que no suma lleva su
  /// etiqueta arriba. Cambiar esta cuenta es cambiar el número que RR.HH.
  /// compara contra el sistema viejo: no se toca sin acta.
  Widget _total(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  desglose.etiquetaTotal,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
                ),
              ),
              const SizedBox(width: Esp.s),
              Text(
                desglose.montoTotalTxt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                  color: desglose.saldoNegativo ? cs.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: Esp.xs),
          Text(
            'Suman ${_num(desglose.montoTotalDebe)} y restan '
            '${_num(desglose.montoTotalHaber)}. La vacación acumulada desde el '
            'último año cumplido no entra en esta cuenta: se muestra aparte '
            'porque el sistema anterior tampoco la sumaba.',
            style: context.apagado(),
          ),
        ],
      ),
    );
  }

  /// Sin decimales cuando no los tiene: «38» y no «38.0», que es cómo lo
  /// escribe el backend en los campos `*Txt`.
  static String _num(double v) =>
      (v == v.roundToDouble() ? v.round().toString() : v.toString()).replaceAll(
        '.',
        ',',
      );
}
