import 'package:bosque_flutter/core/state/cartas_cite_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/identidad_cite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diálogos del módulo Cartas CITE.

// ═══════════════════════════════════════════════════════════════════════════
// NUEVO DOCUMENTO
// ═══════════════════════════════════════════════════════════════════════════

class EleccionNuevoCite {
  final int idTipoDoc;
  final int codEmpresa;
  const EleccionNuevoCite({required this.idTipoDoc, required this.codEmpresa});
}

/// Pregunta tipo y empresa antes de abrir el formulario.
///
/// Son las dos cosas que **no se pueden cambiar después**: de ellas depende el
/// correlativo, y una vez emitido el número no se mueve de tipo ni de empresa.
/// Por eso se preguntan acá y no adentro del formulario, donde parecerían dos
/// campos más entre veinte.
///
/// ## Por qué dejó de ser un combo
///
/// El tipo decide qué campos va a tener el formulario: si lleva ciudad, si el
/// destinatario se escribe o se elige de la planilla, si lleva «Vía:». Elegirlo
/// de una lista desplegable obligaba a saberse esas reglas de memoria —o a
/// entrar, mirar y volver—. Acá cada tipo es una tarjeta que dice para qué
/// sirve, con el mismo ícono y el mismo color que va a tener después en la
/// grilla.
Future<EleccionNuevoCite?> mostrarDialogoNuevoCite(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<EleccionNuevoCite>(
    context: context,
    builder: (ctx) => _DialogoNuevoCite(ref: ref),
  );
}

class _DialogoNuevoCite extends StatefulWidget {
  final WidgetRef ref;
  const _DialogoNuevoCite({required this.ref});

  @override
  State<_DialogoNuevoCite> createState() => _DialogoNuevoCiteState();
}

class _DialogoNuevoCiteState extends State<_DialogoNuevoCite> {
  int? _tipo;
  int? _empresa;

