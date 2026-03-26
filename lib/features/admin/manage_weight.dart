// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ManageWeights extends StatefulWidget {
  const ManageWeights({Key? key}) : super(key: key);

  @override
  _ManageWeightsState createState() => _ManageWeightsState();
}

class _ManageWeightsState extends State<ManageWeights> {
  List<dynamic> _weightsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeights();
  }

  // Mengambil data dari tabel saw_weights di Supabase
  Future<void> _fetchWeights() async {
    try {
      final response = await supabase
          .from('saw_weights')
          .select()
          .order('id', ascending: true); // Urutkan berdasarkan ID
      
      if (mounted) {
        setState(() {
          _weightsList = response;
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

  // Fungsi untuk menyimpan perubahan bobot ke database
  Future<void> _updateWeight(int id, double newBobot) async {
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('saw_weights')
          .update({'bobot': newBobot, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
          
      await _fetchWeights(); // Refresh data setelah berhasil update
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bobot berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui data: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Menampilkan popup untuk mengedit bobot
  void _showEditDialog(Map<String, dynamic> item) {
    final TextEditingController bobotController = 
        TextEditingController(text: item['bobot'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Bobot: ${item['kriteria'].toString().toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masukkan nilai desimal (Contoh: 0.25 untuk 25%)'),
              const SizedBox(height: 12),
              TextField(
                controller: bobotController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Nilai Bobot',
                  border: OutlineInputBorder(),
                ),
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
                final newBobot = double.tryParse(bobotController.text.replaceAll(',', '.'));
                if (newBobot != null) {
                  Navigator.pop(context); // Tutup dialog
                  _updateWeight(item['id'], newBobot); // Jalankan fungsi update
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Format angka tidak valid!')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung total bobot untuk memastikan jumlahnya 1.00 (100%)
    double totalBobot = 0;
    for (var item in _weightsList) {
      totalBobot += (item['bobot'] as num).toDouble();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Bobot Kriteria (SAW)')),
      body: Column(
        children: [
          // Banner Peringatan Total Bobot
          Container(
            padding: const EdgeInsets.all(16),
            color: totalBobot == 1.0 ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bobot Saat Ini:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${(totalBobot * 100).toStringAsFixed(0)}%', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: totalBobot == 1.0 ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (totalBobot != 1.0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Peringatan: Total bobot SAW harus persis 100% (1.00). Silakan sesuaikan kembali nilai di bawah ini.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            
          // List Kriteria
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _weightsList.length,
                    itemBuilder: (context, index) {
                      final item = _weightsList[index];
                      final bobotPersen = ((item['bobot'] as num).toDouble() * 100).toStringAsFixed(0);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(item['kriteria'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Tipe: ${item['tipe'].toString().toUpperCase()} | Bobot: $bobotPersen%'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}