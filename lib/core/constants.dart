import 'package:supabase_flutter/supabase_flutter.dart';

class AppConstants {
  // T
  static const String supabaseUrl = 'https://kervmvmspllrufmwcjkt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlcnZtdm1zcGxscnVmbXdjamt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MTI4MjQsImV4cCI6MjA4NjM4ODgyNH0.fA40Yb985X2jSlm20O3lmqrZySDERKn_88nsoMdx3TI';
}

final supabase = Supabase.instance.client;