  @override
  void initState() {
    super.initState();
    // La empresa del usuario como valor de arranque: es la que va a elegir
    // casi siempre.
    final propia = widget.ref.read(userProvider)?.codEmpresa ?? 0;
    if (propia > 0) _empresa = propia;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipos = widget.ref.watch(tiposDocumentoCiteProvider);
    final empresas = widget.ref.watch(empresasProvider);
    final tam = MediaQuery.of(context).size;
    final angosto = tam.width < 620;

    return Dialog(
      insetPadding: EdgeInsets.all(angosto ? Esp.m : Esp.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: tam.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Esp.l, Esp.l, Esp.l, Esp.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo documento',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: Peso.titulo),
                  ),
                  SizedBox(height: Esp.xs),
                  Text('¿Qué vas a redactar?', style: context.apagado()),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Esp.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tipos.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: Esp.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _AvisoError(
                        mensaje: 'No se pudieron cargar los tipos de documento.',
                        detalle: '$e',
                      ),
                      data: (lista) => _GrillaTipos(
                        tipos: lista,
                        seleccionado: _tipo,
                        angosto: angosto,
                        onElegir: (v) => setState(() => _tipo = v),
                      ),
                    ),
                    SizedBox(height: Esp.l),
                    Text('¿De qué empresa sale?', style: context.tituloSeccion()),
                    SizedBox(height: Esp.s),
                    empresas.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => _AvisoError(
                        mensaje: 'No se pudieron cargar las empresas.',
                        detalle: '$e',
                      ),
                      data: (lista) => Wrap(
                        spacing: Esp.s,
                        runSpacing: Esp.s,
                        children: [
                          for (final e in lista)
                            ChoiceChip(
                              label: Text(e.nombre),
                              selected: _empresa == e.codEmpresa,
                              onSelected: (_) =>
                                  setState(() => _empresa = e.codEmpresa),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: Esp.l),
                    Container(
                      padding: EdgeInsets.all(Esp.m),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(Esquina.chica),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: cs.onSurfaceVariant),
                          SizedBox(width: Esp.s),
                          Expanded(
                            child: Text(
                              'El tipo y la empresa definen el correlativo, así que '
                              'no se pueden cambiar después de guardar.',
                              style: context.apagado(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(Esp.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  SizedBox(width: Esp.s),
                  FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Redactar'),
                    onPressed: (_tipo != null && (_empresa ?? 0) > 0)
                        ? () => Navigator.pop(
                              context,
                              EleccionNuevoCite(
                                idTipoDoc: _tipo!,
                                codEmpresa: _empresa!,
                              ),
                            )
                        : null,
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

/// Las tarjetas de tipo, en una o dos columnas.
///
/// Dos columnas cuando entran: seis tarjetas en una sola columna obligan a
/// scrollear para ver la última, y comparar dos tipos exige recordar el de
/// arriba.
class _GrillaTipos extends StatelessWidget {
  final List<TipoDocumentoCiteEntity> tipos;
  final int? seleccionado;
  final bool angosto;
  final void Function(int) onElegir;

  const _GrillaTipos({
    required this.tipos,
    required this.seleccionado,
    required this.angosto,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    if (angosto) {
      return Column(
        children: [
          for (final t in tipos) ...[
            _TarjetaTipo(
              idTipoDoc: t.idTipoDoc.toInt(),
              nombre: t.tipo,
              seleccionado: seleccionado == t.idTipoDoc.toInt(),
              onElegir: () => onElegir(t.idTipoDoc.toInt()),
            ),
            SizedBox(height: Esp.s),
          ],
        ],
      );
    }

    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (final t in tipos)
          SizedBox(
            width: 288,
            child: _TarjetaTipo(
              idTipoDoc: t.idTipoDoc.toInt(),
              nombre: t.tipo,
              seleccionado: seleccionado == t.idTipoDoc.toInt(),
              onElegir: () => onElegir(t.idTipoDoc.toInt()),
            ),
          ),
      ],
    );
  }
}

class _TarjetaTipo extends StatelessWidget {
  final int idTipoDoc;
  final String nombre;
  final bool seleccionado;
  final VoidCallback onElegir;

  const _TarjetaTipo({
    required this.idTipoDoc,
    required this.nombre,
    required this.seleccionado,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = identidadCite(idTipoDoc);

    return Material(
      color: seleccionado ? cs.primaryContainer : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: InkWell(
        onTap: onElegir,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Esquina.media),
            border: Border.all(
              // Dos píxeles de borde y no una sombra: la selección tiene que
              // leerse igual en claro y en oscuro, y una sombra se pierde
              // contra un fondo oscuro.
              color: seleccionado ? cs.primary : cs.outlineVariant,
              width: seleccionado ? 2 : 1,
            ),
          ),
          padding: EdgeInsets.all(Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelloTipoCite(idTipoDoc: idTipoDoc, tipo: nombre, lado: 40),
              SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: Peso.titulo,
                            color: seleccionado ? cs.onPrimaryContainer : null,
                          ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      id.paraQue,
                      style: context.apagado()?.copyWith(
                            color: seleccionado
                                ? cs.onPrimaryContainer.withValues(alpha: 0.85)
                                : null,
                          ),
                    ),
                  ],
                ),
              ),
              if (seleccionado)
                Icon(Icons.check_circle, size: 20, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;
  final String detalle;
  const _AvisoError({required this.mensaje, required this.detalle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
          SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mensaje, style: TextStyle(color: cs.onErrorContainer)),
                Text(
                  detalle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onErrorContainer.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MEMBRETE
// ═══════════════════════════════════════════════════════════════════════════

/// Sólo para cartas: pregunta si el PDF va con membrete.
///
/// Depende de si se va a imprimir en papel membretado o en hoja blanca, así
/// que no hay forma de decidirlo desde el sistema. El módulo viejo también lo
/// preguntaba, con un confirmDialog.
///
/// Las dos opciones son dos tarjetas y no dos botones seguidos: «Con membrete»
/// y «Sin membrete» se diferencian en una sílaba, y elegir mal significa
/// reimprimir.
Future<bool?> mostrarDialogoLogo(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;

      Widget opcion({
        required IconData icono,
        required String titulo,
        required String detalle,
        required bool valor,
      }) =>
          Material(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Esquina.media),
            child: InkWell(
              onTap: () => Navigator.pop(ctx, valor),
              borderRadius: BorderRadius.circular(Esquina.media),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(Esquina.media),
                ),
                padding: EdgeInsets.all(Esp.m),
                child: Row(
                  children: [
                    Icon(icono, size: 24, color: cs.primary),
                    SizedBox(width: Esp.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: Peso.titulo)),
                          Text(detalle, style: ctx.apagado()),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );

      return AlertDialog(
        title: const Text('¿Cómo se imprime?'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              opcion(
                icono: Icons.verified_outlined,
                titulo: 'Con membrete',
                detalle: 'El PDF trae el logo de la empresa. Hoja blanca.',
                valor: true,
              ),
              SizedBox(height: Esp.s),
              opcion(
                icono: Icons.insert_drive_file_outlined,
                titulo: 'Sin membrete',
                detalle: 'Para papel que ya lo trae impreso.',
                valor: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ANULACIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// Confirma la anulación y pide el motivo. Devuelve el motivo, o `null` si se
/// canceló.
///
/// **El motivo es obligatorio acá aunque la columna acepte NULL.** Anular
/// consume un número de CITE para siempre y el documento pudo haber salido en
/// papel; dentro de un año, "quién lo anuló y cuándo" sin el "por qué" no
/// alcanza para reconstruir qué pasó. Es una acción rara, así que el costo de
/// escribir una línea es bajo. Si molesta, se afloja sacando la condición del
/// `onPressed`.
Future<String?> mostrarDialogoAnular(
  BuildContext context, {
  required String descripcionDocumento,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _DialogoAnular(descripcion: descripcionDocumento),
  );
}

class _DialogoAnular extends StatefulWidget {
  final String descripcion;
  const _DialogoAnular({required this.descripcion});

  @override
  State<_DialogoAnular> createState() => _DialogoAnularState();
}

class _DialogoAnularState extends State<_DialogoAnular> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final escrito = _motivo.text.trim().length;
    final valido = escrito >= 5;

    return AlertDialog(
      icon: Icon(Icons.block_outlined, color: cs.error),
      title: const Text('Anular documento'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se va a anular ${widget.descripcion}.'),
            SizedBox(height: Esp.s),
            Container(
              padding: EdgeInsets.all(Esp.s),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(Esquina.chica),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: cs.onErrorContainer),
                  SizedBox(width: Esp.s),
                  Expanded(
                    child: Text(
                      'El número de CITE queda consumido y no se reutiliza. '
                      'Esta acción no se deshace desde la aplicación.',
                      style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              autofocus: true,
              maxLength: 300,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Motivo de la anulación *',
                hintText: 'Por ejemplo: se emitió por duplicado',
                border: const OutlineInputBorder(),
                isDense: true,
                counterText: '',
                // El botón deshabilitado sin explicación es la forma más común
                // de dejar a alguien golpeando una puerta cerrada.
                helperText: valido
                    ? 'Listo para anular.'
                    : 'Escribí al menos 5 caracteres.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          onPressed:
              valido ? () => Navigator.pop(context, _motivo.text.trim()) : null,
          child: const Text('Anular'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORTE MENSUAL
// ═══════════════════════════════════════════════════════════════════════════

class ParametrosReporteCite {
  final int mes;
  final int anio;
  final int idTipoDoc;
  final int codEmpresa;

  const ParametrosReporteCite({
    required this.mes,
    required this.anio,
    required this.idTipoDoc,
    required this.codEmpresa,
  });
}

Future<ParametrosReporteCite?> mostrarDialogoReporteMensual(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<ParametrosReporteCite>(
    context: context,
    builder: (ctx) => _DialogoReporteMensual(ref: ref),
  );
}

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class _DialogoReporteMensual extends StatefulWidget {
  final WidgetRef ref;
  const _DialogoReporteMensual({required this.ref});

  @override
  State<_DialogoReporteMensual> createState() => _DialogoReporteMensualState();
}

class _DialogoReporteMensualState extends State<_DialogoReporteMensual> {
  int _mes = DateTime.now().month;
  int? _anio;
  int? _tipo;
  int? _empresa;

  @override
  void initState() {
    super.initState();
    final propia = widget.ref.read(userProvider)?.codEmpresa ?? 0;
    if (propia > 0) _empresa = propia;
  }

  @override
  Widget build(BuildContext context) {
    final tipos = widget.ref.watch(tiposDocumentoCiteProvider).valueOrNull ?? [];
    final empresas = widget.ref.watch(empresasProvider).valueOrNull ?? [];
    final gestiones = widget.ref.watch(gestionesCiteProvider).valueOrNull ?? [];

    // La gestión activa por defecto; si el catálogo todavía no llegó, el año
    // en curso.
    _anio ??= gestiones.where((g) => g.esActiva).map((g) => g.gestion).firstOrNull ??
        DateTime.now().year;

    final completo = _anio != null && _tipo != null && (_empresa ?? 0) > 0;

    return AlertDialog(
      icon: const Icon(Icons.summarize_outlined),
      title: const Text('Reporte mensual'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lista los documentos emitidos en el período, para archivo.',
                style: context.apagado(),
              ),
              SizedBox(height: Esp.m),
              DropdownButtonFormField<int>(
                value: _empresa,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Empresa *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined, size: 18),
                ),
                items: empresas
                    .map((e) => DropdownMenuItem(
                          value: e.codEmpresa,
                          child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _empresa = v),
              ),
              SizedBox(height: Esp.m),
              DropdownButtonFormField<int>(
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined, size: 18),
                ),
                items: tipos
                    .map((t) => DropdownMenuItem(
                          value: t.idTipoDoc.toInt(),
                          child: Text(t.tipo),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v),
              ),
              SizedBox(height: Esp.m),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _anio,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Gestión *', border: OutlineInputBorder(),
                      ),
                      items: (gestiones.isEmpty
                              ? [DateTime.now().year]
                              : gestiones.map((g) => g.gestion).toList())
                          .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                          .toList(),
                      onChanged: (v) => setState(() => _anio = v),
                    ),
                  ),
                  SizedBox(width: Esp.m),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _mes,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Mes', border: OutlineInputBorder(),
                      ),
                      items: [
                        // 0 = toda la gestión: es lo que el SP entiende cuando
                        // el mes no viene.
                        const DropdownMenuItem(value: 0, child: Text('Todo el año')),
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(value: i, child: Text(_meses[i - 1])),
                      ],
                      onChanged: (v) => setState(() => _mes = v ?? 0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Generar'),
          onPressed: completo
              ? () => Navigator.pop(
                    context,
                    ParametrosReporteCite(
                      mes: _mes,
                      anio: _anio!,
                      idTipoDoc: _tipo!,
                      codEmpresa: _empresa!,
                    ),
                  )
              : null,
        ),
      ],
    );
  }
}
