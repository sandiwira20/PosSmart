import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
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
  String? _checkoutUrl;
  Timer? _countdownTimer;
  Timer? _autoPollTimer;
  int _secondsLeft = 900; // 15 menit
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await MiomiPayService.createPayment(
      invoiceNumber: widget.invoiceNumber,
      amount: widget.totalAmount,
      customerName: auth.currentUser?.name ?? 'Pelanggan PosSmart',
      customerEmail: auth.currentUser?.email ?? 'kasir@possmart.com',
      description: 'Tagihan #${widget.invoiceNumber} PosSmart',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _qrImageUrl = res.qrImageUrl;
        _paymentReference = res.reference;
        _checkoutUrl = res.checkoutUrl;
      });

      // Simpan transaksi awal berstatus PENDING ke Firebase Realtime Database
      final cart = Provider.of<CartProvider>(context, listen: false);
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
          checkoutUrl: _checkoutUrl,
          qrString: res.qrString,
          createdAt: DateTime.now(),
        ),
      );

      _startTimer();
      _startAutoDetection();
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Deteksi otomatis secara REALTIME ke API MiomiPay setiap 2 detik
  /// Persis seperti Midtrans tanpa perlu klik tombol manual
  void _startAutoDetection() {
    _autoPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_paymentReference != null) {
        final status = await MiomiPayService.checkPaymentStatus(_paymentReference!);
        if (status.toUpperCase() == 'PAID' && mounted) {
          _onPaymentSuccess();
        }
      }
    });
  }

  void _onPaymentSuccess() async {
    _autoPollTimer?.cancel();
    _countdownTimer?.cancel();

    // Update status transaksi di Firebase menjadi PAID
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
  void dispose() {
    _countdownTimer?.cancel();
    _autoPollTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copyIdentifier() {
    final textToCopy = _checkoutUrl ?? _paymentReference ?? widget.invoiceNumber;
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor tagihan disalin ke clipboard!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pembayaran QRIS'),
        centerTitle: true,
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
                  Text(
                    'Menghubungi MiomiPay Gateway...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  // QR Card (Midtrans Style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 15, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text(
                                'MiomiPay • QRIS Realtime',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

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
                              width: 210,
                              height: 210,
                              child: AppNetworkImage(
                                imageUrl: _qrImageUrl ?? '',
                                fit: BoxFit.contain,
                                errorWidget: const Center(
                                  child: Icon(Icons.qr_code_2_rounded, size: 160, color: AppTheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          'Pindai QRIS menggunakan BCA / GoPay / ShopeePay / Dana',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.outline),
                        ),
                        const SizedBox(height: 8),

                        // Total Amount
                        Text(
                          currency.format(widget.totalAmount),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepAccent,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Invoice number & Copy button
                        InkWell(
                          onTap: _copyIdentifier,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Invoice: #${widget.invoiceNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.outline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Realtime Pulse Status (Overflow Fixed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              Flexible(
                                child: Text(
                                  'Menunggu konfirmasi pembayaran...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Batalkan Transaksi
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.outline,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Batalkan Transaksi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
