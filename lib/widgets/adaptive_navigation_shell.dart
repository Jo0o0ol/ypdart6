import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/roles.dart';
import '../core/services.dart';
import 'responsive.dart';

class AdaptiveNavigationShell extends StatelessWidget {
  const AdaptiveNavigationShell({
    super.key,
    required this.services,
    required this.currentLocation,
    required this.child,
  });

  final AppServices services;
  final String currentLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final selected = _selectedIndex(items);
    final widthClass = widthClassFor(MediaQuery.sizeOf(context).width);

    if (widthClass == AppWidthClass.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => context.go(items[index].route),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
                tooltip: item.label,
              ),
          ],
        ),
      );
    }

    final extended = widthClass == AppWidthClass.wide ||
        widthClass == AppWidthClass.ultraWide;

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              selectedIndex: selected,
              extended: extended,
              minExtendedWidth: 190,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              onDestinationSelected: (index) => context.go(items[index].route),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: item.label,
                      child: Icon(item.icon),
                    ),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  List<_NavigationItem> _items() {
    final role = services.auth.uiRole;
    final items = <_NavigationItem>[
      const _NavigationItem(
        label: 'Главная',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        route: '/',
      ),
      const _NavigationItem(
        label: 'Каталог',
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        route: '/books',
      ),
    ];

    if (role == AppRole.reader) {
      items.add(
        const _NavigationItem(
          label: 'Мои выдачи',
          icon: Icons.account_circle_outlined,
          selectedIcon: Icons.account_circle,
          route: '/reader',
        ),
      );
    } else if (role == AppRole.librarian) {
      items.add(
        const _NavigationItem(
          label: 'Рабочее место',
          icon: Icons.local_library_outlined,
          selectedIcon: Icons.local_library,
          route: '/librarian',
        ),
      );
    } else if (role == AppRole.admin) {
      items.add(
        const _NavigationItem(
          label: 'Администратор',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          route: '/admin',
        ),
      );
    }

    items.add(
      const _NavigationItem(
        label: 'Защита',
        icon: Icons.security_outlined,
        selectedIcon: Icons.security,
        route: '/security-demo',
      ),
    );

    return items;
  }

  int _selectedIndex(List<_NavigationItem> items) {
    for (var i = 0; i < items.length; i++) {
      final route = items[i].route;
      if (route == '/') {
        if (currentLocation == '/') return i;
      } else if (currentLocation == route || currentLocation.startsWith('$route/')) {
        return i;
      }
    }
    // Вспомогательные рабочие страницы (/authors, /genres и т.п.)
    // не должны ломать NavigationBar/NavigationRail.
    return 0;
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
