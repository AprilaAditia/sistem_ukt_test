// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import '../../core/constants.dart';

class VerifyDocumentScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const VerifyDocumentScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<VerifyDocumentScreen> createState() => _VerifyDocumentScreenState();
}

class _VerifyDocumentScreenState extends State<VerifyDocumentScreen> {
  bool _isLoading = false;

  // 1. FUNGSI SETUJUI (VALIDASI NORMAL)
  Future<void> _setujuiPengajuan() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan'),
        content: Text(
          'Setujui UKT untuk ${widget.data['profiles']?['nama_lengkap']} pada ${widget.data['rekomendasi_golongan']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Setujui',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    _updateStatus('approved', null, 'Pengajuan berhasil disetujui!');
  }

  // 2. FUNGSI TERIMA BANDING (Memberi akses mahasiswa untuk edit form)
  Future<void> _terimaBanding() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima Banding'),
        content: const Text(
          'Mahasiswa ini akan diberikan akses untuk memperbarui dan mengirim ulang data form UKT mereka. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Terima Banding',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    // Status diubah menjadi 'revisi' agar form mahasiswa terbuka kembali
    _updateStatus(
      'revisi',
      'Banding Anda diterima. Silakan perbarui data Anda.',
      'Banding berhasil diterima. Mahasiswa kini bisa mengedit data.',
    );
  }

  // 3. FUNGSI TOLAK BANDING (Kembali ke submitted + Alasan)
  Future<void> _tolakBanding() async {
    final TextEditingController alasanCtrl = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Banding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Banding akan ditolak dan status kembali menjadi "Menunggu Validasi". Berikan alasan penolakan:',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: alasanCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Contoh: Bukti SKTM tidak valid...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (alasanCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alasan harus diisi!')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text(
              'Tolak Banding',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    // Status dikembalikan ke 'submitted', disertai keterangan
    _updateStatus(
      'submitted',
      'Banding Ditolak: ${alasanCtrl.text}',
      'Banding berhasil ditolak.',
    );
  }

  // FUNGSI INTI UPDATE DATABASE
  Future<void> _updateStatus(
    String statusBaru,
    String? keterangan,
    String pesanSukses,
  ) async {
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('ukt_submissions')
          .update({
            'status_pengajuan': statusBaru,
            'keterangan_reviewer': keterangan,
          })
          .eq('user_id', widget.data['user_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanSukses), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status_pengajuan'] ?? 'submitted';
    final namaLengkap = widget.data['profiles']?['nama_lengkap'] ?? 'Mahasiswa';
    final isBanding = status == 'banding';
    final isApproved = status == 'approved';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Dokumen UKT'),
        backgroundColor: isBanding
            ? Colors.orange.shade800
            : (isApproved ? Colors.green.shade800 : Colors.blue.shade800),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Card(
              color: isBanding
                  ? Colors.orange.shade50
                  : (isApproved ? Colors.green.shade50 : Colors.blue.shade50),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBanding
                      ? Colors.orange
                      : (isApproved ? Colors.green : Colors.blue),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  namaLengkap,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  'Rekomendasi Sistem: ${widget.data['rekomendasi_golongan'] ?? '-'} (Skor: ${widget.data['skor_akhir'] ?? '-'})',
                ),
                trailing: Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: isBanding
                      ? Colors.orange
                      : (isApproved ? Colors.green : Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- ALASAN BANDING ---
            if (isBanding && widget.data['alasan_banding'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'ALASAN PENGAJUAN BANDING',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.red),
                    Text(
                      widget.data['alasan_banding'].toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            //  DATA DETAIL MAHASISWA 
            _buildSectionTitle('1. Data Keluarga'),
            _buildDataRow(
              'Penghasilan Ayah',
              'Rp ${widget.data['penghasilan_ayah'] ?? '0'}',
            ),
            _buildDataRow('Pekerjaan Ayah', widget.data['pekerjaan_ayah']),
            _buildDataRow(
              'Penghasilan Ibu',
              'Rp ${widget.data['penghasilan_ibu'] ?? '0'}',
            ),
            _buildDataRow('Pekerjaan Ibu', widget.data['pekerjaan_ibu']),
            _buildDataRow(
              'Jumlah Tanggungan',
              '${widget.data['jumlah_tanggungan'] ?? '0'} Orang',
            ),
            const Divider(),

            _buildSectionTitle('2. Data Aset & Rumah'),
            _buildDataRow('Status Rumah', widget.data['status_rumah']),
            _buildDataRow(
              'Luas Tanah',
              '${widget.data['luas_tanah'] ?? '0'} M2',
            ),
            _buildDataRow('Pajak PBB', 'Rp ${widget.data['nilai_pbb'] ?? '0'}'),
            _buildDataRow('Punya Kendaraan?', widget.data['punya_kendaraan']),
            if (widget.data['punya_kendaraan'] == 'Ya') ...[
              _buildDataRow('Jenis Kendaraan', widget.data['jenis_kendaraan']),
              _buildDataRow(
                'Jumlah Kendaraan',
                '${widget.data['jumlah_kendaraan'] ?? '0'} Unit',
              ),
            ],
            const Divider(),

            _buildSectionTitle('3. Beban Finansial'),
            _buildDataRow(
              'Cicilan Hutang',
              'Rp ${widget.data['cicilan_hutang'] ?? '0'} / bulan',
            ),
            _buildDataRow(
              'Tagihan Listrik',
              'Rp ${widget.data['tagihan_listrik'] ?? '0'} / bulan',
            ),
            _buildDataRow(
              'Tagihan Air',
              'Rp ${widget.data['tagihan_air'] ?? '0'} / bulan',
            ),
            const Divider(),

            _buildSectionTitle('4. Bukti Dokumen & GPS'),
            _buildDataRow('Koordinat Lokasi', widget.data['koordinat_lokasi']),
            const SizedBox(height: 10),
            const Text(
              'Foto Depan Rumah:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildImage(widget.data['foto_rumah_url']),

            const SizedBox(height: 16),
            const Text(
              'Surat Keterangan Tidak Mampu / Slip Gaji:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildImage(widget.data['sktm_url']),

            const SizedBox(height: 40),

            // TOMBOL AKSI REVIEWER
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (isBanding)
              // JIKA SEDANG BANDING, TAMPILKAN 2 TOMBOL (TERIMA & TOLAK)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text(
                        'TOLAK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _tolakBanding,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.edit_document),
                      label: const Text(
                        'TERIMA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _terimaBanding,
                    ),
                  ),
                ],
              )
            else if (!isApproved)
              // JIKA STATUS SUBMITTED (MENUNGGU VALIDASI)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'VALIDASI & SETUJUI UKT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _setujuiPengajuan,
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value) {
    final String safeValue = value?.toString() ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(' :  '),
          Expanded(
            flex: 3,
            child: Text(
              safeValue,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic urlDynamic) {
    final url = urlDynamic?.toString();
    if (url == null || url.isEmpty)
      return const Text(
        'Gambar tidak dilampirkan',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade200,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey),
              SizedBox(width: 8),
              Text('Gagal memuat gambar'),
            ],
          ),
        ),
      ),
    );
  }
}
