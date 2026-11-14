import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../models/menu_model.dart';
import '../../services/menu_service.dart';
import 'add_edit_menu_screen.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final MenuService _menuService = MenuService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _confirmDelete(BuildContext context, MenuModel menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Menu',
          style: AppTypography.titleMedium
              .copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin ingin menghapus "${menu.name}"? Tindakan ini tidak dapat dibatalkan.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteMenu(menu.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Menu "${menu.name}" berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus menu: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAvailability(MenuModel menu) async {
    try {
      await _menuService.updateMenuAvailability(menu.id, !menu.isAvailable);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status menu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Kelola Menu',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.primaryContainer,
            tooltip: 'Tambah Menu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditMenuScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<MenuModel>>(
        stream: _menuService.streamAllMenuAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryContainer),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snapshot.error}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final menus = snapshot.data ?? [];

          if (menus.isEmpty) {
            return _EmptyState(
              onAddTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditMenuScreen()),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: menus.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final menu = menus[index];
              return _MenuCard(
                menu: menu,
                currencyFormat: _currencyFormat,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditMenuScreen(menu: menu)),
                ),
                onDelete: () => _confirmDelete(context, menu),
                onToggle: () => _toggleAvailability(menu),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditMenuScreen()),
        ),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Menu',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _MenuCard({
    required this.menu,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Colors.orange.shade100;
      case 'minuman':
        return Colors.blue.shade100;
      case 'snack':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _categoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Colors.orange.shade800;
      case 'minuman':
        return Colors.blue.shade800;
      case 'snack':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: menu.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: menu.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.fastfood_rounded,
                            color: AppColors.outline),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.broken_image_rounded,
                            color: AppColors.outline),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceContainerLow,
                      child: const Icon(Icons.fastfood_rounded,
                          color: AppColors.outline, size: 30),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(menu.price),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _categoryColor(menu.category),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          menu.category,
                          style: AppTypography.labelSmall.copyWith(
                            color: _categoryTextColor(menu.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: menu.isAvailable,
                    onChanged: (_) => onToggle(),
                    activeColor: AppColors.primaryContainer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.primaryContainer,
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Hapus',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 56,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada menu',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai tambahkan menu pertama\nuntuk toko Anda',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Menu Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
