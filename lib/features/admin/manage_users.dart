// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../../core/constants.dart'; // Memanggil koneksi Supabase

class ManageUsers extends StatefulWidget {
  const ManageUsers({Key? key}) : super(key: key);

  @override
  _ManageUsersState createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  List<dynamic> _userList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Panggil fungsi ambil data saat halaman dibuka
  }

  // Fungsi untuk mengambil data dari tabel 'profiles' di Supabase
  Future<void> _fetchUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false); // Urutkan dari yang terbaru
      
      if (mounted) {
        setState(() {
          _userList = response;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna (User)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Tambah User sedang dikembangkan')),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Pengguna Baru'),
            ),
            const SizedBox(height: 20),
            
            // Area List View Otomatis dari Database
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userList.isEmpty
                      ? const Center(child: Text('Belum ada data pengguna.'))
                      : ListView.builder(
                          itemCount: _userList.length,
                          itemBuilder: (context, index) {
                            final user = _userList[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.person, color: Colors.blue),
                                ),
                                title: Text(
                                  user['nama_lengkap'] ?? 'Tanpa Nama',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Role: ${user['role'].toString().toUpperCase()}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                  
                                  },
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