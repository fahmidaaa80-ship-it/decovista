import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/loading_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(adminUsersNotifierProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Customers', 'customer'),
                const SizedBox(width: 8),
                _buildFilterChip('Designers', 'designer'),
                const SizedBox(width: 8),
                _buildFilterChip('Admins', 'admin'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                var filteredUsers = users.where((user) {
                  final matchesSearch = user['full_name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery) ||
                      user['email']
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery);

                  final matchesFilter = _filterType == 'all' ||
                      user['user_type'] == _filterType;

                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _UserCard(user: filteredUsers[index]);
                  },
                );
              },
              loading: () => const LoadingWidget(message: 'Loading users...'),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      backgroundColor: AppColors.greyLight,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final Map<String, dynamic> user;

  const _UserCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getUserTypeColor(user['user_type']).withOpacity(0.2),
                backgroundImage: user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
                child: user['avatar_url'] == null
                    ? Text(
                  user['full_name']
                      ?.substring(0, 1)
                      .toUpperCase() ??
                      'U',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getUserTypeColor(user['user_type']),
                  ),
                )
                    : null,
              ),

              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['full_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _RoleBadge(
                          label: user['user_type'] ?? 'customer',
                          color: _getUserTypeColor(user['user_type']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          user['is_active'] == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 14,
                          color: user['is_active'] == true
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user['is_active'] == true ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: user['is_active'] == true
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          user['created_at'] != null
                              ? DateTime.parse(user['created_at'].toString()).toLocal().toString().split(' ')[0]
                              : '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20, color: AppColors.info),
                        SizedBox(width: 12),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Edit Role'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          user['is_active'] == true
                              ? Icons.block
                              : Icons.check_circle_outline,
                          size: 20,
                          color: user['is_active'] == true
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          user['is_active'] == true
                              ? 'Block User'
                              : 'Activate User',
                          style: TextStyle(
                            color: user['is_active'] == true
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showUserDetailsDialog(context, user);
                      break;

                    case 'edit':
                      _showEditRoleDialog(
                        context,
                        user,
                        ref,
                      );
                      break;

                    case 'block':
                      _showBlockDialog(
                        context,
                        user,
                        ref,
                      );
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUserTypeColor(String? userType) {
    switch (userType) {
      case 'admin':
        return AppColors.error;
      case 'designer':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  void _showUserDetailsDialog(BuildContext context, Map<String, dynamic> user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getUserTypeColor(user['user_type']).withOpacity(0.2),
                backgroundImage: user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
                child: user['avatar_url'] == null
                    ? Text(
                  (user['full_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getUserTypeColor(user['user_type']),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(user['full_name'] ?? 'User Details'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Full Name', user['full_name'] ?? 'N/A'),
                _detailRow('Email', user['email'] ?? 'N/A'),
                _detailRow('Phone', user['phone'] ?? 'N/A'),
                const Divider(),
                _detailRow('User Type', user['user_type'] ?? 'customer'),
                _detailRow('Status', user['is_active'] == true ? 'Active' : 'Inactive'),
                _detailRow('Joined', user['created_at'] != null
                    ? DateTime.parse(user['created_at']).toLocal().toString().split('.')[0]
                    : 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(
      BuildContext context,
      Map<String, dynamic> user,
      WidgetRef ref,
      ) {
    String selectedRole =
        user['user_type'] ?? 'customer';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 24, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Edit User Role'),
            ],
          ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'customer',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  title: const Text('Customer'),
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  value: 'designer',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  title: const Text('Designer'),
                  activeColor: AppColors.info,
                ),
                RadioListTile<String>(
                  value: 'admin',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  title: const Text('Admin'),
                  activeColor: AppColors.error,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await SupabaseService.updateUserRole(
                  userId: user['id'],
                  role: selectedRole,
                );

                ref.invalidate(adminUsersNotifierProvider);

                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'User role updated successfully',
                      ),
                      backgroundColor:
                      AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    SnackBar(
                      content:
                      Text('Error: $e'),
                      backgroundColor:
                      AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
      );
    });
  }

  void _showBlockDialog(
      BuildContext context,
      Map<String, dynamic> user,
      WidgetRef ref,
      ) {
    final isActive =
        user['is_active'] == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isActive ? Icons.block : Icons.check_circle_outline,
              size: 24,
              color: isActive ? AppColors.error : AppColors.success,
            ),
            const SizedBox(width: 12),
            Text(
              isActive
                  ? 'Block User'
                  : 'Activate User',
            ),
          ],
        ),
        content: Text(
          isActive
              ? 'Are you sure you want to block this user? They will not be able to access the platform.'
              : 'Are you sure you want to activate this user?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive
                  ? AppColors.error
                  : AppColors.success,
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await SupabaseService
                    .toggleUserStatus(
                  userId: user['id'],
                  isActive: !isActive,
                );

                ref.invalidate(
                  adminUsersProvider,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        isActive
                            ? 'User blocked successfully'
                            : 'User activated successfully',
                      ),
                      backgroundColor:
                      AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content:
                      Text('Error: $e'),
                      backgroundColor:
                      AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              isActive
                  ? 'Block'
                  : 'Activate',
            ),
          ),
        ],
      ),
      );
    });
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
