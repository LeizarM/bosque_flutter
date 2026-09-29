// Destino final: lib/presentation/widgets/tareas-rutinarias/paneles_cierre.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/estado_verificacion_traspaso.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pildora_cumplimiento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';

/// Las secciones de la revisión de Cierre de Operaciones.
///
/// Una por cada cosa que se revisa del día: arqueos de caja, traspasos de Caja
/// AXA, caja fuerte, cheques y las tareas rutinarias de los demás. Es el
/// diálogo dlgRevArqueo del sistema anterior, sección por sección.
///
/// Cada una muestra su propia lectura: si SAP no contesta, la de cheques dice
/// que no se pudo leer y ofrece reintentar, y las otras cuatro siguen sirviendo.
///
/// Y cada una se da por revisada de una de dos maneras: marcando todas sus
/// filas (arqueos, traspasos, caja fuerte) o con el interruptor "Revisado", que
/// es lo único posible cuando no hay nada que marcar — los cheques, las tareas
/// de los demás, o una sección que ese día vino vacía.

/// A partir de este ancho una sección muestra tabla; abajo, tarjetas.
///
/// Es [TareasBreakpoints.splitMin] y no el umbral medio porque estas tablas
/// tienen entre 5 y 9 columnas: con menos ancho, la columna del nombre queda
/// cortando en la primera palabra.
const double _anchoDeTabla = TareasBreakpoints.splitMin;

/// El marco de una sección: encabezado, estado de la lectura y contenido.
class PanelCierreCard extends StatelessWidget {
  final String titulo;

  /// Una línea que explica de dónde sale lo que se ve.
  final String? detalle;

  final IconData icono;
  final Color color;
  final PanelDatos<Object?> datos;

  /// Qué decir cuando la lectura salió bien y no había nada.
  final String vacio;

  /// El título del error de lectura ("No se pudo leer los cheques").
  final String tituloError;

  final VoidCallback onReintentar;

  /// El avance de la sección, a la derecha del título.
  final Widget? contador;

  /// Si la sección ya cuenta como revisada.
  final bool revisada;

  /// Cuando no hay filas que marcar, el interruptor para darla por revisada.
  /// `null` = esta sección se revisa marcando sus filas.
  final ValueChanged<bool>? onRevisada;

  final List<Widget> acciones;
  final WidgetBuilder contenido;

  const PanelCierreCard({
    super.key,
    required this.titulo,
    this.detalle,
    required this.icono,
    required this.color,
    required this.datos,
    required this.vacio,
    required this.tituloError,
    required this.onReintentar,
    this.contador,
    this.revisada = false,
    this.onRevisada,
    this.acciones = const [],
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget cuerpo;
    if (datos.error != null) {
      cuerpo = _ErrorDePanel(
        titulo: tituloError,
        error: datos.error!,
        onReintentar: onReintentar,
      );
    } else if (!datos.cargado && datos.cargando) {
      cuerpo = const Padding(
        padding: EdgeInsets.symmetric(vertical: Esp.l),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (datos.filas.isEmpty) {
      cuerpo = Text(vacio, style: context.apagado());
    } else {
      cuerpo = contenido(context);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      // FranjaAcento y no IntrinsicHeight: el contenido trae LayoutBuilder y
      // consultar intrínsecos sobre uno deja la tarjeta sin pintar.
      child: FranjaAcento(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Encabezado(
                titulo: titulo,
                detalle: detalle,
                icono: icono,
                color: color,
                contador: contador,
                revisada: revisada,
                onRevisada: onRevisada,
                acciones: acciones,
              ),
              // Releyendo con algo ya en pantalla: una línea fina, sin tapar.
              if (datos.cargando && datos.cargado)
                const Padding(
                  padding: EdgeInsets.only(top: Esp.s),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              const SizedBox(height: Esp.m),
              cuerpo,
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String titulo;
  final String? detalle;
  final IconData icono;
  final Color color;
  final Widget? contador;
  final bool revisada;
  final ValueChanged<bool>? onRevisada;
  final List<Widget> acciones;

  const _Encabezado({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.color,
    required this.contador,
    required this.revisada,
    required this.onRevisada,
    required this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    final titulos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: context.tituloSeccion()),
        if (detalle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(detalle!, style: context.apagado()),
          ),
      ],
    );
    final onRevisada = this.onRevisada;
    final extras = <Widget>[
      if (contador != null) contador!,
      if (onRevisada != null)
        _InterruptorRevisado(revisada: revisada, onCambio: onRevisada),
      ...acciones,
    ];

    return LayoutBuilder(
      builder: (context, cajon) {
        // En un cajón angosto el contador y los botones no entran en la misma
        // línea que el título: van abajo, envueltos.
        if (Aire.de(cajon.maxWidth).esChico) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: color, size: 20),
                  const SizedBox(width: Esp.s),
                  Expanded(child: titulos),
                ],
              ),
              if (extras.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Esp.s),
                  child: Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: extras,
                  ),
                ),
            ],
          );
        }
        return Row(
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: Esp.s),
            Expanded(child: titulos),
            for (final e in extras)
              Padding(padding: const EdgeInsets.only(left: Esp.s), child: e),
          ],
        );
      },
    );
  }
}

