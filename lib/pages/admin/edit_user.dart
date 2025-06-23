import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditUserPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> userData;

  const EditUserPage({
    super.key,
    required this.docId,
    required this.userData,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _emailController;

  String _roleTerpilih = 'user';
  final List<String> _daftarRole = ['admin', 'kasir', 'user'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.userData;
    _namaController = TextEditingController(text: data['nama_lengkap']);
    _emailController = TextEditingController(text: data['email']);
    _roleTerpilih = data['role'] ?? 'user';
  }

  Future<void> _konfirmasiUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Perubahan'),
        content: Text(
          'Simpan perubahan pada user ini?\n\n'
          'Nama: ${_namaController.text}\n'
          'Email: ${_emailController.text}\n'
          'Role: $_roleTerpilih',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUser();
            },
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
        'nama_lengkap': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _roleTerpilih,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) =>
                    val == null || !val.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _roleTerpilih,
                items: _daftarRole.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _roleTerpilih = val);
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _konfirmasiUpdate,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Perubahan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
