import '../models/transaction_model.dart';

class TransactionService {
  static final List<TransactionModel> _transactions = [];

  static Future<List<TransactionModel>> getTransactions() async {
    return List.from(_transactions.reversed);
  }

  static Future<void> saveTransaction(TransactionModel transaction) async {
    final existingIndex = _transactions.indexWhere((t) => t.id == transaction.id);
    if (existingIndex != -1) {
      _transactions[existingIndex] = transaction;
    } else {
      _transactions.add(transaction);
    }
  }

  static Future<void> updateStatus(String invoiceNumber, String status) async {
    final index = _transactions.indexWhere((t) => t.invoiceNumber == invoiceNumber);
    if (index != -1) {
      final old = _transactions[index];
      _transactions[index] = TransactionModel(
        id: old.id,
        invoiceNumber: old.invoiceNumber,
        kasirId: old.kasirId,
        kasirName: old.kasirName,
        items: old.items,
        totalAmount: old.totalAmount,
        status: status,
        paymentMethod: old.paymentMethod,
        paymentReference: old.paymentReference,
        checkoutUrl: old.checkoutUrl,
        qrImageUrl: old.qrImageUrl,
        qrString: old.qrString,
        createdAt: old.createdAt,
        paidAt: status == 'PAID' ? DateTime.now() : old.paidAt,
      );
    }
  }
}
