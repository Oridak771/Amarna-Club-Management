import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared page layout used by every top-level and detail screen.
///
/// Gives all pages the same header rhythm (title, optional subtitle, actions),
/// the same side gutters, and a content column capped at [maxWidth] so the
/// layout stays readable on wide tablets.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.floatingActionButton,
    this.bottom,
    this.maxWidth = 1100,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 32),
    this.scrollable = false,
    this.onRefresh,
    this.bottomBar,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// When true, [body] is placed in a scroll view by the caller (e.g. a
  /// `ListView`); the page then only constrains its width.
  final bool scrollable;

  /// Pull-to-refresh handler (non-scrollable pages only).
  final Future<void> Function()? onRefresh;

  /// Sticky bar at the bottom of the screen, for the primary action of a
  /// detail page (kept within thumb reach on a tablet).
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: body,
    );
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: leading,
        toolbarHeight: subtitle == null ? 64 : 76,
        titleSpacing: 16,
        title: _PageTitle(title: title, subtitle: subtitle),
        actions: [
          for (final action in actions) ...[action, const SizedBox(width: 4)],
          const SizedBox(width: 8),
        ],
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                // heightFactor keeps the bar as tall as its button: without it
                // the Align fills the whole screen and squeezes the body.
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1.0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: bottomBar,
                  ),
                ),
              ),
            ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: scrollable
                ? Padding(padding: padding, child: body)
                : onRefresh == null
                    ? scrollView
                    : RefreshIndicator(
                        color: colors.accentPrimary,
                        onRefresh: onRefresh!,
                        child: scrollView,
                      ),
          ),
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: colors.textPrimary,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// White rounded surface with a hairline border: the basic building block of
/// every list item, form block and KPI on the app.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accentColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Optional colour stripe on the left edge (e.g. activity or priority).
  final Color? accentColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Padding(padding: padding, child: child);
    final body = accentColor == null
        ? content
        : IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: accentColor),
                Expanded(child: content),
              ],
            ),
          );

    return Material(
      color: color ?? colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: body,
        ),
      ),
    );
  }
}

/// Section heading with an optional trailing action.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.icon,
  });

  final String title;
  final int? count;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: colors.accentPrimary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                ),
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Shown when a list or query has nothing to display.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: colors.accentPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Shown while data is being fetched from Odoo.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message = 'Chargement…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.accentPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when Odoo could not be reached. Always offers a retry.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Impossible de charger les données',
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPanel(
      color: colors.danger.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: colors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coloured pill with an optional icon: statuses, priorities, counters.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large tappable KPI tile used on the home and reports screens.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
        ],
      ),
    );
  }
}
