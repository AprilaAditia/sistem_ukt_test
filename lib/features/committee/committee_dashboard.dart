import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'finalize_ukt.dart';

class CommitteeDashboard extends StatefulWidget {
  const CommitteeDashboard({Key? key}) : super(key: key);

  @override
  _CommitteeDashboardState createState() => _CommitteeDashboardState();
}

class _CommitteeDashboardState extends State<CommitteeDashboard> {
  bool _isLoading = true;
  int _menungguFinalisasi = 0;
  int _sudahFinal = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  // Fungsi untuk mengambil rekap statistik dari database
  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      // Menghitung yang belum final
      final pendingResponse = await supabase
          .from('ukt_submissions')
          .select('id')
          .neq('status_pengajuan', 'final');

      // Menghitung yang sudah final
      final finalResponse = await supabase
          .from('ukt_submissions')
          .select('id')
          .eq('status_pengajuan', 'final');

      if (mounted) {
        setState(() {
          _menungguFinalisasi = pendingResponse.length;
          _sudahFinal = finalResponse.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Panitia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Ringkasan Penetapan UKT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Kartu Statistik
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.orange.shade100,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Menunggu',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_menungguFinalisasi',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: Colors.green.shade100,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Selesai',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_sudahFinal',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Menu Utama',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Kartu Menu untuk masuk ke halaman Finalisasi
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () async {
                        // Membuka halaman FinalizeUkt, lalu me-refresh statistik jika sudah kembali ke dashboard
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FinalizeUkt(),
                          ),
                        );
                        _fetchDashboardStats();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade700,
                              child: const Icon(
                                Icons.gavel,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Finalisasi Data UKT',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tinjau rekomendasi sistem (SAW), setujui, atau lakukan override secara manual.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
