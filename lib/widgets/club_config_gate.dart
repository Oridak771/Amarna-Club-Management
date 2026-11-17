import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/club_config_provider.dart';

/// Holds the signed-in screens until the club settings are loaded from Odoo.
///
/// Every screen after login reads its thresholds, hours and contacts from
/// [clubConfigProvider]; this gate makes sure that value exists first, so no
/// screen ever runs on a guessed setting.
class ClubConfigGate extends ConsumerWidget {
  const ClubConfigGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authProvider.select((state) => state.status));
    if (status != AuthStatus.authenticated) return child;

    final config = ref.watch(clubConfigProvider);
    return config.when(
      data: (_) => child,
      loading: () => const _ConfigMessage(
        icon: Icons.settings_outlined,
        title: 'Chargement de la configuration du club…',
        showProgress: true,
      ),
      error: (error, _) => _ConfigMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Configuration du club indisponible',
        detail: '$error',
        actionLabel: 'Réessayer',
        onAction: () => ref.invalidate(clubConfigProvider),
      ),
    );
  }
}

class _ConfigMessage extends StatelessWidget {
  const _ConfigMessage({
    required this.icon,
    required this.title,
    this.detail,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showProgress)
                    const CircularProgressIndicator()
                  else
                    Icon(icon, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      detail!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 20),
                    FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
