import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../auth/login_screen.dart';

import 'ukt_submission_form.dart';
import 'result_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({Key? key}) : super(key: key);

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  // Data Mahasiswa
  String _namaMahasiswa = 'Mahasiswa';
  Map<String, dynamic>? _submissionData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Fungsi untuk mengambil Nama dan Status Pengajuan dari Supabase
  Future<void> _fetchDashboardData() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // 1. Ambil Nama dari tabel profiles
      final profileData = await supabase
          .from('profiles')
          .select('nama_lengkap')
          .eq('id', userId)
          .single();

      // 2. Ambil Riwayat Pengajuan
      final submission = await supabase
          .from('ukt_submissions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _namaMahasiswa = profileData['nama_lengkap'] ?? 'Mahasiswa';
          _submissionData = submission;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah form boleh diisi/diedit
    // Boleh jika data kosong ATAU statusnya 'revisi'
    final statusSaatIni = _submissionData?['status_pengajuan'];
    final bool canEditForm =
        _submissionData == null || statusSaatIni == 'revisi';

    // Kumpulan Halaman berdasarkan Menu Sidebar
    final List<Widget> pages = [
      _buildDashboardView(), // Index 0: Dashboard Depan
      // Index 1: Menu Isi Pengajuan (Form Stepper)
      canEditForm
          ? UktSubmissionForm(
              onSuccess: () {
                // Jika form sukses di-submit (atau di-update), refresh data
                _fetchDashboardData();
                setState(() => _selectedIndex = 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Berhasil disimpan!',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Form terkunci. Anda sudah mengajukan UKT. Silakan cek menu Status & Hasil.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

      // Index 2: Status/Hasil Pengajuan (Langsung memanggil ResultScreen)
      _submissionData == null
          ? const Center(
              child: Text(
                'Anda belum mengajukan UKT. Silakan isi form terlebih dahulu.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ResultScreen(
              golongan:
                  _submissionData!['rekomendasi_golongan'] ?? 'Belum Diproses',
              skor: (_submissionData!['skor_akhir'] as num).toDouble(),
              status: _submissionData!['status_pengajuan'] ?? 'submitted',
              keteranganReviewer:
                  _submissionData!['keterangan_reviewer'], // Mengirim catatan reviewer
            ),

      // Index 3: Placeholder Banding (Diarahkan ke Hasil)
      const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Pengajuan Banding dapat dilakukan melalui menu "Status & Hasil UKT".',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Portal UKT Mahasiswa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // MENGUBAH JADI MODE SIDEBAR (DRAWER)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade800),
              accountName: Text(
                _namaMahasiswa,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(supabase.auth.currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.assignment,
              title: 'Isi Pengajuan UKT',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.access_time_filled,
              title: 'Status & Hasil UKT',
              index: 2,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_selectedIndex],
    );
  }

  // Komponen Sidebar Item
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade800 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Tutup sidebar setelah diklik
      },
    );
  }

  // ===========================================================================
  // TAMPILAN DASHBOARD UTAMA
  // ===========================================================================
  Widget _buildDashboardView() {
    // Ekstrak Data
    final status = _submissionData?['status_pengajuan'] ?? 'Belum Mengajukan';
    final golongan = _submissionData?['rekomendasi_golongan'] ?? '-';
    final skor = _submissionData?['skor_akhir']?.toString() ?? '-';

    // Tentukan tahap saat ini (1 sampai 5)
    int currentStep = 1;
    if (_submissionData != null) {
      if (status == 'submitted') currentStep = 3;
      if (status == 'banding') currentStep = 4;
      if (status == 'revisi') currentStep = 1; // Kembali ke tahap isi data
      if (status == 'approved') currentStep = 5;
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ucapan Selamat Datang
            Text(
              'Halo, $_namaMahasiswa! 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Selamat datang di Portal Penentuan UKT Terpadu.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 2. Kartu Ringkasan (Status, Golongan, Skor)
            _buildSummaryCards(status, golongan, skor),
            const SizedBox(height: 30),

            // 3. Indikator Tahapan (Visual Stepper)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alur Pengajuan UKT Anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildProgressTimeline(currentStep),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 4. Tombol Aksi Utama
            if (_submissionData == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'MULAI PENGAJUAN BARU',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => setState(() => _selectedIndex = 1),
                ),
              )
            else if (status == 'revisi')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.edit_document),
                  label: const Text(
                    'PERBARUI DATA UKT (REVISI)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => setState(() => _selectedIndex = 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget Pembuat Kartu Ringkasan
  Widget _buildSummaryCards(String status, String golongan, String skor) {
    // Tentukan warna status
    Color statusColor = Colors.blue;
    if (status == 'banding') statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'revisi') statusColor = Colors.purple;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                'Status Pengajuan',
                status,
                Icons.info_outline,
                statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                'Golongan UKT',
                golongan,
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _infoCard(
            'Skor Sistem SAW',
            skor,
            Icons.analytics,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembuat Alur Visual
  Widget _buildProgressTimeline(int currentStep) {
    final steps = [
      'Isi Data',
      'Upload\nDokumen',
      'Terkirim',
      'Validasi',
      'Hasil\nFinal',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        int stepNumber = index + 1;
        bool isCompleted = stepNumber < currentStep;
        bool isActive = stepNumber == currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0
                          ? Colors.transparent
                          : (isCompleted || isActive
                                ? Colors.blue.shade800
                                : Colors.grey.shade300),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.blue.shade800
                          : (isActive
                                ? Colors.blue.shade100
                                : Colors.grey.shade200),
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: Colors.blue.shade800, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '$stepNumber',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.blue.shade800
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (isCompleted
                                ? Colors.blue.shade800
                                : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.blue.shade800 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
