import 'dart:io';
import 'package:flutter/material.dart';
// Sesuaikan jumlah titik (../) jika posisi file services/core Anda berbeda
import '../../core/constants.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import '../../models/ukt_submission.dart'; // Sesuai dengan struktur folder Anda

class UktSubmissionForm extends StatefulWidget {
  final VoidCallback onSuccess; 

  const UktSubmissionForm({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<UktSubmissionForm> createState() => _UktSubmissionFormState();
}

class _UktSubmissionFormState extends State<UktSubmissionForm> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  final _fileService = FileService();
  bool _isLoading = false;

  // Controllers Data Keluarga
  final _penghasilanAyahCtrl = TextEditingController();
  final _penghasilanIbuCtrl = TextEditingController(text: '0');
  final _tanggunganCtrl = TextEditingController();
  String? _pekerjaanAyahVal;
  String? _pekerjaanIbuVal;

  // Controllers Data Aset
  String? _statusRumahVal;
  final _luasTanahCtrl = TextEditingController();
  final _pbbCtrl = TextEditingController();
  String? _punyaKendaraanVal = 'Tidak';
  String? _jenisKendaraanVal;
  final _jmlKendaraanCtrl = TextEditingController(text: '0');

  // Controllers Finansial
  final _cicilanCtrl = TextEditingController(text: '0');
  final _listrikCtrl = TextEditingController();
  final _airCtrl = TextEditingController();

  // Dokumen & Lokasi
  File? _fotoRumah;
  String _koordinat = "";
  File? _sktm;

  final listPekerjaan = ['PNS', 'TNI/Polri', 'Pegawai BUMN', 'Karyawan Swasta', 'Wiraswasta', 'Ibu Rumah Tangga', 'Lainnya'];

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pekerjaanAyahVal == null || _pekerjaanIbuVal == null || _statusRumahVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih semua dropdown!')));
      return;
    }
    if (_fotoRumah == null || _sktm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajib melampirkan Foto Rumah dan SKTM!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser!.id;

      // 1. Upload Gambar
      String? urlRumah = await _fileService.uploadDokumen(_fotoRumah!, 'foto_rumah');
      String? urlSktm = await _fileService.uploadDokumen(_sktm!, 'sktm');
      if (urlRumah == null || urlSktm == null) throw Exception("Gagal mengunggah dokumen");

      // 2. Bungkus ke Model
      final submission = UktSubmission(
        userId: userId,
        penghasilanAyah: double.parse(_penghasilanAyahCtrl.text),
        penghasilanIbu: double.parse(_penghasilanIbuCtrl.text),
        jumlahTanggungan: int.parse(_tanggunganCtrl.text),
        pekerjaanAyah: _pekerjaanAyahVal!,
        pekerjaanIbu: _pekerjaanIbuVal!,
        statusRumah: _statusRumahVal!,
        luasTanah: int.parse(_luasTanahCtrl.text),
        nilaiPbb: double.parse(_pbbCtrl.text),
        cicilanHutang: double.parse(_cicilanCtrl.text),
        punyaKendaraan: _punyaKendaraanVal!,
        jenisKendaraan: _jenisKendaraanVal,
        jumlahKendaraan: int.parse(_jmlKendaraanCtrl.text),
        tagihanListrik: double.parse(_listrikCtrl.text),
        tagihanAir: double.parse(_airCtrl.text),
        fotoRumahUrl: urlRumah,
        sktmUrl: urlSktm,
        koordinatLokasi: _koordinat,
      );

      // 3. Simpan ke Supabase 
      await _dbService.submitUktForm(submission);
      
      // Sukses
      widget.onSuccess();

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Mengunggah & Menghitung SAW...')]))
      : Form(
          key: _formKey,
          child: Stepper(
            physics: const ClampingScrollPhysics(),
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
                _submitData();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep -= 1);
            },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 3;
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isLastStep ? Colors.green : Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: details.onStepContinue,
                        child: Text(isLastStep ? 'SIMPAN & HITUNG' : 'LANJUT', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: details.onStepCancel,
                          child: const Text('KEMBALI'),
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
            steps: [
              // TAHAP 1
              Step(isActive: _currentStep >= 0, title: const Text('Keluarga'), content: Column(children: [
                TextFormField(controller: _penghasilanAyahCtrl, decoration: const InputDecoration(labelText: 'Penghasilan Ayah (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: _pekerjaanAyahVal, decoration: const InputDecoration(labelText: 'Pekerjaan Ayah', border: OutlineInputBorder()), items: listPekerjaan.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _pekerjaanAyahVal = val)), const SizedBox(height: 10),
                TextFormField(controller: _penghasilanIbuCtrl, decoration: const InputDecoration(labelText: 'Penghasilan Ibu (Rp) (Isi 0 jika tdk bekerja)', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: _pekerjaanIbuVal, decoration: const InputDecoration(labelText: 'Pekerjaan Ibu', border: OutlineInputBorder()), items: listPekerjaan.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _pekerjaanIbuVal = val)), const SizedBox(height: 10),
                TextFormField(controller: _tanggunganCtrl, decoration: const InputDecoration(labelText: 'Jumlah Tanggungan (Orang)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              ])),

              // TAHAP 2
              Step(isActive: _currentStep >= 1, title: const Text('Aset'), content: Column(children: [
                DropdownButtonFormField<String>(value: _statusRumahVal, decoration: const InputDecoration(labelText: 'Status Rumah', border: OutlineInputBorder()), items: ['Milik Sendiri', 'Sewa/Kontrak', 'Numpang/Keluarga'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _statusRumahVal = val)), const SizedBox(height: 10),
                TextFormField(controller: _luasTanahCtrl, decoration: const InputDecoration(labelText: 'Luas Tanah (M2)', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 10),
                TextFormField(controller: _pbbCtrl, decoration: const InputDecoration(labelText: 'Pajak PBB (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: _punyaKendaraanVal, decoration: const InputDecoration(labelText: 'Punya Kendaraan?', border: OutlineInputBorder()), items: ['Ya', 'Tidak'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _punyaKendaraanVal = val)),
                if (_punyaKendaraanVal == 'Ya') ...[
                  const SizedBox(height: 10), DropdownButtonFormField<String>(value: _jenisKendaraanVal, decoration: const InputDecoration(labelText: 'Jenis Kendaraan', border: OutlineInputBorder()), items: ['Mobil', 'Mobil & Motor', 'Motor'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _jenisKendaraanVal = val)),
                  const SizedBox(height: 10), TextFormField(controller: _jmlKendaraanCtrl, decoration: const InputDecoration(labelText: 'Jumlah Kendaraan', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                ],
              ])),

              // TAHAP 3
              Step(isActive: _currentStep >= 2, title: const Text('Finansial'), content: Column(children: [
                TextFormField(controller: _cicilanCtrl, decoration: const InputDecoration(labelText: 'Cicilan Hutang Per Bulan (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 10),
                TextFormField(controller: _listrikCtrl, decoration: const InputDecoration(labelText: 'Tagihan Listrik (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 10),
                TextFormField(controller: _airCtrl, decoration: const InputDecoration(labelText: 'Tagihan Air (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              ])),

              // TAHAP 4
              Step(isActive: _currentStep >= 3, title: const Text('Dokumen'), content: Column(children: [
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: Colors.blue.shade50,
                  leading: const Icon(Icons.camera_alt, color: Colors.blue), title: const Text('Foto Depan Rumah (Kamera)'),
                  subtitle: Text(_koordinat.isEmpty ? 'Lokasi GPS Wajib Diaktifkan' : 'GPS: $_koordinat'),
                  trailing: _fotoRumah != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () async {
                    final hasil = await _fileService.ambilFotoRumah();
                    if (hasil != null) setState(() { _fotoRumah = hasil['file']; _koordinat = hasil['koordinat']; });
                  },
                ),
                if (_fotoRumah != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.file(_fotoRumah!, height: 100)),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: Colors.orange.shade50,
                  leading: const Icon(Icons.upload_file, color: Colors.orange), title: const Text('Upload SKTM / Slip Gaji'),
                  subtitle: const Text('Pilih dari galeri foto'), trailing: _sktm != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () async {
                    final file = await _fileService.pilihSKTM();
                    if (file != null) setState(() => _sktm = file);
                  },
                ),
                if (_sktm != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.file(_sktm!, height: 100)),
              ])),
            ],
          ),
        );
  }
}