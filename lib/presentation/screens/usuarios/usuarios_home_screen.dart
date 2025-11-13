import 'package:bosque_flutter/domain/entities/vista_usuario_entity.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';
import 'package:dropdown_search/dropdown_search.dart';
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

  void _showResetPasswordDialog(
    dynamic user,
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Confirmar acción',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Está seguro que desea restablecer la contraseña para el usuario?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Usuario: ${user.login}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Nombre: ${user.nombreCompleto}',
                style: theme.textTheme.bodyMedium,
              ),
              if ((user.cargo ?? '').isNotEmpty)
                Text('Cargo: ${user.cargo}', style: theme.textTheme.bodyMedium),
              Text(
                'Tipo: ${user.tipoUsuario == 'adm' ? 'Administrador' : 'Limitado'}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancelar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: const Text('Confirmar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      final userNotifier = ref.read(userProvider.notifier);
      final result = await userNotifier.changePassword(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result
                  ? 'Contraseña restablecida correctamente'
                  : 'No se pudo restablecer la contraseña',
            ),
            backgroundColor: result ? colorScheme.primary : colorScheme.error,
          ),
        );
      }
    }
  }

  void _showUserEditDialog(
    dynamic user,
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isCopy,
    List<dynamic> users,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _UserFormDialog(
          user: user,
          isCopy: isCopy,
          theme: theme,
          colorScheme: colorScheme,
          onResetPassword: () {
            Navigator.of(dialogContext).pop();
            _showResetPasswordDialog(user, context, ref, theme, colorScheme);
          },
          onShowMessage: (message, isSuccess) {
            Navigator.of(dialogContext).pop();
            Future.delayed(Duration(milliseconds: 300), () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor:
                      isSuccess ? colorScheme.primary : colorScheme.error,
                ),
              );
            });
          },
          availableUsers: users,
        );
      },
    );
  }

  void _showCopyPermissionsDialog(
    dynamic user,
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    List<dynamic> users,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _CopyPermissionsDialog(
          user: user,
          users: users,
          theme: theme,
          colorScheme: colorScheme,
          onConfirm: (selectedUser) async {
            try {
              // Crear la entidad de vista de usuario para copiar permisos
              final vistaUsuarioEntity = VistaUsuarioEntity(
                codUsuario: user.codUsuario,
                codVista: 0,
                nivelAcceso: 0,
                autorizador: selectedUser.codUsuario,
                audUsuarioI: ref.read(userProvider)?.codUsuario ?? 0,
              );

              // Llamar al método copiarPermisos del repositorio
              final resultado = await AuthRepositoryImpl().copiarPermisos(
                vistaUsuarioEntity,
              );

              Navigator.of(dialogContext).pop();
              Future.delayed(const Duration(milliseconds: 300), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      resultado
                          ? 'Permisos de ${selectedUser.login} copiados a ${user.login}'
                          : 'Error al copiar permisos',
                    ),
                    backgroundColor:
                        resultado ? colorScheme.primary : colorScheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            } catch (e) {
              debugPrint('Error al copiar permisos: $e');
              Navigator.of(dialogContext).pop();
              Future.delayed(const Duration(milliseconds: 300), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al copiar permisos: $e'),
                    backgroundColor: colorScheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }
          },
        );
      },
    );
  }

  void _showAssignPermissionsDialog(
    dynamic user,
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _AssignPermissionsDialog(
          user: user,
          theme: theme,
          colorScheme: colorScheme,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            Future.delayed(const Duration(milliseconds: 300), () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Permisos asignados correctamente'),
                  backgroundColor: colorScheme.primary,
                ),
              );
            });
          },
        );
      },
    );
  }

  void _showNewUserDialog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _UserFormDialog(
          user: null,
          isCopy: false,
          isNew: true,
          theme: theme,
          colorScheme: colorScheme,
          onResetPassword: () {
            // No hacer nada en nuevo usuario
          },
          onShowMessage: (message, isSuccess) {
            Navigator.of(dialogContext).pop();
            Future.delayed(Duration(milliseconds: 300), () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor:
                      isSuccess ? colorScheme.primary : colorScheme.error,
                ),
              );
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usersAsyncValue = ref.watch(usersListProvider);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
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
                          Icon(
                            Icons.group,
                            size: 32,
                            color: colorScheme.primary,
                          ),
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
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.primary,
                          ),
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
                            prefixIcon: Icon(
                              Icons.search,
                              color: colorScheme.primary,
                            ),
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
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: const Text('Nuevo Usuario'),
                        onPressed: () {
                          _showNewUserDialog(context, theme, colorScheme, ref);
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: usersAsyncValue.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay usuarios disponibles',
                            style: theme.textTheme.bodyLarge,
                          ),
                        );
                      }
                      final filtered =
                          users
                              .where(
                                (u) =>
                                    u.login.toLowerCase().contains(_search) ||
                                    (u.nombreCompleto).toLowerCase().contains(
                                      _search,
                                    ),
                              )
                              .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No se encontraron usuarios con ese criterio',
                            style: theme.textTheme.bodyLarge,
                          ),
                        );
                      }

                      final paginated =
                          isMobile
                              ? filtered
                              : filtered
                                  .skip(_currentPage * _rowsPerPage)
                                  .take(_rowsPerPage)
                                  .toList();

                      Widget buildUserCard(user) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              child: Text(
                                (user.login != null && user.login.isNotEmpty)
                                    ? user.login[0].toUpperCase()
                                    : '?',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ),
                            title: Text(
                              user.nombreCompleto ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario: ${user.login ?? ''}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if ((user.cargo ?? '').isNotEmpty)
                                  Text(
                                    'Cargo: ${user.cargo}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                Text(
                                  'Tipo: ${user.tipoUsuario == 'adm' ? 'Administrador' : 'Limitado'}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  'Estado: ${user.estado == 'D' ? 'Desbloqueado' : 'Bloqueado'}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  'Autorizador: ${user.esAutorizador.toUpperCase() == 'SI' ? 'Sí' : 'No'}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.primary,
                              ),
                              onSelected: (value) {
                                if (value == 'copiar') {
                                  _showCopyPermissionsDialog(
                                    user,
                                    context,
                                    ref,
                                    theme,
                                    colorScheme,
                                    users,
                                  );
                                } else if (value == 'permisos') {
                                  _showAssignPermissionsDialog(
                                    user,
                                    context,
                                    theme,
                                    colorScheme,
                                  );
                                } else if (value == 'editar') {
                                  _showUserEditDialog(
                                    user,
                                    context,
                                    ref,
                                    theme,
                                    colorScheme,
                                    false,
                                    users,
                                  );
                                } else if (value == 'restablecer') {
                                  _showResetPasswordDialog(
                                    user,
                                    context,
                                    ref,
                                    theme,
                                    colorScheme,
                                  );
                                }
                              },
                              itemBuilder:
                                  (BuildContext context) => [
                                    PopupMenuItem(
                                      value: 'copiar',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Copiar Permisos'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'permisos',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.security,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Permisos'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'restablecer',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.key_outlined,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Restablecer Contraseña'),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        );
                      }

                      if (isMobile) {
                        return ListView.separated(
                          itemCount: paginated.length,
                          separatorBuilder:
                              (context, i) => const Divider(height: 1),
                          itemBuilder:
                              (context, i) => buildUserCard(paginated[i]),
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
                                    headingRowColor: WidgetStateProperty.all(
                                      colorScheme.surfaceContainerHighest,
                                    ),
                                    headingTextStyle:
                                        theme.dataTableTheme.headingTextStyle,
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          '#',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Usuario',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Nombre Completo',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Cargo',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Tipo',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Estado',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Autorizador',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Acciones',
                                          style:
                                              theme
                                                  .dataTableTheme
                                                  .headingTextStyle,
                                        ),
                                      ),
                                    ],
                                    rows: List.generate(paginated.length, (i) {
                                      final user = paginated[i];
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              '${_currentPage * _rowsPerPage + i + 1}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              user.login,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              user.nombreCompleto,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              user.cargo,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              user.tipoUsuario == 'adm'
                                                  ? 'Administrador'
                                                  : 'Limitado',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        user.tipoUsuario ==
                                                                'adm'
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme
                                                                .secondary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              user.estado == 'D'
                                                  ? 'Desbloqueado'
                                                  : 'Bloqueado',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        user.estado == 'D'
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme.error,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                Icon(
                                                  user.esAutorizador
                                                              .toUpperCase() ==
                                                          'SI'
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                      user.esAutorizador
                                                                  .toUpperCase() ==
                                                              'SI'
                                                          ? colorScheme.primary
                                                          : colorScheme.error,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.esAutorizador
                                                              .toUpperCase() ==
                                                          'SI'
                                                      ? 'Sí'
                                                      : 'No',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            user.esAutorizador
                                                                        .toUpperCase() ==
                                                                    'SI'
                                                                ? colorScheme
                                                                    .primary
                                                                : colorScheme
                                                                    .error,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.lock_outline,
                                                    color: colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Copiar Permisos',
                                                  onPressed: () {
                                                    _showCopyPermissionsDialog(
                                                      user,
                                                      context,
                                                      ref,
                                                      theme,
                                                      colorScheme,
                                                      users,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.security,
                                                    color: colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Asignar Permisos',
                                                  onPressed: () {
                                                    _showAssignPermissionsDialog(
                                                      user,
                                                      context,
                                                      theme,
                                                      colorScheme,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Editar usuario',
                                                  onPressed: () {
                                                    _showUserEditDialog(
                                                      user,
                                                      context,
                                                      ref,
                                                      theme,
                                                      colorScheme,
                                                      false,
                                                      users,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.key_outlined,
                                                    color: colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                  tooltip:
                                                      'Restablecer contraseña',
                                                  onPressed: () {
                                                    _showResetPasswordDialog(
                                                      user,
                                                      context,
                                                      ref,
                                                      theme,
                                                      colorScheme,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
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
                                    icon: Icon(
                                      Icons.chevron_left,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed:
                                        _currentPage > 0
                                            ? () =>
                                                setState(() => _currentPage--)
                                            : null,
                                  ),
                                  ...List.generate(
                                    (filtered.length / _rowsPerPage).ceil(),
                                    (i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor:
                                              i == _currentPage
                                                  ? colorScheme.primary
                                                      .withOpacity(0.15)
                                                  : null,
                                          minimumSize: const Size(32, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _currentPage = i,
                                            ),
                                        child: Text(
                                          '${i + 1}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed:
                                        (_currentPage + 1) * _rowsPerPage <
                                                filtered.length
                                            ? () =>
                                                setState(() => _currentPage++)
                                            : null,
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<int>(
                                    value: _rowsPerPage,
                                    items:
                                        [10, 20, 50].map((v) {
                                          return DropdownMenuItem(
                                            value: v,
                                            child: Text(
                                              '$v',
                                              style: theme.textTheme.bodyMedium,
                                            ),
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
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stack) => Center(
                          child: Text(
                            'Error al cargar usuarios: $error',
                            style: theme.textTheme.bodyLarge,
                          ),
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

class _UserFormDialog extends ConsumerStatefulWidget {
  final dynamic user;
  final bool isCopy;
  final bool isNew;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onResetPassword;
  final Function(String message, bool isSuccess) onShowMessage;
  final List<dynamic>? availableUsers;

  const _UserFormDialog({
    required this.user,
    required this.isCopy,
    this.isNew = false,
    required this.theme,
    required this.colorScheme,
    required this.onResetPassword,
    required this.onShowMessage,
    this.availableUsers,
  });

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  late int _selectedEmpleadoCode; // Cambiar a int para almacenar codPersona
  late TextEditingController _loginController;
  late TextEditingController _cargoController;
  late String _tipoUsuario;
  late String _estado;
  late String _esAutorizador;

  @override
  void initState() {
    super.initState();
    // Si es edición (no es nuevo ni copia), cargar el codEmpleado del usuario
    if (!widget.isNew && !widget.isCopy) {
      _selectedEmpleadoCode = widget.user?.codEmpleado ?? 0;
    } else {
      _selectedEmpleadoCode = 0;
    }
    _loginController = TextEditingController(text: widget.user?.login ?? '');
    _cargoController = TextEditingController(text: widget.user?.cargo ?? '');
    _tipoUsuario = widget.user?.tipoUsuario ?? 'lim';
    _estado = widget.user?.estado ?? 'D';
    _esAutorizador = widget.user?.esAutorizador?.toUpperCase() ?? 'NO';
  }

  @override
  void dispose() {
    _loginController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isNew
            ? 'Nuevo Usuario'
            : widget.isCopy
            ? 'Copiar Usuario'
            : 'Editar Usuario',
        style: widget.theme.textTheme.titleLarge?.copyWith(
          color: widget.colorScheme.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ref
                .watch(empleadosListProvider)
                .when(
                  data: (empleados) {
                    // Crear un map de codEmpleado -> nombre para búsqueda
                    final selectedEmpleado =
                        _selectedEmpleadoCode == 0
                            ? null
                            : empleados.firstWhere(
                              (e) => e.codEmpleado == _selectedEmpleadoCode,
                              orElse: () => null as dynamic,
                            );

                    return DropdownSearch<dynamic>(
                      items: empleados,
                      selectedItem: selectedEmpleado,
                      enabled: widget.isNew || widget.isCopy,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Empleado',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.person,
                            color: widget.colorScheme.primary,
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Buscar empleado...',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.search,
                              color: widget.colorScheme.primary,
                            ),
                          ),
                        ),
                        itemBuilder: (context, empleado, isSelected) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${empleado.nombres}',
                              style: widget.theme.textTheme.bodyMedium,
                            ),
                          );
                        },
                      ),
                      itemAsString:
                          (empleado) =>
                              '${empleado.nombres} (Cod: ${empleado.codEmpleado})',
                      onChanged:
                          widget.isNew || widget.isCopy
                              ? (value) {
                                setState(() {
                                  _selectedEmpleadoCode =
                                      value?.codEmpleado ?? 0;
                                });
                              }
                              : null,
                      compareFn: (item, selectedItem) {
                        return item.codEmpleado == selectedItem.codEmpleado;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginController,
              decoration: InputDecoration(
                labelText: 'Login',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.login,
                  color: widget.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cargoController,
              enabled: widget.isNew || widget.isCopy,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: widget.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoUsuario,
              decoration: InputDecoration(
                labelText: 'Tipo de Usuario',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.admin_panel_settings,
                  color: widget.colorScheme.primary,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'adm',
                  child: Text(
                    'Administrador',
                    style: widget.theme.textTheme.bodyMedium,
                  ),
                ),
                DropdownMenuItem(
                  value: 'lim',
                  child: Text(
                    'Limitado',
                    style: widget.theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoUsuario = value ?? 'lim';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: widget.colorScheme.primary),
              ),
              items: [
                DropdownMenuItem(
                  value: 'D',
                  child: Text(
                    'Desbloqueado',
                    style: widget.theme.textTheme.bodyMedium,
                  ),
                ),
                DropdownMenuItem(
                  value: 'B',
                  child: Text(
                    'Bloqueado',
                    style: widget.theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _estado = value ?? 'D';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _esAutorizador,
              decoration: InputDecoration(
                labelText: 'Es Autorizador',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.check_circle,
                  color: widget.colorScheme.primary,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'SI',
                  child: Text('Sí', style: widget.theme.textTheme.bodyMedium),
                ),
                DropdownMenuItem(
                  value: 'NO',
                  child: Text('No', style: widget.theme.textTheme.bodyMedium),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _esAutorizador = value ?? 'NO';
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        if (!widget.isCopy)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colorScheme.error,
              foregroundColor: widget.colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: widget.onResetPassword,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.key_outlined,
                  size: 20,
                  color: widget.colorScheme.onError,
                ),
                const SizedBox(width: 8),
                const Text('Restablecer Contraseña'),
              ],
            ),
          ),
        TextButton(
          child: Text(
            'Cancelar',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              color: widget.colorScheme.secondary,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colorScheme.primary,
            foregroundColor: widget.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          label: Text(
            widget.isNew
                ? 'Crear Usuario'
                : widget.isCopy
                ? 'Crear Copia'
                : 'Guardar Cambios',
          ),
          onPressed: () {
            widget.onShowMessage(
              widget.isNew
                  ? 'Usuario creado correctamente'
                  : widget.isCopy
                  ? 'Usuario copiado correctamente'
                  : 'Cambios guardados correctamente',
              true,
            );
          },
        ),
      ],
    );
  }
}

class _CopyPermissionsDialog extends StatefulWidget {
  final dynamic user;
  final List<dynamic> users;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Function(dynamic selectedUser) onConfirm;

  const _CopyPermissionsDialog({
    required this.user,
    required this.users,
    required this.theme,
    required this.colorScheme,
    required this.onConfirm,
  });

  @override
  State<_CopyPermissionsDialog> createState() => _CopyPermissionsDialogState();
}

class _CopyPermissionsDialogState extends State<_CopyPermissionsDialog> {
  dynamic _selectedUser;
  String _searchText = '';
  late FocusNode _focusNode;
  late TextEditingController _searchController;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchController = TextEditingController();
    // Excluir el usuario actual de la lista
    _selectedUser =
        widget.users.where((u) => u.login != widget.user.login).firstOrNull;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsers =
        widget.users.where((u) => u.login != widget.user.login).toList();

    final filteredUsers =
        allUsers.where((u) {
          final searchLower = _searchText.toLowerCase();
          return (u.nombreCompleto ?? '').toLowerCase().contains(searchLower) ||
              (u.login ?? '').toLowerCase().contains(searchLower);
        }).toList();

    // Si el usuario seleccionado no está en la lista filtrada, deseleccionar
    if (_selectedUser != null && !filteredUsers.contains(_selectedUser)) {
      _selectedUser = null;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: widget.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Copiar permisos',
                      style: widget.theme.textTheme.titleLarge?.copyWith(
                        color: widget.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Copiar permisos de:',
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.nombreCompleto ?? 'Usuario',
                    style: widget.theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown con búsqueda integrada
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _showDropdown
                                ? widget.colorScheme.primary
                                : Colors.grey.shade300,
                        width: _showDropdown ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Campo de búsqueda
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: widget.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _focusNode,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchText = value;
                                    });
                                  },
                                  onTap: () {
                                    setState(() {
                                      _showDropdown = true;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        _selectedUser != null
                                            ? '${_selectedUser.nombreCompleto ?? _selectedUser.login}'
                                            : 'Buscar usuario...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: widget.theme.textTheme.bodyMedium,
                                ),
                              ),
                              if (_searchText.isNotEmpty ||
                                  _selectedUser != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  iconSize: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchText = '';
                                      _selectedUser = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                        // Lista desplegable de usuarios
                        if (_showDropdown && filteredUsers.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = _selectedUser == user;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _searchController.text =
                                          user.nombreCompleto ?? user.login;
                                      _searchText = '';
                                      _showDropdown = false;
                                      _focusNode.unfocus();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    color:
                                        isSelected
                                            ? widget.colorScheme.primary
                                                .withOpacity(0.1)
                                            : null,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nombreCompleto ?? user.login,
                                          style: widget
                                              .theme
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                color:
                                                    isSelected
                                                        ? widget
                                                            .colorScheme
                                                            .primary
                                                        : null,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if ((user.login ?? '').isNotEmpty)
                                          Text(
                                            user.login,
                                            style: widget
                                                .theme
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else if (_showDropdown && filteredUsers.isEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Center(
                              child: Text(
                                'No se encontraron usuarios',
                                style: widget.theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Comparación de datos de ambos usuarios
            if (_selectedUser != null)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Comparación de Datos',
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tabla comparativa
                    Table(
                      columnWidths: {
                        0: const FlexColumnWidth(0.3),
                        1: const FlexColumnWidth(0.35),
                        2: const FlexColumnWidth(0.35),
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: BoxDecoration(
                            color: widget.colorScheme.primary.withOpacity(0.1),
                          ),
                          children: [
                            _buildTableCell('Campo', isBold: true),
                            _buildTableCell(
                              'De: ${widget.user.login}',
                              isBold: true,
                            ),
                            _buildTableCell(
                              'A: ${_selectedUser.login}',
                              isBold: true,
                            ),
                          ],
                        ),
                        // Nombre Completo
                        TableRow(
                          children: [
                            _buildTableCell('Nombre', isBold: true),
                            _buildTableCell(widget.user.nombreCompleto ?? '-'),
                            _buildTableCell(
                              _selectedUser.nombreCompleto ?? '-',
                            ),
                          ],
                        ),
                        // Tipo de Usuario
                        TableRow(
                          children: [
                            _buildTableCell('Tipo', isBold: true),
                            _buildTableCell(
                              widget.user.tipoUsuario == 'adm'
                                  ? 'Administrador'
                                  : 'Limitado',
                            ),
                            _buildTableCell(
                              _selectedUser.tipoUsuario == 'adm'
                                  ? 'Administrador'
                                  : 'Limitado',
                            ),
                          ],
                        ),
                        // Estado
                        TableRow(
                          children: [
                            _buildTableCell('Estado', isBold: true),
                            _buildTableCell(
                              widget.user.estado == 'D'
                                  ? 'Desbloqueado'
                                  : 'Bloqueado',
                            ),
                            _buildTableCell(
                              _selectedUser.estado == 'D'
                                  ? 'Desbloqueado'
                                  : 'Bloqueado',
                            ),
                          ],
                        ),
                        // Autorizador
                        TableRow(
                          children: [
                            _buildTableCell('Autorizador', isBold: true),
                            _buildTableCell(
                              widget.user.esAutorizador.toUpperCase() == 'SI'
                                  ? 'Sí'
                                  : 'No',
                            ),
                            _buildTableCell(
                              _selectedUser.esAutorizador.toUpperCase() == 'SI'
                                  ? 'Sí'
                                  : 'No',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los permisos del usuario "${_selectedUser.login}" se copiarán a "${widget.user.login}"',
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      'Cancelar',
                      style: widget.theme.textTheme.bodyMedium?.copyWith(
                        color: widget.colorScheme.secondary,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colorScheme.primary,
                      foregroundColor: widget.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text('Copiar Permisos'),
                    onPressed:
                        _selectedUser != null
                            ? () => widget.onConfirm(_selectedUser)
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

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: widget.theme.textTheme.bodySmall?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? widget.colorScheme.primary : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PermissionsSelectionDialog extends StatefulWidget {
  final dynamic targetUser;
  final dynamic sourceUser;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onConfirm;

  const _PermissionsSelectionDialog({
    required this.targetUser,
    required this.sourceUser,
    required this.theme,
    required this.colorScheme,
    required this.onConfirm,
  });

  @override
  State<_PermissionsSelectionDialog> createState() =>
      _PermissionsSelectionDialogState();
}

class _PermissionsSelectionDialogState
    extends State<_PermissionsSelectionDialog> {
  // Definir los módulos y vistas disponibles
  final Map<String, List<String>> modules = {
    'Gestión': ['Usuarios', 'Roles', 'Permisos'],
    'Reportes': ['Reportes Básicos', 'Reportes Avanzados', 'Exportar'],
    'Administración': ['Configuración', 'Auditoría', 'Base de Datos'],
    'Inventario': ['Productos', 'Movimientos', 'Valuación'],
  };

  late Map<String, bool> selectedPermissions;

  @override
  void initState() {
    super.initState();
    // Inicializar todos los permisos como no seleccionados
    selectedPermissions = {};
    modules.forEach((module, views) {
      views.forEach((view) {
        selectedPermissions['$module - $view'] = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Seleccionar Permisos',
        style: widget.theme.textTheme.titleLarge?.copyWith(
          color: widget.colorScheme.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona los permisos que deseas copiar:',
              style: widget.theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...modules.entries.map((entry) {
              final moduleName = entry.key;
              final views = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moduleName,
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.colorScheme.primary,
                    ),
                  ),
                  ...views.map((view) {
                    final key = '$moduleName - $view';
                    return CheckboxListTile(
                      title: Text(
                        view,
                        style: widget.theme.textTheme.bodyMedium,
                      ),
                      value: selectedPermissions[key] ?? false,
                      onChanged: (value) {
                        setState(() {
                          selectedPermissions[key] = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            'Cancelar',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              color: widget.colorScheme.secondary,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colorScheme.primary,
            foregroundColor: widget.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          label: const Text('Guardar Permisos'),
          onPressed: widget.onConfirm,
        ),
      ],
    );
  }
}

class _AssignPermissionsDialog extends StatefulWidget {
  final dynamic user;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onConfirm;

  const _AssignPermissionsDialog({
    required this.user,
    required this.theme,
    required this.colorScheme,
    required this.onConfirm,
  });

  @override
  State<_AssignPermissionsDialog> createState() =>
      _AssignPermissionsDialogState();
}

class _AssignPermissionsDialogState extends State<_AssignPermissionsDialog> {
  // Definir los módulos y vistas disponibles
  final Map<String, List<String>> modules = {
    'Gestión': ['Usuarios', 'Roles', 'Permisos'],
    'Reportes': ['Reportes Básicos', 'Reportes Avanzados', 'Exportar'],
    'Administración': ['Configuración', 'Auditoría', 'Base de Datos'],
    'Inventario': ['Productos', 'Movimientos', 'Valuación'],
  };

  late Map<String, bool> selectedPermissions;

  @override
  void initState() {
    super.initState();
    // Inicializar todos los permisos como no seleccionados
    selectedPermissions = {};
    modules.forEach((module, views) {
      views.forEach((view) {
        selectedPermissions['$module - $view'] = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.security, color: widget.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Asignar Permisos',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              color: widget.colorScheme.primary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Usuario: ${widget.user.nombreCompleto}',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona los permisos para este usuario:',
              style: widget.theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...modules.entries.map((entry) {
              final moduleName = entry.key;
              final views = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moduleName,
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.colorScheme.primary,
                    ),
                  ),
                  ...views.map((view) {
                    final key = '$moduleName - $view';
                    return CheckboxListTile(
                      title: Text(
                        view,
                        style: widget.theme.textTheme.bodyMedium,
                      ),
                      value: selectedPermissions[key] ?? false,
                      onChanged: (value) {
                        setState(() {
                          selectedPermissions[key] = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            'Cancelar',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              color: widget.colorScheme.secondary,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colorScheme.primary,
            foregroundColor: widget.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          label: const Text('Guardar Permisos'),
          onPressed: widget.onConfirm,
        ),
      ],
    );
  }
}
