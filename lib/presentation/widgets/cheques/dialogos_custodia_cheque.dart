/// Los tres dialogos de traspaso y custodia de la barra de Cheques: «Traspaso»,
/// «A Custodio» y «Dar Custodia» (administrador). Todos trabajan sobre la
/// sucursal elegida en la grilla, que llega ya resuelta.
///
/// Que se vea cada boton lo decide `PermisosCheque`; el servidor exige el boton y
/// el permiso de escribir en la sucursal, y su mensaje se muestra **tal cual**,
/// con todas sus lineas, junto al dialogo que lo provoco. Despues de una
/// escritura `OperacionesChequesNotifier` relee la grilla y las listas de apoyo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart'
    show GeneradorPdfCheque;

/// Cuantas opciones se pintan a la vez en la lista de «Dar Custodia»: la
/// sucursal tiene miles de cheques y pintarlos todos congelaria el celular.
const int maximoChequesVisibles = 40;

String _cheques(int n) => n == 1 ? '1 cheque' : '$n cheques';

/// El error de una escritura anterior no debe aparecer en un dialogo nuevo.
void _limpiarError(BuildContext context) =>
    ProviderScope.containerOf(
      context,
    ).read(operacionesChequesProvider.notifier).limpiarError();

/// «Sucursal LA PAZ»: el nombre si ya llego la lista de la empresa activa, el
/// codigo si no.
String _subtituloSucursal(WidgetRef ref, int codSucursal) {
  final lista = ref.watch(sucursalesChequeActivasProvider);
  final nombre =
      lista
          .where((s) => s.codSucursal == codSucursal)
          .map((s) => s.nombre)
          .firstOrNull;
  return 'Sucursal ${nombre ?? codSucursal}';
}

// ═══════════════════════════════════════════════════════════════════════════
// TRASPASO
// ═══════════════════════════════════════════════════════════════════════════

/// «Traspaso» (`btnTraspasoCH`): cuantos cheques de la sucursal esperan pasar a
/// cobranza y un boton para generarlo, apagado si no hay ninguno. Una vez hecho,
/// ofrece imprimir la nomina del traspaso en PDF.
///
/// [codEmpresa] es la empresa activa de la pantalla: solo la necesita la nomina.
/// Sin ella (todavia no resuelta) el traspaso se hace igual y la nomina no se
/// ofrece.
Future<void> abrirTraspasoCheques(
  BuildContext context, {
  required int codSucursal,
  int? codEmpresa,
}) {
  _limpiarError(context);
  return abrirPanelCheque<void>(
    context,
    anchoMaximo: 520,
    contenido:
        (_) => _DialogoTraspasoCheques(
          codSucursal: codSucursal,
          codEmpresa: codEmpresa,
        ),
  );
}

class _DialogoTraspasoCheques extends ConsumerStatefulWidget {
  const _DialogoTraspasoCheques({
    required this.codSucursal,
    required this.codEmpresa,
  });

  final int codSucursal;
  final int? codEmpresa;

  @override
  ConsumerState<_DialogoTraspasoCheques> createState() =>
      _DialogoTraspasoChequesState();
}

