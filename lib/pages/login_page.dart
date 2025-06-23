import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_page.dart';
import 'admin/home_page.dart' as admin;
import 'kasir/home_page.dart' as kasir;
import 'user/home_page.dart' as user;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    setState(() => _isLoading = true);
    try {
      // 1. Login Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Ambil UID
      final uid = userCredential.user!.uid;

      // 3. Ambil dokumen user dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("Data user tidak ditemukan di Firestore.");
      }

      final role = userDoc.data()?['role'];

      // 4. Navigasi sesuai role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const admin.AdminHomePage()),
        );
      } else if (role == 'kasir') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const kasir.KasirHomePage()),
        );
      } else if (role == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const user.UserHomePage()),
        );
      } else {
        throw Exception("Role tidak valid: $role");
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login gagal';
      if (e.code == 'user-not-found') {
        errorMsg = 'Akun tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Password salah';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginUser,
                    child: const Text("Login"),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: const Text("Belum punya akun? Daftar"),
            ),
          ],
        ),
      ),
    );
  }
}
