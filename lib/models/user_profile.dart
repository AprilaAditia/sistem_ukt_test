class UserProfile {
  final String id;
  final String namaLengkap;
  final String role;

  UserProfile({
    required this.id,
    required this.namaLengkap,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      namaLengkap: json['nama_lengkap'],
      role: json['role'],
    );
  }
}