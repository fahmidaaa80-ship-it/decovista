import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/completed_project_model.dart';
import '../../../providers/completed_project_provider.dart';

class AdminCompletedProjectsScreen extends ConsumerWidget {
  const AdminCompletedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(adminCompletedProjectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Completed Projects'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(adminCompletedProjectsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction_outlined, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text('No projects found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              return _ProjectCard(
                project: project,
                onEdit: () => _showFormDialog(context, ref, project),
                onDelete: () => _confirmDelete(context, ref, project),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading projects...'),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, CompletedProjectModel? existing) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');
    final beforeImageController = TextEditingController(text: existing?.beforeImage ?? '');
    final afterImageController = TextEditingController(text: existing?.afterImage ?? '');
    int sortOrder = existing?.sortOrder ?? 0;
    bool saving = false;
    final isEditing = existing != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(isEditing ? 'Edit Project' : 'Add Project'),
            content: saving
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (existing != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 120,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: existing.beforeImage,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          color: AppColors.greyLight,
                                          child: const Icon(Icons.broken_image, size: 32),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: existing.afterImage,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          color: AppColors.greyLight,
                                          child: const Icon(Icons.broken_image, size: 32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(labelText: 'Project Title'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: categoryController,
                            decoration: const InputDecoration(labelText: 'Category (e.g. Bedroom)'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: beforeImageController,
                            decoration: const InputDecoration(
                              labelText: 'Before Image URL',
                              hintText: 'https://...',
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: afterImageController,
                            decoration: const InputDecoration(
                              labelText: 'After Image URL',
                              hintText: 'https://...',
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              hintText: 'Lower = appears first',
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: sortOrder.toString(),
                            onChanged: (v) => sortOrder = int.tryParse(v) ?? 0,
                          ),
                        ],
                      ),
                    ),
                  ),
            actions: saving
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    CustomButton(
                      text: isEditing ? 'Save' : 'Add',
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          final data = {
                            'title': titleController.text.trim(),
                            'category': categoryController.text.trim(),
                            'before_image': beforeImageController.text.trim(),
                            'after_image': afterImageController.text.trim(),
                            'sort_order': sortOrder,
                            'is_active': true,
                          };
                          if (isEditing) {
                            await ref.read(adminCompletedProjectsNotifierProvider.notifier)
                                .updateProject(existing!.id, data);
                          } else {
                            await ref.read(adminCompletedProjectsNotifierProvider.notifier)
                                .addProject(data);
                          }
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                        } catch (e) {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
          ),
        ),
      );
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CompletedProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Delete "${project.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminCompletedProjectsNotifierProvider.notifier)
                    .deleteProject(project.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final CompletedProjectModel project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onEdit,
    required this.onDelete,
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: project.beforeImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.greyLight,
                            child: const Icon(Icons.broken_image, size: 16),
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        color: AppColors.success,
                      ),
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: project.afterImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.greyLight,
                            child: const Icon(Icons.broken_image, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        project.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
