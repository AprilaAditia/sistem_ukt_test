import 'package:flutter/material.dart';
import '../../core/constants.dart';

class FinalizeUkt extends StatefulWidget {
  const FinalizeUkt({Key? key}) : super(key: key);

  @override
  _FinalizeUktState createState() => _FinalizeUktState();
}

class _FinalizeUktState extends State<FinalizeUkt> {
  List<dynamic> _submissionsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  // Mengambil data pengajuan yang belum di-finalisasi (status: submitted atau banding)
  // Query ini melakukan JOIN ke tabel profiles untuk mengambil nama mahasiswa
  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('ukt_submissions')
          .select('id, skor_akhir, rekomendasi_golongan, status_pengajuan, profiles(nama_lengkap)')
          .neq('status_pengajuan', 'final') // Sembunyikan yang sudah selesai
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _submissionsList = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi untuk menyimpan keputusan akhir Panitia
  Future<void> _finalizeSubmission(String idSubmission, String golonganFinal) async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('ukt_submissions').update({
        'rekomendasi_golongan': golonganFinal, // Simpan/Override golongannya
        'status_pengajuan': 'final',           // Ubah status jadi final
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', idSubmission);

      await _fetchSubmissions(); // Refresh daftar setelah berhasil

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UKT berhasil difinalisasi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Menampilkan popup untuk memilih golongan secara manual (Override)
  void _showOverrideDialog(String idSubmission, String currentGolongan, String namaLengkap) {
    String? selectedGolongan = currentGolongan;
    final List<String> daftarGolongan = [
      'Golongan I', 'Golongan II', 'Golongan III', 'Golongan IV',
      'Golongan V', 'Golongan VI', 'Golongan VII', 'Golongan VIII'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Override Manual UKT'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ubah golongan untuk mahasiswa: $namaLengkap'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGolongan,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Golongan Baru',
                      border: OutlineInputBorder(),
                    ),
                    items: daftarGolongan.map((gol) {
                      return DropdownMenuItem(value: gol, child: Text(gol));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedGolongan = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedGolongan != null) {
                      Navigator.pop(context);
                      _finalizeSubmission(idSubmission, selectedGolongan!);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Simpan Override', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalisasi Golongan UKT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSubmissions,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissionsList.isEmpty
              ? const Center(child: Text('Tidak ada antrean finalisasi UKT.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _submissionsList.length,
                  itemBuilder: (context, index) {
                    final item = _submissionsList[index];
                    
                    // Mengurai data Join dari Supabase
                    final namaMahasiswa = item['profiles'] != null ? item['profiles']['nama_lengkap'] : 'User Tidak Dikenal';
                    final skor = (item['skor_akhir'] as num).toDouble();
                    final rekomendasi = item['rekomendasi_golongan'] ?? 'Belum ada';
                    final idSubmission = item['id'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    namaMahasiswa,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Skor SAW: ${skor.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Rekomendasi Sistem: $rekomendasi', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showOverrideDialog(idSubmission, rekomendasi, namaMahasiswa),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                    ),
                                    child: const Text('Override', textAlign: TextAlign.center),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () => _finalizeSubmission(idSubmission, rekomendasi),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Setujui Rekomendasi', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}