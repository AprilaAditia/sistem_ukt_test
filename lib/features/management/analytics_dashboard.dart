import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'report_screen.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  bool _isLoading = true;
  int _totalPendaftar = 0;
  Map<String, int> _distribusiGolongan = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  // Mengambil total pendaftar dan sebaran golongan dari Supabase
  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('ukt_submissions')
          .select('rekomendasi_golongan');

      int total = response.length;
      Map<String, int> distribusi = {};

      // Mengelompokkan (Group By) data berdasarkan golongannya
      for (var item in response) {
        String golongan = item['rekomendasi_golongan'] ?? 'Belum Ditentukan';
        distribusi[golongan] = (distribusi[golongan] ?? 0) + 1;
      }

      // Mengurutkan kunci map (Golongan I, II, III, dst)
      var sortedKeys = distribusi.keys.toList()..sort();
      Map<String, int> sortedDistribusi = {
        for (var k in sortedKeys) k: distribusi[k]!
      };

      if (mounted) {
        setState(() {
          _totalPendaftar = total;
          _distribusiGolongan = sortedDistribusi;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat analitik: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAnalyticsData),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAnalyticsData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kartu Total Pendaftar
                    Card(
                      color: Colors.blue.shade700,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text('Total Pengajuan UKT', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                              '$_totalPendaftar',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Sebaran Rekomendasi Golongan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Area Visualisasi Data (Native Bar Chart)
                    Expanded(
                      child: _totalPendaftar == 0
                          ? const Center(child: Text('Belum ada data pengajuan.'))
                          : ListView.builder(
                              itemCount: _distribusiGolongan.length,
                              itemBuilder: (context, index) {
                                String golongan = _distribusiGolongan.keys.elementAt(index);
                                int jumlah = _distribusiGolongan[golongan]!;
                                // Menghitung persentase untuk panjang bar (progress bar)
                                double persentase = jumlah / _totalPendaftar;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(golongan, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('$jumlah Orang (${(persentase * 100).toStringAsFixed(1)}%)'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: persentase,
                                          minHeight: 12,
                                          backgroundColor: Colors.grey.shade300,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tombol Navigasi ke Halaman Report/Ekspor
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade900,
                      ),
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text('Buka Menu Laporan & Ekspor CSV', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}