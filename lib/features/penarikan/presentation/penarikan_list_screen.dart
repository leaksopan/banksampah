import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../routing/route_paths.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../providers/penarikan_provider.dart';

class PenarikanListScreen extends ConsumerStatefulWidget {
  const PenarikanListScreen({super.key});

  @override
  ConsumerState<PenarikanListScreen> createState() => _PenarikanListScreenState();
}

class _PenarikanListScreenState extends ConsumerState<PenarikanListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Approval Penarikan' : 'Tabungan & Saldo',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(penarikanListProvider),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(penarikanListProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (!isAdmin) ...[
                    _buildBalanceCard(colorScheme),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildAdminSearch(colorScheme),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAdmin ? 'Daftar Pengajuan' : 'Riwayat Penarikan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (!isAdmin)
                        ElevatedButton.icon(
                          onPressed: () => context.go(RoutePaths.penarikanNew),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tarik Saldo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isAdmin) ...[
                    TabBar(
                      controller: _tabController,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Approved'),
                        Tab(text: 'Paid'),
                        Tab(text: 'Rejected'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(isAdmin, 'PENDING'),
                          _buildList(isAdmin, 'APPROVED'),
                          _buildList(isAdmin, 'PAID'),
                          _buildList(isAdmin, 'REJECTED'),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildList(isAdmin, null),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(ColorScheme colorScheme) {
    final saldoAsync = ref.watch(currentPegawaiSaldoProvider);

    return saldoAsync.when(
      data: (saldo) {
        if (saldo == null) return const SizedBox();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SALDO TERSEDIA (DAPAT DITARIK)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.rupiah(saldo.saldoTersedia),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi Saldo (Pending)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.rupiah(saldo.saldoPending),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Telah Ditarik',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.rupiah(saldo.totalDitarik),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget _buildAdminSearch(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama pegawai atau nomor bukti...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
      },
    );
  }

  Widget _buildList(bool isAdmin, String? statusFilter) {
    final listAsync = ref.watch(penarikanListProvider);

    return listAsync.when(
      data: (list) {
        var filteredList = list;
        if (statusFilter != null) {
          filteredList = filteredList.where((x) => x.status == statusFilter).toList();
        }
        if (_searchQuery.isNotEmpty) {
          filteredList = filteredList.where((x) {
            return x.namaPegawai.toLowerCase().contains(_searchQuery) ||
                x.noBukti.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada pengajuan penarikan.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: !isAdmin,
          physics: !isAdmin ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            return _buildPenarikanCard(item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
    );
  }

  Widget _buildPenarikanCard(Penarikan item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTransfer = item.typePembayaran == 'T';

    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case 'PAID':
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'APPROVED':
        statusColor = const Color(0xFF0288D1);
        statusIcon = Icons.rule_rounded;
        break;
      case 'REJECTED':
        statusColor = colorScheme.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFEF6C00);
        statusIcon = Icons.hourglass_empty_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(RoutePaths.penarikanDetail(item.noBukti)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isTransfer ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isTransfer ? Icons.account_balance_rounded : Icons.payments_rounded,
                  color: isTransfer ? const Color(0xFF1E88E5) : const Color(0xFF43A047),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.noBukti,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.namaPegawai} (${AppFormatters.shortDate(item.tglPenarikan)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          item.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppFormatters.rupiah(item.jumlah),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
