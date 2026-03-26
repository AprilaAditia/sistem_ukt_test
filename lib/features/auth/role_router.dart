// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

// Import Dashboard Masing-masing Role
import '../student/student_home.dart';
import '../admin/admin_dashboard.dart';
import '../reviewer/reviewer_dashboard.dart';
import '../committee/committee_dashboard.dart';
import '../management/analytics_dashboard.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({Key? key}) : super(key: key);

  @override
  _RoleRouterState createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Widget _targetScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      final profile = await _authService.getUserProfile(session.user.id);
      if (profile != null) {
        if (mounted) {
          setState(() {
            switch (profile.role) {
              case 'mahasiswa': _targetScreen = const StudentHome(); break;
              case 'admin': _targetScreen = const AdminDashboard(); break;
              case 'reviewer': _targetScreen = const ReviewerDashboard(); break;
              case 'panitia': _targetScreen = const CommitteeDashboard(); break;
              case 'management': _targetScreen = const AnalyticsDashboard(); break;
              default: _targetScreen = const LoginScreen();
            }
          });
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _targetScreen;
  }
}