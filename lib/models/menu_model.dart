class MenuModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  const MenuModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory MenuModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MenuModel(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Lainnya',
      imageUrl: map['image_url'] as String?,
      isAvailable: map['is_available'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'category': category,
    'image_url': imageUrl,
    'is_available': isAvailable,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  MenuModel copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return MenuModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'MenuModel(id: $id, name: $name, price: $price)';
}
