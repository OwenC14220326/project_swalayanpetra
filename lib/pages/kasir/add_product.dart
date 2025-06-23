import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeSeriController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _fotoController = TextEditingController();

  String _kategoriTerpilih = 'Makanan dan Minuman';
  final List<String> _kategoriList = [
    'Makanan dan Minuman',
    'Produk Rumah Tangga',
    'Produk Kecantikan',
    'Alat Tulis',
    'Kesehatan',
  ];

  bool _isLoading = false;

  Future<void> _tambahProduk() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'nama_product': _namaController.text.trim(),
        'kode_seri': _kodeSeriController.text.trim(),
        'deskripsi_product': _deskripsiController.text.trim(),
        'foto_product': _fotoController.text.trim(),
        'harga_product': double.parse(_hargaController.text),
        'stok_product': int.parse(_stokController.text),
        'kategori_product': _kategoriTerpilih,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiTambahProduk() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Apakah kamu yakin ingin menambahkan produk ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  _tambahProduk();
                },
                child: const Text('Ya, Tambahkan'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeSeriController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Nama tidak boleh kosong'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kodeSeriController,
                decoration: const InputDecoration(
                  labelText: 'Kode Seri Produk',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Kode seri wajib diisi'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fotoController,
                decoration: const InputDecoration(
                  labelText: 'Link Foto Produk (URL)',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Harga tidak valid'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || int.tryParse(value) == null
                            ? 'Stok tidak valid'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _kategoriTerpilih,
                items:
                    _kategoriList
                        .map(
                          (kategori) => DropdownMenuItem(
                            value: kategori,
                            child: Text(kategori),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _kategoriTerpilih = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    onPressed: _konfirmasiTambahProduk,
                    icon: const Icon(Icons.save),
                    label: const Text('Tambah Produk'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
