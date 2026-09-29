import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/ventas_ciudades_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/ciudad_venta_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qué ciudades del catálogo de Ventas ve cada usuario. Entra el `ROLE_ADM` o
/// quien tenga el botón `btnCiudadesUsuario`; el backend valida lo mismo.
///
/// - Sin ciudades marcadas: ve la ciudad de su login, como siempre.
/// - Con ciudades marcadas: ve SOLO esas, más "Todas las mías".
/// - Administradores: ven todo; no hace falta marcarles nada.
///
/// Cada casilla se guarda al tocarla (`p_abm_tven_UsuarioCiudad` I/D).
class CiudadesPorUsuarioScreen extends ConsumerStatefulWidget {
  const CiudadesPorUsuarioScreen({super.key});

  @override
  ConsumerState<CiudadesPorUsuarioScreen> createState() =>
      _CiudadesPorUsuarioScreenState();
}

class _CiudadesPorUsuarioScreenState
    extends ConsumerState<CiudadesPorUsuarioScreen> {
  final _busqueda = TextEditingController();
  String _filtro = '';
  bool _soloConExcepciones = false;
  int? _seleccionado;

  /// Copia local de las asignaciones: se actualiza al guardar cada casilla,
  /// sin volver a pedir toda la lista.
  Map<int, Set<int>>? _asignaciones;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  static bool _esAdmin(LoginEntity u) =>
      u.tipoUsuario.toLowerCase().contains('adm');

  Future<bool> _alternar(int codUsuario, int codCiudad, bool marcar) async {
    final repo = ref.read(ventasCiudadesRepositoryProvider);
    try {
      if (marcar) {
        await repo.asignar(codUsuario, codCiudad);
      } else {
        await repo.quitar(codUsuario, codCiudad);
      }
      setState(() {
        final set = _asignaciones!.putIfAbsent(codUsuario, () => <int>{});
        marcar ? set.add(codCiudad) : set.remove(codCiudad);
        if (set.isEmpty) _asignaciones!.remove(codUsuario);
      });
      return true;
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tono: TonoAviso.error,
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usuarios = ref.watch(usersListProvider);
    final ciudades = ref.watch(ciudadesVentaProvider);
    final asignaciones = ref.watch(asignacionesCiudadProvider);

    // La primera carga llena la copia local; después manda la copia.
    if (_asignaciones == null && asignaciones.hasValue) {
      _asignaciones = {
        for (final e in asignaciones.value!.entries) e.key: {...e.value},
      };
    }

    final error = usuarios.error ?? ciudades.error ?? asignaciones.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Ciudades por usuario')),
      body: Builder(
        builder: (context) {
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 44, color: cs.error),
                    const SizedBox(height: 12),
                    Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        _asignaciones = null;
                        ref.invalidate(usersListProvider);
                        ref.invalidate(asignacionesCiudadProvider);
                        ref.invalidate(ciudadesVentaProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!usuarios.hasValue ||
              !ciudades.hasValue ||
              _asignaciones == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _contenido(usuarios.value!, ciudades.value!, _asignaciones!);
        },
      ),
    );
  }

  Widget _contenido(
    List<LoginEntity> todos,
    List<CiudadVentaEntity> ciudades,
    Map<int, Set<int>> asignaciones,
  ) {
    final filtrados =
        todos.where((u) {
            if (_soloConExcepciones &&
                !(asignaciones[u.codUsuario]?.isNotEmpty ?? false)) {
              return false;
            }
            if (_filtro.isEmpty) return true;
            return u.nombreCompleto.toLowerCase().contains(_filtro) ||
                u.login.toLowerCase().contains(_filtro);
          }).toList()
          ..sort(
            (a, b) => a.nombreCompleto.toLowerCase().compareTo(
              b.nombreCompleto.toLowerCase(),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= 840;

        final lista = Column(
          children: [
            _explicacion(context),
            _buscador(context),
            Expanded(
              child:
                  filtrados.isEmpty
                      ? const Center(child: Text('Ningún usuario coincide'))
                      : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtrados.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = filtrados[i];
                          return _filaUsuario(
                            u,
                            ciudades,
                            asignaciones[u.codUsuario] ?? const <int>{},
                            seleccionado:
                                ancho && _seleccionado == u.codUsuario,
                            onTap: () {
                              if (ancho) {
                                setState(() => _seleccionado = u.codUsuario);
                              } else {
                                _abrirHoja(u, ciudades);
                              }
                            },
                          );
                        },
                      ),
            ),
          ],
        );

        if (!ancho) return lista;

        final elegido =
            todos.where((u) => u.codUsuario == _seleccionado).firstOrNull;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 400, child: lista),
            const VerticalDivider(width: 1),
            Expanded(
              child:
                  elegido == null
                      ? Center(
                        child: Text(
                          'Elija un usuario para ver o cambiar sus ciudades',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      : _PanelCiudades(
                        key: ValueKey(elegido.codUsuario),
                        usuario: elegido,
                        esAdmin: _esAdmin(elegido),
                        ciudades: ciudades,
                        marcadas: asignaciones[elegido.codUsuario] ?? const {},
                        onAlternar: _alternar,
                      ),
            ),
          ],
        );
      },
    );
  }

  void _abrirHoja(LoginEntity u, List<CiudadVentaEntity> ciudades) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder:
          (_) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: _PanelCiudades(
              usuario: u,
              esAdmin: _esAdmin(u),
              ciudades: ciudades,
              marcadas: _asignaciones![u.codUsuario] ?? const {},
              onAlternar: _alternar,
            ),
          ),
    );
  }

  Widget _explicacion(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: cs.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin ciudades marcadas, el usuario ve la ciudad de su login. '
              'Con ciudades marcadas, ve solo esas. '
              'Los administradores ven todas.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buscador(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busqueda,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o usuario',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _filtro = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 8),
          FilterChip(
            label: const Text('Solo con ciudades asignadas'),
            selected: _soloConExcepciones,
            onSelected: (v) => setState(() => _soloConExcepciones = v),
          ),
        ],
      ),
    );
  }

  Widget _filaUsuario(
    LoginEntity u,
    List<CiudadVentaEntity> ciudades,
    Set<int> marcadas, {
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final admin = _esAdmin(u);
    final nombres =
        ciudades
            .where((c) => marcadas.contains(c.codCiudad))
            .map((c) => c.ciudad)
            .toList();

    final String resumen;
    final Color colorResumen;
    if (admin) {
      resumen = 'Administrador · ve todas';
      colorResumen = cs.primary;
    } else if (nombres.isEmpty) {
      resumen = 'Ciudad de su login';
      colorResumen = cs.onSurfaceVariant;
    } else {
      resumen = nombres.join(', ');
      colorResumen = cs.tertiary;
    }

    final nombre = u.nombreCompleto.trim().isEmpty ? u.login : u.nombreCompleto;
    return ListTile(
      selected: seleccionado,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.5),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            admin
                ? cs.primaryContainer
                : nombres.isEmpty
                ? cs.surfaceContainerHighest
                : cs.tertiaryContainer,
        child: Text(
          nombre.isEmpty ? '?' : nombre.characters.first.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: admin ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
      ),
      title: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${u.login} · $resumen',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorResumen, fontSize: 12.5),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Casillas de ciudades de un usuario. Tiene su propio estado para que la
/// hoja de celular se actualice sin depender de la pantalla de atrás.
class _PanelCiudades extends StatefulWidget {
  final LoginEntity usuario;
  final bool esAdmin;
  final List<CiudadVentaEntity> ciudades;
  final Set<int> marcadas;
  final Future<bool> Function(int codUsuario, int codCiudad, bool marcar)
  onAlternar;

  const _PanelCiudades({
    super.key,
    required this.usuario,
    required this.esAdmin,
    required this.ciudades,
    required this.marcadas,
    required this.onAlternar,
  });

  @override
  State<_PanelCiudades> createState() => _PanelCiudadesState();
}

class _PanelCiudadesState extends State<_PanelCiudades> {
  late final Set<int> _marcadas = {...widget.marcadas};
  final Set<int> _guardando = {};

  Future<void> _tocar(int codCiudad, bool marcar) async {
    setState(() => _guardando.add(codCiudad));
    final ok = await widget.onAlternar(
      widget.usuario.codUsuario,
      codCiudad,
      marcar,
    );
    if (!mounted) return;
    setState(() {
      _guardando.remove(codCiudad);
      if (ok) marcar ? _marcadas.add(codCiudad) : _marcadas.remove(codCiudad);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u = widget.usuario;
    final nombre = u.nombreCompleto.trim().isEmpty ? u.login : u.nombreCompleto;

    final String estado;
    if (widget.esAdmin) {
      estado = 'Es administrador: ve todas las ciudades sin marcar nada.';
    } else if (_marcadas.isEmpty) {
      estado = 'Sin ciudades marcadas: ve solo la ciudad de su login.';
    } else if (_marcadas.length == 1) {
      estado = 'Ve solo esta ciudad.';
    } else {
      estado =
          'Ve estas ${_marcadas.length} ciudades, una a la vez o todas juntas.';
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          nombre,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(u.login, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        Text(
          estado,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: widget.esAdmin ? cs.primary : cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        for (final c in widget.ciudades)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: widget.esAdmin || _marcadas.contains(c.codCiudad),
            onChanged:
                widget.esAdmin || _guardando.contains(c.codCiudad)
                    ? null
                    : (v) => _tocar(c.codCiudad, v ?? false),
            title: Text(c.ciudad),
            secondary:
                _guardando.contains(c.codCiudad)
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : null,
          ),
      ],
    );
  }
}
