// Destino final: lib/presentation/screens/tareas-rutinarias/verificar_cierre_screen.dart
import 'package:bosque_flutter/core/state/verificar_cierre_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgRevArqueo en su modo idATR=5 (el paso supervisor, el más
/// complejo de los 6 flujos). Los botones "Marcar revisado"/"Marcar
/// verificada" están gateados por el ACL real de vista 78
/// (cboFueRevisado/plCajaFuerte) — si el usuario no tiene el botón,
/// PermissionWidget lo esconde acá Y el backend lo rechaza igual
/// (AccesoModuloHelper.exigirBoton), esconder en el cliente no alcanza.
/// El panel de cheques (plCheques) queda fuera de alcance — reporte SAP de
/// solo lectura, no relacionado a tac_vale.
///
/// El legacy también muestra: Empleado/Sucursal/Tarea en el panel de
/// arqueos, Sucursal/Destino/Hora/Tipo en el de llegadas, un checkbox real
/// "Mostrar otras sucursales" (chkSuc) que amplía ambos paneles a TODA la
/// empresa, y un 3er panel de traspasos (plMovCaja, solo lectura para este
/// rol) — ninguno de los 4 estaba antes. Sin selector de fecha propio: los
/// paneles 'B' siguen acotados a HOY server-side (no hay @fecha todavía en
/// esos 2 ACCIONes) — pendiente si se necesita.
class VerificarCierreScreen extends ConsumerWidget {
  final int idBitTarea;
  final String nombreTarea;

