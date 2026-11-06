/// Listas de vigencias del cálculo: parámetros, tramos y comidas agrupados por
/// clave, cada grupo con su leyenda y cada vigencia con su estado (vigente,
/// programada, vencida, sin uso); tabla en el ancho y tarjetas en el angosto.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

// Cada `flex` es la mitad de los px que pide su columna (como la tabla de
// reportes); el ancho mínimo de cada tabla sale de su suma.
const int _flexValor = 60; // «01/11/2026» en cifras
const int _flexSignificado = 140; // el ejemplo del SP, en varias líneas
const int _flexHorario = 64; // «20:00 – 24:00» y el tipo de día
const int _flexFactor = 48; // ficha con ícono: «×1,25»
const int _flexLeyendaTramo = 120;
const int _flexComida = 110; // código y leyenda, simple y doble
const int _flexMontos = 56; // «Bs 1.234,50»
const int _flexVentana = 64;
const int _flexVigencia = 80; // «Desde 01/01/2026»
const int _flexEstado = 52; // «Vigente»
const int _flexEstadoComida = 60; // «Vigente» e «Inactiva»
const int _flexAcciones = 56; // «Nueva vigencia» y el menú, 48 px cada uno

/// Alto estimado de una fila de parámetros en la tabla: el ejemplo del SP
/// ocupa unas cuatro líneas.
const double altoFilaParametroHex = 96;

/// Anchos de lista desde los que cada pestaña va en tabla; por debajo,
/// tarjetas ([usaTablaHex]). Incluyen el relleno de la fila.
const double anchoTablaParametrosHex =
    2.0 *
        (_flexValor +
            _flexSignificado +
            _flexVigencia +
            _flexEstado +
            _flexAcciones) +
    2 * Esp.m;
const double anchoTablaTramosHex =
    2.0 *
        (_flexHorario +
            _flexFactor +
            _flexLeyendaTramo +
            _flexVigencia +
            _flexEstado +
            _flexAcciones) +
    2 * Esp.m;
const double anchoTablaComidasHex =
    2.0 *
        (_flexComida +
            _flexMontos +
            _flexVentana +
            _flexEstadoComida +
            _flexVigencia +
            _flexAcciones) +
    2 * Esp.m;

/// Qué es una vigencia, siempre a la vista (también en el teléfono): es la
/// idea que más confunde a quien configura el cálculo.
class NotaVigenciaHex extends StatelessWidget {
  const NotaVigenciaHex({super.key});

