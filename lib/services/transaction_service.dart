import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import '../models/transaction_model.dart';
import '../models/cart_item_model.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class TransactionService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final _uuid = const Uuid();

  // Stream transaksi (kasir hanya miliknya, admin semua)
  Stream<List<TransactionModel>> streamTransactions({String? kasirId}) {
    return _db.ref(AppConstants.transactionsPath).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final list = map.entries
          .map((e) => TransactionModel.fromMap(
                e.key as String,
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kasirId != null) {
        return list.where((t) => t.kasirId == kasirId).toList();
      }
      return list;
    });
  }

  // Create transaksi baru + panggil MiomiPay
  Future<TransactionModel> createTransaction({
    required UserModel kasir,
    required List<CartItemModel> cartItems,
    required String paymentMethod,
  }) async {
    final id = _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();
    final externalId = 'POS-$id';

    final subtotal =
        cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    final tax = subtotal * AppConstants.taxRate;
    final total = subtotal + tax;

    final items = cartItems
        .map((c) => TransactionItemModel(
              menuId: c.menu.id,
              menuName: c.menu.name,
              price: c.menu.price,
              quantity: c.quantity,
              subtotal: c.subtotal,
              imageUrl: c.menu.imageUrl,
            ))
        .toList();

    TransactionModel transaction = TransactionModel(
      id: externalId,
      kasirId: kasir.uid,
      kasirName: kasir.name,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
    );

    if (paymentMethod == AppConstants.paymentQris) {
      // Call MiomiPay API
      final paymentResult = await _createMiomiPayPayment(
        externalId: externalId,
        amount: total.round(),
        description: 'Transaksi PosSmart - ${items.length} item',
      );

      transaction = transaction.copyWith(
        paymentReference: paymentResult['reference'],
        checkoutUrl: paymentResult['checkout_url'],
        qrImageUrl: paymentResult['qr_image_url'],
      );
    } else {
      // Cash — langsung PAID
      transaction = transaction.copyWith(
        status: AppConstants.statusPaid,
        paidAt: DateTime.now(),
      );
    }

    // Save to Firebase
    await _db
        .ref('${AppConstants.transactionsPath}/$externalId')
        .set(transaction.toMap());

    return transaction;
  }

  // Check payment status dari MiomiPay
  Future<String> checkPaymentStatus(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.miomiPayBaseUrl}/payment/$reference/status'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.miomiPayKey}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['status'] as String? ?? AppConstants.statusPending;
      }
    } catch (e) {
      // ignore
    }
    return AppConstants.statusPending;
  }

  // Update status transaksi di Firebase
  Future<void> updateTransactionStatus(
    String transactionId,
    String status, {
    DateTime? paidAt,
  }) async {
    final updates = <String, dynamic>{'status': status};
    if (paidAt != null) {
      updates['paid_at'] = paidAt.millisecondsSinceEpoch;
    }
    await _db
        .ref('${AppConstants.transactionsPath}/$transactionId')
        .update(updates);
  }

  // Internal: Call MiomiPay create payment
  Future<Map<String, dynamic>> _createMiomiPayPayment({
    required String externalId,
    required int amount,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.miomiPayBaseUrl}/payment/create'),
      headers: {
        'Authorization': 'Bearer ${AppConstants.miomiPayKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'external_id': externalId,
        'amount': amount,
        'description': description,
        'payment_method': 'qris',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final payData = data['data'] ?? data;
      return {
        'reference': payData['reference'] ?? payData['external_id'],
        'checkout_url': payData['checkout_url'],
        'qr_image_url': payData['qr_image_url'],
      };
    } else {
      throw Exception('MiomiPay error: ${response.statusCode} ${response.body}');
    }
  }
}
