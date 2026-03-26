import '../core/constants.dart';
import '../models/ukt_submission.dart';

class DatabaseService {
  
  // Memastikan fungsi mengembalikan Future<Map<String, dynamic>>
  Future<Map<String, dynamic>> submitUktForm(UktSubmission submission) async {
    try {
      // Menggunakan .toMap() sesuai dengan nama fungsi di model Anda
      final response = await supabase
          .from('ukt_submissions')
          .insert(submission.toMap())
          .select() 
          .single();

      return response; 

    } catch (e) {
      throw Exception('Gagal menyimpan ke database: $e');
    }
  }

}