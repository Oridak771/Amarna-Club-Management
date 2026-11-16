import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  // Notifications are not connected to a source yet: the list stays empty
  // until a real feed exists (no invented items are shown).
  final List<MockNotification> _notifications = [];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Toutes les notifications ont été marquées comme lues.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayNotifs = _notifications.where((n) => n.isToday).toList();
    final earlierNotifs = _notifications.where((n) => !n.isToday).toList();
    final unread = _notifications.where((n) => !n.isRead).length;

    return AppPage(
      title: 'Notifications',
      subtitle: unread > 0 ? '$unread non lue${unread > 1 ? 's' : ''}' : null,
      leading: IconButton(
        tooltip: 'Retour',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (_notifications.any((n) => !n.isRead))
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _markAllAsRead,
            child: Text(
              'Tout lire',
              style: TextStyle(
                  color: context.colors.accentPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ),
      ],
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (todayNotifs.isNotEmpty) ...[
                  const SectionTitle(title: 'Aujourd\'hui'),
                  for (final n in todayNotifs) ...[
                    _buildNotificationRow(n),
                    const SizedBox(height: 10),
                  ],
                ],
                if (earlierNotifs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const SectionTitle(title: 'Plus tôt'),
                  for (final n in earlierNotifs) ...[
                    _buildNotificationRow(n),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'Aucune notification',
      message: 'Vous êtes à jour ! Vos alertes apparaîtront ici.',
    );
  }

  Widget _buildNotificationRow(MockNotification notif) {
    final colors = context.colors;
    final categoryColor = _getCategoryColor(notif.category);
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      color: notif.isRead
          ? null
          : colors.accentPrimary.withValues(alpha: 0.04),
      onTap: () {
        setState(() {
          notif.isRead = true;
        });
        if (notif.routePath != null) {
          context.push(notif.routePath!);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(notif.category),
              color: categoryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight:
                              notif.isRead ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notif.timeAgo,
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.description,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Unread dot
          if (!notif.isRead)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'incident':
        return Icons.warning_amber_rounded;
      case 'maintenance':
        return Icons.build_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'reservation':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'incident':
        return context.colors.danger;
      case 'maintenance':
        return context.colors.info;
      case 'inventory':
        return context.colors.warning;
      case 'reservation':
        return context.colors.accentSecondary;
      default:
        return context.colors.accentPrimary;
    }
  }
}

class MockNotification {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final String category;
  final String? routePath;
  final bool isToday;
  bool isRead;

  MockNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.category,
    this.routePath,
    required this.isToday,
    required this.isRead,
  });
}
