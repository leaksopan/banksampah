import 'package:flutter_test/flutter_test.dart';
import 'package:banksampah/data/models/bank_sampah_models.dart';

void main() {
  group('UnitBisnis Model Tests', () {
    test('Should parse UnitBisnis from JSON successfully', () {
      final json = {
        'UnitBisnisID': 2,
        'UnitBisnisName': 'Dinas Lingkungan Hidup Badung',
        'Kode_OPD': 'DLH',
        'Tipe_OPD': 'DINAS',
        'Warna_Primary': '#2E7D32',
        'Logo_URL': 'https://example.com/logo.png',
        'Status_Aktif': true,
      };

      final unitBisnis = UnitBisnis.fromJson(json);

      expect(unitBisnis.unitBisnisId, 2);
      expect(unitBisnis.unitBisnisName, 'Dinas Lingkungan Hidup Badung');
      expect(unitBisnis.kodeOpd, 'DLH');
      expect(unitBisnis.tipeOpd, 'DINAS');
      expect(unitBisnis.warnaPrimary, '#2E7D32');
      expect(unitBisnis.logoUrl, 'https://example.com/logo.png');
      expect(unitBisnis.statusAktif, true);
    });

    test('Should handle null values in UnitBisnis JSON', () {
      final json = {
        'UnitBisnisID': 1,
        'UnitBisnisName': null,
        'Kode_OPD': null,
        'Tipe_OPD': null,
        'Warna_Primary': null,
        'Logo_URL': null,
        'Status_Aktif': null,
      };

      final unitBisnis = UnitBisnis.fromJson(json);

      expect(unitBisnis.unitBisnisId, 1);
      expect(unitBisnis.unitBisnisName, '');
      expect(unitBisnis.kodeOpd, '');
      expect(unitBisnis.tipeOpd, '');
      expect(unitBisnis.warnaPrimary, isNull);
      expect(unitBisnis.logoUrl, isNull);
      expect(unitBisnis.statusAktif, true); // default true
    });
  });

  group('Pegawai Model Tests', () {
    test('Should parse Pegawai from JSON successfully', () {
      final json = {
        'Pegawai_ID': 4,
        'Nama_Pegawai': 'I Wayan Sampah Mas',
        'NIP': '198812122015041003',
        'UnitBisnisID': 2,
        'User_ID': 6,
        'No_Telepon': '081234567891',
        'Email': 'wayan.mas@dlh.badung.go.id',
        'Status_Aktif': true,
      };

      final pegawai = Pegawai.fromJson(json);

      expect(pegawai.pegawaiId, 4);
      expect(pegawai.namaPegawai, 'I Wayan Sampah Mas');
      expect(pegawai.nip, '198812122015041003');
      expect(pegawai.unitBisnisId, 2);
      expect(pegawai.userId, 6);
      expect(pegawai.noTelepon, '081234567891');
      expect(pegawai.email, 'wayan.mas@dlh.badung.go.id');
      expect(pegawai.statusAktif, true);
    });
  });

  group('SaldoPegawai Model Tests', () {
    test('Should parse SaldoPegawai from JSON successfully', () {
      final json = {
        'Pegawai_ID': 2,
        'Saldo_Pending': 18500.50,
        'Saldo_Tersedia': 8500.00,
        'Total_Berat_Setor': 15.65,
        'Total_Ditarik': 10000.00,
      };

      final saldo = SaldoPegawai.fromJson(json);

      expect(saldo.pegawaiId, 2);
      expect(saldo.saldoPending, 18500.50);
      expect(saldo.saldoTersedia, 8500.00);
      expect(saldo.totalBeratSetor, 15.65);
      expect(saldo.totalDitarik, 10000.00);
    });
  });
}