  @override
  Widget build(BuildContext context) => const AvisoHex(
    tono: TonoHex.primario,
    icono: Icons.event_repeat,
    titulo: '¿Qué es una vigencia?',
    texto:
        'Es el período en el que un valor se usa para calcular. Estos valores '
        'deciden cuánto se paga: cambiar uno crea una vigencia nueva desde el '
        'día que elijas y las anteriores se conservan.',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS COMUNES
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que dice la franja de un grupo: la leyenda que lee el usuario, algo
/// más sobre el grupo (opcional) y la clave técnica como ficha pequeña.
typedef FranjaVigenciasHex =
    ({
      String titulo,
      String? detalle,
      String codigo,
      FamiliaCodigoHex? familia,
    });

/// La leyenda del grupo: la de la vigencia que rige hoy o, si ninguna rige, la
/// de la primera. Si viene vacía, la [clave] técnica: la franja nunca queda
/// sin título.
String leyendaGrupoHex<T>(
  List<T> grupo, {
  required String Function(T) leyenda,
  required bool Function(T) vigente,
  required String clave,
}) {
  final fila = grupo.where(vigente).firstOrNull ?? grupo.first;
  final texto = oGuionHex(leyenda(fila));
  return texto == '—' ? clave : texto;
}

/// Las vigencias agrupadas por [clave], con una franja por grupo ([franja]).
/// Va dentro del desplazamiento de la pantalla: en el ancho, en una caja de
/// hasta [altoMaximo]; si no, tarjetas sin caja.
class ListaVigenciasHex<T> extends StatelessWidget {
  const ListaVigenciasHex({
    super.key,
    required this.filas,
    required this.clave,
    required this.franja,
    required this.tabla,
    required this.anchoMinimoTabla,
    required this.altoMaximo,
    required this.columnas,
    required this.tarjeta,
    required this.vacio,
    this.etiquetasFranja,
    this.pieFranja,
    this.altoFila,
  });

  /// Fichas y explicación de cada franja, si la pestaña las tiene.
  final List<Widget> Function(List<T> grupo)? etiquetasFranja;
  final Widget? Function(List<T> grupo)? pieFranja;

  /// Alto estimado de una fila en la tabla, si sus textos son largos.
  final double? altoFila;

  final List<T> filas;
  final String Function(T) clave;
  final FranjaVigenciasHex Function(List<T> grupo) franja;
  final bool tabla;
  final double anchoMinimoTabla;
  final double altoMaximo;
  final List<BosqueColumn<T>> columnas;
  final Widget Function(T) tarjeta;
  final Widget vacio;

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<T>>{};
    for (final f in filas) {
      grupos.putIfAbsent(clave(f), () => []).add(f);
    }
    final ordenadas = [for (final g in grupos.values) ...g];
    return cajaTablaHex(
      tabla: tabla,
      // Cada franja ocupa como una fila más; con explicación, como dos.
      filas: ordenadas.length + grupos.length * (pieFranja == null ? 1 : 2),
      maximo: altoMaximo,
      porFila: altoFila,
      lista: ListadoHex<T>(
        filas: ordenadas,
        columnas: columnas,
        tarjeta: tarjeta,
        vacio: vacio,
        anchoMinimoTabla: anchoMinimoTabla,
        desplazamientoExterno: !tabla,
        cabeceraAntesDe: cabeceraPorGrupoHex(ordenadas, clave, (f) {
          final grupo = grupos[clave(f)]!;
          final datos = franja(grupo);
          return FranjaGrupoHex(
            titulo: datos.titulo,
            detalle: datos.detalle,
            codigo: datos.codigo,
            familiaCodigo: datos.familia,
            etiquetas: etiquetasFranja?.call(grupo) ?? const [],
            pie: pieFranja?.call(grupo),
            enTabla: tabla,
          );
        }),
      ),
    );
  }
}

/// La vigencia de una fila: el [texto] que calcula el SP («Rige desde el
/// 01/01/2026») o, si no llegó, «Desde 01/01/2026» y, si ya cerró, «Hasta
/// 31/12/2026».
class VigenciaHex extends StatelessWidget {
  const VigenciaHex({
    super.key,
    required this.desde,
    required this.hasta,
    this.texto,
  });

  final DateTime? desde;
  final DateTime? hasta;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final delSp = textoVigenciaHex(texto);
    if (delSp != null) {
      return Text(delSp, style: Theme.of(context).textTheme.bodyMedium);
    }
    return _fechas(context);
  }

  Widget _fechas(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Desde ${fechaHex(desde)}',
        style: estiloCifrasHex(Theme.of(context).textTheme.bodyMedium),
      ),
      if (hasta != null)
        Text(
          'Hasta ${fechaHex(hasta)}',
          style: estiloCifrasHex(context.apagado()),
        ),
    ],
  );
}

/// La vigencia en una línea, para la tarjeta del teléfono.
String vigenciaTextoHex(DateTime? desde, DateTime? hasta) =>
    hasta == null
        ? 'Desde ${fechaHex(desde)}'
        : 'Desde ${fechaHex(desde)} · hasta ${fechaHex(hasta)}';

/// El texto de vigencia del SP («Rige desde el 01/01/2026»), o nulo si no
/// llegó: la pantalla cae entonces en las fechas de la fila.
String? textoVigenciaHex(String? texto) => textoUsableHex(texto);

