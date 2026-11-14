import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../kasir/kasir_dashboard.dart';
import '../admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  final List<String> _statusMessages = [
    'Menghubungkan data outlet...',
    'Memuat katalog produk...',
    'Sinkronisasi QRIS siap ✨',
  ];
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    _startStatusCycle();
    _navigate();
  }

  void _startStatusCycle() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _statusIndex = 1);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _statusIndex = 2);
      });
    });
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.init();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.isAdmin) {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Atmospheric blur circles
          Positioned(
            top: -48,
            left: -48,
            child: _blurCircle(256, AppColors.primaryFixedDim.withOpacity(0.4)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            right: -80,
            child: _blurCircle(288, AppColors.secondaryContainer.withOpacity(0.5)),
          ),
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width * 0.33,
            child: _blurCircle(240, AppColors.primaryFixed.withOpacity(0.3)),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top badge
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildStatusBadge(),
                  ),
                ),

                // Logo area
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: _buildLogoSection(),
                      ),
                    ),
                  ),
                ),

                // Bottom spinner + status
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildBottomSection(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: Container(),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withOpacity(0.8),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'SISTEM KASIR SIAP',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.secondary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer aura
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed.withOpacity(0.3),
              ),
            ),
            // Middle aura
            Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withOpacity(0.2),
              ),
            ),
            // Logo box
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryContainer,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.point_of_sale_rounded,
                    color: AppColors.onPrimary,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // App name
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'PosSmart',
              style: AppTypography.headlineLg.copyWith(
                color: AppColors.primaryContainer,
                fontSize: 28,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'Kasir Cerdas, Bisnis Lancar',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.outline,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        // Feature pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _FeaturePill(label: '⚡ Transaksi Cepat'),
            _FeaturePill(label: '🧾 QRIS & Tunai'),
            _FeaturePill(label: '📊 Real-time Sync'),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Spinner
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                  AppColors.primaryContainer.withOpacity(0.9),
                ),
                backgroundColor:
                    AppColors.primaryFixedDim.withOpacity(0.3),
              ),
              const Icon(
                Icons.bolt,
                color: AppColors.primaryContainer,
                size: 18,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessages[_statusIndex],
            key: ValueKey(_statusIndex),
            style: AppTypography.labelSm.copyWith(
              color: AppColors.outline,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: AppColors.outline,
              ),
              const SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                  children: [
                    const TextSpan(text: 'v1.0.0 • Powered by '),
                    TextSpan(
                      text: 'MiomiPay',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
