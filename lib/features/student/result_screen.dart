import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../auth/login_screen.dart';

class ResultScreen extends StatefulWidget {
  final String golongan;
  final double skor;
  final String status;
  final String? keteranganReviewer; // Tambahan untuk menerima pesan dari reviewer

  const ResultScreen({
    Key? key,
    required this.golongan,
    required this.skor,
    required this.status,
    this.keteranganReviewer,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
  }

  String _getNominalUkt(String golongan) {
    switch (golongan) {
      case 'Golongan I': return 'Rp 500.000';
      case 'Golongan II': return 'Rp 1.000.000';
      case 'Golongan III': return 'Rp 2.000.000';
      case 'Golongan IV': return 'Rp 3.000.000';
      case 'Golongan V': return 'Rp 4.000.000';
      case 'Golongan VI': return 'Rp 5.000.000';
      case 'Golongan VII': return 'Rp 6.000.000';
      case 'Golongan VIII': return 'Rp 7.500.000';
      default: return 'Sedang Dihitung...';
    }
  }

  Future<void> _tampilkanDialogBanding() async {
    final TextEditingController alasanCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajukan Banding UKT'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Apakah Anda yakin ingin mengajukan banding? Silakan jelaskan alasan Anda secara detail.', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(controller: alasanCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Contoh: Penghasilan orang tua menurun...', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (alasanCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan banding tidak boleh kosong!')));
                  return;
                }
                Navigator.pop(context);
                await _prosesBanding(alasanCtrl.text);
              },
              child: const Text('Kirim Banding', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _prosesBanding(String alasan) async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('ukt_submissions').update({
        'status_pengajuan': 'banding',
        'alasan_banding': alasan,
      }).eq('user_id', userId);

      setState(() => _currentStatus = 'banding');

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan banding berhasil dikirim!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim banding: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.blue;
    String statusText = 'Terkirim / Menunggu Review';
    IconData statusIcon = Icons.access_time_filled;

    if (_currentStatus == 'banding') {
      statusColor = Colors.orange; statusText = 'Sedang Dalam Proses Banding'; statusIcon = Icons.warning_amber_rounded;
    } else if (_currentStatus == 'approved') {
      statusColor = Colors.green; statusText = 'UKT Telah Disetujui Final'; statusIcon = Icons.check_circle;
    } else if (_currentStatus == 'revisi') {
      statusColor = Colors.purple; statusText = 'Banding Diterima - Silakan Revisi Data'; statusIcon = Icons.edit_document;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Penentuan UKT'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, size: 80, color: statusColor),
              const SizedBox(height: 20),
              
              Card(
                elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text('Berdasarkan perhitungan sistem, Anda masuk ke dalam:', style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(widget.golongan, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_getNominalUkt(widget.golongan), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text('Skor SAW: ${widget.skor.toStringAsFixed(2)} / 100', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // BADGE STATUS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Status: $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              // KOTAK KETERANGAN REVIEWER (Jika ditolak atau diberi pesan)
              if (widget.keteranganReviewer != null && widget.keteranganReviewer!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Row(children: [Icon(Icons.message, color: Colors.red, size: 18), SizedBox(width: 8), Text('Catatan Reviewer:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                      const SizedBox(height: 8),
                      Text(widget.keteranganReviewer!, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),

              // TOMBOL BANDING (Hanya muncul jika statusnya 'submitted')
              if (_currentStatus == 'submitted') ...[
                const Text('Merasa hasil ini tidak sesuai dengan kondisi ekonomi Anda?', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                _isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      icon: const Icon(Icons.warning_amber_rounded), label: const Text('AJUKAN BANDING'),
                      onPressed: _tampilkanDialogBanding,
                    ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}