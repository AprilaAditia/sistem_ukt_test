// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sistem_ukt_test/features/admin/manage_weight.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'manage_users.dart';


class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Menu Utama Administrator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Tombol Menu 1: Kelola Pengguna
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageUsers()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.people_alt, color: Colors.white, size: 30),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kelola Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Tambah user, atur hak akses (Role), dan hapus akun.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Tombol Menu 2: Kelola Bobot SAW
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageWeights()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.balance, color: Colors.white, size: 30),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kelola Bobot Kriteria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Atur persentase bobot SAW untuk 10 variabel UKT.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
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