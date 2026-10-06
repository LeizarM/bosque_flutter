import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/formato_incapacidad.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/interruptor_revision.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';

/// Una columna por dato del SP, sin scroll horizontal: la columna Revisión,
/// la única que se toca, tiene que verse siempre. Por eso la tabla aparece
/// recién desde `anchoTablaIncapacidad` (1060 px, una laptop de 1366 con
/// sidebar); debajo van tarjetas.
const List<AnchoCol> _anchos = [
  AnchoCol.flexible(3), // empleado
  AnchoCol.flexible(2), // motivo
  AnchoCol.fijo(118), // periodo: desde / hasta, con hora
  AnchoCol.fijo(40), // días
  AnchoCol.fijo(58), // días seguro
  AnchoCol.fijo(96), // salario mensual
  AnchoCol.fijo(76), // diario
  AnchoCol.fijo(80), // 75 %
  AnchoCol.fijo(96), // descuento
  AnchoCol.fijo(152), // revisión
];

/// Las pendientes llevan franja ámbar a la izquierda: es lo que queda por
/// hacer. Todas las filas reservan el ancho para no desalinear columnas.
const double _franja = 4;

class TablaIncapacidad extends StatelessWidget {
  final List<PlanillaIncapacidadEntity> filas;
  final Set<int> guardando;
  final void Function(PlanillaIncapacidadEntity fila, bool revisado) onMarcar;

  const TablaIncapacidad({
    super.key,
    required this.filas,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    return MarcoTabla(
      child: Column(
        children: [
          const _Encabezado(),
          Expanded(
            child: ListView.builder(
              itemCount: filas.length,
              itemBuilder:
                  (context, i) => _Fila(
                    fila: filas[i],
                    guardando: guardando.contains(filas[i].idPIT),
                    onMarcar: onMarcar,
                  ),
            ),
          ),
          _Totales(filas: filas),
        ],
      ),
    );
  }
}

Border _borde(ColorScheme cs, Color franja) => Border(
  left: BorderSide(color: franja, width: _franja),
  bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
);

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
    );
    Widget t(String texto, {bool derecha = false, String? ayuda}) {
      final w = Text(
        texto,
        style: estilo,
        textAlign: derecha ? TextAlign.right : TextAlign.left,
      );
      return ayuda == null ? w : Tooltip(message: ayuda, child: w);
    }

    return FilaTabla(
      anchos: _anchos,
      fondo: cs.surfaceContainerHighest,
      borde: Border(
        left: const BorderSide(color: Colors.transparent, width: _franja),
        bottom: BorderSide(color: cs.outlineVariant),
      ),
      celdas: [
        t('Empleado'),
        t('Motivo'),
        t('Periodo'),
        t('Días', derecha: true, ayuda: 'Días de baja, del primero al último'),
        t('Días seguro', derecha: true, ayuda: 'Días a cargo del seguro: desde el 4.º día de baja'),
        t('Salario mensual', derecha: true),
        t('Diario', derecha: true, ayuda: 'Salario mensual / 30'),
        t('75 % diario', derecha: true, ayuda: 'Salario diario × 0.75'),
        t('Descuento', derecha: true, ayuda: 'Días seguro × 75 % diario'),
        t('Revisión'),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final PlanillaIncapacidadEntity fila;
  final bool guardando;
  final void Function(PlanillaIncapacidadEntity fila, bool revisado) onMarcar;

  const _Fila({
    required this.fila,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    Widget n(String texto, {bool fuerte = false}) => Text(
      texto,
      textAlign: TextAlign.right,
      maxLines: 1,
      style: context.numero(fuerte: fuerte),
    );

    return FilaTabla(
      anchos: _anchos,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borde: _borde(
        cs,
        fila.fueRevisado ? Colors.transparent : TareasColors.pendienteTexto(context),
      ),
      celdas: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fila.datoEmpleado,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
            ),
            Tooltip(
              message: seguroBaja(fila.seguro, fila.numSeguro),
              child: Text(
                seguroBaja(fila.seguro, fila.numSeguro),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.apagado(),
              ),
            ),
          ],
        ),
        Tooltip(
          message: fila.motivo,
          child: Text(
            fila.motivo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(momentoBaja(fila.desde), maxLines: 1, style: context.numero()),
            Text(
              momentoBaja(fila.hasta),
              maxLines: 1,
              style: context.numero(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        n(enteroIncapacidad(fila.diasBaja)),
        n(enteroIncapacidad(fila.diasAsumidosCordes)),
        n(montoIncapacidad(fila.salarioMensual)),
        n(montoIncapacidad(fila.salarioDiario)),
        n(montoIncapacidad(fila.porcentajeAl75)),
        n(montoIncapacidad(fila.totalDescuento), fuerte: true),
        Align(
          alignment: Alignment.centerLeft,
          child: InterruptorRevision(
            revisado: fila.fueRevisado,
            fecha: fila.fechaRevisado,
            guardando: guardando,
            onCambiar: (v) => onMarcar(fila, v),
          ),
        ),
      ],
    );
  }
}

/// Suma de lo que se ve (con filtro y búsqueda aplicados).
class _Totales extends StatelessWidget {
  final List<PlanillaIncapacidadEntity> filas;

  const _Totales({required this.filas});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dias = filas.fold(0, (s, f) => s + f.diasBaja);
    final diasSeguro = filas.fold(0, (s, f) => s + f.diasAsumidosCordes);
    final descuento = filas.fold(0.0, (s, f) => s + f.totalDescuento);
    Widget n(String texto) => Text(
      texto,
      textAlign: TextAlign.right,
      maxLines: 1,
      style: context.numero(fuerte: true),
    );

    return FilaTabla(
      anchos: _anchos,
      fondo: cs.surfaceContainerHigh,
      borde: Border(
        left: const BorderSide(color: Colors.transparent, width: _franja),
        top: BorderSide(color: cs.outlineVariant),
      ),
      celdas: [
        Text(
          filas.length == 1 ? 'Total · 1 baja' : 'Total · ${filas.length} bajas',
          style: context.tituloSeccion(),
        ),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        n(enteroIncapacidad(dias)),
        n(enteroIncapacidad(diasSeguro)),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        n(montoIncapacidad(descuento)),
        const SizedBox.shrink(),
      ],
    );
  }
}
