import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_paths.dart';
import '../providers/approval_provider.dart';

class ApprovalListScreen extends ConsumerWidget {
  const ApprovalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsers = ref.watch(pendingUsersProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        children: [
          Text(
            'Approval User',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Setujui akun baru agar bisa masuk dashboard.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          pendingUsers.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Gagal memuat pending user: $error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            data: (items) {
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('Tidak ada user pending saat ini.'),
                );
              }

              return Column(
                children:
                    items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PendingUserCard(
                              userId: item.userId,
                              namaAsli: item.namaAsli,
                              email: item.email,
                              onTap:
                                  () => context.push(
                                    RoutePaths.approvalDetail(item.userId),
                                  ),
                            ),
                          ),
                        )
                        .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  const _PendingUserCard({
    required this.userId,
    required this.namaAsli,
    required this.email,
    required this.onTap,
  });

  final int userId;
  final String namaAsli;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaAsli.isEmpty ? '-' : namaAsli,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isEmpty ? '-' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User_ID: $userId',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
