import 'cart_item_model.dart';

class TransactionModel {
  final String id;
  final String invoiceNumber;
  final String kasirId;
  final String kasirName;
  final List<CartItemModel> items;
  final double totalAmount;
  final String status; // 'PENDING', 'PAID', 'EXPIRED', 'CANCELLED'
  final String paymentMethod;
  final String? paymentReference;
  final String? checkoutUrl;
  final String? qrImageUrl;
  final String? qrString;
  final DateTime createdAt;
  final DateTime? paidAt;

  TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.kasirId,
    required this.kasirName,
    required this.items,
    required this.totalAmount,
    this.status = 'PENDING',
    this.paymentMethod = 'QRIS',
    this.paymentReference,
    this.checkoutUrl,
    this.qrImageUrl,
    this.qrString,
    required this.createdAt,
    this.paidAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'kasirId': kasirId,
      'kasirName': kasirName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'checkoutUrl': checkoutUrl,
      'qrImageUrl': qrImageUrl,
      'qrString': qrString,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map, String id) {
    List<CartItemModel> itemList = [];
    if (map['items'] != null) {
      if (map['items'] is List) {
        itemList = (map['items'] as List)
            .map((item) => CartItemModel.fromMap(Map<dynamic, dynamic>.from(item)))
            .toList();
      } else if (map['items'] is Map) {
        itemList = (map['items'] as Map)
            .values
            .map((item) => CartItemModel.fromMap(Map<dynamic, dynamic>.from(item)))
            .toList();
      }
    }

    return TransactionModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      kasirId: map['kasirId'] ?? '',
      kasirName: map['kasirName'] ?? '',
      items: itemList,
      totalAmount: (map['totalAmount'] is num)
          ? (map['totalAmount'] as num).toDouble()
          : 0.0,
      status: map['status'] ?? 'PENDING',
      paymentMethod: map['paymentMethod'] ?? 'QRIS',
      paymentReference: map['paymentReference'],
      checkoutUrl: map['checkoutUrl'],
      qrImageUrl: map['qrImageUrl'],
      qrString: map['qrString'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt']) : null,
    );
  }
}
