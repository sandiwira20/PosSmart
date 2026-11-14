import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';

class TransactionService {
  /// Mengambil semua riwayat transaksi dari Firebase Realtime Database
  static Future<List<TransactionModel>> getTransactions() async {
    try {
      final snapshot = await FirebaseService.transactionsRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value;
      final List<TransactionModel> transactions = [];

      if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            transactions.add(TransactionModel.fromMap(val, key.toString()));
          }
        });
      }

      // Urutkan dari transaksi terbaru
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    } catch (e) {
      debugPrint('Error getting transactions from Firebase: $e');
      return [];
    }
  }

  /// Simpan transaksi baru ke Firebase
  static Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await FirebaseService.transactionsRef
          .child(transaction.invoiceNumber)
          .set(transaction.toMap());
    } catch (e) {
      debugPrint('Error saving transaction to Firebase: $e');
    }
  }

  /// Update status pembayaran transaksi (misal menjadi 'PAID')
  static Future<void> updateStatus(String invoiceNumber, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (status == 'PAID') {
        updates['paidAt'] = DateTime.now().toIso8601String();
      }

      await FirebaseService.transactionsRef
          .child(invoiceNumber)
          .update(updates);
    } catch (e) {
      debugPrint('Error updating transaction status in Firebase: $e');
    }
  }

  /// Stream realtime untuk riwayat transaksi
  static Stream<List<TransactionModel>> streamTransactions() {
    return FirebaseService.transactionsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <TransactionModel>[];
      }

      final data = snapshot.value;
      final List<TransactionModel> transactions = [];

      if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            transactions.add(TransactionModel.fromMap(val, key.toString()));
          }
        });
      }

      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }
}
