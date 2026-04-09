import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/services/local_storage_service.dart';

final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  return LocalStorageService.create();
});
