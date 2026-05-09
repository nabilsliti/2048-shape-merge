import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/providers/account_sync_provider.dart';

/// Full-screen overlay shown while the post-sign-in account merge is running.
/// Blocks input so the user doesn't act on stale local values that are about
/// to be replaced by the merged Firestore values.
class AccountSyncOverlay extends ConsumerWidget {
  const AccountSyncOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(accountSyncProvider);
    if (!syncing) return const SizedBox.shrink();

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: const Center(
          child: SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
        ),
      ),
    );
  }
}
