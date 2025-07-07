import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class UsuariosHomeScreen extends ConsumerStatefulWidget {
  const UsuariosHomeScreen({super.key});

  @override
  ConsumerState<UsuariosHomeScreen> createState() => _UsuariosHomeScreenState();
}

class _UsuariosHomeScreenState extends ConsumerState<UsuariosHomeScreen> {
  int _rowsPerPage = 10;
  int _currentPage = 0;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usersAsyncValue = ref.watch(usersListProvider);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : horizontalPadding,
          vertical: isDesktop ? 24 : 0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, size: 32, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Gestión de Usuarios',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                          hintText: 'Buscar por usuario o nombre...',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _search = value.toLowerCase();
                            _currentPage = 0;
                          });
                        },
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.group, size: 32, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Gestión de Usuarios',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                            hintText: 'Buscar por usuario o nombre...',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _search = value.toLowerCase();
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: usersAsyncValue.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text('No hay usuarios disponibles', style: theme.textTheme.bodyLarge),
                        );
                      }
                      final filtered = users.where((u) =>
                        (u.login ?? '').toLowerCase().contains(_search) ||
                        (u.nombreCompleto ?? '').toLowerCase().contains(_search)
                      ).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text('No se encontraron usuarios con ese criterio', style: theme.textTheme.bodyLarge),
                        );
                      }

                      final paginated = isMobile ? filtered : filtered.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                      Widget buildUserCard(user) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              child: Text(
                                (user.login != null && user.login.isNotEmpty) ? user.login[0].toUpperCase() : '?',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ),
                            title: Text(user.nombreCompleto ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Usuario: ${user.login ?? ''}', style: theme.textTheme.bodyMedium),
                                if ((user.cargo ?? '').isNotEmpty) Text('Cargo: ${user.cargo}', style: theme.textTheme.bodyMedium),
                                Text('Tipo: ${user.tipoUsuario == 'adm' ? 'Administrador' : 'Limitado'}', style: theme.textTheme.bodyMedium),
                                Text('Estado: ${user.estado == 'D' ? 'Desbloqueado' : 'Bloqueado'}', style: theme.textTheme.bodyMedium),
                                Text('Autorizador: ${user.esAutorizador.toUpperCase() == 'SI' ? 'Sí' : 'No'}', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.key_outlined, color: colorScheme.primary),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
                                          const SizedBox(width: 8),
                                          Text('Confirmar acción', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('¿Está seguro que desea realizar esta acción para el usuario?', style: theme.textTheme.bodyMedium),
                                          const SizedBox(height: 12),
                                          Text('Usuario: ${user.login}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          Text('Nombre: ${user.nombreCompleto}', style: theme.textTheme.bodyMedium),
                                          if ((user.cargo ?? '').isNotEmpty) Text('Cargo: ${user.cargo}', style: theme.textTheme.bodyMedium),
                                          Text('Tipo: ${user.tipoUsuario == 'adm' ? 'Administrador' : 'Limitado'}', style: theme.textTheme.bodyMedium),
                                          Text('Estado: ${user.estado == 'D' ? 'Desbloqueado' : 'Bloqueado'}', style: theme.textTheme.bodyMedium),
                                          Text('Autorizador: ${user.esAutorizador.toUpperCase() == 'SI' ? 'Sí' : 'No'}', style: theme.textTheme.bodyMedium),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancelar', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.secondary)),
                                          onPressed: () => Navigator.of(context).pop(false),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.check),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.primary,
                                            foregroundColor: colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          label: const Text('Confirmar'),
                                          onPressed: () => Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmed == true) {
                                  // Lógica: llamar al provider para cambiar la contraseña
                                  final userNotifier = ref.read(userProvider.notifier);
                                  final result = await userNotifier.changePassword(user);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result
                                            ? 'Contraseña restablecida correctamente'
                                            : 'No se pudo restablecer la contraseña'),
                                        backgroundColor: result ? colorScheme.primary : colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }

                      if (isMobile) {
                        return ListView.separated(
                          itemCount: paginated.length,
                          separatorBuilder: (context, i) => const Divider(height: 1),
                          itemBuilder: (context, i) => buildUserCard(paginated[i]),
                        );
                      }

                      // Desktop/tablet: tabla con scroll y paginación, pero cada fila usa el mismo widget de usuario
                      return Column(
                        children: [
                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
                                    headingTextStyle: theme.dataTableTheme.headingTextStyle,
                                    columns: [
                                      DataColumn(label: Text('#', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Usuario', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Nombre Completo', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Cargo', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Tipo', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Estado', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Autorizador', style: theme.dataTableTheme.headingTextStyle)),
                                      DataColumn(label: Text('Acciones', style: theme.dataTableTheme.headingTextStyle)),
                                    ],
                                    rows: List.generate(paginated.length, (i) {
                                      final user = paginated[i];
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('${_currentPage * _rowsPerPage + i + 1}', style: theme.textTheme.bodyMedium)),
                                          DataCell(Text(user.login ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold))),
                                          DataCell(Text(user.nombreCompleto ?? '', style: theme.textTheme.bodyMedium)),
                                          DataCell(Text(user.cargo ?? '', style: theme.textTheme.bodyMedium)),
                                          DataCell(Text(user.tipoUsuario == 'adm' ? 'Administrador' : 'Limitado', style: theme.textTheme.bodyMedium?.copyWith(color: user.tipoUsuario == 'adm' ? colorScheme.primary : colorScheme.secondary, fontWeight: FontWeight.w600))),
                                          DataCell(Text(user.estado == 'D' ? 'Desbloqueado' : 'Bloqueado', style: theme.textTheme.bodyMedium?.copyWith(color: user.estado == 'D' ? colorScheme.primary : colorScheme.error, fontWeight: FontWeight.w600))),
                                          DataCell(Row(
                                            children: [
                                              Icon(
                                                user.esAutorizador.toUpperCase() == 'SI' ? Icons.check_circle : Icons.cancel,
                                                color: user.esAutorizador.toUpperCase() == 'SI' ? colorScheme.primary : colorScheme.error,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.esAutorizador.toUpperCase() == 'SI' ? 'Sí' : 'No',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: user.esAutorizador.toUpperCase() == 'SI' ? colorScheme.primary : colorScheme.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )),
                                          DataCell(IconButton(
                                            icon: Icon(Icons.key_outlined, color: colorScheme.primary, size: 28),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: Row(
                                                      children: [
                                                        Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
                                                        const SizedBox(width: 8),
                                                        Text('Confirmar acción', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
                                                      ],
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('¿Está seguro que desea realizar esta acción para el usuario?', style: theme.textTheme.bodyMedium),
                                                        const SizedBox(height: 12),
                                                        Text('Usuario: ${user.login}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                                        Text('Nombre: ${user.nombreCompleto}', style: theme.textTheme.bodyMedium),
                                                        if ((user.cargo ?? '').isNotEmpty) Text('Cargo: ${user.cargo}', style: theme.textTheme.bodyMedium),
                                                        Text('Tipo: ${user.tipoUsuario == 'adm' ? 'Administrador' : 'Limitado'}', style: theme.textTheme.bodyMedium),
                                                        Text('Estado: ${user.estado == 'D' ? 'Desbloqueado' : 'Bloqueado'}', style: theme.textTheme.bodyMedium),
                                                        Text('Autorizador: ${user.esAutorizador.toUpperCase() == 'SI' ? 'Sí' : 'No'}', style: theme.textTheme.bodyMedium),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: Text('Cancelar', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.secondary)),
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                      ),
                                                      ElevatedButton.icon(
                                                        icon: const Icon(Icons.check),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: colorScheme.primary,
                                                          foregroundColor: colorScheme.onPrimary,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        label: const Text('Confirmar'),
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              if (confirmed == true) {
                                                // Lógica: llamar al provider para cambiar la contraseña
                                                final userNotifier = ref.read(userProvider.notifier);
                                                final result = await userNotifier.changePassword(user);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(result
                                                          ? 'Contraseña restablecida correctamente'
                                                          : 'No se pudo restablecer la contraseña'),
                                                      backgroundColor: result ? colorScheme.primary : colorScheme.error,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          )),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mostrando ${filtered.isEmpty ? 0 : (_currentPage * _rowsPerPage + 1)} a ${(_currentPage * _rowsPerPage + paginated.length)} de ${filtered.length} usuarios',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                                    onPressed: _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                  ),
                                  ...List.generate(
                                    (filtered.length / _rowsPerPage).ceil(),
                                    (i) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: i == _currentPage
                                              ? colorScheme.primary.withOpacity(0.15)
                                              : null,
                                          minimumSize: const Size(32, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () => setState(() => _currentPage = i),
                                        child: Text('${i + 1}', style: theme.textTheme.bodyMedium),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right, color: colorScheme.primary),
                                    onPressed: (_currentPage + 1) * _rowsPerPage < filtered.length
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<int>(
                                    value: _rowsPerPage,
                                    items: [10, 20, 50].map((v) {
                                      return DropdownMenuItem(
                                        value: v,
                                        child: Text('$v', style: theme.textTheme.bodyMedium),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _rowsPerPage = v;
                                          _currentPage = 0;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error al cargar usuarios: $error', style: theme.textTheme.bodyLarge),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}