# 09 — Flutter Structure

> Struktur folder & layering untuk app Flutter (mobile + web).

## Stack Internal

| Layer | Library |
|---|---|
| Routing | `go_router` |
| State | `flutter_riverpod` + `riverpod_annotation` |
| DB Client | `supabase_flutter` |
| Form | `flutter_form_builder` + `form_builder_validators` |
| Date/Money Format | `intl` (locale `id_ID`) |
| Logger | `talker_flutter` |
| Env Config | `--dart-define` |
| Code Gen | `build_runner` + `freezed` + `json_serializable` |
| UI (web) | `flutter_shadcn_ui` (atau alternatif setara) |
| UI (mobile) | Material 3 |
| Charts | `fl_chart` |
| Data Table | `data_table_2` (mobile) / `flutter_shadcn_ui` table (web) |

## Folder Structure

```
app/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp.router config
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── env.dart                  # baca --dart-define
│   │   │   └── supabase_config.dart
│   │   ├── constants/
│   │   │   ├── jenis_transaksi.dart      # const ID 700-712
│   │   │   ├── kode_modul.dart           # 'BSP','BSJ','BST'
│   │   │   ├── status.dart               # enum status setoran/penjualan/penarikan
│   │   │   └── role.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_typography.dart
│   │   ├── utils/
│   │   │   ├── formatters.dart           # currency, date, weight
│   │   │   ├── validators.dart
│   │   │   └── responsive.dart           # detect mobile vs web
│   │   ├── extensions/
│   │   │   ├── string_x.dart
│   │   │   └── num_x.dart
│   │   └── errors/
│   │       └── app_exception.dart
│   │
│   ├── data/
│   │   ├── supabase/
│   │   │   ├── supabase_client_provider.dart
│   │   │   └── auth_provider.dart
│   │   ├── models/                        # freezed data classes
│   │   │   ├── unit_bisnis.dart
│   │   │   ├── pegawai.dart
│   │   │   ├── sampah.dart
│   │   │   ├── vendor.dart
│   │   │   ├── lokasi.dart
│   │   │   ├── kategori.dart
│   │   │   ├── setoran.dart
│   │   │   ├── setoran_detail.dart
│   │   │   ├── penjualan.dart
│   │   │   ├── penjualan_detail.dart
│   │   │   ├── penarikan.dart
│   │   │   ├── kartu_gudang.dart
│   │   │   ├── stock_layer.dart
│   │   │   ├── mutasi_saldo.dart
│   │   │   └── saldo_pegawai.dart
│   │   └── repositories/
│   │       ├── pegawai_repository.dart
│   │       ├── sampah_repository.dart
│   │       ├── vendor_repository.dart
│   │       ├── lokasi_repository.dart
│   │       ├── setoran_repository.dart
│   │       ├── penjualan_repository.dart
│   │       ├── penarikan_repository.dart
│   │       ├── saldo_repository.dart
│   │       └── kartu_gudang_repository.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── splash_screen.dart
│   │   │   └── providers/
│   │   │       └── auth_state_provider.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── presentation/
│   │   │   │   ├── pegawai_dashboard.dart
│   │   │   │   └── admin_dashboard.dart
│   │   │   └── widgets/
│   │   │       ├── saldo_card.dart
│   │   │       └── stock_summary.dart
│   │   │
│   │   ├── setoran/
│   │   │   ├── presentation/
│   │   │   │   ├── setoran_list_screen.dart
│   │   │   │   ├── setoran_form_screen.dart
│   │   │   │   └── setoran_detail_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── setoran_item_form.dart
│   │   │   │   └── setoran_card.dart
│   │   │   └── providers/
│   │   │       ├── setoran_list_provider.dart
│   │   │       └── setoran_form_provider.dart
│   │   │
│   │   ├── penjualan/
│   │   │   ├── presentation/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   │
│   │   ├── penarikan/
│   │   │   ├── presentation/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   │
│   │   ├── master/
│   │   │   ├── pegawai/
│   │   │   ├── sampah/
│   │   │   ├── vendor/
│   │   │   └── lokasi/
│   │   │
│   │   └── laporan/
│   │       ├── kartu_gudang_screen.dart
│   │       ├── setoran_per_pegawai.dart
│   │       └── selisih_realisasi.dart
│   │
│   ├── routing/
│   │   ├── app_router.dart                # go_router config
│   │   └── route_paths.dart               # const route names
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_data_table.dart
│       │   ├── app_dialog.dart
│       │   └── empty_state.dart
│       └── layouts/
│           ├── main_layout.dart           # nav rail (web) / bottom nav (mobile)
│           └── auth_layout.dart
│
├── test/
└── integration_test/
```

## Naming Convention Dart

| Item | Style | Contoh |
|---|---|---|
| Class | PascalCase | `SetoranSampah`, `PegawaiRepository` |
| File | snake_case | `setoran_form_screen.dart` |
| Variable / Property | camelCase | `noBukti`, `tglSetoran` |
| Constant | lowerCamelCase di file `constants/` | `kJenisTransaksiSetoran = 700` |
| Provider | camelCase + suffix `Provider` | `setoranListProvider` |

## Mapping Field DB → Dart

DB pakai `PascalCase_underscore`, Dart pakai `camelCase`. Mapping di `fromMap`/`toMap`:

