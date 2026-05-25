class RoutePaths {
  const RoutePaths._();

  static const login = '/login';
  static const pending = '/pending';
  static const dashboard = '/dashboard';
  static const approval = '/approval';
  static const approvalDetailBase = '/approval/user';
  static const master = '/master';
  static const setoran = '/setoran';
  static const setoranNew = '/setoran/new';
  static const setoranDetailBase = '/setoran/detail';
  static const setoranPrintBase = '/setoran/print';
  static const penjualan = '/penjualan';
  static const penjualanNew = '/penjualan/new';
  static const penjualanDetailBase = '/penjualan/detail';
  static const penarikan = '/penarikan';
  static const penarikanNew = '/penarikan/new';
  static const penarikanDetailBase = '/penarikan/detail';
  static const reporting = '/reporting';
  static const reportKartuGudang = '/reporting/kartu-gudang';
  static const reportSaldoPegawai = '/reporting/saldo-pegawai';
  static const reportSelisihRealisasi = '/reporting/selisih-realisasi';
  static const reportNeraca = '/reporting/neraca';
  static const reportHppLabaRugi = '/reporting/hpp-labarugi';
  static const reportCoaList = '/reporting/coa-list';

  static String approvalDetail(int userId) => '$approvalDetailBase/$userId';
  static String setoranDetail(String noBukti) {
    return '$setoranDetailBase/${Uri.encodeComponent(noBukti)}';
  }

  static String setoranPrint(String noBukti) {
    return '$setoranPrintBase/${Uri.encodeComponent(noBukti)}';
  }

  static String penjualanDetail(String noBukti) {
    return '$penjualanDetailBase/${Uri.encodeComponent(noBukti)}';
  }

  static String penarikanDetail(String noBukti) {
    return '$penarikanDetailBase/${Uri.encodeComponent(noBukti)}';
  }
}
