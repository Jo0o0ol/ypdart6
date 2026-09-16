import 'package:flutter/material.dart';

import '../core/roles.dart';

enum AppWidthClass { compact, medium, wide, ultraWide }

AppWidthClass widthClassFor(double width) {
  if (width < 600) return AppWidthClass.compact;
  if (width < 1100) return AppWidthClass.medium;
  if (width < 1600) return AppWidthClass.wide;
  return AppWidthClass.ultraWide;
}

class ResponsiveEntityLayout extends StatelessWidget {
  const ResponsiveEntityLayout({
    super.key,
    required this.cards,
    required this.table,
    this.tableBreakpoint = 1000,
  });

  final Widget cards;
  final Widget table;
  final double tableBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= tableBreakpoint ? table : cards;
      },
    );
  }
}

class RoleVisibility extends StatelessWidget {
  const RoleVisibility({
    super.key,
    required this.currentRole,
    required this.requiredRole,
    required this.child,
    this.replacement = const SizedBox.shrink(),
  });

  final AppRole? currentRole;
  final AppRole requiredRole;
  final Widget child;
  final Widget replacement;

  @override
  Widget build(BuildContext context) {
    final role = currentRole;
    if (role == null || !RolePermissions.hasAtLeast(role, requiredRole)) {
      return replacement;
    }
    return child;
  }
}
