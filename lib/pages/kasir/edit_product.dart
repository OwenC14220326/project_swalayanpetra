import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditProductPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> productData;

  const EditProductPage({
    super.key,
    required this.docId,
    required this.productData,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _kodeSeriController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _stokController;
  late TextEditingController _fotoController;

  String _kategoriTerpilih = '';
  final List<String> _kategoriList = [
    'Makanan dan Minuman',
    'Produk Rumah Tangga',
    'Produk Kecantikan',
    'Alat Tulis',
    'Kesehatan',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final data = widget.productData;
    _namaController = TextEditingController(text: data['nama_product']);
    _kodeSeriController = TextEditingController(text: data['kode_seri']);
    _deskripsiController = TextEditingController(
      text: data['deskripsi_product'],
    );
    _fotoController = TextEditingController(text: data['foto_product']);
    _hargaController = TextEditingController(
      text: data['harga_product'].toString(),
    );
    _stokController = TextEditingController(
      text: data['stok_product'].toString(),
    );
    _kategoriTerpilih = data['kategori_product'] ?? _kategoriList[0];
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.docId)
          .update({
            'nama_product': _namaController.text.trim(),
            'kode_seri': _kodeSeriController.text.trim(),
            'deskripsi_product': _deskripsiController.text.trim(),
            'foto_product': _fotoController.text.trim(),
            'harga_product': double.parse(_hargaController.text),
            'stok_product': int.parse(_stokController.text),
            'kategori_product': _kategoriTerpilih,
            'updated_at': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Apakah kamu yakin ingin menyimpan perubahan produk ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  _updateProduct();
                },
                child: const Text('Ya, Simpan'),
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
      appBar: AppBar(title: const Text('Edit Produk')),
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
                  : ElevatedButton(
                    onPressed: _konfirmasiUpdate,
                    child: const Text('Simpan Perubahan'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
