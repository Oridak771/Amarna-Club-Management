import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tout lire',
                style: TextStyle(
                    color: context.colors.accentPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (todayNotifs.isNotEmpty) ...[
                        _buildSectionHeader('Aujourd\'hui'),
                        ...todayNotifs.map((n) => _buildNotificationRow(n)),
                      ],
                      if (earlierNotifs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSectionHeader('Plus tôt'),
                        ...earlierNotifs.map((n) => _buildNotificationRow(n)),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: context.colors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour ! Vos alertes apparaîtront ici.',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(MockNotification notif) {
    return InkWell(
      onTap: () {
        setState(() {
          notif.isRead = true;
        });
        if (notif.routePath != null) {
          context.push(notif.routePath!);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.transparent
              : context.colors.accentPrimary.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(color: context.colors.border, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _getCategoryColor(notif.category).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(notif.category),
                color: _getCategoryColor(notif.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(
                            color: context.colors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.description,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Unread Dot
            if (!notif.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.colors.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
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