/// La vigencia de una fila: el texto del SP o, sin él, «Desde … hasta …».
String vigenciaFilaTextoHex(String? texto, DateTime? desde, DateTime? hasta) =>
    textoVigenciaHex(texto) ?? vigenciaTextoHex(desde, hasta);

/// El estado de una vigencia según el SP: VIGENTE en verde, PROGRAMADA en
/// ámbar con un reloj de espera, VENCIDA neutro y SIN_USO con contorno. Sin
/// [estado], solo se marca «Vigente» si lo es hoy ([vigente]).
Widget? chipVigenciaHex({required bool vigente, String? estado}) =>
    switch (estado) {
      'VIGENTE' => const ChipHex(
        texto: 'Vigente',
        icono: Icons.check_circle_outline,
        tono: TonoHex.exito,
      ),
      'PROGRAMADA' => const ChipHex(
        texto: 'Programada',
        icono: Icons.update,
        tono: TonoHex.pendiente,
      ),
      'VENCIDA' => const ChipHex(
        texto: 'Vencida',
        icono: Icons.history,
        tono: TonoHex.neutro,
      ),
      'SIN_USO' => const ChipHex(
        texto: 'Sin uso',
        icono: Icons.block,
        contorno: true,
      ),
      _ =>
        vigente
            ? const ChipHex(
              texto: 'Vigente',
              icono: Icons.check_circle_outline,
              tono: TonoHex.exito,
            )
            : null,
    };

/// El estado de la vigencia ([chipVigenciaHex]) y, en una comida, «Inactiva».
List<Widget> etiquetasVigenciaHex({
  required bool vigente,
  String? estado,
  bool inactiva = false,
}) {
  final chip = chipVigenciaHex(vigente: vigente, estado: estado);
  return [
    if (chip != null) chip,
    if (inactiva)
      const ChipHex(
        texto: 'Inactiva',
        icono: Icons.visibility_off_outlined,
        tono: TonoHex.terciario,
      ),
  ];
}

/// En la tabla, la primera acción a la vista y el resto en el menú.
class AccionesVigenciaHex extends StatelessWidget {
  const AccionesVigenciaHex(this.acciones, {super.key});

  final List<AccionHex> acciones;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (acciones.isNotEmpty) AccionesHex(acciones: [acciones.first]),
      if (acciones.length > 1)
        AccionesHex(acciones: acciones.sublist(1), enMenu: true),
    ],
  );
}

Widget _estado(List<Widget> etiquetas) =>
    Wrap(spacing: Esp.xs, runSpacing: Esp.xs, children: etiquetas);

// ═══════════════════════════════════════════════════════════════════════════
// PARÁMETROS
// ═══════════════════════════════════════════════════════════════════════════

/// El valor de un parámetro: el texto del SP con su unidad («240 horas al
/// mes») o, si no llegó, su fecha o su número.
String valorParametroHex(HexParametroEntity p) =>
    textoUsableHex(p.valorTexto) ??
    (p.valorFecha != null ? fechaHex(p.valorFecha) : decimalHex(p.valorNumero));

/// Qué significa el valor de la fila: el ejemplo del SP o, sin él, la leyenda.
String significadoParametroHex(HexParametroEntity p) =>
    textoUsableHex(p.ejemplo) ?? oGuionHex(p.leyenda);

/// El nombre del grupo: el del catálogo o, sin él, la leyenda vigente.
String nombreGrupoParametroHex(List<HexParametroEntity> grupo) =>
    grupo.map((p) => textoUsableHex(p.nombre)).nonNulls.firstOrNull ??
    leyendaGrupoHex(
      grupo,
      leyenda: (p) => p.leyenda,
      vigente: (p) => p.estadoVigencia == 'VIGENTE' || p.esVigente,
      clave: grupo.first.clave,
    );

