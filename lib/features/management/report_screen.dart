import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy to Clipboard
import '../../core/constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedGolongan = 'Semua Golongan';
  List<dynamic> _reportData = [];
  bool _isLoading = true;

  final List<String> _golonganOptions = [
    'Semua Golongan',
    'Golongan I', 'Golongan II', 'Golongan III', 'Golongan IV',
    'Golongan V', 'Golongan VI', 'Golongan VII', 'Golongan VIII'
  ];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  // Mengambil data berdasarkan filter Dropdown dengan urutan Query yang benar
  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Inisialisasi awal Select (Tanpa Order terlebih dahulu)
      var query = supabase
          .from('ukt_submissions')
          .select('id, penghasilan_ortu, skor_akhir, rekomendasi_golongan, status_pengajuan, profiles(nama_lengkap)');

      // 2. Terapkan Filter (EQ) JIKA BUKAN 'Semua Golongan'
      if (_selectedGolongan != 'Semua Golongan') {
        query = query.eq('rekomendasi_golongan', _selectedGolongan);
      }

      // 3. Terapkan Order di tahap paling akhir, lalu eksekusi dengan await
      final response = await query.order('skor_akhir', ascending: false);

      if (mounted) {
        setState(() {
          _reportData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi Native Dart untuk mengubah JSON (List) menjadi format text CSV
  void _generateAndShowCSV() {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor!')),
      );
      return;
    }

    StringBuffer csvData = StringBuffer();
    // 1. Buat Header (Baris Pertama CSV)
    csvData.writeln("Nama Mahasiswa,Penghasilan Ortu,Skor SAW,Golongan UKT,Status");

    // 2. Looping isi data
    for (var item in _reportData) {
      final nama = item['profiles'] != null ? item['profiles']['nama_lengkap'] : 'Anonim';
      final penghasilan = item['penghasilan_ortu'] ?? 0;
      final skor = (item['skor_akhir'] as num).toDouble().toStringAsFixed(2);
      final golongan = item['rekomendasi_golongan'] ?? '-';
      final status = item['status_pengajuan'] ?? '-';

      // Gabungkan dengan pemisah koma (Comma Separated Values)
      csvData.writeln("$nama,$penghasilan,$skor,$golongan,$status");
    }

    // 3. Tampilkan di Popup Dialog agar bisa di-copy
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hasil Ekspor CSV'),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200,
              child: SelectableText(
                csvData.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvData.toString()));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data CSV disalin ke Clipboard! Tinggal Paste di Notepad/Excel.'), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Data'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Ekspor Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area Filter
            const Text('Filter Data Berdasarkan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGolongan,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: _golonganOptions.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedGolongan = val);
                        _fetchReportData(); // Otomatis refresh tabel saat filter diganti
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateAndShowCSV,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text('CSV', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 2),
            
            // Area Pratinjau Tabel
            const Text('Pratinjau Data Laporan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reportData.isEmpty
                      ? const Center(child: Text('Tidak ada data yang sesuai filter.'))
                      : ListView.builder(
                          itemCount: _reportData.length,
                          itemBuilder: (context, index) {
                            final item = _reportData[index];
                            final nama = item['profiles'] != null ? item['profiles']['nama_lengkap'] : 'Anonim';
                            final golongan = item['rekomendasi_golongan'] ?? 'Belum ada';
                            final skor = (item['skor_akhir'] as num).toDouble().toStringAsFixed(2);
                            final status = item['status_pengajuan'].toString().toUpperCase();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text('${index + 1}', style: TextStyle(color: Colors.blue.shade900)),
                                ),
                                title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Skor: $skor | $golongan'),
                                trailing: Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'FINAL' ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}