import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/theme/app_theme.dart';
import 'package:shape_merge/core/widgets/glass_card.dart';
import 'package:shape_merge/core/widgets/gradient_button.dart';
import 'package:shape_merge/l10n/generated/app_localizations.dart';
import 'package:shape_merge/providers/game_state_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventory = ref.watch(gameStateProvider).jokerInventory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.shop, style: AppTheme.titleStyle),
        leading: const BackButton(color: AppTheme.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current inventory
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _JokerStock(icon: '💣', count: inventory.bomb),
                  _JokerStock(icon: '🌀', count: inventory.wildcard),
                  _JokerStock(icon: '⬇️', count: inventory.reducer),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Packs
            _PackCard(
              title: l10n.packSmall,
              description: '5 × 💣 + 5 × 🌀 + 5 × ⬇️',
              price: '1,99 €',
              color: AppTheme.green,
              onBuy: () {
                // TODO: IAP integration
              },
            ),
            const SizedBox(height: 12),
            _PackCard(
              title: l10n.packMedium,
              description: '15 × 💣 + 15 × 🌀 + 15 × ⬇️',
              price: '4,99 €',
              color: AppTheme.blue,
              onBuy: () {},
            ),
            const SizedBox(height: 12),
            _PackCard(
              title: l10n.packLarge,
              description: '40 × 💣 + 40 × 🌀 + 40 × ⬇️',
              price: '9,99 €',
              color: AppTheme.purple,
              onBuy: () {},
            ),
            const SizedBox(height: 24),
            // Watch ad
            GlassCard(
              child: Column(
                children: [
                  Text(
                    l10n.watchAdReward,
                    style: TextStyle(color: AppTheme.muted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: '📺 ${l10n.watchAd}',
                    onPressed: () {
                      _showJokerChoiceDialog(context, ref);
                    },
                    colors: [AppTheme.gold, const Color(0xFFFF8F00)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJokerChoiceDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: Text(l10n.chooseJoker, style: TextStyle(color: AppTheme.text)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _JokerChoiceButton(
              icon: '💣',
              onTap: () {
                ref
                    .read(gameStateProvider.notifier)
                    .addJokers(JokerType.bomb);
                Navigator.of(ctx).pop();
              },
            ),
            _JokerChoiceButton(
              icon: '🌀',
              onTap: () {
                ref
                    .read(gameStateProvider.notifier)
                    .addJokers(JokerType.wildcard);
                Navigator.of(ctx).pop();
              },
            ),
            _JokerChoiceButton(
              icon: '⬇️',
              onTap: () {
                ref
                    .read(gameStateProvider.notifier)
                    .addJokers(JokerType.reducer);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JokerStock extends StatelessWidget {
  final String icon;
  final int count;

  const _JokerStock({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          '×$count',
          style: const TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PackCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final Color color;
  final VoidCallback onBuy;

  const _PackCard({
    required this.title,
    required this.description,
    required this.price,
    required this.color,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: price,
              onPressed: onBuy,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerChoiceButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _JokerChoiceButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(icon, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}
