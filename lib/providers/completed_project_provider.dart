import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/completed_project_model.dart';

final completedProjectsProvider = FutureProvider<List<CompletedProjectModel>>((ref) async {
  try {
    final response = await SupabaseService.getCompletedProjects(activeOnly: true);
    final projects = <CompletedProjectModel>[];
    for (final json in response) {
      try {
        projects.add(CompletedProjectModel.fromJson(json));
      } catch (e) {
        debugPrint('Skipping bad completed project row: $e');
      }
    }
    return projects;
  } catch (e) {
    debugPrint('completedProjectsProvider error: $e');
    return [];
  }
});

class AdminCompletedProjectsNotifier extends AsyncNotifier<List<CompletedProjectModel>> {
  @override
  Future<List<CompletedProjectModel>> build() async {
    try {
      final response = await SupabaseService.getCompletedProjects();
      final projects = <CompletedProjectModel>[];
      for (final json in response) {
        try {
          projects.add(CompletedProjectModel.fromJson(json));
        } catch (e) {
          debugPrint('Skipping bad completed project row: $e');
        }
      }
      return projects;
    } catch (e) {
      debugPrint('AdminCompletedProjectsNotifier.build error: $e');
      return [];
    }
  }

  Future<void> addProject(Map<String, dynamic> data) async {
    await SupabaseService.addCompletedProject(data);
    ref.invalidateSelf();
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    await SupabaseService.updateCompletedProject(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteProject(String id) async {
    await SupabaseService.deleteCompletedProject(id);
    state = AsyncData(state.value?.where((p) => p.id != id).toList() ?? []);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final adminCompletedProjectsNotifierProvider =
    AsyncNotifierProvider<AdminCompletedProjectsNotifier, List<CompletedProjectModel>>(
  AdminCompletedProjectsNotifier.new,
);
