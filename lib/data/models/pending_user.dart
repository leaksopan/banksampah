class PendingUser {
  const PendingUser({
    required this.userId,
    required this.email,
    required this.namaAsli,
    required this.statusApproval,
    required this.tglDaftar,
  });

  final int userId;
  final String email;
  final String namaAsli;
  final String statusApproval;
  final DateTime? tglDaftar;

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    final tglDaftarValue = json['Tgl_Daftar'];
    final parsedDate =
        tglDaftarValue is String && tglDaftarValue.isNotEmpty
            ? DateTime.tryParse(tglDaftarValue)
            : null;

    return PendingUser(
      userId: json['User_ID'] as int,
      email: (json['Email'] as String?) ?? '',
      namaAsli: (json['Nama_Asli'] as String?) ?? '',
      statusApproval: (json['Status_Approval'] as String?) ?? 'PENDING',
      tglDaftar: parsedDate,
    );
  }
}
