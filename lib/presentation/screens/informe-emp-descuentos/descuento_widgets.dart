import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/descuento_empleado_entity.dart';
import 'package:flutter/material.dart';

/// Widgets de presentación de «Descuentos por Empleado»: el resumen del
/// período (con sumatorias por moneda) y una tarjeta ancha por descuento, con
/// sus tres montos en fila. No conocen el estado ni los providers.

// ═══════════════════════════════════════════════════════════════════════════
// COLOR
// ═══════════════════════════════════════════════════════════════════════════

/// Un matiz con su variante para superficie clara y para oscura.
///
/// **Por qué colores fijos y no del tema.** El resto de los módulos saca el
/// color del `ColorScheme` porque el usuario elige la semilla. Aquí el color es
/// lo que se busca de un vistazo: el tipo de descuento se reconoce por su
/// matiz (préstamo índigo, anticipo naranja, atrasos rojo, multa morado), como
/// en la pantalla de siempre. Por eso son matices propios, que no cambian con
/// la semilla; las dos variantes se eligieron para alcanzar contraste de texto
/// (4,5:1) sobre fondo claro y sobre fondo oscuro.
class MatizDescuento {
  const MatizDescuento(this.claro, this.oscuro);

  final Color claro;
  final Color oscuro;

  Color de(Brightness brillo) => brillo == Brightness.dark ? oscuro : claro;
}

const _indigo = MatizDescuento(Color(0xFF3949AB), Color(0xFF9FA8DA));
const _naranja = MatizDescuento(Color(0xFFC2410C), Color(0xFFFDBA74));
const _rojo = MatizDescuento(Color(0xFFC62828), Color(0xFFEF9A9A));
const _morado = MatizDescuento(Color(0xFF7B1FA2), Color(0xFFCE93D8));
const _turquesa = MatizDescuento(Color(0xFF00796B), Color(0xFF80CBC4));
const _violeta = MatizDescuento(Color(0xFF5E35B1), Color(0xFFB39DDB));
const _verde = MatizDescuento(Color(0xFF2E7D32), Color(0xFFA5D6A7));
const _pizarra = MatizDescuento(Color(0xFF455A64), Color(0xFFB0BEC5));

/// Color e ícono de un tipo de descuento. El ícono y el texto dicen el tipo,
/// así que el color no es el único canal.
({Color color, IconData icono}) estiloDeTipoDescuento(
  Brightness brillo,
  String tipo,
) {
  final t = tipo.trim().toLowerCase();
  return switch (t) {
    _ when t.startsWith('prest') => (
      color: _indigo.de(brillo),
      icono: Icons.account_balance_outlined,
    ),
    'anticipo' => (color: _naranja.de(brillo), icono: Icons.payments_outlined),
    'atrasos' => (color: _rojo.de(brillo), icono: Icons.alarm_off_outlined),
    'multa' => (color: _morado.de(brillo), icono: Icons.gavel_outlined),
    _ => (color: _turquesa.de(brillo), icono: Icons.receipt_long_outlined),
  };
}

/// Lo que se descontó: en rojo, es dinero que sale.
Color colorDescontado(Brightness brillo) => _rojo.de(brillo);

/// Lo que queda por descontar.
Color colorSaldo(Brightness brillo) => _violeta.de(brillo);

/// Ejecutado en verde; cualquier otro estado, en pizarra (el color no grita
/// lo que todavía no pasó).
Color colorDeEstadoDescuento(Brightness brillo, String estado) =>
    (estado.trim().toLowerCase() == 'ejecutado' ? _verde : _pizarra).de(brillo);

// ═══════════════════════════════════════════════════════════════════════════
// DATOS DERIVADOS
// ═══════════════════════════════════════════════════════════════════════════

class _Totales {
  double descontado = 0;
  double total = 0;
  double saldo = 0;
}

