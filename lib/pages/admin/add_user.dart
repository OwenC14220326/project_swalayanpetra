import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _roleTerpilih = 'user';
  final List<String> _daftarRole = ['admin', 'kasir', 'user'];

  bool _isLoading = false;

  Future<void> _konfirmasiTambahUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Apakah kamu yakin ingin menambahkan user berikut?\n\n'
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
              _simpanUser();
            },
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanUser() async {
    setState(() => _isLoading = true);
    try {
      // 1. Buat user di Firebase Auth
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Simpan data ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'nama_lengkap': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _roleTerpilih,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User berhasil ditambahkan')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal membuat akun';
      if (e.code == 'email-already-in-use') {
        msg = 'Email sudah digunakan';
      } else if (e.code == 'weak-password') {
        msg = 'Password terlalu lemah';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah User')),
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
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (val) =>
                    val == null || val.length < 6 ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Konfirmasi password wajib' : null,
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
                      onPressed: _konfirmasiTambahUser,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan User'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
