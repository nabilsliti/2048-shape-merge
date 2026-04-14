part of '../shop_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Joker choice button (for dialog)
// ═══════════════════════════════════════════════════════════════
// ── Joker choice panel (stateful — tracks selection, validates on button) ──
class _JokerChoicePanel extends StatefulWidget {
  @override
  State<_JokerChoicePanel> createState() => _JokerChoicePanelState();
}

class _JokerChoicePanelState extends State<_JokerChoicePanel> {
  JokerType? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.panelBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 8)),
          BoxShadow(color: Colors.black54, offset: Offset(0, 12), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gift icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.profileGradTop, AppTheme.profileGradBot],
              ),
              border: Border.all(color: AppTheme.gold, width: 3),
              boxShadow: [
                BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.chooseJoker.toUpperCase(), style: AppTheme.titleStyle(AppTheme.fontBody)),
          ),
          const SizedBox(height: 20),

          // Joker choices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _JokerChoiceButton(
                icon: JokerUI.icon(JokerType.bomb, size: 36),
                color: JokerUI.color(JokerType.bomb),
                label: JokerUI.localizedLabel(JokerType.bomb, l10n),
                selected: _selected == JokerType.bomb,
                onTap: () => setState(() => _selected = JokerType.bomb),
              ),
              _JokerChoiceButton(
                icon: JokerUI.icon(JokerType.wildcard, size: 36),
                color: JokerUI.color(JokerType.wildcard),
                label: JokerUI.localizedLabel(JokerType.wildcard, l10n),
                selected: _selected == JokerType.wildcard,
                onTap: () => setState(() => _selected = JokerType.wildcard),
              ),
              _JokerChoiceButton(
                icon: JokerUI.icon(JokerType.reducer, size: 30),
                color: JokerUI.color(JokerType.reducer),
                label: JokerUI.localizedLabel(JokerType.reducer, l10n),
                selected: _selected == JokerType.reducer,
                onTap: () => setState(() => _selected = JokerType.reducer),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Validate button — only pops with selection
          SizedBox(
            width: double.infinity,
            child: Button3D.green(
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(l10n.validateButton, style: AppTheme.titleStyle(AppTheme.fontBody)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single joker choice tile (visual only, no pop) ──
class _JokerChoiceButton extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _JokerChoiceButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.2) : AppTheme.panelBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: color, width: selected ? 3 : 1.5),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: selected ? 0.6 : 0.3), blurRadius: selected ? 20 : 10),
                        const BoxShadow(color: AppTheme.shadowDeep, offset: Offset(0, 3)),
                      ],
                    ),
                    child: icon,
                  ),
                  if (selected)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.titleStyle(AppTheme.fontSmall).copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
