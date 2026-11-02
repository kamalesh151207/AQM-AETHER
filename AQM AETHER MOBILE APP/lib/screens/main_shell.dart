// AQM AETHER — Main Shell with 6-Section Modern Industrial Navigation
// 1. Dashboard  2. Devices  3. Environment  4. Motion  5. Alerts  6. Settings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../services/notifications/notification_service.dart';
import 'overview/overview_screen.dart';
import 'devices/devices_screen.dart';
import 'environment/environment_screen.dart';
import 'motion/motion_screen.dart';
import 'alerts/alerts_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<_NavDestination> _destinations = const [
    _NavDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'DASHBOARD',
    ),
    _NavDestination(
      icon: Icons.bluetooth_searching_rounded,
      activeIcon: Icons.bluetooth_connected_rounded,
      label: 'DEVICES',
    ),
    _NavDestination(
      icon: Icons.eco_outlined,
      activeIcon: Icons.eco_rounded,
      label: 'ENVIRONMENT',
    ),
    _NavDestination(
      icon: Icons.screen_rotation_outlined,
      activeIcon: Icons.screen_rotation_rounded,
      label: 'MOTION',
    ),
    _NavDestination(
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_active_rounded,
      label: 'ALERTS',
    ),
    _NavDestination(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'SETTINGS',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
    NotificationService().navigationPayloadNotifier.addListener(_handleNotificationNavigation);
  }

  @override
  void dispose() {
    NotificationService().navigationPayloadNotifier.removeListener(_handleNotificationNavigation);
    _pageController.dispose();
    super.dispose();
  }

  void _handleNotificationNavigation() {
    final payload = NotificationService().navigationPayloadNotifier.value;
    if (payload == null) return;
    NotificationService().navigationPayloadNotifier.value = null;

    if (payload == 'nav:alerts') {
      _onNavTap(4);
    } else if (payload == 'nav:settings') {
      _onNavTap(5);
    } else if (payload == 'nav:live' || payload == 'nav:environment') {
      _onNavTap(2);
    } else if (payload == 'nav:motion') {
      _onNavTap(3);
    } else if (payload == 'nav:devices') {
      _onNavTap(1);
    } else if (payload == 'nav:overview' || payload == 'nav:dashboard') {
      _onNavTap(0);
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          OverviewScreen(
            onNavigateToLive: () => _onNavTap(2),
            onNavigateToSettings: () => _onNavTap(5),
            onNavigateToAlerts: () => _onNavTap(4),
          ),
          const DevicesScreen(),
          const EnvironmentScreen(),
          const MotionScreen(),
          const AlertsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _AqmBottomNavBar(
        currentIndex: _currentIndex,
        destinations: _destinations,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── Custom Bottom Nav Bar ─────────────────────────────────────────────────────

class _AqmBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onTap;

  const _AqmBottomNavBar({
    required this.currentIndex,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(destinations.length, (i) {
              return Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  isSelected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.textPrimary;
    const inactiveColor = AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentSecondaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(
              isSelected ? destination.activeIcon : destination.icon,
              color: isSelected ? AppColors.accentSecondary : inactiveColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
