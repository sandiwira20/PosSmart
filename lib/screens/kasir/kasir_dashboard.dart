import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../models/menu_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../services/menu_service.dart';
import '../auth/login_screen.dart';
import 'checkout_screen.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  final _searchController = TextEditingController();
  final _menuService = MenuService();
  final _currencyFmt = NumberFormat('#,###', 'id_ID');
  int _orderCounter = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<MenuProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _orderId =>
      '#ORD-${_orderCounter.toString().padLeft(3, '0')}';

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Keluar', style: AppTypography.headlineMd),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi kasir?',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTypography.labelLg
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusFull),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final kasirName = auth.user?.name ?? 'Kasir';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── AppBar ─────────────────────────────────────────────
          _buildAppBar(kasirName),

          // ── Status bar ─────────────────────────────────────────
          _buildStatusBar(kasirName),

          // ── Main scrollable content ────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildSearchBar(),
                  ),
                ),

                // Category chips
                SliverToBoxAdapter(
                  child: _buildCategoryChips(menuProvider),
                ),

                // Menu grid via StreamBuilder
                StreamBuilder<List<MenuModel>>(
                  stream: _menuService.streamMenu(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  size: 48, color: AppColors.outlineVariant),
                              const SizedBox(height: 12),
                              Text('Gagal memuat menu',
                                  style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      );
                    }

                    final allMenus = snapshot.data ?? [];

                    // Sync to provider for filtering
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        context.read<MenuProvider>().setMenus(allMenus);
                      }
                    });

                    final filtered = menuProvider.menus;

                    if (filtered.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.restaurant_menu_rounded,
                                  size: 56, color: AppColors.outlineVariant),
                              const SizedBox(height: 12),
                              Text('Menu tidak ditemukan',
                                  style: AppTypography.titleMd.copyWith(
                                      color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text('Coba kategori atau kata kunci lain',
                                  style: AppTypography.bodySm),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        cart.isEmpty ? 24 : 200,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _MenuCard(menu: filtered[index]),
                          childCount: filtered.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Bottom Cart Panel ──────────────────────────────────
          if (!cart.isEmpty)
            _BottomCartPanel(
              cart: cart,
              currencyFmt: _currencyFmt,
              orderId: _orderId,
              onCheckout: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String kasirName) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Brand
          RichText(
            text: const TextSpan(
              text: 'Pos',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              children: [
                TextSpan(
                  text: 'Smart',
                  style: TextStyle(color: AppColors.primaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Kasir badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Text(
              'Kasir',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              kasirName,
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Notification icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.onSurfaceVariant,
            iconSize: 22,
            onPressed: () {},
          ),
          // Logout icon
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.error,
            iconSize: 22,
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String kasirName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Shift Aktif • $kasirName',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Text(
              _orderId,
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodyMd,
        decoration: InputDecoration(
          hintText: 'Cari makanan atau minuman...',
          hintStyle:
              AppTypography.bodyMd.copyWith(color: AppColors.outline),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.outline, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.outline, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context.read<MenuProvider>().setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(MenuProvider menuProvider) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: AppConstants.menuCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = AppConstants.menuCategories[index];
          final isSelected = menuProvider.selectedCategory == cat;
          return GestureDetector(
            onTap: () =>
                context.read<MenuProvider>().setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.outlineVariant,
                ),
              ),
              child: Text(
                cat,
                style: AppTypography.labelMd.copyWith(
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Menu Card ──────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  static final _fmt = NumberFormat('#,###', 'id_ID');

  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.getQuantity(menu.id);
    final inCart = qty > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                menu.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: menu.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.primaryFixed,
                          child: const Center(
                            child: Icon(Icons.fastfood_rounded,
                                color: AppColors.primaryFixedDim,
                                size: 36),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primaryFixed,
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: AppColors.primaryFixedDim,
                                size: 36),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryFixed,
                        child: const Center(
                          child: Icon(Icons.fastfood_rounded,
                              color: AppColors.primaryFixedDim, size: 40),
                        ),
                      ),
                // In-cart indicator
                if (inCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull),
                      ),
                      child: Text(
                        '${qty}x',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.onPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: AppTypography.labelLg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_fmt.format(menu.price)}',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Quantity controls or Add button
                if (inCart)
                  _QtyControl(menu: menu, qty: qty)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusFull),
                        ),
                      ),
                      onPressed: () =>
                          context.read<CartProvider>().addItem(menu),
                      icon: const Icon(Icons.add_rounded,
                          size: 16, color: AppColors.onPrimary),
                      label: const Text(
                        'Tambah',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final MenuModel menu;
  final int qty;

  const _QtyControl({required this.menu, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleBtn(
          icon: Icons.remove_rounded,
          onTap: () =>
              context.read<CartProvider>().removeItem(menu.id),
          color: AppColors.error,
        ),
        Expanded(
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: AppTypography.titleMd,
          ),
        ),
        _CircleBtn(
          icon: Icons.add_rounded,
          onTap: () => context.read<CartProvider>().addItem(menu),
          color: AppColors.primaryContainer,
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Bottom Cart Panel ──────────────────────────────────────────────────────

class _BottomCartPanel extends StatelessWidget {
  final CartProvider cart;
  final NumberFormat currencyFmt;
  final String orderId;
  final VoidCallback onCheckout;

  const _BottomCartPanel({
    required this.cart,
    required this.currencyFmt,
    required this.orderId,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      color: AppColors.primaryContainer, size: 20),
                  const SizedBox(width: 6),
                  const Text('Pesanan Aktif',
                      style: AppTypography.titleMd),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusFull),
                    ),
                    child: Text(
                      '${cart.totalItems}',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    onPressed: () => context.read<CartProvider>().clearCart(),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.error),
                    label: Text(
                      'Reset',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Cart items list (max ~160 height)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final item = cart.items[i];
                    return Row(
                      children: [
                        // Mini thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.menu.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: item.menu.imageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: AppColors.primaryFixed,
                                    child: const Icon(
                                        Icons.fastfood_rounded,
                                        size: 20,
                                        color: AppColors.primaryFixedDim),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: AppColors.primaryFixed,
                                  child: const Icon(Icons.fastfood_rounded,
                                      size: 20,
                                      color: AppColors.primaryFixedDim),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.menu.name,
                                  style: AppTypography.labelMd,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                'Rp ${currencyFmt.format(item.menu.price)}',
                                style: AppTypography.bodySm,
                              ),
                            ],
                          ),
                        ),
                        // Compact qty controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SmallQtyBtn(
                              icon: Icons.remove_rounded,
                              onTap: () => context
                                  .read<CartProvider>()
                                  .removeItem(item.menu.id),
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text('${item.quantity}',
                                style: AppTypography.titleMd),
                            const SizedBox(width: 6),
                            _SmallQtyBtn(
                              icon: Icons.add_rounded,
                              onTap: () => context
                                  .read<CartProvider>()
                                  .addItem(item.menu),
                              color: AppColors.primaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 72,
                          child: Text(
                            'Rp ${currencyFmt.format(item.subtotal)}',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              const Divider(color: AppColors.outlineVariant, height: 1),
              const SizedBox(height: 10),

              // Totals
              Row(
                children: [
                  Text('Subtotal',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const Spacer(),
                  Text('Rp ${currencyFmt.format(cart.subtotal)}',
                      style: AppTypography.bodyMd),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('Total',
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    'Rp ${currencyFmt.format(cart.total)}',
                    style: AppTypography.titleMd.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusFull),
                    ),
                  ),
                  onPressed: onCheckout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_checkout_rounded,
                          color: AppColors.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'LANJUT CHECKOUT (Rp ${currencyFmt.format(cart.total)})',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.onPrimary, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _SmallQtyBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
