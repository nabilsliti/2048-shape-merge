import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/providers/connectivity_provider.dart';

/// Small animated wifi-off icon shown when offline.
/// Must be placed inside a [Stack].
class OfflineIndicator extends ConsumerStatefulWidget {
  /// If true, positions itself in the top-right safe area (for use in AdShell).
  /// If false, caller must wrap it in a [Positioned].
  final bool autoPosition;

  const OfflineIndicator({super.key, this.autoPosition = true});

  @override
  ConsumerState<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends ConsumerState<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool? _wasOffline;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final isOffline = !isOnline;

    // Trigger animation on transition to offline (or on first build if already offline)
    if (isOffline && _wasOffline != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctrl.forward(from: 0);
      });
    } else if (!isOffline && _wasOffline == true) {
      _ctrl.reverse();
    }
    _wasOffline = isOffline;

    if (isOnline && !_ctrl.isAnimating) return const SizedBox.shrink();

    final icon = FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.red.shade700.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.wifi_off, color: Colors.white, size: 14),
        ),
      ),
    );

    if (!widget.autoPosition) return icon;

    final topPadding = MediaQuery.of(context).viewPadding.top;
    return Positioned(
      top: topPadding + 4,
      right: 8,
      child: IgnorePointer(child: icon),
    );
  }
}
