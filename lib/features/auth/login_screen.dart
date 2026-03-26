import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../shared_widgets/custom_button.dart';      // Import Custom Button
import '../../shared_widgets/custom_textfield.dart';   // Import Custom TextField
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleRouter())
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan yang tidak terduga'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // Tambahkan ini agar tidak error 'overflow' saat keyboard muncul
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'SPK UKT', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 40),
              
              // Menggunakan CustomTextField untuk Email
              CustomTextField(
                controller: _emailCtrl, 
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Menggunakan CustomTextField untuk Password
              CustomTextField(
                controller: _passwordCtrl, 
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              // Menggunakan CustomButton
              CustomButton(
                text: 'LOGIN',
                onPressed: _login,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}