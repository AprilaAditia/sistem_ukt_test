import '../core/constants.dart';
import '../models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Fungsi Login
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Cek Role berdasarkan tabel 'profiles'
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}