/// "Revisado" para las secciones que no tienen filas que marcar.
///
/// Es un acto deliberado, no un adorno: la tarea no se completa hasta que las
/// cinco secciones estén revisadas, y esta es la única forma de dar por
/// revisadas las que solo se miran.
class _InterruptorRevisado extends StatelessWidget {
  final bool revisada;
  final ValueChanged<bool> onCambio;

  const _InterruptorRevisado({required this.revisada, required this.onCambio});

  @override
  Widget build(BuildContext context) => FilterChip(
    avatar: Icon(
      revisada ? Icons.check_circle : Icons.radio_button_unchecked,
      size: 18,
      color:
          revisada
              ? TareasColors.realizadoTexto(context)
              : TareasColors.pendienteTexto(context),
    ),
    label: const Text('Revisado'),
    selected: revisada,
    showCheckmark: false,
    onSelected: onCambio,
  );
}

/// Una lectura que falló, dentro de la sección: el resto de la revisión sigue.
class _ErrorDePanel extends StatelessWidget {
  final String titulo;
  final Object error;
  final VoidCallback onReintentar;

  const _ErrorDePanel({
    required this.titulo,
    required this.error,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final color = TareasColors.vencidoTexto(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TareasColors.vencido(context),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off_outlined, size: 18, color: color),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(fontWeight: Peso.titulo, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.xs),
            Text(textoParaUsuario(error), style: context.apagado()),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El avance de una sección: "3/5 revisados".
class ContadorPanel extends StatelessWidget {
  final String texto;
  final bool completo;

  const ContadorPanel({super.key, required this.texto, required this.completo});

  /// "hechos/total texto", con el tono de si ya está todo.
  factory ContadorPanel.avance(int hechos, int total, String texto) =>
      ContadorPanel(texto: '$hechos/$total $texto', completo: hechos >= total);

  @override
  Widget build(BuildContext context) => PildoraTareas(
    texto: texto,
    fondo:
        completo
            ? TareasColors.realizado(context)
            : TareasColors.pendiente(context),
    color:
        completo
            ? TareasColors.realizadoTexto(context)
            : TareasColors.pendienteTexto(context),
  );
}

/// Una tabla de sección: encabezado de columnas y filas separadas.
class TablaCierre extends StatelessWidget {
  final List<AnchoCol> anchos;
  final List<String> titulos;
  final Set<int> aLaDerecha;
  final List<Widget> filas;

  const TablaCierre({
    super.key,
    required this.anchos,
    required this.titulos,
    this.aLaDerecha = const {},
    required this.filas,
  });

  @override
  Widget build(BuildContext context) {
    final linea = context.cs.outlineVariant.withValues(alpha: 0.5);
    return MarcoTabla(
      child: Column(
        children: [
          EncabezadoTabla(
            anchos: anchos,
            titulos: titulos,
            aLaDerecha: aLaDerecha,
          ),
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) Divider(height: 1, color: linea),
            filas[i],
          ],
        ],
      ),
    );
  }
}

String _junto(List<String?> partes) =>
    partes.whereType<String>().where((p) => p.trim().isNotEmpty).join(' · ');

// ─────────────────────────────────────────────────────────────────────────────
// ARQUEOS DE CAJA
// ─────────────────────────────────────────────────────────────────────────────

const _anchosArqueos = <AnchoCol>[
  AnchoCol.flexible(3), // encargado
  AnchoCol.fijo(130), // sucursal
  AnchoCol.fijo(52), // hora
  AnchoCol.fijo(120), // saldo SAP
  AnchoCol.fijo(120), // total
  AnchoCol.fijo(120), // diferencia
  AnchoCol.flexible(2), // observación
  AnchoCol.fijo(40), // PDF
  AnchoCol.fijo(172), // revisado
];

class ContenidoArqueos extends StatelessWidget {
  final List<ArqueoDelCierre> filas;
  final bool Function(int idAC) guardando;
  final void Function(int idAC) onRevisar;
  final void Function(int idAC) onPdf;