/// Sumatorias por moneda, en orden de aparición. Sumar bolivianos con dólares
/// y rotular el resultado «Bs» daba un número que no significa nada.
Map<String, _Totales> _totalesPorMoneda(List<DescuentoEmpleadoEntity> ds) {
  final grupos = <String, _Totales>{};
  for (final d in ds) {
    final g = grupos.putIfAbsent(FormatoMoneda.unidad(d.moneda), _Totales.new);
    g.descontado += d.montoDescuento;
    g.total += d.montoTotal;
    g.saldo += d.saldoRestante;
  }
  return grupos;
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMEN
// ═══════════════════════════════════════════════════════════════════════════

/// Totales del período: lo descontado este mes, el monto total y el saldo,
/// uno por moneda.
class ResumenDescuentos extends StatelessWidget {
  const ResumenDescuentos({
    super.key,
    required this.descuentos,
    required this.periodo,
  });

  final List<DescuentoEmpleadoEntity> descuentos;

  /// «Septiembre 2026».
  final String periodo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final grupos = _totalesPorMoneda(descuentos);
    final n = descuentos.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.11),
            cs.tertiary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Esp.m,
              runSpacing: Esp.s,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.summarize_outlined, size: 20, color: cs.primary),
                    const SizedBox(width: Esp.s),
                    // Flexible: con texto ampliado pasa a dos líneas en vez
                    // de desbordar.
                    Flexible(
                      child: Text(
                        'Resumen — $periodo',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(
                          fontWeight: Peso.dato,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Esp.m,
                      vertical: Esp.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 14, color: cs.primary),
                        const SizedBox(width: Esp.xs),
                        Text(
                          n == 1 ? '1 descuento' : '$n descuentos',
                          style: t.labelMedium?.copyWith(
                            fontWeight: Peso.dato,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            for (final e in grupos.entries) ...[
              const SizedBox(height: Esp.m),
              // Con una sola moneda no hace falta rotular el grupo.
              if (grupos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: Esp.s),
                  child: Text(
                    e.key.isEmpty ? 'Sin moneda' : e.key,
                    style: t.labelLarge?.copyWith(
                      fontWeight: Peso.titulo,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              _Kpis(unidad: e.key, totales: e.value),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tres cifras. Con espacio, en una fila; sin él, la de lo descontado a todo
/// el ancho y las otras dos lado a lado.
class _Kpis extends StatelessWidget {
  const _Kpis({required this.unidad, required this.totales});

  final String unidad;
  final _Totales totales;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final tres = ancho >= 660;
        // Hacia abajo: la suma de una fila nunca pasa del ancho.
        final tercio = ((ancho - Esp.m * 2) / 3).floorToDouble();
        final mitad = ((ancho - Esp.m) / 2).floorToDouble();

        Widget kpi(
          IconData icono,
          String etiqueta,
          double valor,
          Color? color, {
          required double ancho,
          bool destacado = false,
          bool conIcono = true,
        }) => SizedBox(
          width: ancho,
          child: _Kpi(
            icono: icono,
            etiqueta: etiqueta,
            valor: FormatoMoneda.conUnidad(unidad, valor),
            color: color,
            destacado: destacado,
            conIcono: conIcono,
          ),
        );

        return Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            kpi(
              Icons.money_off_outlined,
              'Monto descontado',
              totales.descontado,
              colorDescontado(brillo),
              ancho: tres ? tercio : ancho,
              destacado: true,
            ),
            kpi(
              Icons.account_balance_outlined,
              'Monto total',
              totales.total,
              null,
              ancho: tres ? tercio : mitad,
              conIcono: tres,
            ),
            kpi(
              Icons.account_balance_wallet_outlined,
              'Saldo pendiente',
              totales.saldo,
              colorSaldo(brillo),
              ancho: tres ? tercio : mitad,
              conIcono: tres,
            ),
          ],
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.destacado,
    required this.conIcono,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  /// Color del valor y del ícono; sin él, el del texto normal.
  final Color? color;
  final bool destacado;

  /// Sin ícono cuando la tarjeta es angosta (dos por fila en un teléfono).
  final bool conIcono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            destacado
                ? c.withValues(alpha: 0.10)
                : cs.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: destacado ? c.withValues(alpha: 0.35) : cs.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Row(
          children: [
            if (conIcono) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Esquina.chica),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Esp.s),
                  child: Icon(icono, size: 20, color: c),
                ),
              ),
              const SizedBox(width: Esp.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.apagado(),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valor,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                        color: c,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

/// Una tarjeta ancha por descuento, una debajo de otra: a todo el ancho los
/// tres montos quedan en fila, como una fila de tabla.
class ListaDescuentos extends StatelessWidget {
  const ListaDescuentos({super.key, required this.descuentos});

  final List<DescuentoEmpleadoEntity> descuentos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < descuentos.length; i++) ...[
          if (i > 0) const SizedBox(height: Esp.m),
          TarjetaDescuento(descuentos[i]),
        ],
      ],
    );
  }
}

class TarjetaDescuento extends StatelessWidget {
  const TarjetaDescuento(this.descuento, {super.key});

  final DescuentoEmpleadoEntity descuento;

  @override
  Widget build(BuildContext context) {
    final d = descuento;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final brillo = cs.brightness;
    final tipo = estiloDeTipoDescuento(brillo, d.tipoDescuento);
    final oscuro = brillo == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs, color: tipo.color.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado teñido con el matiz del tipo: se reconoce al recorrer
          // la lista sin leer.
          ColoredBox(
            color: tipo.color.withValues(alpha: oscuro ? 0.16 : 0.09),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Esp.l,
                vertical: Esp.m,
              ),
              // Wrap con extremos opuestos: el tipo a la izquierda y el estado
              // pegado al borde derecho; si no caben juntos, el estado baja.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Esp.s,
                runSpacing: Esp.xs,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: tipo.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(Esquina.chica),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Esp.xs + 2),
                          child: Icon(tipo.icono, size: 18, color: tipo.color),
                        ),
                      ),
                      const SizedBox(width: Esp.s + 2),
                      Flexible(
                        child: Text(
                          d.tipoDescuento,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                            fontWeight: Peso.dato,
                            color: tipo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (d.estadoDescuento.trim().isNotEmpty)
                    EstadoDescuentoChip(d.estadoDescuento),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Texto(
                  d.descripcion,
                  estilo: t.titleSmall?.copyWith(fontWeight: Peso.dato),
                  lineas: 2,
                ),
                const SizedBox(height: Esp.m),
                _FilaMontos(d),
                if (d.totalCuotas > 0) ...[
                  const SizedBox(height: Esp.m),
                  _Cuotas(d, color: tipo.color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Los tres montos en columnas separadas por un filo: lo descontado en rojo,
/// el monto total neutro y el saldo en violeta. Un cero va apagado: lo que no
/// se descontó no debe competir con lo que sí.
class _FilaMontos extends StatelessWidget {
  const _FilaMontos(this.d);

  final DescuentoEmpleadoEntity d;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brillo = cs.brightness;

    Widget divisor() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m),
      child: SizedBox(
        width: 1,
        child: ColoredBox(color: cs.outlineVariant),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // En una tarjeta angosta (teléfono) «Monto descontado» no cabe en su
        // columna y se cortaba: va como «Descontado».
        final etiquetaDescontado =
            constraints.maxWidth < 420 ? 'Descontado' : 'Monto descontado';
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Monto(
                  etiquetaDescontado,
                  d.moneda,
                  d.montoDescuento,
                  colorDescontado(brillo),
                ),
              ),
              divisor(),
              Expanded(
                child: _Monto('Monto total', d.moneda, d.montoTotal, null),
              ),
              divisor(),
              Expanded(
                child: _Monto(
                  'Saldo restante',
                  d.moneda,
                  d.saldoRestante,
                  colorSaldo(brillo),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Monto extends StatelessWidget {
  const _Monto(this.etiqueta, this.moneda, this.valor, this.color);

  final String etiqueta;
  final String moneda;
  final double valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.apagado(),
        ),
        const SizedBox(height: 2),
        // FittedBox: se achica en vez de desbordar con texto ampliado.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            FormatoMoneda.conUnidad(moneda, valor),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
              color: valor == 0 ? cs.onSurfaceVariant : (color ?? cs.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

/// «Cuota 3 de 12» o, si en el mes se descontó más de una, «Cuotas 3–4 de 12»,
/// con el avance del plan en una barra y en porcentaje.
class _Cuotas extends StatelessWidget {
  const _Cuotas(this.d, {required this.color});

  final DescuentoEmpleadoEntity d;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final total = d.totalCuotas;
    final desde = d.primeraCuotaMes;
    final hasta = d.ultimaCuotaMes > desde ? d.ultimaCuotaMes : desde;
    final varias = hasta > desde;
    final texto =
        varias ? 'Cuotas $desde–$hasta de $total' : 'Cuota $desde de $total';
    final avance = (hasta / total).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered, size: 15, color: cs.onSurfaceVariant),
            const SizedBox(width: Esp.xs + 2),
            Expanded(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(fontWeight: Peso.titulo),
              ),
            ),
            Text(
              '${(avance * 100).round()} %',
              style: t.bodySmall?.copyWith(
                fontWeight: Peso.dato,
                color: color,
                fontFeatures: cifrasTabulares,
              ),
            ),
          ],
        ),
        const SizedBox(height: Esp.s - 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(Esquina.pastilla),
          child: LinearProgressIndicator(
            value: avance,
            minHeight: 7,
            color: color,
            backgroundColor: color.withValues(alpha: 0.16),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS COMUNES
// ═══════════════════════════════════════════════════════════════════════════

/// Estado del descuento: relleno tenue y borde del color del estado, más ícono
/// y texto (el color no es el único canal).
class EstadoDescuentoChip extends StatelessWidget {
  const EstadoDescuentoChip(this.estado, {super.key});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final color = colorDeEstadoDescuento(brillo, estado);
    final ejecutado = estado.trim().toLowerCase() == 'ejecutado';

    // Se achica en vez de desbordar con texto ampliado.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: brillo == Brightness.dark ? 0.18 : 0.12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(Esquina.pastilla),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ejecutado ? Icons.check_circle : Icons.schedule,
                size: 14,
                color: color,
              ),
              const SizedBox(width: Esp.xs),
              Text(
                estado,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: Peso.dato,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto con puntos suspensivos; el tooltip deja leer lo cortado.
class _Texto extends StatelessWidget {
  const _Texto(this.texto, {this.estilo, this.lineas = 1});

  final String texto;
  final TextStyle? estilo;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      texto,
      style: estilo,
      maxLines: lineas,
      overflow: TextOverflow.ellipsis,
    );
    return texto.isEmpty ? t : Tooltip(message: texto, child: t);
  }
}
