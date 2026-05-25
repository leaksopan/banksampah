class AppUser {
  const AppUser({
    required this.userId,
    required this.email,
    required this.namaAsli,
    required this.statusApproval,
    required this.roles,
    required this.unitBisnisIds,
  });

  final int userId;
  final String email;
  final String namaAsli;
  final String statusApproval;
  final List<String> roles;
  final List<int> unitBisnisIds;

  bool get isApproved => statusApproval == 'APPROVED';
  bool get isAdmin => roles.contains('ADMIN');

  int? get primaryUnitBisnisId {
    return unitBisnisIds.isEmpty ? null : unitBisnisIds.first;
  }

  factory AppUser.fromJson(
    Map<String, dynamic> json, {
    List<int> unitBisnisIds = const <int>[],
  }) {
    final rolesRaw = json['Roles'];

    return AppUser(
      userId: json['User_ID'] as int,
      email: (json['Email'] as String?) ?? '',
      namaAsli: (json['Nama_Asli'] as String?) ?? '',
      statusApproval: (json['Status_Approval'] as String?) ?? 'PENDING',
      roles:
          rolesRaw is List
              ? rolesRaw.whereType<String>().toList(growable: false)
              : const <String>[],
      unitBisnisIds: unitBisnisIds,
    );
  }
}
