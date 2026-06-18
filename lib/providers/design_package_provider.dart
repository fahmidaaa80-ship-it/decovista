import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/design_package_model.dart';

// Featured Design Packages Provider
final featuredPackagesProvider = FutureProvider<List<DesignPackage>>((ref) async {
  try {
    final response = await SupabaseService.getDesignPackages(isFeatured: true);
    return response.map((json) => DesignPackage.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// All Design Packages Provider
final allPackagesProvider = FutureProvider<List<DesignPackage>>((ref) async {
  try {
    final response = await SupabaseService.getDesignPackages();
    return response.map((json) => DesignPackage.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// Package by ID Provider
final packageByIdProvider = FutureProvider.family<DesignPackage?, String>((ref, packageId) async {
  try {
    final response = await SupabaseService.getPackageById(packageId);
    return DesignPackage.fromJson(response);
  } catch (e) {
    return null;
  }
});

// Packages by Room Type Provider
final packagesByRoomTypeProvider = FutureProvider.family<List<DesignPackage>, String>((ref, roomType) async {
  try {
    final response = await SupabaseService.getDesignPackages(roomType: roomType);
    return response.map((json) => DesignPackage.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});