import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../auth/login_screen.dart';
import 'verify_document.dart';

class ReviewerDashboard extends StatefulWidget {
  const ReviewerDashboard({Key? key}) : super(key: key);

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  String _namaReviewer = 'Reviewer';
  List<dynamic> _submissions = [];

  // Variabel untuk menghitung Statistik
  int _jmlPending = 0;
  int _jmlBanding = 0;
  int _jmlApproved = 0;
  int _jmlRevisi = 0; // Tambahan untuk menghitung data yang direvisi

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      // Ambil Nama Reviewer
      final profile = await supabase
          .from('profiles')
          .select('nama_lengkap')
          .eq('id', userId)
          .single();

      // Ambil Seluruh Data Pengajuan
      final response = await supabase
          .from('ukt_submissions')
          .select('*, profiles:user_id(nama_lengkap)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _namaReviewer = profile['nama_lengkap'] ?? 'Reviewer';
          _submissions = response;

          // Hitung Statistik
          _jmlPending = _submissions
              .where((s) => s['status_pengajuan'] == 'submitted')
              .length;
          _jmlBanding = _submissions
              .where((s) => s['status_pengajuan'] == 'banding')
              .length;
          _jmlApproved = _submissions
              .where((s) => s['status_pengajuan'] == 'approved')
              .length;
          _jmlRevisi = _submissions
              .where((s) => s['status_pengajuan'] == 'revisi')
              .length; // Logika perhitungan revisi

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
    if (mounted)
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Menambahkan halaman untuk status revisi di index ke-3
    final List<Widget> pages = [
      _buildDashboardView(),
      _buildSubmissionListView('submitted'), // Index 1: Pending
      _buildSubmissionListView('banding'), // Index 2: Banding
      _buildSubmissionListView('revisi'), // Index 3: Revisi
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Portal Reviewer UKT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      // SIDEBAR MENU
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo.shade800),
              accountName: Text(
                _namaReviewer,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(supabase.auth.currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                  color: Colors.indigo,
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.assignment_late,
              title: 'Antrean Validasi',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.warning_amber_rounded,
              title: 'Review Banding',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.edit_document,
              title: 'Dalam Revisi',
              index: 3,
            ), // Menu Baru
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.indigo.shade800 : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.indigo.shade800 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.indigo.shade50,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // ===========================================================================
  // LAYAR 1: DASHBOARD DEPAN (Ringkasan)
  // ===========================================================================
  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $_namaReviewer! ',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Berikut adalah ringkasan data pengajuan UKT saat ini.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // KARTU STATISTIK (SEKARANG MENJADI 2x2 GRID)
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    'Menunggu Validasi',
                    _jmlPending.toString(),
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    'Banding Masuk',
                    _jmlBanding.toString(),
                    Icons.warning_amber_rounded,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    'Sedang Direvisi',
                    _jmlRevisi.toString(),
                    Icons.edit_document,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    'Telah Disetujui',
                    _jmlApproved.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              'Seluruh Pengajuan Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // LIST VIEW SEMUA DATA (Mini Version)
            _submissions.isEmpty
                ? const Center(child: Text('Belum ada pengajuan masuk.'))
                : Column(
                    children: _submissions
                        .take(5)
                        .map((data) => _buildSubmissionCard(data))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LAYAR 2, 3 & 4: DAFTAR ANTREAN SPESIFIK
  // ===========================================================================
  Widget _buildSubmissionListView(String filterStatus) {
    final filteredData = _submissions
        .where((s) => s['status_pengajuan'] == filterStatus)
        .toList();

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: filteredData.isEmpty
          ? const Center(child: Text('Tidak ada data dalam kategori ini.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredData.length,
              itemBuilder: (context, index) =>
                  _buildSubmissionCard(filteredData[index]),
            ),
    );
  }

  // WIDGET KARTU PENGAJUAN (Dipakai di Layar 1, 2, 3, 4)
  Widget _buildSubmissionCard(Map<String, dynamic> data) {
    final nama = data['profiles']?['nama_lengkap'] ?? 'Mahasiswa';
    final status = data['status_pengajuan'] ?? 'submitted';

    // Pewarnaan dinamis berdasarkan status
    final isBanding = status == 'banding';
    final isApproved = status == 'approved';
    final isRevisi = status == 'revisi';

    Color statusColor = isBanding
        ? Colors.orange
        : (isApproved
              ? Colors.green
              : (isRevisi ? Colors.purple : Colors.blue));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Golongan: ${data['rekomendasi_golongan']} (SAW: ${data['skor_akhir']})',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          // Buka Layar Detail, lalu tunggu jika reviewer melakukan perubahan data
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VerifyDocumentScreen(data: data)),
          );
          if (result == true) {
            _fetchDashboardData();
          }
        },
      ),
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
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
