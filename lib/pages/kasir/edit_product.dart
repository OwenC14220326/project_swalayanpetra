import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _stokController;
  late TextEditingController _fotoController;
  late TextEditingController _kodeSeriController;

  String _kategoriTerpilih = '';
  final List<String> _kategoriList = [
    'Makanan dan Minuman',
    'Kebersihan',
    'Kecantikan',
    'Alat Tulis',
    'Kesehatan',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.productData;

    _namaController = TextEditingController(text: data['nama_product']);
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
    _kodeSeriController = TextEditingController(text: data['kode_seri']);
    _kategoriTerpilih = data['kategori_product'] ?? _kategoriList.first;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _fotoController.dispose();
    _kodeSeriController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Yakin ingin menyimpan perubahan produk ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Simpan'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.docId)
          .update({
            'nama_product': _namaController.text.trim(),
            'deskripsi_product': _deskripsiController.text.trim(),
            'foto_product': _fotoController.text.trim(),
            'harga_product': double.parse(_hargaController.text),
            'stok_product': int.parse(_stokController.text),
            'kode_seri': _kodeSeriController.text.trim(),
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
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui produk: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF2F4F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_namaController, 'Nama Produk', Icons.label),
              const SizedBox(height: 12),
              _buildTextField(_kodeSeriController, 'Kode Seri', Icons.qr_code),
              const SizedBox(height: 12),
              _buildTextField(
                _deskripsiController,
                'Deskripsi',
                Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _fotoController,
                'Link Foto (URL)',
                Icons.image,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _hargaController,
                'Harga',
                Icons.attach_money,
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Harga tidak valid'
                            : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _stokController,
                'Stok',
                Icons.inventory,
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
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items:
                    _kategoriList
                        .map(
                          (kategori) => DropdownMenuItem(
                            value: kategori,
                            child: Text(kategori),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _kategoriTerpilih = val);
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateProduct,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator:
          validator ??
          (value) =>
              value == null || value.isEmpty
                  ? '$label tidak boleh kosong'
                  : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