```dart
@freezed
class Setoran with _$Setoran {
  const factory Setoran({
    required String noBukti,
    required DateTime tglSetoran,
    required int pegawaiId,
    required int lokasiId,
    required double totalBerat,
    required num totalNilai,
    @Default(false) bool statusBatal,
    @Default(false) bool posted,
    required int unitBisnisId,
  }) = _Setoran;

  factory Setoran.fromJson(Map<String, dynamic> json) => Setoran(
    noBukti: json['No_Bukti'],
    tglSetoran: DateTime.parse(json['Tgl_Setoran']),
    pegawaiId: json['Pegawai_ID'],
    lokasiId: json['Lokasi_ID'],
    totalBerat: (json['Total_Berat'] as num).toDouble(),
    totalNilai: json['Total_Nilai'],
    statusBatal: json['Status_Batal'] ?? false,
    posted: json['Posted'] ?? false,
    unitBisnisId: json['UnitBisnisID'],
  );

  Map<String, dynamic> toJson() => {
    'No_Bukti': noBukti,
    'Tgl_Setoran': tglSetoran.toIso8601String(),
    'Pegawai_ID': pegawaiId,
    'Lokasi_ID': lokasiId,
    'Total_Berat': totalBerat,
    'Total_Nilai': totalNilai,
    'Status_Batal': statusBatal,
    'Posted': posted,
    'UnitBisnisID': unitBisnisId,
  };
}
```

## Repository Pattern

```dart
class SetoranRepository {
  SetoranRepository(this._client);
  final SupabaseClient _client;

  Future<List<Setoran>> list({
    required int unitBisnisId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client.from('BS_trSetoran').select().eq('UnitBisnisID', unitBisnisId);
    if (from != null) query = query.gte('Tgl_Setoran', from.toIso8601String());
    if (to != null)   query = query.lte('Tgl_Setoran', to.toIso8601String());

    final res = await query.order('Tgl_Setoran', ascending: false);
    return (res as List).map((e) => Setoran.fromJson(e)).toList();
  }

  Future<Setoran> create({
    required int pegawaiId,
    required int lokasiId,
    required List<SetoranDetail> details,
    String? keterangan,
  }) async {
    // panggil RPC supaya transaksi atomik (header + detail + layer + KG + mutasi)
    final res = await _client.rpc('bs_create_setoran', params: {
      'p_pegawai_id': pegawaiId,
      'p_lokasi_id': lokasiId,
      'p_keterangan': keterangan,
      'p_details': details.map((d) => d.toJson()).toList(),
    });
    return Setoran.fromJson(res);
  }
}
```

## Routing (go_router)

```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/setoran',   builder: (_, __) => const SetoranListScreen()),
        GoRoute(path: '/setoran/new', builder: (_, __) => const SetoranFormScreen()),
        GoRoute(path: '/setoran/:noBukti', builder: (_, s) =>
          SetoranDetailScreen(noBukti: s.pathParameters['noBukti']!)),
        // ...penjualan, penarikan, master, laporan
      ],
    ),
  ],
  redirect: (ctx, state) {
    // auth guard via authStateProvider
  },
);
```

### MVP Login/Dashboard Awal

Implementasi awal memakai struktur langsung di root proyek Flutter:

- `lib/main.dart` inisialisasi Supabase dari `--dart-define`.
- `lib/app.dart` berisi `MaterialApp.router`.
- `lib/routing/app_router.dart` menjaga route `/login`, `/pending`, dan `/dashboard`.
- `lib/features/auth/` berisi Google login, pending approval, dan provider profil user.
- `lib/shared/layouts/main_layout.dart` memakai layout mobile-first dengan bottom tab bar membulat; jangan pakai sidebar kiri / `NavigationRail` untuk user HP.
- `lib/shared/layouts/mobile_app_frame.dart` membatasi canvas app maksimal 430 px di browser desktop supaya tampilan tetap seperti HP.

Dashboard masih kosong, mobile-first, dan role `ADMIN`/`NASABAH` baru dipakai untuk guard/state awal.
Referensi visual utama: `.docs/Referensi.png`.

Catatan istilah: di HP, navigasi utama disebut **bottom navigation bar**, **bottom tab bar**,
atau **tab bar bawah**. Hindari istilah/implementasi navbar kiri untuk end-user mobile.

## State Management Pattern

```dart
@riverpod
class SetoranList extends _$SetoranList {
  @override
  Future<List<Setoran>> build({DateTimeRange? range}) async {
    final repo = ref.watch(setoranRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    return repo.list(unitBisnisId: user.unitBisnisId, from: range?.start, to: range?.end);
  }

  Future<void> refresh() => ref.invalidateSelf();
}
```

## Responsive: Mobile vs Web

```dart
class Responsive {
  static bool isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) => !isMobile(ctx) && MediaQuery.of(ctx).size.width < 1024;
  static bool isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 1024;
}

// Penggunaan:
Widget build(BuildContext ctx) {
  if (Responsive.isDesktop(ctx)) {
    return const AdminDashboardWeb();
  }
  return const AdminDashboardMobile();
}
```

## Hal Penting

1. **Multi-detail form**: pakai `ListView` + `flutter_form_builder` di dalam form parent. Tiap baris detail: dropdown sampah + input qty + auto-calc subtotal.
2. **Realtime saldo update**: subscribe ke channel Supabase `BS_tSaldoPegawai` untuk pegawai login. Update reactive di dashboard.
3. **Offline draft**: simpan draft setoran di Hive/Isar lokal, sync saat online (Phase 7).
4. **Bukti foto**: upload ke Supabase Storage bucket `bukti-bank-sampah/`, simpan URL di field `Bukti_Transfer_URL`.
5. **Locale**: `MaterialApp(locale: Locale('id','ID'))`. Date format: `dd MMM yyyy`. Currency: `Rp 1.234.567`.
