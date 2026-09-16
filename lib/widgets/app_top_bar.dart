import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/roles.dart';
import '../core/services.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.services,
    required this.title,
    this.showHome = true,
  });

  final AppServices services;
  final String title;
  final bool showHome;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: services.auth,
      builder: (context, _) {
        final user = services.auth.user;
        final serverRole = services.auth.serverRole;
        final uiRole = services.auth.uiRole;
        final compact = MediaQuery.sizeOf(context).width < 600;

        return AppBar(
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
          leading: showHome
              ? IconButton(
                  tooltip: 'На главную',
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                )
              : null,
          actions: [
            if (user != null && !compact)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '${user.fullName} · ${serverRole?.title ?? user.role}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (user != null && compact)
              Tooltip(
                message: '${user.fullName} · ${serverRole?.title ?? user.role}',
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.account_circle_outlined),
                ),
              ),
            if (uiRole != null &&
                serverRole != null &&
                uiRole != serverRole &&
                !compact)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Chip(
                    avatar: const Icon(Icons.warning_amber, size: 18),
                    label: Text('UI: ${uiRole.title}'),
                  ),
                ),
              ),
            if (user != null)
              IconButton(
                tooltip: 'Выйти',
                onPressed: () async {
                  await services.auth.logout();
                },
                icon: const Icon(Icons.logout),
              ),
            if (!compact) const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