  const ContenidoArqueos({
    super.key,
    required this.filas,
    required this.guardando,
    required this.onRevisar,
    required this.onPdf,
  });

  Widget _estado(BuildContext context, ArqueoDelCierre a) {
    if (guardando(a.idAC)) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (a.revisado) {
      return PildoraTareas(
        texto: 'Revisado',
        icono: Icons.check,
        fondo: TareasColors.realizado(context),
        color: TareasColors.realizadoTexto(context),
      );
    }
    return FilledButton.tonal(
      onPressed: () => onRevisar(a.idAC),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      child: const Text('Marcar revisado'),
    );
  }

  Widget _diferencia(BuildContext context, ArqueoDelCierre a) => Text(
    a.cuadra ? 'Cuadra' : FormatoMoneda.bs(a.diferencia),
    textAlign: TextAlign.right,
    style: context.numero(
      fuerte: true,
      color:
          a.cuadra
              ? TareasColors.cuadradoTexto(context)
              : TareasColors.descuadradoTexto(context),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, cajon) {
      if (cajon.maxWidth < _anchoDeTabla) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final a in filas) _tarjeta(context, a)],
        );
      }
      final numero = context.numero();
      return TablaCierre(
        anchos: _anchosArqueos,
        aLaDerecha: const {3, 4, 5},
        titulos: const [
          'Encargado',
          'Sucursal',
          'Hora',
          'Saldo SAP',
          'Total',
          'Diferencia',
          'Observación',
          '',
          '¿Revisado?',
        ],
        filas: [
          for (final a in filas)
            FilaTabla(
              anchos: _anchosArqueos,
              celdas: [
                Text(
                  a.encargado,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: Peso.titulo),
                ),
                Text(
                  a.sucursal ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
                Text(a.hora ?? '—', style: numero),
                Text(
                  FormatoMoneda.bs(a.saldoSap),
                  textAlign: TextAlign.right,
                  style: numero,
                ),
                Text(
                  FormatoMoneda.bs(a.total),
                  textAlign: TextAlign.right,
                  style: numero,
                ),
                _diferencia(context, a),
                Text(
                  a.obs ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  tooltip: 'Ver el PDF del arqueo',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onPdf(a.idAC),
                ),
                Align(alignment: Alignment.centerLeft, child: _estado(context, a)),
              ],
            ),
        ],
      );
    },
  );

  Widget _tarjeta(BuildContext context, ArqueoDelCierre a) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.encargado,
                    style: const TextStyle(fontWeight: Peso.titulo),
                  ),
                  Text(
                    _junto([a.sucursal, a.tarea, a.hora]),
                    style: context.apagado(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            _estado(context, a),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Wrap(
          spacing: Esp.m,
          runSpacing: 2,
          children: [
            Text(
              'Saldo SAP: ${FormatoMoneda.bs(a.saldoSap)}',
              style: context.numero(),
            ),
            Text('Total: ${FormatoMoneda.bs(a.total)}', style: context.numero()),
            Text(
              a.cuadra ? 'Cuadra' : 'Diferencia: ${FormatoMoneda.bs(a.diferencia)}',
              style: context.numero(
                fuerte: true,
                color:
                    a.cuadra
                        ? TareasColors.cuadradoTexto(context)
                        : TareasColors.descuadradoTexto(context),
              ),
            ),
          ],
        ),
        if (a.obs != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Obs.: ${a.obs}',
              style: context.apagado()?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => onPdf(a.idAC),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Ver PDF'),
          ),
        ),
        const Divider(height: Esp.m),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TRASPASOS DE CAJA AXA
// ─────────────────────────────────────────────────────────────────────────────

const _anchosTraspasos = <AnchoCol>[
  AnchoCol.fijo(96), // sistema
  AnchoCol.fijo(104), // cuenta
  AnchoCol.fijo(104), // contra cuenta
  AnchoCol.flexible(2), // nombre de la cuenta
  AnchoCol.fijo(120), // tipo
  AnchoCol.fijo(112), // dólares
  AnchoCol.fijo(120), // bolivianos
  AnchoCol.fijo(150), // ¿cuadra?
];

/// Los traspasos del día, de solo lectura.
///
/// Los marca el cajero en su propia tarea ("Verificar traspaso Caja AXA", la
/// 295). Quien revisa el cierre mira cómo quedaron —cuáles cuadran, cuál no y
/// cuál nadie miró— y da la sección por revisada.
class ContenidoTraspasos extends StatelessWidget {
  final List<TraspasoMovCajaEntity> filas;

  const ContenidoTraspasos({super.key, required this.filas});

  Widget _estado(BuildContext context, TraspasoMovCajaEntity t) =>
      EstadoVerificacionTraspaso(valor: t.fueVerificado);

  /// El nombre del sistema, con la marca de "SAP ya no lo devuelve".
  Widget _sistema(BuildContext context, TraspasoMovCajaEntity t) {
    if (!t.soloEnBosque) return Text(t.bd ?? '—', overflow: TextOverflow.ellipsis);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(t.bd ?? '—', overflow: TextOverflow.ellipsis)),
        const SizedBox(width: Esp.xs),
        Tooltip(
          message:
              'Está registrado en Bosque pero el sistema ya no lo devuelve. '
              'Revísalo: puede haberse anulado del otro lado.',
          child: Icon(
            Icons.report_problem_outlined,
            size: 16,
            color: TareasColors.pendienteTexto(context),
          ),
        ),
      ],
    );
  }

  String _importe(double? valor, String unidad) =>
      (valor ?? 0) == 0 ? '—' : '$unidad ${FormatoMoneda.monto.format(valor)}';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, cajon) {
      if (cajon.maxWidth < _anchoDeTabla) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final t in filas) _tarjeta(context, t)],
        );
      }
      final numero = context.numero();
      return TablaCierre(
        anchos: _anchosTraspasos,
        aLaDerecha: const {5, 6},
        titulos: const [
          'Sistema',
          'Cuenta',
          'Contra cuenta',
          'Nombre de la cuenta',
          'Tipo',
          'Dólares',
          'Bolivianos',
          '¿Cuadra?',
        ],
        filas: [
          for (final t in filas)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilaTabla(
                  anchos: _anchosTraspasos,
                  celdas: [
                    _sistema(context, t),
                    Text(t.account ?? '—', style: numero),
                    Text(t.contraAct ?? '—', style: numero),
                    Text(
                      t.acctName ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: Peso.titulo),
                    ),
                    Text(
                      t.tipoTransaccion ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: context.apagado(),
                    ),
                    Text(
                      _importe(t.dolares, r'$us'),
                      textAlign: TextAlign.right,
                      style: numero,
                    ),
                    Text(
                      _importe(t.bs, 'Bs'),
                      textAlign: TextAlign.right,
                      style: numero,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _estado(context, t),
                    ),
                  ],
                ),
                if ((t.obs ?? '').trim().isNotEmpty)
                  _Observacion(texto: t.obs!.trim()),
              ],
            ),
        ],
      );
    },
  );

  Widget _tarjeta(BuildContext context, TraspasoMovCajaEntity t) {
    final montos = [
      if ((t.bs ?? 0) != 0) _importe(t.bs, 'Bs'),
      if ((t.dolares ?? 0) != 0) _importe(t.dolares, r'$us'),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.acctName ?? t.account ?? 'Traspaso',
            style: const TextStyle(fontWeight: Peso.titulo),
          ),
          Text(
            '${t.bd ?? '—'} · ${t.tipoTransaccion ?? '—'} · '
            '${t.account ?? '—'} → ${t.contraAct ?? '—'}',
            style: context.apagado(),
          ),
          if (montos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Esp.xs),
              child: Text(montos, style: context.numero(fuerte: true)),
            ),
          if ((t.obs ?? '').trim().isNotEmpty)
            _Observacion(texto: t.obs!.trim()),
          const SizedBox(height: Esp.xs),
          Align(alignment: Alignment.centerLeft, child: _estado(context, t)),
          const Divider(height: Esp.m),
        ],
      ),
    );
  }
}

