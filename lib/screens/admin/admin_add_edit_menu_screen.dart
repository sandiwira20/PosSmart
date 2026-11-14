import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';

class AdminAddEditMenuScreen extends StatefulWidget {
  final MenuModel? menu;

  const AdminAddEditMenuScreen({super.key, this.menu});

  @override
  State<AdminAddEditMenuScreen> createState() => _AdminAddEditMenuScreenState();
}

class _AdminAddEditMenuScreenState extends State<AdminAddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;
  String _category = 'Makanan';
  bool _isAvailable = true;

  final List<String> _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menu?.name ?? '');
    _priceController = TextEditingController(
      text: widget.menu != null ? widget.menu!.price.toInt().toString() : '',
    );
    _imageController = TextEditingController(
      text: widget.menu?.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
    );
    _descController = TextEditingController(text: widget.menu?.description ?? '');
    _category = widget.menu?.category ?? 'Makanan';
    _isAvailable = widget.menu?.isAvailable ?? true;
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final image = _imageController.text.trim();
    final desc = _descController.text.trim();

    final menuProv = Provider.of<MenuProvider>(context, listen: false);

    if (widget.menu == null) {
      // Create
      final newMenu = MenuModel(
        id: 'menu-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: _category,
        price: price,
        imageUrl: image,
        description: desc,
        isAvailable: _isAvailable,
      );
      await menuProv.addMenu(newMenu);
    } else {
      // Update
      final updated = widget.menu!.copyWith(
        name: name,
        category: _category,
        price: price,
        imageUrl: image,
        description: desc,
        isAvailable: _isAvailable,
      );
      await menuProv.updateMenu(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.menu == null ? 'Menu baru ditambahkan!' : 'Menu berhasil diupdate!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menu != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Menu' : 'Tambah Menu Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview Card
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryLight, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: _imageController.text,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.outline),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Preview Foto Produk',
                      style: TextStyle(fontSize: 12, color: AppTheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Image URL input
              const Text('URL Foto Produk', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imageController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Name input
              const Text('Nama Menu', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty ? 'Nama menu wajib diisi' : null,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Nasi Goreng Spesial',
                  prefixIcon: Icon(Icons.restaurant, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Price input
              const Text('Harga Jual (Rp)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Harga wajib diisi' : null,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 20000',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.outline),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              // Description input
              const Text('Deskripsi (Opsional)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Keterangan menu...',
                  prefixIcon: Icon(Icons.notes, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Availability Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Stok Tersedia', style: TextStyle(fontWeight: FontWeight.w600)),
                    Switch(
                      value: _isAvailable,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _saveMenu,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(isEdit ? 'Simpan Perubahan' : 'Tambah Menu ke Database'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
