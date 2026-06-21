import 'package:amarna_club/ui/activity_ui_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/providers/activities_provider.dart';
import 'package:amarna_club/theme/app_theme.dart';

class ActivitiesGridScreen extends ConsumerStatefulWidget {
  ActivitiesGridScreen({super.key});

  @override
  ConsumerState<ActivitiesGridScreen> createState() =>
      _ActivitiesGridScreenState();
}

class _ActivitiesGridScreenState extends ConsumerState<ActivitiesGridScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allActivities = ref.watch(activitiesProvider);

    final filtered = allActivities.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == null || a.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    final openCount =
        allActivities.where((a) => a.status == ActivityStatus.open).length;
    final warningCount =
        allActivities.where((a) => a.status == ActivityStatus.warning).length;
    final closedCount =
        allActivities.where((a) => a.status == ActivityStatus.closed).length;

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final isDesktop = constraints.maxWidth >= 960;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top App Bar ──────────────────────────────────────
                _buildTopBar(context, isTablet),

                // ── Search + Filter ──────────────────────────────────
                _buildSearchRow(context),

                // ── Status Summary Chips ─────────────────────────────
                _buildStatusChips(
                  openCount: openCount,
                  warningCount: warningCount,
                  closedCount: closedCount,
                  total: allActivities.length,
                  filtered: filtered.length,
                ),

                SizedBox(height: 6),

                // ── Activity Grid / List ─────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildGrid(filtered, isTablet, isDesktop),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, bool isTablet) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isTablet ? 24 : 16, 16, isTablet ? 16 : 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activites',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gestion en temps reel',
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 13,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          _ActionIconButton(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: 'Scanner QR/NFC',
            onTap: () => context.push('/scan'),
          ),
          SizedBox(width: 6),
          _ActionIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  // ── Search + Filter row ────────────────────────────────────────────────────
  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher une activite…',
          hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: context.colors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.colors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: context.colors.backgroundSecondary,
          contentPadding:
              EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: context.colors.accentPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Status summary chips ───────────────────────────────────────────────────
  Widget _buildStatusChips({
    required int openCount,
    required int warningCount,
    required int closedCount,
    required int total,
    required int filtered,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Toutes',
            count: total,
            color: context.colors.accentPrimary,
            icon: Icons.grid_view_rounded,
            isSelected: _filterStatus == null,
            onTap: () => setState(() => _filterStatus = null),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Ouvertes',
            count: openCount,
            color: context.colors.success,
            icon: Icons.check_circle_outline_rounded,
            isSelected: _filterStatus == ActivityStatus.open,
            onTap: () => setState(() => _filterStatus =
                _filterStatus == ActivityStatus.open
                    ? null
                    : ActivityStatus.open),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Alerte',
            count: warningCount,
            color: context.colors.warning,
            icon: Icons.warning_amber_rounded,
            isSelected: _filterStatus == ActivityStatus.warning,
            onTap: () => setState(() => _filterStatus =
                _filterStatus == ActivityStatus.warning
                    ? null
                    : ActivityStatus.warning),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Fermees',
            count: closedCount,
            color: context.colors.danger,
            icon: Icons.lock_outline_rounded,
            isSelected: _filterStatus == ActivityStatus.closed,
            onTap: () => setState(() => _filterStatus =
                _filterStatus == ActivityStatus.closed
                    ? null
                    : ActivityStatus.closed),
          ),
        ],
      ),
    );
  }

  // ── Responsive Grid ────────────────────────────────────────────────────────
  Widget _buildGrid(List<Activity> activities, bool isTablet, bool isDesktop) {
    final crossAxisCount = isDesktop
        ? 4
        : isTablet
            ? 3
            : 2;
    final hPad = isDesktop
        ? 24.0
        : isTablet
            ? 20.0
            : 16.0;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
      itemCount: activities.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isTablet ? 14 : 12,
        mainAxisSpacing: isTablet ? 14 : 12,
        childAspectRatio: isDesktop
            ? 0.88
            : isTablet
                ? 0.84
                : 0.78,
      ),
      itemBuilder: (context, index) {
        return ActivityCard(
          activity: activities[index],
          onTap: () => context.push('/activites/${activities[index].id}'),
        );
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.border),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40,
              color: context.colors.textMuted,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Aucune activite trouvée',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(color: context.colors.textMuted, fontSize: 13),
          ),
          SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _filterStatus = null;
              });
            },
            icon: Icon(Icons.refresh_rounded),
            label: Text('Reinitialiser'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTIVITY CARD — Premium Design
// ══════════════════════════════════════════════════════════════════════════════

class ActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback? onTap;

  ActivityCard({super.key, required this.activity, this.onTap});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final color = resolveActivityColor(context, activity.id);
    final isClosed = activity.status == ActivityStatus.closed;
    final isMaintenance = activity.status == ActivityStatus.maintenance;
    final isUnavailable = isClosed || isMaintenance;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: context.colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnavailable
                        ? context.colors.border
                        : (_isHovered
                            ? color.withValues(alpha: 0.6)
                            : color.withValues(alpha: 0.25)),
                    width: isUnavailable ? 1 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUnavailable
                          ? Colors.transparent
                          : color.withValues(alpha: _isHovered ? 0.18 : 0.06),
                      blurRadius: _isHovered ? 20 : 10,
                      spreadRadius: _isHovered ? 1 : 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Background hero gradient ─────────────────────────
                Positioned(
                  top: -10,
                  right: -10,
                  child: Opacity(
                    opacity: isUnavailable ? 0.04 : 0.07,
                    child: Icon(
                      resolveActivityIcon(activity.iconKey),
                      size: 100,
                      color: color,
                    ),
                  ),
                ),

                // ── Top color accent strip ────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnavailable
                            ? [context.colors.border, context.colors.border]
                            : [
                                color.withValues(alpha: 0.0),
                                color.withValues(alpha: 0.8),
                                color.withValues(alpha: 0.0),
                              ],
                      ),
                    ),
                  ),
                ),

                // ── Main content ─────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 18, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + Status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Activity icon in a glowing container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isUnavailable
                                    ? [
                                        context.colors.surface,
                                        context.colors.backgroundElevated,
                                      ]
                                    : [
                                        color.withValues(alpha: 0.25),
                                        color.withValues(alpha: 0.10),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isUnavailable
                                    ? context.colors.border
                                    : color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              resolveActivityIcon(activity.iconKey),
                              color:
                                  isUnavailable ? context.colors.textMuted : color,
                              size: 24,
                            ),
                          ),

                          // Status badge pill
                          _StatusPill(status: activity.status),
                        ],
                      ),

                      Spacer(),

                      // Activity name
                      Text(
                        activity.name,
                        style: TextStyle(
                          color: isUnavailable
                              ? context.colors.textSecondary
                              : context.colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4),

                      // Staff line
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: context.colors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.assignedStaff,
                              style: TextStyle(
                                color: context.colors.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Occupancy section
                      if (!isUnavailable) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Occupation',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${activity.currentOccupancy} / ${activity.maxCapacity}',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        _AnimatedProgressBar(
                          value: activity.occupancyPercentage,
                          color: color,
                        ),
                        SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(activity.occupancyPercentage * 100).toInt()}%',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              isMaintenance
                                  ? Icons.build_circle_outlined
                                  : Icons.lock_rounded,
                              size: 12,
                              color: context.colors.textMuted,
                            ),
                            SizedBox(width: 5),
                            Text(
                              isMaintenance ? 'En maintenance' : 'Acces ferme',
                              style: TextStyle(
                                color: context.colors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          child: LinearProgressIndicator(
                            value: 0,
                            minHeight: 4,
                            backgroundColor: context.colors.surface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUPPORTING WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

/// Animated progress bar that fills smoothly when first rendered.
class _AnimatedProgressBar extends StatefulWidget {
  final double value;
  final Color color;

  _AnimatedProgressBar({required this.value, required this.color});

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = widget.value > 0.85;
    final barColor = isWarning ? context.colors.warning : widget.color;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _anim.value,
            minHeight: 5,
            backgroundColor: context.colors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        );
      },
    );
  }
}

/// Compact pill badge showing activity status.
class _StatusPill extends StatelessWidget {
  final ActivityStatus status;

  _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ActivityStatus.open => ('Ouvert', context.colors.success, Icons.circle),
      ActivityStatus.warning => (
          'Alerte',
          context.colors.warning,
          Icons.warning_rounded
        ),
      ActivityStatus.closed => ('Fermé', context.colors.danger, Icons.lock_rounded),
      ActivityStatus.maintenance => (
          'Maintenance',
          context.colors.info,
          Icons.build_rounded
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 7, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated filter chip with icon + count.
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : context.colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? color : context.colors.textMuted,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : context.colors.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? color : context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular icon button for the top bar actions.
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: Icon(icon, color: context.colors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
