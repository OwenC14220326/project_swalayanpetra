import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTransaksiPage extends StatefulWidget {
  const AddTransaksiPage({super.key});

  @override
  State<AddTransaksiPage> createState() => _AddTransaksiPageState();
}

class _AddTransaksiPageState extends State<AddTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _kodeSeriController = TextEditingController();

  String? _selectedProductId;
  double _hargaProduk = 0.0;
  String _namaProduk = '';
  int _stokTersedia = 0;

  List<DocumentSnapshot> _produkList = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  Future<void> _fetchProduk() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _produkList = snapshot.docs;
    });
  }

  void _onPilihProduk(String? idProduct) {
    if (idProduct == null) return;

    final selectedDoc =
        _produkList.firstWhere((doc) => doc.id == idProduct, orElse: () => throw Exception());

    final data = selectedDoc.data() as Map<String, dynamic>;
    setState(() {
      _selectedProductId = idProduct;
      _hargaProduk = double.tryParse(data['harga_product'].toString()) ?? 0.0;
      _namaProduk = data['nama_product'] ?? '';
      _stokTersedia = int.tryParse(data['stok_product'].toString()) ?? 0;
    });
  }

  void _cariProdukDariKodeSeri() {
    final inputKode = _kodeSeriController.text.trim().toLowerCase();

    final matching = _produkList.firstWhere(
      (doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['kode_seri'] ?? '').toString().toLowerCase() == inputKode;
      },
      orElse: () => throw Exception('Kode tidak ditemukan'),
    );

    final data = matching.data() as Map<String, dynamic>;
    setState(() {
      _selectedProductId = matching.id;
      _namaProduk = data['nama_product'];
      _hargaProduk = double.tryParse(data['harga_product'].toString()) ?? 0.0;
      _stokTersedia = int.tryParse(data['stok_product'].toString()) ?? 0;
    });
  }

  Future<void> _konfirmasiDanSimpanTransaksi() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) return;

    final jumlah = int.tryParse(_jumlahController.text) ?? 0;
    final total = jumlah * _hargaProduk;

    if (jumlah > _stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok tidak cukup. Stok tersedia: $_stokTersedia')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Transaksi'),
        content: Text('Tambahkan transaksi ini?\n\n'
            'Produk: $_namaProduk\n'
            'Jumlah: $jumlah\n'
            'Harga satuan: $_hargaProduk\n'
            'Total: Rp $total'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simpanTransaksiDanUpdateStok(jumlah, total);
            },
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanTransaksiDanUpdateStok(int jumlah, double total) async {
    setState(() => _isLoading = true);
    final transaksi = FirebaseFirestore.instance.collection('transactions');
    final produk = FirebaseFirestore.instance.collection('products').doc(_selectedProductId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Kurangi stok
        transaction.update(produk, {
          'stok_product': _stokTersedia - jumlah,
        });

        // Tambah transaksi
        transaction.set(transaksi.doc(), {
          'id_product': _selectedProductId,
          'jumlah_product': jumlah,
          'total_harga': total,
          'waktu_transaksi': FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _kodeSeriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('🔍 Cari Berdasarkan Kode Seri'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kodeSeriController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: PRD-00123',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _cariProdukDariKodeSeri,
                  )
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                items: _produkList.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('${data['nama_product']} (${data['kode_seri']})'),
                  );
                }).toList(),
                onChanged: _onPilihProduk,
                decoration: const InputDecoration(labelText: 'Pilih Produk'),
              ),
              const SizedBox(height: 16),
              Text('Harga Satuan: Rp $_hargaProduk'),
              Text('Stok Tersedia: $_stokTersedia'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Produk'),
                validator: (val) =>
                    val == null || int.tryParse(val) == null ? 'Jumlah tidak valid' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _konfirmasiDanSimpanTransaksi,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Transaksi'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