  const VerificarCierreScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  String _dateFmt(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : (raw is DateTime ? raw : null);
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _horaFmt(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : (raw is DateTime ? raw : null);
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = verificarCierreProvider(idBitTarea);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    ref.listen(provider, (previo, actual) {
      if (actual.ocurrenciasCerradas != null &&
          actual.ocurrenciasCerradas != previo?.ocurrenciasCerradas) {
        HapticFeedback.mediumImpact();
        mostrarAviso(
          context,
          'Verificación cerrada (${actual.ocurrenciasCerradas} ocurrencia(s)).',
        );
        Navigator.of(context).pop(true);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    void marcarArqueo(int idAC) {
      HapticFeedback.selectionClick();
      notifier.marcarArqueoRevisado(idAC);
    }

    void marcarLlegada(int idRp) {
      HapticFeedback.selectionClick();
      notifier.marcarLlegadaVerificada(idRp, 1);
    }

    final panelArqueos = PermissionWidget(
      buttonName: 'cboFueRevisado',
      child: _Seccion(
        titulo: 'Arqueos de caja de hoy',
        icono: Icons.point_of_sale,
        vacio: 'No hay arqueos de caja registrados hoy.',
        hijos: state.arqueos.map((a) {
          final idAC = (a['idAC'] as num).toInt();
          return _FilaArqueo(
            arqueo: a,
            guardando: state.guardandoIdAC == idAC,
            onMarcar: () => marcarArqueo(idAC),
            dateFmt: _dateFmt,
          );
        }).toList(),
      ),
    );

    final panelLlegadas = PermissionWidget(
      buttonName: 'plCajaFuerte',
      child: _Seccion(
        titulo: 'Caja fuerte — llegadas de hoy',
        icono: Icons.lock_outlined,
        vacio: 'No hay llegadas de caja fuerte registradas hoy.',
        hijos: state.llegadas.map((l) {
          final idRp = (l['idRp'] as num).toInt();
          return _FilaLlegada(
            llegada: l,
            guardando: state.guardandoIdRp == idRp,
            onMarcar: () => marcarLlegada(idRp),
            horaFmt: _horaFmt,
          );
        }).toList(),
      ),
    );

    final panelTraspasos = _Seccion(
      titulo: 'Traspasos de hoy (solo lectura)',
      icono: Icons.sync_alt,
      vacio: 'No hay traspasos de movimiento de caja sincronizados hoy.',
      hijos: state.traspasos.map((t) => _FilaTraspasoSoloLectura(traspaso: t)).toList(),
    );

    final paneles = [panelArqueos, panelLlegadas, panelTraspasos];

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreTarea, overflow: TextOverflow.ellipsis),
        actions: [
          // Checkbox real "Mostrar otras sucursales" del legacy — gated
          // por el mismo botón chkSuc que ya usa el resto de la app.
          PermissionWidget(
            buttonName: 'chkSuc',
            child: Row(
              children: [
                Text('Todas las sucursales', style: Theme.of(context).textTheme.labelSmall),
                Switch(
                  value: state.todasSucursales,
                  onChanged: state.cargando
                      ? null
                      : (v) {
                          HapticFeedback.selectionClick();
                          notifier.alternarTodasSucursales(v);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.cargar,
        child:
            state.cargando && state.arqueos.isEmpty && state.llegadas.isEmpty && state.traspasos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                // LayoutBuilder decide por el ANCHO disponible, no por plataforma:
                // en pantallas angostas los 3 paneles del supervisor van apilados;
                // en pantallas anchas van lado a lado, para no dejar el monitor en
                // blanco mientras se revisa.
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final esAncho = constraints.maxWidth >= 1000;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: esAncho
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final p in paneles) ...[
                                      Expanded(child: p),
                                      if (p != paneles.last) const SizedBox(width: 16),
                                    ],
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  for (final p in paneles) ...[
                                    p,
                                    if (p != paneles.last) const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: state.confirmando ? null : notifier.confirmar,
            icon: state.confirmando
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.task_alt),
            label: Text(
              state.confirmando ? 'Cerrando…' : 'Confirmar verificación y cerrar',
            ),
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String vacio;
  final List<Widget> hijos;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.vacio,
    required this.hijos,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (hijos.isEmpty)
              Text(
                vacio,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              )
            else
              ...hijos,
          ],
        ),
      ),
    );
  }
}

class _FilaArqueo extends StatelessWidget {
  final Map<String, dynamic> arqueo;
  final bool guardando;
  final VoidCallback onMarcar;
  final String Function(dynamic) dateFmt;

  const _FilaArqueo({
    required this.arqueo,
    required this.guardando,
    required this.onMarcar,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final revisado = (arqueo['fueRevisado'] as num?)?.toInt() == 1;
    final total = (arqueo['total'] as num?)?.toDouble() ?? 0;
    final diferencia = (arqueo['diferencia'] as num?)?.toDouble() ?? 0;
    final cuadrado = diferencia.abs() <= 0.01;
    final obs = arqueo['obs'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: revisado ? 1.1 : 1.0,
              child: Icon(
                revisado ? Icons.check_circle : Icons.radio_button_unchecked,
                color: revisado
                    ? TareasColors.realizadoTexto(context)
                    : TareasColors.pendienteTexto(context),
              ),
            ),
            title: Text(
              (arqueo['nombreCompletoEncargado'] as String?)?.trim().isNotEmpty == true
                  ? (arqueo['nombreCompletoEncargado'] as String).trim()
                  : 'Encargado sin nombre',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${(arqueo['nombreSucursal'] as String?) ?? '—'} · '
              '${(arqueo['nombreTarea'] as String?) ?? 'Arqueo de caja'}',
            ),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: guardando
                  ? const SizedBox(
                      key: ValueKey('cargando'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : revisado
                  ? Chip(
                      key: const ValueKey('revisado'),
                      label: const Text('Revisado'),
                      backgroundColor: TareasColors.realizado(context),
                      labelStyle: TextStyle(
                        color: TareasColors.realizadoTexto(context),
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                    )
                  : TextButton(
                      key: const ValueKey('pendiente'),
                      onPressed: onMarcar,
                      child: const Text('Marcar revisado'),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                Text('Fecha: ${dateFmt(arqueo['fecha'])}', style: Theme.of(context).textTheme.bodySmall),
                Text('Hora: ${(arqueo['hora'] as String?) ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  'Saldo SAP: ${((arqueo['saldoMovSap'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text('Total: ${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  cuadrado ? 'Cuadró' : 'Diferencia: ${diferencia.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cuadrado
                        ? TareasColors.cuadradoTexto(context)
                        : TareasColors.descuadradoTexto(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (obs != null && obs.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                'Obs: $obs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _FilaLlegada extends StatelessWidget {
  final Map<String, dynamic> llegada;
  final bool guardando;
  final VoidCallback onMarcar;
  final String Function(dynamic) horaFmt;

  const _FilaLlegada({
    required this.llegada,
    required this.guardando,
    required this.onMarcar,
    required this.horaFmt,
  });

  @override
  Widget build(BuildContext context) {
    final verificado = (llegada['fueVerificado'] as num?)?.toInt() == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: verificado ? 1.1 : 1.0,
              child: Icon(
                verificado ? Icons.check_circle : Icons.radio_button_unchecked,
                color: verificado
                    ? TareasColors.realizadoTexto(context)
                    : TareasColors.pendienteTexto(context),
              ),
            ),
            title: Text(
              (llegada['cliente'] as String?) ?? (llegada['persona'] as String?) ?? 'Llegada',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${(llegada['nombreSucursal'] as String?) ?? '—'} · '
              '${(llegada['moneda'] as String?) ?? ''} ${((llegada['importe'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
            ),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: guardando
                  ? const SizedBox(
                      key: ValueKey('cargando'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : verificado
                  ? Chip(
                      key: const ValueKey('verificada'),
                      label: const Text('Verificada'),
                      backgroundColor: TareasColors.realizado(context),
                      labelStyle: TextStyle(
                        color: TareasColors.realizadoTexto(context),
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                    )
                  : TextButton(
                      key: const ValueKey('pendiente'),
                      onPressed: onMarcar,
                      child: const Text('Marcar verificada'),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(
                  'Destino: ${(llegada['destino'] as String?)?.trim().isNotEmpty == true ? llegada['destino'] : '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text('Hora: ${horaFmt(llegada['horallegada'])}', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  'Tipo: ${(llegada['tipo'] as String?) ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

/// Panel de traspasos del supervisor — solo lectura, sin acciones (el
/// legacy no muestra un botón Guardar acá para el rol idATR=5).
class _FilaTraspasoSoloLectura extends StatelessWidget {
  final TraspasoMovCajaEntity traspaso;

  const _FilaTraspasoSoloLectura({required this.traspaso});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.sync_alt, size: 20),
      title: Text(traspaso.acctName ?? traspaso.account ?? 'Traspaso'),
      subtitle: Text(
        '${traspaso.bd ?? ''} · ${traspaso.tipoTransaccion ?? ''} · cuenta ${traspaso.account ?? '—'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if ((traspaso.bs ?? 0) != 0) Text('Bs ${traspaso.bs!.toStringAsFixed(2)}'),
          if ((traspaso.dolares ?? 0) != 0) Text('\$us ${traspaso.dolares!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
