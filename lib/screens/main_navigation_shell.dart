import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/offline_banner.dart';

class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  MainNavigationShell({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? ValueKey<String>('MainNavigationShell'));

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _onTap(context, index),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Activites',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Tickets',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: 'Plus',
            ),
          ],
        ),
      ),
    );
  }
}