class _DialogoTraspasoChequesState
    extends ConsumerState<_DialogoTraspasoCheques>
    with GeneradorPdfCheque<_DialogoTraspasoCheques> {
  /// Cuantos se traspasaron en esta visita; null mientras no se genero.
  int? _traspasados;

  Future<void> _generar() async {
    final n = await ref
        .read(operacionesChequesProvider.notifier)
        .traspasar(widget.codSucursal);
    // El error, si lo hubo, queda en el estado y se dibuja en el dialogo.
    if (n == null || !mounted) return;
    setState(() => _traspasados = n);
  }

  /// La nomina del ULTIMO traspaso de la sucursal, que es el que se acaba de
  /// hacer.
  Future<void> _imprimirNomina(int codEmpresa) => generarPdf(
    generar:
        (repo) => repo.reporteTraspaso(
          codEmpresa: codEmpresa,
          codSucursal: widget.codSucursal,
        ),
    titulo: 'Nómina del traspaso de cheques',
    nombreArchivo: 'nomina-traspaso-cheques.pdf',
  );

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesChequesProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesChequesProvider.select((s) => s.error),
    );
    final pendientes = ref.watch(
      traspasosPendientesChequesProvider(widget.codSucursal),
    );
    final cs = Theme.of(context).colorScheme;
    final hecho = _traspasados;
    final n = pendientes.valueOrNull ?? 0;

    final Widget cuerpo;
    if (hecho != null) {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NotaDelDato(
            tono: hecho > 0 ? TonoNota.exito : TonoNota.info,
            texto:
                hecho > 0
                    ? 'Se traspasaron ${_cheques(hecho)}.'
                    : 'No había cheques pendientes: no se traspasó ninguno.',
          ),
          // Un fallo de la nomina no deshace el traspaso: se dice debajo, junto
          // al boton que lo provoco.
          if (errorDelPdf != null) ...[
            const SizedBox(height: Esp.s),
            ErrorServidorCheque(errorDelPdf!),
          ],
        ],
      );
    } else {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorServidor != null) ...[
            ErrorServidorCheque(errorServidor),
            const SizedBox(height: Esp.l),
          ],
          pendientes.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error:
                (e, _) => NotaDelDato(
                  tono: TonoNota.error,
                  texto:
                      'No se pudo consultar los traspasos pendientes: '
                      '${mensajeDeErrorCheque(e)}',
                  accion: TextButton(
                    onPressed:
                        () => ref.invalidate(
                          traspasosPendientesChequesProvider(
                            widget.codSucursal,
                          ),
                        ),
                    child: const Text('Reintentar'),
                  ),
                ),
            data:
                (cuantos) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cuantos',
                      key: const ValueKey('traspaso-pendientes'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                        color: cuantos > 0 ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      cuantos == 1
                          ? 'cheque espera el traspaso a cobranza'
                          : 'cheques esperan el traspaso a cobranza',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: Esp.m),
                    Text(
                      cuantos > 0
                          ? 'Registra la salida de caja de todos los cheques '
                              'de la sucursal que solo tienen la acción de '
                              'recepción.'
                          : 'No hay nada que traspasar por ahora.',
                      style: context.apagado(),
                    ),
                  ],
                ),
          ),
        ],
      );
    }

    final codEmpresa = widget.codEmpresa;

    return MarcoPanelCheque(
      titulo: 'Traspaso de cheques',
      subtitulo: _subtituloSucursal(ref, widget.codSucursal),
      onCerrar: (ocupado || generando) ? () {} : () => Navigator.of(context).pop(),
      cuerpo: cuerpo,
      acciones:
          hecho != null
              ? [
                // Solo despues de traspasar y solo si hubo algo que nominar.
                if (hecho > 0 && codEmpresa != null)
                  FilledButton.tonalIcon(
                    onPressed:
                        generando ? null : () => _imprimirNomina(codEmpresa),
                    icon:
                        generando
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(
                      generando ? 'Generando…' : 'Imprimir nómina (PDF)',
                    ),
                  ),
                FilledButton(
                  onPressed: generando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Listo'),
                ),
              ]
              : [
                TextButton(
                  onPressed: ocupado ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                BotonGuardarCheque(
                  etiqueta: 'Generar',
                  etiquetaOcupado: 'Generando…',
                  icono: Icons.move_to_inbox_outlined,
                  ocupado: ocupado,
                  // El legacy lo apaga con cero pendientes.
                  onPressed: n > 0 ? _generar : null,
                ),
              ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// A CUSTODIO
// ═══════════════════════════════════════════════════════════════════════════

/// «A Custodio» (`btnCustodiaCH`): se elige el responsable y se marcan los
/// cheques de hoy que se le entregan. Es todo o nada: si el servidor rechaza uno
/// no queda ninguno entregado.
Future<bool?> abrirCustodiaCheques(
  BuildContext context, {
  required int codSucursal,
}) {
  _limpiarError(context);
  return abrirPanelCheque<bool>(
    context,
    anchoMaximo: 640,
    contenido: (_) => _DialogoCustodiaCheques(codSucursal: codSucursal),
  );
}

class _DialogoCustodiaCheques extends ConsumerStatefulWidget {
  const _DialogoCustodiaCheques({required this.codSucursal});

  final int codSucursal;

  @override
  ConsumerState<_DialogoCustodiaCheques> createState() =>
      _DialogoCustodiaChequesState();
}

class _DialogoCustodiaChequesState
    extends ConsumerState<_DialogoCustodiaCheques> {
  int? _codEmpleado;
  final Set<BigInt> _marcados = {};

  Future<void> _guardar(int codEmpleado, List<BigInt> codCheques) async {
    final n = await ref
        .read(operacionesChequesProvider.notifier)
        .entregarEnCustodia(
          CustodiaChequeRequestEntity(
            codSucursal: widget.codSucursal,
            codEmpleado: codEmpleado,
            codCheques: codCheques,
          ),
        );
    // El error, si lo hubo, queda en el estado y se dibuja en el dialogo; los
    // cheques siguen marcados.
    if (n == null || !mounted) return;
    avisar(
      context,
      n == 1
          ? 'Se entregó 1 cheque en custodia.'
          : 'Se entregaron $n cheques en custodia.',
    );
    Navigator.of(context).pop(true);
  }

  void _alternar(BigInt id, bool marcado) =>
      setState(() => marcado ? _marcados.add(id) : _marcados.remove(id));

  void _alternarTodos(List<ChequeFilaEntity> lista, bool marcarTodos) =>
      setState(() {
        _marcados.clear();
        if (marcarTodos) _marcados.addAll(lista.map((c) => c.codCheque));
      });

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesChequesProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesChequesProvider.select((s) => s.error),
    );
    final asyncResponsables = ref.watch(
      personalCustodiaProvider(widget.codSucursal),
    );
    final asyncCheques = ref.watch(
      chequesParaCustodiaProvider(widget.codSucursal),
    );
    final responsables =
        asyncResponsables.valueOrNull ?? const <PersonalChequeEntity>[];
    final cheques = asyncCheques.valueOrNull ?? const <ChequeFilaEntity>[];

    // Solo cuenta lo que sigue en la lista: tras una recarga puede haber
    // cheques que ya no estan.
    final responsable =
        responsables.any((p) => p.codEmpleado == _codEmpleado)
            ? _codEmpleado
            : null;
    final seleccion = [
      for (final c in cheques)
        if (_marcados.contains(c.codCheque)) c.codCheque,
    ];
    final todos = cheques.isNotEmpty && seleccion.length == cheques.length;
    final puedeGuardar =
        !ocupado && responsable != null && seleccion.isNotEmpty;

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        Text(
          'Elige quién se lleva los cheques y marca los que le entregas. Cada '
          'uno queda con la acción «A cobranza».',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.l),
        DropdownButtonFormField<int>(
          key: ValueKey('responsable-$responsable-${responsables.length}'),
          value: responsable,
          isExpanded: true,
          items: [
            for (final p in responsables)
              DropdownMenuItem(
                value: p.codEmpleado,
                child: Text(p.nombreCompleto, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged:
              ocupado || responsables.isEmpty
                  ? null
                  : (v) => setState(() => _codEmpleado = v),
          decoration: const InputDecoration(
            labelText: 'Responsable',
            helperText: 'Jefe de cobranzas o cobrador de la sucursal.',
            helperMaxLines: 2,
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        if (asyncResponsables.hasError && !asyncResponsables.isLoading)
          NotaDelDato(
            tono: TonoNota.error,
            texto:
                'No se pudo cargar los responsables: '
                '${mensajeDeErrorCheque(asyncResponsables.error!)}',
            accion: TextButton(
              onPressed:
                  () => ref.invalidate(
                    personalCustodiaProvider(widget.codSucursal),
                  ),
              child: const Text('Reintentar'),
            ),
          )
        else if (asyncResponsables.hasValue && responsables.isEmpty)
          const NotaDelDato(
            tono: TonoNota.aviso,
            texto:
                'No hay responsables de custodia activos en esta sucursal: '
                'no se puede entregar ningún cheque.',
          ),
        const SizedBox(height: Esp.l),
        Text('Cheques de hoy', style: context.tituloSeccion()),
        const SizedBox(height: Esp.s),
        if (asyncCheques.hasError && !asyncCheques.isLoading)
          NotaDelDato(
            tono: TonoNota.error,
            texto:
                'No se pudo cargar los cheques: '
                '${mensajeDeErrorCheque(asyncCheques.error!)}',
            accion: TextButton(
              onPressed:
                  () => ref.invalidate(
                    chequesParaCustodiaProvider(widget.codSucursal),
                  ),
              child: const Text('Reintentar'),
            ),
          )
        else if (!asyncCheques.hasValue)
          const LinearProgressIndicator(minHeight: 2)
        else if (cheques.isEmpty)
          const NotaDelDato(
            tono: TonoNota.info,
            texto: 'No hay cheques de hoy listos para entregar en custodia.',
          )
        else ...[
          _BarraDeMarcado(
            todos: todos,
            ninguno: seleccion.isEmpty,
            marcados: seleccion.length,
            total: cheques.length,
            habilitado: !ocupado,
            onTodos: () => _alternarTodos(cheques, !todos),
          ),
          const SizedBox(height: Esp.xs),
          _ListaAcotada(
            key: const ValueKey('lista-custodia'),
            itemCount: cheques.length,
            itemBuilder: (context, i) {
              final c = cheques[i];
              return CheckboxListTile(
                key: ValueKey('custodia-${c.codCheque}'),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _marcados.contains(c.codCheque),
                onChanged:
                    ocupado ? null : (v) => _alternar(c.codCheque, v ?? false),
                title: Text(
                  'Cheque ${c.cheque.nrocheque} · ${textoODash(c.datoCliente)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${textoODash(c.nombreBanco)} · ${textoMontoCheque(c)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ],
      ],
    );

    return MarcoPanelCheque(
      titulo: 'A Custodio',
      subtitulo: _subtituloSucursal(ref, widget.codSucursal),
      onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
      cuerpo: cuerpo,
      acciones: [
        TextButton(
          onPressed: ocupado ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonGuardarCheque(
          etiqueta: 'Guardar',
          icono: Icons.how_to_reg_outlined,
          ocupado: ocupado,
          onPressed:
              puedeGuardar ? () => _guardar(responsable, seleccion) : null,
        ),
      ],
    );
  }
}

/// «Marcar todos» y el contador. En anchos chicos o con texto grande el contador
/// baja a la linea de abajo en vez de desbordar.
class _BarraDeMarcado extends StatelessWidget {
  const _BarraDeMarcado({
    required this.todos,
    required this.ninguno,
    required this.marcados,
    required this.total,
    required this.habilitado,
    required this.onTodos,
  });

  final bool todos;
  final bool ninguno;
  final int marcados;
  final int total;
  final bool habilitado;
  final VoidCallback onTodos;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Esp.l,
      children: [
        InkWell(
          key: const ValueKey('marcar-todos'),
          borderRadius: BorderRadius.circular(Esquina.chica),
          onTap: habilitado ? onTodos : null,
          child: Padding(
            padding: const EdgeInsets.only(right: Esp.m),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  // Parcial cuando hay algunos marcados.
                  tristate: true,
                  value: todos ? true : (ninguno ? false : null),
                  onChanged: habilitado ? (_) => onTodos() : null,
                ),
                const Text('Marcar todos'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          child: Text(
            '$marcados de $total marcados',
            key: const ValueKey('contador-marcados'),
            style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
          ),
        ),
      ],
    );
  }
}

/// Una lista con su propio scroll y alto acotado dentro del cuerpo del panel,
/// que ya se desplaza: el panel no puede pedirle «toda la altura».
class _ListaAcotada extends StatelessWidget {
  const _ListaAcotada({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final alto = (MediaQuery.sizeOf(context).height * 0.35).clamp(180.0, 360.0);
    return Container(
      constraints: BoxConstraints(maxHeight: alto),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder:
            (_, __) => Divider(height: 1, color: cs.outlineVariant),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DAR CUSTODIA (ADMINISTRADOR)
// ═══════════════════════════════════════════════════════════════════════════

/// «Dar Custodia» (`btnCustodia2CH`, administrador): copia una entrega a cobranza
/// ya hecha (misma fecha, responsable y observacion) a otro cheque de la
/// sucursal. Dos pasos: la entrega de un dia y despues el cheque.
Future<bool?> abrirDarCustodiaCheques(
  BuildContext context, {
  required int codSucursal,
}) {
  _limpiarError(context);
  return abrirPanelCheque<bool>(
    context,
    anchoMaximo: 640,
    contenido: (_) => _DialogoDarCustodia(codSucursal: codSucursal),
  );
}

class _DialogoDarCustodia extends ConsumerStatefulWidget {
  const _DialogoDarCustodia({required this.codSucursal});

  final int codSucursal;

  @override
  ConsumerState<_DialogoDarCustodia> createState() =>
      _DialogoDarCustodiaState();
}

class _DialogoDarCustodiaState extends ConsumerState<_DialogoDarCustodia> {
  late final DateTime _hoy = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();

  int _paso = 1;
  late DateTime _fecha = _hoy;
  EntregaChequeEntity? _entrega;
  ChequeResumenEntity? _cheque;

  ConsultaEntregasCheque get _consulta => (
    codSucursal: widget.codSucursal,
    fecha: _fecha,
  );

  void _volverAlPaso1() {
    ref.read(operacionesChequesProvider.notifier).limpiarError();
    setState(() => _paso = 1);
  }

  Future<void> _asignar() async {
    final entrega = _entrega;
    final cheque = _cheque;
    if (entrega == null || cheque == null) return;
    final id = await ref
        .read(operacionesChequesProvider.notifier)
        .darCustodia(
          DarCustodiaRequestEntity(
            codSucursal: widget.codSucursal,
            codAccionOrigen: entrega.codAccion,
            codCheque: cheque.codCheque,
          ),
        );
    if (id == null || !mounted) return;
    avisar(context, 'Se asignó la custodia al cheque.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesChequesProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesChequesProvider.select((s) => s.error),
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        if (_paso == 1) _paso1(context) else _paso2(context),
      ],
    );

    return MarcoPanelCheque(
      titulo: 'Dar Custodia',
      subtitulo:
          '${_subtituloSucursal(ref, widget.codSucursal)} · Paso $_paso de 2',
      onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
      cuerpo: cuerpo,
      acciones:
          _paso == 1
              ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed:
                      _entrega == null ? null : () => setState(() => _paso = 2),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Siguiente'),
                ),
              ]
              : [
                TextButton(
                  onPressed: ocupado ? null : _volverAlPaso1,
                  child: const Text('Atrás'),
                ),
                BotonGuardarCheque(
                  etiqueta: 'Asignar',
                  etiquetaOcupado: 'Asignando…',
                  icono: Icons.assignment_ind_outlined,
                  ocupado: ocupado,
                  onPressed:
                      (_entrega != null && _cheque != null) ? _asignar : null,
                ),
              ],
    );
  }

  // ── Paso 1: la entrega ───────────────────────────────────────────────────

  Widget _paso1(BuildContext context) {
    final entregas = ref.watch(entregasDelDiaChequeProvider(_consulta));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Copia a otro cheque una entrega a cobranza ya registrada, con la '
          'misma fecha, responsable y observación. Primero elige el día y la '
          'entrega.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.l),
        CampoFechaCheque(
          etiqueta: 'Fecha de la entrega',
          valor: _fecha,
          ultima: _hoy,
          onCambio: (f) {
            if (f == null) return;
            // Otro dia, otras entregas: la elegida ya no vale.
            setState(() {
              _fecha = DateTime(f.year, f.month, f.day);
              _entrega = null;
            });
          },
        ),
        const SizedBox(height: Esp.l),
        entregas.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error:
              (e, _) => NotaDelDato(
                tono: TonoNota.error,
                texto:
                    'No se pudo cargar las entregas: ${mensajeDeErrorCheque(e)}',
                accion: TextButton(
                  onPressed:
                      () => ref.invalidate(
                        entregasDelDiaChequeProvider(_consulta),
                      ),
                  child: const Text('Reintentar'),
                ),
              ),
          data: (lista) {
            if (lista.isEmpty) {
              return const _SinEntregas();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Entregas del ${textoFecha(_fecha)}',
                  style: context.tituloSeccion(),
                ),
                const SizedBox(height: Esp.s),
                _ListaAcotada(
                  key: const ValueKey('lista-entregas'),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final e = lista[i];
                    return _OpcionUnica(
                      key: ValueKey('entrega-${e.codAccion}'),
                      titulo: e.hora,
                      elegida: _entrega?.codAccion == e.codAccion,
                      onElegir: () => setState(() => _entrega = e),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Paso 2: el cheque ────────────────────────────────────────────────────

  Widget _paso2(BuildContext context) {
    final cheques = ref.watch(
      chequesParaDarCustodiaProvider(widget.codSucursal),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DatoCheque(
          etiqueta: 'Entrega que se copia',
          valor: '${_entrega?.hora ?? ''} · ${textoFecha(_fecha)}',
        ),
        const SizedBox(height: Esp.l),
        cheques.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error:
              (e, _) => NotaDelDato(
                tono: TonoNota.error,
                texto:
                    'No se pudo cargar los cheques: ${mensajeDeErrorCheque(e)}',
                accion: TextButton(
                  onPressed:
                      () => ref.invalidate(
                        chequesParaDarCustodiaProvider(widget.codSucursal),
                      ),
                  child: const Text('Reintentar'),
                ),
              ),
          data:
              (lista) =>
                  lista.isEmpty
                      ? const NotaDelDato(
                        tono: TonoNota.info,
                        texto: 'No hay cheques en esta sucursal.',
                      )
                      : _BuscadorDeCheques(
                        lista: lista,
                        elegido: _cheque?.codCheque,
                        alElegir: (c) => setState(() => _cheque = c),
                      ),
        ),
      ],
    );
  }
}

/// «No hay entregas en esa fecha», con la salida: otra fecha.
class _SinEntregas extends StatelessWidget {
  const _SinEntregas();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('sin-entregas'),
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_busy_outlined, color: cs.onSurfaceVariant),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hay entregas en esa fecha',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Esp.xs),
                Text(
                  'Elige otro día: solo aparecen las entregas a cobranza '
                  'registradas en la fecha elegida.',
                  style: context.apagado(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una opcion de una lista de eleccion unica: el icono dice si esta elegida y el
/// resto del tema (`selected`) la resalta; no depende solo del color.
class _OpcionUnica extends StatelessWidget {
  const _OpcionUnica({
    super.key,
    required this.titulo,
    required this.elegida,
    required this.onElegir,
  });

  final String titulo;
  final bool elegida;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      selected: elegida,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
      leading: Icon(
        elegida ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(titulo, maxLines: 3, overflow: TextOverflow.ellipsis),
      onTap: onElegir,
    );
  }
}

/// Buscador de cheques **en memoria**: la lista entera ya llego y se filtra aqui
/// por palabras, sin distinguir mayusculas. Como el combo de cliente del
/// formulario, solo se pintan las primeras [maximoChequesVisibles].
class _BuscadorDeCheques extends StatefulWidget {
  const _BuscadorDeCheques({
    required this.lista,
    required this.elegido,
    required this.alElegir,
  });

  final List<ChequeResumenEntity> lista;
  final BigInt? elegido;
  final ValueChanged<ChequeResumenEntity> alElegir;

  @override
  State<_BuscadorDeCheques> createState() => _BuscadorDeChequesState();
}

class _BuscadorDeChequesState extends State<_BuscadorDeCheques> {
  String _texto = '';

  /// La lista de la que salieron [_claves]: pasar a minusculas miles de textos
  /// se hace una vez, no en cada tecla.
  List<ChequeResumenEntity>? _origen;
  List<String> _claves = const [];

  void _preparar(List<ChequeResumenEntity> lista) {
    if (identical(lista, _origen)) return;
    _origen = lista;
    _claves = [for (final c in lista) c.datoCheque.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    _preparar(widget.lista);
    final palabras =
        _texto
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();

    final visibles = <ChequeResumenEntity>[];
    var coincidencias = 0;
    for (var i = 0; i < widget.lista.length; i++) {
      if (palabras.every(_claves[i].contains)) {
        coincidencias++;
        if (visibles.length < maximoChequesVisibles) {
          visibles.add(widget.lista[i]);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('buscar-cheque'),
          onChanged: (t) => setState(() => _texto = t),
          decoration: const InputDecoration(
            labelText: 'Buscar cheque',
            helperText:
                'Escribe parte del nro. de cheque, del cliente o del monto.',
            helperMaxLines: 2,
            isDense: true,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: Esp.s),
        if (coincidencias > visibles.length)
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.s),
            child: Text(
              'Hay $coincidencias coincidencias: escribe más para acotar.',
              key: const ValueKey('mas-coincidencias'),
              style: context.apagado(),
            ),
          ),
        if (visibles.isEmpty)
          const NotaDelDato(
            tono: TonoNota.info,
            texto: 'Ningún cheque coincide con la búsqueda.',
          )
        else
          _ListaAcotada(
            key: const ValueKey('lista-cheques-dar-custodia'),
            itemCount: visibles.length,
            itemBuilder: (context, i) {
              final c = visibles[i];
              return _OpcionUnica(
                key: ValueKey('cheque-${c.codCheque}'),
                titulo: c.datoCheque,
                elegida: widget.elegido == c.codCheque,
                onElegir: () => widget.alElegir(c),
              );
            },
          ),
      ],
    );
  }
}
