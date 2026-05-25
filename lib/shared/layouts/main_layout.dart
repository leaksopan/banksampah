import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/role.dart';
import '../../features/auth/providers/auth_state_provider.dart';
import '../../routing/route_paths.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(supabaseClientProvider).auth.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final isAdmin = user?.roles.contains(AppRole.admin) ?? false;
    final items = _buildItems(isAdmin);
    final selectedIndex = _resolveSelectedIndex(items);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var index = 0; index < items.length; index++)
                  _BottomNavItem(
                    icon: items[index].icon,
                    label: items[index].label,
                    selected: selectedIndex == index,
                    onTap: () async {
                      if (items[index].action == _BottomAction.signOut) {
                        await _signOut(ref);
                        return;
                      }

                      if (context.mounted) {
                        context.go(items[index].path!);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _resolveSelectedIndex(List<_BottomItem> items) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.path == null) {
        continue;
      }
      if (currentLocation.startsWith(item.path!)) {
        return i;
      }
    }

    return 0;
  }

  List<_BottomItem> _buildItems(bool isAdmin) {
    final baseItems = <_BottomItem>[
      const _BottomItem(
        icon: Icons.home_rounded,
        label: 'Beranda',
        path: RoutePaths.dashboard,
        action: _BottomAction.navigate,
      ),
      _BottomItem(
        icon:
            isAdmin
                ? Icons.add_circle_rounded
                : Icons.account_balance_wallet_rounded,
        label: isAdmin ? 'Setoran' : 'Saldo',
        path: isAdmin ? RoutePaths.setoran : RoutePaths.dashboard,
        action: _BottomAction.navigate,
      ),
      if (isAdmin)
        const _BottomItem(
          icon: Icons.local_shipping_rounded,
          label: 'Jual',
          path: RoutePaths.penjualan,
          action: _BottomAction.navigate,
        ),
      if (isAdmin)
        const _BottomItem(
          icon: Icons.tune_rounded,
          label: 'Master',
          path: RoutePaths.master,
          action: _BottomAction.navigate,
        ),
      if (!isAdmin)
        const _BottomItem(
          icon: Icons.person_rounded,
          label: 'Profil',
          path: RoutePaths.dashboard,
          action: _BottomAction.navigate,
        ),
      const _BottomItem(
        icon: Icons.logout_rounded,
        label: 'Keluar',
        path: null,
        action: _BottomAction.signOut,
      ),
    ];

    return baseItems;
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.action,
  });

  final IconData icon;
  final String label;
  final String? path;
  final _BottomAction action;
}

enum _BottomAction { navigate, signOut }
