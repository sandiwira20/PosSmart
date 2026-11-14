import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/miomipay_service.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import 'receipt_success_screen.dart';

class PaymentQrisScreen extends StatefulWidget {
  final String invoiceNumber;
  final double totalAmount;

  const PaymentQrisScreen({
    super.key,
    required this.invoiceNumber,
    required this.totalAmount,
  });

  @override
  State<PaymentQrisScreen> createState() => _PaymentQrisScreenState();
}

class _PaymentQrisScreenState extends State<PaymentQrisScreen> {
  bool _isLoading = true;
  String? _qrImageUrl;
  String? _paymentReference;
  Timer? _timer;
  int _secondsLeft = 900; // 15 menit
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    final res = await MiomiPayService.createPayment(
      invoiceNumber: widget.invoiceNumber,
      amount: widget.totalAmount,
      description: 'Tagihan #${widget.invoiceNumber} PosSmart',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _qrImageUrl = res.qrImageUrl;
        _paymentReference = res.reference;
      });

      // Save initial transaction
      final cart = Provider.of<CartProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      TransactionService.saveTransaction(
        TransactionModel(
          id: 'trx-${DateTime.now().millisecondsSinceEpoch}',
          invoiceNumber: widget.invoiceNumber,
          kasirId: auth.currentUser?.id ?? 'kasir-1',
          kasirName: auth.currentUser?.name ?? 'Kasir Budi',
          items: List.from(cart.items),
          totalAmount: widget.totalAmount,
          status: 'PENDING',
          paymentReference: _paymentReference,
          qrImageUrl: _qrImageUrl,
          createdAt: DateTime.now(),
        ),
      );

      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _confirmPaid() async {
    await TransactionService.updateStatus(widget.invoiceNumber, 'PAID');
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptSuccessScreen(
            invoiceNumber: widget.invoiceNumber,
            totalAmount: widget.totalAmount,
            reference: _paymentReference ?? 'MP-REF-SUCCESS',
            items: List.from(cart.items),
          ),
        ),
      );
      cart.clearCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pembayaran QRIS'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.softBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.deepAccent),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_secondsLeft),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Menghubungi MiomiPay Gateway...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // QR Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepAccent.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Gateway Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 16, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text(
                                'MiomiPay • QRIS Sandbox',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Code Image
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.outlineVariant, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 220,
                              height: 220,
                              child: CachedNetworkImage(
                                imageUrl: _qrImageUrl ?? '',
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(color: AppTheme.primary),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 160,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text(
                          'Pindai QR ini melalui GoPay / E-Wallet',
                          style: TextStyle(fontSize: 13, color: AppTheme.outline),
                        ),
                        const SizedBox(height: 6),

                        // Total Amount
                        Text(
                          currency.format(widget.totalAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepAccent,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Animated Pulse Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Menunggu konfirmasi pembayaran...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulation Button for Sandbox Testing
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shadowColor: AppTheme.success.withOpacity(0.3),
                    ),
                    onPressed: _confirmPaid,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Simulasikan Pembayaran Lunas (PAID)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batalkan Transaksi'),
                  ),
                ],
              ),
            ),
    );
  }
}
