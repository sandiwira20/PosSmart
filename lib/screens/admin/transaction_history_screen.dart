import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionService _transactionService = TransactionService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  final _dayFormat = DateFormat('dd MMM yyyy', 'id_ID');

  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Riwayat Transaksi',
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
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionService.streamTransactions(),
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
                  const Icon(Icons.error_outline_rounded,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data ?? [];
          final today = DateTime.now();
          final todayTransactions = transactions.where((t) {
            final d = t.createdAt;
            return d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }).toList();
          final todayRevenue = todayTransactions
              .where((t) => t.status == AppConstants.statusPaid)
              .fold<double>(0, (sum, t) => sum + t.total);

          if (transactions.isEmpty) {
            return Column(
              children: [
                _SummaryCard(
                  transactionCount: 0,
                  totalRevenue: 0,
                  currencyFormat: _currencyFormat,
                ),
                const Expanded(child: _EmptyState()),
              ],
            );
          }

          return Column(
            children: [
              _SummaryCard(
                transactionCount: todayTransactions.length,
                totalRevenue: todayRevenue,
                currencyFormat: _currencyFormat,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isExpanded = _expandedIds.contains(tx.id);
                    return _TransactionCard(
                      transaction: tx,
                      isExpanded: isExpanded,
                      currencyFormat: _currencyFormat,
                      dateFormat: _dateFormat,
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIds.remove(tx.id);
                          } else {
                            _expandedIds.add(tx.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int transactionCount;
  final double totalRevenue;
  final NumberFormat currencyFormat;

  const _SummaryCard({
    required this.transactionCount,
    required this.totalRevenue,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryContainer, const Color(0xFFFFB347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'Transaksi Hari Ini',
                value: '$transactionCount transaksi',
                icon: Icons.receipt_long_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: Colors.white.withOpacity(0.4),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: _SummaryItem(
                label: 'Total Pendapatan',
                value: currencyFormat.format(totalRevenue),
                icon: Icons.payments_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final bool isExpanded;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.isExpanded,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'EXPIRED':
        return AppColors.error;
      default:
        return AppColors.outline;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.success.withOpacity(0.12);
      case 'PENDING':
        return AppColors.warning.withOpacity(0.15);
      case 'EXPIRED':
        return AppColors.error.withOpacity(0.1);
      default:
        return AppColors.surfaceContainerLow;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'LUNAS';
      case 'PENDING':
        return 'PENDING';
      case 'EXPIRED':
        return 'EXPIRED';
      default:
        return status.toUpperCase();
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Icons.check_circle_rounded;
      case 'PENDING':
        return Icons.hourglass_empty_rounded;
      case 'EXPIRED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = transaction.status;
    final itemCount = transaction.items.fold<int>(
        0, (sum, item) => sum + item.quantity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? AppColors.primaryContainer.withOpacity(0.4)
                : AppColors.surfaceContainer,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${transaction.id.length > 8 ? transaction.id.substring(0, 8).toUpperCase() : transaction.id.toUpperCase()}',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(transaction.createdAt),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBgColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(status),
                                color: _statusColor(status), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(status),
                              style: AppTypography.labelSmall.copyWith(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.surfaceContainer),
                  const SizedBox(height: 10),
                  // Info row
                  Row(
                    children: [
                      // Kasir
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 15,
                                color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                transaction.kasirName.isNotEmpty
                                    ? transaction.kasirName
                                    : 'Kasir',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Items count
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined,
                              size: 15, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '$itemCount item',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Total
                      Text(
                        currencyFormat.format(transaction.total),
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                  // Expand toggle row
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        isExpanded ? 'Sembunyikan detail' : 'Lihat detail',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryContainer,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded items
            if (isExpanded) ...[
              const Divider(
                  height: 1,
                  color: AppColors.surfaceContainerLow,
                  thickness: 1.2),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Pesanan',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...transaction.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryFixed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item.quantity}x',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                          color: AppColors.primaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat
                                  .format(item.price * item.quantity),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.surfaceContainer),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          currencyFormat.format(transaction.total),
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada transaksi',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi yang masuk akan\nmuncul di sini',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
