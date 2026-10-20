/// Usuarios externos (`tcpeExamenes/Usuarios`): los postulantes con login
/// IPX. Se activan o desactivan y se les regenera la clave (que se ve una sola
/// vez). El administrador puede pasar a hash las claves que quedan en claro.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/dialogos_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

final _buscarProvider = StateProvider.autoDispose<String>((ref) => '');
final _activoProvider = StateProvider.autoDispose<bool?>((ref) => true);
final _areaProvider = StateProvider.autoDispose<BigInt?>((ref) => null);
final _enCursoProvider = StateProvider.autoDispose<Set<BigInt>>((ref) => {});

String _nombre(TcpeUsuarioEntity u) =>
    [u.nombres, u.apellidoPaterno, u.apellidoMaterno].where((p) => (p ?? '').trim().isNotEmpty).join(' ');

class UsuariosExternosScreen extends ConsumerWidget {
  const UsuariosExternosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(tcpeUsuariosExternosProvider);
    final areas = ref.watch(tcpeAreasProvider).valueOrNull ?? const [];
    final nombresArea = {for (final a in areas) a.codArea: a.nombreArea ?? ''};
    final buscar = ref.watch(_buscarProvider).toLowerCase();
    final activo = ref.watch(_activoProvider);
    final codArea = ref.watch(_areaProvider);
    final enCurso = ref.watch(_enCursoProvider);
    final esAdmin = ref.watch(userProvider)?.tipoUsuario == 'ROLE_ADM';

    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        final activos = (activo != true ? 1 : 0) + (codArea != null ? 1 : 0);
        return Scaffold(
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Exámenes · Usuarios externos',
                  titulo: 'Usuarios externos',
                  icono: Icons.badge_outlined,
                  detalle: 'Postulantes que rinden con un usuario IPX. Desactivar uno le impide entrar a rendir.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(tcpeUsuariosExternosProvider),
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.refresh),
                    ),
                    if (esAdmin)
                      OutlinedButton.icon(
                        onPressed: () => _migrar(context, ref),
                        icon: const Icon(Icons.enhanced_encryption_outlined, size: 18),
                        label: const Text('Proteger claves antiguas'),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                if (compacto) ...[_busqueda(ref, compacto), const SizedBox(height: Esp.s)],
                FiltrosExamenes(
                  compacto: compacto,
                  activos: activos,
                  onLimpiar: () {
                    ref.read(_activoProvider.notifier).state = true;
                    ref.read(_areaProvider.notifier).state = null;
                  },
                  campos: [
                    if (!compacto) _busqueda(ref, compacto),
                    ComboFiltro<bool>(
                      etiqueta: 'Estado',
                      valor: activo,
                      textoTodos: 'Activos e inactivos',
                      opciones: const [(true, 'Activos'), (false, 'Inactivos')],
                      onCambio: (v) => ref.read(_activoProvider.notifier).state = v,
                    ),
                    ComboFiltro<BigInt>(
                      etiqueta: 'Área',
                      valor: codArea,
                      textoTodos: 'Todas',
                      opciones: [for (final a in areas) (a.codArea, a.nombreArea ?? '')],
                      onCambio: (v) => ref.read(_areaProvider.notifier).state = v,
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Expanded(
                  child: datos.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoLista(),
                    error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(tcpeUsuariosExternosProvider)),
                    data: (todos) {
                      final filas = [
                        for (final u in todos)
                          if ((activo == null || u.activo == activo) &&
                              (codArea == null || u.codArea == codArea) &&
                              (buscar.isEmpty || '${u.login} ${_nombre(u)} ${u.ci}'.toLowerCase().contains(buscar)))
                            u,
                      ];
                      return TablaExamenes<TcpeUsuarioEntity>(
                        filas: filas,
                        claveFila: (u) => u.codUsuario,
                        tonoFila: (u) => u.activo ? TonoExamen.principal : TonoExamen.neutro,
                        vacio: const VacioExamenes(
                          icono: Icons.person_off_outlined,
                          titulo: 'No hay usuarios con estos filtros',
                          detalle: 'Los usuarios externos se crean al generar un lote para postulantes.',
                        ),
                        columnas: [
                          ColumnaExamen(
                            'Usuario',
                            (u) => Text(u.login ?? '--', style: const TextStyle(fontFamily: fuenteFija, fontWeight: FontWeight.w600)),
                            flex: 2,
                          ),
                          ColumnaExamen('Nombre', (u) => CeldaTexto(_nombre(u).isEmpty ? null : _nombre(u)), flex: 5),
                          ColumnaExamen('CI', (u) => CeldaTexto(u.ci), flex: 2),
                          ColumnaExamen('Área', (u) => CeldaTexto(nombresArea[u.codArea], apagado: true), flex: 3),
                          ColumnaExamen('Alta', (u) => CeldaTexto(fechaCorta(u.audFecha), apagado: true), flex: 2),
                          ColumnaExamen('Estado', (u) => _estado(u, enCurso), flex: 2),
                        ],
                        acciones: [
                          AccionExamen(
                            'Regenerar clave',
                            Icons.key_outlined,
                            (u) => _regenerar(context, ref, u),
                            tono: TonoExamen.secundario,
                          ),
                          AccionExamen(
                            'Desactivar',
                            Icons.block,
                            (u) => _alternar(context, ref, u),
                            visible: (u) => u.activo,
                            tono: TonoExamen.terciario,
                          ),
                          AccionExamen(
                            'Activar',
                            Icons.check_circle_outline,
                            (u) => _alternar(context, ref, u),
                            visible: (u) => !u.activo,
                          ),
                        ],
                        tarjeta:
                            (u) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      u.login ?? '--',
                                      style: const TextStyle(fontFamily: fuenteFija, fontWeight: FontWeight.w700),
                                    ),
                                    const Spacer(),
                                    _estado(u, enCurso),
                                  ],
                                ),
                                const SizedBox(height: Esp.xs),
                                Text(_nombre(u).isEmpty ? 'Todavía no completó sus datos' : _nombre(u)),
                                Text(
                                  'CI ${u.ci ?? '--'} · ${nombresArea[u.codArea] ?? 'Sin área'}',
                                  style: context.apagado(),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _busqueda(WidgetRef ref, bool compacto) => SizedBox(
    width: compacto ? double.infinity : 300,
    child: TextField(
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search, size: 20),
        hintText: 'Buscar por usuario, nombre o CI',
        border: OutlineInputBorder(),
      ),
      onChanged: (t) => ref.read(_buscarProvider.notifier).state = t.trim(),
    ),
  );

  Widget _estado(TcpeUsuarioEntity u, Set<BigInt> enCurso) {
    if (enCurso.contains(u.codUsuario)) {
      return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Etiqueta(texto: u.activo ? 'Activo' : 'Inactivo', tono: u.activo ? TonoEtiqueta.exito : TonoEtiqueta.neutro);
  }

  void _marcar(WidgetRef ref, BigInt cod, bool en) {
    final s = {...ref.read(_enCursoProvider)};
    en ? s.add(cod) : s.remove(cod);
    ref.read(_enCursoProvider.notifier).state = s;
  }

  Future<void> _alternar(BuildContext context, WidgetRef ref, TcpeUsuarioEntity u) async {
    if (u.activo) {
      final ok = await confirmar(
        context,
        titulo: 'Desactivar ${u.login ?? ''}',
        detalle: 'No podrá entrar a rendir hasta que lo actives de nuevo. Sus resultados se conservan.',
        textoConfirmar: 'Desactivar',
        destructiva: true,
      );
      if (!ok || !context.mounted) return;
    }
    _marcar(ref, u.codUsuario, true);
    try {
      await ref.read(examenesRepositoryProvider).guardarCatalogo(TcpeCatalogo.usuario, u.copyWith(activo: !u.activo));
      ref.invalidate(tcpeUsuariosExternosProvider);
      if (context.mounted) avisar(context, u.activo ? 'Usuario desactivado.' : 'Usuario activado.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (context.mounted) _marcar(ref, u.codUsuario, false);
    }
  }

  /// Clave temporal nueva, al azar: la anterior deja de servir.
  Future<void> _regenerar(BuildContext context, WidgetRef ref, TcpeUsuarioEntity u) async {
    final ok = await confirmar(
      context,
      titulo: 'Regenerar clave de ${u.login ?? ''}',
      detalle:
          'Se crea una clave temporal nueva y la anterior deja de servir. La nueva se muestra una sola vez.',
      textoConfirmar: 'Regenerar',
    );
    if (!ok || !context.mounted) return;
    _marcar(ref, u.codUsuario, true);
    try {
      final c = await ref.read(examenesRepositoryProvider).regenerarClave(u.codUsuario);
      if (!context.mounted) return;
      await mostrarCredenciales(
        context,
        tituloLote: _nombre(u).isEmpty ? (u.login ?? '') : _nombre(u),
        credenciales: [
          c.copyWith(
            login: c.login ?? u.login,
            ci: c.ci ?? u.ci,
            nombreCompleto: c.nombreCompleto ?? (_nombre(u).isEmpty ? null : _nombre(u)),
          ),
        ],
        titulo: 'Clave nueva',
      );
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (context.mounted) _marcar(ref, u.codUsuario, false);
    }
  }

  Future<void> _migrar(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Proteger claves antiguas',
      detalle:
          'Las claves que el sistema anterior guardaba en texto claro pasan a guardarse cifradas. '
          'Los usuarios siguen entrando con la misma clave. Puede tardar varios minutos.',
      textoConfirmar: 'Proteger',
    );
    if (!ok || !context.mounted) return;
    try {
      final n = await ref.read(examenesRepositoryProvider).migrarClaves();
      if (context.mounted) avisar(context, n == 0 ? 'No había claves por proteger.' : '$n claves protegidas.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }
}
