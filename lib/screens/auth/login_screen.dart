import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../kasir/kasir_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _selectedRole = 'kasir'; // 'kasir' or 'admin'

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user!;
      if (user.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KasirDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login gagal.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER WAVE ---
            _buildHeader(size),

            // --- FORM CARD (overlapping) ---
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFormCard(auth),
              ),
            ),

            // --- FOOTER ---
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.38,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer,
            AppColors.tertiaryContainer,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -48,
            right: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -32,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.06),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.point_of_sale_rounded,
                          color: AppColors.onPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'POSSMART',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Kasir Cerdas, Bisnis Lancar',
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Sistem kasir untuk gerai dan toko Anda',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.primaryFixed.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avatar illustration
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primaryContainer,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Text('Selamat Datang',
                    style: AppTypography.headlineLg),
                const SizedBox(width: 8),
                const Text('👋', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Masuk ke akun kasir atau admin Anda',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.outline,
              ),
            ),

            const SizedBox(height: 20),

            // Role toggle
            _buildRoleToggle(),

            const SizedBox(height: 20),

            // Email field
            _buildLabel('Email atau ID Pengguna'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  _selectedRole == 'kasir'
                      ? Icons.account_circle_outlined
                      : Icons.manage_accounts_outlined,
                  color: AppColors.outline,
                ),
                hintText: _selectedRole == 'kasir'
                    ? 'kasir@possmart.id'
                    : 'admin@possmart.id',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Email tidak boleh kosong' : null,
            ),

            const SizedBox(height: 16),

            // Password field
            _buildLabel('Kata Sandi'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.outline,
                ),
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.outline,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Password min 6 karakter' : null,
            ),

            const SizedBox(height: 12),

            // Remember me & Forgot
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                  activeColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text('Ingat saya', style: AppTypography.bodySm),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lupa Password?',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Masuk Sekarang',
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.onPrimary, size: 20),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Shift info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timelapse_rounded,
                      size: 18,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift Pagi Aktif (08:00 - 16:00)',
                          style: AppTypography.labelMd,
                        ),
                        Text(
                          'PosSmart • Sistem Kasir Digital',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          _roleButton('kasir', Icons.badge_outlined, 'Kasir'),
          _roleButton(
              'admin', Icons.admin_panel_settings_outlined, 'Admin'),
        ],
      ),
    );
  }

  Widget _roleButton(String role, IconData icon, String label) {
    final isActive = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.3),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLg.copyWith(
                  color: isActive
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMd.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 15,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'Akses terenkripsi aman • Firebase Auth',
              style: AppTypography.labelSm,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'PosSmart v1.0.0',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.outlineVariant,
          ),
        ),
      ],
    );
  }
}
