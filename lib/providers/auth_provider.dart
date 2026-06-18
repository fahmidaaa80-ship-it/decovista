// auth_provider.dart - পুরোটা replace করো

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../data/models/user_model.dart';

// Auth State Stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

// Current User — stream থেকে নেয়, সবসময় fresh
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user)
      ?? SupabaseService.currentUser;
});

// User Profile — currentUser change হলে auto re-fetch
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
    return UserModel.fromJson(response);
  } catch (e) {
    return null;
  }
});

// User Type Provider
final userTypeProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'customer';

  try {
    final response = await Supabase.instance.client
        .from('users')
        .select('user_type')
        .eq('id', user.id)
        .maybeSingle();
    return response?['user_type']?.toString().toLowerCase() ?? 'customer';
  } catch (e) {
    return 'customer';
  }
});

// Is Admin Provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  final userType = await ref.watch(userTypeProvider.future);
  return userType == 'admin';
});

// Admin User Provider
final adminUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('users')
        .select('id, full_name, email, user_type')
        .eq('id', user.id)
        .maybeSingle();
    return response;
  } catch (e) {
    return null;
  }
});

// Auth Controller
class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.signUp(
          email: email, password: password, fullName: fullName);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.signInWithFacebook();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.signOut();
      // সব cached provider clear করো
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userTypeProvider);
      _ref.invalidate(isAdminProvider);
      _ref.invalidate(adminUserProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authControllerProvider =
StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});