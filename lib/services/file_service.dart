import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileService {
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // 1. Fungsi Buka Kamera & Catat GPS
  Future<Map<String, dynamic>?> ambilFotoRumah() async {
    try {
      // Cek Izin GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return null; 
        }
      }
      
      // Ambil Koordinat
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String koordinat = "${position.latitude}, ${position.longitude}";

      // Buka Kamera HP
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      
      if (image != null) {
        return {'file': File(image.path), 'koordinat': koordinat};
      }
    } catch (e) {
      print("Error Kamera/GPS: $e");
    }
    return null;
  }

  // 2. Fungsi Pilih File SKTM dari Galeri
  Future<File?> pilihSKTM() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) return File(image.path);
    } catch (e) {
      print("Error Galeri: $e");
    }
    return null;
  }

  // 3. Fungsi Upload ke Supabase Storage
  Future<String?> uploadDokumen(File file, String folder) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final path = '$folder/$fileName';
      
      await _supabase.storage.from('dokumen_ukt').upload(path, file);
      return _supabase.storage.from('dokumen_ukt').getPublicUrl(path);
    } catch (e) {
      print("Error Upload: $e");
      return null;
    }
  }
}