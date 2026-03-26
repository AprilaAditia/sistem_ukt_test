class UktSubmission {
  final String userId;
  final double penghasilanAyah;
  final double penghasilanIbu;
  final int jumlahTanggungan;
  final String pekerjaanAyah;
  final String pekerjaanIbu;
  final String statusRumah;
  final int luasTanah;
  final double nilaiPbb;
  final double cicilanHutang;
  final String punyaKendaraan;
  final String? jenisKendaraan;
  final int jumlahKendaraan;
  final double tagihanListrik;
  final double tagihanAir;
  
  // Variabel Dokumen Baru
  final String fotoRumahUrl;
  final String sktmUrl;
  final String koordinatLokasi;

  UktSubmission({
    required this.userId, 
    required this.penghasilanAyah, 
    required this.penghasilanIbu,
    required this.jumlahTanggungan, 
    required this.pekerjaanAyah, 
    required this.pekerjaanIbu,
    required this.statusRumah, 
    required this.luasTanah, 
    required this.nilaiPbb,
    required this.cicilanHutang, 
    required this.punyaKendaraan, 
    this.jenisKendaraan,
    required this.jumlahKendaraan, 
    required this.tagihanListrik, 
    required this.tagihanAir,
    required this.fotoRumahUrl, 
    required this.sktmUrl, 
    required this.koordinatLokasi,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'penghasilan_ayah': penghasilanAyah, 
      'penghasilan_ibu': penghasilanIbu,
      'jumlah_tanggungan': jumlahTanggungan,
      'pekerjaan_ayah': pekerjaanAyah, 
      'pekerjaan_ibu': pekerjaanIbu,
      'status_rumah': statusRumah, 
      'luas_tanah': luasTanah, 
      'nilai_pbb': nilaiPbb,
      'cicilan_hutang': cicilanHutang, 
      'punya_kendaraan': punyaKendaraan,
      'jenis_kendaraan': jenisKendaraan, 
      'jumlah_kendaraan': jumlahKendaraan,
      'tagihan_listrik': tagihanListrik, 
      'tagihan_air': tagihanAir,
      'foto_rumah_url': fotoRumahUrl, 
      'sktm_url': sktmUrl, 
      'koordinat_lokasi': koordinatLokasi,
      'status_pengajuan': 'submitted', 
      'status_dokumen': 'pending',
    };
  }
}