class _Observacion extends StatelessWidget {
  final String texto;

  const _Observacion({required this.texto});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: Esp.m, right: Esp.m, bottom: Esp.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.subdirectory_arrow_right,
          size: 16,
          color: context.cs.onSurfaceVariant,
        ),
        const SizedBox(width: Esp.xs),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TareasColors.descuadradoTexto(context),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CAJA FUERTE
// ─────────────────────────────────────────────────────────────────────────────

const _anchosCajaFuerte = <AnchoCol>[
  AnchoCol.flexible(3), // cliente
  AnchoCol.flexible(2), // persona
  AnchoCol.fijo(120), // sucursal
  AnchoCol.fijo(130), // importe
  AnchoCol.flexible(2), // destino
  AnchoCol.fijo(52), // hora
  AnchoCol.fijo(96), // tipo
  AnchoCol.fijo(184), // verificada
];

class ContenidoCajaFuerte extends StatelessWidget {
  final List<LlegadaDelCierre> filas;
  final bool Function(int idRp) guardando;
  final void Function(int idRp) onVerificar;

  const ContenidoCajaFuerte({
    super.key,
    required this.filas,
    required this.guardando,
    required this.onVerificar,
  });

  String _hora(DateTime? d) => d == null ? '—' : FormatearFecha.formatearHora(d);