/// «Obligatorio» u «Opcional», como lo dice el catálogo; nada si no llegó.
List<Widget> etiquetasGrupoParametroHex(
  List<HexParametroEntity> grupo,
) => switch (grupo.map((p) => p.obligatorio).nonNulls.firstOrNull) {
  true => const [
    ChipHex(
      texto: 'Obligatorio',
      icono: Icons.lock_outline,
      tono: TonoHex.primario,
    ),
  ],
  false => const [ChipHex(texto: 'Opcional', icono: Icons.toggle_off_outlined)],
  null => const [],
};

/// La explicación del grupo: para qué sirve y qué pasa si falta.
Widget? explicacionGrupoParametroHex(List<HexParametroEntity> grupo) {
  String? primero(String? Function(HexParametroEntity) campo) =>
      grupo.map((p) => textoUsableHex(campo(p))).nonNulls.firstOrNull;
  final descripcion = primero((p) => p.descripcion);
  final siFalta = primero((p) => p.siFalta);
  if (descripcion == null && siFalta == null) return null;
  return ExplicacionParametroHex(descripcion: descripcion, siFalta: siFalta);
}

/// Texto chico con ícono de información: la descripción y «Si falta: …».
class ExplicacionParametroHex extends StatelessWidget {
  const ExplicacionParametroHex({super.key, this.descripcion, this.siFalta});

  final String? descripcion;
  final String? siFalta;

  @override
  Widget build(BuildContext context) {
    final estilo = context.apagado();
    final que = descripcion;
    final falta = siFalta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Esp.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (que != null) Text(que, style: estilo),
              if (falta != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Si falta: ',
                        style: estilo?.copyWith(fontWeight: Peso.titulo),
                      ),
                      TextSpan(text: falta),
                    ],
                  ),
                  style: estilo,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

List<BosqueColumn<HexParametroEntity>> columnasParametrosHex(
  BuildContext context, {
  required List<AccionHex> Function(HexParametroEntity) acciones,
}) => [
  BosqueColumn(
    label: 'Valor',
    flex: _flexValor,
    cellBuilder:
        (p) => Text(
          valorParametroHex(p),
          style: estiloCifrasHex(
            Theme.of(context).textTheme.bodyMedium,
            fuerte: true,
          ),
        ),
  ),
  BosqueColumn(
    label: 'Qué significa',
    flex: _flexSignificado,
    cellBuilder: (p) => Text(significadoParametroHex(p)),
  ),
  BosqueColumn(
    label: 'Vigencia',
    flex: _flexVigencia,
    cellBuilder:
        (p) => VigenciaHex(
          desde: p.vigenteDesde,
          hasta: p.vigenteHasta,
          texto: p.textoVigencia,
        ),
  ),
  BosqueColumn(
    label: 'Estado',
    flex: _flexEstado,
    cellBuilder:
        (p) => _estado(
          etiquetasVigenciaHex(vigente: p.esVigente, estado: p.estadoVigencia),
        ),
  ),
  BosqueColumn(
    label: '',
    flex: _flexAcciones,
    alignment: Alignment.centerRight,
    cellBuilder: (p) => AccionesVigenciaHex(acciones(p)),
  ),
];

class TarjetaParametroHex extends StatelessWidget {
  const TarjetaParametroHex(this.p, {super.key, required this.acciones});

  final HexParametroEntity p;
  final List<AccionHex> acciones;

