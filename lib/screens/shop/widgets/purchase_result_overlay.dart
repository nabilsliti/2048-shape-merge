part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Purchase Result Overlay — shown after a successful or failed purchase.
// Follows the same visual pattern as LevelUpOverlay.
// ═══════════════════════════════════════════════════════════════

enum _PurchaseResultType { success, error }

class _PurchaseResult {
  final _PurchaseResultType type;
  final String? productId;
  final String? errorMessage;
  const _PurchaseResult({required this.type, this.productId, this.errorMessage});
}

class _PurchaseResultOverlay extends StatefulWidget {
  const _PurchaseResultOverlay({
    required this.result,
    required this.onDismiss,
  });

  final _PurchaseResult result;
  final VoidCallback onDismiss;

  @override
  State<_PurchaseResultOverlay> createState() => _PurchaseResultOverlayState();
}

class _PurchaseResultOverlayState extends State<_PurchaseResultOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSuccess = widget.result.type == _PurchaseResultType.success;
    final pack = widget.result.productId != null
        ? ShopCatalog.byId(widget.result.productId!)
        : null;

    final accentColor = isSuccess ? AppTheme.greenTop : AppTheme.redTop;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = isSuccess ? l10n.purchaseSuccess : l10n.purchaseError;

    return IgnorePointer(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: isSuccess ? AppTheme.greenBorder : AppTheme.redBorder, width: 3),
              boxShadow: const [
                BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
                BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                Icon(icon, color: accentColor, size: 48)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1, end: 1.2, duration: 700.ms, curve: Curves.easeInOut),

                const SizedBox(height: 12),

                // Title
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: AppTheme.fontH2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                // Pack content details (success only)
                if (isSuccess && pack != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    pack.emoji,
                    style: const TextStyle(fontSize: AppTheme.fontXXL),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  const SizedBox(height: 8),
                  _buildRewardList(pack)
                      .animate().fadeIn(duration: 300.ms, delay: 400.ms),
                ],

                // Error message (error only)
                if (!isSuccess && widget.result.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.result.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: AppTheme.fontSmall,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                ],
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),
        ),
      ),
    );
  }

  Widget _buildRewardList(ShopPack pack) {
    Widget item(Widget icon, int count, Color color) {
      if (count <= 0) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text(
            AppLocalizations.of(context)!.rewardPlusN(count),
            style: GoogleFonts.fredoka(
              fontSize: AppTheme.fontBody,
              fontWeight: FontWeight.w700,
              color: AppTheme.gold,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        item(JokerUI.icon(JokerType.bomb, size: 22), pack.freeJokers, JokerUI.color(JokerType.bomb)),
        item(JokerUI.icon(JokerType.wildcard, size: 22), pack.freeJokers, JokerUI.color(JokerType.wildcard)),
        item(JokerUI.icon(JokerType.reducer, size: 20), pack.freeJokers, JokerUI.color(JokerType.reducer)),
        if (pack.radar > 0) item(JokerUI.icon(JokerType.radar, size: 20), pack.radar, JokerUI.color(JokerType.radar)),
        if (pack.evolution > 0) item(JokerUI.icon(JokerType.evolution, size: 20), pack.evolution, JokerUI.color(JokerType.evolution)),
        if (pack.megaBomb > 0) item(JokerUI.icon(JokerType.megaBomb, size: 20), pack.megaBomb, JokerUI.color(JokerType.megaBomb)),
      ],
    );
  }
}