  Widget _estado(BuildContext context, LlegadaDelCierre l) {
    if (guardando(l.idRp)) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (l.verificada) {
      return PildoraTareas(
        texto: 'Verificada',
        icono: Icons.check,
        fondo: TareasColors.realizado(context),
        color: TareasColors.realizadoTexto(context),
      );
    }
    return FilledButton.tonal(
      onPressed: () => onVerificar(l.idRp),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      child: const Text('Marcar verificada'),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, cajon) {
      if (cajon.maxWidth < _anchoDeTabla) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final l in filas) _tarjeta(context, l)],
        );
      }
      final numero = context.numero();
      return TablaCierre(
        anchos: _anchosCajaFuerte,
        aLaDerecha: const {3},
        titulos: const [
          'Cliente',
          'Persona',
          'Sucursal',
          'Importe',
          'Destino',
          'Hora',
          'Tipo',
          '¿Verificada?',
        ],
        filas: [
          for (final l in filas)
            FilaTabla(
              anchos: _anchosCajaFuerte,
              celdas: [
                Text(
                  l.cliente ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: Peso.titulo),
                ),
                Text(l.persona ?? '—', overflow: TextOverflow.ellipsis),
                Text(
                  l.sucursal ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
                Text(
                  FormatoMoneda.conUnidad(l.moneda, l.importe),
                  textAlign: TextAlign.right,
                  style: context.numero(fuerte: true),
                ),
                Text(
                  l.destino ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
                Text(_hora(l.hora), style: numero),
                Text(l.tipo ?? '—', overflow: TextOverflow.ellipsis),
                Align(alignment: Alignment.centerLeft, child: _estado(context, l)),
              ],
            ),
        ],
      );
    },
  );

  Widget _tarjeta(BuildContext context, LlegadaDelCierre l) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.cliente ?? l.persona ?? 'Llegada',
                    style: const TextStyle(fontWeight: Peso.titulo),
                  ),
                  Text(
                    _junto([l.sucursal, l.tipo, _hora(l.hora)]),
                    style: context.apagado(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            _estado(context, l),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Wrap(
          spacing: Esp.m,
          runSpacing: 2,
          children: [
            Text(
              FormatoMoneda.conUnidad(l.moneda, l.importe),
              style: context.numero(fuerte: true),
            ),
            if (l.persona != null)
              Text('Persona: ${l.persona}', style: context.apagado()),
            if (l.destino != null)
              Text('Destino: ${l.destino}', style: context.apagado()),
          ],
        ),
        const Divider(height: Esp.m),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CHEQUES
// ─────────────────────────────────────────────────────────────────────────────

const _anchosCheques = <AnchoCol>[
  AnchoCol.fijo(120), // nº de cheque
  AnchoCol.flexible(3), // cliente
  AnchoCol.fijo(140), // monto
  AnchoCol.fijo(120), // empresa
  AnchoCol.fijo(230), // resultado
];

class ContenidoCheques extends StatelessWidget {
  final List<ChequeDelCierre> filas;

  const ContenidoCheques({super.key, required this.filas});

  ({Color fondo, Color texto}) _tono(BuildContext context, ResultadoCheque r) =>
      switch (r) {
        ResultadoCheque.cobrado => (
          fondo: TareasColors.realizado(context),
          texto: TareasColors.realizadoTexto(context),
        ),
        // Está cobrado, pero no el día que se revisa: hay algo que mirar.
        ResultadoCheque.otraFecha ||
        ResultadoCheque.salidaAnterior ||
        ResultadoCheque.sinCobrar => (
          fondo: TareasColors.pendiente(context),
          texto: TareasColors.pendienteTexto(context),
        ),
        // SAP lo cobró y en Bosque no está: eso no se explica solo.
        ResultadoCheque.sinRegistro => (
          fondo: TareasColors.vencido(context),
          texto: TareasColors.vencidoTexto(context),
        ),
        ResultadoCheque.otro => (
          fondo: TareasColors.noAplica(context),
          texto: TareasColors.noAplicaTexto(context),
        ),
      };

  Widget _resultado(BuildContext context, ChequeDelCierre c) {
    final tono = _tono(context, c.resultado);
    return PildoraTareas(
      texto:
          c.resultado == ResultadoCheque.otro
              ? (c.textoResultado ?? '—')
              : c.resultado.etiqueta,
      fondo: tono.fondo,
      color: tono.texto,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, cajon) {
      if (cajon.maxWidth < TareasBreakpoints.mediumMax) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final c in filas) _tarjeta(context, c)],
        );
      }
      return TablaCierre(
        anchos: _anchosCheques,
        aLaDerecha: const {2},
        titulos: const [
          'Nº de cheque',
          'Cliente',
          'Monto',
          'Empresa',
          'Resultado',
        ],
        filas: [
          for (final c in filas)
            FilaTabla(
              anchos: _anchosCheques,
              celdas: [
                Text(c.nroCheque, style: context.numero()),
                Text(
                  _junto([c.cliente, c.codCliente]),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  FormatoMoneda.conUnidad(c.moneda, c.monto),
                  textAlign: TextAlign.right,
                  style: context.numero(fuerte: true),
                ),
                Text(
                  c.empresa ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _resultado(context, c),
                ),
              ],
            ),
        ],
      );
    },
  );

  Widget _tarjeta(BuildContext context, ChequeDelCierre c) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.cliente ?? 'Cheque ${c.nroCheque}',
                    style: const TextStyle(fontWeight: Peso.titulo),
                  ),
                  Text(
                    _junto(['Nº ${c.nroCheque}', c.empresa]),
                    style: context.apagado(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            _resultado(context, c),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text(
          FormatoMoneda.conUnidad(c.moneda, c.monto),
          style: context.numero(fuerte: true),
        ),
        const Divider(height: Esp.m),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAREAS RUTINARIAS DEL DÍA
// ─────────────────────────────────────────────────────────────────────────────

const _anchosTareas = <AnchoCol>[
  AnchoCol.flexible(3), // persona
  AnchoCol.flexible(2), // cargo
  AnchoCol.flexible(4), // tarea
  AnchoCol.fijo(130), // estado
  AnchoCol.flexible(2), // quién respondió
];

/// Las tareas que generó el Job ese día para los demás, con un filtro: lo
/// normal es querer ver lo que falta, no las 54 del día.
class ContenidoTareas extends StatefulWidget {
  final List<BitacoraCumplimientoEntity> filas;

  const ContenidoTareas({super.key, required this.filas});

  @override
  State<ContenidoTareas> createState() => _ContenidoTareasState();
}

class _ContenidoTareasState extends State<ContenidoTareas> {
  bool _soloSinHacer = true;

  static bool _sinHacer(BitacoraCumplimientoEntity t) =>
      t.cumplimiento == Cumplimiento.noRealizada ||
      t.cumplimiento == Cumplimiento.enPlazo;

  @override
  Widget build(BuildContext context) {
    final sinHacer = widget.filas.where(_sinHacer).toList();
    final visibles = _soloSinHacer ? sinHacer : widget.filas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          children: [
            ChoiceChip(
              label: Text('Sin hacer · ${sinHacer.length}'),
              selected: _soloSinHacer,
              onSelected: (_) => setState(() => _soloSinHacer = true),
            ),
            ChoiceChip(
              label: Text('Todas · ${widget.filas.length}'),
              selected: !_soloSinHacer,
              onSelected: (_) => setState(() => _soloSinHacer = false),
            ),
          ],
        ),
        const SizedBox(height: Esp.m),
        if (visibles.isEmpty)
          Text(
            'Todas las tareas del día están respondidas.',
            style: context.apagado(),
          )
        else
          LayoutBuilder(
            builder: (context, cajon) {
              if (cajon.maxWidth < TareasBreakpoints.wideMax) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final t in visibles) _tarjeta(context, t)],
                );
              }
              return TablaCierre(
                anchos: _anchosTareas,
                titulos: const [
                  'Persona',
                  'Cargo',
                  'Tarea',
                  'Estado',
                  'Respondió',
                ],
                filas: [
                  for (final t in visibles)
                    FilaTabla(
                      anchos: _anchosTareas,
                      celdas: [
                        Text(
                          t.nombreEmpleado,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: Peso.titulo),
                        ),
                        Text(
                          t.descripcionCargo ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: context.apagado(),
                        ),
                        Text(
                          t.nombreTareaRutinaria,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: PildoraCumplimiento(cumplimiento: t.cumplimiento),
                        ),
                        Text(
                          t.nombreRespondio ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: context.apagado(),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, BitacoraCumplimientoEntity t) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nombreTareaRutinaria,
                    style: const TextStyle(fontWeight: Peso.titulo),
                  ),
                  Text(
                    _junto([
                      t.nombreEmpleado,
                      t.descripcionCargo,
                      t.nombreSucursal,
                    ]),
                    style: context.apagado(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            PildoraCumplimiento(cumplimiento: t.cumplimiento),
          ],
        ),
        if ((t.obs ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Obs.: ${t.obs!.trim()}',
              style: context.apagado()?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        const Divider(height: Esp.m),
      ],
    ),
  );
}