  /// El valor con su unidad va de título: el nombre ya está en la franja.
  @override
  Widget build(BuildContext context) => TarjetaHex(
    titulo: valorParametroHex(p),
    subtitulo: vigenciaFilaTextoHex(
      p.textoVigencia,
      p.vigenteDesde,
      p.vigenteHasta,
    ),
    contenido: Text(significadoParametroHex(p)),
    etiquetas: etiquetasVigenciaHex(
      vigente: p.esVigente,
      estado: p.estadoVigencia,
    ),
    acciones: acciones,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TRAMOS
// ═══════════════════════════════════════════════════════════════════════════

/// «20:00 – 24:00»: el fin 00:00 de un tramo son las 24:00.
String horarioTramoHex(HexTramoEntity t) =>
    '${horaTramoHex(t.horaDesde)} – ${horaTramoHex(t.horaHasta, esFin: true)}';

/// «×1,5»: cuántas veces el costo hora paga una hora del tramo.
String factorHex(double v) => '×${decimalHex(v)}';

/// El grupo de un tramo es la clave del SP: código y tipo de día.
String claveTramoHex(HexTramoEntity t) =>
    '${t.codigo} · ${tipoDiaHex(t.tipoDia)}';

/// El factor de un tramo como ficha: más presencia cuanto mayor es.
Widget factorChipHex(double v) =>
    CodigoHex(factorHex(v), familia: FamiliaCodigoHex.tramo, multiplicador: v);

List<BosqueColumn<HexTramoEntity>> columnasTramosHex(
  BuildContext context, {
  required List<AccionHex> Function(HexTramoEntity) acciones,
}) {
  final cuerpo = Theme.of(context).textTheme.bodyMedium;
  return [
    BosqueColumn(
      label: 'Horario',
      flex: _flexHorario,
      cellBuilder:
          (t) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(horarioTramoHex(t), style: estiloCifrasHex(cuerpo)),
              Text(tipoDiaHex(t.tipoDia), style: context.apagado()),
            ],
          ),
    ),
    BosqueColumn(
      label: 'Factor',
      flex: _flexFactor,
      cellBuilder: (t) => factorChipHex(t.multiplicador),
    ),
    BosqueColumn(
      label: 'Leyenda',
      flex: _flexLeyendaTramo,
      cellBuilder: (t) => Text(oGuionHex(t.leyenda)),
    ),
    BosqueColumn(
      label: 'Vigencia',
      flex: _flexVigencia,
      cellBuilder:
          (t) => VigenciaHex(
            desde: t.vigenteDesde,
            hasta: t.vigenteHasta,
            texto: t.textoVigencia,
          ),
    ),
    BosqueColumn(
      label: 'Estado',
      flex: _flexEstado,
      cellBuilder:
          (t) => _estado(
            etiquetasVigenciaHex(
              vigente: t.esVigente,
              estado: t.estadoVigencia,
            ),
          ),
    ),
    BosqueColumn(
      label: '',
      flex: _flexAcciones,
      alignment: Alignment.centerRight,
      cellBuilder: (t) => AccionesVigenciaHex(acciones(t)),
    ),
  ];
}

class TarjetaTramoHex extends StatelessWidget {
  const TarjetaTramoHex(this.t, {super.key, required this.acciones});

  final HexTramoEntity t;
  final List<AccionHex> acciones;

  @override
  Widget build(BuildContext context) => TarjetaHex(
    titulo: oGuionHex(t.leyenda),
    subtitulo: vigenciaFilaTextoHex(
      t.textoVigencia,
      t.vigenteDesde,
      t.vigenteHasta,
    ),
    contenido: Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${tipoDiaHex(t.tipoDia)} ·'),
        Text(
          horarioTramoHex(t),
          style: estiloCifrasHex(Theme.of(context).textTheme.bodyMedium),
        ),
        factorChipHex(t.multiplicador),
      ],
    ),
    etiquetas: etiquetasVigenciaHex(
      vigente: t.esVigente,
      estado: t.estadoVigencia,
    ),
    acciones: acciones,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// COMIDAS
// ═══════════════════════════════════════════════════════════════════════════

/// «18:00 – 20:00» o «Sin horario»: sin horario la comida no se gana.
String ventanaComidaHex(HexComidaEntity c) =>
    c.horaDesde == null || c.horaHasta == null
        ? 'Sin horario'
        : '${horaTramoHex(c.horaDesde)} – '
            '${horaTramoHex(c.horaHasta, esFin: true)}';

/// Un código con su leyenda: «C Cena».
class _CodigoLeyendaHex extends StatelessWidget {
  const _CodigoLeyendaHex(this.codigo, this.leyenda, {this.apagado = false});

