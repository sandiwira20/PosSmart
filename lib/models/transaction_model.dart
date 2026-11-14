class TransactionItemModel {
  final String menuId;
  final String menuName;
  final double price;
  final int quantity;
  final double subtotal;
  final String? imageUrl;

  const TransactionItemModel({
    required this.menuId,
    required this.menuName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
  });

  factory TransactionItemModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionItemModel(
      menuId: map['menu_id'] as String? ?? '',
      menuName: map['menu_name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'menu_id': menuId,
    'menu_name': menuName,
    'price': price,
    'quantity': quantity,
    'subtotal': subtotal,
    'image_url': imageUrl,
  };
}

class TransactionModel {
  final String id;
  final String kasirId;
  final String kasirName;
  final List<TransactionItemModel> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final String status;
  final String? paymentReference;
  final String? checkoutUrl;
  final String? qrImageUrl;
  final DateTime createdAt;
  final DateTime? paidAt;

  const TransactionModel({
    required this.id,
    required this.kasirId,
    required this.kasirName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.paymentReference,
    this.checkoutUrl,
    this.qrImageUrl,
    required this.createdAt,
    this.paidAt,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory TransactionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawItems = map['items'];
    List<TransactionItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .whereType<Map>()
          .map((e) => TransactionItemModel.fromMap(e))
          .toList();
    } else if (rawItems is Map) {
      itemsList = rawItems.values
          .whereType<Map>()
          .map((e) => TransactionItemModel.fromMap(e))
          .toList();
    }

    return TransactionModel(
      id: id,
      kasirId: map['kasir_id'] as String? ?? '',
      kasirName: map['kasir_name'] as String? ?? '',
      items: itemsList,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'qris',
      status: map['status'] as String? ?? 'PENDING',
      paymentReference: map['payment_reference'] as String?,
      checkoutUrl: map['checkout_url'] as String?,
      qrImageUrl: map['qr_image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      paidAt: map['paid_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paid_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'kasir_id': kasirId,
    'kasir_name': kasirName,
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'payment_method': paymentMethod,
    'status': status,
    'payment_reference': paymentReference,
    'checkout_url': checkoutUrl,
    'qr_image_url': qrImageUrl,
    'created_at': createdAt.millisecondsSinceEpoch,
    'paid_at': paidAt?.millisecondsSinceEpoch,
  };

  TransactionModel copyWith({
    String? status,
    String? paymentReference,
    String? checkoutUrl,
    String? qrImageUrl,
    DateTime? paidAt,
  }) {
    return TransactionModel(
      id: id,
      kasirId: kasirId,
      kasirName: kasirName,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
