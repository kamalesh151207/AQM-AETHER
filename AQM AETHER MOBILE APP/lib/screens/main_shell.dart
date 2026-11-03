// AQM AETHER — Main Shell with 5-Section Industrial IoT Architecture
// 1. Dashboard (Command Center)
// 2. Devices (BLE Device Discovery & Link)
// 3. Analytics (Historical Trends & Aggregation)
// 4. History (Tabular Telemetry Logs & CSV Export)
// 5. Settings (Hardware Configuration & System Controls)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../services/notifications/notification_service.dart';
import 'overview/overview_screen.dart';
import 'devices/devices_screen.dart';
import 'analytics/analytics_screen.dart';
import 'history/history_screen.dart';
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
      icon: Icons.insights_rounded,
      activeIcon: Icons.insights_rounded,
      label: 'ANALYTICS',
    ),
    _NavDestination(
      icon: Icons.history_rounded,
      activeIcon: Icons.manage_history_rounded,
      label: 'HISTORY',
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

    if (payload == 'nav:alerts' || payload == 'nav:history') {
      _onNavTap(3);
    } else if (payload == 'nav:settings') {
      _onNavTap(4);
    } else if (payload == 'nav:analytics' || payload == 'nav:live' || payload == 'nav:environment') {
      _onNavTap(2);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.backgroundPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          OverviewScreen(
            onNavigateToAnalytics: () => _onNavTap(2),
            onNavigateToHistory: () => _onNavTap(3),
            onNavigateToSettings: () => _onNavTap(4),
            onNavigateToAlerts: () => _onNavTap(3),
          ),
          const DevicesScreen(),
          const AnalyticsScreen(),
          const HistoryScreen(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: isDark ? const [] : AppShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(destinations.length, (i) {
              return Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  isSelected: currentIndex == i,
                  isDark: isDark,
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
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkPrimaryBlue : AppColors.primaryNavy;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final pillBg = isDark
        ? (isSelected ? AppColors.darkElevated : Colors.transparent)
        : (isSelected ? AppColors.mutedBackground : Colors.transparent);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(
              isSelected ? destination.activeIcon : destination.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