  final String codigo;
  final String leyenda;
  final bool apagado;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        CodigoHex(codigo, apagado: apagado, familia: FamiliaCodigoHex.comida),
        const SizedBox(width: Esp.s),
        Expanded(child: Text(oGuionHex(leyenda))),
      ],
    ),
  );
}

List<BosqueColumn<HexComidaEntity>> columnasComidasHex(
  BuildContext context, {
  required List<AccionHex> Function(HexComidaEntity) acciones,
}) {
  final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
  return [
    BosqueColumn(
      label: 'Comida',
      flex: _flexComida,
      cellBuilder:
          (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CodigoLeyendaHex(c.codigo, c.leyenda, apagado: !c.activo),
              _CodigoLeyendaHex(
                c.codigoDoble,
                c.leyendaDoble,
                apagado: !c.activo || !c.conDoble,
              ),
              // D40: si paga la doble y cuánto dura, en palabras del SP.
              if ((c.textoDuracion ?? '').trim().isNotEmpty)
                Text(c.textoDuracion!.trim(), style: context.apagado()),
            ],
          ),
    ),
    BosqueColumn(
      label: 'Horario',
      flex: _flexVentana,
      cellBuilder: (c) => Text(ventanaComidaHex(c), style: cifras),
    ),
    BosqueColumn(
      label: 'Montos',
      flex: _flexMontos,
      alignment: Alignment.centerRight,
      cellBuilder:
          (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(bsHex(c.monto), style: cifras),
              Text(bsHex(c.montoDoble), style: cifras),
            ],
          ),
    ),
    BosqueColumn(
      label: 'Estado',
      flex: _flexEstadoComida,
      cellBuilder:
          (c) => _estado(
            etiquetasVigenciaHex(
              vigente: c.esVigente,
              estado: c.estadoVigencia,
              inactiva: !c.activo,
            ),
          ),
    ),
    BosqueColumn(
      label: 'Vigencia',
      flex: _flexVigencia,
      cellBuilder:
          (c) => VigenciaHex(
            desde: c.vigenteDesde,
            hasta: c.vigenteHasta,
            texto: c.textoVigencia,
          ),
    ),
    BosqueColumn(
      label: '',
      flex: _flexAcciones,
      alignment: Alignment.centerRight,
      cellBuilder: (c) => AccionesVigenciaHex(acciones(c)),
    ),
  ];
}

class TarjetaComidaHex extends StatelessWidget {
  const TarjetaComidaHex(this.c, {super.key, required this.acciones});

  final HexComidaEntity c;
  final List<AccionHex> acciones;

  @override
  Widget build(BuildContext context) {
    final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
    Widget linea(String codigo, String leyenda, double? monto) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          CodigoHex(
            codigo,
            apagado: !c.activo,
            familia: FamiliaCodigoHex.comida,
          ),
          const SizedBox(width: Esp.s),
          Expanded(child: Text(oGuionHex(leyenda))),
          const SizedBox(width: Esp.s),
          Text(bsHex(monto), style: cifras),
        ],
      ),
    );
    return TarjetaHex(
      titulo: oGuionHex(c.leyenda),
      subtitulo: vigenciaFilaTextoHex(
        c.textoVigencia,
        c.vigenteDesde,
        c.vigenteHasta,
      ),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          linea(c.codigo, c.leyenda, c.monto),
          linea(c.codigoDoble, c.leyendaDoble, c.montoDoble),
          const SizedBox(height: Esp.xs),
          Text('Horario: ${ventanaComidaHex(c)}', style: context.apagado()),
          if ((c.textoDuracion ?? '').trim().isNotEmpty)
            Text(c.textoDuracion!.trim(), style: context.apagado()),
        ],
      ),
      etiquetas: etiquetasVigenciaHex(
        vigente: c.esVigente,
        estado: c.estadoVigencia,
        inactiva: !c.activo,
      ),
      acciones: acciones,
    );
  }
}
