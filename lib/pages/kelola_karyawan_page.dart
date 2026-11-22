import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/karyawan.dart';

class KelolaKaryawanPage extends StatefulWidget {
  const KelolaKaryawanPage({super.key});

  @override
  State<KelolaKaryawanPage> createState() => _KelolaKaryawanPageState();
}

class _KelolaKaryawanPageState extends State<KelolaKaryawanPage> {
  List<Karyawan> _karyawanList = [];
  bool _isLoading = true;
  String _activeCashierName = 'Belum Ditentukan';

  @override
  void initState() {
    super.initState();
    _muatDataKaryawan();
  }

  Future<void> _muatDataKaryawan() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final data = await DatabaseHelper.instance.getAllKaryawan();
    if (!mounted) return;
    setState(() {
      _activeCashierName =
          prefs.getString('active_cashier_name') ?? 'Belum Ditentukan';
      _karyawanList = data;
      _isLoading = false;
    });
  }

  Future<void> _setKasirAktif(Karyawan karyawan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_cashier_name', karyawan.namaKaryawan);
    if (!mounted) return;
    setState(() {
      _activeCashierName = karyawan.namaKaryawan;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kasir aktif diubah menjadi ${karyawan.namaKaryawan}.'),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _tampilkanFormKaryawan({Karyawan? karyawan}) {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(
      text: karyawan?.namaKaryawan ?? '',
    );
    final pinController = TextEditingController(
      text: karyawan?.pin ?? '',
    );
    String peranTerpilih = karyawan?.peran ?? 'Kasir';
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                karyawan == null ? 'Tambah Karyawan' : 'Edit Karyawan',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Karyawan',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama karyawan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pinController,
                        obscureText: obscurePin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'PIN (4-6 Digit)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePin
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePin = !obscurePin;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 4) {
                            return 'PIN minimal 4 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: peranTerpilih,
                        decoration: const InputDecoration(
                          labelText: 'Peran / Jabatan',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Kasir',
                            child: Text('Kasir'),
                          ),
                          DropdownMenuItem(
                            value: 'Manajer',
                            child: Text('Manajer'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              peranTerpilih = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final dataBaru = Karyawan(
                      id: karyawan?.id,
                      namaKaryawan: namaController.text.trim(),
                      pin: pinController.text.trim(),
                      peran: peranTerpilih,
                    );

                    if (karyawan == null) {
                      await DatabaseHelper.instance.insertKaryawan(dataBaru);
                    } else {
                      await DatabaseHelper.instance.updateKaryawan(dataBaru);
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _muatDataKaryawan();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _hapusKaryawan(Karyawan karyawan) async {
    if (karyawan.namaKaryawan == _activeCashierName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Karyawan yang sedang berstatus kasir aktif tidak dapat dihapus!',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (karyawan.id != null) {
      await DatabaseHelper.instance.deleteKaryawan(karyawan.id!);
      _muatDataKaryawan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kelola Karyawan & Shift',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFFFBBF24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KASIR AKTIF SAAT INI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _activeCashierName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _karyawanList.isEmpty
                    ? const Center(child: Text('Belum ada data karyawan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _karyawanList.length,
                        itemBuilder: (context, index) {
                          final k = _karyawanList[index];
                          final isAktif = k.namaKaryawan == _activeCashierName;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAktif
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFE2E8F0),
                                child: Icon(
                                  Icons.person,
                                  color: isAktif ? Colors.white : Colors.black87,
                                ),
                              ),
                              title: Text(
                                k.namaKaryawan,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Peran: ${k.peran}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isAktif ? Icons.star : Icons.star_border,
                                      color: isAktif
                                          ? Colors.amber.shade700
                                          : Colors.grey,
                                    ),
                                    tooltip: 'Jadikan Kasir Aktif',
                                    onPressed: () => _setKasirAktif(k),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    onPressed: () =>
                                        _tampilkanFormKaryawan(karyawan: k),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _hapusKaryawan(k),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilkanFormKaryawan(),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Karyawan'),
      ),
    );
  }
}